#!/usr/bin/env bash
# ForgeOS desktop command center installer
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FORGE_HOME="${FORGE_HOME:-$HOME/.forge-os}"
LOG_DIR="$FORGE_HOME/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/install-desktop-command-center-$(date +%Y%m%d-%H%M%S).log"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
log(){ printf "%b\n" "$*" | tee -a "$LOG_FILE"; }
run(){ log "${CYAN}▶ $*${NC}"; "$@" 2>&1 | tee -a "$LOG_FILE"; }
has(){ command -v "$1" >/dev/null 2>&1; }
need_sudo(){ if [[ $EUID -ne 0 ]]; then SUDO=sudo; else SUDO=""; fi; }
need_sudo

log "=== ForgeOS desktop command center install started: $(date --iso-8601=seconds) ==="

run $SUDO apt-get update
run $SUDO apt-get install -y \
  river sway i3-wm waybar eww wofi rofi fuzzel mako dunst \
  foot kitty alacritty wezterm tmux zellij \
  grim slurp swappy wf-recorder wl-clipboard cliphist copyq \
  xwayland xdg-desktop-portal xdg-desktop-portal-wlr \
  dbus-user-session seatd greetd wireplumber pipewire pipewire-pulse \
  swayidle swaylock-effects kanshi wlr-randr swww feh \
  playerctl brightnessctl pavucontrol network-manager-gnome \
  fonts-firacode fonts-jetbrains-mono fonts-noto-color-emoji papirus-icon-theme

mkdir -p \
  "$HOME/.config/river" \
  "$HOME/.config/waybar" \
  "$HOME/.config/eww" \
  "$HOME/.config/mako" \
  "$HOME/.config/wallpapers" \
  "$HOME/.local/bin" \
  "$FORGE_HOME/state"

cp -n "$ROOT_DIR/configs/river/init" "$HOME/.config/river/init" 2>/dev/null || true
chmod +x "$HOME/.config/river/init" 2>/dev/null || true
cp -n "$ROOT_DIR/configs/waybar/config" "$HOME/.config/waybar/config" 2>/dev/null || true
cp -n "$ROOT_DIR/configs/waybar/style.css" "$HOME/.config/waybar/style.css" 2>/dev/null || true
cp -n "$ROOT_DIR/configs/eww/eww.yuck" "$HOME/.config/eww/eww.yuck" 2>/dev/null || true
cp -n "$ROOT_DIR/configs/eww/eww.scss" "$HOME/.config/eww/eww.scss" 2>/dev/null || true
cp -n "$ROOT_DIR/configs/mako/config" "$HOME/.config/mako/config" 2>/dev/null || true
cp -n "$ROOT_DIR/scripts/forge-wallpaper.sh" "$HOME/.local/bin/forge-wallpaper" 2>/dev/null || true
chmod +x "$HOME/.local/bin/forge-wallpaper" 2>/dev/null || true

if getent group seat >/dev/null 2>&1; then
  run $SUDO usermod -aG seat "$(id -un)" || true
fi

cat > "$FORGE_HOME/state/desktop-command-center.env" <<STATE
desktop_command_center_installed=$(date --iso-8601=seconds)
river_config=$HOME/.config/river/init
waybar_config=$HOME/.config/waybar/config
eww_config=$HOME/.config/eww/eww.yuck
log=$LOG_FILE
STATE

log "${GREEN}Desktop command center install complete.${NC}"
log "Log: $LOG_FILE"
log "Next: log out/in if seat group changed, then start River from a TTY with: river"
