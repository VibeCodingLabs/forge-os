#!/usr/bin/env bash
# =============================================================================
# ForgeOS — install-obsidian
# Vault structure setup + Obsidian AppImage/Flatpak install guidance
# Observability: all steps logged, state written
# =============================================================================
set -Eeuo pipefail

FORGE_HOME="${FORGE_HOME:-$HOME/.forge-os}"
LOG_DIR="$FORGE_HOME/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/install-obsidian-$(date +%Y%m%d-%H%M%S).log"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
log()  { printf "%b\n" "$*" | tee -a "$LOG_FILE"; }
ok()   { log "${GREEN}[ OK ]${NC} $*"; }
warn() { log "${YELLOW}[WARN]${NC} $*"; }
run()  { log "${CYAN} ▶${NC} $*"; "$@" 2>&1 | tee -a "$LOG_FILE"; }
has()  { command -v "$1" >/dev/null 2>&1; }

log "=== install-obsidian started: $(date --iso-8601=seconds) ==="
log "user=$(id -un) host=$(hostname) forge_home=$FORGE_HOME"
START=$(date +%s)

VAULT_ROOT="$HOME/forge-os/vaults/forge-operator"
VAULT_DIRS=(
  00-inbox
  01-daily
  02-projects
  03-agents
  04-runbooks
  05-prompts
  06-evals
  07-telemetry
  08-performance
  09-configs
  99-archive
)

log "--- vault structure ---"
for d in "${VAULT_DIRS[@]}"; do
  mkdir -p "$VAULT_ROOT/$d"
  ok "vault dir: $VAULT_ROOT/$d"
done

# Obsidian .obsidian config dir placeholder
mkdir -p "$VAULT_ROOT/.obsidian"

# Copy obsidian configs if available
if [[ -d "$HOME/forge-os-setup/configs/obsidian" ]]; then
  cp -rn "$HOME/forge-os-setup/configs/obsidian/." "$VAULT_ROOT/.obsidian/" 2>/dev/null || true
  ok "Obsidian config copied from repo"
fi

log "--- Obsidian install ---"
if has flatpak; then
  ok "flatpak detected"
  warn "Run manually (use your preferred verified Flatpak source):"
  warn "  flatpak install flathub md.obsidian.Obsidian"
  warn "  flatpak run md.obsidian.Obsidian"
elif [[ -f "$HOME/forge-os/downloads/obsidian.AppImage" ]]; then
  chmod +x "$HOME/forge-os/downloads/obsidian.AppImage"
  ln -sf "$HOME/forge-os/downloads/obsidian.AppImage" "$HOME/.local/bin/obsidian" || true
  ok "Obsidian AppImage linked → ~/.local/bin/obsidian"
else
  warn "Obsidian not found. Options:"
  warn "  1. Install Flatpak: sudo apt-get install -y flatpak"
  warn "  2. Download AppImage from: https://obsidian.md/download"
  warn "     Place at: $HOME/forge-os/downloads/obsidian.AppImage"
  warn "     Then re-run this script."
fi

END=$(date +%s)
ELAPSED=$((END - START))

log "--- observability state ---"
mkdir -p "$FORGE_HOME/state"
VAULT_SIZE=$(du -sh "$VAULT_ROOT" 2>/dev/null | cut -f1 || echo 'empty')
printf 'obsidian_setup=%s\nelapsed_sec=%d\nvault_root=%s\nvault_size=%s\nflatpak_available=%s\n' \
  "$(date --iso-8601=seconds)" "$ELAPSED" \
  "$VAULT_ROOT" "$VAULT_SIZE" \
  "$(has flatpak && echo yes || echo no)" \
  > "$FORGE_HOME/state/obsidian.env"
ok "State written → $FORGE_HOME/state/obsidian.env"

log "=== install-obsidian complete in ${ELAPSED}s ==="
log "Log: $LOG_FILE"
log "Vault root: $VAULT_ROOT"
