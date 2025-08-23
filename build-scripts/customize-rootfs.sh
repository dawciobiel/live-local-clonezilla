#!/bin/bash
set -euo pipefail

# =============================================================================
# customize-rootfs.sh
# =============================================================================
#
# Skrypt do personalizacji systemu rootfs dla Live ISO Clonezilla.
#
# Funkcje:
#   1. Montowanie pseudo-systemów plików (/dev, /proc, /sys) w rootfs dla chroot.
#   2. Instalacja pakietów z pliku konfiguracyjnego packages.txt.
#      - Lista pakietów aktualizowana jest tylko raz.
#      - W trybie DEBUG=1 wyświetlany jest pełny output apt-get.
#      - W normalnym trybie output apt-get jest cichy, chyba że wystąpi błąd.
#   3. Kopiowanie własnych aplikacji do /opt w rootfs (custom-apps/opt).
#   4. Kopiowanie dodatkowych plików użytkownika lub konfiguracji (custom-files).
#   5. Czyszczenie i odmontowywanie pseudo-filesystemów po zakończeniu.
#
# Zmienne używane przez skrypt:
#   WORK_DIR         - katalog główny projektu
#   ROOTFS_DIR       - katalog rootfs do personalizacji
#   CUSTOM_APPS_DIR  - katalog z aplikacjami do kopiowania do /opt
#   CUSTOM_FILES_DIR - katalog z dodatkowymi plikami do kopiowania do rootfs
#   PACKAGES_FILE    - plik z listą pakietów do instalacji
#   DEBUG            - flaga debugowania (0 = wyłączone, 1 = włączone)
#
# Wymagania:
#   - uprawnienia root (sudo)
#   - dostęp do internetu dla apt-get install
#   - istniejące katalogi CUSTOM_APPS_DIR i CUSTOM_FILES_DIR (opcjonalnie)
#
# Użycie:
#   DEBUG=1 ./customize-rootfs.sh
#   lub
#   ./customize-rootfs.sh
#
# Autor: Dawid Bielecki
# Data: 2025-08-23
# =============================================================================

# ==========================
# Resolve dirs robustly
# ==========================
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
WORK_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CUSTOM_APPS_DIR="$WORK_DIR/custom-apps/opt"
CUSTOM_FILES_DIR="$WORK_DIR/custom-files"
ROOTFS_DIR="$WORK_DIR/rootfs"
PACKAGES_FILE="${PACKAGES_FILE:-$WORK_DIR/config/packages.txt}"

# ==========================
# Load logging functions
# ==========================
: "${DEBUG:=0}"
source "$SCRIPT_DIR/logging.sh"

log_info "Customizing rootfs..."
log_debug "Rootfs dir: $ROOTFS_DIR"
log_debug "Packages file: $PACKAGES_FILE"
log_debug "Custom apps dir: $CUSTOM_APPS_DIR"
log_debug "Custom files dir: $CUSTOM_FILES_DIR"

# ==========================
# STEP 0: Mount pseudo-filesystems for chroot
# ==========================
sudo mount --bind /dev "$ROOTFS_DIR/dev" || true
sudo mount --bind /dev/pts "$ROOTFS_DIR/dev/pts" || true
sudo mount --bind /proc "$ROOTFS_DIR/proc" || true
sudo mount --bind /sys "$ROOTFS_DIR/sys" || true

# ==========================
# STEP 1: Install packages (if applicable)
# ==========================
if [[ -f "$PACKAGES_FILE" ]]; then
    log_info "Installing packages from $PACKAGES_FILE..."

    # Update package lists once
    if [[ "$DEBUG" -eq 1 ]]; then
        log_debug "=========================="
        log_debug "Running apt-get update inside chroot"
        log_debug "Command: apt-get update"
        log_debug "=========================="
        sudo chroot "$ROOTFS_DIR" /bin/sh -c "apt-get update"
    else
        if ! sudo chroot "$ROOTFS_DIR" /bin/sh -c "apt-get update" >/dev/null 2>&1; then
            log_warn "apt-get update failed. Check your network or sources list."
        fi
    fi

    while read -r pkg; do
        [[ -z "$pkg" || "$pkg" =~ ^# ]] && continue

        if [[ "$DEBUG" -eq 1 ]]; then
            log_debug "=========================="
            log_debug "Installing package: $pkg"
            log_debug "Command: apt-get install -y $pkg"
            log_debug "=========================="
            sudo chroot "$ROOTFS_DIR" /bin/sh -c "apt-get install -y $pkg"
        else
            if ! sudo chroot "$ROOTFS_DIR" /bin/sh -c "apt-get install -y $pkg" >/dev/null 2>&1; then
                log_warn "Package '$pkg' failed to install. See apt logs for details."
            fi
        fi

    done < "$PACKAGES_FILE"

    log_success "Package installation completed."
else
    log_warn "No packages file found, skipping package installation."
fi

# ==========================
# STEP 2: Copy custom apps
# ==========================
if [[ -d "$CUSTOM_APPS_DIR" ]]; then
    log_info "Copying custom apps to /opt in rootfs..."
    sudo mkdir -p "$ROOTFS_DIR/opt"
    sudo cp -a "$CUSTOM_APPS_DIR/." "$ROOTFS_DIR/opt/"
    if [[ "$DEBUG" -eq 1 ]]; then
        log_debug "Content of rootfs/opt after copy:"
        ls -l "$ROOTFS_DIR/opt"
    fi
    log_success "Custom apps copied."
else
    log_warn "No custom apps found in $CUSTOM_APPS_DIR, skipping."
fi

# ==========================
# STEP 2b: Copy additional custom files
# ==========================
if [[ -d "$CUSTOM_FILES_DIR" ]]; then
    log_info "Copying additional custom files to rootfs..."
    sudo cp -a "$CUSTOM_FILES_DIR/." "$ROOTFS_DIR/"
    if [[ "$DEBUG" -eq 1 ]]; then
        log_debug "Content of rootfs after copying custom files:"
        find "$ROOTFS_DIR" -type f -exec ls -l {} \;
    fi
    log_success "Custom files copied."
else
    log_warn "No additional custom files found in $CUSTOM_FILES_DIR, skipping."
fi

# ==========================
# STEP 3: Cleanup mounts (failsafe)
# ==========================
ROOTFS="${ROOTFS_DIR:-$(pwd)/rootfs}"

for mp in proc sys dev dev/pts run; do
    TARGET="$ROOTFS/$mp"
    if [ -d "$TARGET" ] && mountpoint -q "$TARGET"; then
        log_debug "Unmounting $TARGET"
        sudo umount -lf "$TARGET" || true
    fi
done

log_success "Rootfs customization complete!"
