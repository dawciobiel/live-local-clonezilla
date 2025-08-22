#!/bin/bash
set -euo pipefail

# ==========================
# USER CONFIGURATION
# ==========================
ISO_URL="ftp://free.nchc.org.tw/clonezilla-live/stable/clonezilla-live-3.2.2-15-amd64.iso"

# ==========================
# DIRECTORIES
# ==========================
ARTIFACTS_DIR="$(pwd)/artifacts/clonezilla"
mkdir -p "$ARTIFACTS_DIR"

ISO_FILE=$(basename "$ISO_URL")
VERSION=$(echo "$ISO_FILE" | sed -E "s/clonezilla-live-(.*)\.iso/\1/")
TARGET_DIR="$ARTIFACTS_DIR/$VERSION"
mkdir -p "$TARGET_DIR"

ISO_PATH="$TARGET_DIR/$ISO_FILE"
SHA_FILE="$TARGET_DIR/SHA256SUMS"

# ==========================
# Load logging functions
# ==========================
SCRIPT_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"
source "$SCRIPT_DIR/logging.sh"

# ==========================
# Download ISO if missing
# ==========================
if [[ -f "$ISO_PATH" ]]; then
    log_info "ISO already exists: $ISO_PATH"
else
    log_info "Downloading Clonezilla ISO..."
    log_debug "ISO URL: $ISO_URL"
    curl -# -o "$ISO_PATH" "$ISO_URL"
fi

# ==========================
# Download SHA256SUMS
# ==========================
SHA_URL="$(dirname "$ISO_URL")/SHA256SUMS"
if curl --head --silent --fail "$SHA_URL" >/dev/null; then
    log_info "Downloading SHA256SUMS..."
    curl -# -o "$SHA_FILE" "$SHA_URL"

    log_info "Verifying SHA256 checksum..."
    if (cd "$TARGET_DIR" && sha256sum -c --ignore-missing "$(basename "$SHA_FILE")"); then
        log_success "SHA256 checksum OK"
    else
        log_error "SHA256 checksum mismatch! Re-downloading ISO..."
        rm -f "$ISO_PATH"
        curl -# -o "$ISO_PATH" "$ISO_URL"

        log_info "Verifying SHA256 checksum again..."
        (cd "$TARGET_DIR" && sha256sum -c --ignore-missing "$(basename "$SHA_FILE")")
    fi
else
    log_warn "No SHA256SUMS file available at $SHA_URL. Skipping verification."
fi

# ==========================
# Create base symlink
# ==========================
ln -sf "$VERSION/$ISO_FILE" "$ARTIFACTS_DIR/clonezilla-base.iso"
log_info "Base ISO symlink created: $ARTIFACTS_DIR/clonezilla-base.iso -> $ISO_FILE"
