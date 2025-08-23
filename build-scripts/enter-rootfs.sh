#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Script: enter-rootfs.sh
# Description:
#   Enter the prepared rootfs using either chroot (preferred for local runs)
#   or proot (fallback for restricted environments like GitHub Actions).
#
# Usage:
#   ./enter-rootfs.sh
# =============================================================================

SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
WORK_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ROOTFS_DIR="$WORK_DIR/rootfs"

# ==========================
# LOGGING
# ==========================
log_info()  { echo -e "\033[1;32m[INFO]\033[0m $*"; }
log_warn()  { echo -e "\033[1;33m[WARN]\033[0m $*"; }
log_error() { echo -e "\033[1;31m[ERROR]\033[0m $*"; }
log_debug() { echo -e "\033[0;36m[DEBUG]\033[0m $*"; }

# ==========================
# Ensure rootfs exists
# ==========================
if [ ! -d "$ROOTFS_DIR" ]; then
    log_error "Rootfs directory not found: $ROOTFS_DIR"
    exit 1
fi

# ==========================
# Try chroot mounts (if root and allowed)
# ==========================
use_chroot=false
if command -v chroot >/dev/null 2>&1 && [ "$(id -u)" -eq 0 ]; then
    log_debug "Root privileges detected, attempting chroot mounts..."

    mount -t proc /proc "$ROOTFS_DIR/proc" 2>/dev/null || true
    mount --rbind /sys "$ROOTFS_DIR/sys" 2>/dev/null || true
    mount --make-rslave "$ROOTFS_DIR/sys" 2>/dev/null || true
    mount --rbind /dev "$ROOTFS_DIR/dev" 2>/dev/null || true
    mount --make-rslave "$ROOTFS_DIR/dev" 2>/dev/null || true
    mount --rbind /run "$ROOTFS_DIR/run" 2>/dev/null || true
    mount --make-rslave "$ROOTFS_DIR/run" 2>/dev/null || true

    if mountpoint -q "$ROOTFS_DIR/proc"; then
        use_chroot=true
        log_info "chroot environment prepared."
    else
        log_warn "Failed to mount /proc, falling back to proot."
    fi
fi

# ==========================
# Run shell in chroot or proot
# ==========================
if [ "$use_chroot" = true ]; then
    log_info "Entering chroot environment..."
    chroot "$ROOTFS_DIR" /bin/sh
else
    if ! command -v proot >/dev/null 2>&1; then
        log_error "Neither chroot (working) nor proot available. Install proot."
        exit 1
    fi

    log_info "Using proot fallback..."
    proot -R "$ROOTFS_DIR" /bin/sh
fi

# ==========================
# Cleanup mounts (failsafe)
# ==========================
log_debug "Cleaning up mounts..."
for mp in proc sys dev dev/pts run; do
    TARGET="$ROOTFS_DIR/$mp"
    if [ -d "$TARGET" ] && mountpoint -q "$TARGET"; then
        log_debug "Unmounting $TARGET"
        umount -lf "$TARGET" || true
    fi
done

log_info "Exited rootfs environment."

