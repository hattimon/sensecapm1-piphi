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
