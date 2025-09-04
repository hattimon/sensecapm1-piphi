# Manual Installation Guide (English)

Based on [https://github.com/hattimon/sensecapm1-piphi/tree/main](https://github.com/hattimon/sensecapm1-piphi/tree/main).

## Prerequisites
- Ensure `wget` is installed on the host: `apt-get install -y wget`
- Connect a USB GPS dongle (e.g., U-Blox 7) to the SenseCAP M1.

## Solution
### Step 1: Manually Fix the Existing Container
#### Remove the existing `ubuntu-piphi` container:
```
balena stop ubuntu-piphi
balena rm ubuntu-piphi
```

#### Run a new container:
```
balena run -d --privileged -v /mnt/data/piphi-network:/piphi-network -p 31415:31415 -p 5432:5432 -p 3000:3000 --cpus="2.0" --memory="2g" --name ubuntu-piphi --restart unless-stopped ubuntu:20.04 tail -f /dev/null
```
- Wait 5 seconds.

#### Enter the container:
```
balena exec -it ubuntu-piphi /bin/bash
```

#### Configure timezone (if needed):
```
apt-get update
apt-get install -y tzdata
echo 'Europe/Warsaw' > /etc/timezone
ln -sf /usr/share/zoneinfo/Europe/Warsaw /etc/localtime
dpkg-reconfigure -f noninteractive tzdata
```

#### Install all dependencies:
```
apt-get install -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" ca-certificates curl gnupg lsb-release usbutils gpsd gpsd-clients iputils-ping
```

#### Install cron package:
```
apt-get install -y cron
```

#### Fix Docker repository:
- Remove old repository:
  ```
  rm /etc/apt/sources.list.d/docker.list
  ```
- Add correct repository for arm64:
  ```
  mkdir -p /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  echo "deb [arch=arm64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu focal stable" > /etc/apt/sources.list.d/docker.list
  apt-get update
  ```

#### Install Docker and docker-compose:
```
apt-get install -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" docker-ce docker-ce-cli containerd.io docker-compose-plugin
```

#### Install yq:
```
curl -L https://github.com/mikefarah/yq/releases/download/v4.44.3/yq_linux_arm64 -o /usr/bin/yq
chmod +x /usr/bin/yq
```

#### Start Docker daemon:
```
nohup dockerd --host=unix:///var/run/docker.sock --storage-driver=vfs > /piphi-network/dockerd.log 2>&1 &
```
- Wait 10 seconds, then check:
  ```
  docker info
  ```
- If there’s an error, view logs:
  ```
  cat /piphi-network/dockerd.log
  ```

#### Check network connectivity:
```
curl -I https://registry-1.docker.io/v2/
```
- Expected result: `HTTP/1.1 401 Unauthorized`.
- If it fails, set DNS:
  ```
  echo 'nameserver 8.8.8.8' > /etc/resolv.conf
  ```

#### Run PiPhi services:
```
cd /piphi-network
docker compose pull
docker compose up -d
```
- If pulling fails, try individually (worked, but `docker compose pull` took long):
  ```
  docker pull postgres:13.3
  docker pull piphinetwork/team-piphi:latest
  docker pull containrrr/watchtower
  docker pull grafana/grafana-oss
  docker compose up -d
  ```

#### Check status:
```
docker ps
```
- Expected containers: `piphi-network-image`, `db`, `watchtower`, `grafana`.

#### Check GPS:
```
gpsd /dev/ttyACM0
cgps -s
```
- Place the device outdoors for a GPS fix (1–5 minutes).

#### Exit and restart the container:
```
exit
balena restart ubuntu-piphi
```

## Ensuring Automatic Startup of Docker Daemon and Containers
To ensure the Docker daemon and all containers (`piphi-network-image`, `db`, `watchtower`, `grafana`) automatically start in the `ubuntu-piphi` container after a system restart:

1. **Install and Verify cron**:
   - Ensure `cron` is installed (done in the previous step). Verify:
     ```
     cron --version
     ```
   - If not installed, install it:
     ```
     apt-get install -y cron
     ```

2. **Configure cron for Docker Daemon and Services**:
   - Edit the crontab file:
     ```
     crontab -e
     ```
   - Add the following lines (e.g., using `nano`):
     ```
     @reboot sleep 30 && nohup dockerd --host=unix:///var/run/docker.sock --storage-driver=vfs > /piphi-network/dockerd.log 2>&1 &
     @reboot sleep 60 && cd /piphi-network && docker compose up -d
     ```
   - Save and exit (`Ctrl+O`, Enter, `Ctrl+X` in `nano`).

3. **Start cron service**:
   - Ensure `cron` is running:
     ```
     service cron start
     ```
   - Verify status:
     ```
     service cron status
     ```
   - If needed, run in background:
     ```
     cron &
     ```

4. **Verification**:
   - After a reboot, enter the container:
     ```
     balena exec -it ubuntu-piphi /bin/bash
     ```
   - Check Docker daemon:
     ```
     docker info
     ```
   - Check running containers:
     ```
     docker ps
     ```
   - Ensure the PiPhi panel is accessible at `http://<IP_urządzenia>:31415`.

# Podręcznik Instalacji Ręcznej (Polski)

Oparte na [https://github.com/hattimon/sensecapm1-piphi/tree/main](https://github.com/hattimon/sensecapm1-piphi/tree/main).

## Wymagania wstępne
- Upewnij się, że `wget` jest zainstalowany na hoście: `apt-get install -y wget`
- Podłącz dongle USB GPS (np. U-Blox 7) do SenseCAP M1.

## Rozwiązanie
### Krok 1: Napraw ręcznie istniejący kontener
#### Usuń istniejący kontener `ubuntu-piphi`:
```
balena stop ubuntu-piphi
balena rm ubuntu-piphi
```

#### Uruchom nowy kontener:
```
balena run -d --privileged -v /mnt/data/piphi-network:/piphi-network -p 31415:31415 -p 5432:5432 -p 3000:3000 --cpus="2.0" --memory="2g" --name ubuntu-piphi --restart unless-stopped ubuntu:20.04 tail -f /dev/null
```
- Poczekaj 5 sekund.

#### Wejdź do kontenera:
```
balena exec -it ubuntu-piphi /bin/bash
```

#### Skonfiguruj strefę czasową (jeśli potrzebne):
```
apt-get update
apt-get install -y tzdata
echo 'Europe/Warsaw' > /etc/timezone
ln -sf /usr/share/zoneinfo/Europe/Warsaw /etc/localtime
dpkg-reconfigure -f noninteractive tzdata
```

#### Zainstaluj wszystkie zależności:
```
apt-get install -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" ca-certificates curl gnupg lsb-release usbutils gpsd gpsd-clients iputils-ping
```

#### Zainstaluj pakiet cron:
```
apt-get install -y cron
```

#### Napraw repozytorium Dockera:
- Usuń stare repozytorium:
  ```
  rm /etc/apt/sources.list.d/docker.list
  ```
- Dodaj poprawne repozytorium dla arm64:
  ```
  mkdir -p /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
  echo "deb [arch=arm64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu focal stable" > /etc/apt/sources.list.d/docker.list
  apt-get update
  ```

#### Zainstaluj Docker i docker-compose:
```
apt-get install -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" docker-ce docker-ce-cli containerd.io docker-compose-plugin
```

#### Zainstaluj yq:
```
curl -L https://github.com/mikefarah/yq/releases/download/v4.44.3/yq_linux_arm64 -o /usr/bin/yq
chmod +x /usr/bin/yq
```

#### Uruchom daemon Dockera:
```
nohup dockerd --host=unix:///var/run/docker.sock --storage-driver=vfs > /piphi-network/dockerd.log 2>&1 &
```
- Poczekaj 10 sekund, a następnie sprawdź:
  ```
  docker info
  ```
- Jeśli błąd, zobacz logi:
  ```
  cat /piphi-network/dockerd.log
  ```

#### Sprawdź połączenie sieciowe:
```
curl -I https://registry-1.docker.io/v2/
```
- Oczekiwany wynik: `HTTP/1.1 401 Unauthorized`.
- Jeśli nie działa, ustaw DNS:
  ```
  echo 'nameserver 8.8.8.8' > /etc/resolv.conf
  ```

#### Uruchom usługi PiPhi:
```
cd /piphi-network
docker compose pull
docker compose up -d
```
- Jeśli pobieranie nie działa, spróbuj pojedynczo (zadziałało pobieranie, ale `docker compose pull` długo się wykonywało):
  ```
  docker pull postgres:13.3
  docker pull piphinetwork/team-piphi:latest
  docker pull containrrr/watchtower
  docker pull grafana/grafana-oss
  docker compose up -d
  ```

#### Sprawdź status:
```
docker ps
```
- Oczekiwane kontenery: `piphi-network-image`, `db`, `watchtower`, `grafana`.

#### Sprawdź GPS:
```
gpsd /dev/ttyACM0
cgps -s
```
- Umieść urządzenie na zewnątrz dla fix GPS (1–5 minut).

#### Wyjdź i zrestartuj kontener:
```
exit
balena restart ubuntu-piphi
```

## Zapewnienie Automatycznego Uruchomienia Demona Dockera i Kontenerów
Aby zapewnić, że demon Dockera oraz wszystkie kontenery (`piphi-network-image`, `db`, `watchtower`, `grafana`) automatycznie startują w kontenerze `ubuntu-piphi` po restarcie systemu:

1. **Zainstaluj i zweryfikuj cron**:
   - Upewnij się, że `cron` jest zainstalowany (wykonane w poprzednim kroku). Zweryfikuj:
     ```
     cron --version
     ```
   - Jeśli nie jest zainstalowany, zainstaluj:
     ```
     apt-get install -y cron
     ```

2. **Skonfiguruj cron dla demona Dockera i usług**:
   - Edytuj plik `crontab`:
     ```
     crontab -e
     ```
   - Dodaj następujące linie (np. w `nano`):
     ```
     @reboot sleep 30 && nohup dockerd --host=unix:///var/run/docker.sock --storage-driver=vfs > /piphi-network/dockerd.log 2>&1 &
     @reboot sleep 60 && cd /piphi-network && docker compose up -d
     ```
   - Zapisz i zamknij (`Ctrl+O`, Enter, `Ctrl+X` w `nano`).

3. **Uruchom usługę cron**:
   - Upewnij się, że `cron` działa:
     ```
     service cron start
     ```
   - Sprawdź status:
     ```
     service cron status
     ```
   - Jeśli potrzebne, uruchom w tle:
     ```
     cron &
     ```

4. **Weryfikacja**:
   - Po restarcie wejdź do kontenera:
     ```
     balena exec -it ubuntu-piphi /bin/bash
     ```
   - Sprawdź demona Dockera:
     ```
     docker info
     ```
   - Sprawdź działające kontenery:
     ```
     docker ps
     ```
   - Upewnij się, że panel PiPhi jest dostępny pod adresem `http://<IP_urządzenia>:31415`.
