#!/usr/bin/env bash
# ForgeOS Sway command-center installer.
# Usage from repo root: bash s
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FORGE_HOME="${FORGE_HOME:-$HOME/.forge-os}"
LOG_DIR="$FORGE_HOME/logs/sway"
mkdir -p "$LOG_DIR" "$HOME/.local/bin" "$HOME/.config/sway" "$HOME/.config/waybar" "$HOME/.config/mako" "$HOME/.config/wallpapers" "$FORGE_HOME/artifacts/screenshots"
LOG="$LOG_DIR/sway-install-$(date +%Y%m%d-%H%M%S).log"

C='\033[0;36m'; G='\033[0;32m'; Y='\033[1;33m'; R='\033[0;31m'; N='\033[0m'
log(){ printf "%b\n" "$*" | tee -a "$LOG"; }
run(){ log "${C}> $*${N}"; "$@" 2>&1 | tee -a "$LOG"; }
need_sudo(){ if [[ $EUID -ne 0 ]]; then SUDO=sudo; else SUDO=""; fi; }
has_pkg(){ apt-cache show "$1" >/dev/null 2>&1; }
pkg(){ if has_pkg "$1"; then run $SUDO apt-get install -y "$1" || log "${Y}skip failed package: $1${N}"; else log "${Y}skip unavailable package: $1${N}"; fi; }
need_sudo

log "${G}ForgeOS Sway installer started${N}"
log "log=$LOG"
cd "$ROOT"

run $SUDO apt-get update

for p in \
  sway swaybg swayidle swaylock waybar wofi fuzzel rofi dunst mako foot kitty alacritty tmux \
  grim slurp wf-recorder wl-clipboard copyq xwayland xdg-desktop-portal xdg-desktop-portal-wlr \
  dbus-user-session wireplumber pipewire pipewire-pulse kanshi wlr-randr swww feh \
  playerctl brightnessctl pavucontrol network-manager-gnome \
  fonts-firacode fonts-jetbrains-mono fonts-noto-color-emoji papirus-icon-theme; do
  pkg "$p"
done

cat > "$HOME/.config/sway/config" <<'EOF'
# ForgeOS Sway Command Center
set $mod Mod4
set $term foot
set $menu wofi --show drun

set $forge_home $HOME/.forge-os
set $foundry $HOME/forge-foundry

output * bg #11100e solid_color
font pango:JetBrains Mono 10

exec mkdir -p $HOME/.forge-os/logs/sway $HOME/.forge-os/artifacts/screenshots
exec_always systemctl --user start forge-heartbeat.timer forge-observer.timer forge-net-watch.timer forge-fs-watch.timer 2>/dev/null || true
exec waybar >>$HOME/.forge-os/logs/sway/waybar.log 2>&1
exec mako >>$HOME/.forge-os/logs/sway/mako.log 2>&1
exec wl-paste --type text --watch cliphist store >>$HOME/.forge-os/logs/sway/cliphist.log 2>&1

# Basics
floating_modifier $mod
bindsym $mod+Return exec foot
bindsym $mod+Shift+Return exec kitty
bindsym $mod+d exec $menu
bindsym $mod+Shift+q kill
bindsym $mod+Shift+e exec swaynag -t warning -m 'Exit Sway?' -b 'Yes' 'swaymsg exit'

# ForgeOS launchers
bindsym $mod+a exec foot --title agent-workspace -D $HOME/forge-foundry tmux new-session -A -s forge-agents
bindsym $mod+o exec foot --title observability zsh -lc 'forge-observe; exec zsh'
bindsym $mod+g exec foot --title forge-foundry -D $HOME/forge-foundry
bindsym $mod+t exec foot --title forge-tui zsh -lc 'forge-tui || echo forge-tui not installed; exec zsh'
bindsym $mod+w exec zsh -lc 'bash $HOME/forge-os/o && xdg-open $HOME/.forge-os/artifacts/reports/observability.html 2>/dev/null || true'

# Movement
bindsym $mod+h focus left
bindsym $mod+j focus down
bindsym $mod+k focus up
bindsym $mod+l focus right
bindsym $mod+Left focus left
bindsym $mod+Down focus down
bindsym $mod+Up focus up
bindsym $mod+Right focus right

bindsym $mod+Shift+h move left
bindsym $mod+Shift+j move down
bindsym $mod+Shift+k move up
bindsym $mod+Shift+l move right

# Layout
bindsym $mod+b splith
bindsym $mod+v splitv
bindsym $mod+s layout stacking
bindsym $mod+e layout toggle split
bindsym $mod+f fullscreen
bindsym $mod+Shift+space floating toggle
bindsym $mod+space focus mode_toggle

# Workspaces
set $ws1 "1:term"
set $ws2 "2:agents"
set $ws3 "3:web"
set $ws4 "4:code"
set $ws5 "5:docs"
set $ws6 "6:media"
set $ws7 "7:ops"
set $ws8 "8:observe"
set $ws9 "9:vault"

bindsym $mod+1 workspace $ws1
bindsym $mod+2 workspace $ws2
bindsym $mod+3 workspace $ws3
bindsym $mod+4 workspace $ws4
bindsym $mod+5 workspace $ws5
bindsym $mod+6 workspace $ws6
bindsym $mod+7 workspace $ws7
bindsym $mod+8 workspace $ws8
bindsym $mod+9 workspace $ws9

bindsym $mod+Shift+1 move container to workspace $ws1
bindsym $mod+Shift+2 move container to workspace $ws2
bindsym $mod+Shift+3 move container to workspace $ws3
bindsym $mod+Shift+4 move container to workspace $ws4
bindsym $mod+Shift+5 move container to workspace $ws5
bindsym $mod+Shift+6 move container to workspace $ws6
bindsym $mod+Shift+7 move container to workspace $ws7
bindsym $mod+Shift+8 move container to workspace $ws8
bindsym $mod+Shift+9 move container to workspace $ws9

# Screenshots
bindsym $mod+Print exec grim $HOME/.forge-os/artifacts/screenshots/full-$(date +%Y%m%d-%H%M%S).png
bindsym $mod+Shift+s exec grim -g "$(slurp)" $HOME/.forge-os/artifacts/screenshots/sel-$(date +%Y%m%d-%H%M%S).png

# Styling
client.focused          #d08770 #d08770 #11100e #d08770 #d08770
client.unfocused        #3b4252 #3b4252 #d8dee9 #3b4252 #3b4252
client.focused_inactive #4c566a #4c566a #d8dee9 #4c566a #4c566a

bar {
  swaybar_command waybar
}
EOF

cat > "$HOME/.config/waybar/config" <<'EOF'
{
  "layer": "top",
  "position": "top",
  "height": 32,
  "modules-left": ["sway/workspaces", "sway/window"],
  "modules-center": ["clock"],
  "modules-right": ["pulseaudio", "network", "cpu", "memory", "temperature", "battery", "tray", "custom/forge"],
  "clock": {"format": "{:%a %b %d  %I:%M %p}"},
  "cpu": {"format": "CPU {usage}%"},
  "memory": {"format": "RAM {}%"},
  "network": {"format-wifi": "NET {essid} {signalStrength}%", "format-ethernet": "NET wired", "format-disconnected": "NET down"},
  "pulseaudio": {"format": "VOL {volume}%", "format-muted": "MUTE", "on-click": "pavucontrol"},
  "custom/forge": {"format": "FORGE", "on-click": "foot --title observability zsh -lc 'forge-observe; exec zsh'"}
}
EOF

cat > "$HOME/.config/waybar/style.css" <<'EOF'
* { border: none; border-radius: 0; font-family: "JetBrains Mono", monospace; font-size: 12px; min-height: 0; }
window#waybar { background: rgba(17,17,17,0.94); color: #eceff4; border-bottom: 1px solid rgba(216,129,112,0.48); }
#workspaces button, #clock, #pulseaudio, #network, #cpu, #memory, #temperature, #battery, #tray, #custom-forge { padding: 0 10px; margin: 4px 3px; background: rgba(46,52,64,0.86); border-radius: 8px; }
#workspaces button.focused, #custom-forge { color: #111111; background: #d08770; font-weight: 800; }
EOF

cat > "$HOME/.config/mako/config" <<'EOF'
font=JetBrains Mono 10
background-color=#11100eee
text-color=#eceff4ff
border-color=#d08770ff
border-size=1
border-radius=10
default-timeout=6000
EOF

cat > "$HOME/.local/bin/fs" <<'SCRIPT'
#!/usr/bin/env bash
set -Eeuo pipefail
export XDG_CURRENT_DESKTOP=sway
export XDG_SESSION_TYPE=wayland
export MOZ_ENABLE_WAYLAND=1
export ELECTRON_OZONE_PLATFORM_HINT=wayland
mkdir -p "$HOME/.forge-os/logs/sway"
exec sway 2>&1 | tee -a "$HOME/.forge-os/logs/sway/sway-session.log"
SCRIPT
chmod +x "$HOME/.local/bin/fs"

cat > "$HOME/.local/bin/sd" <<'SCRIPT'
#!/usr/bin/env bash
set -Eeuo pipefail
echo "== Sway Doctor =="
for c in sway swaymsg waybar wofi fuzzel mako dunst foot kitty grim slurp wl-copy wl-paste; do
  if command -v "$c" >/dev/null 2>&1; then printf '[OK]   %s -> %s\n' "$c" "$(command -v "$c")"; else printf '[MISS] %s\n' "$c"; fi
done
echo
echo "== Configs =="
ls -lah "$HOME/.config/sway" "$HOME/.config/waybar" "$HOME/.config/mako" 2>/dev/null || true
echo
echo "== Timers =="
systemctl --user list-timers 2>/dev/null || true
echo
echo "== Logs =="
ls -lt "$HOME/.forge-os/logs/sway" 2>/dev/null | head || true
SCRIPT
chmod +x "$HOME/.local/bin/sd"

if command -v forge-event >/dev/null 2>&1; then
  forge-event sway.installer.completed "Sway command center installer completed" >/dev/null || true
fi

cat > "$FORGE_HOME/state/sway-command-center.env" <<STATE
sway_installer_ran=$(date --iso-8601=seconds)
log=$LOG
sway=$(command -v sway || true)
start_command=fs
doctor_command=sd
STATE

log "${G}Done.${N}"
log "Short commands:"
log "  sd   # Sway doctor"
log "  fs   # start Sway from TTY"
log "Next: export PATH=\"$HOME/.local/bin:\$PATH\" && sd"
log "After reboot, from TTY type: fs"
