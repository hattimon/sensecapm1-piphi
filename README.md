# 🛰️ PiPhi on SenseCAP M1 (balenaOS)

![Docker](https://img.shields.io/badge/docker-compose-blue)
![Platform](https://img.shields.io/badge/platform-balenaOS-green)
![Hardware](https://img.shields.io/badge/device-SenseCAP%20M1-orange)
![License](https://img.shields.io/badge/license-MIT-lightgrey)

![Flow](img/flow-sensecap-piphi-watchdog.png)

Run the **PiPhi network stack** on a **SenseCAP M1** device using
**balenaOS** and a **USB GPS module**, with an optional **PiPhi
Watchdog** for automatic recovery of the PiPhi panel.

This repository provides helper scripts that prepare a **safe PiPhi
environment inside an Ubuntu container** (`ubuntu-piphi`) and an
optional **watchdog container** running on the balenaOS host.

------------------------------------------------------------------------

# 🌐 Language / Język

* 🇬🇧 [English Documentation](#-english-documentation)
* 🇵🇱 [Dokumentacja po Polsku](#-dokumentacja-po-polsku)

------------------------------------------------------------------------

# 🏗 Architecture

The environment runs PiPhi **inside a nested Docker environment** to isolate it from the default SenseCAP miner stack.

```
SenseCAP M1 (balenaOS host)
    │
    ├── balena-engine (host Docker daemon)
    │       │
    │       ├── ubuntu-piphi (Ubuntu 20.04 container)
    │       │         │
    │       │         └── dockerd (nested Docker daemon)
    │       │                   │
    │       │                   └── PiPhi docker-compose stack
    │       │                             ├── db
    │       │                             ├── grafana
    │       │                             ├── software
    │       │                             ├── watchtower
    │       │                             └── GPSD
    │       │
    │       └── other SenseCAP containers (miner, gateway-config, etc.)
    │
    └── piphi-watchdog (optional)
            │
            ├── HTTP checks on 127.0.0.1:31415 (host network, --net host)
            ├── docker ps / docker restart ubuntu-piphi (via /var/run/balena-engine.sock)
            └── docker exec ubuntu-piphi sh -lc 'cd /piphi-network && ./start-piphi.sh'
```

# 🇬🇧 English Documentation

## ⚙️ Requirements

Before installation make sure you have:

-   SenseCAP M1 device
-   balenaOS running
-   root SSH access
-   USB GPS module (recommended U‑Blox 7)
-   Internet connection

------------------------------------------------------------------------

## 🔐 SSH Root Access

Full guide:

https://github.com/hattimon/miner_watchdog/blob/main/linki.md#jak-dosta%C4%87-si%C4%99-na-root-sensecap-m1-przez-ssh

------------------------------------------------------------------------

## 📡 Check GPS Device

On SenseCAP host:

``` bash
ls /dev/ttyACM*
```

Expected:

    /dev/ttyACM0

------------------------------------------------------------------------

## 🚀 Install PiPhi

Run on the SenseCAP host:

``` bash
mkdir -p /mnt/data/piphi
cd /mnt/data/piphi

curl -L https://raw.githubusercontent.com/hattimon/sensecapm1-piphi/main/install-piphi-sensecapm1.sh -o install-piphi-sensecapm1.sh
chmod +x install-piphi-sensecapm1.sh

./install-piphi-sensecapm1.sh
```

Installer will:

-   prepare `/mnt/data/piphi`
-   download docker-compose
-   configure GPS
-   create container `ubuntu-piphi`
-   install Docker inside container
-   generate `start-piphi.sh`

------------------------------------------------------------------------

## 🐳 First Manual Start

Enter container:

```
balena exec -it ubuntu-piphi bash
cd /piphi-network
```

Start Docker daemon:

```
dockerd --host=unix:///var/run/docker.sock > /piphi-network/dockerd.log 2>&1 &
sleep 10
docker ps
```

---

## Stage 1 — Database + Grafana

```
docker compose -f docker-compose.yml up -d db grafana
sleep 20
docker ps
```

---

## Stage 2 — PiPhi + Watchtower

```
docker compose -f docker-compose.yml up -d software watchtower
```

------------------------------------------------------------------------

## 🌍 Access Interfaces

PiPhi:

    http://YOUR_SENSECAP_IP:31415

Grafana:

    http://YOUR_SENSECAP_IP:3000

------------------------------------------------------------------------

## ⏱️ Optional Watchdogs

### Install Local Watchdog

You can install a local watchdog that automatically monitors the PiPhi panel and attempts recovery if the system becomes unavailable.

See the full documentation here:

[FULL INSTRUCTION](piphi-watchdog/watchdog-balena.md)

Run the installer on the SenseCAP host:

```bash
cd /mnt/data && \
curl -L https://raw.githubusercontent.com/hattimon/sensecapm1-piphi/main/piphi-watchdog/install-piphi-watchdog-balena.sh -o install-piphi-watchdog-balena.sh && \
chmod +x install-piphi-watchdog-balena.sh && \
./install-piphi-watchdog-balena.sh
```

------------------------------------------------------------------------

# 🇵🇱 Dokumentacja po Polsku

## ⚙️ Wymagania

Potrzebujesz:

-   SenseCAP M1
-   balenaOS
-   dostęp SSH root
-   GPS USB (U‑Blox 7)

------------------------------------------------------------------------

## 📡 Sprawdzenie GPS

Na hoście:

``` bash
ls /dev/ttyACM*
```

Powinno pojawić się:

    /dev/ttyACM0

------------------------------------------------------------------------

## 🚀 Instalacja PiPhi

``` bash
mkdir -p /mnt/data/piphi
cd /mnt/data/piphi

curl -L https://raw.githubusercontent.com/hattimon/sensecapm1-piphi/main/install-piphi-sensecapm1.sh -o install-piphi-sensecapm1.sh
chmod +x install-piphi-sensecapm1.sh

./install-piphi-sensecapm1.sh
```

------------------------------------------------------------------------

## 🐳 Pierwsze uruchomienie

## Wejście do kontenera

```bash
balena exec -it ubuntu-piphi bash
cd /piphi-network
```

---

## Uruchomienie demona Docker

```bash
dockerd --host=unix:///var/run/docker.sock > /piphi-network/dockerd.log 2>&1 &
sleep 10
docker ps
```

---

## Etap 1 — Baza danych + Grafana

```bash
docker compose -f docker-compose.yml up -d db grafana
sleep 20
docker ps
```

---

## Etap 2 — PiPhi + Watchtower

```bash
docker compose -f docker-compose.yml up -d software watchtower
```

------------------------------------------------------------------------

## 🌍 Dostęp do paneli

PiPhi:

    http://IP_SENSECAP:31415

Grafana:

    http://IP_SENSECAP:3000

------------------------------------------------------------------------

## 🛠 Troubleshooting

Sprawdź kontenery:

``` bash
balena ps
```

Logi:

``` bash
balena logs ubuntu-piphi
```
------------------------------------------------------------------------

## ⏱️ Opcjonalny Watchdog

### Instalacja lokalnego watchdoga

Możesz zainstalować lokalny watchdog, który automatycznie monitoruje panel PiPhi i próbuje przywrócić system do działania, jeśli przestanie on odpowiadać.

Pełna dokumentacja znajduje się tutaj:

[PEŁNA INSTRUKCJA](piphi-watchdog/watchdog-balena.md)

Uruchom instalator na hoście SenseCAP:

```bash
cd /mnt/data && \
curl -L https://raw.githubusercontent.com/hattimon/sensecapm1-piphi/main/piphi-watchdog/install-piphi-watchdog-balena.sh -o install-piphi-watchdog-balena.sh && \
chmod +x install-piphi-watchdog-balena.sh && \
./install-piphi-watchdog-balena.sh
```

------------------------------------------------------------------------

License: MIT
