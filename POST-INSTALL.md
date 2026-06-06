# ForgeOS — Post-Install Walkthrough

> **Target:** Debian 13 (Trixie) + River Wayland compositor  
> **Profile:** Ghostnode Secure Workstation / HP14 Lab  
> **Observability:** All steps log to `~/.forge-os/logs/`

---

## Table of Contents

1. [Prerequisites](#1-prerequisites)
2. [Clone & Bootstrap](#2-clone--bootstrap)
3. [Performance Tuning](#3-performance-tuning)
4. [Core System Install](#4-core-system-install)
5. [River Compositor Setup](#5-river-compositor-setup)
6. [Systemd Session Units](#6-systemd-session-units)
7. [UX/UI Stack](#7-uxui-stack)
8. [Shell & Terminal](#8-shell--terminal)
9. [Observability Layer](#9-observability-layer)
10. [Verification Checklist](#10-verification-checklist)
11. [Troubleshooting](#11-troubleshooting)

---

## 1. Prerequisites

Fresh Debian 13 (Trixie) minimal install. No desktop environment selected during OS install.

```bash
# Confirm OS
cat /etc/os-release
# Expected: VERSION_CODENAME=trixie (or bookworm for Debian 12)

# Update base system
sudo apt-get update && sudo apt-get upgrade -y

# Install git and curl if missing
sudo apt-get install -y git curl ca-certificates
```

**Required before continuing:**
- User is in `sudo` group: `sudo usermod -aG sudo $USER` (re-login after)
- `$HOME` partition has ≥ 20GB free
- Internet connection active

---

## 2. Clone & Bootstrap

```bash
# Clone forge-os
git clone https://github.com/VibeCodingLabs/forge-os.git ~/forge-os-setup
cd ~/forge-os-setup

# Make install entry executable
chmod +x install.sh

# Launch the Forge command center
./install.sh
```

From the menu:
- **Option 1** — Run preflight (shows disk, RAM, kernel, Debian version)
- Review output before proceeding

---

## 3. Performance Tuning

> Run this **before** installing the desktop stack. It sets zram, CPU governor, I/O scheduler, and journald limits.

```bash
# Must be run as root
sudo bash ~/forge-os-setup/scripts/performance-tune.sh
```

What this does:

| Tunable | Value | Rationale |
|---|---|---|
| `vm.swappiness` | 10 | Prefer RAM; push to swap only under pressure |
| `vm.dirty_ratio` | 10 | Bound write cache for desktop responsiveness |
| CPU governor | `schedutil` | Reactive scaling; better than `ondemand` on modern kernels |
| I/O scheduler (SSD) | `mq-deadline` | Low latency for NVMe/SATA SSD |
| I/O scheduler (HDD) | `bfq` | Fair queuing for spinning disks |
| zram size | 50% of RAM (lz4) | Compressed RAM swap, avoids disk thrash |
| journald disk cap | 512MB | Prevent log sprawl |

Logs written to: `~/.forge-os/logs/perf/`

**Reboot after this step:**
```bash
sudo reboot
```

---

## 4. Core System Install

```bash
cd ~/forge-os-setup
./install.sh
# Select: Option 2 — Minimal Recovery Base
```

This installs: `git curl wget build-essential tmux htop btop ripgrep fzf bat eza figlet gum python3 nodejs golang cargo`

Then:
```bash
# Select: Option 4 — Dev Runtime
# Installs: python3-venv pipx nodejs pnpm cargo cmake shellcheck shfmt
```

---

## 5. River Compositor Setup

### 5a. Install River and Wayland stack

```bash
sudo apt-get install -y \
  river rivertile \
  waybar mako wofi rofi \
  swayidle swaylock wlopm \
  grim slurp wl-clipboard \
  xdg-desktop-portal xdg-desktop-portal-wlr \
  dbus-user-session xwayland \
  pipewire pipewire-pulse wireplumber \
  brightnessctl playerctl \
  fonts-noto-color-emoji fonts-jetbrains-mono
```

### 5b. Install River init config

```bash
mkdir -p ~/.config/river
cp ~/forge-os-setup/configs/river/init ~/.config/river/init
chmod +x ~/.config/river/init
```

### 5c. Verify River config

```bash
# Check syntax (River will report errors on launch)
cat ~/.config/river/init

# Test River can find its deps
command -v river rivertile waybar mako wofi grim slurp
```

### 5d. Start River (TTY launch)

Log out to a TTY (Ctrl+Alt+F2), then:

```bash
# Add to ~/.bash_profile or ~/.zprofile for auto-start on TTY1
if [ -z "$WAYLAND_DISPLAY" ] && [ "$(tty)" = '/dev/tty1' ]; then
  exec river > ~/.forge-os/logs/river/river-tty.log 2>&1
fi
```

Or launch manually:
```bash
river
```

**Key bindings (default — Super = Windows/Meta key):**

| Binding | Action |
|---|---|
| `Super + Enter` | Open terminal (kitty/wezterm/foot) |
| `Super + D` | App launcher (wofi/rofi) |
| `Super + B` | Browser (firefox/chromium) |
| `Super + S` | Screenshot (region) |
| `Super + Shift + S` | Screenshot (full screen) |
| `Super + H/J/K/L` | Focus left/down/up/right |
| `Super + Shift + H/J/K/L` | Swap views |
| `Super + F` | Toggle fullscreen |
| `Super + Shift + Space` | Toggle float |
| `Super + 1–9` | Switch to tag/workspace |
| `Super + Shift + 1–9` | Move view to tag |
| `Super + Alt + H/L` | Adjust main ratio |
| `Super + +/-` | Adjust main count |
| `Super + Shift + Q` | Close view |
| `Super + Shift + E` | Exit River |
| `XF86Audio*` | Volume / mic / media controls |
| `XF86Brightness*` | Screen brightness |

---

## 6. Systemd Session Units

### 6a. Install user units

```bash
mkdir -p ~/.config/systemd/user
cp ~/forge-os-setup/systemd/user/*.service \
   ~/forge-os-setup/systemd/user/*.timer \
   ~/.config/systemd/user/

systemctl --user daemon-reload
```

### 6b. Enable units

```bash
# Seat bootstrap (runs on login)
systemctl --user enable --now forge-seat.service

# Observability snapshots (every 15 min)
systemctl --user enable --now forge-obs.timer

# Heartbeat + observer (existing)
systemctl --user enable --now forge-heartbeat.timer forge-observer.timer

# River session (optional — use if launching River via systemd)
# systemctl --user enable river-session.service
```

### 6c. Verify units

```bash
systemctl --user status forge-seat.service forge-obs.timer forge-heartbeat.timer forge-observer.timer

# Check logs
journalctl --user -u forge-seat.service -n 20
journalctl --user -u forge-obs.timer -n 20
```

---

## 7. UX/UI Stack

```bash
cd ~/forge-os-setup
./install.sh
# Select: Option 9 — Install Command Center UX stack
# (runs recovery base + terminal stack + zsh + TUI dev + rich UI)
```

This installs in order:
1. Recovery base packages
2. Terminal emulators (kitty, wezterm, alacritty, foot, tmux, zellij)
3. ZSH with Oh-My-Zsh / Starship prompt
4. Bubble Tea + Lip Gloss Go TUI libraries
5. Python Rich + Textual color UI stack
6. All dotfiles copied to `~/.config/`

### Manual config copy (if needed)

```bash
./install.sh
# Select: Option 7 — Copy terminal configs
```

---

## 8. Shell & Terminal

```bash
# Set zsh as default shell
chsh -s $(which zsh)

# Re-login or:
exec zsh

# Verify Starship prompt
starship --version

# Verify zoxide
zoxide --version
```

**Terminal preference order:** kitty → wezterm → alacritty → foot

Configs live at:
- `~/.config/kitty/kitty.conf`
- `~/.config/wezterm/wezterm.lua`
- `~/.config/alacritty/alacritty.toml`
- `~/.zshrc` + `~/.config/zsh/forge.zsh`
- `~/.config/starship.toml`

---

## 9. Observability Layer

ForgeOS logs all activity to `~/.forge-os/logs/`:

| Path | Contents |
|---|---|
| `logs/river/session.log` | River session start/stop events |
| `logs/river/session-err.log` | River stderr (crash diagnostics) |
| `logs/perf/` | Performance tuning run logs + pre/post snapshots |
| `logs/perf/snapshots/` | Periodic system state snapshots |
| `logs/obs/` | Observability collector output (every 15 min) |
| `logs/seat.log` | Seat bootstrap events |
| `logs/forge-menu-*.log` | Install session logs |

### Live log tailing

```bash
# Watch River session
tail -f ~/.forge-os/logs/river/session.log

# Watch observability snapshots
tail -f ~/.forge-os/logs/obs/obs.log

# Latest performance snapshot
ls -lt ~/.forge-os/logs/perf/snapshots/ | head -3
cat $(ls -t ~/.forge-os/logs/perf/snapshots/*.txt | head -1)

# Systemd user journal
journalctl --user -f
```

### Trigger manual obs snapshot

```bash
systemctl --user start forge-obs.service
cat ~/.forge-os/logs/obs/obs.log | tail -60
```

---

## 10. Verification Checklist

Run after full install and reboot:

```bash
# --- System ---
echo "Kernel: $(uname -srmo)"
cat /etc/os-release | grep PRETTY_NAME

# --- Performance ---
cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
sysctl vm.swappiness
swapon --show        # should show zram device
zramctl              # should show zram0 with lz4

# --- River ---
command -v river && river --version
ls -la ~/.config/river/init
head -5 ~/.config/river/init  # should be #!/bin/sh

# --- Display stack ---
command -v waybar mako wofi grim slurp wl-copy
command -v pipewire wireplumber

# --- Shell ---
echo $SHELL          # should be /usr/bin/zsh or /bin/zsh
starship --version
zoxide --version

# --- Systemd units ---
systemctl --user status forge-seat.service
systemctl --user status forge-obs.timer
systemctl --user status forge-heartbeat.timer
systemctl --user status forge-observer.timer

# --- Logs exist ---
ls ~/.forge-os/logs/

# --- Terminal ---
kitty --version || wezterm --version || alacritty --version
```

All green? You're live on ForgeOS.

---

## 11. Troubleshooting

### River won't start
```bash
# Check River log
cat ~/.forge-os/logs/river/session-err.log

# Test init script directly
bash -x ~/.config/river/init 2>&1 | head -40

# Missing rivertile?
command -v rivertile || sudo apt-get install -y rivertile river
```

### No audio
```bash
pipewire --version
systemctl --user status pipewire wireplumber
# Restart:
systemctl --user restart pipewire wireplumber pipewire-pulse
# Test:
wpctl status
```

### Screen stays black after River starts
```bash
# Check XDG portal
systemctl --user status xdg-desktop-portal
# Check waybar
journalctl --user -u waybar -n 20
# Try launching kitty directly from TTY:
WAYLAND_DISPLAY=wayland-1 kitty
```

### zram not active
```bash
zramctl
# If empty:
sudo modprobe zram
sudo bash ~/forge-os-setup/scripts/performance-tune.sh
```

### systemd user units not loading
```bash
systemctl --user daemon-reload
systemctl --user reset-failed
journalctl --user -xe | tail -30
```

---

*Generated by ForgeOS — [github.com/VibeCodingLabs/forge-os](https://github.com/VibeCodingLabs/forge-os)*
