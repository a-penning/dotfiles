#!/usr/bin/env zsh
# Clean mode: remove dotfiles integration and ephemeral data

# Get the full path to the script's directory
SCRIPTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)/scripts"

# shellcheck disable=SC1090
source "$SCRIPTS_DIR/bash/_dotfiles_bootstrap.sh"

# Detect if this script is being sourced and store result
is_script_sourced && DOTFILES_SCRIPT_SOURCED=1 || DOTFILES_SCRIPT_SOURCED=0

# Execute clean playbook
LOGFILE=$(dotfiles_logfile "clean")
echo "⏳ Cleaning dotfiles environment..."
if ansible-playbook "$DOTFILES_ROOT/ansible/playbooks/clean.yml" \
    -c local \
    --inventory "$DOTFILES_ROOT/ansible/inventories/localhost.yml" \
    > "$LOGFILE" 2>&1; then
  echo "✓ Clean completed. Note: this script does not delete the repository itself."

  # If dotfiles were active in this shell, handle exit behavior based on how this script was invoked.
  # When sourced we can exit the current shell to fully clear the environment.
  # When executed we cannot exit the caller's shell — prompt the user to remove DOTFILES_ROOT and advise exiting.
  if [[ -n "${DOTFILES_ACTIVE:-}" ]]; then
    echo "● Dotfiles were active when this script ran."
    echo

    # Offer to remove the repository automatically if the user confirms.
    if [[ -t 0 ]]; then
      read -r "REPLY?Do you want to remove '$DOTFILES_ROOT' now? [y/(n)] "
      if [[ "$REPLY" =~ ^[Yy]$ ]]; then
        if rm -rf "$DOTFILES_ROOT"; then
          echo "✓ Repository removed."
        else
          echo "Error: failed to remove $DOTFILES_ROOT" >&2
        fi
      else
        echo "Repository not removed."
        echo "To fully remove the dotfiles repository and clear the environment, run:"
        echo
        echo "  rm -rf \"$DOTFILES_ROOT\""
        echo
        echo "After removing the repository, start a new shell or run 'exit' to leave your current session."
        echo
      fi
    fi
    if [[ "${DOTFILES_SCRIPT_SOURCED:-0}" -eq 1 ]]; then
      return 0
    else
      exit 0
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