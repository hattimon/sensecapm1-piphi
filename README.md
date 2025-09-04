# PiPhi Network Installation for SenseCAP M1 with balenaOS

This repository contains the `install-piphi.sh` script to install and configure the PiPhi Network alongside a Helium Miner on a SenseCAP M1 device running balenaOS. The script supports a USB GPS dongle (e.g., U-Blox 7) and ensures automatic startup on reboot, making the PiPhi panel available.

## Overview
- **Version**: 2.18
- **Author**: hattimon (with assistance from Grok, xAI)
- **Date**: September 02, 2025, 09:30 PM CEST
- **Last Updated**: September 04, 2025, 06:27 PM CEST
- **Requirements**: balenaOS (tested on 2.80.3+rev1), USB GPS dongle, SSH access as root
- **Repository**: [https://github.com/hattimon/sensecapm1-piphi/tree/main](https://github.com/hattimon/sensecapm1-piphi/tree/main)

## Features
- Installs PiPhi Network with dependencies (Docker, docker-compose, GPS support).
- Configures automatic startup of the Docker daemon and PiPhi services.
- Supports Helium Miner coexistence.
- Provides a web panel on port 31415 and Grafana on port 3000.

## Prerequisites
- SenseCAP M1 with balenaOS (version 2.80.3+rev1 or later).
- USB GPS dongle (e.g., U-Blox 7) connected to the device.
- SSH access to the device as root (enable SSH in balenaOS dashboard).
- Internet connectivity for downloading images and dependencies.

## Installation Instructions (English)

### Step 1: Prepare the Device
1. **Connect the GPS Dongle**: Plug in the U-Blox 7 GPS dongle to a USB port on the SenseCAP M1.
2. **Access the Device**: SSH into the device as root (e.g., `ssh root@<device-ip>`).
3. **Install wget** (if not already installed):
   ```
   apt-get update
   apt-get install -y wget
   ```

### Step 2: Download and Run the Installation Script
1. **Download the Script**:
   ```
   wget https://raw.githubusercontent.com/hattimon/sensecapm1-piphi/main/install-piphi.sh
   ```
2. **Make the Script Executable**:
   ```
   chmod +x install-piphi.sh
   ```
3. **Run the Script**:
   ```
   ./install-piphi.sh
   ```
   - The script will guide you through the installation process with a menu (options 1 for installation, 2 to exit, 3 to change language).
   - It checks for Helium containers, loads the GPS module, downloads `docker-compose.yml`, sets up an Ubuntu container, and installs PiPhi services.

### Step 3: Monitor Installation
- The script provides progress messages in English or Polish (configurable via the menu).
- If successful, the PiPhi panel will be available at `http://<device-ip>:31415` and Grafana at `http://<device-ip>:3000`.
- Check GPS status with:
  ```
  balena exec -it ubuntu-piphi cgps -s
  ```
  - Note: Place the device outdoors for a GPS fix (1–5 minutes).

### Step 4: Handle Potential Crash
The script may crash during the `docker pull` step for the Docker daemon due to network issues or resource constraints. If this happens:
1. **Restart the Device**:
   ```
   balena reboot
   ```
2. **Complete Installation Manually** (refer to `manual.md`):
   - Enter the container:
     ```
     balena exec -it ubuntu-piphi /bin/bash
     ```
   - Follow the manual steps in `manual.md` to install dependencies, start the Docker daemon, and run `docker compose up -d`.
   - Ensure the PiPhi panel is accessible after completion.

### Step 5: Verification
- Check running containers:
  ```
  balena ps
  balena exec ubuntu-piphi docker ps
  ```
- Expected containers: `ubuntu-piphi`, `piphi-network-image`, `db`, `watchtower`, `grafana`.
- View logs if needed:
  - PiPhi logs: `balena exec ubuntu-piphi docker logs piphi-network-image`
  - Docker logs: `balena exec ubuntu-piphi cat /piphi-network/dockerd.log`

## Troubleshooting (English)
- **GPS Not Detected**: Run `lsusb` on the host to verify the GPS dongle. Ensure the `cdc-acm` module is loaded (`modprobe cdc-acm`).
- **Network Issues**: Set DNS manually in the container:
  ```
  balena exec -it ubuntu-piphi bash -c "echo 'nameserver 8.8.8.8' > /etc/resolv.conf"
  ```
- **Crash During Installation**: Check logs with `balena logs ubuntu-piphi` and proceed with manual steps.
- **Panel Not Accessible**: Ensure ports 31415, 5432, and 3000 are open and not blocked by a firewall.

## Automatic Startup (English)
The script configures the Docker daemon and PiPhi services to start automatically on reboot using a startup script (`/piphi-network/start-docker.sh`) and container restart policies (`--restart unless-stopped`). If manual intervention was required, ensure cron jobs are set up as described in `manual.md`.

## Contributing
Feel free to submit issues or pull requests on [GitHub](https://github.com/hattimon/sensecapm1-piphi).

## License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

# Instrukcje Instalacji (Polski)

## Krok 1: Przygotowanie Urządzenia
1. **Podłącz Dongle GPS**: Włóż dongle GPS U-Blox 7 do portu USB SenseCAP M1.
2. **Uzyskaj Dostęp do Urządzenia**: Połącz się przez SSH jako root (np. `ssh root@<adres-ip-urządzenia>`).
3. **Zainstaluj wget** (jeśli nie jest zainstalowany):
   ```
   apt-get update
   apt-get install -y wget
   ```

## Krok 2: Pobierz i Uruchom Skrypt Instalacyjny
1. **Pobierz Skrypt**:
   ```
   wget https://raw.githubusercontent.com/hattimon/sensecapm1-piphi/main/install-piphi.sh
   ```
2. **Ustaw Uprawnienia Wykonywalności**:
   ```
   chmod +x install-piphi.sh
   ```
3. **Uruchom Skrypt**:
   ```
   ./install-piphi.sh
   ```
   - Skrypt przeprowadzi Cię przez proces instalacji za pomocą menu (opcja 1 do instalacji, 2 do wyjścia, 3 do zmiany języka).
   - Sprawdzi kontenery Helium, załaduje moduł GPS, pobierze `docker-compose.yml`, skonfiguruje kontener Ubuntu i zainstaluje usługi PiPhi.

## Krok 3: Monitorowanie Instalacji
- Skrypt wyświetla komunikaty postępów w języku angielskim lub polskim (można zmienić w menu).
- Jeśli instalacja się powiedzie, panel PiPhi będzie dostępny pod adresem `http://<adres-ip-urządzenia>:31415`, a Grafana pod `http://<adres-ip-urządzenia>:3000`.
- Sprawdź status GPS:
  ```
  balena exec -it ubuntu-piphi cgps -s
  ```
  - Uwaga: Umieść urządzenie na zewnątrz dla fix GPS (1–5 minut).

## Krok 4: Obsługa Potencjalnego Crashu
Skrypt może crashować podczas kroku `docker pull` dla demona Dockera z powodu problemów z siecią lub ograniczeń zasobów. Jeśli tak się stanie:
1. **Restart Urządzenia**:
   ```
   balena reboot
   ```
2. **Dokończ Instalację Ręcznie** (patrz `manual.md`):
   - Wejdź do kontenera:
     ```
     balena exec -it ubuntu-piphi /bin/bash
     ```
   - Postępuj zgodnie z instrukcjami manualnymi w `manual.md`, aby zainstalować zależności, uruchomić demona Dockera i wykonać `docker compose up -d`.
   - Upewnij się, że panel PiPhi jest dostępny po zakończeniu.

## Krok 5: Weryfikacja
- Sprawdź działające kontenery:
  ```
  balena ps
  balena exec ubuntu-piphi docker ps
  ```
- Oczekiwane kontenery: `ubuntu-piphi`, `piphi-network-image`, `db`, `watchtower`, `grafana`.
- Jeśli potrzebne, sprawdź logi:
  - Logi PiPhi: `balena exec ubuntu-piphi docker logs piphi-network-image`
  - Logi Dockera: `balena exec ubuntu-piphi cat /piphi-network/dockerd.log`

## Rozwiązywanie Problemów (Polski)
- **GPS Nie Wykryto**: Uruchom `lsusb` na hoście, aby zweryfikować dongle GPS. Upewnij się, że moduł `cdc-acm` jest załadowany (`modprobe cdc-acm`).
- **Problemy z Siecią**: Ustaw DNS ręcznie w kontenerze:
  ```
  balena exec -it ubuntu-piphi bash -c "echo 'nameserver 8.8.8.8' > /etc/resolv.conf"
  ```
- **Crash Podczas Instalacji**: Sprawdź logi za pomocą `balena logs ubuntu-piphi` i przejdź do kroków manualnych.
- **Panel Niedostępny**: Upewnij się, że porty 31415, 5432 i 3000 są otwarte i nie blokowane przez firewall.

## Automatyczny Start (Polski)
Skrypt konfiguruje demona Dockera i usługi PiPhi do automatycznego startu po restarcie za pomocą skryptu startowego (`/piphi-network/start-docker.sh`) i zasad restartu kontenera (`--restart unless-stopped`). Jeśli wymagana była interwencja manualna, upewnij się, że zadania cron są skonfigurowane zgodnie z opisem w `manual.md`.

## Wkład
Zachęcamy do zgłaszania problemów lub przesyłania pull requestów na [GitHub](https://github.com/hattimon/sensecapm1-piphi).

## Licencja
Ten projekt jest objęty licencją MIT - zobacz plik [LICENSE](LICENSE) po szczegóły.
