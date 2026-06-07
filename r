#!/usr/bin/env bash
# ForgeOS River / Wayland command-center installer.
# Usage from repo root: bash r
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FORGE_HOME="${FORGE_HOME:-$HOME/.forge-os}"
SRC_HOME="${SRC_HOME:-$HOME/.local/src}"
LOG_DIR="$FORGE_HOME/logs/river"
mkdir -p "$LOG_DIR" "$HOME/.local/bin" "$SRC_HOME"
LOG="$LOG_DIR/river-install-$(date +%Y%m%d-%H%M%S).log"

C='\033[0;36m'; G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; N='\033[0m'
log(){ printf "%b\n" "$*" | tee -a "$LOG"; }
run(){ log "${C}> $*${N}"; "$@" 2>&1 | tee -a "$LOG"; }
need_sudo(){ if [[ $EUID -ne 0 ]]; then SUDO=sudo; else SUDO=""; fi; }
has(){ command -v "$1" >/dev/null 2>&1; }
has_pkg(){ apt-cache show "$1" >/dev/null 2>&1; }
pkg(){ if has_pkg "$1"; then run $SUDO apt-get install -y "$1" || log "${Y}skip failed package: $1${N}"; else log "${Y}skip unavailable package: $1${N}"; fi; }
need_sudo

log "${G}ForgeOS River installer started${N}"
log "log=$LOG"
cd "$ROOT"

run $SUDO apt-get update

log "${C}Installing Wayland/River build/runtime prerequisites one-by-one...${N}"
for p in \
  git ca-certificates curl wget xz-utils tar unzip build-essential pkg-config cmake meson ninja-build scdoc python3 \
  wayland-protocols libwayland-dev libxkbcommon-dev libpixman-1-dev libudev-dev libseat-dev seatd \
  libinput-dev libdrm-dev libgbm-dev libegl-dev libgles2-mesa-dev libvulkan-dev libdisplay-info-dev libliftoff-dev \
  hwdata xwayland dbus-user-session xdg-desktop-portal xdg-desktop-portal-wlr \
  zig river rivertile sway i3-wm waybar wofi fuzzel rofi mako dunst foot kitty grim slurp wl-clipboard copyq \
  swayidle swaylock kanshi wlr-randr swww feh playerctl brightnessctl pavucontrol \
  fonts-firacode fonts-jetbrains-mono fonts-noto-color-emoji papirus-icon-theme; do
  pkg "$p"
done

if getent group seat >/dev/null 2>&1; then
  run $SUDO usermod -aG seat "$(id -un)" || true
fi

if has river; then
  log "${G}river already installed: $(command -v river)${N}"
else
  log "${Y}river package not installed. Trying source build if zig is available.${N}"
  if has zig; then
    if [[ ! -d "$SRC_HOME/river/.git" ]]; then
      run git clone https://codeberg.org/river/river.git "$SRC_HOME/river" || true
    else
      run git -C "$SRC_HOME/river" pull --ff-only || true
    fi
    if [[ -d "$SRC_HOME/river" ]]; then
      cd "$SRC_HOME/river"
      log "${C}Trying river source build variants...${N}"
      if zig build -Doptimize=ReleaseSafe -Dxwayland --prefix "$HOME/.local" install 2>&1 | tee -a "$LOG"; then
        log "${G}river built with optimize/xwayland flags${N}"
      elif zig build -Doptimize=ReleaseSafe --prefix "$HOME/.local" install 2>&1 | tee -a "$LOG"; then
        log "${G}river built with optimize flag${N}"
      elif zig build -Drelease-safe -Dxwayland --prefix "$HOME/.local" install 2>&1 | tee -a "$LOG"; then
        log "${G}river built with legacy release-safe/xwayland flags${N}"
      elif zig build -Drelease-safe --prefix "$HOME/.local" install 2>&1 | tee -a "$LOG"; then
        log "${G}river built with legacy release-safe flag${N}"
      else
        log "${Y}source build did not complete. Dependencies are installed; check $LOG after docs review.${N}"
      fi
      cd "$ROOT"
    fi
  else
    log "${Y}zig unavailable; install a compatible Zig toolchain later, then rerun: bash r${N}"
  fi
fi

log "${C}Installing ForgeOS River configs and helpers...${N}"
mkdir -p "$HOME/.config/river" "$HOME/.config/waybar" "$HOME/.config/eww" "$HOME/.config/mako" "$HOME/.config/wallpapers" "$FORGE_HOME/state" "$HOME/.local/bin"
cp -n "$ROOT/configs/river/init" "$HOME/.config/river/init" 2>/dev/null || true
chmod +x "$HOME/.config/river/init" 2>/dev/null || true
cp -n "$ROOT/configs/waybar/config" "$HOME/.config/waybar/config" 2>/dev/null || true
cp -n "$ROOT/configs/waybar/style.css" "$HOME/.config/waybar/style.css" 2>/dev/null || true
cp -n "$ROOT/configs/eww/eww.yuck" "$HOME/.config/eww/eww.yuck" 2>/dev/null || true
cp -n "$ROOT/configs/eww/eww.scss" "$HOME/.config/eww/eww.scss" 2>/dev/null || true
cp -n "$ROOT/configs/mako/config" "$HOME/.config/mako/config" 2>/dev/null || true

cat > "$HOME/.local/bin/fr" <<'SCRIPT'
#!/usr/bin/env bash
set -Eeuo pipefail
export PATH="$HOME/.local/bin:$PATH"
export XDG_CURRENT_DESKTOP=river
export XDG_SESSION_TYPE=wayland
export MOZ_ENABLE_WAYLAND=1
export ELECTRON_OZONE_PLATFORM_HINT=wayland
mkdir -p "$HOME/.forge-os/logs/river"
if command -v river >/dev/null 2>&1; then
  exec river 2>&1 | tee -a "$HOME/.forge-os/logs/river/river-session.log"
elif command -v sway >/dev/null 2>&1; then
  echo "river missing; launching sway fallback" | tee -a "$HOME/.forge-os/logs/river/river-session.log"
  exec sway 2>&1 | tee -a "$HOME/.forge-os/logs/river/sway-session.log"
else
  echo "Neither river nor sway is installed. Run: bash ~/forge-os/r"
  exit 1
fi
SCRIPT
chmod +x "$HOME/.local/bin/fr"

cat > "$HOME/.local/bin/rd" <<'SCRIPT'
#!/usr/bin/env bash
set -Eeuo pipefail
echo "== River Doctor =="
for c in river riverctl rivertile sway waybar eww wofi fuzzel mako dunst foot kitty grim slurp wl-copy wl-paste; do
  if command -v "$c" >/dev/null 2>&1; then printf '[OK]   %s -> %s\n' "$c" "$(command -v "$c")"; else printf '[MISS] %s\n' "$c"; fi
done
echo
echo "== Configs =="
ls -lah "$HOME/.config/river" "$HOME/.config/waybar" "$HOME/.config/eww" 2>/dev/null || true
echo
echo "== Seat =="
id
loginctl show-session "${XDG_SESSION_ID:-self}" 2>/dev/null | sed -n '1,40p' || true
echo
echo "== Logs =="
ls -lt "$HOME/.forge-os/logs/river" 2>/dev/null | head || true
SCRIPT
chmod +x "$HOME/.local/bin/rd"

cat > "$FORGE_HOME/state/river-command-center.env" <<STATE
river_installer_ran=$(date --iso-8601=seconds)
log=$LOG
river=$(command -v river || true)
riverctl=$(command -v riverctl || true)
sway=$(command -v sway || true)
start_command=fr
doctor_command=rd
STATE

if command -v forge-event >/dev/null 2>&1; then
  forge-event river.installer.completed "River command center installer completed" >/dev/null || true
fi

log "${G}Done.${N}"
log "Short commands now available:"
log "  rd   # river doctor"
log "  fr   # start river, or sway fallback"
log "From a TTY after reboot, type: fr"
log "If group membership changed, reboot or log out/in first."
