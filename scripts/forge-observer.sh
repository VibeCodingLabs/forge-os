#!/usr/bin/env bash
# =============================================================================
# ForgeOS — forge-observer
# Deep system observation snapshot: processes, network, containers,
# Wayland/River state, filesystem, security, journal errors
# Runs via: forge-observer.timer (every 15 min)
# Writes:   $FORGE_HOME/observability/snapshot-<ts>.txt
#           $FORGE_HOME/logs/observer.log (append)
#           $FORGE_HOME/logs/alerts.log   (anomalies)
# =============================================================================
set -Eeuo pipefail

FORGE_HOME="${FORGE_HOME:-$HOME/.forge-os}"
OBS_DIR="$FORGE_HOME/observability"
LOG_FILE="$FORGE_HOME/logs/observer.log"
ALERT_LOG="$FORGE_HOME/logs/alerts.log"
mkdir -p "$OBS_DIR" "$FORGE_HOME/logs"

TS="$(date --iso-8601=seconds)"
SNAP="$OBS_DIR/snapshot-$(date +%Y%m%d-%H%M%S).txt"

collect() {
  echo "# =========================================================="
  echo "# ForgeOS Observer Snapshot"
  echo "# $TS"
  echo "# host=$(hostname) user=$(id -un) kernel=$(uname -sr)"
  echo "# =========================================================="
  echo

  echo "## ── LOAD & UPTIME ──────────────────────────────────────"
  uptime
  echo

  echo "## ── MEMORY ────────────────────────────────────────────"
  free -h
  echo
  echo "--- zram ---"
  zramctl 2>/dev/null || echo 'N/A'
  echo

  echo "## ── CPU ───────────────────────────────────────────────"
  echo "governor: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo N/A)"
  echo "temp:     $(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null | awk '{printf "%.1f°C", $1/1000}' || echo N/A)"
  echo "freq (MHz per core):"
  for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_cur_freq; do
    [[ -f "$f" ]] && awk '{printf "  %s: %d MHz\n", FILENAME, $1/1000}' "$f"
  done | sort -t/ -k7 -V || true
  echo

  echo "## ── DISK ──────────────────────────────────────────────"
  df -h / "$HOME" "$FORGE_HOME" 2>/dev/null || true
  echo
  echo "--- I/O scheduler ---"
  for b in /sys/block/*/queue/scheduler; do
    [[ -f "$b" ]] && printf '  %s: %s\n' "$(echo "$b"|cut -d/ -f4)" "$(cat "$b")"
  done || true
  echo

  echo "## ── SWAP ──────────────────────────────────────────────"
  swapon --show 2>/dev/null || echo 'none'
  echo

  echo "## ── TOP PROCESSES (CPU) ───────────────────────────────"
  ps -eo pid,ppid,user,cmd,%mem,%cpu --sort=-%cpu | head -20
  echo

  echo "## ── TOP PROCESSES (MEM) ───────────────────────────────"
  ps -eo pid,ppid,user,cmd,%mem,%cpu --sort=-%mem | head -20
  echo

  echo "## ── WAYLAND / RIVER ───────────────────────────────────"
  echo "WAYLAND_DISPLAY=${WAYLAND_DISPLAY:-none}"
  echo "XDG_SESSION_TYPE=${XDG_SESSION_TYPE:-unknown}"
  echo "XDG_CURRENT_DESKTOP=${XDG_CURRENT_DESKTOP:-unknown}"
  echo "river pid: $(pgrep -x river 2>/dev/null || echo 'not running')"
  echo "waybar pid: $(pgrep -x waybar 2>/dev/null || echo 'not running')"
  echo "mako pid: $(pgrep -x mako 2>/dev/null || echo 'not running')"
  echo "swayidle pid: $(pgrep -x swayidle 2>/dev/null || echo 'not running')"
  echo "xdg-desktop-portal pid: $(pgrep -f xdg-desktop-portal 2>/dev/null | head -1 || echo 'not running')"
  echo
  echo "--- River session log (tail 20) ---"
  tail -20 "$FORGE_HOME/logs/river/session.log" 2>/dev/null || echo 'no river session log'
  echo

  echo "## ── AUDIO (pipewire) ──────────────────────────────────"
  echo "pipewire pid: $(pgrep -x pipewire 2>/dev/null || echo 'not running')"
  echo "wireplumber pid: $(pgrep -x wireplumber 2>/dev/null || echo 'not running')"
  wpctl status 2>/dev/null | head -30 || echo 'wpctl not available'
  echo

  echo "## ── SYSTEMD USER UNITS ────────────────────────────────"
  systemctl --user list-units --no-pager --no-legend --state=active 2>/dev/null | head -30 || true
  echo
  echo "--- failed units ---"
  systemctl --user --state=failed --no-pager --no-legend 2>/dev/null || echo 'none'
  echo
  echo "--- timers ---"
  systemctl --user list-timers --no-pager 2>/dev/null || true
  echo

  echo "## ── NETWORK ───────────────────────────────────────────"
  echo "--- listeners ---"
  ss -tulpn 2>/dev/null | head -30 || true
  echo
  echo "--- connections ---"
  ss -tnp 2>/dev/null | head -20 || true
  echo
  echo "--- interfaces ---"
  ip -brief addr 2>/dev/null || true
  echo

  echo "## ── JOURNAL ERRORS (last 50) ──────────────────────────"
  journalctl --user -p err --no-pager -n 50 2>/dev/null || true
  echo
  echo "--- system journal errors (last 20) ---"
  journalctl -p err --no-pager -n 20 2>/dev/null || true
  echo

  echo "## ── BATTERY ───────────────────────────────────────────"
  for f in /sys/class/power_supply/BAT*; do
    [[ -d "$f" ]] && printf '  %s: %s%% (%s)\n' \
      "$(basename "$f")" \
      "$(cat "$f/capacity" 2>/dev/null || echo '?')" \
      "$(cat "$f/status" 2>/dev/null || echo '?')"
  done || echo 'no battery'
  echo

  echo "## ── CONTAINERS (rootless) ─────────────────────────────"
  if command -v podman >/dev/null 2>&1; then
    podman ps --format 'table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Image}}' 2>/dev/null || echo 'none'
  else
    echo 'podman not installed'
  fi
  echo

  echo "## ── FORGE HOME SIZE ───────────────────────────────────"
  du -sh "$FORGE_HOME"/* 2>/dev/null | sort -h || true
  echo

  echo "## ── ALERTS LOG (last 20) ──────────────────────────────"
  tail -20 "$FORGE_HOME/logs/alerts.log" 2>/dev/null || echo 'no alerts'
  echo

  echo "# ── END SNAPSHOT ────────────────────────────────────── $TS"
}

collect > "$SNAP" 2>&1

# ---- append summary to rolling log ----------------------------------------
printf '[%s] observer snapshot: %s\n' "$TS" "$SNAP" >> "$LOG_FILE"
printf '  load=%s  mem_avail=%sMB  river=%s  failed_units=%s\n' \
  "$(cut -d ' ' -f1 /proc/loadavg)" \
  "$(awk '/MemAvailable/ {printf "%.0f", $2/1024}' /proc/meminfo)" \
  "$(pgrep -x river >/dev/null 2>&1 && echo running || echo stopped)" \
  "$(systemctl --user --state=failed --no-pager --no-legend 2>/dev/null | wc -l)" \
  >> "$LOG_FILE"

# ---- anomaly detection + alerts --------------------------------------------
# River not running during expected session hours (6am–midnight)
HOUR=$(date +%-H)
if ! pgrep -x river >/dev/null 2>&1 && [[ $HOUR -ge 6 && $HOUR -lt 24 ]]; then
  printf '[%s] WARN: river not running (hour=%d)\n' "$TS" "$HOUR" >> "$ALERT_LOG"
fi

# Disk usage > 90%
ROOT_PCT=$(df / | awk 'NR==2 {gsub("%",""); print $5}')
if [[ "$ROOT_PCT" -gt 90 ]]; then
  printf '[%s] ALERT: root disk usage %d%%\n' "$TS" "$ROOT_PCT" >> "$ALERT_LOG"
fi

HOME_PCT=$(df "$HOME" | awk 'NR==2 {gsub("%",""); print $5}')
if [[ "$HOME_PCT" -gt 90 ]]; then
  printf '[%s] ALERT: home disk usage %d%%\n' "$TS" "$HOME_PCT" >> "$ALERT_LOG"
fi

# Memory pressure: < 200MB available
MEM_AVAIL=$(awk '/MemAvailable/ {printf "%d", $2/1024}' /proc/meminfo)
if [[ "$MEM_AVAIL" -lt 200 ]]; then
  printf '[%s] ALERT: low memory available %dMB\n' "$TS" "$MEM_AVAIL" >> "$ALERT_LOG"
fi

# ---- rotate snapshots (keep 48h of snapshots) ------------------------------
find "$OBS_DIR" -name 'snapshot-*.txt' -mmin +2880 -delete 2>/dev/null || true
