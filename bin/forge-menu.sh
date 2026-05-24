#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FORGE_HOME="${FORGE_HOME:-$HOME/.forge-os}"
LOG_DIR="$FORGE_HOME/logs"
mkdir -p "$LOG_DIR" "$HOME/.local/bin"
LOG_FILE="$LOG_DIR/forge-menu-$(date +%Y%m%d-%H%M%S).log"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; MAG='\033[0;35m'; BOLD='\033[1m'; NC='\033[0m'

log(){ printf "%b\n" "$*" | tee -a "$LOG_FILE"; }
run(){ log "${CYAN}▶ $*${NC}"; "$@" 2>&1 | tee -a "$LOG_FILE"; }
need_sudo(){ if [[ $EUID -ne 0 ]]; then SUDO=sudo; else SUDO=""; fi; }
has(){ command -v "$1" >/dev/null 2>&1; }

banner(){
  clear || true
  if has figlet; then figlet -f slant "ForgeOS" || true; else echo "==== ForgeOS ===="; fi
  printf "%b\n" "${MAG}.-.-.-.-=//g\\h//s\\t//n\\0//d\\3//=-.-.-.-.${NC}"
  printf "%b\n" "${BOLD}${CYAN}Ghostnode Command Center Installer${NC}"
  printf "%b\n" "${YELLOW}Log: $LOG_FILE${NC}\n"
}

pause(){ printf "\nPress Enter to continue..."; read -r _; }
apt_update(){ need_sudo; run $SUDO apt-get update; }
install_apt(){ need_sudo; apt_update; run $SUDO apt-get install -y "$@"; }

preflight(){
  banner
  log "${BOLD}ForgeOS Preflight${NC}"
  log "Host: $(hostname)"
  log "User: $(id -un)"
  log "Kernel: $(uname -srmo)"
  log "Debian: $(cat /etc/debian_version 2>/dev/null || echo unknown)"
  log "Shell: $SHELL"
  log "Disk:"
  df -h / "$HOME" 2>/dev/null | tee -a "$LOG_FILE" || true
  log "Memory:"
  free -h | tee -a "$LOG_FILE" || true
  log "Top-level home usage:"
  du -h -d 1 "$HOME" 2>/dev/null | sort -h | tail -20 | tee -a "$LOG_FILE" || true
  log "${GREEN}Preflight complete.${NC}"
  pause
}

setup_dirs(){
  mkdir -p "$FORGE_HOME"/{bin,configs,logs,state,sandboxes,worktrees,observability,themes,telemetry,cache}
  mkdir -p "$HOME/forge-os"/{projects,worktrees,vaults,sandboxes,downloads}
  log "${GREEN}Workspace directories created.${NC}"
}

copy_configs(){
  mkdir -p "$HOME/.config/kitty" "$HOME/.config/alacritty" "$HOME/.config/wezterm"
  cp -n "$ROOT_DIR/configs/kitty/kitty.conf" "$HOME/.config/kitty/kitty.conf" 2>/dev/null || true
  cp -n "$ROOT_DIR/configs/alacritty/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml" 2>/dev/null || true
  cp -n "$ROOT_DIR/configs/wezterm/wezterm.lua" "$HOME/.config/wezterm/wezterm.lua" 2>/dev/null || true
  cp -n "$ROOT_DIR/configs/tmux/tmux.conf" "$HOME/.tmux.conf" 2>/dev/null || true
  log "${GREEN}Terminal configs copied.${NC}"
}

install_scripts(){
  install -m 0755 "$ROOT_DIR/scripts/forge-heartbeat.sh" "$HOME/.local/bin/forge-heartbeat"
  install -m 0755 "$ROOT_DIR/scripts/forge-observer.sh" "$HOME/.local/bin/forge-observer"
  log "${GREEN}Local Forge scripts installed.${NC}"
}

enable_timers(){
  install_scripts
  mkdir -p "$HOME/.config/systemd/user"
  cp "$ROOT_DIR"/systemd/user/*.service "$ROOT_DIR"/systemd/user/*.timer "$HOME/.config/systemd/user/" 2>/dev/null || true
  systemctl --user daemon-reload || true
  systemctl --user enable --now forge-heartbeat.timer forge-observer.timer || true
  log "${GREEN}ForgeOS user timers enabled.${NC}"
}

install_recovery_base(){
  install_apt git curl wget ca-certificates gnupg lsb-release build-essential pkg-config unzip zip jq yq tmux htop btop ripgrep fd-find fzf bat eza tree direnv figlet toilet lolcat gum python3 python3-pip python3-venv pipx nodejs npm cargo rustc clang cmake ninja-build openssh-client openssh-server
  setup_dirs; install_scripts; enable_timers
}

install_terminal_stack(){
  install_apt wezterm kitty alacritty foot tmux zellij ranger mc lf yazi ncdu btop htop glances iotop iftop fzf ripgrep fd-find eza bat zoxide starship wl-clipboard xclip
  copy_configs
}

install_desktop_lab(){
  install_apt i3 sway waybar wofi rofi mako grim slurp swayidle swaylock xwayland xdg-desktop-portal xdg-desktop-portal-wlr dbus-user-session wireplumber pipewire pipewire-pulse network-manager
}

install_dev_runtime(){
  install_apt python3 python3-pip python3-venv pipx nodejs npm cargo rustc golang-go clang cmake ninja-build libssl-dev pkg-config sqlite3 libsqlite3-dev shellcheck shfmt
  has npm && run npm install -g pnpm yarn || true
  has cargo && run cargo install cargo-audit cargo-edit cargo-cache --locked || true
}

install_tauri_stack(){
  install_apt libwebkit2gtk-4.1-dev libayatana-appindicator3-dev librsvg2-dev libsoup-3.0-dev libjavascriptcoregtk-4.1-dev
  has cargo && run cargo install tauri-cli --locked || true
}

install_security_baseline(){
  install_apt ufw fail2ban auditd audispd-plugins apparmor apparmor-utils lynis aide rkhunter chkrootkit clamav clamav-daemon yara openscap-scanner debsecan unattended-upgrades needrestart
}

install_repo_scanners(){
  install_apt git-secrets shellcheck semgrep bandit pip-audit npm-audit-ci gitleaks trufflehog syft grype osv-scanner || true
  has pipx && pipx install detect-secrets || true
  has cargo && cargo install cargo-audit --locked || true
}

install_websec_lab(){
  install_apt nmap wireshark tshark mitmproxy zaproxy ffuf feroxbuster gobuster sqlmap whois dnsutils tcpdump netcat-openbsd httpie || true
}

install_ai_sdk_stack(){
  install_apt python3-venv pipx nodejs npm sqlite3
  has npm && run npm install -g pnpm @modelcontextprotocol/inspector || true
  has pipx && pipx install uv || true
  python3 -m venv "$FORGE_HOME/venvs/ai" 2>/dev/null || true
  "$FORGE_HOME/venvs/ai/bin/pip" install --upgrade pip wheel openai anthropic litellm pydantic pydantic-ai langchain langgraph chromadb fastapi uvicorn httpx rich textual typer || true
}

install_browser_automation(){
  install_apt chromium firefox-esr xvfb mitmproxy python3-venv pipx
  has npm && run npm install -g playwright || true
  has npx && npx playwright install chromium firefox || true
}

install_obsidian_lane(){
  mkdir -p "$HOME/forge-os/vaults/forge-operator"/{00-inbox,01-daily,02-projects,03-agents,04-runbooks,05-prompts,06-evals,07-telemetry,99-archive}
  bash "$ROOT_DIR/scripts/install-obsidian.sh" || true
}

show_manifests(){
  banner
  find "$ROOT_DIR/manifests" -type f -name '*.yaml' -maxdepth 1 2>/dev/null | sort | while read -r f; do
    printf "\n${BOLD}%s${NC}\n" "$(basename "$f")"
    sed -n '1,120p' "$f"
  done
  pause
}

custom_menu(){
  while true; do
    banner
    echo "Custom module installer"
    echo "1) Recovery base"
    echo "2) Terminal/session stack"
    echo "3) Desktop/compositor lab"
    echo "4) Dev runtime"
    echo "5) Tauri 2 desktop stack"
    echo "6) Security baseline"
    echo "7) Repo/secrets/code scanners"
    echo "8) Web security lab tools"
    echo "9) AI SDK stack"
    echo "10) Browser automation"
    echo "11) Obsidian knowledge vault"
    echo "12) Back"
    read -rp "Select module: " choice
    case "$choice" in
      1) install_recovery_base; pause;;
      2) install_terminal_stack; pause;;
      3) install_desktop_lab; pause;;
      4) install_dev_runtime; pause;;
      5) install_tauri_stack; pause;;
      6) install_security_baseline; pause;;
      7) install_repo_scanners; pause;;
      8) install_websec_lab; pause;;
      9) install_ai_sdk_stack; pause;;
      10) install_browser_automation; pause;;
      11) install_obsidian_lane; pause;;
      12) return;;
      *) echo "Invalid choice"; sleep 1;;
    esac
  done
}

install_hp14_lab(){
  install_recovery_base
  install_terminal_stack
  install_desktop_lab
  install_dev_runtime
  install_tauri_stack
  install_browser_automation
  install_obsidian_lane
}

install_ghostnode_workstation(){
  install_hp14_lab
  install_security_baseline
  install_repo_scanners
  install_ai_sdk_stack
}

main_menu(){
  while true; do
    banner
    echo "1) Preflight + disk report"
    echo "2) Minimal Recovery Base"
    echo "3) HP14 Lab Stack"
    echo "4) Ghostnode Secure Workstation"
    echo "5) Custom Modules"
    echo "6) Show manifests"
    echo "7) Copy terminal configs"
    echo "8) Enable observability timers"
    echo "9) Exit"
    read -rp "Choose: " choice
    case "$choice" in
      1) preflight;;
      2) install_recovery_base; pause;;
      3) install_hp14_lab; pause;;
      4) install_ghostnode_workstation; pause;;
      5) custom_menu;;
      6) show_manifests;;
      7) copy_configs; pause;;
      8) enable_timers; pause;;
      9) exit 0;;
      *) echo "Invalid choice"; sleep 1;;
    esac
  done
}

main_menu
