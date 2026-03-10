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

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOGFILE"
}

# 1. Ping HTTP panelu PiPhi
URL="http://${SENSECAP_HOST}:${SENSECAP_PORT}/"
log "Sprawdzam panel PiPhi pod adresem: $URL"

if curl -s --max-time 5 "$URL" >/dev/null 2>&1; then
  log "Panel PiPhi odpowiada. Nic nie robię."
  exit 0
fi

log "Panel PiPhi NIE odpowiada. Próba naprawy..."

# 2. Próba połączenia SSH (ssh użyje ssh-agent, więc BEZ -i)
SSH_TARGET="${SENSECAP_SSH_USER}@${SENSECAP_HOST}"
SSH_OPTS="-p ${SENSECAP_SSH_PORT} -o BatchMode=yes -o ConnectTimeout=10"

if ! ssh $SSH_OPTS "$SSH_TARGET" "echo 'SSH OK'" >/dev/null 2>&1; then
  log "Brak połączenia SSH do $SSH_TARGET. Możliwe, że SenseCAP jeszcze nie wstał. Czekam ${BOOT_DELAY}s i kończę."
  sleep "$BOOT_DELAY"
  exit 1
fi

log "Połączenie SSH do SenseCAP działa. Czekam ${BOOT_DELAY}s przed restartem kontenerów..."
sleep "$BOOT_DELAY"

# 3. Restart kontenerów / próba postawienia panelu
log "Próbuję odświeżyć kontenery PiPhi na SenseCAP..."

ssh $SSH_OPTS "$SSH_TARGET" 'balena ps' >> "$LOGFILE" 2>&1 || log "balena ps zwróciło błąd (mogło jeszcze nie wstać)."

ssh $SSH_OPTS "$SSH_TARGET" '
  echo "Restartuję kontenery PiPhi..."
  balena restart db || true
  balena restart grafana || true
  balena restart watchtower || true
  balena restart piphi-network-image || true
' >> "$LOGFILE" 2>&1 || log "Błąd podczas restartu kontenerów."

log "Odczekuję ${RETRY_DELAY}s i ponownie sprawdzam panel..."
sleep "$RETRY_DELAY"

if curl -s --max-time 5 "$URL" >/dev/null 2>&1; then
  log "Panel PiPhi ponownie działa."
  exit 0
fi

log "Panel PiPhi nadal nie działa po próbie restartu. Sprawdzę przy kolejnym wywołaniu watchdoga."
exit 1
