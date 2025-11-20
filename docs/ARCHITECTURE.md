# Architecture

This document is a description of the dotfiles system Architecture.

## Design principles

- Ephemeral: runtime files live under repo-local directories and can be removed without leaving traces.
- Self-contained: dependencies are installed locally (repo-local Python venv, repo-local cargo).
- Idempotent: Ansible playbooks and tasks are written to be safely re-runnable.
- Non-invasive: run mode affects only the current shell session; install mode only adds a single source line to the user's shell startup.
- Portable: works without sudo on macOS and Linux (zsh).

## High-level flow

```
User runs script → Bootstrap Python venv → Ensure Ansible in venv → Run playbook → Render shell fragments → Source fragments
```

## Entry points

- run.sh — session-only activation; sources scripts/bash/_dotfiles_bootstrap.sh and runs ansible/playbooks/run.yml.
- install.sh — adds a source line to `~/.zshrc` via ansible/playbooks/install.yml and runs included setup tasks; when sourced it also activates the generated environment for the current shell.
- clean.sh — invokes ansible/playbooks/clean.yml to remove generated artifacts; the playbook removes `root/`. The interactive wrapper in clean.sh may offer to remove the repository directory but the playbook itself does not delete the repo root.

## Bootstrap behavior

- scripts/bash/_dotfiles_bootstrap.sh:
  - Determines DOTFILES_ROOT relative to the script location.
  - Creates and activates `venv` if missing.
  - Installs Ansible into the activated venv (so ansible-playbook runs from the venv).
  - Exports DOTFILES_VENV for prompt/venv-management logic and ensures `logs` exists.

## Ansible layout (current)

- ansible/ansible.cfg — configuration file lives under the ansible/ directory.
- ansible/inventories/localhost.yml — default local inventory.
- ansible/playbooks/{run.yml,install.yml,clean.yml}.
- ansible/tasks/ — reusable tasks, including:
  - setup_env.yml
  - setup_python.yml
  - setup_cargo.yml
  - setup_shell.yml
  - setup_fzf.yml
  - zsh_plugins.yml
  - cleanup.yml
- ansible/vars/ — main.yml, python_requirements.yml, cargo_requirements.yml.
- ansible/templates/ — Jinja2 templates rendered to repo runtime shell fragments under `root/shell/`:
  - env.zsh.j2, definitions.zsh.j2, overrides.zsh.j2, aliases.zsh.j2, functions.zsh.j2, prompt.zsh.j2, plugins.zsh.j2

## Tasks and features (implemented)

- setup_env.yml: creates ephemeral runtime directories under `root/` (bin, lib, tmp, logs, shell, shell/plugins).
- setup_python.yml: idempotently creates `venv` and installs pip packages listed in `ansible/vars/python_requirements.yml` into the venv.
- setup_cargo.yml: installs a repo-local Rust toolchain and cargo-installed binaries into `root/cargo/` and symlinks resulting binaries into `root/bin/`.
- setup_shell.yml: renders templates into `root/shell/*`, creates `custom.zsh` if missing, and includes plugin/fzf setup tasks.
- setup_fzf.yml: fetches latest fzf release metadata from GitHub and installs a platform-appropriate binary into `root/bin/` when needed.
- zsh_plugins.yml: clones zsh-autosuggestions and zsh-syntax-highlighting into `root/shell/plugins`.
- cleanup.yml: removes the `~/.zshrc` source line (if present), deletes `root/`.

## Generated artifacts (where to inspect)

- `root/shell/env.zsh` — sets DOTFILES_ACTIVE=1, DOTFILES_ROOT and prepends `root/bin` to PATH; sources other fragments.
- `root/shell/definitions.zsh` — editor selection, history configuration and cargo env vars (RUSTUP_HOME, CARGO_HOME).
- `root/shell/{overrides,aliases,functions,prompt,plugins}.zsh` — shell UX, aliases, functions (dotfiles-update, reinstall, venv wrapping), prompt logic, and plugin sourcing.

## Environment variables set when active

- DOTFILES_ACTIVE=1
- DOTFILES_ROOT — canonical repository root (derived from playbook_dir in ansible/vars/main.yml)
- PATH — `root/bin` is prepended
- DOTFILES_VENV — exported by bootstrap to identify the managed venv
- RUSTUP_HOME and CARGO_HOME — exported by templates/definitions.zsh when cargo support is active

## Prompt & venv handling (current)

- Prompt implementation sets PROMPT via a precmd hook that updates a lightweight git-branch string and a venv icon. The code uses PROMPT and precmd functions (not PS1) to avoid heavy prompt-time operations.
- functions.zsh implements logic to wrap external venv deactivate functions so the repository venv can be restored when appropriate.

## Notable differences vs older docs (code = source of truth)

- ansible.cfg is located at `ansible/ansible.cfg` (not the repository root).
- Additional templates exist (definitions.zsh, overrides.zsh, plugins.zsh) beyond older lists.
- Cargo and fzf setup tasks are implemented (setup_cargo.yml, setup_fzf.yml) — portable binaries and cargo installs are active parts of the codebase.
- Prompt uses PROMPT and precmd hook logic (the earlier doc referenced PS1).
- The bootstrap script installs Ansible into the `venv` and the scripts rely on the venv-installed ansible-playbook.

## Security & behavior guarantees

- No elevated privileges required; scripts do not use sudo.
- Non-invasive by default; `install.sh` optionally modifies `~/.zshrc` (a single line).
- `clean.sh` and the cleanup playbook remove generated artifacts; if you want the repo removed, do so manually or accept the interactive prompt in clean.sh.

## Where to change behavior

- scripts/bash/_dotfiles_bootstrap.sh — venv and ansible installation logic.
- ansible/playbooks/*.yml and ansible/tasks/*.yml — operational workflow.
- ansible/templates/*.j2 — user-facing shell fragments and prompt behavior.

## Debugging hints

- Ansible logs are written under `logs/`. Inspect `run-*.log`, `install-*.log`, `clean-*.log`.
- Reproduce or test locally with: `./run.sh` (or `source ./run.sh`) from the repository root.
