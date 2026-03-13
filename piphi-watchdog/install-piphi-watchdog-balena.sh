#!/bin/bash
# PiPhi Watchdog installer for balenaOS (SenseCAP M1)
# Version: 2.0 (EN default, optional PL)
# - Builds Alpine image with docker-cli + curl + watchdog.sh
# - Runs piphi-watchdog container on balenaOS host (balena-engine)

set -e

INSTALL_DIR="/mnt/data/piphi-watchdog-balena"
IMAGE_NAME="piphi-watchdog-balena:latest"
CONTAINER_NAME="piphi-watchdog"
UBUNTU_PIPHI_NAME="ubuntu-piphi"
PIPHI_PORT="31415"
CHECK_INTERVAL="60"   # seconds between checks AFTER warmup
BOOT_DELAY="600"      # 10 minutes after host boot / restart

# ===== LANGUAGE SELECTION =====

LANGUAGE="en"

echo "========================================"
echo "PiPhi Watchdog installer for balenaOS"
echo "========================================"
echo "Select language / Wybierz język:"
echo "1) English (default)"
echo "2) Polski"
read -rp "Choice [1/2]: " LANG_CHOICE

case "$LANG_CHOICE" in
  2)
    LANGUAGE="pl"
    ;;
  *)
    LANGUAGE="en"
    ;;
esac

if [ "$LANGUAGE" = "pl" ]; then
  echo "Wybrano język: polski"
else
  echo "Selected language: English"
fi

echo

if [ "$LANGUAGE" = "pl" ]; then
  echo "=== Instalator PiPhi Watchdog (balenaOS) ==="
  echo "Katalog instalacyjny: $INSTALL_DIR"
else
  echo "=== PiPhi Watchdog installer (balenaOS) ==="
  echo "Install directory: $INSTALL_DIR"
fi

mkdir -p "$INSTALL_DIR"
cd "$INSTALL_DIR"

if [ "$LANGUAGE" = "pl" ]; then
  echo "===> Tworzę watchdog.sh..."
else
  echo "===> Creating watchdog.sh..."
fi

cat > watchdog.sh << 'EOF'
#!/bin/sh
set -e

PIPHI_PORT="${PIPHI_PORT:-31415}"
CHECK_INTERVAL="${CHECK_INTERVAL:-60}"    # seconds between checks (after warmup)
BOOT_DELAY="${BOOT_DELAY:-600}"           # seconds after host boot (e.g. 600 = 10 min)
UBUNTU_PIPHI_NAME="${UBUNTU_PIPHI_NAME:-ubuntu-piphi}"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

# Warmup after host boot – Docker inside ubuntu-piphi, PiPhi stack, GPS need time
log "Initial boot delay: ${BOOT_DELAY}s (waiting for docker + PiPhi + GPS)..."
sleep "$BOOT_DELAY"

consecutive_failures=0
MAX_FAIL_BEFORE_RESTART=3

while true; do
  URL="http://127.0.0.1:${PIPHI_PORT}/"
  log "Checking PiPhi panel at: $URL"

  if curl -s --max-time 5 "$URL" >/dev/null 2>&1; then
    log "PiPhi panel is UP."
    consecutive_failures=0
  else
    log "PiPhi panel is DOWN. Attempting recovery via balena exec..."

    # host diagnostics
    docker ps || true

    # ensure ubuntu-piphi is UP (restart if needed)
    if ! docker ps --format '{{.Names}}' | grep -q "^${UBUNTU_PIPHI_NAME}$"; then
      log "${UBUNTU_PIPHI_NAME} is not running – trying to start it..."
      docker restart "${UBUNTU_PIPHI_NAME}" || true
      sleep 10
    fi

    consecutive_failures=$((consecutive_failures + 1))
    log "Consecutive failures: ${consecutive_failures}/${MAX_FAIL_BEFORE_RESTART}"

    if [ "$consecutive_failures" -ge "$MAX_FAIL_BEFORE_RESTART" ]; then
      log "Running start-piphi.sh in ${UBUNTU_PIPHI_NAME} (dockerd + PiPhi + GPS)..."
      docker exec "${UBUNTU_PIPHI_NAME}" sh -lc 'cd /piphi-network && ./start-piphi.sh' \
        || log "start-piphi.sh returned an error"

      # after a restart, give system some time (shorter than initial BOOT_DELAY)
      POST_RESTART_DELAY=300  # 5 minutes
      log "Waiting ${POST_RESTART_DELAY}s after restart for panel to come up..."
      sleep "$POST_RESTART_DELAY"

      if curl -s --max-time 5 "$URL" >/dev/null 2>&1; then
        log "PiPhi panel is UP after recovery."
        consecutive_failures=0
      else
        log "PiPhi panel still DOWN after recovery attempt."
        # do not hammer endlessly – keep failure counter, next loop will try again
      fi
    else
      log "PiPhi panel DOWN but below restart threshold – will re-check in ${CHECK_INTERVAL}s."
    fi
  fi

  sleep "$CHECK_INTERVAL"
done
EOF
chmod +x watchdog.sh

if [ "$LANGUAGE" = "pl" ]; then
  echo "===> Tworzę Dockerfile..."
else
  echo "===> Creating Dockerfile..."
fi

cat > Dockerfile << 'EOF'
FROM alpine:3.19

RUN apk add --no-cache docker-cli curl

WORKDIR /usr/src/app

COPY watchdog.sh /usr/src/app/watchdog.sh

RUN chmod +x /usr/src/app/watchdog.sh

CMD ["/usr/src/app/watchdog.sh"]
EOF

if [ "$LANGUAGE" = "pl" ]; then
  echo "===> Buduję obraz $IMAGE_NAME (balena build) ..."
else
  echo "===> Building image $IMAGE_NAME (balena build) ..."
fi
balena build . -t "$IMAGE_NAME"

if [ "$LANGUAGE" = "pl" ]; then
  echo "===> Zatrzymuję stary kontener (jeśli istnieje)..."
else
  echo "===> Removing old container (if exists)..."
fi
balena rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true

if [ "$LANGUAGE" = "pl" ]; then
  echo "===> Uruchamiam nowy kontener watchdog: $CONTAINER_NAME"
else
  echo "===> Starting new watchdog container: $CONTAINER_NAME"
fi

balena run -d \
  --name "$CONTAINER_NAME" \
  --restart unless-stopped \
  --net host \
  -e PIPHI_PORT="$PIPHI_PORT" \
  -e CHECK_INTERVAL="$CHECK_INTERVAL" \
  -e BOOT_DELAY="$BOOT_DELAY" \
  -e UBUNTU_PIPHI_NAME="$UBUNTU_PIPHI_NAME" \
  -v /run/balena-engine.sock:/var/run/docker.sock \
  -e DOCKER_HOST="unix:///var/run/docker.sock" \
  "$IMAGE_NAME"

if [ "$LANGUAGE" = "pl" ]; then
  echo "=== Gotowe. Logi watchdoga: balena logs -f $CONTAINER_NAME"
else
  echo "=== Done. Watchdog logs: balena logs -f $CONTAINER_NAME"
fi
