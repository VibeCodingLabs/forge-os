#!/usr/bin/env bash
set -Eeuo pipefail
FORGE_HOME="${FORGE_HOME:-$HOME/.forge-os}"
mkdir -p "$FORGE_HOME/logs" "$FORGE_HOME/state"
{
  echo "timestamp=$(date --iso-8601=seconds)"
  echo "host=$(hostname)"
  echo "user=$(id -un)"
  echo "kernel=$(uname -srmo)"
  echo "load=$(cut -d ' ' -f1-3 /proc/loadavg)"
  echo "disk=$(df -h "$HOME" | awk 'NR==2 {print $5" used on "$6}')"
} > "$FORGE_HOME/state/heartbeat.env"
cat "$FORGE_HOME/state/heartbeat.env" >> "$FORGE_HOME/logs/heartbeat.log"
