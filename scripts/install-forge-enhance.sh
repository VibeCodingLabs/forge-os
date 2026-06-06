#!/usr/bin/env bash
# =============================================================================
# ForgeOS — install-forge-enhance
# Build forge-enhance binary, install wrapper + .desktop
# Observability: all steps logged to $FORGE_HOME/logs/
# =============================================================================
set -euo pipefail

FORGE_HOME="${FORGE_HOME:-$HOME/.forge-os}"
LOG_DIR="$FORGE_HOME/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/install-forge-enhance-$(date +%Y%m%d-%H%M%S).log"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
log()  { printf "%b\n" "$*" | tee -a "$LOG_FILE"; }
ok()   { log "${GREEN}[ OK ]${NC} $*"; }
warn() { log "${YELLOW}[WARN]${NC} $*"; }
err()  { log "${RED}[ERR ]${NC} $*"; }
run()  { log "${CYAN} ▶${NC} $*"; "$@" 2>&1 | tee -a "$LOG_FILE"; }

log "=== install-forge-enhance started: $(date --iso-8601=seconds) ==="
log "user=$(id -un) host=$(hostname) forge_home=$FORGE_HOME"

BIN_DIR="${HOME}/.local/bin"
DESKTOP_DIR="${HOME}/.local/share/applications"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
mkdir -p "$BIN_DIR" "$DESKTOP_DIR"

log "--- build ---"
STEP_START=$(date +%s)
cd "$REPO_ROOT"
run go build -trimpath -ldflags="-s -w" -o "$BIN_DIR/forge-enhance" ./cmd/forge-enhance/
STEP_END=$(date +%s)
ok "forge-enhance built in $((STEP_END - STEP_START))s → $BIN_DIR/forge-enhance"

log "--- install popup wrapper ---"
run install -m 0755 "$REPO_ROOT/bin/forge-enhance-popup.sh" "$BIN_DIR/forge-enhance-popup"
ok "forge-enhance-popup installed → $BIN_DIR/forge-enhance-popup"

log "--- install .desktop entry ---"
run install -m 0644 "$REPO_ROOT/configs/desktop/forge-enhance.desktop" "$DESKTOP_DIR/forge-enhance.desktop"
if command -v update-desktop-database >/dev/null 2>&1; then
  run update-desktop-database -q "$DESKTOP_DIR" || true
fi
ok ".desktop entry installed"

log "--- capability check ---"
POPUP_OK=""; CLIP_OK=""; KEY_OK=""
for B in zenity yad wofi bemenu rofi dmenu; do
  if command -v "$B" >/dev/null 2>&1; then
    ok "popup helper: $B"; POPUP_OK=1; break
  fi
done
[[ -z "$POPUP_OK" ]] && warn "No popup helper found — install wofi (River) or zenity (GNOME)"

for B in wl-copy xclip xsel; do
  if command -v "$B" >/dev/null 2>&1; then
    ok "clipboard helper: $B"; CLIP_OK=1; break
  fi
done
[[ -z "$CLIP_OK" ]] && warn "No clipboard helper — install wl-clipboard (Wayland) or xclip (X11)"

command -v notify-send >/dev/null 2>&1 && ok "notify-send: found" || warn "notify-send not found — install libnotify-bin"

log "--- provider check ---"
for V in GROQ_API_KEY CEREBRAS_API_KEY GEMINI_API_KEY; do
  if [[ -n "${!V:-}" ]]; then
    ok "API key: $V set"; KEY_OK=1; break
  fi
done
if [[ -z "$KEY_OK" ]]; then
  if command -v ollama >/dev/null 2>&1; then
    warn "No API key — Ollama found, will use as fallback"
  else
    warn "No API key and Ollama not installed"
    warn "Get a free Groq key: https://console.groq.com/keys"
    warn "Add to ~/.env.forge: GROQ_API_KEY=..."
  fi
fi

log "--- observability registration ---"
mkdir -p "$FORGE_HOME/state"
printf 'forge_enhance_installed=%s\nforge_enhance_bin=%s\n' \
  "$(date --iso-8601=seconds)" "$BIN_DIR/forge-enhance" \
  > "$FORGE_HOME/state/forge-enhance.env"
ok "State written to $FORGE_HOME/state/forge-enhance.env"

log "=== install-forge-enhance complete: $(date --iso-8601=seconds) ==="
ok "Log: $LOG_FILE"

echo ""
echo "Next steps:"
echo "  1. Ensure ~/.local/bin is on PATH"
echo "  2. Source ~/.env.forge in your shell rc:"
echo "       set -a; source ~/.env.forge; set +a"
echo "  3. Add River keybinding (already in configs/river/init):"
echo "       riverctl map normal Super E spawn forge-enhance-popup"
echo "  4. Try it: forge-enhance 'build me a CLI that does X'"
