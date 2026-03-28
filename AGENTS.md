# Agent Instructions for dotfiles-gnome

> [!IMPORTANT]
> 共通の基本ルールは [DOTFILES_COMMON_RULES.md](./DOTFILES_COMMON_RULES.md) を参照してください。

# PROJECT KNOWLEDGE BASE

**Repository:** dotfiles-gnome
**Role:** GNOME desktop environment configuration — extensions, shortcuts, dconf settings, Mozc input, and sticky keys

## STRUCTURE

```text
dotfiles-gnome/
├── _mk/                         # Makefile sub-targets
│   ├── extensions.mk           # GNOME extension install targets
│   ├── gnome.mk                # GNOME settings targets
│   ├── mozc.mk                 # Mozc input method targets
│   ├── shortcuts.mk            # Keyboard shortcut targets
│   └── sticky-keys.mk          # Sticky keys disable targets
├── dot-config/                 # [Link Target] XDG config files
│   └── mozc/                   # Mozc iBus config → ~/.config/mozc/
│       └── ibus_config.textproto
├── gnome-extensions/           # GNOME extension management
│   ├── enabled-extensions.txt  # Extension list
│   ├── extensions-settings.dconf
│   └── *.sh                    # Install/test scripts
├── gnome-settings/             # GNOME dconf exports
│   ├── gnome-settings-export-*/ # Timestamped dconf dumps
│   └── setup-*.sh              # Setup scripts
├── gnome-shortcuts/            # Keyboard shortcut config
│   └── export-current-shortcuts.sh
├── mozc/                       # Mozc setup scripts (internal, NOT linked)
│   ├── check_import_status.sh
│   ├── import_ut_dictionary.py # Dictionary import
│   └── setup_mozc_import.sh
├── sticky-keys/                # Sticky keys management
│   ├── *.sh                    # Disable/fix scripts
│   └── *.desktop               # Autostart entries
└── Makefile                    # Setup entry point (includes _mk/*.mk)
```

## COMPONENT LAYOUT CONVENTION

This repository is part of the **dotfiles polyrepo** orchestrated by `dotfiles-core`.
All changes MUST comply with the central layout rules. Please refer to the central [ARCHITECTURE.md](https://raw.githubusercontent.com/yohi/dotfiles-core/refs/heads/master/docs/ARCHITECTURE.md) for the full, authoritative rules and constraints.

## THIS COMPONENT — SPECIAL NOTES

- GNOME settings are applied via `dconf load` and shell scripts, NOT symlinks (except `dot-config/mozc/`).
- `dot-config/mozc/ibus_config.textproto` is linked to `~/.config/mozc/ibus_config.textproto` via `ln -sfn`.
- Root-level `mozc/` contains setup scripts (NOT a link target).
- `_mk/` splits Makefile targets by GNOME subsystem (extensions, shortcuts, mozc, etc.).
- `gnome-settings/` contains timestamped dconf exports — keep directory naming convention: `gnome-settings-export-YYYYMMDD_HHMMSS/`.
- `sticky-keys/*.desktop` files are autostart entries — installed to `~/.config/autostart/` via scripts.
- Scripts that use `dconf`, `gsettings`, or `gnome-extensions` require a running GNOME session.

## CODE STYLE

- **Documentation / README**: Japanese (日本語)
- **AGENTS.md**: English
- **Commit Messages**: Japanese, Conventional Commits (e.g., `feat: 新機能追加`, `fix: バグ修正`)
- **Shell**: `set -euo pipefail`, dynamic path resolution, idempotent operations

## FORBIDDEN OPERATIONS

Per `opencode.jsonc` (when present), these operations are blocked for agent execution:

- `rm` (destructive file operations)
- `ssh` (remote access)
- `sudo` (privilege escalation)
