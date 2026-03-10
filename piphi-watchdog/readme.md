# 🛰️ PiPhi Watchdog for SenseCAP M1

![GitHub release](https://img.shields.io/github/v/release/hattimon/sensecapm1-piphi?color=blue&label=Release)
![GitHub license](https://img.shields.io/github/license/hattimon/sensecapm1-piphi)
![GitHub stars](https://img.shields.io/github/stars/hattimon/sensecapm1-piphi?style=social)

Optional **PiPhi watchdog** that runs on a Raspberry Pi to automatically restore PiPhi panel on your SenseCAP M1 if it goes down (power loss, reboot, container crash).

The watchdog:

- Periodically checks PiPhi web panel via HTTP
- Connects to SenseCAP M1 over SSH if panel is down
- Waits for the device boot
- Restarts required containers (`db`, `grafana`, `watchtower`, `piphi-network-image`)
- Runs automatically via `systemd --user` timer

> Connects to SenseCAP M1 as `sensecap_root` using existing SSH key.  
> Adding new key to SenseCAP balenaOS is blocked, so watchdog uses the key already loaded in `ssh-agent`.

---

# 🌐 Language / Język

- 🇬🇧 [English documentation](#english)
- 🇵🇱 [Dokumentacja po polsku](#polski)

---

# 🏗️ Architecture

flowchart LR
    RPi["Raspberry Pi (watchdog)"] -->|SSH| SC["SenseCAP M1"]
    SC -->|balenaEngine| UB["ubuntu-piphi container"]
    UB -->|Docker| PS["PiPhi stack"]

- **Raspberry Pi** – host watchdoga i `systemd --user` timer  
- **SenseCAP M1** – urządzenie z balenaOS i PiPhi w kontenerze  
- **ubuntu-piphi** – kontener przygotowany przez skrypt instalacyjny  
- **PiPhi stack** – baza danych, Grafana, aplikacja PiPhi, Watchtower  

---

# 🇬🇧 English documentation {#english}

## 📂 Files

- [`piphi-watchdog-setup.sh`](./piphi-watchdog-setup.sh) – interactive installer
- [`piphi-watchdog.sh`](./piphi-watchdog.sh) – main watchdog script

**Note:** `start-piphi.sh` is generated in ubuntu-piphi as a helper to start dockerd. **PiPhi services are started manually** via docker compose.

---

## ⚙️ Prerequisites

**Raspberry Pi host:**

- Debian-based OS (Raspberry Pi OS, Ubuntu, Debian)
- `systemd`, `bash`, `ssh`, `ssh-agent`, `ssh-add`, `curl`
- Working SSH key for `sensecap_root` (port 22222)

**SenseCAP M1:**

- PiPhi containers (`db`, `grafana`, `watchtower`, `piphi-network-image`)
- PiPhi panel accessible via HTTP (default port `31415`)
- Grafana HTTP port `3000`

---

## Installation Steps

```bash
git clone https://github.com/hattimon/sensecapm1-piphi.git
cd sensecapm1-piphi/piphi-watchdog
chmod +x piphi-watchdog-setup.sh
./piphi-watchdog-setup.sh
```

Installer will:

1. Validate environment
2. Ask for key paths, host IP, ports, delays
3. Write `~/.config/piphi-watchdog.conf`
4. Generate `piphi-watchdog.sh` (optional helper for dockerd)
5. Create `ssh-agent.service` (systemd user)
6. Export `SSH_AUTH_SOCK`
7. Load `sensecap_root` key
8. Create and enable `piphi-watchdog.service` and `.timer`

---

## How the watchdog works

1. Loads `~/.config/piphi-watchdog.conf`
2. Checks PiPhi panel via HTTP (`http://SENSECAP_HOST:31415/`)
3. If UP → exit
4. If DOWN:
   - SSH to `sensecap_root@SENSECAP_HOST:22222` using ssh-agent
   - Wait `BOOT_DELAY`
   - Run `balena ps`
   - Restart containers (`db`, `grafana`, `watchtower`, `piphi-network-image`)
   - Wait `RETRY_DELAY` and recheck

Logs:

- installer: `~/piphi-watchdog-setup.log`  
- watchdog runtime: `~/piphi-watchdog-run.log`

---

# 🇵🇱 Dokumentacja po polsku {#polski}

## 📂 Pliki

- [`piphi-watchdog-setup.sh`](./piphi-watchdog-setup.sh) – instalator
- [`piphi-watchdog.sh`](./piphi-watchdog.sh) – główny skrypt watchdoga

**Uwaga:** `start-piphi.sh` tworzony jest w kontenerze ubuntu-piphi jako pomocniczy do startu dockerd. **Usługi PiPhi uruchamiasz ręcznie** za pomocą `docker compose`.

---

## ⚙️ Wymagania

**Raspberry Pi:**

- system Debian-based (Raspberry Pi OS, Ubuntu, Debian)
- narzędzia: `systemd`, `bash`, `ssh`, `ssh-agent`, `ssh-add`, `curl`
- działający klucz SSH dla `sensecap_root` (port 22222)

**SenseCAP M1:**

- kontenery PiPhi (`db`, `grafana`, `watchtower`, `piphi-network-image`)
- panel PiPhi dostępny przez HTTP (domyślnie port `31415`)  
- panel Grafana (domyślnie port `3000`)

---

## Instalacja

```bash
git clone https://github.com/hattimon/sensecapm1-piphi.git
cd sensecapm1-piphi/piphi-watchdog
chmod +x piphi-watchdog-setup.sh
./piphi-watchdog-setup.sh
```

Skrypt:

1. Sprawdza środowisko
2. Pyta o ścieżki klucza, hosta, porty i opóźnienia
3. Tworzy `~/.config/piphi-watchdog.conf`
4. Generuje `piphi-watchdog.sh` (pomocniczy do dockerd)
5. Tworzy `ssh-agent.service`
6. Eksportuje `SSH_AUTH_SOCK`
7. Ładuje klucz `sensecap_root`
8. Tworzy i włącza `piphi-watchdog.service` i `.timer`

---

## Jak działa watchdog

1. Wczytuje konfigurację
2. Sprawdza panel PiPhi HTTP (`http://SENSECAP_HOST:31415/`)
3. Jeśli UP → kończy
4. Jeśli DOWN:
   - SSH do `sensecap_root@SENSECAP_HOST:22222`
   - Czeka `BOOT_DELAY`
   - Uruchamia `balena ps`
   - Restartuje kontenery (`db`, `grafana`, `watchtower`, `piphi-network-image`)
   - Czeka `RETRY_DELAY` i ponownie sprawdza

Logi:

- instalacja: `~/piphi-watchdog-setup.log`  
- runtime: `~/piphi-watchdog-run.log`

---

# 🧹 Usuwanie / Cleanup

```bash
systemctl --user disable --now piphi-watchdog.timer ssh-agent.service
rm -f ~/.config/systemd/user/piphi-watchdog.service
rm -f ~/.config/systemd/user/piphi-watchdog.timer
rm -f ~/.config/systemd/user/ssh-agent.service
systemctl --user daemon-reload

rm -f ~/.config/piphi-watchdog.conf
rm -f ~/piphi-watchdog.sh
rm -f ~/piphi-watchdog-setup.log
rm -f ~/piphi-watchdog-run.log
```

> Usuwanie `ssh-agent.service` jest opcjonalne, jeśli używasz ssh-agent do innych celów.
