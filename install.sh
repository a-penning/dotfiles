#!/usr/bin/env zsh
# Install mode: persist dotfiles for new shells by adding source line to ~/.zshrc

# Get the full path to the script's directory
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)/scripts"

# shellcheck disable=SC1090
source "$SCRIPTS_DIR/bash/_dotfiles_bootstrap.sh"

# Detect if this script is being sourced and store result
is_script_sourced && DOTFILES_SCRIPT_SOURCED=1 || DOTFILES_SCRIPT_SOURCED=0

# Choose install vs reinstall log name and user message
if [[ -n "${DOTFILES_REINSTALL:-}" ]]; then
  LOGFILE=$(dotfiles_logfile "reinstall")
else
  LOGFILE=$(dotfiles_logfile "install")
  echo "⏳ Installing dotfiles..."
fi

# Execute install playbook
if ansible-playbook "$DOTFILES_ROOT/ansible/playbooks/install.yml" \
    -c local \
    --inventory "$DOTFILES_ROOT/ansible/inventories/localhost.yml" \
    > "$LOGFILE" 2>&1; then
  # If script is being sourced, also source generated environment to activate in current session
  if [[ "$DOTFILES_SCRIPT_SOURCED" -eq 1 ]]; then
    # Source generated environment file if it exists
    if dotfiles_source_env; then
      dotfiles_mark_complete
      if [[ -n "${DOTFILES_REINSTALL:-}" ]]; then
        echo "✓ Dotfiles reinstalled and loaded for this session"
      else
        echo "✓ Dotfiles installed and loaded for this session"
      fi
    else
      echo "Error: Environment file not generated. Check log: $LOGFILE" >&2
      if [[ "${DOTFILES_SCRIPT_SOURCED:-0}" -eq 1 ]]; then
        return 1
      else
        exit 1
      fi
    fi
  else
    # Not sourced - just mark complete and provide instructions
    dotfiles_mark_complete
    if [[ -n "${DOTFILES_REINSTALL:-}" ]]; then
      echo "✓ Dotfiles reinstalled. To use now: source \"~/.zshrc\""
    else
      echo "✓ Dotfiles installed. To use now: source \"~/.zshrc\""
    fi
  fi
else
  echo "Error: Installation failed. Check log: $LOGFILE" >&2
  if [[ "${DOTFILES_SCRIPT_SOURCED:-0}" -eq 1 ]]; then
    return 1
  else
    exit 1
  fi
fi