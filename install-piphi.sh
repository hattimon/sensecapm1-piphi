#!/bin/bash

# PiPhi Network Installation Script dla Balena OS (zainspirowany install-piphi-old.sh i skryptem ThingsIX)
# Wersja: 1.0
# Autor: Grok (na podstawie zapytań użytkownika)
# Data: 04 września 2025
# Opis: Instaluje kontenery PiPhi z docker-compose.yml w kontenerze Ubuntu, z GPS, automatycznym startem po restarcie.
# Wymagania: Balena OS, USB GPS (U-Blox 7), SSH jako root, /mnt/data writable.

# Ustaw język (domyślnie polski)
if [ -f /tmp/language ]; then
    LANGUAGE=$(cat /tmp/language)
else
    LANGUAGE="pl"
fi

# Funkcja zmiany języka
function set_language() {
    if [ "$LANGUAGE" = "pl" ]; then
        LANGUAGE="en"
        echo -e "Language changed to English."
        echo "en" > /tmp/language
    else
        LANGUAGE="pl"
        echo -e "Język zmieniony na polski."
        echo "pl" > /tmp/language
    fi
}

# Tłumaczenia
declare -A MESSAGES
MESSAGES[pl,header]="Instalacja PiPhi Network w Balena OS z GPS i auto-startem"
MESSAGES[pl,separator]="================================================================"
MESSAGES[pl,wget_missing]="Wget nie zainstalowany. Zainstaluj wget lub pobierz pliki ręcznie."
MESSAGES[pl,changing_dir]="Zmiana katalogu na /mnt/data/piphi-network..."
MESSAGES[pl,dir_error]="Błąd zmiany katalogu na /mnt/data/piphi-network"
MESSAGES[pl,checking_existing]="Sprawdzanie istniejących kontenerów (np. Helium)..."
MESSAGES[pl,existing_found]="Znaleziono kontenery: %s. PiPhi będzie działać obok nich."
MESSAGES[pl,loading_gps]="Ładowanie modułu GPS (cdc-acm)..."
MESSAGES[pl,gps_detected]="GPS wykryty: %s"
MESSAGES[pl,gps_not_detected]="GPS nie wykryty. Podłącz U-Blox 7 i sprawdź lsusb."
MESSAGES[pl,removing_old]="Usuwanie starych instalacji PiPhi..."
MESSAGES[pl,downloading_compose]="Pobieranie docker-compose.yml..."
MESSAGES[pl,download_error]="Błąd pobierania docker-compose.yml"
MESSAGES[pl,updating_compose]="Aktualizacja docker-compose.yml (dodanie GPS)..."
MESSAGES[pl,pulling_ubuntu]="Pobieranie obrazu Ubuntu (próba %d/3)..."
MESSAGES[pl,pull_error]="Błąd pobierania Ubuntu po 3 próbach"
MESSAGES[pl,running_container]="Uruchamianie kontenera bazowego ubuntu-piphi..."
MESSAGES[pl,run_error]="Błąd uruchamiania ubuntu-piphi. Sprawdź balena logs ubuntu-piphi"
MESSAGES[pl,waiting_container]="Czekanie na start ubuntu-piphi (max 60s)..."
MESSAGES[pl,waiting_progress]="Czekanie... (%ds)"
MESSAGES[pl,container_failed]="ubuntu-piphi nie wystartował. Sprawdź logi."
MESSAGES[pl,setting_dns]="Ustawianie DNS (8.8.8.8) w kontenerze..."
MESSAGES[pl,installing_deps]="Instalacja zależności w Ubuntu..."
MESSAGES[pl,deps_error]="Błąd instalacji zależności."
MESSAGES[pl,installing_docker]="Instalacja Dockera i compose w kontenerze..."
MESSAGES[pl,docker_error]="Błąd instalacji Dockera."
MESSAGES[pl,configuring_startup]="Konfiguracja auto-startu Dockera i usług PiPhi..."
MESSAGES[pl,starting_daemon]="Uruchamianie daemona Dockera..."
MESSAGES[pl,daemon_error]="Błąd startu daemona Dockera."
MESSAGES[pl,starting_services]="Uruchamianie usług PiPhi (z compose)..."
MESSAGES[pl,services_error]="Błąd startu usług. Próba %d/3..."
MESSAGES[pl,services_success]="Usługi PiPhi uruchomione!"
MESSAGES[pl,waiting_panel]="Czekanie na panel PiPhi (port 31415, max 60s)..."
MESSAGES[pl,panel_success]="Panel dostępny: http://<IP>:31415"
MESSAGES[pl,panel_error]="Panel nie dostępny po 60s."
MESSAGES[pl,install_complete]="Instalacja zakończona! Auto-start po restarcie włączony."
MESSAGES[pl,check_ps]="Sprawdź kontenery: balena ps (na hoście) i balena exec ubuntu-piphi docker ps (wewnątrz)"
MESSAGES[pl,gps_check]="Sprawdź GPS: balena exec -it ubuntu-piphi cgps -s"
MESSAGES[pl,logs_check]="Logi: balena exec ubuntu-piphi docker logs piphi-network-image"

MESSAGES[en,header]="Installing PiPhi Network in Balena OS with GPS and auto-start"
MESSAGES[en,separator]="================================================================"
MESSAGES[en,wget_missing]="Wget not installed. Install wget or download files manually."
MESSAGES[en,changing_dir]="Changing directory to /mnt/data/piphi-network..."
MESSAGES[en,dir_error]="Error changing directory to /mnt/data/piphi-network"
MESSAGES[en,checking_existing]="Checking existing containers (e.g., Helium)..."
MESSAGES[en,existing_found]="Found containers: %s. PiPhi will run alongside."
MESSAGES[en,loading_gps]="Loading GPS module (cdc-acm)..."
MESSAGES[en,gps_detected]="GPS detected: %s"
MESSAGES[en,gps_not_detected]="GPS not detected. Connect U-Blox 7 and check lsusb."
MESSAGES[en,removing_old]="Removing old PiPhi installations..."
MESSAGES[en,downloading_compose]="Downloading docker-compose.yml..."
MESSAGES[en,download_error]="Error downloading docker-compose.yml"
MESSAGES[en,updating_compose]="Updating docker-compose.yml (adding GPS)..."
MESSAGES[en,pulling_ubuntu]="Pulling Ubuntu image (attempt %d/3)..."
MESSAGES[en,pull_error]="Error pulling Ubuntu after 3 attempts"
MESSAGES[en,running_container]="Running base container ubuntu-piphi..."
MESSAGES[en,run_error]="Error running ubuntu-piphi. Check balena logs ubuntu-piphi"
MESSAGES[en,waiting_container]="Waiting for ubuntu-piphi to start (max 60s)..."
MESSAGES[en,waiting_progress]="Waiting... (%ds)"
MESSAGES[en,container_failed]="ubuntu-piphi failed to start. Check logs."
MESSAGES[en,setting_dns]="Setting DNS (8.8.8.8) in container..."
MESSAGES[en,installing_deps]="Installing dependencies in Ubuntu..."
MESSAGES[en,deps_error]="Error installing dependencies."
MESSAGES[en,installing_docker]="Installing Docker and compose in container..."
MESSAGES[en,docker_error]="Error installing Docker."
MESSAGES[en,configuring_startup]="Configuring auto-start for Docker and PiPhi services..."
MESSAGES[en,starting_daemon]="Starting Docker daemon..."
MESSAGES[en,daemon_error]="Error starting Docker daemon."
MESSAGES[en,starting_services]="Starting PiPhi services (from compose)..."
MESSAGES[en,services_error]="Error starting services. Attempt %d/3..."
MESSAGES[en,services_success]="PiPhi services started!"
MESSAGES[en,waiting_panel]="Waiting for PiPhi panel (port 31415, max 60s)..."
MESSAGES[en,panel_success]="Panel available: http://<IP>:31415"
MESSAGES[en,panel_error]="Panel not available after 60s."
MESSAGES[en,install_complete]="Installation complete! Auto-start on restart enabled."
MESSAGES[en,check_ps]="Check containers: balena ps (host) and balena exec ubuntu-piphi docker ps (inside)"
MESSAGES[en,gps_check]="Check GPS: balena exec -it ubuntu-piphi cgps -s"
MESSAGES[en,logs_check]="Logs: balena exec ubuntu-piphi docker logs piphi-network-image"

# Funkcja wyświetlania komunikatów
function msg() {
    local key=$1
    printf "${MESSAGES[$LANGUAGE,$key]}\n" "${@:2}"
}

# Funkcja czekania na kontener (Up state)
function wait_for_container() {
    local container=$1
    local max_wait=$2
    for i in $(seq 1 $((max_wait/5))); do
        if balena ps -a | grep "$container" | grep -q "Up"; then
            sleep 5  # Stabilizacja
            return 0
        fi
        msg "waiting_progress" $((i*5))
        sleep 5
    done
    msg "container_failed"
    exit 1
}

# Funkcja wykonania komendy w kontenerze z retry
function exec_with_retry() {
    local cmd=$1
    local max_attempts=3
    for attempt in $(seq 1 $max_attempts); do
        if balena exec ubuntu-piphi bash -c "$cmd"; then
            return 0
        fi
        msg "waiting_progress" $((attempt*5))
        sleep 5
    done
    return 1
}

# Funkcja instalacji
function install() {
    msg "header"
    msg "separator"

    # Sprawdź wget na hoście
    if ! command -v wget >/dev/null 2>&1; then
        msg "wget_missing"
        exit 1
    fi

    # Zmień katalog (writable)
    msg "changing_dir"
    mkdir -p /mnt/data/piphi-network
    cd /mnt/data/piphi-network || { msg "dir_error"; exit 1; }

    # Sprawdź istniejące kontenery (np. Helium, jak w skrypcie ThingsIX)
    msg "checking_existing"
    local existing_containers=$(balena ps --format "{{.Names}}" | grep pktfwd_ || true)
    if [ -n "$existing_containers" ]; then
        msg "existing_found" "$existing_containers"
    fi

    # Załaduj GPS na hoście
    msg "loading_gps"
    modprobe cdc-acm
    if ls /dev/ttyACM* >/dev/null 2>&1; then
        msg "gps_detected" "$(ls /dev/ttyACM*)"
    else
        msg "gps_not_detected"
        exit 1
    fi

    # Usuń stare PiPhi
    msg "removing_old"
    balena stop ubuntu-piphi 2>/dev/null || true
    balena rm ubuntu-piphi 2>/dev/null || true
    rm -rf /mnt/data/piphi-network/* 2>/dev/null || true

    # Pobierz docker-compose.yml
    msg "downloading_compose"
    wget -O docker-compose.yml https://chibisafe.piphi.network/m2JmK11Z7tor.yml || { msg "download_error"; exit 1; }

    # Aktualizuj compose (dodaj GPS jak w old.sh)
    msg "updating_compose"
    sed -i '/^version:/d' docker-compose.yml
    sed -i '/software:/a \    devices:\n      - "/dev/ttyACM0:/dev/ttyACM0"' docker-compose.yml
    sed -i '/software:/a \    environment:\n      - "GPS_DEVICE=/dev/ttyACM0"' docker-compose.yml
    sed -i '/grafana:/a \    volumes:\n      - grafana:/var/lib/grafana' docker-compose.yml
    cat >> docker-compose.yml << EOL

volumes:
  grafana:
    driver: local
EOL

    # Pobierz Ubuntu z retry
    for attempt in {1..3}; do
        msg "pulling_ubuntu" $attempt
        if balena pull ubuntu:20.04; then
            break
        fi
        if [ $attempt -eq 3 ]; then
            msg "pull_error"
            exit 1
        fi
        sleep 5
    done

    # Uruchom kontener bazowy (z auto-restart, mapowaniem GPS i volume)
    msg "running_container"
    balena run -d --privileged --device /dev/ttyACM0 -v /mnt/data/piphi-network:/piphi-network -p 31415:31415 -p 5432:5432 -p 3000:3000 --name ubuntu-piphi --restart unless-stopped ubuntu:20.04 /bin/bash -c "while true; do sleep 3600; done" || { msg "run_error"; exit 1; }

    # Czekaj na start
    msg "waiting_container"
    wait_for_container "ubuntu-piphi" 60

    # Ustaw DNS w kontenerze
    msg "setting_dns"
    exec_with_retry "echo 'nameserver 8.8.8.8' > /etc/resolv.conf" || { msg "deps_error"; exit 1; }

    # Instaluj zależności (w tym gpsd)
    msg "installing_deps"
    exec_with_retry "apt-get update && apt-get install -y ca-certificates curl gnupg lsb-release usbutils gpsd gpsd-clients iputils-ping netcat tzdata" || { msg "deps_error"; exit 1; }

    # Instaluj Docker i compose
    msg "installing_docker"
    exec_with_retry "mkdir -p /etc/apt/keyrings && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg" || { msg "docker_error"; exit 1; }
    exec_with_retry "echo 'deb [arch=arm64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu focal stable' > /etc/apt/sources.list.d/docker.list" || { msg "docker_error"; exit 1; }
    exec_with_retry "apt-get update && apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin" || { msg "docker_error"; exit 1; }

    # Konfiguruj auto-start (skrypt jak w old.sh i ThingsIX)
    msg "configuring_startup"
    exec_with_retry "cat > /piphi-network/start-piphi.sh << EOL
#!/bin/bash
dockerd --host=unix:///var/run/docker.sock > /piphi-network/dockerd.log 2>&1 &
sleep 10
cd /piphi-network && docker compose pull
cd /piphi-network && docker compose up -d
EOL" || { msg "daemon_error"; exit 1; }
    exec_with_retry "chmod +x /piphi-network/start-piphi.sh" || { msg "daemon_error"; exit 1; }

    # Uruchom daemon i usługi z retry
    msg "starting_daemon"
    exec_with_retry "/piphi-network/start-piphi.sh" || { msg "daemon_error"; exit 1; }
    for attempt in {1..3}; do
        msg "starting_services"
        if exec_with_retry "cd /piphi-network && docker compose up -d"; then
            msg "services_success"
            break
        fi
        msg "services_error" $attempt
        sleep 10
        if [ $attempt -eq 3 ]; then
            msg "daemon_error"
            exit 1
        fi
    done

    # Czekaj na panel
    msg "waiting_panel"
    for i in {1..12}; do
        if exec_with_retry "nc -z 127.0.0.1 31415"; then
            msg "panel_success"
            break
        fi
        msg "waiting_progress" $((i*5))
        sleep 5
        if [ $i -eq 12 ]; then
            msg "panel_error"
            exit 1
        fi
    done

    # Restart dla stabilności (jak w ThingsIX)
    balena restart ubuntu-piphi

    # Zakończenie
    msg "install_complete"
    msg "check_ps"
    msg "gps_check"
    msg "logs_check"
    echo -e "Uwaga: GPS fix trwa 1-5 min na zewnątrz. Watchtower aktualizuje obrazy automatycznie."
}

# Menu główne
msg "separator"
if [ "$LANGUAGE" = "pl" ]; then
    echo -e "Skrypt instalacji PiPhi w Balena OS"
    echo -e "1 - Instaluj PiPhi (z GPS i auto-startem)"
    echo -e "2 - Wyjście"
    echo -e "3 - Zmień na angielski"
else
    echo -e "PiPhi Installation Script for Balena OS"
    echo -e "1 - Install PiPhi (with GPS and auto-start)"
    echo -e "2 - Exit"
    echo -e "3 - Change to Polish"
fi
msg "separator"
read -rp "Wybierz opcję: "
case "$REPLY" in
    1) clear; install ;;
    2) exit ;;
    3) set_language; clear; . "$0" ;;
esac
