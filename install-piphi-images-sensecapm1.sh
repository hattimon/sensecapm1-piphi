#!/bin/bash
set -e

BASE_URL="http://91.197.91.141:1234"
PIPHI_DIR="/mnt/data/piphi"

echo "[PiPhi] --- Drugi etap instalacji PiPhi (obrazy z tar) ---"

echo "[PiPhi] Tworzę katalog ${PIPHI_DIR} (jeśli nie istnieje)..."
mkdir -p "${PIPHI_DIR}"
cd "${PIPHI_DIR}"

echo "[PiPhi] Pobieram obrazy *.tar z ${BASE_URL}..."
wget -O postgres-13.3.tar       "${BASE_URL}/postgres-13.3.tar"
wget -O team-piphi-latest.tar   "${BASE_URL}/team-piphi-latest.tar"
wget -O watchtower-latest.tar   "${BASE_URL}/watchtower-latest.tar"
wget -O grafana-oss-latest.tar  "${BASE_URL}/grafana-oss-latest.tar"

echo "[PiPhi] Sprawdzam, czy kontener ubuntu-piphi działa..."
if ! balena ps | grep -q "ubuntu-piphi"; then
  echo "[PiPhi] BŁĄD: kontener ubuntu-piphi nie jest uruchomiony."
  echo "[PiPhi] Uruchom najpierw główny instalator: install-piphi-sensecapm1.sh"
  exit 1
fi

echo "[PiPhi] Ładuję obrazy i startuję PiPhi wewnątrz ubuntu-piphi..."
balena exec ubuntu-piphi sh -lc "
  set -e
  cd ${PIPHI_DIR}

  if pgrep dockerd >/dev/null 2>&1; then
    echo '[PiPhi] Ubijam stary dockerd...'
    pkill dockerd || true
    sleep 5
  fi
  rm -f /var/run/docker.pid

  echo '[PiPhi] Start dockerd w ubuntu-piphi...'
  dockerd --host=unix:///var/run/docker.sock > ${PIPHI_DIR}/dockerd.log 2>&1 &
  sleep 10

  echo '[PiPhi] docker load z tarów...'
  docker load -i postgres-13.3.tar
  docker load -i team-piphi-latest.tar
  docker load -i watchtower-latest.tar
  docker load -i grafana-oss-latest.tar

  echo '[PiPhi] Aktualne obrazy w ubuntu-piphi:'
  docker images

  echo '[PiPhi] Start db + grafana (z lokalnych obrazów)...'
  docker compose -f docker-compose.yml up -d db grafana
  sleep 20

  echo '[PiPhi] Start software + watchtower (z lokalnych obrazów)...'
  docker compose -f docker-compose.yml up -d software watchtower
  sleep 10

  echo '[PiPhi] Kontenery po starcie:'
  docker ps
"

echo "[PiPhi] Drugi etap instalacji zakończony – PiPhi powinno już działać."
