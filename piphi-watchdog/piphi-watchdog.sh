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

# ----- Backoff state -----

# struktura stanu:
# ATTEMPTS=0..N (ile kolejnych nieudanych prób przy SSH OK)
# NEXT_TS=unix_epoch (do kiedy pauzujemy próby na SenseCAP)

ATTEMPTS=0
NEXT_TS=0

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
EOF
}

# Jeśli mamy ustawiony NEXT_TS w przyszłości, nie dotykamy SenseCAP
NOW=$(now_ts)
if [[ "$NEXT_TS" -gt "$NOW" ]]; then
  REM=$(( NEXT_TS - NOW ))
  log "Backoff aktywny: kolejne próby dopiero za ${REM}s (do $(date -d "@$NEXT_TS")). Kończę."
  exit 0
fi

URL="http://${SENSECAP_HOST}:${SENSECAP_PORT}/"
SSH_TARGET="${SENSECAP_SSH_USER}@${SENSECAP_HOST}"
SSH_OPTS="-p ${SENSECAP_SSH_PORT} -o BatchMode=yes -o ConnectTimeout=10"

# domyślne z configa (ale bez długich sleepów)
BOOT_DELAY="${BOOT_DELAY:-0}"
RETRY_DELAY="${RETRY_DELAY:-30}"

log "Sprawdzam panel PiPhi pod adresem: $URL"

if curl -s --max-time 5 "$URL" >/dev/null 2>&1; then
  log "Panel PiPhi odpowiada. Resetuję licznik backoff i nic nie robię."
  ATTEMPTS=0
  NEXT_TS=0
  save_state
  exit 0
fi

log "Panel PiPhi NIE odpowiada. Próba naprawy..."

# szybki test SSH
if ! ssh $SSH_OPTS "$SSH_TARGET" "echo 'SSH OK'" >/dev/null 2>&1; then
  log "Brak połączenia SSH do $SSH_TARGET. Kończę od razu, spróbuję przy kolejnym wywołaniu watchdoga."
  # Nie zwiększamy ATTEMPTS, bo nie męczyliśmy SenseCAP sensownie
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
  log "Panel PiPhi ponownie działa po restarcie. Resetuję licznik backoff."
  ATTEMPTS=0
  NEXT_TS=0
  save_state
  exit 0
fi

log "Panel PiPhi nadal nie działa po próbie restartu."

# ----- aktualizacja backoffu -----

ATTEMPTS=$(( ATTEMPTS + 1 ))
log "Kolejna nieudana próba z SSH OK: ATTEMPTS=$ATTEMPTS"

# co 3 próby zwiększamy okno: 10, 20, 40, 80, 160, 240 (max 4h)
if (( ATTEMPTS >= 3 )); then
  # stopień = liczba „bloków” po 3 próby, zaczynamy od 0
  BLOCK=$(( (ATTEMPTS - 3) / 3 ))  # 0,1,2,...
  BASE_DELAY_MIN=10

  # wyliczamy minuty = 10 * 2^BLOCK, ale cap na 240
  DELAY_MIN=$(( BASE_DELAY_MIN * (1 << BLOCK) ))
  if (( DELAY_MIN > 240 )); then
    DELAY_MIN=240
  fi

  DELAY_SEC=$(( DELAY_MIN * 60 ))
  NEXT_TS=$(( NOW + DELAY_SEC ))
  log "Ustawiam backoff: następne realne próby dopiero za ${DELAY_MIN} minut (do $(date -d "@$NEXT_TS"))."
else
  # jeszcze nie dobiliśmy do 3 nieudanych prób – bez dodatkowego backoffu
  NEXT_TS=0
fi

save_state
exit 1
