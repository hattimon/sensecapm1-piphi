# 🛰️ PiPhi on SenseCAP M1 (balenaOS)

Run the **PiPhi network stack** on a **SenseCAP M1** device using **balenaOS** and a **USB GPS module**.

This repository provides a helper script that prepares a **safe PiPhi environment inside a container**, preventing the main SenseCAP services from being overloaded.

---

# 🌐 Language / Język

* 🇬🇧 [English Documentation](#-english-documentation)
* 🇵🇱 [Dokumentacja po Polsku](#-dokumentacja-po-polsku)

---

# 🇬🇧 English Documentation

## 📑 Table of Contents

* ⚙️ [Requirements](#️-requirements)
* 🚀 [Quick Installation](#-quick-installation)
* 📁 [Manual Installation](#-manual-installation)
* 🐳 [Starting PiPhi](#-starting-piphi)
* 🌍 [Accessing the Interfaces](#-accessing-the-interfaces)
* 📡 [GPS Support](#-gps-support)
* 🛠 [Troubleshooting](#-troubleshooting)

---

# ⚙️ Requirements

Before installation make sure you have:

* 🛰 **SenseCAP M1** running **balenaOS**
* 🔐 **SSH access as root**
* 📡 **USB GPS module** (recommended: **U-Blox 7**)
* 🌐 Internet connection

Verify that the GPS device is detected:

```
ls /dev/ttyACM*
```

Expected result:

```
/dev/ttyACM0
```

---

# 🚀 Quick Installation

Connect to your SenseCAP via SSH and run:

```
mkdir -p /mnt/data/piphi
cd /mnt/data/piphi

wget https://raw.githubusercontent.com/hattimon/sensecapm1-piphi/main/install-piphi-sensecapm1.sh -O install-piphi-sensecapm1.sh
chmod +x install-piphi-sensecapm1.sh

./install-piphi-sensecapm1.sh
```

Then select:

```
1 - Prepare / reinstall PiPhi (without automatic start)
```

---

# 📁 Manual Installation

Create working directory:

```
mkdir -p /mnt/data/piphi
cd /mnt/data/piphi
```

Download installation script:

```
wget https://raw.githubusercontent.com/hattimon/sensecapm1-piphi/main/install-piphi-sensecapm1.sh -O install-piphi-sensecapm1.sh
chmod +x install-piphi-sensecapm1.sh
```

Run the installer:

```
./install-piphi-sensecapm1.sh
```

The script automatically:

* checks for `/dev/ttyACM0`
* downloads the latest **PiPhi docker-compose.yml**
* injects **GPS configuration**
* fixes **volume mappings**
* creates persistent directory `/mnt/data/piphi`
* pulls `ubuntu:20.04`
* creates container **ubuntu-piphi**
* installs **Docker + Docker Compose**
* creates helper script `/piphi-network/start-piphi.sh`

Verify container:

```
balena ps
```

Expected output:

```
ubuntu-piphi (Up)
```

---

# 🐳 Starting PiPhi

Enter the container:

```
balena exec -it ubuntu-piphi bash
cd /piphi-network
```

---

## Start Docker inside container

```
dockerd --host=unix:///var/run/docker.sock > /piphi-network/dockerd.log 2>&1 &
sleep 10
docker ps
```

Initially the list will be empty.

---

## Stage 1 — Database + Grafana

```
docker compose -f docker-compose.yml up -d db grafana
sleep 20
docker ps
```

Running containers:

* db
* grafana

Grafana interface:

```
http://YOUR_SENSECAP_IP:3000
```

---

## Stage 2 — PiPhi + Watchtower

```
docker compose -f docker-compose.yml up -d software watchtower
docker ps
```

Running containers:

* db
* grafana
* piphi-network-image
* watchtower

---

# 🌍 Accessing the Interfaces

After startup the following services should be available.

### PiPhi dashboard

```
http://YOUR_SENSECAP_IP:31415
```

### Grafana dashboard

```
http://YOUR_SENSECAP_IP:3000
```

---

# 📡 GPS Support

PiPhi accesses GPS through:

```
/dev/ttyACM0
```

---

# 🛠 Troubleshooting

### balenaEngine resets socket

Sometimes balenaEngine resets the Docker socket under heavy load.

Restart missing services:

```
docker compose up -d software
```

---

# 🇵🇱 Dokumentacja po Polsku

## 📑 Spis treści

* ⚙️ [Wymagania](#️-wymagania)
* 🚀 [Szybka instalacja](#-szybka-instalacja)
* 📁 [Instalacja ręczna](#-instalacja-ręczna)
* 🐳 [Uruchomienie PiPhi](#-uruchomienie-piphi)
* 🌍 [Dostęp do paneli](#-dostęp-do-paneli)
* 📡 [Obsługa GPS](#-obsługa-gps)
* 🛠 [Rozwiązywanie problemów](#-rozwiązywanie-problemów)

---

# ⚙️ Wymagania

Przed instalacją upewnij się, że masz:

* 🛰 **SenseCAP M1**
* 💿 **balenaOS**
* 🔐 dostęp **SSH root**
* 📡 **GPS USB** (np. U-Blox 7)
* 🌐 połączenie z internetem

Sprawdzenie czy GPS jest wykryty:

```
ls /dev/ttyACM*
```

Powinno zwrócić:

```
/dev/ttyACM0
```

---

# 🚀 Szybka instalacja

Połącz się z SenseCAP przez SSH i wykonaj:

```
mkdir -p /mnt/data/piphi
cd /mnt/data/piphi

wget https://raw.githubusercontent.com/hattimon/sensecapm1-piphi/main/install-piphi-sensecapm1.sh -O install-piphi-sensecapm1.sh
chmod +x install-piphi-sensecapm1.sh

./install-piphi-sensecapm1.sh
```

Następnie wybierz:

```
1 - Przygotuj / przeinstaluj PiPhi (bez automatycznego startu)
```

---

# 📁 Instalacja ręczna

Utwórz katalog roboczy:

```
mkdir -p /mnt/data/piphi
cd /mnt/data/piphi
```

Pobierz skrypt instalacyjny:

```
wget https://raw.githubusercontent.com/hattimon/sensecapm1-piphi/main/install-piphi-sensecapm1.sh -O install-piphi-sensecapm1.sh
chmod +x install-piphi-sensecapm1.sh
```

Uruchom instalator:

```
./install-piphi-sensecapm1.sh
```

Skrypt automatycznie:

* sprawdzi czy istnieje `/dev/ttyACM0`
* pobierze najnowszy **docker-compose.yml PiPhi**
* doda konfigurację **GPS**
* poprawi mapowanie **volume**
* utworzy katalog trwałych danych `/mnt/data/piphi`
* pobierze obraz `ubuntu:20.04`
* utworzy kontener **ubuntu-piphi**
* zainstaluje **Docker + Docker Compose**
* utworzy pomocniczy skrypt `/piphi-network/start-piphi.sh`

Sprawdzenie czy kontener działa:

```
balena ps
```

Oczekiwany wynik:

```
ubuntu-piphi (Up)
```

---

# 🐳 Uruchomienie PiPhi

Wejdź do kontenera:

```
balena exec -it ubuntu-piphi bash
cd /piphi-network
```

---

## Uruchomienie Dockera w kontenerze

```
dockerd --host=unix:///var/run/docker.sock > /piphi-network/dockerd.log 2>&1 &
sleep 10
docker ps
```

Na początku lista kontenerów będzie pusta.

---

## Etap 1 — baza danych + Grafana

```
docker compose -f docker-compose.yml up -d db grafana
sleep 20
docker ps
```

Uruchomione kontenery:

* db
* grafana

Panel Grafana:

```
http://IP_TWOJEGO_SENSECAP:3000
```

---

## Etap 2 — PiPhi + Watchtower

```
docker compose -f docker-compose.yml up -d software watchtower
docker ps
```

Uruchomione kontenery:

* db
* grafana
* piphi-network-image
* watchtower

---

# 🌍 Dostęp do paneli

Po uruchomieniu dostępne będą następujące interfejsy:

### Panel PiPhi

```
http://IP_TWOJEGO_SENSECAP:31415
```

### Panel Grafana

```
http://IP_TWOJEGO_SENSECAP:3000
```

Adres IP urządzenia można znaleźć:

* w routerze
* w lokalnej konsoli SenseCAP

---

# 📡 Obsługa GPS

PiPhi korzysta z GPS przez urządzenie:

```
/dev/ttyACM0
```

Test GPS (opcjonalny):

```
docker stop piphi-network-image

gpsd -N -n /dev/ttyACM0 -F /var/run/gpsd.sock &
sleep 3
cgps -s
```

Po teście uruchom ponownie PiPhi:

```
pkill gpsd || true
docker start piphi-network-image
```

W praktyce wystarczy sprawdzić status GPS w **interfejsie PiPhi**.

---

# 🛠 Rozwiązywanie problemów

### balenaEngine resetuje socket

Przy dużym obciążeniu balenaEngine może zresetować socket Dockera.

Uruchom ponownie brakujące usługi:

```
docker compose up -d software
```

lub

```
docker compose up -d watchtower
```

---

### GPS nie jest wykryty

Sprawdź:

```
ls /dev/ttyACM*
```

Jeśli nic nie pojawia się:

* odłącz i podłącz ponownie GPS
* uruchom ponownie SenseCAP

---

### Kontenery się nie uruchamiają

Sprawdź logi:

```
docker compose logs
```

lub:

```
docker logs piphi-network-image
```
