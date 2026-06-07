#!/usr/bin/env bash
# Short ForgeOS recovery/continue installer.
# Run from repo root with: bash f
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FORGE_HOME="${FORGE_HOME:-$HOME/.forge-os}"
LOG_DIR="$FORGE_HOME/logs"
mkdir -p "$LOG_DIR" "$HOME/.local/bin"
LOG="$LOG_DIR/f-continue-$(date +%Y%m%d-%H%M%S).log"

C='\033[0;36m'; G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; N='\033[0m'
log(){ printf "%b\n" "$*" | tee -a "$LOG"; }
run(){ log "${C}> $*${N}"; "$@" 2>&1 | tee -a "$LOG"; }
need_sudo(){ if [[ $EUID -ne 0 ]]; then SUDO=sudo; else SUDO=""; fi; }
has_pkg(){ apt-cache show "$1" >/dev/null 2>&1; }
pkg(){ if has_pkg "$1"; then run $SUDO apt-get install -y "$1" || log "${Y}skip failed package: $1${N}"; else log "${Y}skip unavailable package: $1${N}"; fi; }
mod(){ local s="$1"; if [[ -f "$ROOT/scripts/$s" ]]; then log "${C}== $s ==${N}"; bash "$ROOT/scripts/$s" || log "${Y}module had warnings/failure: $s${N}"; else log "${Y}missing module: $s${N}"; fi; }
need_sudo

log "${G}ForgeOS short recovery installer started${N}"
log "repo=$ROOT"
log "log=$LOG"

cd "$ROOT"
chmod +x install.sh bin/*.sh scripts/*.sh 2>/dev/null || true

run $SUDO apt-get update

log "${C}Installing safe desktop/runtime packages one-by-one...${N}"
for p in \
  git ca-certificates curl jq yq sqlite3 zsh tmux htop btop glances ripgrep fd-find fzf bat eza tree shellcheck \
  dbus-user-session xwayland xdg-desktop-portal xdg-desktop-portal-wlr wireplumber pipewire pipewire-pulse \
  sway i3-wm waybar wofi rofi fuzzel dunst foot kitty alacritty grim slurp wf-recorder wl-clipboard copyq \
  swayidle swaylock kanshi wlr-randr swww feh playerctl brightnessctl pavucontrol network-manager-gnome \
  fonts-firacode fonts-jetbrains-mono fonts-noto-color-emoji papirus-icon-theme \
  python3 python3-venv python3-pip pipx golang-go cargo rustc build-essential pkg-config cmake ninja-build clang make \
  ufw fail2ban auditd apparmor apparmor-utils clamav clamav-daemon clamav-freshclam lynis rkhunter chkrootkit \
  earlyoom irqbalance thermald sysstat vnstat zram-tools powertop; do
  pkg "$p"
done

log "${C}Copying desktop configs...${N}"
mkdir -p "$HOME/.config/river" "$HOME/.config/waybar" "$HOME/.config/eww" "$HOME/.config/mako" "$HOME/.config/wallpapers" "$FORGE_HOME/state" "$HOME/.local/bin"
cp -n configs/river/init "$HOME/.config/river/init" 2>/dev/null || true
chmod +x "$HOME/.config/river/init" 2>/dev/null || true
cp -n configs/waybar/config "$HOME/.config/waybar/config" 2>/dev/null || true
cp -n configs/waybar/style.css "$HOME/.config/waybar/style.css" 2>/dev/null || true
cp -n configs/eww/eww.yuck "$HOME/.config/eww/eww.yuck" 2>/dev/null || true
cp -n configs/eww/eww.scss "$HOME/.config/eww/eww.scss" 2>/dev/null || true
cp -n configs/mako/config "$HOME/.config/mako/config" 2>/dev/null || true
cp -n scripts/forge-wallpaper.sh "$HOME/.local/bin/forge-wallpaper" 2>/dev/null || true
chmod +x "$HOME/.local/bin/forge-wallpaper" 2>/dev/null || true

log "${C}Continuing ForgeOS modules...${N}"
mod install-observability-center.sh
mod install-performance-tuning.sh
mod install-security-hardening.sh
mod install-dictation-accessibility.sh
mod install-tui-dev.sh
mod install-python-rich-ui.sh

if [[ -f scripts/forge-doctor.sh ]]; then
  install -m 0755 scripts/forge-doctor.sh "$HOME/.local/bin/forge-doctor"
fi

if command -v forge-event >/dev/null 2>&1; then
  forge-event installer.short.completed "short ForgeOS recovery installer completed" >/dev/null || true
fi

log "${G}Done.${N}"
log "Next: export PATH=\"$HOME/.local/bin:\$PATH\""
log "Then: forge-doctor"
log "Then: forge-observe"
log "Then reboot: sudo reboot"
