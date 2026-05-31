#!/usr/bin/env bash
# forge-enhance-popup — hotkey / dock wrapper.
#
# Pops a text-entry dialog (zenity / wofi / bemenu / rofi), pipes the
# typed text through `forge-enhance`, copies the result to the clipboard,
# and shows a desktop notification.
#
# Bind to a global hotkey:
#   GNOME (Pop!_OS):  Settings → Keyboard → Custom Shortcuts → add
#                     name:    forge-enhance
#                     command: /home/$USER/.local/bin/forge-enhance-popup
#                     binding: <Super>E
#   River:            in ~/.config/river/init add:
#                     riverctl map normal Super E spawn forge-enhance-popup
#   Sway/Hyprland:    bind = SUPER, E, exec, forge-enhance-popup
#
# Or pin as a dock applet: see configs/desktop/forge-enhance.desktop
set -euo pipefail

# Source ~/.env.forge if present so API keys are visible without needing
# the whole shell environment imported into the hotkey context.
if [ -f "$HOME/.env.forge" ]; then
  set -a
  # shellcheck disable=SC1091
  . "$HOME/.env.forge"
  set +a
fi

# forge-enhance handles the popup + copy + notify internally when given
# all three flags. We delegate to it so this wrapper stays trivial.
exec forge-enhance --popup --copy --notify "$@"
