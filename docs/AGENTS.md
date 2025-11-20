# Agent Guidelines

Guidelines for AI code agents (like GitHub Copilot, Claude, ChatGPT, etc.) working on this dotfiles repository.

## Project Overview

This is an **ephemeral dotfiles system** that:
- Runs without root/admin privileges
- Works on macOS and Linux with zsh
- Uses Ansible for idempotent configuration
- Can be completely removed without leaving traces
- Keeps all dependencies local to the repository

## Core Principles

### 1. Ephemeral Nature
- All runtime data goes in `root/` (gitignored)
- All binaries, libraries, and temp files are local
- Clean mode must remove **everything**
- No system-wide modifications except optional `~/.zshrc` line

### 2. No Root Access Required
- Never use `sudo` or require elevated privileges
- All installations are user-local
- Use Python venv for dependencies
- Download portable binaries when needed

### 3. Idempotency
- All configuration via Ansible tasks
- Tasks must be safely re-runnable
- Check before create/modify
- Use Ansible's declarative approach

### 4. Platform Compatibility
- Support both macOS and Linux
- Use platform detection when needed
- Test on both platforms before committing
- Handle platform-specific edge cases gracefully

## Repository Structure Rules

### File Placement

```
Repository Root:
├── run.sh, install.sh, clean.sh    # Entry point scripts only
├── ansible.cfg                     # Ansible config only
├── README.md                       # User documentation only

ansible/:
├── inventories/                    # Inventory files (localhost.yml, etc.)
├── playbooks/                      # Main playbooks (run.yml, install.yml, clean.yml)
├── tasks/                          # Reusable task files
├── vars/                           # Variable definitions
├── files/                          # Static files to copy
└── templates/                      # Jinja2 templates (*.j2)

scripts/:
├── bash/                           # Bash scripts
└── python/                         # Python scripts

root/:                              # ALL GITIGNORED
├── bin/                            # Local binaries
├── lib/                            # Local libraries
├── venv/                           # Python virtual environment
├── cargo/                          # Cargo installation
└── tmp/                            # Temporary files

docs/:
├── ARCHITECTURE.md                 # Technical architecture
├── ROADMAP.md                      # Development roadmap
└── AGENTS.md            # This file
```

### What Goes Where

**Ansible Templates** (`ansible/templates/*.j2`):
- Shell aliases
- Shell functions
- Shell prompt configuration
- Dynamic configuration files

**Ansible Files** (`ansible/files/`):
- Static configuration files
- Files to be copied as-is

**Ansible Tasks** (`ansible/tasks/`):
- Reusable task definitions
- Should be included by playbooks
- Must be idempotent

**Scripts** (`scripts/bash/` or `scripts/python/`):
- Standalone executable scripts
- Made available in PATH via run mode
- Should have shebang and be executable

**Root** (`root/`):
- Downloaded binaries
- Generated files
- Temporary data
- **NEVER commit anything from here**

## Coding Standards

### Shell Scripts (Bash/Zsh)

```bash
#!/usr/bin/env zsh
# Brief description of the script

set -e  # Exit on error (where appropriate)

# Use meaningful variable names
DOTFILES_ROOT="${DOTFILES_ROOT:-$(pwd)}"

# Check prerequisites
if [[ ! -d "$DOTFILES_ROOT" ]]; then
    echo "Error: DOTFILES_ROOT not found"
    exit 1
fi

# Use functions for complex logic
setup_environment() {
    # Function implementation
}

# Main execution
main() {
    setup_environment
}

main "$@"
```

### Python Scripts

```python
#!/usr/bin/env python3
"""
Brief description of the script.
"""

import sys
from pathlib import Path


def main():
    """Main entry point."""
    # Implementation
    pass


if __name__ == "__main__":
    sys.exit(main())
```

### Ansible Playbooks

```yaml
---
- name: Descriptive playbook name
  hosts: localhost
  connection: local
  gather_facts: yes
  
  tasks:
    - name: Descriptive task name
      # Task implementation
      # Always use descriptive names
      # Check before creating/modifying
```

### Ansible Tasks

```yaml
---
- name: Descriptive task name
  # Use check_mode compatible modules when possible
  # Set changed_when appropriately
  # **NEVER** use tags
```

### Templates (Jinja2)

```jinja2
# {{ ansible_managed }}
# Description of what this template generates

# Use variables with defaults
export VARIABLE_NAME="{{ variable_name | default('default_value') }}"

# Platform-specific sections
{% if ansible_os_family == "Darwin" %}
# macOS-specific configuration
{% else %}
# Linux-specific configuration
{% endif %}
```

## Development Workflow

### 1. Before Making Changes

- Read relevant documentation (README, ARCHITECTURE, ROADMAP)
- Understand the current structure
- Check if similar functionality exists
- Consider platform compatibility

### 2. Making Changes

- Follow the repository structure rules
- Write idempotent Ansible tasks
- Add appropriate error handling
- Test on both macOS and Linux if possible
- Update documentation if needed

### 3. Testing

- Test run mode in a fresh shell
- Verify install mode adds/removes shell integration
- Ensure clean mode removes everything
- Check for platform-specific issues

### 4. Documentation

- Update README.md for user-facing changes
- Update ARCHITECTURE.md for structural changes
- Update ROADMAP.md to mark completed tasks
- Add comments in code for complex logic

## Common Patterns

### Environment Variables

Set in Ansible tasks, used in templates:

```yaml
- name: Set environment variables
  set_fact:
    dotfiles_root: "{{ playbook_dir | dirname }}"
    dotfiles_active: "1"
```

Definitions in vars files are preferred to setting facts in tasks. Only set facts when the variable is fetched as part of a previous task.

### Platform Detection

```yaml
- name: Platform-specific task
  # Task implementation
  when: ansible_os_family == "Darwin"  # macOS
  # or
  when: ansible_os_family == "Debian"  # Linux (example)
```

### Path Management

Always use absolute paths or well-defined variables:

```yaml
- name: Create directory
  file:
    path: "{{ dotfiles_root }}/root/bin"
    state: directory
```

### Idempotent Downloads

```yaml
- name: Download binary
  get_url:
    url: "https://example.com/binary"
    dest: "{{ dotfiles_root }}/root/bin/binary"
    mode: '0755'
  register: download_result
  changed_when: download_result.changed
```

## Anti-Patterns to Avoid

### ❌ Don't

- Use `sudo` or require root access
- Modify system-wide files (except optional `~/.zshrc` line)
- Hard-code paths (use variables)
- Assume specific OS versions
- Commit generated files
- Create non-idempotent tasks
- Mix concerns (keep scripts focused)
- Ignore errors silently

### ✅ Do

- Keep everything user-local
- Use Ansible variables and facts
- Detect platform and adapt
- Gitignore all ephemeral data
- Make tasks idempotent
- Handle errors gracefully
- Provide clear error messages
- Document complex logic

## Output Guidelines

### User-Facing Messages

Keep output minimal and clean:

```bash
# Good
echo "⏳ Setting up dotfiles environment for this session..."
# ... (silent execution)
echo "✓ Dotfiles environment loaded for this session"

# Bad
echo "Creating virtual environment..."
echo "Installing Ansible..."
echo "Running playbook..."
# (Too verbose)
```

### Ansible Output

Configure for minimal output in `ansible.cfg`:

```ini
[defaults]
stdout_callback = minimal
```

Suppress task output unless there's an error.

### Error Messages

Be clear and actionable:

```bash
# Good
echo "Error: Python 3 not found. Please install Python 3.6 or later."

# Bad
echo "Error: Command failed"
```

## Git Commit Guidelines

### Commit Message Format

```
<type>: <subject>

<body (optional)>

<footer (optional)>
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `refactor`: Code refactoring
- `test`: Adding tests
- `chore`: Maintenance tasks

### Examples

```
feat: add ripgrep as portable binary

- Download ripgrep based on platform
- Create alias for grep command
- Add to PATH in run mode

Closes #123
```

```
docs: update ARCHITECTURE.md with binary management

Add section describing how portable binaries are downloaded
and managed in the root/bin directory.
```

## Security Considerations

### 1. Download Verification

When downloading binaries:
- Verify checksums
- Use HTTPS only
- Download from official sources
- Check file integrity

### 2. Sensitive Data

- Never commit secrets
- Don't log sensitive information
- Use `.gitignore` for sensitive files
- Document any security assumptions

### 3. Execution Safety

- Validate inputs
- Quote variables in shell scripts
- Use safe defaults
- Handle untrusted data carefully

## Performance Guidelines

### 1. Lazy Loading

Don't load everything upfront:

```bash
# Good: Load only when needed
alias expensive_tool='load_expensive_tool && expensive_tool'

# Bad: Load everything at startup
source all_the_things.sh
```

### 2. Parallel Execution

Use Ansible's parallel features when possible:

```yaml
- name: Multiple tasks
  # Tasks can run in parallel
  async: 45
  poll: 0
```

### 3. Caching

Cache expensive operations:

```yaml
- name: Cache result
  # Implementation
  register: cached_result
  
- name: Use cached result
  # Use cached_result variable
  when: cached_result is defined
```

## Troubleshooting

### Common Issues

1. **Ansible not found**: Ensure `venv` is activated
2. **Template errors**: Check Jinja2 syntax and variable availability
3. **Path issues**: Use `{{ dotfiles_root }}` variable
4. **Platform issues**: Check `ansible_os_family` fact

### Debugging

Add debug output temporarily:

```yaml
- name: Debug variable
  debug:
    var: variable_name
    verbosity: 2
```

Run with verbose flag:
```bash
ansible-playbook -vvv playbook.yml
```

## Questions?

When in doubt:
1. Check existing patterns in the codebase
2. Review ARCHITECTURE.md for design decisions
3. Consult ROADMAP.md for planned features
4. Follow the principle: **ephemeral, portable, idempotent**

## Contributing Checklist

Before submitting changes:

- [ ] Code follows repository structure
- [ ] Ansible tasks are idempotent
- [ ] Works without root access
- [ ] Tested on macOS and/or Linux
- [ ] Documentation updated
- [ ] No system-wide modifications (except optional install)
- [ ] Clean mode removes all traces
- [ ] Commit message follows guidelines
- [ ] No sensitive data committed