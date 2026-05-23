#!/usr/bin/env bash
set -Eeuo pipefail
FORGE_HOME="${FORGE_HOME:-$HOME/.forge-os}"
mkdir -p "$FORGE_HOME/logs" "$FORGE_HOME/observability"
OUT="$FORGE_HOME/observability/snapshot-$(date +%Y%m%d-%H%M%S).txt"
{
  echo "# ForgeOS Observability Snapshot"
  date --iso-8601=seconds
  echo
  echo "## systemd user timers"
  systemctl --user list-timers --no-pager || true
  echo
  echo "## processes"
  ps -eo pid,ppid,cmd,%mem,%cpu --sort=-%cpu | head -40
  echo
  echo "## network listeners"
  ss -tulpn || true
  echo
  echo "## rootless containers"
  podman ps --format json || true
} | tee "$OUT" >> "$FORGE_HOME/logs/observer.log"
