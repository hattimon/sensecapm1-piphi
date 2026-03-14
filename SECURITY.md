# ⚠️ Safety Procedures / Procedury Bezpieczeństwa
**Before installing PiPhi on SenseCAP M1! / Przed instalacją PiPhi na SenseCAP M1!**

**Proceed with extreme caution. These steps can brick your device. Always backup first. / Działaj z najwyższą ostrożnością. Kroki mogą uszkodzić urządzenie. Zawsze zrób backup.**

## 🇬🇧 English

### 1. Backup config.json (Critical)
- Power off the device, open the front panel, remove the SD card, and copy `config.json` from the `resin-boot` partition.
- This file is unique per device. Do not share it.

Official guide (EN):
https://sensecap-mx.gitbook.io/home/sensecap-gateways/sensecap-m1/m1-troubleshooting/micro-sd-card-errors/replace-config.json-file

### 2. Flashing Image (Only if advised)
- Format the SD card with SD Card Formatter, flash the SenseCAP M1 image with BalenaEtcher, then restore `config.json` to `resin-boot`.
- After boot, wait 20-30 minutes for OTA updates.

Official guide (EN):
https://sensecap-mx.gitbook.io/home/sensecap-gateways/sensecap-m1/m1-troubleshooting/micro-sd-card-errors/format-existing-micro-sd-card

### 3. Risks & Tips
- **Brick risk:** wrong image or missing `config.json` can prevent boot.
- Use only official SenseCAP files and tools.
- Avoid frequent power cycling during recovery.
- Keep backups offline and labeled with device S/N.
- Protect SSH keys with a passphrase.

Support: https://support.sensecapmx.com

## 🇵🇱 Polski

### 1. Backup config.json (Krytyczne)
- Wylacz urzadzenie, otworz panel, wyjmij karte SD i skopiuj `config.json` z partycji `resin-boot`.
- Plik jest unikalny dla urzadzenia. Nie udostepniaj go.

Oficjalny przewodnik (PL):
https://sensecap-mx.gitbook.io/home/sensecap-gateways/sensecap-m1/m1-troubleshooting/micro-sd-card-errors/replace-config.json-file

### 2. Flashowanie obrazu (Tylko gdy zaleci support)
- Sformatuj karte SD w SD Card Formatter, flashuj obraz SenseCAP M1 w BalenaEtcher, a potem przywroc `config.json` do `resin-boot`.
- Po starcie odczekaj 20-30 minut na aktualizacje OTA.

Oficjalny przewodnik (PL):
https://sensecap-mx.gitbook.io/home/sensecap-gateways/sensecap-m1/m1-troubleshooting/micro-sd-card-errors/format-existing-micro-sd-card

### 3. Ryzyka i wskazowki
- **Ryzyko bricka:** zly obraz lub brak `config.json` moze zablokowac start.
- Uzywaj tylko oficjalnych plikow i narzedzi SenseCAP.
- Unikaj czestych restartow podczas odzyskiwania.
- Przechowuj backupy offline i oznacz S/N urzadzenia.
- Zabezpiecz klucze SSH haslem.

Support: https://support.sensecapmx.com

**Last updated: March 2026**
