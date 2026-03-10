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

URL="http://${SENSECAP_HOST}:${SENSECAP_PORT}/"
SSH_TARGET="${SENSECAP_SSH_USER}@${SENSECAP_HOST}"
SSH_OPTS="-p ${SENSECAP_SSH_PORT} -o BatchMode=yes -o ConnectTimeout=10"

# Domyślne (jakby nie było w conf)
BOOT_DELAY="${BOOT_DELAY:-0}"
RETRY_DELAY="${RETRY_DELAY:-30}"

log "Sprawdzam panel PiPhi pod adresem: $URL"

if curl -s --max-time 5 "$URL" >/dev/null 2>&1; then
  log "Panel PiPhi odpowiada. Nic nie robię."
  exit 0
fi

log "Panel PiPhi NIE odpowiada. Próba naprawy..."

# 1. Szybkie sprawdzenie SSH (bez długiego sleep)
if ! ssh $SSH_OPTS "$SSH_TARGET" "echo 'SSH OK'" >/dev/null 2>&1; then
  log "Brak połączenia SSH do $SSH_TARGET. Kończę od razu, spróbuję przy kolejnym wywołaniu watchdoga."
  exit 1
fi

if [[ "$BOOT_DELAY" -gt 0 ]]; then
  log "Połączenie SSH działa. Czekam ${BOOT_DELAY}s (jednorazowe opóźnienie) przed restartem kontenerów..."
  sleep "$BOOT_DELAY"
fi

# 2. Start Dockera + restart PiPhi w ubuntu-piphi
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
  # db jest kluczowy, reszta opcjonalna – błędy ignorujemy
  balena exec ubuntu-piphi docker restart db 2>&1 || true
  balena exec ubuntu-piphi docker restart grafana piphi-network-image watchtower 2>&1 || true
' >> "$LOGFILE" 2>&1 || log "Błąd podczas restartu / startu kontenerów PiPhi wewnątrz ubuntu-piphi."

log "Odczekuję ${RETRY_DELAY}s i ponownie sprawdzam panel..."
sleep "$RETRY_DELAY"

if curl -s --max-time 5 "$URL" >/dev/null 2>&1; then
  log "Panel PiPhi ponownie działa."
  exit 0
fi

log "Panel PiPhi nadal nie działa po próbie restartu. Sprawdzę przy kolejnym wywołaniu watchdoga."
exit 1
