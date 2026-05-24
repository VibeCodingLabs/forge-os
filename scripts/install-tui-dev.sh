#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FORGE_HOME="${FORGE_HOME:-$HOME/.forge-os}"
LOG_DIR="$FORGE_HOME/logs"
mkdir -p "$LOG_DIR" "$HOME/.local/bin"
LOG_FILE="$LOG_DIR/install-tui-dev-$(date +%Y%m%d-%H%M%S).log"

log(){ printf "%b\n" "$*" | tee -a "$LOG_FILE"; }
run(){ log "▶ $*"; "$@" 2>&1 | tee -a "$LOG_FILE"; }
need_sudo(){ if [[ $EUID -ne 0 ]]; then SUDO=sudo; else SUDO=""; fi; }
has(){ command -v "$1" >/dev/null 2>&1; }

need_sudo
run $SUDO apt-get update
run $SUDO apt-get install -y golang-go git build-essential ca-certificates curl

cd "$ROOT_DIR"
run go mod tidy
run go get github.com/charmbracelet/bubbletea@latest github.com/charmbracelet/lipgloss@latest
run go mod tidy
run go build -o "$HOME/.local/bin/forge-tui" ./cmd/forge-tui

log "Forge TUI installed at $HOME/.local/bin/forge-tui"
log "Run it with: forge-tui"
