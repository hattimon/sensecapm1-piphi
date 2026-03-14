#!/bin/bash
set -e

# --- Language selection / Wybór języka ---
echo "Select language / Wybierz język:"
echo "1) English"
echo "2) Polski"
read -rp "[1/2]: " LANG_CHOICE

case "$LANG_CHOICE" in
  2)
    LANG="pl"
    ;;
  *)
    LANG="en"
    ;;
esac

msg() {
  local key="$1"
  shift
  case "$key" in
    start)
      if [ "$LANG" = "pl" ]; then
        echo "[PiPhi] --- Drugi etap instalacji PiPhi (obrazy z tar) ---"
      else
        echo "[PiPhi] --- PiPhi installation stage 2 (images from tar) ---"
      fi
      ;;
    create_dir)
      if [ "$LANG" = "pl" ]; then
        echo "[PiPhi] Tworzę katalog $1 (jeśli nie istnieje)..."
      else
        echo "[PiPhi] Creating directory $1 (if it does not exist)..."
      fi
      ;;
    downloading)
      if [ "$LANG" = "pl" ]; then
        echo "[PiPhi] Pobieram obrazy *.tar z $1..."
      else
        echo "[PiPhi] Downloading *.tar images from $1..."
      fi
      ;;
    check_container)
      if [ "$LANG" = "pl" ]; then
        echo "[PiPhi] Sprawdzam, czy kontener ubuntu-piphi działa..."
      else
        echo "[PiPhi] Checking if ubuntu-piphi container is running..."
      fi
      ;;
    no_container)
      if [ "$LANG" = "pl" ]; then
        echo "[PiPhi] BŁĄD: kontener ubuntu-piphi nie jest uruchomiony."
        echo "[PiPhi] Uruchom najpierw główny instalator: install-piphi-sensecapm1.sh"
      else
        echo "[PiPhi] ERROR: ubuntu-piphi container is not running."
        echo "[PiPhi] Please run the main installer first: install-piphi-sensecapm1.sh"
      fi
      ;;
    inside_ubuntu_start)
      if [ "$LANG" = "pl" ]; then
        echo "[PiPhi] Uruchamiam dockerd, ładuję obrazy i startuję kontenery (wewnątrz ubuntu-piphi)..."
      else
        echo "[PiPhi] Starting dockerd, loading images and starting containers (inside ubuntu-piphi)..."
      fi
      ;;
    finished)
      if [ "$LANG" = "pl" ]; then
        echo "[PiPhi] Drugi etap instalacji zakończony – PiPhi powinno już działać."
      else
        echo "[PiPhi] Second installation stage finished – PiPhi should now be running."
      fi
      ;;
  esac
}

BASE_URL="http://91.197.91.141:1234"
HOST_PIPHI_DIR="/mnt/data/piphi"
CONTAINER_PIPHI_DIR="/piphi-network"

msg start

# --- host side: download tars to /mnt/data/piphi ---
msg create_dir "$HOST_PIPHI_DIR"
mkdir -p "${HOST_PIPHI_DIR}"
cd "${HOST_PIPHI_DIR}"

msg downloading "$BASE_URL"
wget -O postgres-13.3.tar       "${BASE_URL}/postgres-13.3.tar"
wget -O team-piphi-latest.tar   "${BASE_URL}/team-piphi-latest.tar"
wget -O watchtower-latest.tar   "${BASE_URL}/watchtower-latest.tar"
wget -O grafana-oss-latest.tar  "${BASE_URL}/grafana-oss-latest.tar"

msg check_container
if ! balena ps | grep -q "ubuntu-piphi"; then
  msg no_container
  exit 1
fi

msg inside_ubuntu_start

balena exec ubuntu-piphi sh -lc "
  set -e

  mkdir -p ${CONTAINER_PIPHI_DIR}
  cd ${CONTAINER_PIPHI_DIR}

  echo '[PiPhi] Copying tar files from host /mnt/data/piphi into container...'
  cp /mnt/data/piphi/postgres-13.3.tar .
  cp /mnt/data/piphi/team-piphi-latest.tar .
  cp /mnt/data/piphi/watchtower-latest.tar .
  cp /mnt/data/piphi/grafana-oss-latest.tar .

  if pgrep dockerd >/dev/null 2>&1; then
    echo '[PiPhi] Killing old dockerd...'
    pkill dockerd || true
    sleep 5
  fi
  rm -f /var/run/docker.pid

  echo '[PiPhi] Starting dockerd inside ubuntu-piphi...'
  dockerd --host=unix:///var/run/docker.sock > ${CONTAINER_PIPHI_DIR}/dockerd.log 2>&1 &
  sleep 10

  echo '[PiPhi] Loading images from tar...'
  docker load -i postgres-13.3.tar
  docker load -i team-piphi-latest.tar
  docker load -i watchtower-latest.tar
  docker load -i grafana-oss-latest.tar

  echo '[PiPhi] Current images in ubuntu-piphi:'
  docker images

  echo '[PiPhi] Starting db + grafana (from local images)...'
  docker compose -f docker-compose.yml up -d db grafana
  sleep 20

  echo '[PiPhi] Starting software + watchtower (from local images)...'
  docker compose -f docker-compose.yml up -d software watchtower
  sleep 10

  echo '[PiPhi] Containers after start:'
  docker ps
"

msg finished
