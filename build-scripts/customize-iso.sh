#!/bin/bash
set -euo pipefail

# =============================================================================
# Customize ISO
# =============================================================================

# ==========================
# CONFIG
# ==========================
ISO_ARTIFACT="$(pwd)/artifacts/clonezilla/clonezilla-latest.iso"
WORK_DIR="$(pwd)/work"
ISO_MOUNT="$WORK_DIR/iso-mount"
ROOTFS_DIR="$WORK_DIR/rootfs"
OUTPUT_DIR="$(pwd)/artifacts/hardclone"
OUTPUT_ISO="$OUTPUT_DIR/hardclone-live.iso"
DOCKER_IMAGE="debian:bookworm-slim"  # Clonezilla packages base

mkdir -p "$ISO_MOUNT" "$ROOTFS_DIR" "$OUTPUT_DIR"

# ==========================
# Load logging functions
# ==========================
SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
source "$SCRIPT_DIR/logging.sh"

# ==========================
# Mount ISO
# ==========================
log_info "Mounting ISO..."
sudo mount -o loop "$ISO_ARTIFACT" "$ISO_MOUNT"

# ==========================
# Copy ISO contents
# ==========================
log_info "Copying ISO contents..."
rsync -a --exclude=filesystem.squashfs "$ISO_MOUNT/" "$ROOTFS_DIR/iso-root"

# ==========================
# Extract SquashFS
# ==========================
log_info "Extracting filesystem.squashfs..."
mkdir -p "$ROOTFS_DIR/squashfs-root"
sudo unsquashfs -d "$ROOTFS_DIR/squashfs-root" "$ISO_MOUNT/live/filesystem.squashfs"

sudo umount "$ISO_MOUNT"
log_success "ISO mounted and extracted."

# ==========================
# Customize rootfs via Docker
# ==========================
log_info "Running Docker to customize rootfs..."
docker run --rm -it \
    -v "$ROOTFS_DIR/squashfs-root:/mnt/rootfs" \
    -w /mnt/rootfs \
    $DOCKER_IMAGE /bin/bash -c "
apt-get update && \
apt-get install -y python3-pip && \
echo '[INFO] Packages installed inside Docker container'
"

log_success "Rootfs customization inside Docker completed."

# ==========================
# Repack filesystem.squashfs
# ==========================
log_info "Repacking filesystem.squashfs..."
sudo mksquashfs "$ROOTFS_DIR/squashfs-root" "$ROOTFS_DIR/iso-root/live/filesystem.squashfs" -comp xz -b 1048576 -Xbcj x86
log_success "SquashFS repacked."

# ==========================
# Create new ISO
# ==========================
log_info "Creating new ISO..."
cd "$ROOTFS_DIR/iso-root"
sudo genisoimage -o "$OUTPUT_ISO" \
    -b isolinux/isolinux.bin \
    -c isolinux/boot.cat \
    -no-emul-boot -boot-load-size 4 -boot-info-table \
    -eltorito-alt-boot \
    -e EFI/boot/bootx64.efi -no-emul-boot \
    -V "HARDCLONE_LIVE" -J -r .

log_success "Done! ISO created at: $OUTPUT_ISO"
