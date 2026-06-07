#!/usr/bin/env bash
# =============================================================================
# ForgeOS — forge-heartbeat
# Periodic system health snapshot with full observability
# Runs via: forge-heartbeat.timer (every 5 min)
# Writes:   $FORGE_HOME/state/heartbeat.env  (current state, overwritten)
#           $FORGE_HOME/logs/heartbeat.log   (append, rotating)
#           $FORGE_HOME/telemetry/heartbeat/ (timestamped snapshots, kept 48h)
# =============================================================================
set -Eeuo pipefail

FORGE_HOME="${FORGE_HOME:-$HOME/.forge-os}"
TELEM_DIR="$FORGE_HOME/telemetry/heartbeat"
LOG_FILE="$FORGE_HOME/logs/heartbeat.log"
mkdir -p "$FORGE_HOME/logs" "$FORGE_HOME/state" "$TELEM_DIR"

TS="$(date --iso-8601=seconds)"
SNAP="$TELEM_DIR/$(date +%Y%m%d-%H%M%S).env"

# ---- helpers ---------------------------------------------------------------
bat_pct()  { cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -1 || echo 'N/A'; }
bat_stat() { cat /sys/class/power_supply/BAT*/status  2>/dev/null | head -1 || echo 'N/A'; }
cpu_temp() { cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null | awk '{printf "%.1f°C", $1/1000}' || echo 'N/A'; }
cpu_gov()  { cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo 'N/A'; }
wayland()  { echo "${WAYLAND_DISPLAY:-none}"; }
zram_use() { zramctl --noheadings --output NAME,DATA,COMPR,STREAMS 2>/dev/null | head -1 || echo 'N/A'; }
journal_errs() { journalctl --user -p err --since '5 minutes ago' --no-pager -q 2>/dev/null | wc -l || echo '0'; }
failed_units() { systemctl --user --state=failed --no-pager --no-legend 2>/dev/null | wc -l || echo '0'; }

# ---- collect ---------------------------------------------------------------
{
  echo "timestamp=$TS"
  echo "host=$(hostname -f 2>/dev/null || hostname)"
  echo "user=$(id -un)"
  echo "kernel=$(uname -srmo)"
  echo "uptime=$(uptime -p 2>/dev/null || uptime)"
  echo "load=$(cut -d ' ' -f1-3 /proc/loadavg)"
  echo "cpu_cores=$(nproc)"
  echo "cpu_temp=$(cpu_temp)"
  echo "cpu_gov=$(cpu_gov)"
  echo "mem_total=$(awk '/MemTotal/ {printf "%.0fMB", $2/1024}' /proc/meminfo)"
  echo "mem_avail=$(awk '/MemAvailable/ {printf "%.0fMB", $2/1024}' /proc/meminfo)"
  echo "mem_used=$(free -m | awk 'NR==2 {printf "%dMB / %dMB (%.0f%%)", $3, $2, $3/$2*100}')"
  echo "swap_used=$(free -m | awk 'NR==3 {printf "%dMB / %dMB", $3, $2}')"
  echo "zram=$(zram_use)"
  echo "disk_home=$(df -h "$HOME" | awk 'NR==2 {print $3"/"$2" ("$5") on "$6}')"
  echo "disk_root=$(df -h / | awk 'NR==2 {print $3"/"$2" ("$5")')"
  echo "battery_pct=$(bat_pct)"
  echo "battery_status=$(bat_stat)"
  echo "wayland_display=$(wayland)"
  echo "river_pid=$(pgrep -x river 2>/dev/null || echo 'not running')"
  echo "waybar_pid=$(pgrep -x waybar 2>/dev/null || echo 'not running')"
  echo "pipewire_pid=$(pgrep -x pipewire 2>/dev/null || echo 'not running')"
  echo "journal_errors_5m=$(journal_errs)"
  echo "failed_systemd_units=$(failed_units)"
  echo "forge_home=$FORGE_HOME"
  echo "forge_home_size=$(du -sh "$FORGE_HOME" 2>/dev/null | cut -f1 || echo 'N/A')"
} | tee "$FORGE_HOME/state/heartbeat.env" > "$SNAP"

# ---- append to rolling log -------------------------------------------------
printf '[%s] heartbeat\n' "$TS" >> "$LOG_FILE"
cat "$SNAP" >> "$LOG_FILE"
printf -- '---\n' >> "$LOG_FILE"

# ---- alert: failed units ---------------------------------------------------
FAILED=$(failed_units)
if [[ "$FAILED" -gt 0 ]]; then
  printf '[%s] ALERT: %d failed systemd user unit(s)\n' "$TS" "$FAILED" \
    >> "$FORGE_HOME/logs/alerts.log"
  systemctl --user --state=failed --no-pager --no-legend 2>/dev/null \
    >> "$FORGE_HOME/logs/alerts.log" || true
fi

# ---- alert: high load ------------------------------------------------------
LOAD1=$(cut -d ' ' -f1 /proc/loadavg)
CPUS=$(nproc)
if awk "BEGIN {exit !(\"$LOAD1\"+0 > $CPUS*1.5)}"; then
  printf '[%s] ALERT: high load %s on %d cpus\n' "$TS" "$LOAD1" "$CPUS" \
    >> "$FORGE_HOME/logs/alerts.log"
fi

# ---- rotate telemetry (keep 48h / ~576 files) ------------------------------
find "$TELEM_DIR" -name '*.env' -mmin +2880 -delete 2>/dev/null || true
