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

```bash
mkdir -p /mnt/data/hattimon
cd /mnt/data/hattimon

curl -L https://raw.githubusercontent.com/hattimon/sensecapm1-piphi/main/piphi-light/sensecapm1-piphi-light.sh -o sensecapm1-piphi-light.sh
chmod +x sensecapm1-piphi-light.sh
./sensecapm1-piphi-light.sh
```

---

### 🖥️ Example installation output

![Installation output](screen.png)

---

### 💾 Real Disk Usage (Based on actual install)

```bash
du -sh /mnt/data/hattimon/piphi/*
balena system df
```

Typical real values:

- 🗄️ `postgres-data`: ~41 MB  
- 📊 `tsdb-data`: ~4 KB  
- 📝 `logs`: ~4 KB  

⚠️ Note:
- Total images on system: ~3.6 GB (includes other SenseCAP containers)
- PiPhi + Postgres images themselves are only a **small part of that**

---

## 🇵🇱 Polski – Instalator PiPhi Light (SenseCAP M1)

### ⚡ Opis

Lekka wersja instalatora zoptymalizowana pod szybkie wdrożenie PiPhi przy minimalnym zużyciu miejsca.

---

### 🚀 Instalacja

```bash
mkdir -p /mnt/data/hattimon
cd /mnt/data/hattimon

curl -L https://raw.githubusercontent.com/hattimon/sensecapm1-piphi/main/piphi-light/sensecapm1-piphi-light.sh -o sensecapm1-piphi-light.sh
chmod +x sensecapm1-piphi-light.sh
./sensecapm1-piphi-light.sh
```

---

### 🖥️ Przykładowy wynik instalacji

![Wynik instalacji](screen_pl.png)

---

### 💾 Rzeczywiste zużycie miejsca

```bash
du -sh /mnt/data/hattimon/piphi/*
balena system df
```

Rzeczywiste wartości:

- 🗄️ `postgres-data`: ~41 MB  
- 📊 `tsdb-data`: ~4 KB  
- 📝 `logs`: ~4 KB  

⚠️ Uwaga:
- Całkowite obrazy w systemie: ~3.6 GB (zawiera inne kontenery SenseCAP)
- Same obrazy PiPhi + Postgres to tylko **niewielka część tej wartości**

---
