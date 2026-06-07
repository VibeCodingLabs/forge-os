#!/usr/bin/env bash
# ForgeOS dictation and accessibility installer
set -Eeuo pipefail
FORGE_HOME="${FORGE_HOME:-$HOME/.forge-os}"
LOG_DIR="$FORGE_HOME/logs"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/install-dictation-accessibility-$(date +%Y%m%d-%H%M%S).log"
CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
log(){ printf "%b\n" "$*" | tee -a "$LOG_FILE"; }
run(){ log "${CYAN}▶ $*${NC}"; "$@" 2>&1 | tee -a "$LOG_FILE"; }
need_sudo(){ if [[ $EUID -ne 0 ]]; then SUDO=sudo; else SUDO=""; fi; }
need_sudo

log "=== ForgeOS dictation/accessibility install started: $(date --iso-8601=seconds) ==="
run $SUDO apt-get update
run $SUDO apt-get install -y \
  pipewire wireplumber pipewire-pulse pavucontrol playerctl \
  speech-dispatcher espeak-ng festival xdotool ydotool wtype wl-clipboard \
  python3 python3-venv python3-pip pipx

mkdir -p "$FORGE_HOME/venvs" "$FORGE_HOME/state" "$HOME/.local/bin"
python3 -m venv "$FORGE_HOME/venvs/dictation" 2>/dev/null || true
"$FORGE_HOME/venvs/dictation/bin/pip" install --upgrade pip wheel || true
"$FORGE_HOME/venvs/dictation/bin/pip" install vosk sounddevice numpy pynput rich typer || true

cat > "$HOME/.local/bin/forge-dictation-note" <<'NOTE'
#!/usr/bin/env bash
set -Eeuo pipefail
OUT="${FORGE_HOME:-$HOME/.forge-os}/dictation/notes/note-$(date +%Y%m%d-%H%M%S).md"
mkdir -p "$(dirname "$OUT")"
echo "# Dictation Note" > "$OUT"
echo >> "$OUT"
echo "Created: $(date --iso-8601=seconds)" >> "$OUT"
echo >> "$OUT"
echo "Paste/transcribe dictation here. Offline Vosk model setup is intentionally manual so models are not auto-downloaded without review." >> "$OUT"
${EDITOR:-nano} "$OUT"
echo "Saved: $OUT"
NOTE
chmod +x "$HOME/.local/bin/forge-dictation-note"

cat > "$FORGE_HOME/state/dictation-accessibility.env" <<STATE
dictation_accessibility_installed=$(date --iso-8601=seconds)
audio=pipewire,wireplumber,pavucontrol
speech=speech-dispatcher,espeak-ng,festival
input=wtype,ydotool,wl-clipboard
python_venv=$FORGE_HOME/venvs/dictation
log=$LOG_FILE
STATE

log "${GREEN}Dictation/accessibility install complete.${NC}"
log "Manual next step: install an offline Vosk model into $FORGE_HOME/models/vosk before real speech-to-text automation."
log "Log: $LOG_FILE"
