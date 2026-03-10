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
ATTEMPTS=0
NEXT_TS=0
REBOOT_LEVEL=0

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
SSH_OPTS="-p ${SENSECAP_SSH_PORT} -i ${SSH_KEY_PATH} -o IdentitiesOnly=yes -o ConnectTimeout=10"

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
  save_state
  exit 1
fi

if [[ "$BOOT_DELAY" -gt 0 ]]; then
  log "Połączenie SSH działa. Czekam ${BOOT_DELAY}s przed próbą naprawy kontenerów..."
  sleep "$BOOT_DELAY"
fi

log "Próbuję odtworzyć środowisko PiPhi wewnątrz ubuntu-piphi (dokładnie jak ręcznie)..."

ssh $SSH_OPTS "$SSH_TARGET" '
  set -e

  echo "===> balena ps (host) dla diagnostyki:"
  balena ps || true

  echo "===> Sprawdzam, czy ubuntu-piphi jest UP..."
  if ! balena ps | grep -q "ubuntu-piphi"; then
    echo "ubuntu-piphi nie działa – próbuję go uruchomić..."
    balena restart ubuntu-piphi || true
    sleep 10
  fi

  echo "===> Sprawdzam dockerd w ubuntu-piphi (docker info)..."
  if ! balena exec ubuntu-piphi docker info >/dev/null 2>&1; then
    echo "Docker w ubuntu-piphi NIE działa – uruchamiam tak jak ręcznie."
    if balena exec ubuntu-piphi bash -lc "[ -d /piphi-network ]"; then
      echo "Uruchamiam: cd /piphi-network && dockerd --host=unix:///var/run/docker.sock > /piphi-network/dockerd.log 2>&1 &"
      balena exec ubuntu-piphi bash -lc "cd /piphi-network && dockerd --host=unix:///var/run/docker.sock > /piphi-network/dockerd.log 2>&1 &"
      sleep 10
      echo "Uruchamiam: ./start-piphi.sh (docker compose up ...)"
      balena exec ubuntu-piphi bash -lc "cd /piphi-network && ./start-piphi.sh" || true
    elif [ -d /mnt/data/piphi ]; then
      echo "Fallback: /mnt/data/piphi istnieje – uruchamiam tam start-piphi.sh"
      balena exec ubuntu-piphi bash -lc "cd /mnt/data/piphi && ./start-piphi.sh" || true
    else
      echo "Brak katalogu /piphi-network i /mnt/data/piphi – nie wiem, gdzie jest instalacja PiPhi."
    fi
  else
    echo "Docker w ubuntu-piphi działa – sprawdzam kontenery PiPhi..."
    balena exec ubuntu-piphi docker ps || true
  fi
' >> "$LOGFILE" 2>&1 || log "Błąd podczas odtwarzania środowiska PiPhi wewnątrz ubuntu-piphi."

log "Odczekuję ${RETRY_DELAY}s i ponownie sprawdzam panel..."
sleep "$RETRY_DELAY"

if curl -s --max-time 5 "$URL" >/dev/null 2>&1; then
  log "Panel PiPhi ponownie działa po naprawie. Resetuję stan."
  ATTEMPTS=0
  NEXT_TS=0
  REBOOT_LEVEL=0
  save_state
  exit 0
fi

log "Panel PiPhi nadal nie działa po próbie naprawy."

# ----- aktualizacja backoffu i rebootów -----

ATTEMPTS=$(( ATTEMPTS + 1 ))
log "Kolejna nieudana próba z SSH OK: ATTEMPTS=$ATTEMPTS, REBOOT_LEVEL=$REBOOT_LEVEL"

BASE_DELAY_MIN=10
MAX_DELAY_BEFORE_FIRST_REBOOT=240  # 4h

REBOOT_DONE=0
DELAY_MIN=0

if (( REBOOT_LEVEL == 0 )); then
  if (( ATTEMPTS >= 3 )); then
    BLOCK=$(( (ATTEMPTS - 3) / 3 ))
    DELAY_MIN=$(( BASE_DELAY_MIN * (1 << BLOCK) ))
    if (( DELAY_MIN > MAX_DELAY_BEFORE_FIRST_REBOOT )); then
      DELAY_MIN=$MAX_DELAY_BEFORE_FIRST_REBOOT
    fi
  else
    DELAY_MIN=0
  fi

  if (( DELAY_MIN == MAX_DELAY_BEFORE_FIRST_REBOOT )); then
    log "Osiągnięto maksymalny backoff przed pierwszym rebootem (${MAX_DELAY_BEFORE_FIRST_REBOOT} min). Wysyłam reboot SenseCAP..."
    if ssh $SSH_OPTS "$SSH_TARGET" "reboot" >/dev/null 2>&1; then
      log "Komenda reboot (poziom 1) wysłana pomyślnie."
    else
      log "Nie udało się wysłać komendy reboot (poziom 1)."
    fi
    REBOOT_DONE=1
    REBOOT_LEVEL=1
    ATTEMPTS=0
    DELAY_MIN=$((8*60))
  fi

elif (( REBOOT_LEVEL == 1 )); then
  DELAY_MIN=$((8*60))
  log "Jesteśmy po pierwszym reboocie. Ustawiam minimalny backoff 8h."

  if (( ATTEMPTS >= 3 )); then
    log "Kolejne nieudane próby po pierwszym reboocie, wysyłam drugi reboot..."
    if ssh $SSH_OPTS "$SSH_TARGET" "reboot" >/dev/null 2>&1; then
      log "Komenda reboot (poziom 2) wysłana pomyślnie."
    else
      log "Nie udało się wysłać komendy reboot (poziom 2)."
    fi
    REBOOT_DONE=1
    REBOOT_LEVEL=2
    ATTEMPTS=0
    DELAY_MIN=$((16*60))
  fi

elif (( REBOOT_LEVEL == 2 )); then
  DELAY_MIN=$((16*60))
  log "Jesteśmy po drugim reboocie. Ustawiam minimalny backoff 16h."

  if (( ATTEMPTS >= 3 )); then
    log "Kolejne nieudane próby po drugim reboocie, wysyłam trzeci reboot..."
    if ssh $SSH_OPTS "$SSH_TARGET" "reboot" >/dev/null 2>&1; then
      log "Komenda reboot (poziom 3) wysłana pomyślnie."
    else
      log "Nie udało się wysłać komendy reboot (poziom 3)."
    fi
    REBOOT_DONE=1
    REBOOT_LEVEL=3
    ATTEMPTS=0
    DELAY_MIN=$((24*60))
  fi

else
  DELAY_MIN=$((24*60))
  log "Tryb podtrzymania: REBOOT_LEVEL>=3, maksymalnie jeden reboot na 24h."
  if (( ATTEMPTS >= 3 )); then
    log "Kolejne nieudane próby w trybie 24h, wysyłam reboot..."
    if ssh $SSH_OPTS "$SSH_TARGET" "reboot" >/dev/null 2>&1; then
      log "Komenda reboot (tryb 24h) wysłana pomyślnie."
    else
      log "Nie udało się wysłać komendy reboot (tryb 24h)."
    fi
    REBOOT_DONE=1
    ATTEMPTS=0
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
