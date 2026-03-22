# 🌐 PiPhi Light Installer (SenseCAP M1)

> 🚀 Lightweight PiPhi deployment for SenseCAP M1 with minimal disk usage

---

## 🌍 Language / Język

- 🇬🇧 [English](#-english--piphi-light-installer-sensecap-m1)
- 🇵🇱 [Polski](#-polski--instalator-piphi-light-sensecap-m1)

---

## 🇬🇧 English – PiPhi Light installer (SenseCAP M1)

### ⚡ Overview

This **light** version of the installer is optimized for quick deployment of PiPhi on a SenseCAP M1 while using minimal disk space.

---

### 🚀 Installation

Run the following commands on your device:

```bash
mkdir -p /mnt/data/hattimon
cd /mnt/data/hattimon

curl -L https://raw.githubusercontent.com/hattimon/sensecapm1-piphi/main/piphi-light/sensecapm1-piphi-light.sh -o sensecapm1-piphi-light.sh
chmod +x sensecapm1-piphi-light.sh
./sensecapm1-piphi-light.sh
```

---

### 🔧 Key Differences

Compared to the full setup:

- 📦 Installs **only two containers**:
  - `postgres:13.3`
  - `piphinetwork/team-piphi:latest`

- 🐳 Runs containers **directly on balenaOS**
  - 📁 Data: `/mnt/data/hattimon/piphi`
  - 🔁 Restart: `--restart=always`
  - 🌐 Ports:
    - `5432` → Postgres
    - `31415` → PiPhi UI

- 🚫 No Watchtower required (managed by balenaEngine)

---

### 💾 Disk Usage

```bash
du -sh /mnt/data/hattimon/piphi/*
balena system df
```

- 🗄️ postgres-data: ~40–80 MB  
- 📊 tsdb-data: few KB  
- 📝 logs: few KB  
- 📦 images: ~300–400 MB  

---

## 🇵🇱 Polski – Instalator PiPhi Light (SenseCAP M1)

### ⚡ Opis

Lekka wersja instalatora zoptymalizowana pod szybkie wdrożenie PiPhi przy minimalnym zużyciu miejsca.

---

### 🚀 Instalacja

Uruchom na urządzeniu:

```bash
mkdir -p /mnt/data/hattimon
cd /mnt/data/hattimon

curl -L https://raw.githubusercontent.com/hattimon/sensecapm1-piphi/main/piphi-light/sensecapm1-piphi-light.sh -o sensecapm1-piphi-light.sh
chmod +x sensecapm1-piphi-light.sh
./sensecapm1-piphi-light.sh
```

---

### 🔧 Różnice

- 📦 2 kontenery:
  - `postgres:13.3`
  - `piphinetwork/team-piphi:latest`

- 🐳 Bez Docker-in-Docker (balenaOS)
  - 📁 `/mnt/data/hattimon/piphi`
  - 🔁 `--restart=always`
  - 🌐 Porty: 5432, 31415

- 🚫 Bez Watchtowera

---

### 💾 Zużycie miejsca

```bash
du -sh /mnt/data/hattimon/piphi/*
balena system df
```

- 🗄️ postgres-data: ~40–80 MB  
- 📊 tsdb-data: kilka KB  
- 📝 logs: kilka KB  
- 📦 obrazy: ~300–400 MB  

---
