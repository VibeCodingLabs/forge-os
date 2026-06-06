#!/usr/bin/env bash
# =============================================================================
# ForgeOS — forge-obs-status
# Live observability dashboard — print current state of all obs subsystems
# Usage: bash scripts/forge-obs-status.sh [--watch]
# =============================================================================
set -Eeuo pipefail

FORGE_HOME="${FORGE_HOME:-$HOME/.forge-os}"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; MAG='\033[0;35m'; BOLD='\033[1m'; NC='\033[0m'

hr()  { printf '%b\n' "${CYAN}────────────────────────────────────────────────────${NC}"; }
head_() { printf '%b\n' "${BOLD}${MAG}$*${NC}"; }
ok()  { printf '  %b✔%b %s\n' "$GREEN" "$NC" "$*"; }
warn(){ printf '  %b⚠%b %s\n' "$YELLOW" "$NC" "$*"; }
bad() { printf '  %b✘%b %s\n' "$RED" "$NC" "$*"; }

print_dashboard() {
  clear || true
  printf '%b\n' "${BOLD}${MAG} ForgeOS Observability Status — $(date)${NC}"
  hr

  # ── Heartbeat state
  head_ "Heartbeat"
  HB="$FORGE_HOME/state/heartbeat.env"
  if [[ -f "$HB" ]]; then
    # shellcheck disable=SC1090
    source "$HB"
    ok "timestamp: ${timestamp:-?}"
    ok "load: ${load:-?} | mem_used: ${mem_used:-?}"
    ok "cpu_temp: ${cpu_temp:-?} | cpu_gov: ${cpu_gov:-?}"
    ok "zram: ${zram:-?}"
    ok "river_pid: ${river_pid:-?} | waybar_pid: ${waybar_pid:-?}"
    ok "battery: ${battery_pct:-?}% (${battery_status:-?})"
    [[ "${failed_systemd_units:-0}" -gt 0 ]] && bad "failed units: $failed_systemd_units" || ok "failed units: 0"
    [[ "${journal_errors_5m:-0}" -gt 0 ]] && warn "journal errors (5m): $journal_errors_5m" || ok "journal errors (5m): 0"
  else
    bad "heartbeat.env not found — run forge-heartbeat first"
  fi
  hr

  # ── Installed state files
  head_ "Install State"
  for f in forge-enhance zsh-productivity tui-dev rich-ui obsidian; do
    SF="$FORGE_HOME/state/${f}.env"
    if [[ -f "$SF" ]]; then
      TS=$(grep -m1 'installed=' "$SF" 2>/dev/null | cut -d= -f2 || echo '?')
      ELAPSED=$(grep 'elapsed_sec' "$SF" 2>/dev/null | cut -d= -f2 || echo '?')
      ok "$f: installed $TS (${ELAPSED}s)"
    else
      warn "$f: not yet installed"
    fi
  done
  hr

  # ── Timers
  head_ "Systemd User Timers"
  systemctl --user list-timers --no-pager --no-legend 2>/dev/null | while read -r line; do
    echo "  $line"
  done || bad "systemctl --user not available"
  hr

  # ── Alerts
  head_ "Recent Alerts (last 10)"
  ALERT_LOG="$FORGE_HOME/logs/alerts.log"
  if [[ -f "$ALERT_LOG" ]] && [[ -s "$ALERT_LOG" ]]; then
    tail -10 "$ALERT_LOG" | while read -r line; do
      if echo "$line" | grep -q 'ALERT'; then
        printf '  %b%s%b\n' "$RED" "$line" "$NC"
      else
        printf '  %b%s%b\n' "$YELLOW" "$line" "$NC"
      fi
    done
  else
    ok "no alerts logged"
  fi
  hr

  # ── Disk
  head_ "Disk"
  df -h / "$HOME" "$FORGE_HOME" 2>/dev/null | tail -n +2 | while read -r line; do
    PCT=$(echo "$line" | awk '{gsub("%",""); print $5}')
    if [[ "$PCT" -gt 90 ]]; then
      printf '  %b%s%b\n' "$RED" "$line" "$NC"
    elif [[ "$PCT" -gt 75 ]]; then
      printf '  %b%s%b\n' "$YELLOW" "$line" "$NC"
    else
      printf '  %b%s%b\n' "$GREEN" "$line" "$NC"
    fi
  done
  hr

  # ── Latest observer snapshot
  head_ "Latest Observer Snapshot"
  LATEST=$(ls -t "$FORGE_HOME/observability/snapshot-"*.txt 2>/dev/null | head -1 || echo '')
  if [[ -n "$LATEST" ]]; then
    ok "$(basename "$LATEST")"
    grep -E '(WAYLAND|river|waybar|governor|load|MemAvail)' "$LATEST" 2>/dev/null | head -10 | while read -r l; do
      echo "  $l"
    done
  else
    warn "no observer snapshot found — timer may not have fired yet"
  fi
  hr

  printf '%b\n' "${BOLD}  Log dir:  $FORGE_HOME/logs/${NC}"
  printf '%b\n' "${BOLD}  State:    $FORGE_HOME/state/${NC}"
  printf '%b\n' "${BOLD}  Obs:      $FORGE_HOME/observability/${NC}"
  printf '%b\n' "${BOLD}  Telemetry:$FORGE_HOME/telemetry/${NC}"
}

if [[ "${1:-}" == "--watch" ]]; then
  while true; do
    print_dashboard
    sleep 10
  done
else
  print_dashboard
fi
