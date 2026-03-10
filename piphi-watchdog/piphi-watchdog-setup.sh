#!/usr/bin/env bash
set -e

# Colors
RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
CYAN='\e[36m'
BOLD='\e[1m'
RESET='\e[0m'

LOGFILE="$HOME/piphi-watchdog-setup.log"
LANG_CHOICE="en"  # default

log() {
  echo -e "$@" | tee -a "$LOGFILE"
}

section() {
  local title="$1"
  echo -e "\n${CYAN}${BOLD}===== [SECTION] $title =====${RESET}\n" | tee -a "$LOGFILE"
}

confirm() {
  local prompt_en="$1"
  local prompt_pl="$2"
  local default="${3:-y}"
  local ans
  local prompt
  if [[ "$LANG_CHOICE" == "pl" ]]; then
    prompt="$prompt_pl"
  else
    prompt="$prompt_en"
  fi
  echo -ne "${YELLOW}$prompt [y/n] (default: $default): ${RESET}"
  read ans
  ans="${ans:-$default}"
  if [[ "$ans" =~ ^[Yy]$ ]]; then
    return 0
  else
    return 1
  fi
}

ask() {
  local prompt_en="$1"
  local prompt_pl="$2"
  local default="$3"
  local var
  local prompt
  if [[ "$LANG_CHOICE" == "pl" ]]; then
    prompt="$prompt_pl"
  else
    prompt="$prompt_en"
  fi
  echo -ne "${YELLOW}$prompt [default: $default]: ${RESET}"
  read var
  var="${var:-$default}"
  echo "$var"
}

AUTO_MODE=0

# =========================
# LANGUAGE SELECTION
# =========================
echo -e "${CYAN}${BOLD}===== PiPhi Watchdog setup =====${RESET}"
echo -e "${YELLOW}Select language / Wybierz język:${RESET}"
echo "  1) English (default)"
echo "  2) Polski"
echo -ne "${YELLOW}Choice / Wybór [1/2] (default: 1): ${RESET}"
read lang_sel
lang_sel="${lang_sel:-1}"
if [[ "$lang_sel" == "2" ]]; then
  LANG_CHOICE="pl"
else
  LANG_CHOICE="en"
fi

# =========================
# INTRO
# =========================
if [[ "$LANG_CHOICE" == "pl" ]]; then
  section "WSTĘP"
  log "${GREEN}Ten skrypt skonfiguruje ssh-agent, załaduje klucz SenseCAP, utworzy watchdog PiPhi (systemd) i zapisze konfigurację pingowania panelu.${RESET}"
  log "Log z przebiegu: $LOGFILE"
  log "Uruchamiaj jako użytkownik ${BOLD}pi${RESET} na Raspberry Pi."
else
  section "INTRO"
  log "${GREEN}This script configures ssh-agent, loads the SenseCAP key, sets up the PiPhi watchdog (systemd) and saves HTTP panel monitoring configuration.${RESET}"
  log "Log file: $LOGFILE"
  log "Run as user ${BOLD}pi${RESET} on a Raspberry Pi."
fi

if confirm \
  "Use fully automatic mode (minimal questions)?" \
  "Czy chcesz użyć trybu automatycznego (minimum pytań)?" \
  "y"; then
  AUTO_MODE=1
  if [[ "$LANG_CHOICE" == "pl" ]]; then
    log "${GREEN}Wybrano tryb automatyczny.${RESET}"
  else
    log "${GREEN}Automatic mode selected.${RESET}"
  fi
else
  if [[ "$LANG_CHOICE" == "pl" ]]; then
    log "${YELLOW}Wybrano tryb krok-po-kroku.${RESET}"
  else
    log "${YELLOW}Step-by-step mode selected.${RESET}"
  fi
fi

# =========================
# 1: ENV CHECK
# =========================
if [[ "$LANG_CHOICE" == "pl" ]]; then
  section "1. Walidacja środowiska"
else
  section "1. Environment validation"
fi

if [[ "$USER" != "pi" ]]; then
  if [[ "$LANG_CHOICE" == "pl" ]]; then
    log "${RED}Uwaga: skrypt jest zaprojektowany dla użytkownika 'pi', a teraz jest: '$USER'.${RESET}"
  else
    log "${RED}Warning: this script is designed for user 'pi', current user is '$USER'.${RESET}"
  fi
  if ! confirm \
    "Continue anyway?" \
    "Kontynuować mimo to?" \
    "n"; then
    if [[ "$LANG_CHOICE" == "pl" ]]; then
      log "${RED}Przerywam.${RESET}"
    else
      log "${RED}Aborting.${RESET}"
    fi
    exit 1
  fi
fi

for bin in systemctl ssh-agent ssh-add ssh; do
  if ! command -v "$bin" >/dev/null 2>&1; then
    if [[ "$LANG_CHOICE" == "pl" ]]; then
      log "${RED}Brak wymaganej komendy: $bin. Zainstaluj pakiety i spróbuj ponownie.${RESET}"
    else
      log "${RED}Missing required command: $bin. Install packages and try again.${RESET}"
    fi
    exit 1
  fi
done

if ! command -v curl >/dev/null 2>&1; then
  if [[ "$LANG_CHOICE" == "pl" ]]; then
    log "${YELLOW}Brak 'curl' – instaluję (wymagane do pingowania panelu PiPhi)...${RESET}"
  else
    log "${YELLOW}'curl' not found – installing (required for HTTP checks)...${RESET}"
  fi
  if command -v sudo >/dev/null 2>&1; then
    sudo apt-get update && sudo apt-get install -y curl
  else
    if [[ "$LANG_CHOICE" == "pl" ]]; then
      log "${RED}Brak curl i sudo – zainstaluj curl ręcznie i uruchom skrypt ponownie.${RESET}"
    else
      log "${RED}No curl and no sudo – install curl manually and rerun the script.${RESET}"
    fi
    exit 1
  fi
fi

# =========================
# 2: PATHS, IP, PORT
# =========================
if [[ "$LANG_CHOICE" == "pl" ]]; then
  section "2. Ścieżki, IP SenseCAP i port PiPhi"
else
  section "2. Paths, SenseCAP IP and PiPhi port"
fi

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
  SSH_KEY_PATH=$(ask \
    "Path to SSH key for sensecap_root" \
    "Ścieżka do klucza SSH dla sensecap_root" \
    "$KEY_PATH_DEFAULT")
  WATCHDOG_PATH=$(ask \
    "Path for piphi-watchdog.sh" \
    "Ścieżka do skryptu piphi-watchdog.sh" \
    "$WATCHDOG_PATH_DEFAULT")
  SENSECAP_HOST=$(ask \
    "SenseCAP host/IP (balena host with PiPhi)" \
    "IP lub hostname SenseCAP (host balena z PiPhi)" \
    "$SENSECAP_HOST_DEFAULT")
  PIPHI_PORT=$(ask \
    "PiPhi panel HTTP port on SenseCAP" \
    "Port HTTP panelu PiPhi na SenseCAP" \
    "$PIPHI_PORT_DEFAULT")
fi

SSH_KEY_PATH="${SSH_KEY_PATH:-$KEY_PATH_DEFAULT}"
WATCHDOG_PATH="${WATCHDOG_PATH:-$WATCHDOG_PATH_DEFAULT}"
SENSECAP_HOST="${SENSECAP_HOST:-$SENSECAP_HOST_DEFAULT}"
PIPHI_PORT="${PIPHI_PORT:-$PIPHI_PORT_DEFAULT}"

if [[ ! -f "$SSH_KEY_PATH" ]]; then
  if [[ "$LANG_CHOICE" == "pl" ]]; then
    log "${RED}Plik klucza SSH nie istnieje: $SSH_KEY_PATH${RESET}"
  else
    log "${RED}SSH key file does not exist: $SSH_KEY_PATH${RESET}"
  fi
  exit 1
fi

mkdir -p "$(dirname "$WATCHDOG_PATH")"
mkdir -p "$CONF_DIR"

if [[ "$LANG_CHOICE" == "pl" ]]; then
  log "${GREEN}Klucz SSH: ${BOLD}$SSH_KEY_PATH${RESET}"
  log "${GREEN}Docelowy skrypt watchdog: ${BOLD}$WATCHDOG_PATH${RESET}"
  log "${GREEN}SenseCAP host: ${BOLD}$SENSECAP_HOST${RESET}"
  log "${GREEN}Port panelu PiPhi: ${BOLD}$PIPHI_PORT${RESET}"
else
  log "${GREEN}SSH key: ${BOLD}$SSH_KEY_PATH${RESET}"
  log "${GREEN}Watchdog script: ${BOLD}$WATCHDOG_PATH${RESET}"
  log "${GREEN}SenseCAP host: ${BOLD}$SENSECAP_HOST${RESET}"
  log "${GREEN}PiPhi panel port: ${BOLD}$PIPHI_PORT${RESET}"
fi

# =========================
# 3: WRITE CONFIG
# =========================
if [[ "$LANG_CHOICE" == "pl" ]]; then
  section "3. Zapis konfiguracji do $CONF_FILE"
else
  section "3. Writing configuration to $CONF_FILE"
fi

if [[ $AUTO_MODE -eq 1 ]]; then
  BOOT_DELAY="300"
  RETRY_DELAY="60"
  RESTORE_INTERVAL="600"
else
  BOOT_DELAY=$(ask \
    "Delay after SenseCAP boot before trying to start panel (seconds)" \
    "Opóźnienie po starcie SenseCAP przed próbą startu panelu (sekundy)" \
    "300")
  RETRY_DELAY=$(ask \
    "Delay between recovery attempts (seconds)" \
    "Przerwa między kolejnymi próbami naprawy (sekundy)" \
    "60")
  RESTORE_INTERVAL=$(ask \
    "Interval between watchdog runs (seconds)" \
    "Okres między wywołaniami watchdoga (sekundy)" \
    "600")
fi

cat > "$CONF_FILE" <<EOF
# PiPhi Watchdog configuration
SENSECAP_HOST="$SENSECAP_HOST"
SENSECAP_PORT="$PIPHI_PORT"
SENSECAP_SSH_USER="sensecap_root"
SENSECAP_SSH_PORT="22222"

BOOT_DELAY="$BOOT_DELAY"
RETRY_DELAY="$RETRY_DELAY"
RESTORE_INTERVAL="$RESTORE_INTERVAL"

SSH_KEY_PATH="$SSH_KEY_PATH"
EOF

if [[ "$LANG_CHOICE" == "pl" ]]; then
  log "${GREEN}Konfiguracja zapisana w: ${BOLD}$CONF_FILE${RESET}"
else
  log "${GREEN}Configuration written to: ${BOLD}$CONF_FILE${RESET}"
fi

# =========================
# 4: GENERATE WATCHDOG SCRIPT IF MISSING
# =========================
if [[ "$LANG_CHOICE" == "pl" ]]; then
  section "4. Generacja szablonu piphi-watchdog.sh (jeśli brak)"
else
  section "4. Generating piphi-watchdog.sh template (if missing)"
fi

if [[ -f "$WATCHDOG_PATH" ]]; then
  if [[ "$LANG_CHOICE" == "pl" ]]; then
    log "${YELLOW}Skrypt $WATCHDOG_PATH już istnieje – NIE nadpisuję.${RESET}"
  else
    log "${YELLOW}Script $WATCHDOG_PATH already exists – NOT overwriting.${RESET}"
  fi
else
  cat > "$WATCHDOG_PATH" <<'EOF'
#!/usr/bin/env bash
set -e

CONF_FILE="$HOME/.config/piphi-watchdog.conf"

if [[ ! -f "$CONF_FILE" ]]; then
  echo "Missing config file: $CONF_FILE"
  exit 1
fi

# shellcheck source=/dev/null
source "$CONF_FILE"

LOGFILE="$HOME/piphi-watchdog-run.log"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOGFILE"
}

# 1. HTTP check for PiPhi panel
URL="http://${SENSECAP_HOST}:${SENSECAP_PORT}/"
log "Checking PiPhi panel at: $URL"

if curl -s --max-time 5 "$URL" >/dev/null 2>&1; then
  log "PiPhi panel is up. Nothing to do."
  exit 0
fi

log "PiPhi panel is DOWN. Attempting recovery..."

# 2. SSH check (ssh uses ssh-agent, no -i)
SSH_TARGET="${SENSECAP_SSH_USER}@${SENSECAP_HOST}"
SSH_OPTS="-p ${SENSECAP_SSH_PORT} -o BatchMode=yes -o ConnectTimeout=10"

if ! ssh $SSH_OPTS "$SSH_TARGET" "echo 'SSH OK'" >/dev/null 2>&1; then
  log "No SSH connection to $SSH_TARGET. Maybe SenseCAP is still booting. Sleeping ${BOOT_DELAY}s and exiting."
  sleep "$BOOT_DELAY"
  exit 1
fi

log "SSH to SenseCAP works. Waiting ${BOOT_DELAY}s before restarting containers..."
sleep "$BOOT_DELAY"

# 3. Restart containers / try to bring panel up
log "Refreshing PiPhi containers on SenseCAP..."

ssh $SSH_OPTS "$SSH_TARGET" 'balena ps' >> "$LOGFILE" 2>&1 || log "balena ps returned error (maybe not fully up)."

ssh $SSH_OPTS "$SSH_TARGET" '
  echo "Restarting PiPhi containers..."
  balena restart db || true
  balena restart grafana || true
  balena restart watchtower || true
  balena restart piphi-network-image || true
' >> "$LOGFILE" 2>&1 || log "Error while restarting containers."

log "Sleeping ${RETRY_DELAY}s and re-checking panel..."
sleep "$RETRY_DELAY"

if curl -s --max-time 5 "$URL" >/dev/null 2>&1; then
  log "PiPhi panel is back online."
  exit 0
fi

log "PiPhi panel is still down after restart attempt. Will retry on next watchdog run."
exit 1
EOF

  chmod +x "$WATCHDOG_PATH"
  if [[ "$LANG_CHOICE" == "pl" ]]; then
    log "${GREEN}Utworzono szablon skryptu: ${BOLD}$WATCHDOG_PATH${RESET}"
  else
    log "${GREEN}Created watchdog script template: ${BOLD}$WATCHDOG_PATH${RESET}"
  fi
fi

# =========================
# 5: ssh-agent SERVICE
# =========================
if [[ "$LANG_CHOICE" == "pl" ]]; then
  section "5. Konfiguracja systemd user service: ssh-agent"
else
  section "5. Configuring systemd user service: ssh-agent"
fi

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

log "${GREEN}Saved: $SSH_AGENT_SERVICE${RESET}"

systemctl --user daemon-reload
systemctl --user enable --now ssh-agent.service

sleep 1
if systemctl --user is-active --quiet ssh-agent.service; then
  if [[ "$LANG_CHOICE" == "pl" ]]; then
    log "${GREEN}ssh-agent.service jest aktywny.${RESET}"
  else
    log "${GREEN}ssh-agent.service is active.${RESET}"
  fi
else
  if [[ "$LANG_CHOICE" == "pl" ]]; then
    log "${RED}ssh-agent.service NIE jest aktywny. Sprawdź: systemctl --user status ssh-agent.service${RESET}"
  else
    log "${RED}ssh-agent.service is NOT active. Check: systemctl --user status ssh-agent.service${RESET}"
  fi
  exit 1
fi

# =========================
# 6: SSH_AUTH_SOCK in ~/.profile
# =========================
if [[ "$LANG_CHOICE" == "pl" ]]; then
  section "6. Ustawienie SSH_AUTH_SOCK w ~/.profile"
else
  section "6. Setting SSH_AUTH_SOCK in ~/.profile"
fi

PROFILE_FILE="$HOME/.profile"
LINE_EXPORT='export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"'

if grep -q 'SSH_AUTH_SOCK=.*ssh-agent.socket' "$PROFILE_FILE" 2>/dev/null; then
  if [[ "$LANG_CHOICE" == "pl" ]]; then
    log "${YELLOW}Wygląda na to, że SSH_AUTH_SOCK jest już ustawiony w $PROFILE_FILE.${RESET}"
  else
    log "${YELLOW}SSH_AUTH_SOCK already seems to be set in $PROFILE_FILE.${RESET}"
  fi
else
  {
    echo ""
    echo "# ssh-agent via systemd user service"
    echo "$LINE_EXPORT"
  } >> "$PROFILE_FILE"
  if [[ "$LANG_CHOICE" == "pl" ]]; then
    log "${GREEN}Dodano ustawienie SSH_AUTH_SOCK do $PROFILE_FILE.${RESET}"
  else
    log "${GREEN}Added SSH_AUTH_SOCK export to $PROFILE_FILE.${RESET}"
  fi
fi

export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/ssh-agent.socket"
if [[ "$LANG_CHOICE" == "pl" ]]; then
  log "${GREEN}Ustawiono SSH_AUTH_SOCK dla bieżącej sesji: $SSH_AUTH_SOCK${RESET}"
else
  log "${GREEN}Set SSH_AUTH_SOCK for current session: $SSH_AUTH_SOCK${RESET}"
fi

# =========================
# 7: ssh-add key
# =========================
if [[ "$LANG_CHOICE" == "pl" ]]; then
  section "7. Dodawanie klucza SenseCAP do ssh-agent"
  log "${GREEN}Za chwilę zostaniesz poproszony o passphrase do klucza: $SSH_KEY_PATH${RESET}"
  log "To jest dodanie klucza do agenta (ssh-agent)."
else
  section "7. Adding SenseCAP key to ssh-agent"
  log "${GREEN}You will now be asked for the passphrase to key: $SSH_KEY_PATH${RESET}"
  log "This adds the key to ssh-agent."
fi

if ssh-add "$SSH_KEY_PATH"; then
  if [[ "$LANG_CHOICE" == "pl" ]]; then
    log "${GREEN}Klucz został pomyślnie dodany do ssh-agent.${RESET}"
  else
    log "${GREEN}Key successfully added to ssh-agent.${RESET}"
  fi
else
  if [[ "$LANG_CHOICE" == "pl" ]]; then
    log "${RED}Nie udało się dodać klucza do ssh-agent. Sprawdź passphrase lub plik klucza.${RESET}"
  else
    log "${RED}Failed to add key to ssh-agent. Check passphrase or key file.${RESET}"
  fi
  exit 1
fi

if [[ "$LANG_CHOICE" == "pl" ]]; then
  log "${GREEN}Aktualne klucze w ssh-agent:${RESET}"
else
  log "${GREEN}Current keys in ssh-agent:${RESET}"
fi
ssh-add -l || log "${YELLOW}ssh-add -l failed – no keys?${RESET}"

# =========================
# 8: piphi-watchdog.service
# =========================
if [[ "$LANG_CHOICE" == "pl" ]]; then
  section "8. Konfiguracja piphi-watchdog.service"
else
  section "8. Configuring piphi-watchdog.service"
fi

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

log "${GREEN}Saved: $PIPHI_SERVICE${RESET}"

# =========================
# 9: Timer
# =========================
if [[ "$LANG_CHOICE" == "pl" ]]; then
  section "9. Konfiguracja piphi-watchdog.timer"
else
  section "9. Configuring piphi-watchdog.timer"
fi

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

log "${GREEN}Saved: $PIPHI_TIMER${RESET}"

systemctl --user daemon-reload
systemctl --user enable --now piphi-watchdog.timer

sleep 1
systemctl --user list-timers --all | tee -a "$LOGFILE"

# =========================
# 10: Manual test
# =========================
if [[ "$LANG_CHOICE" == "pl" ]]; then
  section "10. Ręczny test piphi-watchdog (opcjonalny)"
else
  section "10. Manual piphi-watchdog test (optional)"
fi

if confirm \
  "Run piphi-watchdog.service now for a test?" \
  "Czy chcesz teraz ręcznie uruchomić piphi-watchdog.service do testu?" \
  "y"; then
  systemctl --user start piphi-watchdog.service
  sleep 3
  systemctl --user status piphi-watchdog.service --no-pager || true
  if [[ "$LANG_CHOICE" == "pl" ]]; then
    log "${GREEN}Sprawdź też log: $HOME/piphi-watchdog-run.log${RESET}"
  else
    log "${GREEN}Also check log: $HOME/piphi-watchdog-run.log${RESET}"
  fi
else
  if [[ "$LANG_CHOICE" == "pl" ]]; then
    log "${YELLOW}Pominięto ręczny test usługi.${RESET}"
  else
    log "${YELLOW}Skipped manual service test.${RESET}"
  fi
fi

# =========================
# 11: Summary
# =========================
if [[ "$LANG_CHOICE" == "pl" ]]; then
  section "11. Podsumowanie"
  log "${GREEN}Konfiguracja zakończona.${RESET}"
  log "Plik konfiguracyjny: $CONF_FILE"
  log "Skrypt watchdoga: $WATCHDOG_PATH"
  log "Usługi user-level: ssh-agent.service, piphi-watchdog.service, piphi-watchdog.timer"
  log "Po restarcie RPi systemd --user uruchomi ssh-agent i timer, który co $ON_ACTIVE będzie odpalał watchdoga."
  log "Log z instalacji: $LOGFILE"
else
  section "11. Summary"
  log "${GREEN}Configuration finished.${RESET}"
  log "Config file: $CONF_FILE"
  log "Watchdog script: $WATCHDOG_PATH"
  log "User services: ssh-agent.service, piphi-watchdog.service, piphi-watchdog.timer"
  log "After RPi reboot, systemd --user will start ssh-agent and the timer, which runs the watchdog every $ON_ACTIVE."
  log "Setup log: $LOGFILE"
fi
