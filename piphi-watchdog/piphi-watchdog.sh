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

# 1. Sprawdzenie panelu PiPhi (HTTP)
URL="http://${SENSECAP_HOST}:${SENSECAP_PORT}/"
log "Sprawdzam panel PiPhi pod adresem: $URL"

if curl -s --max-time 5 "$URL" >/dev/null 2>&1; then
  log "Panel PiPhi odpowiada. Nic nie robię."
  exit 0
fi

log "Panel PiPhi NIE odpowiada. Próba naprawy..."

# 2. Sprawdzenie SSH (ssh użyje ssh-agent, bez -i)
SSH_TARGET="${SENSECAP_SSH_USER}@${SENSECAP_HOST}"
SSH_OPTS="-p ${SENSECAP_SSH_PORT} -o BatchMode=yes -o ConnectTimeout=10"

if ! ssh $SSH_OPTS "$SSH_TARGET" "echo 'SSH OK'" >/dev/null 2>&1; then
  log "Brak połączenia SSH do $SSH_TARGET. Możliwe, że SenseCAP jeszcze nie wstał. Czekam ${BOOT_DELAY}s i kończę."
  sleep "$BOOT_DELAY"
  exit 1
fi

log "Połączenie SSH do SenseCAP działa. Czekam ${BOOT_DELAY}s przed restartem kontenerów..."
sleep "$BOOT_DELAY"

# 3. Restart kontenerów PiPhi wewnątrz ubuntu-piphi
log "Próbuję odświeżyć kontenery PiPhi wewnątrz ubuntu-piphi..."

# Podgląd kontenerów na hoście (debug)
ssh $SSH_OPTS "$SSH_TARGET" 'balena ps' >> "$LOGFILE" 2>&1 || log "balena ps na hoście zwróciło błąd (może jeszcze nie wstał)."

# Restart wewnętrznego Dockera w ubuntu-piphi
ssh $SSH_OPTS "$SSH_TARGET" '
  echo "Restartuję kontenery PiPhi wewnątrz ubuntu-piphi..."
  # restart kontenerów w środku ubuntu-piphi
  balena exec ubuntu-piphi docker restart db grafana piphi-network-image watchtower 2>&1 || true
' >> "$LOGFILE" 2>&1 || log "Błąd podczas restartu kontenerów PiPhi wewnątrz ubuntu-piphi."

log "Odczekuję ${RETRY_DELAY}s i ponownie sprawdzam panel..."
sleep "$RETRY_DELAY"

if curl -s --max-time 5 "$URL" >/dev/null 2>&1; then
  log "Panel PiPhi ponownie działa."
  exit 0
fi

log "Panel PiPhi nadal nie działa po próbie restartu. Sprawdzę przy kolejnym wywołaniu watchdoga."
exit 1
