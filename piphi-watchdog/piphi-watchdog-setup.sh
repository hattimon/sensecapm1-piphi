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
LANG_CHOICE="en" # default
AUTO_MODE=0

log() {
    echo -e "$@" | tee -a "$LOGFILE"
}

section() {
    local title="$1"
    echo -e "
${CYAN}${BOLD}===== [SECTION] $title =====${RESET}
" | tee -a "$LOGFILE"
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

uninstall() {
    section "UNINSTALL / DEZINSTALACJA"

    SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
    CONF_FILE="$HOME/.config/piphi-watchdog.conf"
    WATCHDOG_PATH_DEFAULT="$HOME/piphi-watchdog.sh"
    STATE_FILE="$HOME/.local/state/piphi-watchdog.state"
    RUN_LOGFILE="$HOME/piphi-watchdog-run.log"

    if [[ "$LANG_CHOICE" == "pl" ]]; then
        log "${YELLOW}Zatrzymuję i wyłączam jednostki systemd (user): ssh-agent, piphi-watchdog, timer...${RESET}"
    else
        log "${YELLOW}Stopping and disabling systemd user units: ssh-agent, piphi-watchdog, timer...${RESET}"
    fi

    systemctl --user stop piphi-watchdog.timer 2>/dev/null || true
    systemctl --user stop piphi-watchdog.service 2>/dev/null || true
    systemctl --user stop ssh-agent.service 2>/dev/null || true

    systemctl --user disable piphi-watchdog.timer 2>/dev/null || true
    systemctl --user disable piphi-watchdog.service 2>/dev/null || true
    systemctl --user disable ssh-agent.service 2>/dev/null || true

    systemctl --user daemon-reload 2>/dev/null || true

    if [[ "$LANG_CHOICE" == "pl" ]]; then
        log "${YELLOW}Usuwam pliki unitów systemd z $SYSTEMD_USER_DIR...${RESET}"
    else
        log "${YELLOW}Removing systemd unit files from $SYSTEMD_USER_DIR...${RESET}"
    fi

    rm -f "$SYSTEMD_USER_DIR/piphi-watchdog.service"
    rm -f "$SYSTEMD_USER_DIR/piphi-watchdog.timer"
    rm -f "$SYSTEMD_USER_DIR/ssh-agent.service"

    systemctl --user daemon-reload 2>/dev/null || true

    if [[ "$LANG_CHOICE" == "pl" ]]; then
        log "${YELLOW}Usuwam skrypt watchdoga, konfigurację, logi i plik stanu...${RESET}"
    else
        log "${YELLOW}Removing watchdog script, config, logs and state file...${RESET}"
    fi

    rm -f "$WATCHDOG_PATH_DEFAULT"
    rm -f "$CONF_FILE"
    rm -f "$LOGFILE"
    rm -f "$RUN_LOGFILE"
    rm -f "$STATE_FILE"

    if [[ "$LANG_CHOICE" == "pl" ]]; then
        log "${GREEN}Deinstalacja PiPhi Watchdog zakończona.${RESET}"
    else
        log "${GREEN}PiPhi Watchdog uninstallation finished.${RESET}"
    fi

    exit 0
}

echo -e "${CYAN}${BOLD}===== PiPhi Watchdog setup =====${RESET}"
echo -e "${YELLOW}Select language / Wybierz język:${RESET}"
echo " 1) English (default)"
echo " 2) Polski"
echo -ne "${YELLOW}Choice / Wybór [1/2] (default: 1): ${RESET}"
read lang_sel
lang_sel="${lang_sel:-1}"

if [[ "$lang_sel" == "2" ]]; then
    LANG_CHOICE="pl"
else
    LANG_CHOICE="en"
fi

# wybór trybu: instalacja / odinstalowanie
if [[ "$LANG_CHOICE" == "pl" ]]; then
    echo -e "${YELLOW}Wybierz tryb:${RESET}"
    echo " 1) Instalacja (domyślnie)"
    echo " 2) Deinstalacja"
    echo -ne "${YELLOW}Wybór [1/2] (domyślnie: 1): ${RESET}"
else
    echo -e "${YELLOW}Select mode:${RESET}"
    echo " 1) Install (default)"
    echo " 2) Uninstall"
    echo -ne "${YELLOW}Choice [1/2] (default: 1): ${RESET}"
fi

read mode_sel
mode_sel="${mode_sel:-1}"

if [[ "$mode_sel" == "2" ]]; then
    uninstall
fi

if [[ "$LANG_CHOICE" == "pl" ]]; then
    section "WSTĘP"
    log "${GREEN}Ten skrypt skonfiguruje ssh-agent, załaduje klucz SenseCAP, utworzy watchdog PiPhi (systemd) i zapisze konfigurację pingowania panelu.${RESET}"
    log "Log z przebiegu: $LOGFILE"
    log "Uruchamiaj jako użytkownik ${BOLD}pi${RESET} na Raspberry Pi."
else
    section "INTRO"
    log "${GREEN}This script configures ssh-agent, loads the SenseCAP key, sets up the PiPhi watchdog (systemd) and saves configuration.${RESET}"
    log "Log file: $LOGFILE"
    log "Run as user ${BOLD}pi${RESET} on a Raspberry Pi."
fi

if confirm "Use fully automatic mode (minimal questions)?" "Czy chcesz użyć trybu automatycznego (minimum pytań)?" "y"; then
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

# 1. ENV CHECK
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
    if ! confirm "Continue anyway?" "Kontynuować mimo to?" "n"; then
        if [[ "$LANG_CHOICE" == "pl" ]]; then
            log "${RED}Przerywam.${RESET}"
        else
            log "${RED}Aborting.${RESET}"
        fi
        exit 1
    fi
fi

for bin in systemctl ssh-agent ssh-add ssh curl; do
    if ! command -v "$bin" >/dev/null 2>&1; then
        if [[ "$LANG_CHOICE" == "pl" ]]; then
            log "${RED}Brak wymaganej komendy: $bin. Zainstaluj pakiety i spróbuj ponownie.${RESET}"
        else
            log "${RED}Missing required command: $bin. Install packages and try again.${RESET}"
        fi
        exit 1
    fi
done

# 2. PATHS, IP, PORT
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
SENSECAP_SSH_PORT_DEFAULT="22222"
SENSECAP_SSH_USER_DEFAULT="sensecap_root"

if [[ $AUTO_MODE -eq 1 ]]; then
    SSH_KEY_PATH="$KEY_PATH_DEFAULT"
    WATCHDOG_PATH="$WATCHDOG_PATH_DEFAULT"
    SENSECAP_HOST="$SENSECAP_HOST_DEFAULT"
    PIPHI_PORT="$PIPHI_PORT_DEFAULT"
    SENSECAP_SSH_PORT="$SENSECAP_SSH_PORT_DEFAULT"
    SENSECAP_SSH_USER="$SENSECAP_SSH_USER_DEFAULT"
else
    SSH_KEY_PATH=$(ask "Path to SSH key for sensecap_root" "Ścieżka do klucza SSH dla sensecap_root" "$KEY_PATH_DEFAULT")
    WATCHDOG_PATH=$(ask "Path for piphi-watchdog.sh" "Ścieżka do skryptu piphi-watchdog.sh" "$WATCHDOG_PATH_DEFAULT")
    SENSECAP_HOST=$(ask "SenseCAP host/IP" "IP lub hostname SenseCAP" "$SENSECAP_HOST_DEFAULT")
    PIPHI_PORT=$(ask "PiPhi panel HTTP port" "Port HTTP panelu PiPhi" "$PIPHI_PORT_DEFAULT")
    SENSECAP_SSH_PORT=$(ask "SenseCAP SSH port" "Port SSH SenseCAP" "$SENSECAP_SSH_PORT_DEFAULT")
    SENSECAP_SSH_USER=$(ask "SenseCAP SSH user" "Użytkownik SSH SenseCAP" "$SENSECAP_SSH_USER_DEFAULT")
fi

SSH_KEY_PATH="${SSH_KEY_PATH:-$KEY_PATH_DEFAULT}"
WATCHDOG_PATH="${WATCHDOG_PATH:-$WATCHDOG_PATH_DEFAULT}"
SENSECAP_HOST="${SENSECAP_HOST:-$SENSECAP_HOST_DEFAULT}"
PIPHI_PORT="${PIPHI_PORT:-$PIPHI_PORT_DEFAULT}"
SENSECAP_SSH_PORT="${SENSECAP_SSH_PORT:-$SENSECAP_SSH_PORT_DEFAULT}"
SENSECAP_SSH_USER="${SENSECAP_SSH_USER:-$SENSECAP_SSH_USER_DEFAULT}"

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

# 3. WRITE CONFIG
if [[ "$LANG_CHOICE" == "pl" ]]; then
    section "3. Zapis konfiguracji do $CONF_FILE"
else
    section "3. Writing configuration to $CONF_FILE"
fi

cat > "$CONF_FILE" <<EOF
# PiPhi Watchdog configuration
SENSECAP_HOST="$SENSECAP_HOST"
SENSECAP_PORT="$PIPHI_PORT"
SENSECAP_SSH_USER="$SENSECAP_SSH_USER"
SENSECAP_SSH_PORT="$SENSECAP_SSH_PORT"
SSH_KEY_PATH="$SSH_KEY_PATH"

BOOT_DELAY="300"
RETRY_DELAY="60"
EOF

log "Konfiguracja zapisana w: $CONF_FILE"

# 4. GENERATE WATCHDOG SCRIPT (pełna wersja z dockerd/start-piphi.sh)
if [[ "$LANG_CHOICE" == "pl" ]]; then
    section "4. Generacja skryptu piphi-watchdog.sh"
else
    section "4. Generating piphi-watchdog.sh"
fi

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
STATE_DIR="$HOME/.local/state"
STATE_FILE="$STATE_DIR/piphi-watchdog.state"

mkdir -p "$STATE_DIR"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOGFILE"
}

ATTEMPTS=0
NEXT_TS=0
REBOOT_LEVEL=0

if [[ -f "$STATE_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$STATE_FILE" || true
fi

now_ts() {
  date +%s
}

save_state() {
  cat > "$STATE_FILE" <<EOL
ATTEMPTS=$ATTEMPTS
NEXT_TS=$NEXT_TS
REBOOT_LEVEL=$REBOOT_LEVEL
EOL
}

NOW=$(now_ts)

if [[ "$NEXT_TS" -gt "$NOW" ]]; then
  REM=$(( NEXT_TS - NOW ))
  log "Backoff aktywny: kolejne próby dopiero za ${REM}s (do $(date -d "@$NEXT_TS")). Kończę."
  exit 0
fi

URL="http://${SENSECAP_HOST}:${SENSECAP_PORT}/"
SSH_TARGET="${SENSECAP_SSH_USER}@${SENSECAP_HOST}"
SSH_OPTS="-p ${SENSECAP_SSH_PORT} -i ${SSH_KEY_PATH} -o IdentitiesOnly=yes -o ConnectTimeout=10"

BOOT_DELAY="${BOOT_DELAY:-0}"
RETRY_DELAY="${RETRY_DELAY:-30}"

log "Sprawdzam panel PiPhi pod adresem: $URL"

if curl -s --max-time 5 "$URL" >/dev/null 2>&1; then
  log "Panel PiPhi odpowiada. Resetuję cały stan backoff/reboot."
  ATTEMPTS=0
  NEXT_TS=0
  REBOOT_LEVEL=0
  save_state
  exit 0
fi

log "Panel PiPhi NIE odpowiada. Próba naprawy..."

if ! ssh $SSH_OPTS "$SSH_TARGET" "echo 'SSH OK'" >/dev/null 2>&1; then
  log "Brak połączenia SSH do $SSH_TARGET. Kończę od razu, spróbuję przy kolejnym wywołaniu watchdoga."
  save_state
  exit 1
fi

if [[ "$BOOT_DELAY" -gt 0 ]]; then
  log "Połączenie SSH działa. Czekam ${BOOT_DELAY}s przed próbą naprawy kontenerów..."
  sleep "$BOOT_DELAY"
fi

log "Próbuję odtworzyć środowisko PiPhi wewnątrz ubuntu-piphi (jak ręcznie)..."

ssh $SSH_OPTS "$SSH_TARGET" '
  set -e

  echo "===> balena ps (host) dla diagnostyki:"
  balena ps || true

  echo "===> Sprawdzam, czy ubuntu-piphi jest UP..."
  if ! balena ps | grep -q "ubuntu-piphi"; then
    echo "ubuntu-piphi nie działa – próbuję go uruchomić..."
    balena restart ubuntu-piphi || true
    sleep 10
  fi

  echo "===> Sprawdzam dockerd w ubuntu-piphi (docker info)..."
  if ! balena exec ubuntu-piphi docker info >/dev/null 2>&1; then
    echo "Docker w ubuntu-piphi NIE działa – uruchamiam tak jak ręcznie."
    if balena exec ubuntu-piphi bash -lc "[ -d /piphi-network ]"; then
      echo "Uruchamiam: cd /piphi-network && dockerd --host=unix:///var/run/docker.sock > /piphi-network/dockerd.log 2>&1 &"
      balena exec ubuntu-piphi bash -lc "cd /piphi-network && dockerd --host=unix:///var/run/docker.sock > /piphi-network/dockerd.log 2>&1 &"
      sleep 10
      echo "Uruchamiam: ./start-piphi.sh (docker compose up ...)"
      balena exec ubuntu-piphi bash -lc "cd /piphi-network && ./start-piphi.sh" || true
    elif [ -d /mnt/data/piphi ]; then
      echo "Fallback: /mnt/data/piphi istnieje – uruchamiam tam start-piphi.sh"
      balena exec ubuntu-piphi bash -lc "cd /mnt/data/piphi && ./start-piphi.sh" || true
    else
      echo "Brak katalogu /piphi-network i /mnt/data/piphi – nie wiem, gdzie jest instalacja PiPhi."
    fi
  else
    echo "Docker w ubuntu-piphi działa – sprawdzam kontenery PiPhi..."
    balena exec ubuntu-piphi docker ps || true
  fi
' >> "$LOGFILE" 2>&1 || log "Błąd podczas odtwarzania środowiska PiPhi wewnątrz ubuntu-piphi."

log "Odczekuję ${RETRY_DELAY}s i ponownie sprawdzam panel..."
sleep "$RETRY_DELAY"

if curl -s --max-time 5 "$URL" >/dev/null 2>&1; then
  log "Panel PiPhi ponownie działa po naprawie. Resetuję stan."
  ATTEMPTS=0
  NEXT_TS=0
  REBOOT_LEVEL=0
  save_state
  exit 0
fi

log "Panel PiPhi nadal nie działa po próbie naprawy."

ATTEMPTS=$(( ATTEMPTS + 1 ))
log "Kolejna nieudana próba z SSH OK: ATTEMPTS=$ATTEMPTS, REBOOT_LEVEL=$REBOOT_LEVEL"

BASE_DELAY_MIN=10
MAX_DELAY_BEFORE_FIRST_REBOOT=240

REBOOT_DONE=0
DELAY_MIN=0

if (( REBOOT_LEVEL == 0 )); then
  if (( ATTEMPTS >= 3 )); then
    BLOCK=$(( (ATTEMPTS - 3) / 3 ))
    DELAY_MIN=$(( BASE_DELAY_MIN * (1 << BLOCK) ))
    if (( DELAY_MIN > MAX_DELAY_BEFORE_FIRST_REBOOT )); then
      DELAY_MIN=$MAX_DELAY_BEFORE_FIRST_REBOOT
    fi
  else
    DELAY_MIN=0
  fi

  if (( DELAY_MIN == MAX_DELAY_BEFORE_FIRST_REBOOT )); then
    log "Osiągnięto maksymalny backoff przed pierwszym rebootem (${MAX_DELAY_BEFORE_FIRST_REBOOT} min). Wysyłam reboot SenseCAP..."
    if ssh $SSH_OPTS "$SSH_TARGET" "reboot" >/dev/null 2>&1; then
      log "Komenda reboot (poziom 1) wysłana pomyślnie."
    else
      log "Nie udało się wysłać komendy reboot (poziom 1)."
    fi
    REBOOT_DONE=1
    REBOOT_LEVEL=1
    ATTEMPTS=0
    DELAY_MIN=$((8*60))
  fi

elif (( REBOOT_LEVEL == 1 )); then
  DELAY_MIN=$((8*60))
  log "Jesteśmy po pierwszym reboocie. Ustawiam minimalny backoff 8h."
  if (( ATTEMPTS >= 3 )); then
    log "Kolejne nieudane próby po pierwszym reboocie, wysyłam drugi reboot..."
    if ssh $SSH_OPTS "$SSH_TARGET" "reboot" >/dev/null 2>&1; then
      log "Komenda reboot (poziom 2) wysłana pomyślnie."
    else
      log "Nie udało się wysłać komendy reboot (poziom 2)."
    fi
    REBOOT_DONE=1
    REBOOT_LEVEL=2
    ATTEMPTS=0
    DELAY_MIN=$((16*60))
  fi

elif (( REBOOT_LEVEL == 2 )); then
  DELAY_MIN=$((16*60))
  log "Jesteśmy po drugim reboocie. Ustawiam minimalny backoff 16h."
  if (( ATTEMPTS >= 3 )); then
    log "Kolejne nieudane próby po drugim reboocie, wysyłam trzeci reboot..."
    if ssh $SSH_OPTS "$SSH_TARGET" "reboot" >/dev/null 2>&1; then
      log "Komenda reboot (poziom 3) wysłana pomyślnie."
    else
      log "Nie udało się wysłać komendy reboot (poziom 3)."
    fi
    REBOOT_DONE=1
    REBOOT_LEVEL=3
    ATTEMPTS=0
    DELAY_MIN=$((24*60))
  fi

else
  DELAY_MIN=$((24*60))
  log "Tryb podtrzymania: REBOOT_LEVEL>=3, maksymalnie jeden reboot na 24h."
  if (( ATTEMPTS >= 3 )); then
    log "Kolejne nieudane próby w trybie 24h, wysyłam reboot..."
    if ssh $SSH_OPTS "$SSH_TARGET" "reboot" >/dev/null 2>&1; then
      log "Komenda reboot (tryb 24h) wysłana pomyślnie."
    else
      log "Nie udało się wysłać komendy reboot (tryb 24h)."
    fi
    REBOOT_DONE=1
    ATTEMPTS=0
  fi
fi

if (( DELAY_MIN > 0 )); then
  DELAY_SEC=$(( DELAY_MIN * 60 ))
  NEXT_TS=$(( NOW + DELAY_SEC ))
  log "Ustawiam backoff: następne realne próby dopiero za ${DELAY_MIN} minut (do $(date -d "@$NEXT_TS"))."
else
  NEXT_TS=0
fi

save_state

if (( REBOOT_DONE == 1 )); then
  log "Po reboot (REBOOT_LEVEL=$REBOOT_LEVEL) watchdog na RPi będzie czekał do $(date -d "@$NEXT_TS") zanim znowu dotknie SenseCAP."
fi

exit 1
EOF

chmod +x "$WATCHDOG_PATH"

# 5. ssh-agent SERVICE
if [[ "$LANG_CHOICE" == "pl" ]]; then
    section "5. Konfiguracja systemd user service: ssh-agent"
else
    section "5. Configuring systemd user service: ssh-agent"
fi

SYSTEMD_USER_DIR="$HOME/.config/systemd/user"
mkdir -p "$SYSTEMD_USER_DIR"

cat > "$SYSTEMD_USER_DIR/ssh-agent.service" <<EOF
[Unit]
Description=SSH key agent

[Service]
Type=simple
Environment=SSH_AUTH_SOCK=%t/ssh-agent.socket
ExecStart=/usr/bin/ssh-agent -D -a %t/ssh-agent.socket

[Install]
WantedBy=default.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now ssh-agent.service

# 6. ssh-add key
if [[ "$LANG_CHOICE" == "pl" ]]; then
    section "6. Dodawanie klucza SenseCAP do ssh-agent"
    log "Za chwilę zostaniesz poproszony o passphrase do klucza: $SSH_KEY_PATH"
else
    section "6. Adding SenseCAP key to ssh-agent"
    log "You will now be asked for passphrase for: $SSH_KEY_PATH"
fi

export SSH_AUTH_SOCK="/run/user/$UID/ssh-agent.socket"
ssh-add "$SSH_KEY_PATH"

# 7. watchdog service + timer
if [[ "$LANG_CHOICE" == "pl" ]]; then
    section "7. Konfiguracja piphi-watchdog.service i .timer"
else
    section "7. Configuring piphi-watchdog.service and .timer"
fi

cat > "$SYSTEMD_USER_DIR/puphi-watchdog.service" <<EOF
[Unit]
Description=PiPhi watchdog

[Service]
Type=oneshot
Environment=SSH_AUTH_SOCK=%t/ssh-agent.socket
WorkingDirectory=$HOME
ExecStart=$WATCHDOG_PATH
EOF

cat > "$SYSTEMD_USER_DIR/piphi-watchdog.timer" <<EOF
[Unit]
Description=Run PiPhi watchdog periodically

[Timer]
OnBootSec=60
OnUnitActiveSec=600
AccuracySec=10s
Unit=piphi-watchdog.service

[Install]
WantedBy=timers.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now piphi-watchdog.timer

if [[ "$LANG_CHOICE" == "pl" ]]; then
    section "11. Podsumowanie"
    log "Konfiguracja zakończona."
    log "Plik konfiguracyjny: $CONF_FILE"
    log "Skrypt watchdoga: $WATCHDOG_PATH"
    log "Usługi user-level: ssh-agent.service, piphi-watchdog.service, piphi-watchdog.timer"
    log "Po restarcie RPi systemd --user uruchomi ssh-agent i timer, który co 10min będzie odpalał watchdoga."
    log "Log z instalacji: $LOGFILE"
else
    section "11. Summary"
    log "Configuration finished."
    log "Config file: $CONF_FILE"
    log "Watchdog script: $WATCHDOG_PATH"
    log "User-level services: ssh-agent.service, piphi-watchdog.service, piphi-watchdog.timer"
    log "After Raspberry Pi reboot, systemd --user will start ssh-agent and the timer, which runs watchdog every 10 minutes."
    log "Setup log: $LOGFILE"
fi
