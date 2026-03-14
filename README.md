# 🛰️ PiPhi on SenseCAP M1 (balenaOS)

![Docker](https://img.shields.io/badge/docker-compose-blue)
![Platform](https://img.shields.io/badge/platform-balenaOS-green)
![Hardware](https://img.shields.io/badge/device-SenseCAP%20M1-orange)
![License](https://img.shields.io/badge/license-MIT-lightgrey)

![Flow](img/flow-sensecap-piphi-watchdog.png)

Run the **PiPhi network stack** on a **SenseCAP M1** device using
**balenaOS** and a **USB GPS module**.

This repository prepares a **safe PiPhi environment inside an Ubuntu
container** (`ubuntu-piphi`) and optionally allows running a **watchdog
container** that automatically recovers the PiPhi panel.

------------------------------------------------------------------------

# 🌐 Language / Język

* 🇬🇧 [English Documentation](#-english-documentation)
* 🇵🇱 [Dokumentacja po Polsku](#-dokumentacja-po-polsku)

------------------------------------------------------------------------

# 🏗 Architecture

SenseCAP M1 (balenaOS host)

    balena-engine
       │
       ├── ubuntu-piphi (Ubuntu container)
       │        │
       │        └── dockerd (nested Docker)
       │               │
       │               └── PiPhi stack
       │                     ├── db
       │                     ├── grafana
       │                     ├── software
       │                     ├── watchtower
       │                     └── gpsd
       │
       └── other SenseCAP services

------------------------------------------------------------------------

# 🧭 Basic Navigation

## Enter Ubuntu container

``` bash
balena exec -it ubuntu-piphi bash
```

Check containers

``` bash
docker ps
```

Exit container

``` bash
exit
```

Check host containers

``` bash
balena ps
```

Identify environment

``` bash
lsb_release -a || cat /etc/os-release
```

------------------------------------------------------------------------

# 🚀 Installation

``` bash
mkdir -p /mnt/data/piphi
cd /mnt/data/piphi

curl -L https://raw.githubusercontent.com/hattimon/sensecapm1-piphi/main/install-piphi-sensecapm1.sh -o install-piphi-sensecapm1.sh
chmod +x install-piphi-sensecapm1.sh

./install-piphi-sensecapm1.sh
```

------------------------------------------------------------------------

# 🐳 First Manual Start

Enter container

``` bash
balena exec -it ubuntu-piphi bash
cd /piphi-network
```

Start docker daemon

``` bash
dockerd --host=unix:///var/run/docker.sock > /piphi-network/dockerd.log 2>&1 &
sleep 10
docker ps
```

------------------------------------------------------------------------

# ⚙ Manual Start Stages

Stage 1

``` bash
docker compose -f docker-compose.yml up -d db
sleep 20
```

Stage 2

``` bash
docker compose -f docker-compose.yml up -d grafana
sleep 20
```

Stage 3

``` bash
docker compose -f docker-compose.yml up -d software
sleep 20
```

Stage 4

``` bash
docker compose -f docker-compose.yml up -d watchtower
```

------------------------------------------------------------------------

# 🛠 Troubleshooting / Real Installation Example

Below are screenshots from a real installation process.

## Example 1 -- Docker pulling images

![Example](img/t1.png)

During large image pulls Docker may appear to stop or return to the
shell. In reality the **extraction continues in the background**.

Wait until **CPU drops to \~5% and stays stable for 2--3 minutes**.

After most of these stages a **device reboot was required**.

------------------------------------------------------------------------

## Example 2 -- Layers already downloaded

![Example](img/t2.png)

Messages like

    Already exists

mean Docker already downloaded these layers earlier.

Docker will reuse them and continue creating containers.

Again:

-   wait until CPU stabilizes
-   reboot if needed
-   continue installation

------------------------------------------------------------------------

## Example 3 -- Final container creation

![Example](img/t3.png)

After several restarts the **software container finally started
correctly**.

At this point running:

``` bash
docker compose -f docker-compose.yml up -d watchtower
```

works immediately because **watchtower is a small image** and pulls
quickly.

------------------------------------------------------------------------

# 🌍 Access Interfaces

PiPhi

    http://YOUR_DEVICE_IP:31415

Grafana

    http://YOUR_DEVICE_IP:3000

------------------------------------------------------------------------

# 🇵🇱 Notatki z instalacji

Podczas rzeczywistej instalacji:

-   większość obrazów wymagała **restartu urządzenia po zakończeniu
    pull**
-   restart był wykonywany gdy **CPU spadało do około 5% przez 2‑3
    minuty**
-   dopiero przy ostatnim obrazie **software uruchomił się poprawnie**
-   obraz **watchtower** jest mały więc uruchomił się od razu

------------------------------------------------------------------------

# License

MIT
