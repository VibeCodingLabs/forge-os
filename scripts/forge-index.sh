#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="${FORGE_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
OUT_DIR="$ROOT_DIR/docs/cheatsheets"
INDEX_FILE="$ROOT_DIR/docs/TOOL_INDEX.md"
mkdir -p "$OUT_DIR"

title(){ printf '%s\n' "$1" | sed 's/.*/# &/'; }
cmd_exists(){ command -v "$1" >/dev/null 2>&1; }

make_tool_sheet(){
  local cmd="$1" out="$OUT_DIR/${cmd}.md"
  {
    echo "# $cmd Cheat Sheet"
    echo
    echo "Generated: $(date -Iseconds)"
    echo
    echo "## Installed?"
    if cmd_exists "$cmd"; then
      echo
      echo '```text'
      command -v "$cmd" || true
      echo '```'
    else
      echo
      echo "Not found on this machine."
    fi
    echo
    echo "## Version"
    echo
    echo '```text'
    "$cmd" --version 2>&1 | head -30 || "$cmd" -V 2>&1 | head -30 || true
    echo '```'
    echo
    echo "## Help"
    echo
    echo '```text'
    "$cmd" --help 2>&1 | head -220 || true
    echo '```'
    echo
    echo "## Notes"
    echo
    echo "Add your daily-use commands here. Keep this short enough to read in Yazi preview."
  } > "$out"
}

TOOLS=(
  yazi tmux zellij git gh ssh rsync curl wget jq yq rg fd fzf bat eza tree
  systemctl journalctl nmcli ip ss tailscale docker podman nmap ffmpeg ollama
  python3 pipx uv node npm pnpm bun cargo go sqlite3 nvim vim nano micro
)

for t in "${TOOLS[@]}"; do
  if cmd_exists "$t"; then make_tool_sheet "$t"; fi
done

{
  echo "# ForgeOS Tool Index"
  echo
  echo "Generated: $(date -Iseconds)"
  echo
  echo "ForgeOS is the Debian-based AI automation workstation bootstrap repo, with installer lanes for terminal UX, Go/Python TUI tooling, file managers, Sway/River/Wayland tooling, runtimes, security hardening, scanners, browser automation, Obsidian vault setup, and observability timers."
  echo
  echo "## Fast Commands"
  echo
  echo '```bash'
  echo './install.sh                    # launch ForgeOS installer menu'
  echo 'bash scripts/forge-index.sh     # rebuild this index and cheat sheets'
  echo 'find scripts -name "*.sh" | sort # list installer/helper scripts'
  echo 'ls docs/cheatsheets             # show generated command cheat sheets'
  echo 'yazi .                          # browse repo with previews'
  echo '```'
  echo
  echo "## Main Installer Menu"
  echo
  echo "The current installer entrypoint is \`install.sh\`, which execs \`bin/forge-menu.sh\`. The menu includes preflight, minimal recovery base, HP14 lab stack, secure workstation, custom modules, manifests, config copy, observability timers, Command Center UX, River desktop, River autostart, River doctor, and Forge TUI launch."
  echo
  echo "## Script Inventory"
  echo
  echo "| Script | Purpose Guess | Run |"
  echo "|---|---|---|"
  find "$ROOT_DIR/scripts" -maxdepth 1 -type f -name '*.sh' | sort | while read -r f; do
    b="$(basename "$f")"
    desc="$(grep -m1 -E '^# [A-Za-z0-9]' "$f" 2>/dev/null | sed 's/^# *//' || true)"
    [[ -z "$desc" ]] && desc="Review with: sed -n '1,120p' scripts/$b"
    echo "| \`scripts/$b\` | $desc | \`bash scripts/$b\` |"
  done
  echo
  echo "## Generated Cheat Sheets"
  echo
  for f in "$OUT_DIR"/*.md; do
    [[ -e "$f" ]] || continue
    b="$(basename "$f")"
    echo "- [${b%.md}](cheatsheets/$b)"
  done | sort
  echo
  echo "## How To See Any App's Commands"
  echo
  echo '```bash'
  echo 'APP=yazi'
  echo '$APP --help'
  echo 'man $APP'
  echo 'tldr $APP'
  echo 'type -a $APP'
  echo 'command -v $APP'
  echo '```'
} > "$INDEX_FILE"

echo "Wrote: $INDEX_FILE"
echo "Wrote cheat sheets under: $OUT_DIR"
