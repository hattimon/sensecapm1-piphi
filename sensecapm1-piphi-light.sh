#!/usr/bin/env bash
set -euo pipefail

# PiPhi on SenseCAP M1 - light installer
# Target data dir:
BASE_DIR="/mnt/data/hattimon/piphi"
PG_VERSION_TAG="13.3"
POSTGRES_IMAGE="postgres:${PG_VERSION_TAG}"
PIPHI_IMAGE="piphinetwork/team-piphi:latest"
POSTGRES_PASSWORD="piphi31415"

# -------- Helpers --------

detect_ip() {
  # Prefer eth0, then wlan0, else first non-loopback
  if ip addr show eth0 >/dev/null 2>&1; then
    ip -4 addr show eth0 | awk '/inet / {print $2}' | cut -d/ -f1 | head -n1
  elif ip addr show wlan0 >/dev/null 2>&1; then
    ip -4 addr show wlan0 | awk '/inet / {print $2}' | cut -d/ -f1 | head -n1
  else
    ip -4 addr | awk '/inet / && $2 !~ /^127\./ {print $2}' | cut -d/ -f1 | head -n1
  fi
}

uninstall_piphi() {
  local lang="$1"

  if [ "$lang" = "en" ]; then
    echo "[*] Stopping and removing PiPhi containers (piphi-app, db)..."
  else
    echo "[*] Zatrzymywanie i usuwanie kontenerów PiPhi (piphi-app, db)..."
  fi

  balena stop piphi-app db 2>/dev/null || true
  balena rm piphi-app db 2>/dev/null || true

  if [ "$lang" = "en" ]; then
    echo "[*] Removing PiPhi data directory: ${BASE_DIR}"
  else
    echo "[*] Usuwanie katalogu danych PiPhi: ${BASE_DIR}"
  fi

  rm -rf "${BASE_DIR}"

  if [ "$lang" = "en" ]; then
    echo "[*] (Optional) You can run 'balena image prune -f' to reclaim unused image space."
    echo "[*] Uninstall complete. SenseCAP is back to pre-PiPhi state (Helium containers untouched)."
  else
    echo "[*] (Opcjonalnie) Możesz uruchomić 'balena image prune -f', aby odzyskać miejsce po obrazach."
    echo "[*] Deinstalacja zakończona. SenseCAP jest w stanie sprzed instalacji PiPhi (kontenery Helium niezmienione)."
  fi
}

install_piphi() {
  local lang="$1"

  if [ "$lang" = "en" ]; then
    echo "[*] Creating PiPhi data directories under ${BASE_DIR}..."
  else
    echo "[*] Tworzenie katalogów danych PiPhi w ${BASE_DIR}..."
  fi

  mkdir -p \
    "${BASE_DIR}/postgres-data" \
    "${BASE_DIR}/tsdb-data" \
    "${BASE_DIR}/logs"

  if [ "$lang" = "en" ]; then
    echo "[*] Pulling images: ${POSTGRES_IMAGE}, ${PIPHI_IMAGE}..."
  else
    echo "[*] Pobieranie obrazów: ${POSTGRES_IMAGE}, ${PIPHI_IMAGE}..."
  fi

  balena pull "${POSTGRES_IMAGE}"
  balena pull "${PIPHI_IMAGE}"

  if [ "$lang" = "en" ]; then
    echo "[*] Stopping/removing old PiPhi containers if they exist..."
  else
    echo "[*] Zatrzymywanie/usuwanie starych kontenerów PiPhi, jeśli istnieją..."
  fi

  balena stop piphi-app db 2>/dev/null || true
  balena rm piphi-app db 2>/dev/null || true

  if [ "$lang" = "en" ]; then
    echo "[*] Starting Postgres container 'db' with restart=always..."
  else
    echo "[*] Uruchamianie kontenera Postgres 'db' z restart=always..."
  fi

  balena run -d \
    --name db \
    --restart=always \
    -p 5432:5432 \
    -e POSTGRES_USER=postgres \
    -e POSTGRES_PASSWORD="${POSTGRES_PASSWORD}" \
    -e POSTGRES_DB=postgres \
    -v "${BASE_DIR}/postgres-data:/var/lib/postgresql/data" \
    "${POSTGRES_IMAGE}"

  if [ "$lang" = "en" ]; then
    echo "[*] Waiting 30 seconds for Postgres to initialize..."
  else
    echo "[*] Czekanie 30 sekund na inicjalizację Postgresa..."
  fi

  sleep 30

  if [ "$lang" = "en" ]; then
    echo "[*] Starting PiPhi container 'piphi-app' with restart=always..."
  else
    echo "[*] Uruchamianie kontenera PiPhi 'piphi-app' z restart=always..."
  fi

  balena run -d \
    --name piphi-app \
    --restart=always \
    -p 31415:31415 \
    --link db:db \
    -v "${BASE_DIR}/tsdb-data:/var/lib/piphi/tsdb" \
    -v "${BASE_DIR}/logs:/var/log/piphi" \
    "${PIPHI_IMAGE}"

  if [ "$lang" = "en" ]; then
    echo "[*] Current containers:"
  else
    echo "[*] Aktualna lista kontenerów:"
  fi
  balena ps

  if [ "$lang" = "en" ]; then
    echo "[*] Last 40 lines of PiPhi logs:"
  else
    echo "[*] Ostatnie 40 linii logów PiPhi:"
  fi
  balena logs piphi-app --tail=40 || true

  local ip
  ip="$(detect_ip || true)"

  if [ -n "$ip" ]; then
    if [ "$lang" = "en" ]; then
      echo
      echo "[*] PiPhi web panel should now be available at:"
      echo "    http://${ip}:31415"
      echo
    else
      echo
      echo "[*] Panel WWW PiPhi powinien być teraz dostępny pod adresem:"
      echo "    http://${ip}:31415"
      echo
    fi
  else
    if [ "$lang" = "en" ]; then
      echo "[!] Could not automatically detect IP address. Open PiPhi on http://<SenseCAP_IP>:31415"
    else
      echo "[!] Nie udało się automatycznie wykryć adresu IP. Otwórz PiPhi pod adresem http://<IP_SenseCAP>:31415"
    fi
  fi
}

# -------- Main flow: language + action --------

echo "============================================="
echo "  SenseCAP M1 - PiPhi light installer"
echo "============================================="
echo
echo "Select language / Wybierz język:"
echo "  1) English"
echo "  2) Polski"
echo
read -rp "[1/2]: " LANG_CHOICE

LANG="en"
if [ "${LANG_CHOICE:-1}" = "2" ]; then
  LANG="pl"
fi

if [ "$LANG" = "en" ]; then
  echo
  echo "[*] Choose action:"
  echo "  1) Install / update PiPhi"
  echo "  2) Uninstall PiPhi (remove containers and data)"
  echo
  read -rp "[1/2]: " ACTION
else
  echo
  echo "[*] Wybierz działanie:"
  echo "  1) Instalacja / aktualizacja PiPhi"
  echo "  2) Deinstalacja PiPhi (usunięcie kontenerów i danych)"
  echo
  read -rp "[1/2]: " ACTION
fi

case "${ACTION:-1}" in
  1)
    install_piphi "$LANG"
    ;;
  2)
    uninstall_piphi "$LANG"
    ;;
  *)
    if [ "$LANG" = "en" ]; then
      echo "[!] Invalid choice, exiting."
    else
      echo "[!] Nieprawidłowy wybór, wychodzę."
    fi
    exit 1
    ;;
esac
