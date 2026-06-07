#!/usr/bin/env bash
set -Eeuo pipefail

FORGE_HOME="${FORGE_HOME:-$HOME/.forge-os}"
LOG_DIR="$FORGE_HOME/logs/river"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/river-doctor-$(date +%Y%m%d-%H%M%S).log"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

log(){ printf "%b\n" "$*" | tee -a "$LOG_FILE"; }
ok(){ log "${GREEN}OK${NC}  $*"; }
warn(){ log "${YELLOW}WARN${NC} $*"; }
fail(){ log "${RED}FAIL${NC} $*"; }
has(){ command -v "$1" >/dev/null 2>&1; }

check_cmd(){
  local cmd="$1"
  if has "$cmd"; then ok "command found: $cmd ($(command -v "$cmd"))"; else fail "missing command: $cmd"; return 1; fi
}
check_optional(){
  local cmd="$1"
  if has "$cmd"; then ok "optional command found: $cmd"; else warn "optional command missing: $cmd"; fi
}

failures=0

log "${BOLD}${CYAN}ForgeOS River Doctor${NC}"
log "Log: $LOG_FILE"
log "User: $(id -un)"
log "Kernel: $(uname -srmo)"
if [[ -r /etc/os-release ]]; then
  # shellcheck disable=SC1091
  . /etc/os-release
  log "OS: ${PRETTY_NAME:-unknown} / codename=${VERSION_CODENAME:-unknown}"
  if [[ "${ID:-}" != "debian" ]]; then warn "This profile is tuned for Debian 13 Trixie; detected ID=${ID:-unknown}."; fi
  if [[ "${VERSION_CODENAME:-}" != "trixie" ]]; then warn "Expected VERSION_CODENAME=trixie for the fresh-install target."; fi
else
  warn "/etc/os-release not readable."
fi

for cmd in river riverctl waybar wofi grim slurp wl-copy foot; do
  check_cmd "$cmd" || failures=$((failures + 1))
done

for cmd in rivertile mako cliphist fuzzel swww-daemon kanshi wlopm kitty wezterm alacritty; do
  check_optional "$cmd"
done

if [[ -x "$HOME/.config/river/init" ]]; then
  ok "River init is executable: ~/.config/river/init"
else
  fail "River init missing or not executable: ~/.config/river/init"
  failures=$((failures + 1))
fi

if [[ -d "$HOME/forge-os/downloads" ]]; then ok "screenshot directory exists: ~/forge-os/downloads"; else warn "screenshot directory missing: ~/forge-os/downloads"; fi
if [[ -d "$LOG_DIR" ]]; then ok "River log directory exists: $LOG_DIR"; fi

if systemctl --user show-environment >/dev/null 2>&1; then
  ok "systemd --user is reachable"
else
  warn "systemd --user is not reachable yet. This is normal before first user session/dbus login."
fi

if [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
  ok "Wayland session detected: WAYLAND_DISPLAY=$WAYLAND_DISPLAY"
else
  warn "No active Wayland session detected. Launch River from tty1 with: river"
fi

if [[ $failures -eq 0 ]]; then
  ok "River desktop verification passed."
  exit 0
fi

fail "River desktop verification found $failures required issue(s)."
exit 1
