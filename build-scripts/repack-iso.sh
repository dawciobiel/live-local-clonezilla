#!/bin/bash
set -euo pipefail

# =============================================================================
# Script: rebuild-iso.sh
# Purpose:
#   Repack customized Clonezilla-based Live ISO with BIOS (isolinux) and
#   UEFI (GRUB) support. Builds filesystem.squashfs from ROOTFS_DIR and
#   injects it into extracted ISO tree before xorriso run.
# =============================================================================

# ==========================
# Resolve dirs
# ==========================
WORK_DIR="$(pwd)"
EXTRACT_DIR="$WORK_DIR/artifacts/clonezilla/extracted"   # extracted ISO tree
ROOTFS_DIR="$WORK_DIR/rootfs"                            # customized rootfs
OUTPUT_DIR="$WORK_DIR/output/hardclone"                  # final ISO
mkdir -p "$OUTPUT_DIR"

# Bootloader files (outside ISO tree)
BOOT_DIR="$WORK_DIR/boot-files"
ISOLINUX_DIR="$BOOT_DIR/isolinux"
GRUB_EFI="$BOOT_DIR/GRUBX64.EFI"
BOOTX64_EFI="$BOOT_DIR/BOOTX64.EFI"

# Required env vars
: "${ISO_LABEL:?ISO_LABEL not set}"
: "${APP_VERSION:?APP_VERSION not set}"
: "${TIMESTAMP:?TIMESTAMP not set}"
: "${OUTPUT_ISO:?OUTPUT_ISO not set}"
OUTPUT_ISO="$OUTPUT_DIR/$OUTPUT_ISO"

# ==========================
# Load logging
# ==========================
source "$WORK_DIR/build-scripts/logging.sh"

# ==========================
# Helpers
# ==========================
die() { log_error "$*"; exit 1; }

need_bin() {
  command -v "$1" >/dev/null 2>&1 || die "Missing required binary: $1"
}

# ==========================
# Preconditions
# ==========================
log_info "Starting ISO repack process..."
log_debug "WORK_DIR      = $WORK_DIR"
log_debug "EXTRACT_DIR   = $EXTRACT_DIR"
log_debug "ROOTFS_DIR    = $ROOTFS_DIR"
log_debug "OUTPUT_DIR    = $OUTPUT_DIR"
log_debug "OUTPUT_ISO    = $OUTPUT_ISO"
log_debug "ISO_LABEL     = $ISO_LABEL"
log_debug "APP_VERSION   = $APP_VERSION"
log_debug "TIMESTAMP     = $TIMESTAMP"

for bin in xorriso mksquashfs cp rm mkdir chmod; do
    need_bin "$bin"
done
need_bin unsquashfs || true

[[ -d "$EXTRACT_DIR" ]] || die "Extracted ISO tree not found: $EXTRACT_DIR"
[[ -d "$ROOTFS_DIR"   ]] || die "Rootfs dir not found: $ROOTFS_DIR"

# ==========================
# Functions
# ==========================
check_boot_files() {
    log_info "Checking required boot files..."
    for f in isolinux.bin ldlinux.c32 isolinux.cfg; do
        [[ -f "$ISOLINUX_DIR/$f" ]] || die "Missing BIOS boot file: $ISOLINUX_DIR/$f"
    done
    for f in "$GRUB_EFI" "$BOOTX64_EFI"; do
        [[ -f "$f" ]] || die "Missing UEFI boot file: $f"
    done
    log_success "All boot files present."
}

stage_boot_files() {
    log_info "Staging boot files into ISO tree..."
    mkdir -p "$EXTRACT_DIR/isolinux"
    chmod -R u+w "$EXTRACT_DIR/isolinux" || true
    cp -av "$ISOLINUX_DIR/"* "$EXTRACT_DIR/isolinux/"

    mkdir -p "$EXTRACT_DIR/EFI/BOOT"
    cp -av "$GRUB_EFI"    "$EXTRACT_DIR/EFI/BOOT/GRUBX64.EFI"
    cp -av "$BOOTX64_EFI" "$EXTRACT_DIR/EFI/BOOT/BOOTX64.EFI"
    log_success "Boot files staged."
}

stage_grub_cfg() {
    log_info "Staging GRUB configuration files..."
    local ISO_DIR="$EXTRACT_DIR"

    # Ensure target dirs exist inside ISO tree
    mkdir -p "$ISO_DIR/isolinux"
    mkdir -p "$ISO_DIR/boot/grub"

    # Copy grub.cfg from project config into ISO structure
    cp config/grub/isolinux/grub.cfg "$ISO_DIR/isolinux/grub.cfg"
    cp config/grub/boot/grub/grub.cfg "$ISO_DIR/boot/grub/grub.cfg"

    # Set correct permissions
    chmod 644 "$ISO_DIR/isolinux/grub.cfg"
    chmod 644 "$ISO_DIR/boot/grub/grub.cfg"

    log_success "GRUB configs staged successfully."
}

warn_if_rootfs_mounted() {
    for mp in dev proc sys run dev/pts; do
        local p="$ROOTFS_DIR/$mp"
        if [[ -d "$p" ]] && mountpoint -q "$p"; then
            log_warn "Detected mounted pseudo-fs inside rootfs: $p"
            log_info "Attempting lazy unmount: umount -lf $p"
            sudo umount -lf "$p" || true
        fi
    done
}

update_squashfs() {
    log_info "Rebuilding filesystem.squashfs from rootfs..."
    local live_dir="$EXTRACT_DIR/live"
    local squashfs_file="$live_dir/filesystem.squashfs"
    mkdir -p "$live_dir"
    rm -f "$squashfs_file"

    log_debug "Preview rootfs /opt:"
    ls -la "$ROOTFS_DIR/opt" || true
    ls -la "$ROOTFS_DIR/opt/hardclone-cli" || true

    sudo mksquashfs "$ROOTFS_DIR" "$squashfs_file" -noappend -always-use-fragments -comp xz
    [[ -f "$squashfs_file" ]] || die "Failed to create filesystem.squashfs"
    log_success "filesystem.squashfs updated: $squashfs_file"

    if command -v unsquashfs >/dev/null 2>&1; then
        log_debug "Verifying /opt in squashfs (quick grep):"
        unsquashfs -l "$squashfs_file" | grep -E "^squashfs-root/opt(/|$)" || log_warn "/opt not listed in squashfs index."
    fi
}

repack_iso() {
    log_info "Repacking ISO with xorriso..."

    xorriso -as mkisofs \
        -r -J -joliet-long -l \
        -iso-level 3 \
        -V "$ISO_LABEL" \
        -o "$OUTPUT_ISO" \
        -b isolinux/isolinux.bin \
        -c isolinux/boot.cat \
        -no-emul-boot \
        -boot-load-size 4 \
        -boot-info-table \
        -eltorito-alt-boot \
        -e boot/grub/efi.img \
        -no-emul-boot \
        -isohybrid-gpt-basdat \
        -append_partition 2 0xef "$EXTRACT_DIR/boot/grub/efi.img" \
        "$EXTRACT_DIR"

    log_success "ISO repacked: $OUTPUT_ISO"
}


remove_wrong_files() {
    # Temporary solution. Deleting files with the wrong name bootx64.efi and grubx64.efi
    log_info "Removing $EXTRACT_DIR/EFI/boot/bootx64.efi"
    sudo rm /home/dawciobiel/IdeaProjects/hardclone/live-local-clonezilla/artifacts/clonezilla/extracted/EFI/boot/bootx64.efi
    log_info "Removing $EXTRACT_DIR/EFI/boot/grubx64.efi"
    sudo rm /home/dawciobiel/IdeaProjects/hardclone/live-local-clonezilla/artifacts/clonezilla/extracted/EFI/boot/grubx64.efi
}

# ==========================
# Main
# ==========================
check_boot_files
stage_boot_files
stage_grub_cfg
remove_wrong_files
warn_if_rootfs_mounted
update_squashfs
repack_iso

log_success "ISO repack process completed."
