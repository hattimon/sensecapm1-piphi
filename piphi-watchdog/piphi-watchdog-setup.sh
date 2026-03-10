#!/usr/bin/env bash
set -e

# Kolory
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
CYAN='\e[36m'
BOLD='\e[1m'
RESET='\e[0m'

LOGFILE="$HOME/piphi-watchdog-setup.log"

log() {
  echo -e "$@" | tee -a "$LOGFILE"
}

section() {
  local title="$1"
  echo -e "\n${CYAN}${BOLD}===== [SEKCJA] $title =====${RESET}\n" | tee -a "$LOGFILE"
}

confirm() {
  local prompt="$1"
  local default="${2:-y}"
  local ans
  echo -ne "${YELLOW}$prompt [y/n] (domyślnie: $default): ${RESET}"
  read ans
  ans="${ans:-$default}"
  if [[ "$ans" =~ ^[Yy]$ ]]; then
    return 0
  else
    return 1
  fi
}

AUTO_MODE=0

section "WSTĘP"
log "${GREEN}Ten skrypt skonfiguruje ssh-agent, załaduje klucz SenseCAP, utworzy watchdog PiPhi (systemd) i zapisze konfigurację pingowania panelu.${RESET}"
log "Log z przebiegu: $LOGFILE"
log "Uruchamiaj jako użytkownik ${BOLD}pi${RESET} na Raspberry Pi."

if confirm "Czy chcesz użyć w pełni automatycznego trybu (minimalna liczba pytań)?" "y"; then
  AUTO_MODE=1
  log "${GREEN}Wybrano tryb automatyczny.${RESET}"
else
  log "${YELLOW}Wybrano tryb krok-po-kroku.${RESET}"
fi

# =========================
# SEKCJA 1: Walidacja środowiska
# =========================
section "1. Walidacja środowiska"

if [[ "$USER" != "pi" ]]; then
  log "${RED}Uwaga: ten skrypt jest zaprojektowany dla użytkownika 'pi', a teraz jest: '$USER'.${RESET}"
  if ! confirm "Kontynuować mimo to?"; then
    log "${RED}Przerywam.${RESET}"
    exit 1
  fi
fi

for bin in systemctl ssh-agent ssh-add ssh; do
  if ! command -v "$bin" >/dev/null 2>&1; then
    log "${RED}Brak wymaganej komendy: $bin. Zainstaluj odpowiednie pakiety i spróbuj ponownie.${RESET}"
    exit 1
  fi
done

if ! command -v curl >/dev/null 2>&1; then
  log "${YELLOW}Brak 'curl' – instaluję (wymagane do pingowania panelu PiPhi)...${RESET}"
  if command -v sudo >/dev/null 2>&1; then
    sudo apt-get update && sudo apt-get install -y curl
  else
    log "${RED}Brak curl i sudo – zainstaluj curl ręcznie i uruchom skrypt ponownie.${RESET}"
    exit 1
  fi
fi

# =========================
# SEKCJA 2: Ścieżki, IP SenseCAP i port PiPhi
# =========================
section "2. Ścieżki, IP SenseCAP i port PiPhi"

KEY_PATH_DEFAULT="$HOME/.ssh/sensecap_root"
WATCHDOG_PATH_DEFAULT="$HOME/piphi-watchdog.sh"
CONF_DIR="$HOME/.config"
CONF_FILE="$CONF_DIR/piphi-watchdog.conf"

SENSECAP_HOST_DEFAULT="192.168.0.56"
PIPHI_PORT_DEFAULT="31415"

if [[ $AUTO_MODE -eq 1 ]]; then
  SSH_KEY_PATH="$KEY_PATH_DEFAULT"
  WATCHDOG_PATH="$WATCHDOG_PATH_DEFAULT"
  SENSECAP_HOST="$SENSECAP_HOST_DEFAULT"
  PIPHI_PORT="$PIPHI_PORT_DEFAULT"
else
  echo -ne "${YELLOW}Podaj ścieżkę do klucza SSH dla sensecap_root [domyślnie: $KEY_PATH_DEFAULT]: ${RESET}"
  read SSH_KEY_PATH
  SSH_KEY_PATH="${SSH_KEY_PATH:-$KEY_PATH_DEFAULT}"

  echo -ne "${YELLOW}Podaj ścieżkę do skryptu piphi-watchdog.sh [domyślnie: $WATCHDOG_PATH_DEFAULT]: ${RESET}"
  read WATCHDOG_PATH
  WATCHDOG_PATH="${WATCHDOG_PATH:-$WATCHDOG_PATH_DEFAULT}"

  echo -ne "${YELLOW}IP lub hostname SenseCAP (host balena, gdzie stoi PiPhi) [domyślnie: $SENSECAP_HOST_DEFAULT]: ${RESET}"
  read SENSECAP_HOST
  SENSECAP_HOST="${SENSECAP_HOST:-$SENSECAP_HOST_DEFAULT}"

  echo -ne "${YELLOW}Port HTTP panelu PiPhi na SenseCAP [domyślnie: $PIPHI_PORT_DEFAULT]: ${RESET}"
  read PIPHI_PORT
  PIPHI_PORT="${PIPHI_PORT:-$PIPHI_PORT_DEFAULT}"
fi

SSH_KEY_PATH="${SSH_KEY_PATH:-$KEY_PATH_DEFAULT}"
WATCHDOG_PATH="${WATCHDOG_PATH:-$WATCHDOG_PATH_DEFAULT}"
SENSECAP_HOST="${SENSECAP_HOST:-$SENSECAP_HOST_DEFAULT}"
PIPHI_PORT="${PIPHI_PORT:-$PIPHI_PORT_DEFAULT}"

if [[ ! -f "$SSH_KEY_PATH" ]]; then
  log "${RED}Plik klucza SSH nie istnieje: $SSH_KEY_PATH${RESET}"
  exit 1
fi

mkdir -p "$(dirname "$WATCHDOG_PATH")"
mkdir -p "$CONF_DIR"

log "${GREEN}Klucz SSH: ${BOLD}$SSH_KEY_PATH${RESET}"
log "${GREEN}Docelowy skrypt watchdog: ${BOLD}$WATCHDOG_PATH${RESET}"
log "${GREEN}SenseCAP host: ${BOLD}$SENSECAP_HOST${RESET}"
log "${GREEN}Port panelu PiPhi: ${BOLD}$PIPHI_PORT${RESET}"

# =========================
# SEKCJA 3: Zapis konfiguracji do ~/.config/piphi-watchdog.conf
# =========================
section "3. Zapis konfiguracji do $CONF_FILE"

if [[ $AUTO_MODE -eq 1 ]]; then
  BOOT_DELAY="300"
  RETRY_DELAY="60"
  RESTORE_INTERVAL="600"
else
  echo -ne "${YELLOW}Opóźnienie po starcie SenseCAP przed próbą startu panelu (sekundy, domyślnie 300): ${RESET}"
  read BOOT_DELAY
  BOOT_DELAY="${BOOT_DELAY:-300}"

  echo -ne "${YELLOW}Przerwa między kolejnymi próbami naprawy (sekundy, domyślnie 60): ${RESET}"
  read RETRY_DELAY
  RETRY_DELAY="${RETRY_DELAY:-60}"

  echo -ne "${YELLOW}Okres między wywołaniami watchdoga (sekundy, domyślnie 600): ${RESET}"
  read RESTORE_INTERVAL
  RESTORE_INTERVAL="${RESTORE_INTERVAL:-600}"
fi

cat > "$CONF_FILE" <<EOF
# Konfiguracja PiPhi Watchdog
SENSECAP_HOST="$SENSECAP_HOST"
SENSECAP_PORT="$PIPHI_PORT"
SENSECAP_SSH_USER="sensecap_root"
SENSECAP_SSH_PORT="22222"

BOOT_DELAY="$BOOT_DELAY"
RETRY_DELAY="$RETRY_DELAY"
RESTORE_INTERVAL="$RESTORE_INTERVAL"

SSH_KEY_PATH="$SSH_KEY_PATH"
EOF

log "${GREEN}Konfiguracja zapisana w: ${BOLD}$CONF_FILE${RESET}"

# =========================
# SEKCJA 4: Generacja szablonu piphi-watchdog.sh (jeśli brak)
# =========================
section "4. Generacja szablonu piphi-watchdog.sh (jeśli brak)"

if [[ -f "$WATCHDOG_PATH" ]]; then
  log "${YELLOW}Skrypt $WATCHDOG_PATH już istnieje – NIE nadpisuję.${RESET}"
else
  cat > "$WATCHDOG_PATH" <<'EOF'
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

# 2. Próba połączenia SSH (ssh użyje ssh-agent, bez -i)
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
EOF

  chmod +x "$WATCHDOG_PATH"
  log "${GREEN}Utworzono szablon skryptu: ${BOLD}$WATCHDOG_PATH${RESET}"
fi

# =========================
# SEKCJA 5: Usługa ssh-agent (systemd --user)
# =========================
section "5. Konfiguracja systemd user service: ssh-agent"

SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
mkdir -p "$SYSTEMD_USER_DIR"

SSH_AGENT_SERVICE="$SYSTEMD_USER_DIR/ssh-agent.service"

cat > "$SSH_AGENT_SERVICE" <<EOF
[Unit]
Description=SSH key agent

[Service]
Type=simple
Environment=SSH_AUTH_SOCK=%t/ssh-agent.socket
ExecStart=/usr/bin/ssh-agent -D -a \$SSH_AUTH_SOCK

[Install]
WantedBy=default.target
EOF

log "${GREEN}Zapisano: $SSH_AGENT_SERVICE${RESET}"

systemctl --user daemon-reload
systemctl --user enable --now ssh-agent.service

sleep 1
if systemctl --user is-active --quiet ssh-agent.service; then
  log "${GREEN}ssh-agent.service jest aktywny.${RESET}"
else
  log "${RED}ssh-agent.service NIE jest aktywny. Sprawdź status: systemctl --user status ssh-agent.service${RESET}"
  exit 1
fi

# =========================
# SEKCJA 6: SSH_AUTH_SOCK w ~/.profile
# =========================
section "6. Ustawienie SSH_AUTH_SOCK w ~/.profile"

PROFILE_FILE="$HOME/.profile"
LINE_EXPORT='export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"'

if grep -q 'SSH_AUTH_SOCK=.*ssh-agent.socket' "$PROFILE_FILE" 2>/dev/null; then
  log "${YELLOW}Wygląda na to, że SSH_AUTH_SOCK jest już ustawiony w $PROFILE_FILE.${RESET}"
else
  {
    echo ""
    echo "# ssh-agent via systemd user service"
    echo "$LINE_EXPORT"
  } >> "$PROFILE_FILE"
  log "${GREEN}Dodano ustawienie SSH_AUTH_SOCK do $PROFILE_FILE.${RESET}"
fi

export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
log "${GREEN}Ustawiono SSH_AUTH_SOCK dla bieżącej sesji: $SSH_AUTH_SOCK${RESET}"

# =========================
# SEKCJA 7: Dodanie klucza do ssh-agent
# =========================
section "7. Dodawanie klucza SenseCAP do ssh-agent"

log "${GREEN}Za chwilę zostaniesz poproszony o passphrase do klucza: $SSH_KEY_PATH${RESET}"
log "To jest dodanie klucza do agenta (ssh-agent)."

if ssh-add "$SSH_KEY_PATH"; then
  log "${GREEN}Klucz został pomyślnie dodany do ssh-agent.${RESET}"
else
  log "${RED}Nie udało się dodać klucza do ssh-agent. Sprawdź passphrase lub plik klucza.${RESET}"
  exit 1
fi

log "${GREEN}Aktualne klucze w ssh-agent:${RESET}"
ssh-add -l || log "${YELLOW}Brak kluczy (coś poszło nie tak z ssh-add).${RESET}"

# =========================
# SEKCJA 8: Usługa piphi-watchdog.service
# =========================
section "8. Konfiguracja piphi-watchdog.service"

PIPHI_SERVICE="$SYSTEMD_USER_DIR/piphi-watchdog.service"

cat > "$PIPHI_SERVICE" <<EOF
[Unit]
Description=PiPhi watchdog

[Service]
Type=oneshot
Environment=SSH_AUTH_SOCK=%t/ssh-agent.socket
WorkingDirectory=$HOME
ExecStart=$WATCHDOG_PATH
EOF

log "${GREEN}Zapisano: $PIPHI_SERVICE${RESET}"

# =========================
# SEKCJA 9: Timer piphi-watchdog.timer
# =========================
section "9. Konfiguracja piphi-watchdog.timer"

INTERVAL_SEC="$RESTORE_INTERVAL"
if [[ "$INTERVAL_SEC" -lt 60 ]]; then
  ON_ACTIVE="${INTERVAL_SEC}s"
else
  MIN=$((INTERVAL_SEC / 60))
  ON_ACTIVE="${MIN}min"
fi

BOOT_DELAY_SEC="$BOOT_DELAY"
if [[ "$BOOT_DELAY_SEC" -lt 60 ]]; then
  ON_BOOT="${BOOT_DELAY_SEC}s"
else
  MINB=$((BOOT_DELAY_SEC / 60))
  ON_BOOT="${MINB}min"
fi

PIPHI_TIMER="$SYSTEMD_USER_DIR/piphi-watchdog.timer"

cat > "$PIPHI_TIMER" <<EOF
[Unit]
Description=Run PiPhi watchdog periodically

[Timer]
OnBootSec=$ON_BOOT
OnUnitActiveSec=$ON_ACTIVE
Unit=piphi-watchdog.service

[Install]
WantedBy=default.target
EOF

log "${GREEN}Zapisano: $PIPHI_TIMER${RESET}"

systemctl --user daemon-reload
systemctl --user enable --now piphi-watchdog.timer

sleep 1
systemctl --user list-timers --all | tee -a "$LOGFILE"

# =========================
# SEKCJA 10: Ręczny test watchdoga
# =========================
section "10. Ręczny test piphi-watchdog (opcjonalny)"

if confirm "Czy chcesz teraz ręcznie uruchomić piphi-watchdog.service do testu?" "y"; then
  systemctl --user start piphi-watchdog.service
  sleep 3
  systemctl --user status piphi-watchdog.service --no-pager || true
  log "${GREEN}Sprawdź też log: $HOME/piphi-watchdog-run.log${RESET}"
else
  log "${YELLOW}Pominięto ręczny test usługi.${RESET}"
fi

# =========================
# SEKCJA 11: Podsumowanie
# =========================
section "11. Podsumowanie"

log "${GREEN}Konfiguracja zakończona.${RESET}"
log "Plik konfiguracyjny: $CONF_FILE"
log "Skrypt watchdoga: $WATCHDOG_PATH"
log "Usługi user-level: ssh-agent.service, piphi-watchdog.service, piphi-watchdog.timer"
log "Po restarcie RPi systemd --user uruchomi ssh-agent i timer, który co $ON_ACTIVE będzie odpalał watchdoga."
log "Log z instalacji: $LOGFILE"
