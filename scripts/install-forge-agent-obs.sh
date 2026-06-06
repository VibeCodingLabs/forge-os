#!/usr/bin/env bash
# =============================================================================
# ForgeOS — install-forge-agent-obs
# Build and install the forge-agent-obs TUI binary
# Observability: all steps logged, state written
# =============================================================================
set -Eeuo pipefail

FORGE_HOME="${FORGE_HOME:-$HOME/.forge-os}"
LOG_DIR="$FORGE_HOME/logs"
mkdir -p "$LOG_DIR" "$HOME/.local/bin"
LOG_FILE="$LOG_DIR/install-forge-agent-obs-$(date +%Y%m%d-%H%M%S).log"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
log()  { printf "%b\n" "$*" | tee -a "$LOG_FILE"; }
ok()   { log "${GREEN}[ OK ]${NC} $*"; }
warn() { log "${YELLOW}[WARN]${NC} $*"; }
run()  { log "${CYAN} ▶${NC} $*"; "$@" 2>&1 | tee -a "$LOG_FILE"; }

log "=== install-forge-agent-obs started: $(date --iso-8601=seconds) ==="
log "user=$(id -un) host=$(hostname)"
START=$(date +%s)

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Ensure agent-calls.jsonl exists (empty ok)
mkdir -p "$FORGE_HOME/logs"
touch "$FORGE_HOME/logs/agent-calls.jsonl"
ok "agent-calls.jsonl ensured: $FORGE_HOME/logs/agent-calls.jsonl"

# Go check
if ! command -v go >/dev/null 2>&1; then
  warn "go not found — installing via apt"
  need_sudo() { if [[ $EUID -ne 0 ]]; then SUDO=sudo; else SUDO=""; fi; }
  need_sudo
  run $SUDO apt-get install -y golang-go
fi
ok "Go: $(go version 2>/dev/null | head -1)"

# Rebuild forge-enhance with call logging
log "--- build forge-enhance (with call log) ---"
BUILD_START=$(date +%s)
cd "$REPO_ROOT"
run go mod tidy
run go build -trimpath -ldflags="-s -w" -o "$HOME/.local/bin/forge-enhance" ./cmd/forge-enhance/
ok "forge-enhance rebuilt in $(( $(date +%s) - BUILD_START ))s"

# Build forge-agent-obs
log "--- build forge-agent-obs ---"
OBS_START=$(date +%s)
run go build -trimpath -ldflags="-s -w" -o "$HOME/.local/bin/forge-agent-obs" ./cmd/forge-agent-obs/
OBS_END=$(date +%s)
SIZE=$(du -sh "$HOME/.local/bin/forge-agent-obs" 2>/dev/null | cut -f1 || echo '?')
ok "forge-agent-obs built in $((OBS_END - OBS_START))s → $HOME/.local/bin/forge-agent-obs ($SIZE)"

END=$(date +%s)
ELAPSED=$((END - START))

# State
mkdir -p "$FORGE_HOME/state"
printf 'agent_obs_installed=%s\nelapsed_sec=%d\nbinary=%s\nlog_path=%s\n' \
  "$(date --iso-8601=seconds)" "$ELAPSED" \
  "$HOME/.local/bin/forge-agent-obs" \
  "$FORGE_HOME/logs/agent-calls.jsonl" \
  > "$FORGE_HOME/state/agent-obs.env"
ok "State written → $FORGE_HOME/state/agent-obs.env"

log "=== install-forge-agent-obs complete in ${ELAPSED}s ==="
log "Launch: forge-agent-obs"
log "Add River keybinding: riverctl map normal Super O spawn forge-agent-obs"
