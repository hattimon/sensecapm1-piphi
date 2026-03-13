# 🛰️ PiPhi Watchdog for SenseCAP M1 (balenaOS)

![Architecture](https://img.shields.io/badge/architecture-watchdog%20recovery-blue)
![Platform](https://img.shields.io/badge/platform-balenaOS-green)
![Environment](https://img.shields.io/badge/environment-balena%20host-orange)
![Device](https://img.shields.io/badge/device-SenseCAP%20M1-lightgrey)
![License](https://img.shields.io/github/license/hattimon/sensecapm1-piphi)
![GitHub Stars](https://img.shields.io/github/stars/hattimon/sensecapm1-piphi?style=social)

Automatic **recovery watchdog for PiPhi running directly on SenseCAP M1 (balenaOS)**.

The watchdog runs as a **balenaOS container on the SenseCAP host** and automatically restores the **PiPhi panel and containers** if the system becomes unavailable due to:

- power outages
- device reboot
- container crashes
- docker daemon issues inside `ubuntu-piphi`

The system uses **safe recovery logic with backoff** to avoid unnecessary restart loops and to give **GPS time to reacquire a fix**.

---

# 🌐 Language / Język

- 🇬🇧 [English Documentation](#english-documentation)
- 🇵🇱 [Dokumentacja po Polsku](#dokumentacja-po-polsku)

---

# ✨ Features

⚡ **Automatic PiPhi panel monitoring**  
Periodically checks the PiPhi web UI on the SenseCAP host (`http://127.0.0.1:31415/`).

🐳 **Host-level watchdog container**  
Runs as a container on balenaOS and talks to `balena-engine` via the Docker socket.

🧩 **Installer-generated watchdog script**  
The installer builds a **small Alpine image with a generated `watchdog.sh`**, tailored to your configuration.

🧠 **Smart recovery logic with backoff**  
Avoids tight restart loops and gives the system time to boot PiPhi and GPS.

🛰 **Integrated GPS startup**  
Relies on `start-piphi.sh` inside `ubuntu-piphi` to start **dockerd + PiPhi stack + GPSD**.

🔁 **Automatic recovery after reboot**  
The watchdog container is created with `--restart unless-stopped`, so it is started automatically by balenaOS.

---

# 🏗 Architecture

```mermaid
flowchart LR
    SC["SenseCAP M1 (balenaOS host)"]
    SC -->|balena-engine| WD["piphi-watchdog container"]
    SC -->|balena-engine| UB["ubuntu-piphi container"]
    UB -->|Docker| PS["PiPhi stack + GPSD"]

    WD -->|HTTP check 31415| SC
    WD -->|docker exec start-piphi.sh| UB
```

- **SenseCAP M1** – runs **balenaOS** and multiple containers (`ubuntu-piphi`, miner, etc.).
- **piphi-watchdog** – small Alpine container with `docker-cli` and `watchdog.sh`, monitoring the PiPhi panel.
- **ubuntu-piphi** – Ubuntu container prepared by your PiPhi installer script.
- **PiPhi stack + GPSD** – database, Grafana, PiPhi app, Watchtower and GPS daemon, started via `start-piphi.sh`.

---

<a id="english-documentation"></a>

# 🇬🇧 English Documentation

## 📦 Repository Files (watchdog for balenaOS)

| File | Description |
|------|-------------|
| `piphi-watchdog/install-piphi-watchdog-balena.sh` | Watchdog installer for balenaOS (SenseCAP M1) |
| `piphi-watchdog/` | Directory for watchdog-related files |

The installer **does NOT download `watchdog.sh` from GitHub** at runtime.  
Instead it **generates `watchdog.sh` locally** and builds a small image around it.

---

## ⚙️ Requirements

Before installation on SenseCAP M1 you need:

- SenseCAP M1 running **balenaOS** with:
  - `balena` CLI available on the host shell
  - `ubuntu-piphi` container installed and prepared with **PiPhi + `start-piphi.sh`**

A working PiPhi installation reachable on the host as:

```
http://127.0.0.1:31415/
```

Access to the **host shell** of the SenseCAP M1 (via SSH or console).

Verify `curl` is available:

```bash
curl --version
```

Example:

```
curl 7.69.1 (aarch64-poky-linux-gnu)
```

On reference SenseCAP M1 devices with balenaOS, `curl` is available by default.

---

# 🚀 Installation (on SenseCAP balenaOS host)

On the SenseCAP host shell (logged into balenaOS as root):

```bash
cd /mnt/data && \
curl -L https://raw.githubusercontent.com/hattimon/sensecapm1-piphi/main/piphi-watchdog/install-piphi-watchdog-balena.sh -o install-piphi-watchdog-balena.sh && \
chmod +x install-piphi-watchdog-balena.sh && \
./install-piphi-watchdog-balena.sh
```

The installer will:

- Ask for language selection (English default, Polish optional)
- Generate `watchdog.sh`
- Build the `piphi-watchdog-balena:latest` image
- Remove any existing `piphi-watchdog` container
- Start a new watchdog container with `--restart unless-stopped`

---

## 🔧 What the Installer Does

The installer:

Creates install directory:

```
/mnt/data/piphi-watchdog-balena
```

Generates `watchdog.sh` with:

- HTTP checks on `127.0.0.1:31415`
- Boot delay **BOOT_DELAY = 60 seconds**
- Check interval **60 seconds**
- Recovery logic via `start-piphi.sh`
- English or Polish logs

Builds a Docker image:

```
piphi-watchdog-balena:latest
```

Removes old container:

```
piphi-watchdog
```

Runs watchdog container:

```bash
balena run -d \
  --name piphi-watchdog \
  --restart unless-stopped \
  --net host \
  -e PIPHI_PORT="31415" \
  -e CHECK_INTERVAL="60" \
  -e BOOT_DELAY="60" \
  -e UBUNTU_PIPHI_NAME="ubuntu-piphi" \
  -e LANGUAGE="en|pl" \
  -v /run/balena-engine.sock:/var/run/docker.sock \
  -e DOCKER_HOST="unix:///var/run/docker.sock" \
  piphi-watchdog-balena:latest
```

---

# 🔁 Recovery Logic

## Stage 0 — Initial Warmup (BOOT_DELAY = 60s)

After SenseCAP boot or watchdog start:

- watchdog waits **60 seconds**
- allows:
  - `ubuntu-piphi` to start
  - Docker inside container to start
  - PiPhi stack initialization
  - GPSD startup

No checks during warmup.

---

## Stage 1 — Panel Check (every 60s)

```bash
curl -s --max-time 5 http://127.0.0.1:31415/
```

If panel works → nothing happens  
If panel fails → Stage 2

---

## Stage 2 — Failure Counting

Watchdog:

1. Logs failure
2. Runs `docker ps`
3. Checks if `ubuntu-piphi` is running
4. If stopped → `docker restart ubuntu-piphi`
5. Increments `consecutive_failures`

If failures < 3 → wait  
If failures ≥ 3 → Stage 3

---

## Stage 3 — Full Recovery

```bash
docker exec ubuntu-piphi sh -lc 'cd /piphi-network && ./start-piphi.sh'
```

Then watchdog waits:

```
POST_RESTART_DELAY = 300 seconds
```

If panel returns → reset counter  
If still down → repeat recovery logic

---

# 📋 Logs and Monitoring

## Watchdog logs

```bash
balena logs -f piphi-watchdog
```

Logs are written to container stdout and visible via:

- `balena logs`
- balenaCloud dashboard

Language depends on installer selection.

---

## List containers

```bash
balena ps
```

Look for:

- `piphi-watchdog`
- `ubuntu-piphi`

Check PiPhi containers inside ubuntu-piphi:

```bash
balena exec -it ubuntu-piphi docker ps
```

---

<a id="dokumentacja-po-polsku"></a>

# 🇵🇱 Dokumentacja po Polsku

## 📦 Pliki w repozytorium

| Plik | Opis |
|------|------|
| `piphi-watchdog/install-piphi-watchdog-balena.sh` | Instalator watchdoga na balenaOS |
| `piphi-watchdog/` | Katalog z plikami watchdog |

Instalator **nie pobiera `watchdog.sh` z GitHuba**.

Zamiast tego **generuje go lokalnie i buduje obraz Docker**.

---

## ⚙️ Wymagania

- SenseCAP M1 z **balenaOS**
- dostęp do **balena CLI**
- kontener **ubuntu-piphi**
- działający panel PiPhi:

```
http://127.0.0.1:31415/
```

Sprawdzenie curl:

```bash
curl --version
```

Na SenseCAP M1 curl jest dostępny domyślnie.

---

# 🚀 Instalacja

Na hoście SenseCAP:

```bash
cd /mnt/data && \
curl -L https://raw.githubusercontent.com/hattimon/sensecapm1-piphi/main/piphi-watchdog/install-piphi-watchdog-balena.sh -o install-piphi-watchdog-balena.sh && \
chmod +x install-piphi-watchdog-balena.sh && \
./install-piphi-watchdog-balena.sh
```

Instalator:

- zapyta o język
- wygeneruje `watchdog.sh`
- zbuduje obraz `piphi-watchdog-balena`
- usunie stary kontener
- uruchomi nowy watchdog

---

# 🔁 Logika naprawy

## Etap 0 — BOOT_DELAY = 60s

Watchdog czeka 60 sekund aby:

- uruchomił się `ubuntu-piphi`
- wystartował dockerd
- uruchomił się stack PiPhi
- GPSD rozpoczął pracę

---

## Etap 1 — Sprawdzenie panelu

```bash
curl -s --max-time 5 http://127.0.0.1:31415/
```

panel działa → brak akcji  
panel nie działa → Etap 2

---

## Etap 2 — Licznik błędów

- log błędu
- `docker ps`
- sprawdzenie `ubuntu-piphi`
- restart jeśli potrzeba

Jeśli błędy ≥ 3 → Etap 3

---

## Etap 3 — Pełna naprawa

```bash
docker exec ubuntu-piphi sh -lc 'cd /piphi-network && ./start-piphi.sh'
```

Czekanie:

```
POST_RESTART_DELAY = 300s
```

Panel wraca → reset licznika

---

# 📋 Logi i monitoring

Logi:

```bash
balena logs -f piphi-watchdog
```

Lista kontenerów:

```bash
balena ps
```

Kontenery PiPhi:

```bash
balena exec -it ubuntu-piphi docker ps
```

---

# ⭐ Contributing

Pull requests are welcome.

- open an **Issue**
- submit a **Pull Request**

---

# 📄 License

Released under **MIT License**

See:

```
LICENSE
```
