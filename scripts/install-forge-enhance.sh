#!/usr/bin/env bash
# install-forge-enhance — build the binary, install the wrapper + .desktop,
# print hotkey-binding instructions for the operator's compositor.
#
# Idempotent. Re-runnable after every wipe.
#
# Usage:
#   bash scripts/install-forge-enhance.sh
#
# Requires (apt installs handled by ForgeOS install.sh):
#   go (>= 1.22)         — builds the binary
#   libnotify-bin        — notify-send (notifications)
#   wl-clipboard         — wl-copy (Wayland clipboard)   OR  xclip
#   one of: zenity, yad, wofi, bemenu, rofi, dmenu       — popup helper

set -euo pipefail

BIN_DIR="${HOME}/.local/bin"
DESKTOP_DIR="${HOME}/.local/share/applications"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

mkdir -p "$BIN_DIR" "$DESKTOP_DIR"

echo "==> Building forge-enhance"
cd "$REPO_ROOT"
go build -trimpath -ldflags="-s -w" -o "$BIN_DIR/forge-enhance" ./cmd/forge-enhance/

echo "==> Installing forge-enhance-popup wrapper"
install -m 0755 "$REPO_ROOT/bin/forge-enhance-popup.sh" "$BIN_DIR/forge-enhance-popup"

echo "==> Installing .desktop entry (dock applet)"
install -m 0644 "$REPO_ROOT/configs/desktop/forge-enhance.desktop" "$DESKTOP_DIR/forge-enhance.desktop"

# Refresh GNOME's app menu so the new entry shows up immediately.
if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database -q "$DESKTOP_DIR" || true
fi

echo ""
echo "==> Capability check"
for B in zenity yad wofi bemenu rofi dmenu; do
  if command -v "$B" >/dev/null 2>&1; then
    echo "  popup helper found: $B"
    POPUP_OK=1
    break
  fi
done
[ -z "${POPUP_OK:-}" ] && echo "  WARNING: no popup helper found — install zenity (GNOME) or wofi (River/Sway)"

for B in wl-copy xclip xsel; do
  if command -v "$B" >/dev/null 2>&1; then
    echo "  clipboard helper found: $B"
    CLIP_OK=1
    break
  fi
done
[ -z "${CLIP_OK:-}" ] && echo "  WARNING: no clipboard helper — install wl-clipboard (Wayland) or xclip (X11)"

if command -v notify-send >/dev/null 2>&1; then
  echo "  notify-send found"
else
  echo "  WARNING: notify-send not found — install libnotify-bin"
fi

echo ""
echo "==> Provider check"
for V in GROQ_API_KEY CEREBRAS_API_KEY GEMINI_API_KEY; do
  if [ -n "${!V:-}" ]; then
    echo "  $V set (will use this)"
    KEY_OK=1
    break
  fi
done
if [ -z "${KEY_OK:-}" ]; then
  if command -v ollama >/dev/null 2>&1; then
    echo "  no API key set, but Ollama is installed — will use it as fallback"
  else
    echo "  WARNING: no API key set and Ollama not installed"
    echo "           sign up for a free Groq key: https://console.groq.com/keys"
    echo "           then add to ~/.env.forge:  GROQ_API_KEY=..."
  fi
fi

echo ""
echo "==> Done. Next steps:"
echo "  1. Make sure ~/.local/bin is on PATH"
echo "  2. Source ~/.env.forge in your shell rc (or pass keys to the hotkey context):"
echo "       set -a; source ~/.env.forge; set +a"
echo "  3. Bind the global hotkey for your compositor:"
echo ""
echo "       GNOME (Pop!_OS / Debian+GNOME):"
echo "         Settings → Keyboard → Custom Shortcuts → +"
echo "           name:    forge-enhance"
echo "           command: $BIN_DIR/forge-enhance-popup"
echo "           binding: <Super>E"
echo ""
echo "       River:"
echo "         echo 'riverctl map normal Super E spawn forge-enhance-popup' >> ~/.config/river/init"
echo ""
echo "       Sway / Hyprland:"
echo "         add to config:  bindsym Mod4+e exec forge-enhance-popup"
echo ""
echo "  4. The dock applet is available as 'Forge Enhance' in the app launcher"
echo "     — right-click → Pin to favorites to keep it on the dock."
echo ""
echo "  Try it:"
echo "       forge-enhance 'build me a CLI that does X'"
