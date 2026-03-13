# 🛰️ PiPhi on SenseCAP M1 (balenaOS)

![Docker](https://img.shields.io/badge/docker-compose-blue)
![Platform](https://img.shields.io/badge/platform-balenaOS-green)
![Hardware](https://img.shields.io/badge/device-SenseCAP%20M1-orange)
![License](https://img.shields.io/badge/license-MIT-lightgrey)

![Flow](img/flow-sensecap-piphi-watchdog.png)

Run the **PiPhi network stack** on a **SenseCAP M1** device using **balenaOS** and a **USB GPS module**, with an optional **PiPhi Watchdog** for automatic recovery of the PiPhi panel.

This repository provides helper scripts that prepare a **safe PiPhi environment inside an Ubuntu container** (`ubuntu-piphi`) and an optional **watchdog container** running on the balenaOS host.

The PiPhi installer:

- prepares the environment under `/mnt/data/piphi`
- automatically modifies `docker-compose.yml` (GPS configuration, devices, volumes)
- creates a **defensive `start-piphi.sh`** that:
  - ensures old `dockerd` is stopped
  - starts the Docker daemon inside `ubuntu-piphi`
  - starts PiPhi stack in two stages (db+grafana → software+watchtower)
  - starts GPSD

**Important**

- After first installation, **PiPhi is started manually** inside `ubuntu-piphi` using `./start-piphi.sh`
- The **PiPhi Watchdog for balenaOS** can later be installed to **automatically start and recover** PiPhi using the same `start-piphi.sh`

---

# 🌐 Language / Język

- 🇬🇧 [English Documentation](#-english-documentation)
- 🇵🇱 [Dokumentacja po Polsku](#-dokumentacja-po-polsku)

---

# 🏗 Architecture

The environment runs PiPhi **inside a nested Docker environment** to isolate it from the default SenseCAP miner stack, plus an optional watchdog container on the balenaOS host.



SenseCAP M1 (balenaOS host)
│
├── balena-engine
│ │
│ ├── ubuntu-piphi (Ubuntu 20.04 container)
│ │ │
│ │ └── dockerd (nested Docker daemon)
│ │ │
│ │ └── PiPhi docker-compose stack
│ │ │
│ │ ┌───────────┴────────────┬───────────────┐
│ │ ▼ ▼ ▼
│ │ Database (PostgreSQL) Grafana PiPhi Software + GPSD
│ │
│ └── other SenseCAP containers (miner, gateway, etc.)
│
└── piphi-watchdog (optional)
│
├── HTTP checks on 127.0.0.1:31415
└── docker exec ubuntu-piphi ./start-piphi.sh


This approach ensures:

- SenseCAP base system remains stable
- PiPhi runs in an isolated environment
- GPS can be passed safely into the container
- Docker services can be restarted independently
- The optional **watchdog container** can automatically recover the PiPhi panel

---

<a id="-english-documentation"></a>
# 🇬🇧 English Documentation

## 📑 Table of Contents

- ⚙️ Requirements
- 🔐 SSH Root Access
- 📡 GPS Check
- 🚀 PiPhi Installation (SenseCAP host)
- 🐳 First Manual Start of PiPhi
- 🌍 Accessing Interfaces
- 📡 GPS Support (inside PiPhi)
- ⏱️ Optional: PiPhi Watchdog on balenaOS
- 🛠 Troubleshooting

---

# ⚙️ Requirements

Before installation make sure you have:

- **SenseCAP M1 device**
- **balenaOS running on SenseCAP**
- **root SSH access to the balenaOS host**
- **USB GPS module (recommended U-Blox 7)**
- Internet connection

---

# 🔐 SSH Root Access to SenseCAP M1

Before installing PiPhi you must have **root SSH access** to the SenseCAP M1 balenaOS host.

Full guide:

https://github.com/hattimon/miner_watchdog/blob/main/linki.md#jak-dosta%C4%87-si%C4%99-na-root-sensecap-m1-przez-ssh

The guide explains how to:

- enable SSH
- connect to SenseCAP
- obtain root shell
- manage the device via terminal

---

# 📡 Check GPS Device

On the SenseCAP balenaOS host:

```bash
ls /dev/ttyACM*

Expected:

/dev/ttyACM0

If the device is not present, plug in the GPS dongle and try again.

🚀 PiPhi Installation (SenseCAP host)

All commands below are run directly on the SenseCAP balenaOS host as root.

1. Download and run the PiPhi installer
mkdir -p /mnt/data/piphi
cd /mnt/data/piphi

curl -L https://raw.githubusercontent.com/hattimon/sensecapm1-piphi/main/install-piphi-sensecapm1.sh -o install-piphi-sensecapm1.sh
chmod +x install-piphi-sensecapm1.sh

./install-piphi-sensecapm1.sh

During installation the script will:

check /dev/ttyACM0

download PiPhi docker-compose.yml

inject GPS configuration

fix Grafana volumes

create /mnt/data/piphi

pull ubuntu:20.04

create the ubuntu-piphi container

install Docker + Docker Compose inside the container

generate /piphi-network/start-piphi.sh

The installer does NOT automatically start PiPhi.
First start is manual so logs and resource usage can be observed.

2. Verify ubuntu-piphi container

On the SenseCAP host:

balena ps

You should see:

ubuntu-piphi (Up)

If not running:

balena logs ubuntu-piphi
🐳 First Manual Start of PiPhi

Enter container:

balena exec -it ubuntu-piphi bash
cd /piphi-network

Run:

./start-piphi.sh

The script will:

stop old dockerd

start Docker daemon

start db + grafana

start software + watchtower

start GPSD

Expected message:

PiPhi + GPS started. You can now open the web UI.
🌍 Accessing Interfaces

From your network:

PiPhi dashboard

http://YOUR_SENSECAP_IP:31415

Grafana dashboard

http://YOUR_SENSECAP_IP:3000
📡 GPS Support

PiPhi reads GPS from:

/dev/ttyACM0

Optional test:

gpsd -N -n /dev/ttyACM0 -F /var/run/gpsd.sock &
cgps -s
⏱️ Optional: PiPhi Watchdog on balenaOS

Install watchdog:

cd /mnt/data && \
curl -L https://raw.githubusercontent.com/hattimon/sensecapm1-piphi/main/piphi-watchdog/install-piphi-watchdog-balena.sh -o install-piphi-watchdog-balena.sh && \
chmod +x install-piphi-watchdog-balena.sh && \
./install-piphi-watchdog-balena.sh

Watchdog:

waits 60s after boot

checks http://127.0.0.1:31415

after 3 failures executes

docker exec ubuntu-piphi ./start-piphi.sh
🛠 Troubleshooting

Inside container:

docker ps
docker compose logs
docker logs piphi-network-image

Dockerd logs:

cat /piphi-network/dockerd.log | tail -n 50




🇵🇱 Dokumentacja po Polsku
📑 Spis treści

Wymagania

Dostęp SSH root

Sprawdzenie GPS

Instalacja PiPhi

Pierwsze uruchomienie

Dostęp do paneli

Watchdog

Rozwiązywanie problemów

⚙️ Wymagania

Potrzebujesz:

SenseCAP M1

balenaOS

dostęp SSH root

GPS USB (U-Blox 7)

🔐 Dostęp SSH root

Instrukcja:

https://github.com/hattimon/miner_watchdog/blob/main/linki.md#jak-dosta%C4%87-si%C4%99-na-root-sensecap-m1-przez-ssh

📡 Sprawdzenie GPS

Na hoście:

ls /dev/ttyACM*

Powinno być:

/dev/ttyACM0
🚀 Instalacja PiPhi
mkdir -p /mnt/data/piphi
cd /mnt/data/piphi

curl -L https://raw.githubusercontent.com/hattimon/sensecapm1-piphi/main/install-piphi-sensecapm1.sh -o install-piphi-sensecapm1.sh
chmod +x install-piphi-sensecapm1.sh

./install-piphi-sensecapm1.sh
🐳 Pierwsze uruchomienie
balena exec -it ubuntu-piphi bash
cd /piphi-network

./start-piphi.sh
🌍 Dostęp do paneli

PiPhi

http://IP_SENSECAP:31415

Grafana

http://IP_SENSECAP:3000
⏱️ Watchdog
cd /mnt/data
curl -L https://raw.githubusercontent.com/hattimon/sensecapm1-piphi/main/piphi-watchdog/install-piphi-watchdog-balena.sh -o install-piphi-watchdog-balena.sh
chmod +x install-piphi-watchdog-balena.sh
./install-piphi-watchdog-balena.sh
🛠 Rozwiązywanie problemów

Kontenery:

balena ps

Logi:

balena logs ubuntu-piphi

W kontenerze:

docker compose logs

License: MIT
