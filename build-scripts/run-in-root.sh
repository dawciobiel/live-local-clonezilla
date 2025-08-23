#!/usr/bin/env bash
set -euo pipefail

# ================================================================
# Script: run-in-root.sh
# Purpose:
#   Run a command inside the rootfs using chroot if available,
#   otherwise fallback to proot (useful for CI like GitHub Actions).
# ================================================================

ROOTFS_DIR="${ROOTFS_DIR:-$(pwd)/rootfs}"

# ==========================
# Helper: logging
# ==========================
log_info()  { echo -e "\033[1;34m[INFO]\033[0m $*"; }
log_warn()  { echo -e "\033[1;33m[WARN]\033[0m $*"; }
log_error() { echo -e "\033[1;31m[ERROR]\033[0m $*" >&2; }

# ==========================
# Detect if we are root
# ==========================
if [ "$(id -u)" -ne 0 ]; then
    log_warn "You are not root. Some operations may fail inside chroot."
fi

# ==========================
# Try chroot first
# ==========================
if command -v chroot >/dev/null 2>&1; then
    log_info "Trying chroot into $ROOTFS_DIR"
    if sudo chroot "$ROOTFS_DIR" "$@" 2>/dev/null; then
        exit 0
    else
        log_warn "chroot failed, falling back to proot..."
    fi
else
    log_warn "chroot not available, falling back to proot..."
fi

# ==========================
# Fallback: proot
# ==========================
if command -v proot >/dev/null 2>&1; then
    log_info "Running inside proot..."
    proot -R "$ROOTFS_DIR" -w / /bin/sh -c "$*"
else
    log_error "Neither chroot nor proot is available. Cannot continue."
    exit 1
fi

