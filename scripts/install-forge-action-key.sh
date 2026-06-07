#!/usr/bin/env bash
# ForgeOS Action Key installer for Sway.
# Creates a one-key, no-hold command mode plus visual keymap/menu.
# Usage: bash scripts/install-forge-action-key.sh
set -Eeuo pipefail

FORGE_HOME="${FORGE_HOME:-$HOME/.forge-os}"
SWAY_DIR="$HOME/.config/sway"
CONF_DIR="$SWAY_DIR/conf.d"
BIN_DIR="$HOME/.local/bin"
REPORT_DIR="$FORGE_HOME/artifacts/reports"
LOG_DIR="$FORGE_HOME/logs/action-key"
mkdir -p "$CONF_DIR" "$BIN_DIR" "$REPORT_DIR" "$LOG_DIR"
LOG="$LOG_DIR/install-action-key-$(date +%Y%m%d-%H%M%S).log"

C='\033[0;36m'; G='\033[0;32m'; Y='\033[1;33m'; N='\033[0m'
log(){ printf "%b\n" "$*" | tee -a "$LOG"; }

log "${G}Installing Forge Action Key for Sway${N}"
log "log=$LOG"

cat > "$BIN_DIR/forge-action-menu" <<'SCRIPT'
#!/usr/bin/env bash
set -Eeuo pipefail
MENU="${FORGE_MENU:-wofi}"
items='Agents
Observability
Forge Foundry
Forge TUI
Files
Browser
Terminal
Timers
Doctor
Keymap
Reload Sway
Exit Sway'
choice=""
if command -v wofi >/dev/null 2>&1; then
  choice="$(printf '%s\n' "$items" | wofi --dmenu --prompt 'Forge Action')"
elif command -v fuzzel >/dev/null 2>&1; then
  choice="$(printf '%s\n' "$items" | fuzzel --dmenu --prompt 'Forge Action> ')"
elif command -v rofi >/dev/null 2>&1; then
  choice="$(printf '%s\n' "$items" | rofi -dmenu -p 'Forge Action')"
else
  printf '%s\n' "$items"
  exit 0
fi
case "$choice" in
  Agents) forge-open-agents ;;
  Observability) forge-open-observability ;;
  "Forge Foundry") forge-open-foundry ;;
  "Forge TUI") forge-open-tui ;;
  Files) forge-open-files ;;
  Browser) chromium 2>/dev/null || firefox-esr 2>/dev/null || true ;;
  Terminal) wezterm 2>/dev/null || kitty 2>/dev/null || foot 2>/dev/null || true ;;
  Timers) wezterm start -- zsh -lc 'systemctl --user list-timers; exec zsh' 2>/dev/null || foot zsh -lc 'systemctl --user list-timers; exec zsh' ;;
  Doctor) wezterm start -- zsh -lc 'forge-doctor; exec zsh' 2>/dev/null || foot zsh -lc 'forge-doctor; exec zsh' ;;
  Keymap) forge-keymap ;;
  "Reload Sway") swaymsg reload ;;
  "Exit Sway") swaymsg exit ;;
esac
SCRIPT
chmod +x "$BIN_DIR/forge-action-menu"

cat > "$BIN_DIR/forge-open-agents" <<'SCRIPT'
#!/usr/bin/env bash
set -Eeuo pipefail
cd "$HOME/forge-foundry" 2>/dev/null || cd "$HOME"
forge-event desktop.open.agents "opening agent workspace" >/dev/null 2>&1 || true
exec wezterm start --class forge-agents -- tmux new-session -A -s forge-agents 2>/dev/null || exec foot --title agent-workspace tmux new-session -A -s forge-agents
SCRIPT
chmod +x "$BIN_DIR/forge-open-agents"

cat > "$BIN_DIR/forge-open-observability" <<'SCRIPT'
#!/usr/bin/env bash
set -Eeuo pipefail
forge-event desktop.open.observability "opening observability" >/dev/null 2>&1 || true
exec wezterm start --class forge-observe -- zsh -lc 'forge-observe; exec zsh' 2>/dev/null || exec foot --title observability zsh -lc 'forge-observe; exec zsh'
SCRIPT
chmod +x "$BIN_DIR/forge-open-observability"

cat > "$BIN_DIR/forge-open-foundry" <<'SCRIPT'
#!/usr/bin/env bash
set -Eeuo pipefail
cd "$HOME/forge-foundry" 2>/dev/null || cd "$HOME"
exec wezterm start --class forge-foundry --cwd "$PWD" 2>/dev/null || exec foot --title forge-foundry -D "$PWD"
SCRIPT
chmod +x "$BIN_DIR/forge-open-foundry"

cat > "$BIN_DIR/forge-open-tui" <<'SCRIPT'
#!/usr/bin/env bash
set -Eeuo pipefail
exec wezterm start --class forge-tui -- zsh -lc 'forge-tui || echo forge-tui not installed; exec zsh' 2>/dev/null || exec foot --title forge-tui zsh -lc 'forge-tui || echo forge-tui not installed; exec zsh'
SCRIPT
chmod +x "$BIN_DIR/forge-open-tui"

cat > "$BIN_DIR/forge-open-files" <<'SCRIPT'
#!/usr/bin/env bash
set -Eeuo pipefail
cd "$HOME/forge-foundry" 2>/dev/null || cd "$HOME"
if command -v yazi >/dev/null 2>&1; then cmd='yazi'; elif command -v mc >/dev/null 2>&1; then cmd='mc'; elif command -v ranger >/dev/null 2>&1; then cmd='ranger'; else cmd='nnn'; fi
exec wezterm start --class forge-files -- "$cmd" 2>/dev/null || exec foot --title forge-files "$cmd"
SCRIPT
chmod +x "$BIN_DIR/forge-open-files"

cat > "$BIN_DIR/forge-keymap" <<'SCRIPT'
#!/usr/bin/env bash
set -Eeuo pipefail
FORGE_HOME="${FORGE_HOME:-$HOME/.forge-os}"
OUT="$FORGE_HOME/artifacts/reports/keymap.html"
mkdir -p "$(dirname "$OUT")"
cat > "$OUT" <<'HTML'
<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Forge Action Keymap</title>
<style>body{margin:0;background:#080807;color:#f3efe4;font-family:ui-monospace,monospace}main{padding:28px}.grid{display:grid;grid-template-columns:repeat(auto-fit,minmax(260px,1fr));gap:14px}.card{background:linear-gradient(180deg,#181714,#0d0d0c);border:1px solid rgba(255,180,94,.28);border-radius:18px;padding:18px;box-shadow:0 20px 60px #0008}.key{display:inline-block;background:#d08770;color:#111;padding:6px 10px;border-radius:10px;font-weight:900}.muted{color:#b7ad9b}h1{font-size:42px;letter-spacing:-2px}h2{color:#ffb45e;text-transform:uppercase;font-size:14px;letter-spacing:.14em}</style></head><body><main><h1>Forge Action Key</h1><p class="muted">Press <span class="key">F12</span> or <span class="key">Pause</span>, then press the second key. No holding required. Press <span class="key">Esc</span> to cancel.</p><div class="grid">
<div class="card"><h2>Core</h2><p><span class="key">?</span> Help / this screen</p><p><span class="key">M</span> Visual action menu</p><p><span class="key">T</span> Terminal</p><p><span class="key">R</span> Reload Sway</p></div>
<div class="card"><h2>Forge</h2><p><span class="key">A</span> Agent workspace</p><p><span class="key">O</span> Observability</p><p><span class="key">G</span> Forge Foundry</p><p><span class="key">U</span> Forge TUI</p></div>
<div class="card"><h2>Apps</h2><p><span class="key">B</span> Browser</p><p><span class="key">F</span> Files</p><p><span class="key">D</span> App launcher</p><p><span class="key">S</span> Screenshot region</p></div>
<div class="card"><h2>Windows</h2><p><span class="key">H/J/K/L</span> Focus left/down/up/right</p><p><span class="key">Shift+H/J/K/L</span> Move window</p><p><span class="key">1-9</span> Workspace</p><p><span class="key">Q</span> Close focused window</p></div>
<div class="card"><h2>System</h2><p><span class="key">P</span> Timers</p><p><span class="key">X</span> Exit Sway prompt</p><p><span class="key">Esc</span> Cancel action mode</p></div>
</div></main></body></html>
HTML
if command -v xdg-open >/dev/null 2>&1; then xdg-open "$OUT" >/dev/null 2>&1 || true; fi
printf '%s\n' "$OUT"
SCRIPT
chmod +x "$BIN_DIR/forge-keymap"

cat > "$CONF_DIR/forge-action-mode.conf" <<'EOF'
# Forge Action Key Mode for Sway
# Press F12 or Pause once, then press the command key. No modifier holding required.
set $mode_forge_action "FORGE ACTION: A agents | O observe | F files | B browser | ? help | Esc cancel"

bindsym --no-repeat F12 mode $mode_forge_action
bindsym --no-repeat Pause mode $mode_forge_action

mode $mode_forge_action {
  bindsym Escape mode default
  bindsym Return mode default, exec forge-action-menu
  bindsym question mode default, exec forge-keymap
  bindsym slash mode default, exec forge-keymap
  bindsym m mode default, exec forge-action-menu

  bindsym a mode default, exec forge-open-agents
  bindsym o mode default, exec forge-open-observability
  bindsym g mode default, exec forge-open-foundry
  bindsym u mode default, exec forge-open-tui
  bindsym f mode default, exec forge-open-files
  bindsym b mode default, exec chromium 2>/dev/null || firefox-esr
  bindsym d mode default, exec wofi --show drun || fuzzel || rofi -show drun
  bindsym t mode default, exec wezterm || kitty || foot
  bindsym s mode default, exec grim -g "$(slurp)" "$HOME/.forge-os/artifacts/screenshots/sel-$(date +%Y%m%d-%H%M%S).png"

  bindsym h mode default, focus left
  bindsym j mode default, focus down
  bindsym k mode default, focus up
  bindsym l mode default, focus right
  bindsym Shift+h mode default, move left
  bindsym Shift+j mode default, move down
  bindsym Shift+k mode default, move up
  bindsym Shift+l mode default, move right

  bindsym 1 mode default, workspace 1:term
  bindsym 2 mode default, workspace 2:agents
  bindsym 3 mode default, workspace 3:web
  bindsym 4 mode default, workspace 4:code
  bindsym 5 mode default, workspace 5:docs
  bindsym 6 mode default, workspace 6:files
  bindsym 7 mode default, workspace 7:ops
  bindsym 8 mode default, workspace 8:observe
  bindsym 9 mode default, workspace 9:vault

  bindsym p mode default, exec wezterm start -- zsh -lc 'systemctl --user list-timers; exec zsh' || foot zsh -lc 'systemctl --user list-timers; exec zsh'
  bindsym r mode default, reload
  bindsym q mode default, kill
  bindsym x mode default, exec swaynag -t warning -m 'Exit Sway?' -b 'Yes' 'swaymsg exit'
}
EOF

if [[ -f "$SWAY_DIR/config" ]]; then
  if ! grep -q 'include .*/conf.d/.*\.conf' "$SWAY_DIR/config" && ! grep -q 'forge-action-mode.conf' "$SWAY_DIR/config"; then
    printf '\n# ForgeOS includes\ninclude %s/conf.d/*.conf\n' "$SWAY_DIR" >> "$SWAY_DIR/config"
  fi
else
  cat > "$SWAY_DIR/config" <<EOF
set \$mod Mod4
font pango:JetBrains Mono 10
include $SWAY_DIR/conf.d/*.conf
bindsym \$mod+Return exec foot || kitty || wezterm
bindsym \$mod+d exec wofi --show drun || fuzzel || rofi -show drun
bar { swaybar_command waybar }
EOF
fi

if command -v forge-event >/dev/null 2>&1; then
  forge-event action_key.installed "Forge Action Key installed" >/dev/null || true
fi

log "${G}Forge Action Key installed.${N}"
log "Keys: F12 or Pause, then A/O/F/B/?/Esc"
log "Run inside Sway: swaymsg reload"
log "Open keymap: forge-keymap"
