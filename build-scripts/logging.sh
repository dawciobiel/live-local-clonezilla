#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# File: logging.sh
# Description:
#   Centralized logging functions with optional color output.
#   Use NO_COLOR=1 to disable colors.
#   Use DEBUG=1 to enable debug messages.
# =============================================================================

# -----------------------------
# Color definitions
# -----------------------------
if [[ -n "${NO_COLOR:-}" ]]; then
  COLOR_RESET=""
  COLOR_RED=""
  COLOR_GREEN=""
  COLOR_YELLOW=""
  COLOR_BLUE=""
  COLOR_MAGENTA=""
else
  COLOR_RESET="\033[0m"
  COLOR_RED="\033[31m"
  COLOR_GREEN="\033[32m"
  COLOR_YELLOW="\033[33m"
  COLOR_BLUE="\033[34m"
  COLOR_MAGENTA="\033[35m"
fi

# -----------------------------
# Logging functions
# -----------------------------
log_info() {
  printf "%b[INFO] %s%b\n" "$COLOR_BLUE" "$*" "$COLOR_RESET"
}

log_success() {
  printf "%b[SUCCESS] %s%b\n" "$COLOR_GREEN" "$*" "$COLOR_RESET"
}

log_warn() {
  printf "%b[WARNING] %s%b\n" "$COLOR_YELLOW" "$*" "$COLOR_RESET"
}

log_error() {
  printf "%b[ERROR] %s%b\n" "$COLOR_RED" "$*" "$COLOR_RESET"
}

log_debug() {
  if [[ "${DEBUG:-}" == "1" ]]; then
    printf "%b[DEBUG] %s%b\n" "$COLOR_MAGENTA" "$*" "$COLOR_RESET"
  fi
}

