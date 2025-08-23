#!/bin/bash
set -euo pipefail

# ==========================
# Resolve dirs robustly
# ==========================
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
WORK_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"   # Root folder of the project
ROOTFS_DIR="$WORK_DIR/rootfs"

# ==========================
# Load logging functions
# ==========================
source "$SCRIPT_DIR/logging.sh"

# Prompt for sudo password upfront
sudo -v
export DEBUG=0

# ==========================
# TIMESTAMP & LOGGING
# ==========================
TIMESTAMP="$(date +%Y%m%d-%H%M)"
LOG_DIR="$WORK_DIR/output/hardclone"
LOG_FILE="$LOG_DIR/build-$TIMESTAMP.log"
mkdir -p "$LOG_DIR"

log_info "Note: During this build process, you may be asked for your sudo password."
log_info "This is required for operations on rootfs (deleting old rootfs, extracting SquashFS, etc.)."

# redirect stdout/stderr to screen and file
mkdir -p "$(dirname "$LOG_FILE")"
tee "$LOG_FILE" <<< "[INFO] Logging started"
exec > >(tee -a "$LOG_FILE" >/dev/tty) 2>&1

log_info "Starting local build process..."
log_debug "Log file: $LOG_FILE"
log_debug "Bash version: ${BASH_VERSION:-unknown}"
log_debug "WORK_DIR: $WORK_DIR"
log_debug "ROOTFS_DIR: $ROOTFS_DIR"

# ==========================
# CHECK DEPENDENCIES
# ==========================
# if ! command -v proot >/dev/null 2>&1; then
#     log_error "Missing dependency: proot is not installed."
#     echo "Please install it with one of the following commands:"
#     echo "  openSUSE:   sudo zypper install proot"
#     echo "  Ubuntu/Debian: sudo apt-get install -y proot"
#     echo "  Arch/Manjaro:  sudo pacman -S proot"
#     exit 1
# else
#     log_success "Dependency check passed: proot found."
# fi

# ==========================
# OPTIONAL: Clean rootfs from previous build
# ==========================
if [ -d "$ROOTFS_DIR" ]; then
    log_info "Cleaning rootfs from previous build..."
    sudo rm -rf "$ROOTFS_DIR"
fi
mkdir -p "$ROOTFS_DIR"
log_info "Rootfs is clean and ready."

# ==========================
# APP VERSION
# ==========================
VERSION_FILE="$WORK_DIR/custom-apps/opt/hardclone-cli/VERSION"
if [[ -f "$VERSION_FILE" ]]; then
    APP_VERSION="$(<"$VERSION_FILE")"
    log_info "hardclone-cli version: $APP_VERSION"
else
    log_warn "VERSION file not found at $VERSION_FILE"
    APP_VERSION="unknown"
fi

# ==========================
# ISO LABEL (≤ 32 chars)
# ==========================
ISO_LABEL="HC-Clonezilla-${APP_VERSION}"
MAX_VOLID=32
if [ "${#ISO_LABEL}" -gt "$MAX_VOLID" ]; then
    ISO_LABEL="${ISO_LABEL:0:$MAX_VOLID}"
    log_warn "ISO label too long. Truncated to: $ISO_LABEL"
fi
log_info "Final ISO label to use: $ISO_LABEL"

# ==========================
# OUTPUT ISO FILE NAME
# ==========================
export OUTPUT_ISO="hardclone-clonezilla-live-${APP_VERSION}-${TIMESTAMP}.iso"
export TIMESTAMP APP_VERSION ISO_LABEL

# ==========================
# STEP 1: Download Clonezilla ISO
# ==========================
log_info "Step 1: Download Clonezilla ISO"
"$WORK_DIR/build-scripts/download-clonezilla-iso.sh"
log_info "Step 1 completed."

# ==========================
# STEP 2: Extract ISO
# ==========================
log_info "Step 2: Extract Clonezilla ISO"
"$WORK_DIR/build-scripts/extract-clonezilla-iso.sh"
log_info "Step 2 completed."

# ==========================
# STEP 3: Customize RootFS
# ==========================
log_info "Step 3: Customize RootFS (install packages, copy custom apps)"
"$WORK_DIR/build-scripts/customize-rootfs.sh"
log_info "Step 3 completed."

# ==========================
# STEP X: Setup Networking
# ==========================
# log_info "Step X: Setup Networking by isc-dhcp-client"
# log_info "Installing isc-dhcp-client..."
#
# # Ensure root ownership of APT directories in rootfs
# chown -R 0:0 "$ROOTFS_DIR/var/lib/apt" "$ROOTFS_DIR/var/cache/apt"
#
# # Use proot with -0 to simulate root inside rootfs
# proot -0 -R "$ROOTFS_DIR" /bin/bash -c '
#     set -e
#     export DEBIAN_FRONTEND=noninteractive
#
#     # Clean cache (non-fatal)
#     apt-get clean || true
#
#     # Update package lists (non-fatal)
#     apt-get update || echo "[WARNING] apt-get update failed, continuing..."
#
#     # Install package (non-fatal)
#     apt-get install -y isc-dhcp-client || echo "[WARNING] Failed to install isc-dhcp-client (non-fatal)"
# '
#
# log_info "Step X completed."


# ==========================
# STEP 4: Repack ISO
# ==========================
log_info "Step 4: Repack customized ISO"
"$WORK_DIR/build-scripts/repack-iso.sh"
log_info "Step 4 completed."

# ==========================
# BUILD FINISHED
# ==========================
log_success "Build process finished successfully!"
log_info "Output ISO is in: $WORK_DIR/output/hardclone/"
log_info "Final ISO label: $ISO_LABEL"
