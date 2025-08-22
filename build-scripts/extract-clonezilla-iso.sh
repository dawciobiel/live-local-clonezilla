#!/bin/bash
set -euo pipefail

# ==========================
# DIRECTORIES
# ==========================
WORK_DIR="$(pwd)"
BASE_ISO="$WORK_DIR/artifacts/clonezilla/clonezilla-base.iso"
EXTRACT_DIR="$WORK_DIR/artifacts/clonezilla/extracted"
ROOTFS_DIR="$WORK_DIR/rootfs"

# ==========================
# Load logging functions
# ==========================
SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
source "$SCRIPT_DIR/logging.sh"

# ==========================
# Unmount previous pseudo-filesystems
# ==========================
log_info "Unmounting any previously mounted pseudo-filesystems (sudo required)..."
log_info "You may be prompted for your password."
sudo umount -lf "$ROOTFS_DIR/proc" 2>/dev/null || true
sudo umount -lf "$ROOTFS_DIR/sys" 2>/dev/null || true
sudo umount -lf "$ROOTFS_DIR/dev" 2>/dev/null || true

# ==========================
# Remove old rootfs
# ==========================
log_info "Removing old rootfs directory if it exists [$ROOTFS_DIR] (sudo required)..."
log_info "You may be prompted for your password."
sudo chown -R "$(whoami):$(whoami)" "$ROOTFS_DIR" || true
sudo rm -rf "$ROOTFS_DIR" || true
mkdir -p "$ROOTFS_DIR"

# ==========================
# Extract ISO
# ==========================
log_info "Extracting ISO..."
7z x -y "$BASE_ISO" -o"$EXTRACT_DIR"

# Find SquashFS
SQUASHFS_FILE=$(find "$EXTRACT_DIR" -type f -name '*.squashfs' | head -n1)
log_debug "SquashFS file: $SQUASHFS_FILE"

if [[ -z "$SQUASHFS_FILE" ]]; then
    log_error "Could not find squashfs file in ISO!"
    exit 1
fi

# ==========================
# Extract SquashFS to rootfs
# ==========================
log_info "Extracting SquashFS to rootfs (sudo required)..."
log_info "You may be prompted for your password."
sudo unsquashfs -d "$ROOTFS_DIR" "$SQUASHFS_FILE"

log_success "Rootfs ready at $ROOTFS_DIR"
