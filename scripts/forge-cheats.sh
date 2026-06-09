#!/usr/bin/env bash
set -Eeuo pipefail

# ForgeOS Cheats launcher
# Opens the generated docs/cheatsheets files from a terminal, Wofi/Rofi menu, or direct command.

ROOT_DIR="${FORGE_ROOT:-}"
if [[ -z "$ROOT_DIR" ]]; then
  if [[ -d "$HOME/forge-os/.git" ]]; then
    ROOT_DIR="$HOME/forge-os"
  else
    ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  fi
fi

CHEAT_DIR="$ROOT_DIR/docs/cheatsheets"
INDEX_FILE="$ROOT_DIR/docs/TOOL_INDEX.md"
GENERATOR="$ROOT_DIR/scripts/forge-index.sh"

has(){ command -v "$1" >/dev/null 2>&1; }

ensure_index(){
  if [[ ! -d "$CHEAT_DIR" || ! -f "$INDEX_FILE" ]]; then
    if [[ -x "$GENERATOR" ]]; then
      bash "$GENERATOR"
    elif [[ -f "$GENERATOR" ]]; then
      bash "$GENERATOR"
    else
      echo "Missing generator: $GENERATOR" >&2
      exit 1
    fi
  fi
}

terminal(){
  local cmd="$1"
  if has kitty; then kitty --title "ForgeOS Cheats" bash -lc "$cmd" &
  elif has foot; then foot -T "ForgeOS Cheats" bash -lc "$cmd" &
  elif has alacritty; then alacritty --title "ForgeOS Cheats" -e bash -lc "$cmd" &
  elif has wezterm; then wezterm start -- bash -lc "$cmd" &
  elif has xterm; then xterm -T "ForgeOS Cheats" -e bash -lc "$cmd" &
  else bash -lc "$cmd"
  fi
}

view_file(){
  local file="$1"
  [[ -f "$file" ]] || { echo "Missing file: $file" >&2; exit 1; }
  local escaped
  escaped="$(printf '%q' "$file")"
  terminal "printf '\\033[1;38;5;208mForgeOS Cheats: %s\\033[0m\\n\\n' '$file'; less -R $escaped"
}

open_tool(){
  ensure_index
  local name="${1:-}"
  [[ -n "$name" ]] || { echo "Usage: forge-cheats open <tool>" >&2; exit 2; }
  if [[ "$name" == "index" || "$name" == "TOOL_INDEX" ]]; then
    view_file "$INDEX_FILE"
    exit 0
  fi
  view_file "$CHEAT_DIR/${name%.md}.md"
}

menu(){
  ensure_index
  local selected=""
  local choices
  choices="$({ echo "TOOL_INDEX"; find "$CHEAT_DIR" -maxdepth 1 -type f -name '*.md' -printf '%f\n' 2>/dev/null | sed 's/\.md$//' | sort; } )"

  if has wofi; then
    selected="$(printf '%s\n' "$choices" | wofi --dmenu --prompt 'ForgeOS Cheats' || true)"
  elif has rofi; then
    selected="$(printf '%s\n' "$choices" | rofi -dmenu -p 'ForgeOS Cheats' || true)"
  elif has fuzzel; then
    selected="$(printf '%s\n' "$choices" | fuzzel --dmenu --prompt 'ForgeOS Cheats: ' || true)"
  elif has fzf; then
    selected="$(printf '%s\n' "$choices" | fzf --prompt='ForgeOS Cheats> ' || true)"
  else
    echo "$choices"
    echo
    read -rp "Open cheat: " selected
  fi

  [[ -n "$selected" ]] || exit 0
  open_tool "$selected"
}

scripts_inventory(){
  ensure_index
  terminal "cd $(printf '%q' "$ROOT_DIR") && find scripts -maxdepth 1 -type f -name '*.sh' | sort | sed 's#^#- #' | less -R"
}

case "${1:-menu}" in
  menu|dropdown|choose) menu ;;
  index) ensure_index; view_file "$INDEX_FILE" ;;
  rebuild|generate) bash "$GENERATOR" ;;
  scripts) scripts_inventory ;;
  open) shift; open_tool "${1:-}" ;;
  *) open_tool "$1" ;;
esac
