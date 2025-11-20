# Repository file structure

A concise reference for the ephemeral dotfiles repository: what lives here, what is generated, and what to inspect when modifying the project.

## Layout

```
dotfiles/
├── .gitignore
├── README.md
├── run.sh
├── install.sh
├── clean.sh
├── ansible/
│   ├── ansible.cfg
│   ├── inventories/
│   │   └── localhost.yml
│   ├── playbooks/
│   │   ├── run.yml
│   │   ├── install.yml
│   │   └── clean.yml
│   ├── tasks/
│   ├── vars/
│   └── templates/
├── scripts/
│   └── bash/_dotfiles_bootstrap.sh
├── root/          # ephemeral runtime data (gitignored)
└── docs/
    ├── ARCHITECTURE.md
    ├── AGENTS.md
    └── FILE_STRUCTURE.md
```

## Important files

- run.sh, install.sh, clean.sh — entry points for session, persistent install, and cleanup. They source `scripts/bash/_dotfiles_bootstrap.sh`.
- scripts/bash/_dotfiles_bootstrap.sh — creates/activates the `venv`, ensures Ansible is installed in the venv.
- ansible/ — holds playbooks, reusable tasks, variables and Jinja2 templates used to render the shell fragments.
- ansible/vars/main.yml — canonical path variables (dotfiles_root, dotfiles_bin, dotfiles_shell, etc.).
- ansible/templates/*.j2 — generate the sourced zsh fragments (env, definitions, aliases, overrides, functions, prompt, plugins).

## Ephemeral data (gitignored)

- root/ — runtime contents: bin/, venv/, cargo/, lib/, logs/, tmp/, shell/ (all generated and removed by clean).
- Generated shell fragments live under `root/shell/` and are sourced by the session when active.

## Gitignore highlights

Common ignored patterns central to the ephemeral design:
- root/
- .vscode/
- .DS_Store

## Permissions & behavior

- Entry scripts and user-facing scripts under `scripts/` should be executable (755).
- Ansible YAML and Jinja2 templates are readable (644).
- All operations run as the user (no sudo). The repo is non-invasive — only `install.sh` optionally modifies `~/.zshrc` to source `run.sh`.

## Philosophy

Keep the environment minimal, user-local and idempotent: use a repo-local venv and Ansible to generate small sourced zsh fragments. `clean.sh` and the Ansible clean playbook remove generated artefacts so the repo can be deleted without leaving traces.