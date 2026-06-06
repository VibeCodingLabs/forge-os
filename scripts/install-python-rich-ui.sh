#!/usr/bin/env bash
# =============================================================================
# ForgeOS — install-python-rich-ui
# Python Rich + Textual + Typer color UI stack in isolated venv
# Observability: all steps logged, timing recorded, state written
# =============================================================================
set -Eeuo pipefail

FORGE_HOME="${FORGE_HOME:-$HOME/.forge-os}"
VENV="$FORGE_HOME/venvs/rich-ui"
LOG_DIR="$FORGE_HOME/logs"
mkdir -p "$LOG_DIR" "$(dirname "$VENV")"
LOG_FILE="$LOG_DIR/install-python-rich-ui-$(date +%Y%m%d-%H%M%S).log"

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
log()  { printf "%b\n" "$*" | tee -a "$LOG_FILE"; }
ok()   { log "${GREEN}[ OK ]${NC} $*"; }
warn() { log "${YELLOW}[WARN]${NC} $*"; }
err()  { log "${RED}[ERR ]${NC} $*"; }
run()  { log "${CYAN} ▶${NC} $*"; "$@" 2>&1 | tee -a "$LOG_FILE"; }
has()  { command -v "$1" >/dev/null 2>&1; }

log "=== install-python-rich-ui started: $(date --iso-8601=seconds) ==="
log "user=$(id -un) host=$(hostname) forge_home=$FORGE_HOME"
START=$(date +%s)

need_sudo() { if [[ $EUID -ne 0 ]]; then SUDO=sudo; else SUDO=""; fi; }
need_sudo

log "--- system packages ---"
run $SUDO apt-get update -qq
run $SUDO apt-get install -y python3 python3-pip python3-venv pipx
ok "Python: $(python3 --version 2>/dev/null)"

log "--- create venv ---"
if [[ -d "$VENV" ]]; then
  warn "venv already exists at $VENV — upgrading packages"
else
  python3 -m venv "$VENV"
  ok "venv created: $VENV"
fi

log "--- install Python packages ---"
PKG_START=$(date +%s)
run "$VENV/bin/pip" install --upgrade pip wheel
run "$VENV/bin/pip" install \
  rich textual typer click \
  prompt-toolkit questionary \
  halo yaspin blessed colorama pygments
PKG_END=$(date +%s)
ok "Python packages installed in $((PKG_END - PKG_START))s"

log "--- package version audit ---"
for pkg in rich textual typer click prompt_toolkit questionary; do
  VER=$("$VENV/bin/pip" show "$pkg" 2>/dev/null | awk '/^Version/ {print $2}') || VER='unknown'
  log "  $pkg: $VER"
done

log "--- install forge-rich-demo ---"
cat > "$HOME/.local/bin/forge-rich-demo" <<'EOF'
#!/usr/bin/env bash
VENV="${FORGE_HOME:-$HOME/.forge-os}/venvs/rich-ui"
exec "$VENV/bin/python" - <<'PY'
from rich.console import Console
from rich.panel import Panel
from rich.table import Table
from rich import box
console = Console()
table = Table(title="ForgeOS Rich UI Stack", box=box.ROUNDED, show_header=True, header_style="bold cyan")
table.add_column("Package", style="green")
table.add_column("Version")
table.add_column("Purpose")
import importlib.metadata as m
for pkg, purpose in [("rich","color formatting, tables, panels"), ("textual","full Python TUIs"), ("typer","CLI apps"), ("prompt_toolkit","autocomplete prompts"), ("questionary","interactive prompts")]:
    try:
        ver = m.version(pkg)
    except Exception:
        ver = "?"
    table.add_row(pkg, ver, purpose)
console.print(Panel.fit("[bold magenta]Ghostnode Command Center[/] — ForgeOS Rich UI", border_style="magenta"))
console.print(table)
PY
EOF
chmod +x "$HOME/.local/bin/forge-rich-demo"
ok "forge-rich-demo installed → $HOME/.local/bin/forge-rich-demo"

VENV_SIZE=$(du -sh "$VENV" 2>/dev/null | cut -f1 || echo 'unknown')
END=$(date +%s)
ELAPSED=$((END - START))

log "--- observability state ---"
mkdir -p "$FORGE_HOME/state"
printf 'rich_ui_installed=%s\nelapsed_sec=%d\npython_version=%s\nvenv_path=%s\nvenv_size=%s\n' \
  "$(date --iso-8601=seconds)" "$ELAPSED" \
  "$(python3 --version 2>/dev/null)" \
  "$VENV" "$VENV_SIZE" \
  > "$FORGE_HOME/state/rich-ui.env"
ok "State written → $FORGE_HOME/state/rich-ui.env"

log "=== install-python-rich-ui complete in ${ELAPSED}s ==="
log "Log: $LOG_FILE"
log "Run demo: forge-rich-demo"
