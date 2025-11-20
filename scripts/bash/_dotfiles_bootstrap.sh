#!/usr/bin/env zsh
# Bootstrap: Common setup for Python venv and Ansible
# This script should be sourced by the main scripts (run.sh, install.sh, clean.sh)

# ============================================================================
# Common Variables
# ============================================================================

# Determine DOTFILES_ROOT (directory two levels above the one containing this script)
if [[ -n "${ZSH_VERSION:-}" ]]; then
  DOTFILES_ROOT="$(cd "$(dirname "${(%):-%x}")/../.." && pwd)"
else
  DOTFILES_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")/../.." && pwd)"
fi
export DOTFILES_ROOT

# Marker and env file paths used across scripts
DOTFILES_MARKER="$DOTFILES_ROOT/root/.dotfiles_setup_complete"
DOTFILES_ENVFILE="$DOTFILES_ROOT/root/shell/env.zsh"
VENV_DIR="$DOTFILES_ROOT/root/venv"

# ============================================================================
# Helper Functions for Top-Level Scripts
# ============================================================================

# Check if the calling script is being sourced
# This must be called by the top-level script, not by the bootstrap itself
# Returns 0 (true) if sourced, 1 (false) if executed
is_script_sourced() {
  (return 0 2>/dev/null)
}

# Generate consistent log file paths
# Args: operation name (e.g., "run", "install", "clean")
dotfiles_logfile() {
  local operation="$1"
  echo "$DOTFILES_ROOT/logs/${operation}-$(date +%Y%m%d-%H%M%S).log"
}

# Source the generated environment file if it exists
# Returns 0 on success, 1 if file doesn't exist
dotfiles_source_env() {
  if [[ -f "$DOTFILES_ENVFILE" ]]; then
    source "$DOTFILES_ENVFILE"
    return 0
  else
    return 1
  fi
}

# Mark the setup as complete with a timestamp
dotfiles_mark_complete() {
  date -u +"%Y-%m-%dT%H:%M:%SZ" > "$DOTFILES_MARKER" || true
}

# ============================================================================
# Bootstrap Logic
# ============================================================================

# Detect if script is being sourced; when executed enable strict mode, but avoid killing interactive shell when sourced
if ! is_script_sourced; then
  set -euo pipefail
fi

# Ensure logs directory exists
mkdir -p "$DOTFILES_ROOT/logs"

# Ensure python3 is available
if ! command -v python3 >/dev/null 2>&1; then
  echo "Error: python3 not found. Install Python 3.6+ and try again." >&2
  return 1 2>/dev/null || exit 1
fi

# Create virtual environment if missing
if [[ ! -d "$VENV_DIR" ]]; then
  echo "⏳ Creating Python virtual environment..."
  python3 -m venv "$VENV_DIR"
fi

# Prevent venv from modifying our custom prompt
export VIRTUAL_ENV_DISABLE_PROMPT=1

# Activate venv
# shellcheck disable=SC1090
source "$VENV_DIR/bin/activate"

# Export dotfiles venv path for detection.
# Always overwrite DOTFILES_VENV so prompt logic consistently recognizes the managed venv.
export DOTFILES_VENV="$VENV_DIR"

python -m pip install --upgrade pip packaging >/dev/null

# Install ansible if not available in venv
if ! command -v ansible-playbook >/dev/null 2>&1; then
  echo "⏳ Installing Ansible into virtual environment..."
  python -m pip install --upgrade ansible >/dev/null
fi