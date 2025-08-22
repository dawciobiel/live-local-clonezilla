#!/bin/bash
set -euo pipefail

# =============================================================================
# Script: setup-network.sh
# Description:
#   Configures network in the Clonezilla-based rootfs so that eth0
#   gets DHCP IP and basic DNS after boot.
# =============================================================================

# ==========================
# Resolve dirs
# ==========================
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
WORK_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
ROOTFS_DIR="$WORK_DIR/rootfs"

# ==========================
# Load logging
# ==========================
source "$SCRIPT_DIR/logging.sh"

log_info "Setting up network in rootfs: $ROOTFS_DIR"

# ==========================
# STEP 1: Install DHCP client
# ==========================
log_info "Installing isc-dhcp-client..."
proot -R "$ROOTFS_DIR" /bin/bash -c "apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y isc-dhcp-client" || log_warn "isc-dhcp-client installation failed, continuing..."

# ==========================
# STEP 2: Configure /etc/network/interfaces
# ==========================
log_info "Writing /etc/network/interfaces..."
cat > "$ROOTFS_DIR/etc/network/interfaces" <<'EOF'
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet dhcp
EOF
log_success "/etc/network/interfaces configured."

# ==========================
# STEP 3: Configure /etc/resolv.conf
# ==========================
log_info "Writing /etc/resolv.conf..."
cat > "$ROOTFS_DIR/etc/resolv.conf" <<'EOF'
nameserver 1.1.1.1
nameserver 8.8.8.8
EOF
log_success "/etc/resolv.conf configured."

log_success "Network setup complete. eth0 will get IP via DHCP at boot."
