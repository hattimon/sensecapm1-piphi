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
