#!/usr/bin/env bash
set -e

CONF_FILE="$HOME/.config/piphi-watchdog.conf"

if [[ ! -f "$CONF_FILE" ]]; then
  echo "Brak pliku konfiguracyjnego: $CONF_FILE"
  exit 1
fi

# shellcheck source=/dev/null
source "$CONF_FILE"

LOGFILE="$HOME/piphi-watchdog-run.log"
STATE_DIR="$HOME/.local/state"
STATE_FILE="$STATE_DIR/piphi-watchdog.state"

mkdir -p "$STATE_DIR"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOGFILE"
}

# ----- Backoff + reboot state -----
ATTEMPTS=0        # kolejne nieudane próby przy SSH OK
NEXT_TS=0         # unix ts do którego pauzujemy próby
REBOOT_LEVEL=0    # 0=jeszcze nie rebootowaliśmy, 1=po 1 reboocie, 2=po 2, >=3=tryb 24h

if [[ -f "$STATE_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$STATE_FILE" || true
fi

now_ts() {
  date +%s
}

save_state() {
  cat > "$STATE_FILE" <<EOF
ATTEMPTS=$ATTEMPTS
NEXT_TS=$NEXT_TS
REBOOT_LEVEL=$REBOOT_LEVEL
EOF
}

NOW=$(now_ts)

# jeśli mamy pauzę – kończymy od razu
if [[ "$NEXT_TS" -gt "$NOW" ]]; then
  REM=$(( NEXT_TS - NOW ))
  log "Backoff aktywny: kolejne próby dopiero za ${REM}s (do $(date -d "@$NEXT_TS")). Kończę."
  exit 0
fi

URL="http://${SENSECAP_HOST}:${SENSECAP_PORT}/"
SSH_TARGET="${SENSECAP_SSH_USER}@${SENSECAP_HOST}"
SSH_OPTS="-p ${SENSECAP_SSH_PORT} -o BatchMode=yes -o ConnectTimeout=10"

BOOT_DELAY="${BOOT_DELAY:-0}"
RETRY_DELAY="${RETRY_DELAY:-30}"

log "Sprawdzam panel PiPhi pod adresem: $URL"

if curl -s --max-time 5 "$URL" >/dev/null 2>&1; then
  log "Panel PiPhi odpowiada. Resetuję cały stan backoff/reboot."
  ATTEMPTS=0
  NEXT_TS=0
  REBOOT_LEVEL=0
  save_state
  exit 0
fi

log "Panel PiPhi NIE odpowiada. Próba naprawy..."

# szybki test SSH
if ! ssh $SSH_OPTS "$SSH_TARGET" "echo 'SSH OK'" >/dev/null 2>&1; then
  log "Brak połączenia SSH do $SSH_TARGET. Kończę od razu, spróbuję przy kolejnym wywołaniu watchdoga."
  # nie zwiększamy ATTEMPTS, bo nie dotykamy sensownie SenseCAP
  save_state
  exit 1
fi

if [[ "$BOOT_DELAY" -gt 0 ]]; then
  log "Połączenie SSH działa. Czekam ${BOOT_DELAY}s przed restartem kontenerów..."
  sleep "$BOOT_DELAY"
fi

log "Próbuję odświeżyć kontenery PiPhi wewnątrz ubuntu-piphi..."

ssh $SSH_OPTS "$SSH_TARGET" '
  set -e

  echo "===> balena ps (host) dla diagnostyki:"
  balena ps || true

  echo "===> Sprawdzam Docker wewnątrz ubuntu-piphi..."
  if ! balena exec ubuntu-piphi docker info >/dev/null 2>&1; then
    echo "Docker w ubuntu-piphi NIE działa. Uruchamiam start-piphi.sh..."
    if balena exec ubuntu-piphi bash -lc "[ -d /piphi-network ]"; then
      balena exec ubuntu-piphi bash -lc "cd /piphi-network && ./start-piphi.sh" || true
    elif [ -d /mnt/data/piphi ]; then
      cd /mnt/data/piphi && ./start-piphi.sh || true
    fi
  else
    echo "Docker w ubuntu-piphi działa."
  fi

  echo "===> Restartuję kontenery PiPhi wewnątrz ubuntu-piphi (db, grafana, piphi-network-image, watchtower)..."
  balena exec ubuntu-piphi docker restart db 2>&1 || true
  balena exec ubuntu-piphi docker restart grafana piphi-network-image watchtower 2>&1 || true
' >> "$LOGFILE" 2>&1 || log "Błąd podczas restartu / startu kontenerów PiPhi wewnątrz ubuntu-piphi."

log "Odczekuję ${RETRY_DELAY}s i ponownie sprawdzam panel..."
sleep "$RETRY_DELAY"

if curl -s --max-time 5 "$URL" >/dev/null 2>&1; then
  log "Panel PiPhi ponownie działa po restarcie. Resetuję stan."
  ATTEMPTS=0
  NEXT_TS=0
  REBOOT_LEVEL=0
  save_state
  exit 0
fi

log "Panel PiPhi nadal nie działa po próbie restartu."

# ----- aktualizacja backoffu i rebootów -----

ATTEMPTS=$(( ATTEMPTS + 1 ))
log "Kolejna nieudana próba z SSH OK: ATTEMPTS=$ATTEMPTS, REBOOT_LEVEL=$REBOOT_LEVEL"

# bazowy backoff przed pierwszym rebootem: 10, 20, 40, 80, 160, 240 min
BASE_DELAY_MIN=10
MAX_DELAY_BEFORE_FIRST_REBOOT=240  # 4h

REBOOT_DONE=0
DELAY_MIN=0

if (( REBOOT_LEVEL == 0 )); then
  # przed pierwszym rebootem robimy klasyczny exponential backoff
  if (( ATTEMPTS >= 3 )); then
    BLOCK=$(( (ATTEMPTS - 3) / 3 ))  # 0,1,2,...
    DELAY_MIN=$(( BASE_DELAY_MIN * (1 << BLOCK) ))
    if (( DELAY_MIN > MAX_DELAY_BEFORE_FIRST_REBOOT )); then
      DELAY_MIN=$MAX_DELAY_BEFORE_FIRST_REBOOT
    fi
  else
    DELAY_MIN=0
  fi

  if (( DELAY_MIN == MAX_DELAY_BEFORE_FIRST_REBOOT )); then
    log "Osiągnięto maksymalny backoff przed pierwszym rebootem (${MAX_DELAY_BEFORE_FIRST_REBOOT} min). Wysyłam reboot SenseCAP..."
    if ssh $SSH_OPTS "$SSH_TARGET" "sudo reboot" >/dev/null 2>&1; then
      log "Komenda reboot (poziom 1) wysłana pomyślnie."
    else
      log "Nie udało się wysłać komendy reboot (poziom 1)."
    fi
    REBOOT_DONE=1
    REBOOT_LEVEL=1
    ATTEMPTS=0
    DELAY_MIN=8*60   # po pierwszym reboocie pauza 8h
  fi

elif (( REBOOT_LEVEL == 1 )); then
  # po pierwszym reboocie: max „loopowanie” i kolejny reboot dopiero po 8h
  DELAY_MIN=8*60
  log "Jesteśmy po pierwszym reboocie. Ustawiam minimalny backoff 8h."

  # jeśli ATTEMPTS urosną (panel ciągle leży) – znowu reboot, ale nie częściej niż co 8h
  if (( ATTEMPTS >= 3 )); then
    log "Kolejne nieudane próby po pierwszym reboocie, wysyłam drugi reboot..."
    if ssh $SSH_OPTS "$SSH_TARGET" "sudo reboot" >/dev/null 2>&1; then
      log "Komenda reboot (poziom 2) wysłana pomyślnie."
    else
      log "Nie udało się wysłać komendy reboot (poziom 2)."
    fi
    REBOOT_DONE=1
    REBOOT_LEVEL=2
    ATTEMPTS=0
    DELAY_MIN=16*60  # po drugim reboocie pauza 16h
  fi

elif (( REBOOT_LEVEL == 2 )); then
  # po drugim reboocie: kolejne dopiero po 16h
  DELAY_MIN=16*60
  log "Jesteśmy po drugim reboocie. Ustawiam minimalny backoff 16h."

  if (( ATTEMPTS >= 3 )); then
    log "Kolejne nieudane próby po drugim reboocie, wysyłam trzeci reboot..."
    if ssh $SSH_OPTS "$SSH_TARGET" "sudo reboot" >/dev/null 2>&1; then
      log "Komenda reboot (poziom 3) wysłana pomyślnie."
    else
      log "Nie udało się wysłać komendy reboot (poziom 3)."
    fi
    REBOOT_DONE=1
    REBOOT_LEVEL=3
    ATTEMPTS=0
    DELAY_MIN=24*60  # potem już max raz na 24h
  fi

else
  # REBOOT_LEVEL >= 3: ostatecznie, reboot max raz na 24h
  DELAY_MIN=24*60
  log "Tryb podtrzymania: REBOOT_LEVEL>=3, maksymalnie jeden reboot na 24h."
  if (( ATTEMPTS >= 3 )); then
    log "Kolejne nieudane próby w trybie 24h, wysyłam reboot..."
    if ssh $SSH_OPTS "$SSH_TARGET" "sudo reboot" >/dev/null 2>&1; then
      log "Komenda reboot (tryb 24h) wysłana pomyślnie."
    else
      log "Nie udało się wysłać komendy reboot (tryb 24h)."
    fi
    REBOOT_DONE=1
    ATTEMPTS=0
    # REBOOT_LEVEL zostaje jak jest (>=3), DELAY_MIN 24h
  fi
fi

if (( DELAY_MIN > 0 )); then
  DELAY_SEC=$(( DELAY_MIN * 60 ))
  NEXT_TS=$(( NOW + DELAY_SEC ))
  log "Ustawiam backoff: następne realne próby dopiero za ${DELAY_MIN} minut (do $(date -d "@$NEXT_TS"))."
else
  NEXT_TS=0
fi

save_state

if (( REBOOT_DONE == 1 )); then
  log "Po reboot (REBOOT_LEVEL=$REBOOT_LEVEL) watchdog na RPi będzie czekał do $(date -d "@$NEXT_TS") zanim znowu dotknie SenseCAP."
fi

exit 1
