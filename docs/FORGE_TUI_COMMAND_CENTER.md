# Forge TUI Command Center

`forge-tui` is the terminal-native command center for ForgeOS.

It is built with Go, Bubble Tea, and Lip Gloss. It is designed to be the real post-clone control surface for a fresh Debian workstation.

## Build

From the repo root:

```bash
bash scripts/install-tui-dev.sh
```

This installs Go dependencies and builds:

```bash
~/.local/bin/forge-tui
```

Run it with:

```bash
forge-tui
```

## Controls

```text
up/down or j/k      move
enter               open or run
esc/backspace/left  back
q                   back or quit
ctrl+c              quit
```

## Main screens

### Install

Install profiles and runtime stacks:

- Full Command Center Install
- Minimal Recovery Base
- ZSH Productivity Shell
- Dev Runtime
- Tauri Desktop Stack

### Desktop

Desktop command-center controls:

- River/Sway/i3 desktop command center
- Waybar
- Eww widget panel
- wallpaper helper
- clipboard manager tooling
- River launch

### Security + Performance

Hardening and performance controls:

- firewall/security hardening
- antivirus tooling
- audit/AppArmor/fail2ban baseline
- performance tuning
- firewall status
- ClamAV verification

### Ops + Doctor

Operational checks and helpers:

- Forge Doctor
- preflight report
- dictation/accessibility installer
- dictation note helper
- fallback shell menu

### Logs + Observability

Local visibility tools:

- tail ForgeOS logs
- list state markers
- inspect systemd user timers
- open `btop`

## Recommended fresh install flow

```bash
sudo apt-get update
sudo apt-get install -y git ca-certificates curl

git clone https://github.com/VibeCodingLabs/forge-os.git
cd forge-os
chmod +x install.sh scripts/*.sh

bash scripts/install-tui-dev.sh
forge-tui
```

Then in the TUI choose:

```text
Install → Full Command Center Install
```

After completion:

```bash
sudo reboot
```

Then from a TTY:

```bash
river
```

## Verification

Run:

```bash
bash scripts/forge-doctor.sh
```

or from the TUI:

```text
Ops + Doctor → Forge Doctor
```

The doctor report checks installed commands, config files, services, timers, firewall status, and workstation readiness.
