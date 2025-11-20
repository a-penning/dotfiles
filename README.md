# Ephemeral Dotfiles

A portable, ephemeral dotfiles system that activates a curated zsh environment without requiring root.

## What it does

- Sets up a repository-local Python virtualenv and a local Rust toolchain.
- Generates and sources shell configuration files to provide aliases, functions, plugins and a git-aware prompt.
- Installs utilities locally so the host system remains untouched.

## Requirements

This repository expects the following tools to be installed on the host system:

- Zsh — a modern interactive shell (Zsh 5.0+ recommended)
- Git — for cloning and working with the repository
- Python 3 — used to create the repository-local virtual environment (Python 3.8+ recommended)
- Python's venv module — used to create isolated virtual environments (usually included with Python 3)

## Quick setup

1. Clone the repo:

```bash
git clone https://github.com/a-penning/dotfiles ~/.dotfiles
cd ~/.dotfiles
```

2. Temporary session (no persistent changes):

```bash
. ./run.sh
```

3. Persist for all new shells:

```bash
. ./install.sh
```

4. Remove integration and ephemeral data:

```bash
./clean.sh
```

## Modes

- [`run.sh`](run.sh:1): activate environment for current shell only.
- [`install.sh`](install.sh:1): add source line to your `~/.zshrc` so new shells activate the env.
- [`clean.sh`](clean.sh:1): remove generated files(`root/` contents, and repository if chosen).

## Prompt behavior

The prompt shows user and path and includes:
- Git branch: green when on `main`/`master`, yellow otherwise.
- Venv icon: `🚀` when the repository-managed venv is active, `🐍` when an external venv is active, `⚠️` when no venv is active.

## Utilities installed locally

- Rust/Cargo tools (installed into the repo-local Cargo root and symlinked into `root/bin`): 
  - rg (ripgrep) — shadows grep for fast, colorized searching
  - exa — replaces ls with a modern, colored listing
  - bat — replaces cat with syntax-highlighted output
  - fd — interactive replacement for find
  - zoxide — smarter directory jumping (provides `z` and used in place of `cd` via aliases)
  - procs — modern replacement for ps
  - btm (bottom) — interactive top alternative
  - git-delta — nicer git diffs / pager
  - dust — prettier du summaries

- Python packages (installed into `root/venv`): tree, tldr, speedtest-cli, thefuck, requests, pytest, pytest-order, pyjwt — provide handy CLI utilities and development tools.

- fzf — fuzzy finder used for history and file selection.

- Zsh plugins: zsh-autosuggestions (inline history suggestions) and zsh-syntax-highlighting (live syntax coloring).

## Notes & troubleshooting

- Scripts create a `venv` and install Ansible locally; ensure `python3` is available.
- If something fails, check logs under `logs/`.
- The repo is designed to be non-invasive; it only changes your `~/.zshrc` when you run `install.sh`.

## Docs

See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md:1) for technical details.