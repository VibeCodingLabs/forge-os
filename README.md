# ForgeOS

ForgeOS is the public post-wipe recovery and command-center bootstrap repo for rebuilding a Debian-based AI automation workstation from a clean install.

It is designed for Ghostnode / VibeCodingLabs operator machines, starting with the HP14 lab station, then promoting stable layers to the main workstation.

## What this repo does

ForgeOS provides an interactive installer for:

- Debian recovery base packages
- terminal UX and productivity tools
- ZSH autocomplete and syntax highlighting
- Bubble Tea / Lip Gloss Go TUI tooling
- Python Rich / Textual color UI tooling
- Kitty, Alacritty, WezTerm, tmux, Zellij, Ranger, Yazi, and file-manager tooling
- i3, Sway, Wayland, and compositor lab dependencies
- Rust, Go, Python, Node, pnpm, and Tauri 2 prerequisites
- security hardening and defensive scanners
- secret scanning and supply-chain tooling
- browser automation and API discovery prerequisites
- Obsidian operator vault setup
- local observability timers and ForgeOS logs

This repo is not a secrets store. Do not commit API keys, tokens, SSH keys, bounty evidence, private reports, cloud credentials, customer data, or personal identity material.

## Quick recovery path after a clean Debian install

Run this after the OS is installed and networking works:

```bash
sudo apt-get update
sudo apt-get install -y git ca-certificates curl

git clone https://github.com/VibeCodingLabs/forge-os.git
cd forge-os
chmod +x install.sh
./install.sh
```

## Recommended HP14 test order

Do not install the full workstation stack first.

Use the HP14 as the lab machine and install in this order:

1. Preflight + disk report
2. Minimal Recovery Base
3. Install Command Center UX stack
4. Test `forge-tui`
5. HP14 Lab Stack
6. Ghostnode Secure Workstation only after the earlier steps work

The full workstation profile installs many more packages, so it should be treated as a promotion target, not the first smoke test.

## Main menu

The installer currently exposes these top-level actions:

- Preflight + disk report
- Minimal Recovery Base
- HP14 Lab Stack
- Ghostnode Secure Workstation
- Custom Modules
- Show manifests
- Copy terminal configs
- Enable observability timers
- Install Command Center UX stack
- Launch Forge TUI if installed

## Custom modules

The custom module lane includes:

- Recovery base
- Terminal/session stack
- Desktop/compositor lab
- Dev runtime
- Tauri 2 desktop stack
- Security baseline
- Repo/secrets/code scanners
- Web security lab tools
- AI SDK stack
- Browser automation
- Obsidian knowledge vault
- ZSH productivity shell
- Bubble Tea / Lip Gloss Go TUI stack
- Python Rich / Textual color UI stack
- Full Command Center UX stack

## Repo layout

```text
install.sh                         # bootstrap entrypoint
bin/forge-menu.sh                  # interactive shell menu
cmd/forge-tui/main.go              # Bubble Tea / Lip Gloss TUI skeleton
configs/                           # terminal, shell, theme, and app configs
configs/zsh/                       # ForgeOS ZSH profile and helpers
configs/starship/                  # Starship prompt config
manifests/                         # install profile manifests
scripts/                           # installer modules and helpers
systemd/user/                      # local user services and timers
docs/                              # task maps, roadmaps, and supporting docs
FORGE.md                           # Master Operating Agreement
AGENTS.md                          # agent conduct and orchestration rules
SECURITY.md                        # security policy and safe-use boundaries
```

## Command Center UX lane

The Command Center UX lane installs the tooling needed to make the terminal feel like a real operator console:

- ZSH
- zsh-autosuggestions
- zsh-syntax-highlighting
- zsh-completions
- Starship
- fzf
- zoxide
- direnv
- Go
- Bubble Tea
- Lip Gloss
- Rich
- Textual
- Typer
- prompt-toolkit
- questionary
- yaspin / halo style spinner libraries

After installation, the Go TUI should be available as:

```bash
forge-tui
```

## Operating agreement

All human and agent work in this repo is governed by `FORGE.md`.

Read it before making changes. It defines the expected quality standard, agent conduct, documentation rules, security expectations, and ethical foundation for ForgeOS.

## Safety notes

- Use authorized testing only.
- Keep offensive security tools behind responsible-use boundaries.
- Do not run untrusted install scripts without review.
- Prefer Debian packages where possible.
- Treat external installers as supply-chain risk.
- Keep privileged actions explicit, logged, and reversible.
- Keep private evidence and credentials out of the repo.

## Status

ForgeOS is under active development. The HP14 Debian station is the intended smoke-test target before promoting profiles to the main workstation.