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

# Ensure top-level scripts and ansible invocations use the repository ansible.cfg
export ANSIBLE_CONFIG="$DOTFILES_ROOT/ansible/ansible.cfg"

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

# Interpreter used to (re)create the venv: prefer homebrew's — ambient python3
# varies during macOS shell startup (PATH may lack homebrew → ancient system 3.9).
_df_python="/opt/homebrew/bin/python3"
[[ -x "$_df_python" ]] || _df_python="$(command -v python3)"

# Decide whether the venv needs (re)creating. Judge it ONLY against its own
# interpreter, never ambient python3: the venv keeps working regardless of PATH.
_df_recreate=""
if [[ ! -x "$VENV_DIR/bin/python" ]]; then
  # Missing or broken symlink (a half-deleted venv leaves lib/ behind with no bin/)
  _df_recreate="missing interpreter"
else
  # An upgraded underlying interpreter strands site-packages under the old
  # minor version (pyvenv.cfg still records it) — losing pip and ansible.
  _df_live_ver="$("$VENV_DIR/bin/python" -c 'import sys; print("%d.%d" % sys.version_info[:2])' 2>/dev/null || true)"
  _df_venv_ver="$(sed -n 's/^version = \([0-9]*\.[0-9]*\).*/\1/p' "$VENV_DIR/pyvenv.cfg" 2>/dev/null || true)"
  if [[ -z "$_df_live_ver" || "$_df_live_ver" != "$_df_venv_ver" ]]; then
    _df_recreate="python ${_df_venv_ver:-?} → ${_df_live_ver:-broken}"
  fi
  unset _df_live_ver _df_venv_ver
fi

if [[ -n "$_df_recreate" ]]; then
  echo "⏳ Recreating Python virtual environment ($_df_recreate)..."
  "$_df_python" -m venv --clear "$VENV_DIR"
fi

# Prevent venv from modifying our custom prompt
export VIRTUAL_ENV_DISABLE_PROMPT=1

# Activate venv
# shellcheck disable=SC1090
source "$VENV_DIR/bin/activate"

# Export dotfiles venv path for detection.
# Always overwrite DOTFILES_VENV so prompt logic consistently recognizes the managed venv.
export DOTFILES_VENV="$VENV_DIR"

# Install tooling only on (re)create or when ansible is missing — steady-state
# shells must do zero pip/network work (this runs on every shell startup).
# proxmoxer/requests: required by dynamic-inventory plugins (community.proxmox)
if [[ -n "$_df_recreate" ]] || ! command -v ansible-playbook >/dev/null 2>&1; then
  echo "⏳ Installing Ansible into virtual environment..."
  python -m pip install --upgrade pip packaging >/dev/null
  python -m pip install --upgrade ansible proxmoxer requests >/dev/null
fi
unset _df_recreate _df_python