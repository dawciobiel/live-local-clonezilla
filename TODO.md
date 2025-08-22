# TODO – Hardclone Live Local Clonezilla

## Repozytorium
- [✅] Stworzyć projekt jako repozytorium GitHub
- [ ] Sprawdzić czy IntelliJ IDEA posiada jakieś super wtyczki do współpracy z GitHub, np. dla GitHub Actions

## 📦 Build System
- [✅] Uporządkować strukturę katalogów `build-scripts/`
- [❌] Dodać obsługę `proot` zamiast `chroot` (dla GitHub Actions)
- [ ] Umożliwić lokalne testowanie builda (`build-local.sh`)
- [ ] Przenieść artefakty ISO do `artifacts/clonezilla/`
- [✅] Stworzyć kolorowany output dla logów. Tak aby np. nazwa zbudowanego obrazu .iso byla w innym kolorze
- [✅] Pakiet pythondialog (dialog.py) można umieścić w folderze głównym lub w lib (odpowiedni import)
- [✅] Aplikacja sprawdza numer wersji za pomocą `git` z pliku VERSION - warto to zmienić, bo wymaga to `git` w systemie.

## 💿 ISO Customization
- [✅] Dodać własne pakiety (np. `python3`, `fish`, `git`, `dialog`)
- [🔄] Skonfigurować domyślnego użytkownika i uprawnienia `sudo`
- [🔄] Dodać własne skrypty do `custom-apps/opt/`
- [ ] Dodać motyw bootowania (GRUB/isolinux)
- [ ] Sprawdzić wsparcie UEFI i BIOS

## 🔧 Scripts
- [✅] Ujednolicić logowanie w skryptach (funkcja `log_info`, `log_error`)
- [ ] Obsłużyć błędy krytyczne (`set -euo pipefail`)
- [ ] Napisać testy dla `extract-base-iso.sh` i `repack-iso.sh`
- [ ] Zrobić skrypt do szybkiego uruchamiania ISO w `virt-manager`

## 🚀 CI/CD (GitHub Actions)
- [❌] Workflow dla pełnego builda ISO
- [❌] Workflow do szybkiego testu (bez repackowania)
- [❌] Dodanie cache pakietów dla przyspieszenia buildów
- [❌] Publikacja ISO jako release na GitHub

## 🧪 Testing
- [ ] Test bootowania w trybie BIOS (VirtualBox/QEMU)
- [ ] Test bootowania w trybie UEFI
- [ ] Test działania internetu w trybie Live
- [ ] Sprawdzenie, czy wszystkie dodatkowe pakiety są obecne

## 📖 Documentation
- [ ] Opisać proces budowy ISO krok po kroku
- [ ] Dodać przykłady uruchamiania w VirtualBox/virt-manager
- [ ] Lista znanych problemów + obejścia
- [ ] Krótki FAQ dla użytkowników

---
**Legenda:**
- ✅ – Zrobione  
- 🔄 – W trakcie  
- ❌ – Do zrobienia  

