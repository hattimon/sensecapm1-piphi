# ⚠️ Safety Procedures / Procedury Bezpieczeństwa
**Before installing PiPhi on SenseCAP M1! / Przed instalacją PiPhi na SenseCAP M1!**

**Proceed with extreme caution. These steps can brick your device. Always backup first. / Działaj z najwyższą ostrożnością. Kroki mogą uszkodzić urządzenie. Zawsze zrób backup.**

## 1. Backup config.json (Critical!)
**EN:** Copy `config.json` from "resin-boot" partition **BEFORE** any flashing. Unique per device – do not share!  
[Official Guide (EN): Replace config.json](https://sensecap-mx.gitbook.io/home/sensecap-gateways/sensecap-m1/m1-troubleshooting/micro-sd-card-errors/replace-config.json-file) [page:1]

**PL:** Skopiuj `config.json` z partycji "resin-boot" **PRZED** flashowaniem. Unikalny dla urządzenia – nie udostępniaj!  
[Oficjalny przewodnik (PL): Zamień config.json](https://sensecap-mx.gitbook.io/home/sensecap-gateways/sensecap-m1/m1-troubleshooting/micro-sd-card-errors/replace-config.json-file) [page:1]

**Tip:** Power off, open panel (2 screws + yellow sticker), remove SD, copy file via reader. Ask SenseCAP support if lost. / Wyczyść: Wyłącz, otwórz panel (2 śruby + żółta naklejka), wyjmij SD, skopiuj plik czytnikiem. Poproś support SenseCAP jeśli zgubiony.[page:0]

## 2. Flashing Image (Only if advised!)
**EN:** Format SD with SD Card Formatter 5.0.1, flash SenseCAP M1 Image with BalenaEtcher, restore config.json. Wait 20-30min post-boot.  
[Official Guide (EN): Format & Flash](https://sensecap-mx.gitbook.io/home/sensecap-gateways/sensecap-m1/m1-troubleshooting/micro-sd-card-errors/format-existing-micro-sd-card) [page:0]

**PL:** Sformatuj SD w SD Card Formatter 5.0.1, flashuj obraz SenseCAP M1 w BalenaEtcher, przywróć config.json. Czekaj 20-30min po starcie.  
[Oficjalny przewodnik (PL): Formatuj i flashuj](https://sensecap-mx.gitbook.io/home/sensecap-gateways/sensecap-m1/m1-troubleshooting/micro-sd-card-errors/format-existing-micro-sd-card) [page:0]

**Downloads:** Image/Etcher/Formatter from official links in docs. Test internet first. Ethernet recommended. / Pobierz: Obraz/Etcher/Formatter z oficjalnych linków w docs. Najpierw sprawdź internet. Polecany Ethernet.[page:0]

## 3. Risks & Tips
- **Brick risk:** Wrong image/config = no boot. Use only official SenseCAP files.
- **SSH Safety:** Use passphrase-protected keys; test on dev device.
- **Post-install:** Monitor via https://status.sensecapmx.cloud. No frequent reboots.
- **Ryzyko bricka:** Zły obraz/config = brak startu. Tylko oficjalne pliki SenseCAP.
- **SSH:** Klucze z hasłem; testuj na urządzeniu dev.
- **Po instalacji:** Monitoruj https://status.sensecapmx.cloud. Unikaj częstych restartów.[page:0]

**Contact:** SenseCAP Support https://support.sensecapmx.com or Discord. / Kontakt: Support SenseCAP https://support.sensecapmx.com lub Discord.[page:0]

**Last updated: March 2026**
