#!/usr/bin/env bash
# ForgeOS Debian 13 Trixie post-install wrapper.
# This is the preferred fresh-install entrypoint after cloning forge-os.
# It intentionally reuses repo modules instead of duplicating installer logic.

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FORGE_USER="${SUDO_USER:-$(id -un)}"
USER_HOME="$(getent passwd "$FORGE_USER" | cut -d: -f6)"
FORGE_HOME="${FORGE_HOME:-$USER_HOME/.forge-os}"
FOUNDRY_ROOT="${FOUNDRY_ROOT:-$USER_HOME/forge-foundry}"
LOG_DIR="$FORGE_HOME/logs"
STATE_DIR="$FORGE_HOME/state"
BIN_DIR="$USER_HOME/.local/bin"
RUN_ID="postinstall-trixie-$(date +%Y%m%d-%H%M%S)"
LOG_FILE="$LOG_DIR/$RUN_ID.log"

export DEBIAN_FRONTEND=noninteractive

CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'

log(){ mkdir -p "$LOG_DIR"; printf "%b\n" "$*" | tee -a "$LOG_FILE"; }
run(){ log "${CYAN}▶ $*${NC}"; "$@" 2>&1 | tee -a "$LOG_FILE"; }
need_sudo(){ if [[ $EUID -ne 0 ]]; then SUDO=sudo; else SUDO=""; fi; }
as_user(){ if [[ "$(id -un)" == "$FORGE_USER" ]]; then "$@"; else sudo -u "$FORGE_USER" "$@"; fi; }
need_sudo

banner(){
  printf "%b\n" "${CYAN}ForgeOS Debian 13 Trixie Post-Install${NC}"
  printf "%s\n" "user=$FORGE_USER"
  printf "%s\n" "forge_home=$FORGE_HOME"
  printf "%s\n" "foundry_root=$FOUNDRY_ROOT"
  printf "%s\n" "log=$LOG_FILE"
}

preflight(){
  mkdir -p "$LOG_DIR" "$STATE_DIR" "$BIN_DIR"
  $SUDO chown -R "$FORGE_USER:$FORGE_USER" "$FORGE_HOME" "$BIN_DIR" 2>/dev/null || true
  banner
  log "date=$(date --iso-8601=seconds)"
  log "kernel=$(uname -srmo)"
  log "debian=$(cat /etc/debian_version 2>/dev/null || echo unknown)"
  if ! grep -qi "trixie\|13" /etc/os-release /etc/debian_version 2>/dev/null; then
    log "${YELLOW}[WARN] This does not look like Debian 13/Trixie. Continuing best-effort.${NC}"
  fi
}

base_packages(){
  run $SUDO apt-get update
  run $SUDO apt-get install -y git ca-certificates curl sudo bash coreutils findutils util-linux systemd systemd-timesyncd dbus-user-session unzip zip tar xz-utils rsync jq yq sqlite3 zsh tmux htop btop glances ripgrep fd-find fzf bat eza tree direnv zoxide shellcheck
}

workspace_tree(){
  log "${CYAN}▶ creating ForgeOS and Forge Foundry directories${NC}"
  as_user mkdir -p \
    "$FORGE_HOME"/{bin,logs,state,observability,artifacts,wiki,agents,automations,skills,workflows,configs,secrets,sandboxes,worktrees,mirrors,raw,generated,backups,reports} \
    "$FORGE_HOME"/logs/{system,network,filesystem,agents,automations,security,model-calls,tool-calls,compiler-runs,heartbeats,watchdogs,river,wezterm} \
    "$FORGE_HOME"/artifacts/{captures,har,flows,screenshots,html,json,reports,builds,packages} \
    "$USER_HOME/forge-work" \
    "$USER_HOME/forge-vault" \
    "$FOUNDRY_ROOT"/{apps,services,tools,packages,agents,skills,workflows,contracts,observability,wiki,raw,generated,mirrors,config,scripts,docs,.github/workflows} \
    "$FOUNDRY_ROOT"/apps/{api-gateway,dashboard,command-center,forge-studio} \
    "$FOUNDRY_ROOT"/services/{agent-python,capture-worker,compiler,mcp-server,observability,webhook-gateway} \
    "$FOUNDRY_ROOT"/tools/{forge-cli,forge-tui,agentic-press,openapi-press,har-press,sidecars} \
    "$FOUNDRY_ROOT"/contracts/{openapi,arazzo,schemas,zod,pydantic} \
    "$FOUNDRY_ROOT"/config/{foundry,agents,workflows,automations,targets,policies}
  $SUDO chown -R "$FORGE_USER:$FORGE_USER" "$FORGE_HOME" "$FOUNDRY_ROOT" "$USER_HOME/forge-work" "$USER_HOME/forge-vault" 2>/dev/null || true
}

foundry_docs(){
  log "${CYAN}▶ writing Forge Foundry starter docs${NC}"
  cat > "$FOUNDRY_ROOT/README.md" <<'EOF'
# Forge Foundry

Local-first automation factory.

Canonical pipeline:

```text
capture -> mirror -> contract -> tools -> MCPs -> Python scripts -> Go CLIs -> Rust sidecars -> Tauri v2 GUI -> agents -> skills -> sub-agents -> cronjobs -> watchdogs -> heartbeats -> GitHub Actions -> issue triaging -> pull requests -> code review -> APIs -> commands -> workflows -> applications -> automations -> products
```

Rules:

1. SQLite + JSONL + artifacts + Git are the v1 source of truth.
2. Agents query mirrors before raw artifacts or live web.
3. Every model call, tool call, compiler run, and automation run gets logged.
4. Raw capture artifacts are sensitive and must be redacted before promotion.
5. Every generated automation needs a manifest, tests or dry-run, and rollback notes.
EOF

  cat > "$FOUNDRY_ROOT/ARCHITECTURE.md" <<'EOF'
# Architecture

Planes:

1. Host Plane: ForgeOS workstation and Jetson worker setup.
2. Capture Plane: authorized browser/API/docs/repo capture.
3. Raw Artifact Plane: HAR, flows, screenshots, HTML, JSON, logs.
4. Mirror Plane: SQLite mirrors and source-linked rows.
5. Contract Plane: OpenAPI 3.1, Arazzo, Zod, Pydantic.
6. Runtime Plane: MCPs, Python scripts, Go CLIs, Rust sidecars.
7. Agent Plane: mirror-first agents and sub-agents.
8. Automation Plane: cronjobs, watchdogs, heartbeats, GitHub Actions.
9. GUI Plane: Tauri v2 command center and dashboards.
10. Product Plane: client-ready deliverables.
EOF

  cat > "$FOUNDRY_ROOT/ROADMAP.md" <<'EOF'
# Roadmap

## Wave 0: Local Spine
- observability DB
- event writers
- monorepo skeleton
- doctor report

## Wave 1: Capture to Mirror
- target allowlist
- capture job schema
- HAR/flow importer
- SQLite mirror schema

## Wave 2: Mirror to Contract
- OpenAPI compiler
- Arazzo compiler
- Zod/Pydantic compilers

## Wave 3: Contract to Runtime
- Cobra CLI generator
- FastMCP generator
- Python worker scripts
- Rust sidecars

## Wave 4: Runtime to Automation
- skills
- sub-agents
- cronjobs
- watchdogs
- GitHub Actions
- PR/code review automation

## Wave 5: GUI and Productization
- Tauri v2 GUI
- dashboards
- deliverable generator
- pricing/proposal templates
EOF

  cat > "$FOUNDRY_ROOT/.gitignore" <<'EOF'
.env
.env.*
*.db
*.sqlite
*.sqlite3
*.log
node_modules/
dist/
build/
target/
.venv/
__pycache__/
raw/private/
artifacts/private/
secrets/
EOF
  $SUDO chown -R "$FORGE_USER:$FORGE_USER" "$FOUNDRY_ROOT" 2>/dev/null || true
}

install_modules(){
  chmod +x "$ROOT_DIR"/install.sh "$ROOT_DIR"/bin/*.sh "$ROOT_DIR"/scripts/*.sh 2>/dev/null || true
  run bash "$ROOT_DIR/scripts/install-full-command-center.sh"
  if [[ -f "$ROOT_DIR/scripts/forge-doctor.sh" ]]; then
    install -m 0755 "$ROOT_DIR/scripts/forge-doctor.sh" "$BIN_DIR/forge-doctor"
    $SUDO chown "$FORGE_USER:$FORGE_USER" "$BIN_DIR/forge-doctor" 2>/dev/null || true
  fi
}

shell_paths(){
  touch "$USER_HOME/.bashrc"
  if ! grep -q 'FORGE_HOME' "$USER_HOME/.bashrc"; then
    cat >> "$USER_HOME/.bashrc" <<'EOF'

# ForgeOS paths
export PATH="$HOME/.local/bin:$PATH"
export FORGE_HOME="${FORGE_HOME:-$HOME/.forge-os}"
export FOUNDRY_ROOT="${FOUNDRY_ROOT:-$HOME/forge-foundry}"
alias fo='cd "$FOUNDRY_ROOT"'
alias fh='cd "$FORGE_HOME"'
alias fobs='forge-observe'
alias fdoc='forge-doctor'
EOF
  fi
  $SUDO chown "$FORGE_USER:$FORGE_USER" "$USER_HOME/.bashrc" 2>/dev/null || true
}

finish(){
  cat > "$STATE_DIR/postinstall-trixie.env" <<STATE
run_id=$RUN_ID
completed=$(date --iso-8601=seconds)
forge_user=$FORGE_USER
forge_home=$FORGE_HOME
foundry_root=$FOUNDRY_ROOT
log=$LOG_FILE
STATE
  $SUDO chown "$FORGE_USER:$FORGE_USER" "$STATE_DIR/postinstall-trixie.env" 2>/dev/null || true
  if command -v forge-event >/dev/null 2>&1; then
    as_user forge-event postinstall.trixie.completed "ForgeOS Trixie post-install completed" >/dev/null || true
  fi
  log "${GREEN}ForgeOS Trixie post-install complete.${NC}"
  log "Next: sudo reboot"
  log "After reboot: forge-doctor && forge-observe"
}

main(){
  preflight
  base_packages
  workspace_tree
  foundry_docs
  install_modules
  shell_paths
  finish
}

main "$@"
