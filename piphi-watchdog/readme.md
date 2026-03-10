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
- **NEW**: Implements intelligent backoff and remote reboot logic to protect your hardware.

---

# 🌐 Language / Język

- 🇬🇧 [English documentation](#english)
- 🇵🇱 [Dokumentacja po polsku](#polski)

---

## 🏗 Architecture

```mermaid
flowchart LR
    RPi["Raspberry Pi (watchdog)"] -->|SSH| SC["SenseCAP M1"]
    SC -->|balenaEngine| UB["ubuntu-piphi container"]
    UB -->|Docker| PS["PiPhi stack"]
```

- **Raspberry Pi** – host for the watchdog and `systemd --user` timer / host watchdoga i `systemd --user` timer
- **SenseCAP M1** – device running balenaOS and PiPhi in a container / urządzenie z balenaOS i PiPhi w kontenerze
- **ubuntu-piphi** – container prepared by the installer script / kontener przygotowany przez skrypt instalacyjny
- **PiPhi stack** – database, Grafana, PiPhi app, Watchtower / baza danych, Grafana, aplikacja PiPhi, Watchtower

---

# 🇬🇧 English documentation {#english}

## 📂 Files
- [`piphi-watchdog-setup.sh`](./piphi-watchdog-setup.sh) – interactive installer
- [`piphi-watchdog.sh`](./piphi-watchdog.sh) – main watchdog script

## ⚙️ Prerequisites
- Raspberry Pi with Debian-based OS (Raspberry Pi OS, Ubuntu)
- Working SSH key for `sensecap_root` on port `22222`
- Passphrase for the SSH key (if encrypted)

## 🚀 Installation

```bash
git clone https://github.com/hattimon/sensecapm1-piphi.git
cd sensecapm1-piphi/piphi-watchdog
chmod +x piphi-watchdog-setup.sh
./piphi-watchdog-setup.sh
```

The installer will:
1. Configure `ssh-agent` as a systemd user service.
2. Add your SenseCAP key to the agent (asking for passphrase once).
3. Generate the watchdog script with smart backoff logic.
4. Enable the systemd timer (checks every 10 minutes).

## 🛠 Troubleshooting & Manual Management

### Commands
- **Check logs**: `tail -f ~/piphi-watchdog-run.log`
- **Check service status**: `systemctl --user status piphi-watchdog.service`
- **Restart watchdog**: `systemctl --user restart piphi-watchdog.service`
- **Manually add key to agent**:
  ```bash
  export SSH_AUTH_SOCK="/run/user/$UID/ssh-agent.socket"
  ssh-add ~/.ssh/sensecap_root
  ```

### How backoff works
If the panel stays down despite container restarts:
1. Retries every 10, 20, 40, 80, 160, 240 mins.
2. After reaching 4h backoff, sends a `reboot` command to SenseCAP.
3. If still down, wait 8h, then 16h, then 24h between further reboots.
4. Once panel is back UP, all timers reset to zero.

---

# 🇵🇱 Dokumentacja po polsku {#polski}

## 📂 Pliki
- [`piphi-watchdog-setup.sh`](./piphi-watchdog-setup.sh) – instalator interaktywny
- [`piphi-watchdog.sh`](./piphi-watchdog.sh) – główny skrypt watchdoga

## ⚙️ Wymagania
- Raspberry Pi z systemem Debian-based (Raspberry Pi OS, Ubuntu)
- Działający klucz SSH dla `sensecap_root` na porcie `22222`
- Hasło do klucza (jeśli jest zaszyfrowany)

## 🚀 Instalacja

```bash
git clone https://github.com/hattimon/sensecapm1-piphi.git
cd sensecapm1-piphi/piphi-watchdog
chmod +x piphi-watchdog-setup.sh
./piphi-watchdog-setup.sh
```

Instalator:
1. Konfiguruje `ssh-agent` jako usługę systemd.
2. Dodaje klucz do agenta (zapyta o hasło tylko raz).
3. Generuje skrypt z inteligentną logiką restartów.
4. Włącza timer (sprawdzanie co 10 minut).

## 🛠 Zarządzanie i Rozwiązywanie problemów

### Komendy
- **Podgląd logów**: `tail -f ~/piphi-watchdog-run.log`
- **Status usługi**: `systemctl --user status piphi-watchdog.service`
- **Restart watchdoga**: `systemctl --user restart piphi-watchdog.service`
- **Ręczne dodanie klucza do agenta**:
  ```bash
  export SSH_AUTH_SOCK="/run/user/$UID/ssh-agent.socket"
  ssh-add ~/.ssh/sensecap_root
  ```

### Logika "Backoff" i Rebootów
Jeśli panel nie wstaje mimo restartów kontenerów:
1. Skrypt rzadziej męczy urządzenie: przerwy 10, 20, 40, 80, 160, 240 min.
2. Po 4h bezskutecznych prób wysyła komendę `reboot` do SenseCAP.
3. Jeśli nadal leży, zwiększa pauzy między rebootami: 8h, 16h, aż do 24h.
4. Gdy panel PiPhi wróci, wszystkie liczniki się zerują.
