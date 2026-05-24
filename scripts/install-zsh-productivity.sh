#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FORGE_HOME="${FORGE_HOME:-$HOME/.forge-os}"
LOG_DIR="$FORGE_HOME/logs"
mkdir -p "$LOG_DIR" "$HOME/.config/zsh" "$HOME/.local/share/zsh/plugins"
LOG_FILE="$LOG_DIR/install-zsh-productivity-$(date +%Y%m%d-%H%M%S).log"

log(){ printf "%b\n" "$*" | tee -a "$LOG_FILE"; }
run(){ log "▶ $*"; "$@" 2>&1 | tee -a "$LOG_FILE"; }
need_sudo(){ if [[ $EUID -ne 0 ]]; then SUDO=sudo; else SUDO=""; fi; }
has(){ command -v "$1" >/dev/null 2>&1; }
clone_or_update(){ local repo="$1" dest="$2"; if [[ -d "$dest/.git" ]]; then git -C "$dest" pull --ff-only || true; else git clone --depth=1 "$repo" "$dest"; fi }

need_sudo
run $SUDO apt-get update
run $SUDO apt-get install -y zsh git curl fzf ripgrep fd-find eza bat zoxide starship direnv fonts-powerline

clone_or_update https://github.com/zsh-users/zsh-autosuggestions "$HOME/.local/share/zsh/plugins/zsh-autosuggestions"
clone_or_update https://github.com/zsh-users/zsh-syntax-highlighting "$HOME/.local/share/zsh/plugins/zsh-syntax-highlighting"
clone_or_update https://github.com/zsh-users/zsh-completions "$HOME/.local/share/zsh/plugins/zsh-completions"

cp "$ROOT_DIR/configs/zsh/zshrc" "$HOME/.zshrc"
cp "$ROOT_DIR/configs/zsh/forge.zsh" "$HOME/.config/zsh/forge.zsh"

if has starship; then
  mkdir -p "$HOME/.config"
  cp "$ROOT_DIR/configs/starship/starship.toml" "$HOME/.config/starship.toml"
fi

log "ZSH productivity shell installed. Launch with: zsh"
log "To make default shell later: chsh -s $(command -v zsh)"
