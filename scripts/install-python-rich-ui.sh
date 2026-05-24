#!/usr/bin/env bash
set -Eeuo pipefail

FORGE_HOME="${FORGE_HOME:-$HOME/.forge-os}"
VENV="$FORGE_HOME/venvs/rich-ui"
LOG_DIR="$FORGE_HOME/logs"
mkdir -p "$LOG_DIR" "$(dirname "$VENV")"
LOG_FILE="$LOG_DIR/install-python-rich-ui-$(date +%Y%m%d-%H%M%S).log"

log(){ printf "%b\n" "$*" | tee -a "$LOG_FILE"; }
run(){ log "▶ $*"; "$@" 2>&1 | tee -a "$LOG_FILE"; }
need_sudo(){ if [[ $EUID -ne 0 ]]; then SUDO=sudo; else SUDO=""; fi; }

need_sudo
run $SUDO apt-get update
run $SUDO apt-get install -y python3 python3-pip python3-venv pipx
python3 -m venv "$VENV"
run "$VENV/bin/pip" install --upgrade pip wheel
run "$VENV/bin/pip" install rich textual typer click prompt-toolkit questionary halo yaspin blessed colorama pygments

cat > "$HOME/.local/bin/forge-rich-demo" <<'EOF'
#!/usr/bin/env bash
VENV="${FORGE_HOME:-$HOME/.forge-os}/venvs/rich-ui"
exec "$VENV/bin/python" - <<'PY'
from rich.console import Console
from rich.panel import Panel
from rich.table import Table
console = Console()
table = Table(title="ForgeOS Rich UI Stack")
table.add_column("Package")
table.add_column("Purpose")
for row in [("rich", "color formatting and tables"), ("textual", "full Python TUIs"), ("typer", "CLI apps"), ("prompt-toolkit", "autocomplete prompts")]:
    table.add_row(*row)
console.print(Panel.fit("Ghostnode Command Center", style="bold magenta"))
console.print(table)
PY
EOF
chmod +x "$HOME/.local/bin/forge-rich-demo"
log "Rich/Textual environment installed at $VENV"
log "Run demo with: forge-rich-demo"
