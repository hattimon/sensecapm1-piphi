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

- 🇬🇧 English documentation
- 🇵🇱 Dokumentacja po polsku

---

# 📂 Files in this folder

- **[`piphi-watchdog-setup.sh`](./piphi-watchdog-setup.sh)**  
  Interactive installer that configures the watchdog environment.

  It installs and configures:

  - `ssh-agent` systemd user service
  - SSH key for `sensecap_root`
  - configuration file `~/.config/piphi-watchdog.conf`
  - systemd user units:
    - `piphi-watchdog.service`
    - `piphi-watchdog.timer`
  - main watchdog script `piphi-watchdog.sh`

---

- **[`piphi-watchdog.sh`](./piphi-watchdog.sh)**  
  The actual watchdog script executed by systemd.

  It:

  - reads configuration from `~/.config/piphi-watchdog.conf`
  - checks the PiPhi panel using HTTP
  - connects to SenseCAP via SSH
  - restarts required containers when necessary

---

# ⚙️ Prerequisites

## On the Raspberry Pi

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

---

## On the SenseCAP M1

PiPhi containers must exist and be visible to the `balena` CLI:

```
db
grafana
watchtower
piphi-network-image
```

PiPhi panel must also be available via HTTP (default port `3000`).

---

# 🇬🇧 Step 2 – Installing the PiPhi Watchdog on Raspberry Pi

This step should be performed **after PiPhi has already been installed on the SenseCAP M1.**

---

## 1 Clone repository

```
git clone https://github.com/hattimon/sensecapm1-piphi.git
cd sensecapm1-piphi/piphi-watchdog
```

---

## 2 Make installer executable

```
chmod +x piphi-watchdog-setup.sh
```

---

## 3 Run installer

```
./piphi-watchdog-setup.sh
```

---

The installer will:

1. Validate required tools (`systemd`, `ssh-agent`, `curl`)
2. Ask for configuration values

Example prompts:

```
SSH key path (default ~/.ssh/sensecap_root)
watchdog script location (default ~/piphi-watchdog.sh)
SenseCAP host IP (default 192.168.0.56)
PiPhi panel port (default 3000)
boot delay
retry delay
watchdog interval
```

---

Then the script will:

- create configuration file:

```
~/.config/piphi-watchdog.conf
```

- generate watchdog script if needed

```
~/piphi-watchdog.sh
```

- create systemd user service:

```
ssh-agent.service
```

- export environment variable:

```
SSH_AUTH_SOCK
```

- load the `sensecap_root` SSH key into the agent

- create systemd units:

```
piphi-watchdog.service
piphi-watchdog.timer
```

---

Each installer section is clearly marked in the terminal:

```
===== [SECTION] 5. Configuring systemd user service: ssh-agent =====
```

If the installer stops unexpectedly, check the log:

```
~/piphi-watchdog-setup.log
```

---

# 🔄 What the watchdog actually does

Once installed:

### ssh-agent.service

Runs a persistent SSH agent for the `pi` user and stores the `sensecap_root` key.

---

### piphi-watchdog.timer

Triggers periodic execution of the watchdog service.

---

### piphi-watchdog.service

Executes:

```
piphi-watchdog.sh
```

The script performs the following steps:

1️⃣ Load configuration:

```
~/.config/piphi-watchdog.conf
```

2️⃣ Check the PiPhi panel:

```
http://SENSECAP_HOST:SENSECAP_PORT
```

3️⃣ If panel is **UP**

→ exit

4️⃣ If panel is **DOWN**

- test SSH connection:

```
sensecap_root@SENSECAP_HOST:22222
```

(using ssh-agent, **no password prompt**)

- wait `BOOT_DELAY` seconds

- run:

```
balena ps
```

- restart PiPhi containers:

```
db
grafana
watchtower
piphi-network-image
```

- wait `RETRY_DELAY`

- check panel again

---

# 📄 Logs

Installer log:

```
~/piphi-watchdog-setup.log
```

Watchdog runtime log:

```
~/piphi-watchdog-run.log
```

---

# 🇵🇱 Instalacja PiPhi Watchdog na Raspberry Pi

Ten krok wykonuje się **po zainstalowaniu PiPhi na SenseCAP M1**.

---

## 1 Sklonuj repozytorium

```
git clone https://github.com/hattimon/sensecapm1-piphi.git
cd sensecapm1-piphi/piphi-watchdog
```

---

## 2 Nadaj prawa wykonywalne

```
chmod +x piphi-watchdog-setup.sh
```

---

## 3 Uruchom instalator

```
./piphi-watchdog-setup.sh
```

---

Skrypt instalacyjny:

1. sprawdzi wymagane narzędzia (`systemd`, `ssh-agent`, `curl`)
2. zapyta o parametry konfiguracji:

- ścieżkę do klucza SSH (`~/.ssh/sensecap_root`)
- lokalizację skryptu watchdog (`~/piphi-watchdog.sh`)
- adres SenseCAP
- port panelu PiPhi
- opóźnienia startowe i retry

---

Następnie skrypt:

- zapisze konfigurację do

```
~/.config/piphi-watchdog.conf
```

- wygeneruje `piphi-watchdog.sh`

- utworzy usługę:

```
ssh-agent.service
```

- doda zmienną:

```
SSH_AUTH_SOCK
```

- załaduje klucz `sensecap_root` do `ssh-agent`

- utworzy jednostki systemd:

```
piphi-watchdog.service
piphi-watchdog.timer
```

---

# 🔄 Co robi watchdog

Po instalacji:

### ssh-agent.service

przechowuje klucz SSH do SenseCAP.

---

### piphi-watchdog.timer

cyklicznie uruchamia watchdog.

---

### piphi-watchdog.service

uruchamia skrypt:

```
piphi-watchdog.sh
```

Skrypt:

1. wczytuje konfigurację
2. sprawdza panel PiPhi przez HTTP
3. jeśli panel działa → kończy
4. jeśli panel nie działa:

- sprawdza SSH do SenseCAP
- czeka `BOOT_DELAY`
- restartuje kontenery:

```
db
grafana
watchtower
piphi-network-image
```

- czeka `RETRY_DELAY`
- ponownie sprawdza panel

---

# 📄 Logi

Instalacja:

```
~/piphi-watchdog-setup.log
```

Działanie watchdog:

```
~/piphi-watchdog-run.log
```

---

# 🧹 Uninstall / Usunięcie watchdog

Disable services:

```
systemctl --user disable --now piphi-watchdog.timer ssh-agent.service
```

Remove systemd units:

```
rm -f ~/.config/systemd/user/piphi-watchdog.service
rm -f ~/.config/systemd/user/piphi-watchdog.timer
rm -f ~/.config/systemd/user/ssh-agent.service
```

Reload systemd:

```
systemctl --user daemon-reload
```

Optional cleanup:

```
rm -f ~/.config/piphi-watchdog.conf
rm -f ~/piphi-watchdog.sh
rm -f ~/piphi-watchdog-setup.log
rm -f ~/piphi-watchdog-run.log
```

> Removing `ssh-agent.service` is optional if you use ssh-agent for other SSH tasks.
