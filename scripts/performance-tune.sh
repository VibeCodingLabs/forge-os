#!/usr/bin/env bash
# =============================================================================
# ForgeOS — Performance Tuning Script
# zram, swappiness, cpufreq governor, journald, I/O scheduler, vm tweaks
# Observability: all actions logged to $FORGE_HOME/logs/perf/
# =============================================================================
set -Eeuo pipefail

FORGE_HOME="${FORGE_HOME:-$HOME/.forge-os}"
LOG_DIR="$FORGE_HOME/logs/perf"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/tune-$(date +%Y%m%d-%H%M%S).log"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

log()  { printf "%b\n" "$*" | tee -a "$LOG_FILE"; }
info() { log "${CYAN}[INFO]${NC} $*"; }
ok()   { log "${GREEN}[ OK ]${NC} $*"; }
warn() { log "${YELLOW}[WARN]${NC} $*"; }
err()  { log "${RED}[ERR ]${NC} $*"; }

require_root() {
  if [[ $EUID -ne 0 ]]; then
    err "This script must be run as root (sudo $0)"
    exit 1
  fi
}

snap_before() {
  info "=== PRE-TUNE SNAPSHOT ==="
  info "Kernel: $(uname -srmo)"
  info "CPU governor: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo 'N/A')"
  info "Swappiness: $(sysctl -n vm.swappiness 2>/dev/null || echo 'N/A')"
  info "Dirty ratio: $(sysctl -n vm.dirty_ratio 2>/dev/null || echo 'N/A')"
  info "I/O scheduler (sda): $(cat /sys/block/sda/queue/scheduler 2>/dev/null || echo 'N/A')"
  info "zram devices: $(ls /dev/zram* 2>/dev/null | wc -l)"
  info "Memory:"
  free -h | tee -a "$LOG_FILE" || true
  info "=========================="
}

snap_after() {
  info "=== POST-TUNE SNAPSHOT ==="
  info "CPU governor: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo 'N/A')"
  info "Swappiness: $(sysctl -n vm.swappiness)"
  info "Dirty ratio: $(sysctl -n vm.dirty_ratio)"
  info "zram status:"
  zramctl 2>/dev/null | tee -a "$LOG_FILE" || info "zramctl not available"
  info "Memory:"
  free -h | tee -a "$LOG_FILE" || true
  info "============================"
}

# ---------------------------------------------------------------------------
# ZRAM
# ---------------------------------------------------------------------------
setup_zram() {
  info "Setting up zram swap..."
  local MEM_KB
  MEM_KB=$(awk '/MemTotal/ {print $2}' /proc/meminfo)
  local ZRAM_SIZE_MB=$(( MEM_KB / 1024 / 2 ))  # 50% of RAM
  local ZRAM_SIZE="${ZRAM_SIZE_MB}M"

  if ! command -v zramctl >/dev/null 2>&1; then
    apt-get install -y zram-tools 2>&1 | tee -a "$LOG_FILE" || true
  fi

  # Use zram-tools config if available
  if [[ -f /etc/default/zramswap ]]; then
    sed -i 's/^#*ALGO=.*/ALGO=lz4/' /etc/default/zramswap
    sed -i 's/^#*PERCENT=.*/PERCENT=50/' /etc/default/zramswap
    systemctl enable --now zramswap 2>/dev/null || service zramswap restart 2>/dev/null || true
    ok "zramswap service configured (lz4, 50% RAM = ~${ZRAM_SIZE_MB}MB)"
  else
    # Manual zram setup fallback
    modprobe zram num_devices=1 2>/dev/null || true
    local ZRAM_DEV
    ZRAM_DEV=$(zramctl --find --size "$ZRAM_SIZE" --algorithm lz4 2>/dev/null || echo "")
    if [[ -n "$ZRAM_DEV" ]]; then
      mkswap "$ZRAM_DEV" 2>&1 | tee -a "$LOG_FILE"
      swapon -p 100 "$ZRAM_DEV" 2>&1 | tee -a "$LOG_FILE"
      ok "zram swap enabled: $ZRAM_DEV (${ZRAM_SIZE}, lz4, priority 100)"
    else
      warn "Could not create zram device automatically"
    fi
  fi

  # Persist via /etc/fstab comment block (don't duplicate)
  if ! grep -q 'zramswap' /etc/fstab 2>/dev/null; then
    printf '\n# ForgeOS: zram swap managed by zramswap service\n' >> /etc/fstab
  fi
}

# ---------------------------------------------------------------------------
# VM / SWAP TUNING
# ---------------------------------------------------------------------------
tune_vm() {
  info "Tuning VM parameters..."

  cat > /etc/sysctl.d/90-forgeos-perf.conf << 'EOF'
# ForgeOS Performance Tuning
# vm.swappiness: low = prefer RAM, push to swap later
vm.swappiness = 10
# Aggressive writeback — better for desktop, SSD
vm.dirty_ratio = 10
vm.dirty_background_ratio = 5
vm.dirty_expire_centisecs = 3000
vm.dirty_writeback_centisecs = 500
# Reduce OOM aggressiveness
vm.oom_kill_allocating_task = 0
vm.overcommit_memory = 1
# Reduce inotify limits warning
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 512
# Network perf
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_congestion_control = bbr
net.core.default_qdisc = fq
EOF

  sysctl --system 2>&1 | grep -E '(forgeos|swappiness|dirty|inotify)' | tee -a "$LOG_FILE" || true
  ok "VM sysctl params applied (/etc/sysctl.d/90-forgeos-perf.conf)"
}

# ---------------------------------------------------------------------------
# CPU FREQUENCY GOVERNOR
# ---------------------------------------------------------------------------
tune_cpu() {
  info "Setting CPU frequency governor..."

  if ! command -v cpufreq-set >/dev/null 2>&1; then
    apt-get install -y cpufrequtils 2>&1 | tee -a "$LOG_FILE" || true
  fi

  # Detect available governors
  local AVAIL
  AVAIL=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors 2>/dev/null || echo "")

  local GOV="schedutil"  # Best for desktop: schedutil > ondemand > performance
  if echo "$AVAIL" | grep -qw schedutil; then
    GOV=schedutil
  elif echo "$AVAIL" | grep -qw ondemand; then
    GOV=ondemand
  elif echo "$AVAIL" | grep -qw performance; then
    GOV=performance
  fi

  local CPU_COUNT
  CPU_COUNT=$(nproc)
  for i in $(seq 0 $((CPU_COUNT - 1))); do
    echo "$GOV" > "/sys/devices/system/cpu/cpu${i}/cpufreq/scaling_governor" 2>/dev/null || true
  done

  # Persist via cpufrequtils
  if [[ -d /etc/default ]]; then
    cat > /etc/default/cpufrequtils << EOF
GOVERNOR="$GOV"
MIN_SPEED=0
MAX_SPEED=0
EOF
  fi

  ok "CPU governor set to '$GOV' for $CPU_COUNT cores"
}

# ---------------------------------------------------------------------------
# I/O SCHEDULER
# ---------------------------------------------------------------------------
tune_io() {
  info "Setting I/O schedulers..."

  # Rule: NVMe/SSD -> none (or mq-deadline), spinning HDD -> bfq
  for block in /sys/block/*/queue/scheduler; do
    local DEV
    DEV=$(echo "$block" | cut -d/ -f4)
    local ROTATIONAL
    ROTATIONAL=$(cat "/sys/block/${DEV}/queue/rotational" 2>/dev/null || echo "1")
    local SCHED

    if [[ "$ROTATIONAL" == "0" ]]; then
      SCHED="none"  # SSD/NVMe: kernel default mq is fine
      # Try mq-deadline as fallback for better latency
      if grep -q mq-deadline "$block" 2>/dev/null; then
        SCHED="mq-deadline"
      fi
    else
      SCHED="bfq"  # HDD: Budget Fair Queuing
    fi

    echo "$SCHED" > "$block" 2>/dev/null || true
    ok "$DEV (rotational=$ROTATIONAL) -> scheduler=$SCHED"
  done

  # Persist via udev rule
  cat > /etc/udev/rules.d/60-forgeos-io.rules << 'EOF'
# ForgeOS I/O scheduler
ACTION=="add|change", KERNEL=="sd[a-z]*", ATTR{queue/rotational}=="1", ATTR{queue/scheduler}="bfq"
ACTION=="add|change", KERNEL=="sd[a-z]*", ATTR{queue/rotational}=="0", ATTR{queue/scheduler}="mq-deadline"
ACTION=="add|change", KERNEL=="nvme*",    ATTR{queue/scheduler}="none"
ACTION=="add|change", KERNEL=="mmcblk*",  ATTR{queue/scheduler}="mq-deadline"
EOF
  udevadm control --reload-rules 2>/dev/null || true
  ok "I/O scheduler udev rule written"
}

# ---------------------------------------------------------------------------
# JOURNALD LIMITS
# ---------------------------------------------------------------------------
tune_journald() {
  info "Tuning journald..."

  mkdir -p /etc/systemd/journald.conf.d
  cat > /etc/systemd/journald.conf.d/forgeos.conf << 'EOF'
[Journal]
# Keep on-disk journal bounded
SystemMaxUse=512M
SystemKeepFree=1G
SystemMaxFileSize=64M
SystemMaxFiles=8
# Memory journal ring buffer
RuntimeMaxUse=64M
RuntimeMaxFileSize=8M
# Compression + forward to syslog off (saves overhead)
Compress=yes
ForwardToSyslog=no
ForwardToWall=no
# Reduce verbosity
MaxLevelConsole=info
MaxLevelStore=debug
RateLimitIntervalSec=30s
RateLimitBurst=10000
EOF

  systemctl kill --kill-who=main --signal=SIGUSR2 systemd-journald 2>/dev/null || true
  systemctl restart systemd-journald 2>/dev/null || true
  ok "journald limits applied (512M max on disk, 64M runtime)"
}

# ---------------------------------------------------------------------------
# PRELOAD / READAHEAD (optional)
# ---------------------------------------------------------------------------
tune_preload() {
  info "Checking preload availability..."
  if apt-cache show preload >/dev/null 2>&1; then
    apt-get install -y preload 2>&1 | tee -a "$LOG_FILE" || true
    systemctl enable --now preload 2>/dev/null || true
    ok "preload installed and enabled"
  else
    warn "preload not available in repos — skipping"
  fi
}

# ---------------------------------------------------------------------------
# DISABLE UNUSED SERVICES (battery + speed)
# ---------------------------------------------------------------------------
disable_unused() {
  info "Disabling unused/heavyweight services..."
  local SERVICES=(
    ModemManager
    bluetooth
    avahi-daemon
    cups
    cups-browsed
    wpa_supplicant
  )
  for svc in "${SERVICES[@]}"; do
    if systemctl is-enabled "$svc" >/dev/null 2>&1; then
      systemctl disable --now "$svc" 2>/dev/null || true
      warn "Disabled: $svc (re-enable with: systemctl enable --now $svc)"
    fi
  done
  ok "Unused service audit complete"
}

# ---------------------------------------------------------------------------
# OBSERVABILITY SNAPSHOT
# ---------------------------------------------------------------------------
write_obs_snapshot() {
  local SNAP_DIR="$FORGE_HOME/logs/perf/snapshots"
  mkdir -p "$SNAP_DIR"
  local SNAP="$SNAP_DIR/$(date +%Y%m%d-%H%M%S).txt"
  {
    echo "=== ForgeOS Perf Snapshot: $(date -Iseconds) ==="
    echo "--- CPU ---"
    lscpu | grep -E '(Model name|CPU\(s\)|Thread|Socket|MHz|NUMA|Vendor)'
    echo "--- Memory ---"
    free -h
    echo "--- Swap ---"
    swapon --show
    echo "--- zram ---"
    zramctl 2>/dev/null || echo "N/A"
    echo "--- vm sysctl ---"
    sysctl vm.swappiness vm.dirty_ratio vm.dirty_background_ratio vm.overcommit_memory 2>/dev/null
    echo "--- CPU Governor ---"
    for f in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
      [[ -f "$f" ]] && printf '%s: %s\n' "$(echo "$f" | grep -oP 'cpu\d+')" "$(cat "$f")"
    done | sort -u
    echo "--- I/O Scheduler ---"
    for b in /sys/block/*/queue/scheduler; do
      [[ -f "$b" ]] && printf '%s: %s\n' "$(echo "$b" | cut -d/ -f4)" "$(cat "$b")"
    done
    echo "--- journald usage ---"
    journalctl --disk-usage 2>/dev/null || echo "N/A"
    echo "--- Load ---"
    uptime
  } > "$SNAP"
  ok "Observability snapshot written: $SNAP"
}

# ---------------------------------------------------------------------------
# MAIN
# ---------------------------------------------------------------------------
main() {
  require_root
  log "${BOLD}ForgeOS Performance Tuner${NC} — $(date)"
  log "Log: $LOG_FILE"
  log ""

  snap_before

  setup_zram
  tune_vm
  tune_cpu
  tune_io
  tune_journald
  tune_preload
  disable_unused

  snap_after
  write_obs_snapshot

  log ""
  ok "=== Performance tuning complete. Reboot recommended. ==="
  log "Full log: $LOG_FILE"
}

main "$@"
