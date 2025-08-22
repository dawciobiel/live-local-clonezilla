#!/bin/bash
set -euo pipefail

# =============================================================================
# Script: fix-scripts-format-to-utf8-lf.sh
# Description:
#   Converts all .sh files in the current directory and subdirectories to:
#     - UTF-8 encoding
#     - LF line endings
#     - Uses #!/bin/bash shebang
#   Ensures scripts are executable
#   Supports excluding directories
# =============================================================================

# ==========================
# Resolve dirs
# ==========================
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
WORK_DIR="$(pwd)"

# ==========================
# Load logging
# ==========================
source "$SCRIPT_DIR/logging.sh"

log_info "Starting script normalization in: $WORK_DIR"

# ==========================
# Directories to exclude
# ==========================
EXCLUDE_DIRS=("custom-apps")  # możesz dodać kolejne foldery tutaj
EXCLUDE_FIND_ARGS=()
for dir in "${EXCLUDE_DIRS[@]}"; do
    EXCLUDE_FIND_ARGS+=( -path "$WORK_DIR/$dir" -prune -o )
done

# ==========================
# Find .sh files (excluding EXCLUDE_DIRS)
# ==========================
sh_files=$(find "$WORK_DIR" "${EXCLUDE_FIND_ARGS[@]}" -type f -name '*.sh' -print)

if [[ -z "$sh_files" ]]; then
    log_warn "No .sh files found in $WORK_DIR"
fi

# ==========================
# Process each file
# ==========================
for f in $sh_files; do
    log_info "Processing $f ..."

    tmp_file="$f.tmp"

    # Convert to UTF-8
    if iconv -f UTF-8 -t UTF-8 "$f" -o "$tmp_file" 2>/dev/null; then
        log_debug "UTF-8 encoding OK for $f"
    else
        log_warn "Failed to convert $f to UTF-8, copying original"
        cp "$f" "$tmp_file"
    fi

    # Normalize line endings to LF
    if command -v dos2unix >/dev/null 2>&1; then
        dos2unix "$tmp_file" >/dev/null 2>&1 || log_warn "dos2unix failed on $f"
    else
        sed -i 's/\r$//' "$tmp_file"
    fi

    # Replace shebang
    sed -i '1s|^#!/usr/bin/env bash$|#!/bin/bash|' "$tmp_file"

    # Overwrite original
    mv "$tmp_file" "$f"

    # Ensure executable
    chmod +x "$f"

    log_success "$f processed successfully."
done

log_success "✅ All .sh scripts have been normalized."
