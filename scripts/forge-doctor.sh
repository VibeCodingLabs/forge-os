#!/usr/bin/env bash
set -Eeuo pipefail

FORGE_HOME="${FORGE_HOME:-$HOME/.forge-os}"
REPORT_DIR="$FORGE_HOME/reports"
mkdir -p "$REPORT_DIR"
REPORT="$REPORT_DIR/doctor-$(date +%Y%m%d-%H%M%S).txt"

ok(){ printf '[ OK ] %s\n' "$*"; }
warn(){ printf '[WARN] %s\n' "$*"; }
miss(){ printf '[MISS] %s\n' "$*"; }
check_cmd(){ if command -v "$1" >/dev/null 2>&1; then ok "$1: $(command -v "$1")"; else miss "$1 not found"; fi; }
check_file(){ if [[ -e "$1" ]]; then ok "$1 present"; else miss "$1 missing"; fi; }
check_service(){ if systemctl is-enabled "$1" >/dev/null 2>&1; then ok "$1 enabled"; else warn "$1 not enabled"; fi; }
check_user_timer(){ if systemctl --user is-enabled "$1" >/dev/null 2>&1; then ok "user $1 enabled"; else warn "user $1 not enabled"; fi; }

{
  echo "ForgeOS Doctor Report"
  echo "Generated: $(date --iso-8601=seconds)"
  echo "Host: $(hostname)"
  echo "User: $(id -un)"
  echo "Kernel: $(uname -srmo)"
  echo "Debian: $(cat /etc/debian_version 2>/dev/null || echo unknown)"
  echo
  echo "== Disk =="
  df -h / "$HOME" 2>/dev/null || true
  echo
  echo "== Memory =="
  free -h || true
  echo
  echo "== Core commands =="
  for c in git curl wget jq yq rg fd fzf bat eza zsh tmux kitty foot river waybar eww wofi fuzzel mako wl-copy cliphist swww grim slurp python3 node npm go cargo rustc sqlite3; do
    check_cmd "$c"
  done
  echo
  echo "== Security commands =="
  for c in ufw fail2ban-client auditctl aa-status clamscan freshclam lynis rkhunter chkrootkit; do
    check_cmd "$c"
  done
  echo
  echo "== Config files =="
  check_file "$HOME/.config/river/init"
  check_file "$HOME/.config/waybar/config"
  check_file "$HOME/.config/waybar/style.css"
  check_file "$HOME/.config/eww/eww.yuck"
  check_file "$HOME/.zshrc"
  check_file "$HOME/.tmux.conf"
  echo
  echo "== System services =="
  check_service ufw.service
  check_service fail2ban.service
  check_service auditd.service
  check_service apparmor.service
  check_service clamav-freshclam.service
  check_service clamav-daemon.service
  check_service fstrim.timer
  check_service irqbalance.service
  check_service thermald.service
  check_service earlyoom.service
  echo
  echo "== ForgeOS user timers =="
  check_user_timer forge-heartbeat.timer
  check_user_timer forge-observer.timer
  echo
  echo "== Firewall =="
  sudo ufw status verbose 2>/dev/null || true
} | tee "$REPORT"

echo
echo "Doctor report saved: $REPORT"
