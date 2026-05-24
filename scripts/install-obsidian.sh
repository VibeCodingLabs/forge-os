#!/usr/bin/env bash
set -Eeuo pipefail

mkdir -p "$HOME/forge-os/vaults/forge-operator"

if command -v flatpak >/dev/null 2>&1; then
  echo "Flatpak detected. You can install Obsidian with your preferred verified Flatpak source."
else
  echo "Flatpak not detected. Install Flatpak first or use the official Obsidian Linux package/AppImage."
fi

echo "Vault path prepared: $HOME/forge-os/vaults/forge-operator"
