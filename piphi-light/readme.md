# 🌐 PiPhi Light Installer (SenseCAP M1)

> 🚀 Lightweight PiPhi deployment for SenseCAP M1 with minimal disk
> usage

------------------------------------------------------------------------

# 🌍 Language / Język

-   🇬🇧 English
-   🇵🇱 Polski

------------------------------------------------------------------------

# 🇬🇧 English -- PiPhi Light installer (SenseCAP M1)

## ⚡ Overview

This **light installer** allows quick deployment of **PiPhi** on a
**SenseCAP M1** device with minimal disk usage and simple installation.

The goal is to keep the footprint **as small as possible** while
maintaining full functionality.

------------------------------------------------------------------------

# 🚀 Installation

``` bash
mkdir -p /mnt/data/hattimon
cd /mnt/data/hattimon

curl -L https://raw.githubusercontent.com/hattimon/sensecapm1-piphi/main/piphi-light/sensecapm1-piphi-light.sh -o sensecapm1-piphi-light.sh
chmod +x sensecapm1-piphi-light.sh
./sensecapm1-piphi-light.sh
```

------------------------------------------------------------------------

# 📊 Real disk usage (measured)

Measured on a **real SenseCAP M1 installation**.

Commands used:

``` bash
du -sh /mnt/data/hattimon/piphi/*
balena system df
```

### 📁 Data usage

    postgres-data   ~41 MB
    logs            ~4 KB
    tsdb-data       ~4 KB

👉 **Total runtime data: \~41 MB**

------------------------------------------------------------------------

# 💾 Real installation footprint

  Component            Disk usage
  -------------------- ---------------
  📁 Runtime data      \~41 MB
  📦 Docker images     \~400--550 MB
  ⚙️ Total footprint   \~450--600 MB

👉 PiPhi only adds **two Docker images**:

-   PiPhi
-   PostgreSQL

------------------------------------------------------------------------

# 📦 Docker image changes

Before installation:

    ACTIVE images: 7

After installation:

    ACTIVE images: 9

👉 **+2 images added**

------------------------------------------------------------------------

# 🧹 After uninstall

When PiPhi is removed:

-   runtime data removed ✅
-   containers removed ✅
-   Docker images remain cached ❗

Example:

    ACTIVE: 7
    RECLAIMABLE: 2.7 GB

------------------------------------------------------------------------

# ⚠️ Important note about balenaEngine

On SenseCAP devices using **balenaEngine**:

-   Docker images may remain **cached**
-   `balena image prune -f` may **not immediately remove them**

This happens because images can be:

-   system-managed
-   referenced by other layers

👉 This is **normal behavior** on SenseCAP systems.

Images become **reclaimable**, but may persist until the engine decides
to clean them.

------------------------------------------------------------------------

# 🇵🇱 Polski -- Instalator PiPhi Light (SenseCAP M1)

## ⚡ Opis

Lekka wersja instalatora umożliwia szybkie uruchomienie **PiPhi na
SenseCAP M1** przy **minimalnym zużyciu miejsca na dysku**.

Instalator został zaprojektowany tak, aby footprint był **jak
najmniejszy**, przy zachowaniu pełnej funkcjonalności.

------------------------------------------------------------------------

# 🚀 Instalacja

``` bash
mkdir -p /mnt/data/hattimon
cd /mnt/data/hattimon

curl -L https://raw.githubusercontent.com/hattimon/sensecapm1-piphi/main/piphi-light/sensecapm1-piphi-light.sh -o sensecapm1-piphi-light.sh
chmod +x sensecapm1-piphi-light.sh
./sensecapm1-piphi-light.sh
```

------------------------------------------------------------------------

# 📊 Rzeczywiste zużycie miejsca (pomiar)

Pomiar wykonany na **rzeczywistej instalacji SenseCAP M1**.

Użyte polecenia:

``` bash
du -sh /mnt/data/hattimon/piphi/*
balena system df
```

### 📁 Dane aplikacji

    postgres-data   ~41 MB
    logs            ~4 KB
    tsdb-data       ~4 KB

👉 **Łączne dane runtime: \~41 MB**

------------------------------------------------------------------------

# 💾 Faktyczny footprint instalacji

  Element             Zużycie
  ------------------- ---------------
  📁 Dane aplikacji   \~41 MB
  📦 Obrazy Docker    \~400--550 MB
  ⚙️ Razem            \~450--600 MB

👉 Instalacja dodaje tylko **2 obrazy Docker**:

-   PiPhi
-   PostgreSQL

------------------------------------------------------------------------

# 🧹 Po odinstalowaniu

Po usunięciu PiPhi:

-   dane aplikacji usunięte ✅
-   kontenery usunięte ✅
-   obrazy Docker pozostają w cache ❗

Przykład:

    ACTIVE: 7
    RECLAIMABLE: 2.7 GB

------------------------------------------------------------------------

# ⚠️ Uwaga dotycząca balenaEngine

Na urządzeniach SenseCAP korzystających z **balenaEngine**:

-   obrazy Docker mogą pozostać **w cache**
-   `balena image prune -f` **nie zawsze usuwa je od razu**

Jest to **normalne zachowanie balenaEngine**.
