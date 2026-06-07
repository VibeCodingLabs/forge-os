#!/usr/bin/env bash
set -Eeuo pipefail
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FORGE_HOME="${FORGE_HOME:-$HOME/.forge-os}"
mkdir -p "$FORGE_HOME/logs" "$FORGE_HOME/state"
LOG_FILE="$FORGE_HOME/logs/install-full-command-center-$(date +%Y%m%d-%H%M%S).log"
log(){ printf "%s\n" "$*" | tee -a "$LOG_FILE"; }
run_script(){ log "==> $1"; bash "$ROOT_DIR/scripts/$1" 2>&1 | tee -a "$LOG_FILE"; }

log "ForgeOS full command center install started: $(date --iso-8601=seconds)"

bash "$ROOT_DIR/install.sh" <<'MENU' || true
2

MENU

run_script install-zsh-productivity.sh
run_script install-desktop-command-center.sh
run_script install-performance-tuning.sh
run_script install-security-hardening.sh
run_script install-dictation-accessibility.sh
run_script install-tui-dev.sh
run_script install-python-rich-ui.sh

cat > "$FORGE_HOME/state/full-command-center.env" <<STATE
full_command_center_installed=$(date --iso-8601=seconds)
log=$LOG_FILE
STATE

log "ForgeOS full command center install complete."
log "Recommended next step: reboot, log in again, then launch River from a TTY with: river"
