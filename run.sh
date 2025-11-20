#!/usr/bin/env zsh
# Run mode: activate dotfiles for current shell session

# Get the full path to the script's directory
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)/scripts"

# shellcheck disable=SC1090
source "$SCRIPTS_DIR/bash/_dotfiles_bootstrap.sh"

# Detect if this script is being sourced and store result
is_script_sourced && DOTFILES_SCRIPT_SOURCED=1 || DOTFILES_SCRIPT_SOURCED=0

# Parse args: support --force and -f to ignore marker and force re-run
FORCE=0
for arg in "$@"; do
  case "$arg" in
    --force|-f)
      FORCE=1
      ;;
  esac
done

# If we already installed before and env file exists, load and skip work (unless forced)
if [[ "$FORCE" -ne 1 && -f "$DOTFILES_MARKER" && -f "$DOTFILES_ENVFILE" ]]; then
  dotfiles_source_env
  if [[ "${DOTFILES_SCRIPT_SOURCED:-0}" -eq 1 ]]; then
    return 0
  else
    exit 0
  fi
fi

# Execute run playbook
LOGFILE=$(dotfiles_logfile "run")
echo "⏳ Setting up dotfiles environment for this session..."
if ansible-playbook "$DOTFILES_ROOT/ansible/playbooks/run.yml" \
    -c local \
    --inventory "$DOTFILES_ROOT/ansible/inventories/localhost.yml" \
    > "$LOGFILE" 2>&1; then
  # Source generated environment file if it exists
  if dotfiles_source_env; then
    dotfiles_mark_complete
    echo "✓ Dotfiles environment loaded for this session"
  else
    echo "Error: Environment file not generated. Check log: $LOGFILE" >&2
    if [[ "${DOTFILES_SCRIPT_SOURCED:-0}" -eq 1 ]]; then
      return 1
    else
      exit 1
    fi
  fi
else
  echo "Error: Ansible playbook failed. Check log: $LOGFILE" >&2
  if [[ "${DOTFILES_SCRIPT_SOURCED:-0}" -eq 1 ]]; then
    return 1
  else
    exit 1
  fi
fi