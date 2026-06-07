#!/usr/bin/env bash
# ForgeOS performance tuning installer
set -Eeuo pipefail
FORGE_HOME="${FORGE_HOME:-$HOME/.forge-os}"
LOG_DIR="$FORGE_HOME/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/install-performance-tuning-$(date +%Y%m%d-%H%M%S).log"
CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
log(){ printf "%b\n" "$*" | tee -a "$LOG_FILE"; }
run(){ log "${CYAN}▶ $*${NC}"; "$@" 2>&1 | tee -a "$LOG_FILE"; }
need_sudo(){ if [[ $EUID -ne 0 ]]; then SUDO=sudo; else SUDO=""; fi; }
need_sudo

log "=== ForgeOS performance tuning started: $(date --iso-8601=seconds) ==="
run $SUDO apt-get update
run $SUDO apt-get install -y zram-tools tuned powertop thermald preload earlyoom irqbalance util-linux sysstat iotop iftop btop htop ncdu duf stress-ng hyperfine

# Conservative workstation defaults. These avoid risky kernel tweaks and focus on stability.
run $SUDO systemctl enable --now irqbalance || true
run $SUDO systemctl enable --now thermald || true
run $SUDO systemctl enable --now earlyoom || true
run $SUDO systemctl enable --now sysstat || true
run $SUDO systemctl enable --now fstrim.timer || true

if command -v tuned-adm >/dev/null 2>&1; then
  run $SUDO systemctl enable --now tuned || true
  run $SUDO tuned-adm profile balanced || true
fi

# zram-tools default config is distro-owned; write a ForgeOS note instead of overwriting blindly.
mkdir -p "$FORGE_HOME/state"
cat > "$FORGE_HOME/state/performance-tuning.env" <<STATE
performance_tuning_installed=$(date --iso-8601=seconds)
services=irqbalance,thermald,earlyoom,sysstat,fstrim.timer,tuned
profile=balanced
log=$LOG_FILE
STATE

log "${GREEN}Performance tuning complete.${NC}"
log "${YELLOW}Reboot recommended after full desktop/security install.${NC}"
