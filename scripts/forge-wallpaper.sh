#!/usr/bin/env bash
set -Eeuo pipefail
WALL_DIR="${FORGE_WALLPAPER_DIR:-$HOME/.config/wallpapers}"
mkdir -p "$WALL_DIR"
TARGET="${FORGE_WALLPAPER_FILE:-}"
if [[ -z "$TARGET" ]]; then
  TARGET="$(find "$WALL_DIR" -maxdepth 1 -type f -name '*.png' | sort | head -1 || true)"
fi
if [[ -z "$TARGET" ]]; then
  echo "Add a PNG wallpaper to $WALL_DIR or set FORGE_WALLPAPER_FILE."
  exit 0
fi
if command -v swww >/dev/null 2>&1; then
  swww img "$TARGET" --transition-type fade --transition-duration 1 || true
elif command -v swaybg >/dev/null 2>&1; then
  swaybg -i "$TARGET" -m fill &
else
  echo "Wallpaper target: $TARGET"
fi
