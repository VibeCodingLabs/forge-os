#!/usr/bin/env bash
# =============================================================================
# ForgeOS — install-zsh-productivity
# ZSH + plugins + Starship prompt + shell productivity tools
# Observability: all steps logged, timing recorded, state written
# =============================================================================
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FORGE_HOME="${FORGE_HOME:-$HOME/.forge-os}"
LOG_DIR="$FORGE_HOME/logs"
mkdir -p "$LOG_DIR" "$HOME/.config/zsh" "$HOME/.local/share/zsh/plugins"
LOG_FILE="$LOG_DIR/install-zsh-productivity-$(date +%Y%m%d-%H%M%S).log"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
log()  { printf "%b\n" "$*" | tee -a "$LOG_FILE"; }
ok()   { log "${GREEN}[ OK ]${NC} $*"; }
warn() { log "${YELLOW}[WARN]${NC} $*"; }
err()  { log "${RED}[ERR ]${NC} $*"; }
run()  { log "${CYAN} ▶${NC} $*"; "$@" 2>&1 | tee -a "$LOG_FILE"; }
has()  { command -v "$1" >/dev/null 2>&1; }
clone_or_update() {
  local repo="$1" dest="$2"
  if [[ -d "$dest/.git" ]]; then
    log "  updating $(basename "$dest")"
    git -C "$dest" pull --ff-only 2>&1 | tee -a "$LOG_FILE" || true
  else
    log "  cloning $(basename "$dest")"
    git clone --depth=1 "$repo" "$dest" 2>&1 | tee -a "$LOG_FILE"
  fi
}

log "=== install-zsh-productivity started: $(date --iso-8601=seconds) ==="
log "user=$(id -un) host=$(hostname) forge_home=$FORGE_HOME"
START=$(date +%s)

need_sudo() { if [[ $EUID -ne 0 ]]; then SUDO=sudo; else SUDO=""; fi; }
need_sudo

log "--- system packages ---"
run $SUDO apt-get update -qq
run $SUDO apt-get install -y \
  zsh git curl fzf ripgrep fd-find eza bat zoxide starship direnv \
  fonts-powerline fonts-noto-color-emoji
ok "System packages installed"

log "--- ZSH plugins ---"
PLUGIN_DIR="$HOME/.local/share/zsh/plugins"
mkdir -p "$PLUGIN_DIR"
clone_or_update https://github.com/zsh-users/zsh-autosuggestions     "$PLUGIN_DIR/zsh-autosuggestions"
clone_or_update https://github.com/zsh-users/zsh-syntax-highlighting  "$PLUGIN_DIR/zsh-syntax-highlighting"
clone_or_update https://github.com/zsh-users/zsh-completions          "$PLUGIN_DIR/zsh-completions"
ok "ZSH plugins ready"

log "--- dotfiles ---"
cp "$ROOT_DIR/configs/zsh/zshrc"      "$HOME/.zshrc"
cp "$ROOT_DIR/configs/zsh/forge.zsh"  "$HOME/.config/zsh/forge.zsh"
ok "ZSH dotfiles copied"

if has starship; then
  mkdir -p "$HOME/.config"
  cp "$ROOT_DIR/configs/starship/starship.toml" "$HOME/.config/starship.toml"
  ok "Starship config copied ($(starship --version 2>/dev/null || echo unknown))"
else
  warn "starship not found — config not copied"
fi

log "--- version audit ---"
for tool in zsh git fzf rg bat eza zoxide starship direnv; do
  if has "$tool"; then
    log "  $tool: $("$tool" --version 2>/dev/null | head -1 || echo 'installed')"
  else
    warn "  $tool: NOT FOUND"
  fi
done

END=$(date +%s)
ELAPSED=$((END - START))

log "--- observability state ---"
mkdir -p "$FORGE_HOME/state"
printf 'zsh_productivity_installed=%s\nelapsed_sec=%d\nzsh_version=%s\nstarship_version=%s\n' \
  "$(date --iso-8601=seconds)" "$ELAPSED" \
  "$(zsh --version 2>/dev/null | head -1 || echo unknown)" \
  "$(starship --version 2>/dev/null || echo unknown)" \
  > "$FORGE_HOME/state/zsh-productivity.env"
ok "State written → $FORGE_HOME/state/zsh-productivity.env"

log "=== install-zsh-productivity complete in ${ELAPSED}s ==="
log "Log: $LOG_FILE"
log "Launch ZSH: exec zsh"
log "Make default: chsh -s \$(command -v zsh)"
