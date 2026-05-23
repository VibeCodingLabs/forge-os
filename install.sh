#!/usr/bin/env bash
set -Eeuo pipefail

FORGE_HOME="${FORGE_HOME:-$HOME/.forge-os}"
LOG_DIR="$FORGE_HOME/logs"
mkdir -p "$LOG_DIR" "$HOME/.local/bin"
LOG_FILE="$LOG_DIR/install-$(date +%Y%m%d-%H%M%S).log"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; MAG='\033[0;35m'; NC='\033[0m'

log(){ printf "%b\n" "$*" | tee -a "$LOG_FILE"; }
run(){ log "${CYAN}▶ $*${NC}"; "$@" 2>&1 | tee -a "$LOG_FILE"; }
need_sudo(){ if [[ $EUID -ne 0 ]]; then SUDO=sudo; else SUDO=""; fi; }

banner(){
  clear || true
  if command -v figlet >/dev/null 2>&1; then figlet -f slant "ForgeOS" || true; else echo "==== ForgeOS ==== "; fi
  printf "%b\n" "${MAG}.-.-.-.-=//g\\h//s\\t//n\\0//d\\3//=-.-.-.-.${NC}"
  printf "%b\n" "${CYAN}Forge/River Command Center Bootstrap${NC}"
  printf "%b\n" "${YELLOW}Logs: $LOG_FILE${NC}\n"
}

apt_update(){ need_sudo; run $SUDO apt-get update; }
install_base(){ need_sudo; run $SUDO apt-get install -y git curl wget ca-certificates gnupg lsb-release build-essential pkg-config unzip zip jq yq tmux htop btop ripgrep fd-find fzf bat eza tree direnv figlet toilet lolcat gum python3 python3-pip python3-venv pipx nodejs npm cargo rustc clang cmake ninja-build libssl-dev libgtk-3-dev libwebkit2gtk-4.1-dev libayatana-appindicator3-dev librsvg2-dev libsoup-3.0-dev libjavascriptcoregtk-4.1-dev bubblewrap firejail podman uidmap slirp4netns fuse-overlayfs kitty alacritty foot wayland-protocols libwayland-dev libxkbcommon-dev libevdev-dev libpixman-1-dev scdoc xwayland dbus-user-session wireplumber pipewire pipewire-pulse network-manager; }
install_bun(){ command -v bun >/dev/null 2>&1 || curl -fsSL https://bun.sh/install | bash; }
install_tauri(){ cargo install tauri-cli --locked || true; }
install_bubbletea_cli(){ command -v go >/dev/null 2>&1 || { need_sudo; run $SUDO apt-get install -y golang; }; go install github.com/charmbracelet/gum@latest || true; }
setup_dirs(){ mkdir -p "$FORGE_HOME"/{bin,configs,logs,state,sandboxes,worktrees,observability,themes}; }
write_configs(){
  mkdir -p "$HOME/.config/kitty" "$HOME/.config/alacritty"
  cp -n configs/kitty/kitty.conf "$HOME/.config/kitty/kitty.conf" 2>/dev/null || true
  cp -n configs/alacritty/alacritty.toml "$HOME/.config/alacritty/alacritty.toml" 2>/dev/null || true
}
install_scripts(){
  install -m 0755 scripts/forge-heartbeat.sh "$HOME/.local/bin/forge-heartbeat"
  install -m 0755 scripts/forge-observer.sh "$HOME/.local/bin/forge-observer"
}
install_systemd_units(){
  install_scripts
  mkdir -p "$HOME/.config/systemd/user"
  cp systemd/user/*.service systemd/user/*.timer "$HOME/.config/systemd/user/" 2>/dev/null || true
  systemctl --user daemon-reload || true
  systemctl --user enable --now forge-heartbeat.timer forge-observer.timer || true
}

menu(){
  banner
  PS3=$'\nChoose ForgeOS action: '
  select opt in "Full bootstrap" "Base packages" "Tauri 2/Rust desktop deps" "Terminal configs" "Sandbox tooling" "Systemd user timers" "Install local scripts" "Show post-wipe commands" "Quit"; do
    case "$REPLY" in
      1) apt_update; install_base; install_bun; install_tauri; install_bubbletea_cli; setup_dirs; write_configs; install_scripts; install_systemd_units; log "${GREEN}Full bootstrap complete.${NC}";;
      2) apt_update; install_base;;
      3) install_bun; install_tauri;;
      4) setup_dirs; write_configs;;
      5) need_sudo; run $SUDO apt-get install -y bubblewrap firejail podman uidmap slirp4netns fuse-overlayfs;;
      6) install_systemd_units;;
      7) install_scripts;;
      8) cat docs/recovery.md;;
      9) exit 0;;
      *) echo "Invalid option";;
    esac
  done
}

menu
