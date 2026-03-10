# 🛰️ PiPhi Watchdog for SenseCAP M1

This directory contains an optional **PiPhi watchdog** that runs on a separate Raspberry Pi and automatically restores the PiPhi panel on your SenseCAP M1 when it goes down (power loss, reboot, container crash, etc.).

The watchdog:

- periodically checks the PiPhi web panel via HTTP
- if the panel is down, connects to SenseCAP M1 over SSH
- waits for the device to boot
- restarts the required balena containers (`db`, `grafana`, `watchtower`, `piphi-network-image`)
- runs automatically using a `systemd --user` timer on the Raspberry Pi

> The Raspberry Pi connects to SenseCAP M1 as `sensecap_root` using the existing SSH key.  
> Adding a new key to SenseCAP balenaOS is blocked by SenseCAP's private cloud, so this watchdog uses the original key loaded into `ssh-agent`.

---

# 🌐 Language / Język

- 🇬🇧 [English documentation](#english)
- 🇵🇱 [Dokumentacja po polsku](#polski)

---

# 🇬🇧 English documentation {#english}

## 📂 Files in this folder

- **[`piphi-watchdog-setup.sh`](./piphi-watchdog-setup.sh)**  
  Interactive installer that configures the watchdog environment.

  It installs and configures:

  - `ssh-agent` systemd user service
  - SSH key for `sensecap_root`
  - configuration file `~/.config/piphi-watchdog.conf`
  - systemd user units:
    - `piphi-watchdog.service`
    - `piphi-watchdog.timer`
  - main watchdog script `piphi-watchdog.sh` (optional helper to start dockerd; PiPhi services are started manually with docker compose)

- **[`piphi-watchdog.sh`](./piphi-watchdog.sh)**  
  The actual watchdog script executed by systemd.

  It:

  - reads configuration from `~/.config/piphi-watchdog.conf`
  - checks the PiPhi panel using HTTP
  - connects to SenseCAP via SSH
  - restarts required containers when necessary

---

## ⚙️ Prerequisites

### On the Raspberry Pi

The watchdog host must run a Debian-based system:

- Raspberry Pi OS
- Ubuntu
- Debian

Required tools:

```
systemd
bash
ssh
ssh-agent
ssh-add
curl
```

You must also have a **working SSH key for `sensecap_root`** that can log into your SenseCAP M1:

```
ssh sensecap_root@SENSECAP_IP -p 22222
```

### On the SenseCAP M1

PiPhi containers must exist and be visible to the `balena` CLI:

```
db
grafana
watchtower
piphi-network-image
```

PiPhi panel must also be available via HTTP (default port `3000`).

---

## Step 2 – Installing the PiPhi Watchdog on Raspberry Pi

This step should be performed **after PiPhi has already been installed on the SenseCAP M1.**

### 1 Clone repository

```bash
git clone https://github.com/hattimon/sensecapm1-piphi.git
cd sensecapm1-piphi/piphi-watchdog
```

### 2 Make installer executable

```bash
chmod +x piphi-watchdog-setup.sh
```

### 3 Run installer

```bash
./piphi-watchdog-setup.sh
```

---

### What the installer does

1. Validates required tools (`systemd`, `ssh-agent`, `curl`)
2. Asks for configuration:

- SSH key path (default `~/.ssh/sensecap_root`)
- Watchdog script path (default `~/piphi-watchdog.sh`)
- SenseCAP host/IP
- PiPhi panel port
- Boot/retry delays, interval

3. Writes configuration:

```
~/.config/piphi-watchdog.conf
```

4. Generates `piphi-watchdog.sh` (optional helper to start dockerd; PiPhi services are started manually)
5. Creates `ssh-agent.service` (systemd user)
6. Exports `SSH_AUTH_SOCK`
7. Loads the `sensecap_root` key
8. Creates systemd units:

```
piphi-watchdog.service
piphi-watchdog.timer
```

Each section is marked in terminal:

```
===== [SECTION] 5. Configuring systemd user service: ssh-agent =====
```

Logs:

```
~/piphi-watchdog-setup.log
```

---

### What the watchdog does

- `ssh-agent.service` holds the SSH key
- `piphi-watchdog.timer` runs periodically
- `piphi-watchdog.service` executes `piphi-watchdog.sh` which:

1. Loads configuration
2. Checks PiPhi panel via HTTP
3. If panel is UP → exit
4. If panel is DOWN:
   - checks SSH to `sensecap_root@SENSECAP_HOST:22222`
   - waits `BOOT_DELAY`
   - runs `balena ps`
   - restarts containers (`db`, `grafana`, `watchtower`, `piphi-network-image`)
   - waits `RETRY_DELAY` and rechecks

Logs:

- installation: `~/piphi-watchdog-setup.log`
- runtime: `~/piphi-watchdog-run.log`

---

# 🇵🇱 Dokumentacja po polsku {#polski}

## 📂 Pliki w folderze

- **[`piphi-watchdog-setup.sh`](./piphi-watchdog-setup.sh)**  
  Skrypt instalacyjny konfigurujący watchdog.

  Tworzy i konfiguruje:

  - `ssh-agent` (usługa systemd user)
  - klucz SSH `sensecap_root`
  - plik konfiguracji `~/.config/piphi-watchdog.conf`
  - jednostki systemd:
    - `piphi-watchdog.service`
    - `piphi-watchdog.timer`
  - główny skrypt watchdog `piphi-watchdog.sh` (pomocniczy do startu dockerd; same usługi PiPhi uruchamiasz ręcznie poleceniami `docker compose`)

- **[`piphi-watchdog.sh`](./piphi-watchdog.sh)**  
  Skrypt wywoływany przez systemd.

  Robi:

  - wczytuje konfigurację z `~/.config/piphi-watchdog.conf`
  - sprawdza panel PiPhi HTTP
  - łączy się SSH do SenseCAP
  - restartuje kontenery w razie potrzeby

---

## ⚙️ Wymagania

### Na Raspberry Pi

- system Debian-based: Raspberry Pi OS, Ubuntu, Debian
- narzędzia: `systemd`, `bash`, `ssh`, `ssh-agent`, `ssh-add`, `curl`
- działający klucz SSH dla `sensecap_root`

### Na SenseCAP M1

PiPhi kontenery:

```
db
grafana
watchtower
piphi-network-image
```

Panel PiPhi na HTTP (domyślnie port `3000`)

---

## Instalacja watchdog (Raspberry Pi)

### 1. Sklonuj repozytorium

```bash
git clone https://github.com/hattimon/sensecapm1-piphi.git
cd sensecapm1-piphi/piphi-watchdog
```

### 2. Nadaj prawa wykonywalne

```bash
chmod +x piphi-watchdog-setup.sh
```

### 3. Uruchom instalator

```bash
./piphi-watchdog-setup.sh
```

---

### Co robi instalator

1. Sprawdza środowisko (`systemd`, `ssh-agent`, `curl`)
2. Pyta o parametry:

- klucz SSH `~/.ssh/sensecap_root`
- lokalizacja skryptu watchdog `~/piphi-watchdog.sh`
- adres IP/host SenseCAP
- port HTTP panelu PiPhi
- opóźnienia startowe i retry

3. Tworzy konfigurację:

```
~/.config/piphi-watchdog.conf
```

4. Generuje `piphi-watchdog.sh` (pomocniczy start dockerd; PiPhi startujesz ręcznie)
5. Tworzy `ssh-agent.service`
6. Ustawia `SSH_AUTH_SOCK`
7. Ładuje klucz `sensecap_root`
8. Tworzy jednostki systemd:

```
piphi-watchdog.service
piphi-watchdog.timer
```

Logi: `~/piphi-watchdog-setup.log`

---

### Co robi watchdog

- `ssh-agent.service` przechowuje klucz SSH
- `piphi-watchdog.timer` uruchamia watchdog cyklicznie
- `piphi-watchdog.service` uruchamia `piphi-watchdog.sh`:

1. Wczytuje konfigurację
2. Sprawdza panel PiPhi przez HTTP
3. Jeśli UP → kończy
4. Jeśli DOWN:
   - testuje SSH
   - czeka `BOOT_DELAY`
   - restartuje kontenery `db`, `grafana`, `watchtower`, `piphi-network-image`
   - czeka `RETRY_DELAY` i ponownie sprawdza

Logi runtime: `~/piphi-watchdog-run.log`

---

# 🧹 Usuwanie / uninstall

Wyłącz usługi:

```bash
systemctl --user disable --now piphi-watchdog.timer ssh-agent.service
```

Usuń jednostki:

```bash
rm -f ~/.config/systemd/user/piphi-watchdog.service
rm -f ~/.config/systemd/user/piphi-watchdog.timer
rm -f ~/.config/systemd/user/ssh-agent.service
```

Przeładuj systemd:

```bash
systemctl --user daemon-reload
```

Opcjonalnie usuń:

```bash
rm -f ~/.config/piphi-watchdog.conf
rm -f ~/piphi-watchdog.sh
rm -f ~/piphi-watchdog-setup.log
rm -f ~/piphi-watchdog-run.log
```

> Usuwanie `ssh-agent.service` jest opcjonalne, jeśli używasz ssh-agent do innych celów.
