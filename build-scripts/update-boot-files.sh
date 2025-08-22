#!/bin/bash
set -euo pipefail

# =============================================================================
# Script: update-boot-files.sh
# Description:
#   Updates bootloader files for ISO (BIOS/UEFI) into boot-files/
#   Ensures bootx64.efi exists by copying grubx64.efi
# =============================================================================

# ==========================
# Load logging
# ==========================
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
source "$SCRIPT_DIR/logging.sh"

BOOT_DIR="$SCRIPT_DIR/boot-files"
mkdir -p "$BOOT_DIR"

log_info "This script updates bootloader files for ISO."
log_warn "Current URLs in the example are dead (404). Please provide alive URLs before using."
exit 1

# ==========================
# Parse arguments
# ==========================
FORCE=false
if [[ $# -gt 0 ]]; then
    case "$1" in
        --force)
            FORCE=true
            ;;
        *)
            log_info "Usage: $0 [--force]"
            exit 1
            ;;
    esac
fi

# ==========================
# Files to download (example, URLs need to be updated)
# ==========================
declare -A FILES=(
    # ["grubx64.efi"]="https://alive-url-to-grubx64.efi"
    # ["BOOTIA32.EFI"]="https://alive-url-to-grubia32.efi"
    # ["isohdpfx.bin"]="https://alive-url-to-isohdpfx.bin"
    # ["isolinux.bin"]="https://alive-url-to-isolinux.bin"
    # ["ldlinux.c32"]="https://alive-url-to-ldlinux.c32"
)

# ==========================
# Download files
# ==========================
for file in "${!FILES[@]}"; do
    url="${FILES[$file]}"
    dest="$BOOT_DIR/$file"

    if [[ -f "$dest" && $FORCE == false ]]; then
        log_info "Skipping $file (already exists)"
    else
        log_info "Downloading $file..."
        curl -L -o "$dest" "$url" || log_error "Failed to download $file"
    fi
done

# ==========================
# Ensure bootx64.efi exists
# ==========================
if [[ -f "$BOOT_DIR/grubx64.efi" ]]; then
    cp -n "$BOOT_DIR/grubx64.efi" "$BOOT_DIR/bootx64.efi"
    log_info "Ensured bootx64.efi exists (copied from grubx64.efi)"
else
    log_warn "grubx64.efi missing, cannot create bootx64.efi"
fi

log_success "Boot files update complete."
