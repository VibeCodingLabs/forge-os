#!/usr/bin/env bash
# =============================================================================
# ForgeOS — install-tui-dev
# Build Bubble Tea / Lip Gloss Go TUI stack + forge-tui binary
# Observability: all steps logged, timing recorded, state written
# =============================================================================
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FORGE_HOME="${FORGE_HOME:-$HOME/.forge-os}"
LOG_DIR="$FORGE_HOME/logs"
mkdir -p "$LOG_DIR" "$HOME/.local/bin"
LOG_FILE="$LOG_DIR/install-tui-dev-$(date +%Y%m%d-%H%M%S).log"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
log()  { printf "%b\n" "$*" | tee -a "$LOG_FILE"; }
ok()   { log "${GREEN}[ OK ]${NC} $*"; }
warn() { log "${YELLOW}[WARN]${NC} $*"; }
err()  { log "${RED}[ERR ]${NC} $*"; }
run()  { log "${CYAN} ▶${NC} $*"; "$@" 2>&1 | tee -a "$LOG_FILE"; }
has()  { command -v "$1" >/dev/null 2>&1; }

log "=== install-tui-dev started: $(date --iso-8601=seconds) ==="
log "user=$(id -un) host=$(hostname) forge_home=$FORGE_HOME"
START=$(date +%s)

need_sudo() { if [[ $EUID -ne 0 ]]; then SUDO=sudo; else SUDO=""; fi; }
need_sudo

log "--- system packages ---"
run $SUDO apt-get update -qq
run $SUDO apt-get install -y golang-go git build-essential ca-certificates curl
ok "Go toolchain: $(go version 2>/dev/null || echo 'unknown')"

log "--- Go TUI dependencies ---"
cd "$ROOT_DIR"
run go mod tidy
run go get github.com/charmbracelet/bubbletea@latest
run go get github.com/charmbracelet/lipgloss@latest
run go get github.com/charmbracelet/bubbles@latest
run go mod tidy
ok "Go TUI deps resolved"

log "--- build forge-tui ---"
BUILD_START=$(date +%s)
run go build -trimpath -ldflags="-s -w" -o "$HOME/.local/bin/forge-tui" ./cmd/forge-tui/
BUILD_END=$(date +%s)
BINARY_SIZE=$(du -sh "$HOME/.local/bin/forge-tui" 2>/dev/null | cut -f1 || echo 'unknown')
ok "forge-tui built in $((BUILD_END - BUILD_START))s → $HOME/.local/bin/forge-tui ($BINARY_SIZE)"

log "--- version audit ---"
for tool in go git; do
  has "$tool" && log "  $tool: $("$tool" version 2>/dev/null | head -1)" || warn "  $tool: NOT FOUND"
done
has "$HOME/.local/bin/forge-tui" && ok "forge-tui binary: present" || warn "forge-tui binary: MISSING"

END=$(date +%s)
ELAPSED=$((END - START))

log "--- observability state ---"
mkdir -p "$FORGE_HOME/state"
printf 'tui_dev_installed=%s\nelapsed_sec=%d\ngo_version=%s\nbinary_size=%s\nbinary_path=%s\n' \
  "$(date --iso-8601=seconds)" "$ELAPSED" \
  "$(go version 2>/dev/null | head -1 || echo unknown)" \
  "$BINARY_SIZE" "$HOME/.local/bin/forge-tui" \
  > "$FORGE_HOME/state/tui-dev.env"
ok "State written → $FORGE_HOME/state/tui-dev.env"

log "=== install-tui-dev complete in ${ELAPSED}s ==="
log "Log: $LOG_FILE"
log "Run: forge-tui"
