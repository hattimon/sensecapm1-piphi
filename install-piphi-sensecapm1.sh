#!/bin/bash
# PiPhi Network Installation Script for SenseCAP M1 (balenaOS)
# Version: 3.2 (start-piphi.sh: safe dockerd restart + staged PiPhi + GPS)
# - Prepares /mnt/data/piphi with PiPhi docker-compose.yml
# - Creates ubuntu-piphi container with /piphi-network bound to /mnt/data/piphi
# - Installs Docker inside ubuntu-piphi
# - Creates start-piphi.sh (defensive dockerd + staged docker compose + gpsd)

INSTALL_DIR="/mnt/data/piphi"
CONTAINER_NAME="ubuntu-piphi"
UBUNTU_IMAGE="ubuntu:20.04"
COMPOSE_URL="https://chibisafe.piphi.network/m2JmK11Z7tor.yml"
GPS_DEVICE="/dev/ttyACM0"

# ===== LANGUAGE =====

if [ -f /tmp/language ]; then
    LANGUAGE=$(cat /tmp/language)
else
    LANGUAGE="pl"
fi

function set_language() {
    if [ "$LANGUAGE" = "pl" ]; then
        LANGUAGE="en"
        echo "en" > /tmp/language
        echo "Language changed to English."
    else
        LANGUAGE="pl"
        echo "pl" > /tmp/language
        echo "Język zmieniony na polski."
    fi
}

declare -A MESSAGES
MESSAGES[pl,header]="Instalacja / przygotowanie PiPhi Network na SenseCAP M1 (balenaOS)"
MESSAGES[pl,separator]="=============================================================="
MESSAGES[pl,wget_missing]="Brak wget na hoście. Zainstaluj wget lub pobierz pliki ręcznie."
MESSAGES[pl,changing_dir]="Używam katalogu instalacyjnego: $INSTALL_DIR ..."
MESSAGES[pl,dir_error]="Błąd przejścia do katalogu $INSTALL_DIR"
MESSAGES[pl,checking_existing]="Sprawdzanie istniejących kontenerów (Helium itp.)..."
MESSAGES[pl,existing_found]="Znaleziono kontenery: %s (PiPhi będzie działać obok)."
MESSAGES[pl,loading_gps]="Ładowanie modułu GPS (cdc-acm)..."
MESSAGES[pl,gps_detected]="GPS wykryty: %s"
MESSAGES[pl,gps_not_detected]="GPS nie wykryty. Podłącz U-Blox 7 i sprawdź lsusb/ls /dev/ttyACM*."
MESSAGES[pl,removing_old]="Usuwanie starej instalacji PiPhi / starego ubuntu-piphi..."
MESSAGES[pl,downloading_compose]="Pobieranie docker-compose.yml PiPhi..."
MESSAGES[pl,download_error]="Błąd pobierania docker-compose.yml"
MESSAGES[pl,updating_compose]="Modyfikacja docker-compose.yml (GPS + volumes)..."
MESSAGES[pl,pulling_ubuntu]="Pobieranie obrazu Ubuntu (próba %d/3)..."
MESSAGES[pl,pull_error]="Błąd pobierania Ubuntu po 3 próbach."
MESSAGES[pl,running_container]="Uruchamianie kontenera bazowego $CONTAINER_NAME..."
MESSAGES[pl,run_error]="Błąd uruchamiania $CONTAINER_NAME. Sprawdź balena logs $CONTAINER_NAME."
MESSAGES[pl,waiting_container]="Czekanie na start $CONTAINER_NAME (max 60s)..."
MESSAGES[pl,waiting_progress]="Czekanie... (%ds)"
MESSAGES[pl,container_failed]="$CONTAINER_NAME nie wystartował. Sprawdź logi."
MESSAGES[pl,setting_dns]="Ustawianie DNS (8.8.8.8) w kontenerze..."
MESSAGES[pl,installing_deps]="Instalacja zależności (gpsd, net-tools, itp.) w Ubuntu..."
MESSAGES[pl,deps_error]="Błąd instalacji zależności."
MESSAGES[pl,installing_docker]="Instalacja Dockera i compose w kontenerze..."
MESSAGES[pl,docker_error]="Błąd instalacji Dockera."
MESSAGES[pl,configuring_startup]="Tworzenie start-piphi.sh (dockerd + PiPhi + GPS)..."
MESSAGES[pl,install_complete]="Przygotowanie zakończone. start-piphi.sh uruchomi PiPhi + GPS."
MESSAGES[pl,check_ps]="Kontenery: balena ps (host) i balena exec $CONTAINER_NAME docker ps (wewnątrz)."
MESSAGES[pl,gps_check]="GPS: uruchamiany automatycznie w start-piphi.sh (cgps opcjonalnie)."
MESSAGES[pl,logs_check]="Logi PiPhi: balena exec $CONTAINER_NAME docker logs piphi-network-image"

MESSAGES[en,header]="Preparing PiPhi Network on SenseCAP M1 (balenaOS)"
MESSAGES[en,separator]="=============================================================="
MESSAGES[en,wget_missing]="wget not installed on host. Install wget or download files manually."
MESSAGES[en,changing_dir]="Using install directory: $INSTALL_DIR ..."
MESSAGES[en,dir_error]="Error changing directory to $INSTALL_DIR"
MESSAGES[en,checking_existing]="Checking existing containers (Helium etc.)..."
MESSAGES[en,existing_found]="Found containers: %s (PiPhi will run alongside)."
MESSAGES[en,loading_gps]="Loading GPS module (cdc-acm)..."
MESSAGES[en,gps_detected]="GPS detected: %s"
MESSAGES[en,gps_not_detected]="GPS not detected. Plug U-Blox 7 and check lsusb/ls /dev/ttyACM*."
MESSAGES[en,removing_old]="Removing old PiPhi installation / old $CONTAINER_NAME..."
MESSAGES[en,downloading_compose]="Downloading PiPhi docker-compose.yml..."
MESSAGES[en,download_error]="Error downloading docker-compose.yml"
MESSAGES[en,updating_compose]="Updating docker-compose.yml (GPS + volumes)..."
MESSAGES[en,pulling_ubuntu]="Pulling Ubuntu image (attempt %d/3)..."
MESSAGES[en,pull_error]="Error pulling Ubuntu after 3 attempts."
MESSAGES[en,running_container]="Running base container $CONTAINER_NAME..."
MESSAGES[en,run_error]="Error running $CONTAINER_NAME. Check balena logs $CONTAINER_NAME."
MESSAGES[en,waiting_container]="Waiting for $CONTAINER_NAME to start (max 60s)..."
MESSAGES[en,waiting_progress]="Waiting... (%ds)"
MESSAGES[en,container_failed]="$CONTAINER_NAME failed to start. Check logs."
MESSAGES[en,setting_dns]="Setting DNS (8.8.8.8) in container..."
MESSAGES[en,installing_deps]="Installing dependencies (gpsd, net-tools, etc.) in Ubuntu..."
MESSAGES[en,deps_error]="Error installing dependencies."
MESSAGES[en,installing_docker]="Installing Docker and compose in container..."
MESSAGES[en,docker_error]="Error installing Docker."
MESSAGES[en,configuring_startup]="Creating start-piphi.sh (dockerd + PiPhi + GPS)..."
MESSAGES[en,install_complete]="Preparation complete. start-piphi.sh will start PiPhi + GPS."
MESSAGES[en,check_ps]="Containers: balena ps (host) and balena exec $CONTAINER_NAME docker ps (inside)."
MESSAGES[en,gps_check]="GPS: started automatically in start-piphi.sh (cgps optional)."
MESSAGES[en,logs_check]="PiPhi logs: balena exec $CONTAINER_NAME docker logs piphi-network-image"

function msg() {
    local key=$1
    printf "${MESSAGES[$LANGUAGE,$key]}\n" "${@:2}"
}

# ===== HELPERS =====

function wait_for_container() {
    local container=$1
    local max_wait=$2
    for i in $(seq 1 $((max_wait/5))); do
        if balena ps -a | grep "$container" | grep -q "Up"; then
            sleep 5
            return 0
        fi
        msg "waiting_progress" $((i*5))
        sleep 5
    done
    msg "container_failed"
    return 1
}

function exec_with_retry() {
    local cmd=$1
    local max_attempts=3
    for attempt in $(seq 1 $max_attempts); do
        if balena exec "$CONTAINER_NAME" bash -c "$cmd"; then
            return 0
        fi
        msg "waiting_progress" $((attempt*5))
        sleep 5
    done
    return 1
}

# ===== MAIN INSTALL / PREPARE =====

function install_piphi() {
    msg "header"
    msg "separator"

    if ! command -v wget >/dev/null 2>&1; then
        msg "wget_missing"
        exit 1
    fi

    msg "changing_dir"
    mkdir -p "$INSTALL_DIR"
    cd "$INSTALL_DIR" || { msg "dir_error"; exit 1; }

    msg "checking_existing"
    local existing_containers
    existing_containers=$(balena ps --format "{{.Names}}" || true)
    if [ -n "$existing_containers" ]; then
        msg "existing_found" "$existing_containers"
    fi

    msg "loading_gps"
    modprobe cdc-acm 2>/dev/null || true
    if ls "$GPS_DEVICE" >/dev/null 2>&1; then
        msg "gps_detected" "$GPS_DEVICE"
    else
        msg "gps_not_detected"
        # NIE przerywamy instalacji – pozwalamy zainstalować PiPhi, GPS można dodać później
    fi

    msg "removing_old"
    balena stop "$CONTAINER_NAME" 2>/dev/null || true
    balena rm "$CONTAINER_NAME" 2>/dev/null || true
    rm -rf "$INSTALL_DIR"/* 2>/dev/null || true

    msg "downloading_compose"
    wget -O docker-compose.yml "$COMPOSE_URL" || { msg "download_error"; exit 1; }

    msg "updating_compose"
    # wywal stary 'version:' (nie jest potrzebny w v2 compose)
    sed -i '/^version:/d' docker-compose.yml

    # dodaj GPS do software (devices + environment) – poprawne YAML
    sed -i '/software:/a \    devices:\n      - "'"$GPS_DEVICE"':'"$GPS_DEVICE"'"' docker-compose.yml
    sed -i '/software:/a \    environment:\n      - "GPS_DEVICE='"$GPS_DEVICE"'"' docker-compose.yml

    # popraw grafanę – używaj nazwanych volume zamiast bind do /var/lib/grafana
    sed -i 's#- /var/lib/grafana#- grafana:/var/lib/grafana#' docker-compose.yml

    # upewnij się, że na dole jest jeden blok volumes: z db + grafana
    awk '
/^volumes:/ {exit}
{print}
' docker-compose.yml > docker-compose.head

    cat << 'EOF' >> docker-compose.head
volumes:
  db:
    driver: local
  grafana:
    driver: local
EOF

    mv docker-compose.head docker-compose.yml

    for attempt in {1..3}; do
        msg "pulling_ubuntu" "$attempt"
        if balena pull "$UBUNTU_IMAGE"; then
            break
        fi
        if [ "$attempt" -eq 3 ]; then
            msg "pull_error"
            exit 1
        fi
        sleep 5
    done

    msg "running_container"
    balena run -d --privileged \
        --device "$GPS_DEVICE" \
        -v "$INSTALL_DIR":/piphi-network \
        -p 31415:31415 -p 5432:5432 -p 3000:3000 \
        --name "$CONTAINER_NAME" \
        --restart unless-stopped \
        "$UBUNTU_IMAGE" \
        /bin/bash -c "while true; do sleep 3600; done" \
        || { msg "run_error"; exit 1; }

    msg "waiting_container"
    wait_for_container "$CONTAINER_NAME" 60 || exit 1

    msg "setting_dns"
    exec_with_retry "echo 'nameserver 8.8.8.8' > /etc/resolv.conf" || { msg "deps_error"; exit 1; }

    msg "installing_deps"
    exec_with_retry "apt-get update && apt-get install -y ca-certificates curl gnupg lsb-release usbutils gpsd gpsd-clients iputils-ping netcat" || { msg "deps_error"; exit 1; }

    msg "installing_docker"
    exec_with_retry "mkdir -p /etc/apt/keyrings && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg" || { msg "docker_error"; exit 1; }
    exec_with_retry "echo 'deb [arch=arm64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu focal stable' > /etc/apt/sources.list.d/docker.list" || { msg "docker_error"; exit 1; }
    exec_with_retry "apt-get update && apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin" || { msg "docker_error"; exit 1; }

    msg "configuring_startup"
    exec_with_retry "cat > /piphi-network/start-piphi.sh << 'EOL'
#!/bin/bash
# Helper script – start PiPhi + GPS inside ubuntu-piphi
cd /piphi-network

echo \"Ensuring old dockerd is not running...\"
if pgrep dockerd >/dev/null 2>&1; then
  echo \"Killing old dockerd...\"
  pkill dockerd || true
  sleep 5
fi

echo \"Removing stale /var/run/docker.pid if exists...\"
rm -f /var/run/docker.pid

echo \"Starting Docker daemon...\"
dockerd --host=unix:///var/run/docker.sock > /piphi-network/dockerd.log 2>&1 &
sleep 10

echo \"Checking docker ps...\"
docker ps || true

echo \"Stage 1 — starting db + grafana...\"
docker compose -f docker-compose.yml up -d db grafana
sleep 20
docker ps || true

echo \"Stage 2 — starting PiPhi software + watchtower...\"
docker compose -f docker-compose.yml up -d software watchtower
sleep 10
docker ps || true

echo \"Starting GPS...\"
gpsd /dev/ttyACM0 -F /var/run/gpsd.sock &
sleep 5

echo \"PiPhi + GPS started. You can now open the web UI.\"
EOL" || { msg "docker_error"; exit 1; }
    exec_with_retry "chmod +x /piphi-network/start-piphi.sh" || { msg "docker_error"; exit 1; }

    msg "install_complete"
    msg "check_ps"
    msg "gps_check"
    msg "logs_check"
}

# ===== MENU =====

msg "separator"
if [ "$LANGUAGE" = "pl" ]; then
    echo "Skrypt przygotowania PiPhi na SenseCAP M1 (balenaOS)"
    echo "1 - Przygotuj / przeinstaluj PiPhi (start-piphi.sh uruchamia PiPhi + GPS)"
    echo "2 - Wyjście"
    echo "3 - Zmień język (PL/EN)"
else
    echo "PiPhi preparation script for SenseCAP M1 (balenaOS)"
    echo "1 - Prepare / reinstall PiPhi (start-piphi.sh runs PiPhi + GPS)"
    echo "2 - Exit"
    echo "3 - Change language (PL/EN)"
fi
msg "separator"
read -rp "Wybierz opcję / Choose option: " REPLY

case "$REPLY" in
    1) clear; install_piphi ;;
    2) exit 0 ;;
    3) set_language; clear; "$0" ;;
esac
