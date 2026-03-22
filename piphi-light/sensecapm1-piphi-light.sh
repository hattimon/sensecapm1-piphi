#!/usr/bin/env bash
set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

# PiPhi on SenseCAP M1 - light installer
BASE_DIR="/mnt/data/hattimon/piphi"
PG_VERSION_TAG="13.3"
POSTGRES_IMAGE="postgres:${PG_VERSION_TAG}"
PIPHI_IMAGE="piphinetwork/team-piphi:latest"
POSTGRES_PASSWORD="piphi31415"

# -------- Helpers --------

detect_ip() {
  ip route get 1.1.1.1 2>/dev/null | awk '/src/ {for (i=1;i<=NF;i++) if ($i=="src") {print $(i+1); exit}}'
}

uninstall_piphi() {
  local lang="$1"

  if [ "$lang" = "en" ]; then
    echo -e "${YELLOW}[*] Stopping and removing PiPhi containers (piphi-app, db)...${RESET}"
  else
    echo -e "${YELLOW}[*] Zatrzymywanie i usuwanie kontenerów PiPhi (piphi-app, db)...${RESET}"
  fi

  balena stop piphi-app db 2>/dev/null || true
  balena rm piphi-app db 2>/dev/null || true

  if [ "$lang" = "en" ]; then
    echo -e "${YELLOW}[*] Removing PiPhi data directory: ${BASE_DIR}${RESET}"
  else
    echo -e "${YELLOW}[*] Usuwanie katalogu danych PiPhi: ${BASE_DIR}${RESET}"
  fi

  rm -rf "${BASE_DIR}"

  if [ "$lang" = "en" ]; then
    echo -e "${GREEN}[*] Uninstall complete. SenseCAP is back to pre-PiPhi state (Helium containers untouched).${RESET}"
    echo -e "${BLUE}[*] Optional:${RESET} run 'balena image prune -f' to reclaim unused image space."
  else
    echo -e "${GREEN}[*] Deinstalacja zakończona. SenseCAP jest w stanie sprzed instalacji PiPhi (kontenery Helium niezmienione).${RESET}"
    echo -e "${BLUE}[*] Opcjonalnie:${RESET} uruchom 'balena image prune -f', aby odzyskać miejsce po obrazach."
  fi
}

install_piphi() {
  local lang="$1"

  if [ "$lang" = "en" ]; then
    echo -e "${YELLOW}[*] Creating PiPhi data directories under ${BASE_DIR}...${RESET}"
  else
    echo -e "${YELLOW}[*] Tworzenie katalogów danych PiPhi w ${BASE_DIR}...${RESET}"
  fi

  mkdir -p \
    "${BASE_DIR}/postgres-data" \
    "${BASE_DIR}/tsdb-data" \
    "${BASE_DIR}/logs"

  if [ "$lang" = "en" ]; then
    echo -e "${YELLOW}[*] Pulling images: ${POSTGRES_IMAGE}, ${PIPHI_IMAGE}...${RESET}"
  else
    echo -e "${YELLOW}[*] Pobieranie obrazów: ${POSTGRES_IMAGE}, ${PIPHI_IMAGE}...${RESET}"
  fi

  balena pull "${POSTGRES_IMAGE}"
  balena pull "${PIPHI_IMAGE}"

  if [ "$lang" = "en" ]; then
    echo -e "${YELLOW}[*] Stopping/removing old PiPhi containers if they exist...${RESET}"
  else
    echo -e "${YELLOW}[*] Zatrzymywanie/usuwanie starych kontenerów PiPhi, jeśli istnieją...${RESET}"
  fi

  balena stop piphi-app db 2>/dev/null || true
  balena rm piphi-app db 2>/dev/null || true

  if [ "$lang" = "en" ]; then
    echo -e "${YELLOW}[*] Starting Postgres container 'db' with restart=always...${RESET}"
  else
    echo -e "${YELLOW}[*] Uruchamianie kontenera Postgres 'db' z restart=always...${RESET}"
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
    echo -e "${YELLOW}[*] Waiting 30 seconds for Postgres to initialize...${RESET}"
  else
    echo -e "${YELLOW}[*] Czekanie 30 sekund na inicjalizację Postgresa...${RESET}"
  fi

  sleep 30

  if [ "$lang" = "en" ]; then
    echo -e "${YELLOW}[*] Starting PiPhi container 'piphi-app' with restart=always...${RESET}"
  else
    echo -e "${YELLOW}[*] Uruchamianie kontenera PiPhi 'piphi-app' z restart=always...${RESET}"
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
    echo -e "${CYAN}[*] Current containers:${RESET}"
  else
    echo -e "${CYAN}[*] Aktualna lista kontenerów:${RESET}"
  fi
  balena ps

  if [ "$lang" = "en" ]; then
    echo -e "${CYAN}[*] Last 40 lines of PiPhi logs:${RESET}"
  else
    echo -e "${CYAN}[*] Ostatnie 40 linii logów PiPhi:${RESET}"
  fi
  balena logs piphi-app --tail=40 || true

  local ip
  ip="$(detect_ip || true)"

  if [ -n "$ip" ]; then
    if [ "$lang" = "en" ]; then
      echo
      echo -e "${CYAN}=============================================${RESET}"
      echo -e "${BOLD}${GREEN}   PiPhi installation completed successfully${RESET}"
      echo -e "${CYAN}=============================================${RESET}"
      echo
      echo -e "${BOLD}   Web panel address:${RESET}"
      echo -e "     ${YELLOW}http://${ip}:31415${RESET}"
      echo
      echo -e "${BLUE}   Next steps:${RESET}"
      echo "     - Open the URL above in your browser"
      echo "     - Complete the initial PiPhi configuration"
      echo
    else
      echo
      echo -e "${CYAN}=============================================${RESET}"
      echo -e "${BOLD}${GREEN}   Instalacja PiPhi zakończona pomyślnie${RESET}"
      echo -e "${CYAN}=============================================${RESET}"
      echo
      echo -e "${BOLD}   Adres panelu WWW:${RESET}"
      echo -e "     ${YELLOW}http://${ip}:31415${RESET}"
      echo
      echo -e "${BLUE}   Kolejne kroki:${RESET}"
      echo "     - Otwórz powyższy adres w przeglądarce"
      echo "     - Dokończ wstępną konfigurację PiPhi"
      echo
    fi
  else
    if [ "$lang" = "en" ]; then
      echo -e "${RED}[!] Could not automatically detect IP address.${RESET}"
      echo    "    Open PiPhi on: http://<SenseCAP_IP>:31415"
    else
      echo -e "${RED}[!] Nie udało się automatycznie wykryć adresu IP.${RESET}"
      echo    "    Otwórz PiPhi pod adresem: http://<IP_SenseCAP>:31415"
    fi
  fi
}

# -------- Main flow: language + action --------

echo -e "${CYAN}=============================================${RESET}"
echo -e "${BOLD}  SenseCAP M1 - PiPhi light installer${RESET}"
echo -e "${CYAN}=============================================${RESET}"
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
      echo -e "${RED}[!] Invalid choice, exiting.${RESET}"
    else
      echo -e "${RED}[!] Nieprawidłowy wybór, wychodzę.${RESET}"
    fi
    exit 1
    ;;
esac
