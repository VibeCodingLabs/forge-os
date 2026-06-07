#!/usr/bin/env bash
# ForgeOS security hardening, firewall, and antivirus installer
set -Eeuo pipefail
FORGE_HOME="${FORGE_HOME:-$HOME/.forge-os}"
LOG_DIR="$FORGE_HOME/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/install-security-hardening-$(date +%Y%m%d-%H%M%S).log"
CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
log(){ printf "%b\n" "$*" | tee -a "$LOG_FILE"; }
run(){ log "${CYAN}▶ $*${NC}"; "$@" 2>&1 | tee -a "$LOG_FILE"; }
need_sudo(){ if [[ $EUID -ne 0 ]]; then SUDO=sudo; else SUDO=""; fi; }
need_sudo

log "=== ForgeOS security hardening started: $(date --iso-8601=seconds) ==="
run $SUDO apt-get update
run $SUDO apt-get install -y \
  ufw fail2ban auditd audispd-plugins apparmor apparmor-utils apparmor-profiles apparmor-profiles-extra \
  clamav clamav-daemon clamav-freshclam rkhunter chkrootkit lynis aide yara debsecan debsums \
  needrestart unattended-upgrades apt-listchanges ca-certificates gnupg curl wget

log "--- firewall baseline ---"
run $SUDO ufw default deny incoming || true
run $SUDO ufw default allow outgoing || true
run $SUDO ufw allow OpenSSH || true
run $SUDO ufw --force enable || true

log "--- service hardening ---"
run $SUDO systemctl enable --now fail2ban || true
run $SUDO systemctl enable --now auditd || true
run $SUDO systemctl enable --now apparmor || true
run $SUDO systemctl enable --now clamav-freshclam || true
run $SUDO systemctl enable --now clamav-daemon || true
run $SUDO systemctl enable --now unattended-upgrades || true

log "--- antivirus definitions ---"
run $SUDO freshclam || true

log "--- unattended upgrades baseline ---"
run $SUDO dpkg-reconfigure -f noninteractive unattended-upgrades || true

mkdir -p "$FORGE_HOME/state" "$FORGE_HOME/security/reports"
cat > "$FORGE_HOME/state/security-hardening.env" <<STATE
security_hardening_installed=$(date --iso-8601=seconds)
firewall=ufw deny-in allow-out openssh-allowed
antivirus=clamav
services=fail2ban,auditd,apparmor,clamav-freshclam,clamav-daemon,unattended-upgrades
log=$LOG_FILE
STATE

cat > "$HOME/.local/bin/forge-security-report" <<'REPORT'
#!/usr/bin/env bash
set -Eeuo pipefail
OUT="${FORGE_HOME:-$HOME/.forge-os}/security/reports/report-$(date +%Y%m%d-%H%M%S).txt"
mkdir -p "$(dirname "$OUT")"
{
  echo "ForgeOS Security Report: $(date --iso-8601=seconds)"
  echo
  echo "== UFW =="; sudo ufw status verbose || true
  echo
  echo "== AppArmor =="; sudo aa-status || true
  echo
  echo "== Fail2ban =="; sudo fail2ban-client status || true
  echo
  echo "== ClamAV =="; clamscan --version || true
  echo
  echo "== Lynis quick audit =="; sudo lynis audit system --quick || true
} | tee "$OUT"
echo "Report saved: $OUT"
REPORT
chmod +x "$HOME/.local/bin/forge-security-report"

log "${GREEN}Security hardening complete.${NC}"
log "Run later: forge-security-report"
log "Log: $LOG_FILE"
