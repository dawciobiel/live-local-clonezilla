#!/bin/bash
set -euo pipefail

# =============================================================================
# Customize RootFS
# =============================================================================

# ==========================
# Resolve dirs robustly
# ==========================
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
WORK_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CUSTOM_APPS_DIR="$WORK_DIR/custom-apps/opt"
ROOTFS_DIR="$WORK_DIR/rootfs"
PACKAGES_FILE="${PACKAGES_FILE:-$WORK_DIR/config/packages.txt}"

# ==========================
# Load logging functions
# ==========================
source "$SCRIPT_DIR/logging.sh"

log_info "Customizing rootfs..."
log_debug "Rootfs dir: $ROOTFS_DIR"
log_debug "Packages file: $PACKAGES_FILE"
log_debug "Custom apps dir: $CUSTOM_APPS_DIR"

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
    while read -r pkg; do
        [[ -z "$pkg" || "$pkg" =~ ^# ]] && continue  # Skip empty lines and comments
        log_info "Installing package: $pkg"
        sudo chroot "$ROOTFS_DIR" /bin/sh -c "apt-get update && apt-get install -y $pkg"
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
    log_debug "Content of rootfs/opt after copy:"
    ls -l "$ROOTFS_DIR/opt"
    log_success "Custom apps copied."
else
    log_warn "No custom apps found in $CUSTOM_APPS_DIR, skipping."
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
