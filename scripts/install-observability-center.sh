#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FORGE_HOME="${FORGE_HOME:-$HOME/.forge-os}"
OBS_DIR="$FORGE_HOME/observability"
LOG_DIR="$FORGE_HOME/logs"
ART_DIR="$FORGE_HOME/artifacts"
WIKI_DIR="$FORGE_HOME/wiki"
mkdir -p "$OBS_DIR" "$LOG_DIR" "$ART_DIR" "$WIKI_DIR" "$FORGE_HOME/state" "$HOME/.local/bin"
LOG_FILE="$LOG_DIR/install-observability-center-$(date +%Y%m%d-%H%M%S).log"

CYAN='\033[0;36m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
log(){ printf "%b\n" "$*" | tee -a "$LOG_FILE"; }
run(){ log "${CYAN}▶ $*${NC}"; "$@" 2>&1 | tee -a "$LOG_FILE"; }
need_sudo(){ if [[ $EUID -ne 0 ]]; then SUDO=sudo; else SUDO=""; fi; }
need_sudo

log "=== ForgeOS observability center install started: $(date --iso-8601=seconds) ==="
run $SUDO apt-get update
run $SUDO apt-get install -y sqlite3 jq yq ripgrep fd-find bat btop htop glances sysstat python3 python3-venv python3-pip pipx graphviz entr watchexec

DB="$OBS_DIR/forge-observability.db"
cp "$ROOT_DIR/observability/schema.sql" "$OBS_DIR/schema.sql"
sqlite3 "$DB" < "$OBS_DIR/schema.sql"

for f in events.jsonl model-calls.jsonl tool-calls.jsonl agent-runs.jsonl compiler-runs.jsonl artifacts.jsonl audit.jsonl errors.jsonl; do
  touch "$LOG_DIR/$f"
done

cat > "$HOME/.local/bin/forge-event" <<'SCRIPT'
#!/usr/bin/env bash
set -Eeuo pipefail
FORGE_HOME="${FORGE_HOME:-$HOME/.forge-os}"
DB="$FORGE_HOME/observability/forge-observability.db"
LOG="$FORGE_HOME/logs/events.jsonl"
mkdir -p "$(dirname "$DB")" "$(dirname "$LOG")"
ID="evt_$(date +%Y%m%d%H%M%S)_$RANDOM"
SOURCE="${FORGE_SOURCE:-forge-cli}"
TYPE="${1:-manual.event}"
MESSAGE="${2:-}"
PROJECT="${FORGE_PROJECT:-}"
AGENT="${FORGE_AGENT:-}"
RUN_ID="${FORGE_RUN_ID:-}"
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
PAYLOAD="${FORGE_PAYLOAD_JSON:-{}}"
printf '{"id":"%s","ts":"%s","source":"%s","type":"%s","project":"%s","agent":"%s","run_id":"%s","message":"%s","payload":%s}\n' "$ID" "$TS" "$SOURCE" "$TYPE" "$PROJECT" "$AGENT" "$RUN_ID" "$(printf '%s' "$MESSAGE" | sed 's/"/\\"/g')" "$PAYLOAD" >> "$LOG"
sqlite3 "$DB" "INSERT OR REPLACE INTO events(id,ts,source,type,project,agent,run_id,message,payload_json) VALUES('$ID','$TS','$SOURCE','$TYPE','$PROJECT','$AGENT','$RUN_ID',quote('$MESSAGE'),'$PAYLOAD');" 2>/dev/null || true
echo "$ID"
SCRIPT
chmod +x "$HOME/.local/bin/forge-event"

cat > "$HOME/.local/bin/forge-model-call" <<'SCRIPT'
#!/usr/bin/env bash
set -Eeuo pipefail
FORGE_HOME="${FORGE_HOME:-$HOME/.forge-os}"
DB="$FORGE_HOME/observability/forge-observability.db"
LOG="$FORGE_HOME/logs/model-calls.jsonl"
mkdir -p "$(dirname "$DB")" "$(dirname "$LOG")"
ID="mc_$(date +%Y%m%d%H%M%S)_$RANDOM"
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
PROVIDER="${1:-unknown-provider}"
MODEL="${2:-unknown-model}"
ROUTE="${3:-default}"
IN_TOK="${4:-0}"
OUT_TOK="${5:-0}"
LAT="${6:-0}"
PROJECT="${FORGE_PROJECT:-}"
AGENT="${FORGE_AGENT:-}"
RUN_ID="${FORGE_RUN_ID:-}"
TOTAL=$((IN_TOK + OUT_TOK))
printf '{"id":"%s","ts":"%s","project":"%s","agent":"%s","run_id":"%s","provider":"%s","model":"%s","route":"%s","input_tokens":%s,"output_tokens":%s,"total_tokens":%s,"latency_ms":%s}\n' "$ID" "$TS" "$PROJECT" "$AGENT" "$RUN_ID" "$PROVIDER" "$MODEL" "$ROUTE" "$IN_TOK" "$OUT_TOK" "$TOTAL" "$LAT" >> "$LOG"
sqlite3 "$DB" "INSERT OR REPLACE INTO model_calls(id,ts,run_id,project,agent,provider,model,route,input_tokens,output_tokens,total_tokens,latency_ms) VALUES('$ID','$TS','$RUN_ID','$PROJECT','$AGENT','$PROVIDER','$MODEL','$ROUTE',$IN_TOK,$OUT_TOK,$TOTAL,$LAT);" 2>/dev/null || true
echo "$ID"
SCRIPT
chmod +x "$HOME/.local/bin/forge-model-call"

cat > "$HOME/.local/bin/forge-tool-call" <<'SCRIPT'
#!/usr/bin/env bash
set -Eeuo pipefail
FORGE_HOME="${FORGE_HOME:-$HOME/.forge-os}"
DB="$FORGE_HOME/observability/forge-observability.db"
LOG="$FORGE_HOME/logs/tool-calls.jsonl"
mkdir -p "$(dirname "$DB")" "$(dirname "$LOG")"
ID="tc_$(date +%Y%m%d%H%M%S)_$RANDOM"
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
TOOL="${1:-unknown-tool}"
STATUS="${2:-ok}"
EXIT_CODE="${3:-0}"
PROJECT="${FORGE_PROJECT:-}"
AGENT="${FORGE_AGENT:-}"
RUN_ID="${FORGE_RUN_ID:-}"
CMD="${FORGE_COMMAND:-}"
CWD="$(pwd)"
printf '{"id":"%s","ts":"%s","project":"%s","agent":"%s","run_id":"%s","tool":"%s","status":"%s","exit_code":%s,"cwd":"%s"}\n' "$ID" "$TS" "$PROJECT" "$AGENT" "$RUN_ID" "$TOOL" "$STATUS" "$EXIT_CODE" "$CWD" >> "$LOG"
sqlite3 "$DB" "INSERT OR REPLACE INTO tool_calls(id,ts,run_id,project,agent,tool_name,status,exit_code,cwd,command) VALUES('$ID','$TS','$RUN_ID','$PROJECT','$AGENT','$TOOL','$STATUS',$EXIT_CODE,'$CWD','$CMD');" 2>/dev/null || true
echo "$ID"
SCRIPT
chmod +x "$HOME/.local/bin/forge-tool-call"

cat > "$HOME/.local/bin/forge-observe" <<'SCRIPT'
#!/usr/bin/env bash
set -Eeuo pipefail
FORGE_HOME="${FORGE_HOME:-$HOME/.forge-os}"
DB="$FORGE_HOME/observability/forge-observability.db"
echo "== Recent Events =="
sqlite3 -header -column "$DB" "SELECT ts,type,project,agent,severity,message FROM events ORDER BY ts DESC LIMIT 20;" 2>/dev/null || true
echo
echo "== Model Costs =="
sqlite3 -header -column "$DB" "SELECT * FROM v_model_costs LIMIT 20;" 2>/dev/null || true
echo
echo "== Recent Tool Calls =="
sqlite3 -header -column "$DB" "SELECT ts,project,agent,tool_name,status,exit_code FROM tool_calls ORDER BY ts DESC LIMIT 20;" 2>/dev/null || true
SCRIPT
chmod +x "$HOME/.local/bin/forge-observe"

cat > "$HOME/.local/bin/forge-compile-log" <<'SCRIPT'
#!/usr/bin/env bash
set -Eeuo pipefail
FORGE_HOME="${FORGE_HOME:-$HOME/.forge-os}"
DB="$FORGE_HOME/observability/forge-observability.db"
LOG="$FORGE_HOME/logs/compiler-runs.jsonl"
ID="cr_$(date +%Y%m%d%H%M%S)_$RANDOM"
TS="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
COMPILER="${1:-unknown-compiler}"
SRC="${2:-}"
OUT="${3:-}"
PROJECT="${FORGE_PROJECT:-}"
printf '{"id":"%s","ts_start":"%s","project":"%s","compiler":"%s","source_path":"%s","output_path":"%s","status":"recorded"}\n' "$ID" "$TS" "$PROJECT" "$COMPILER" "$SRC" "$OUT" >> "$LOG"
sqlite3 "$DB" "INSERT OR REPLACE INTO compiler_runs(id,ts_start,project,compiler,source_path,output_path,status) VALUES('$ID','$TS','$PROJECT','$COMPILER','$SRC','$OUT','recorded');" 2>/dev/null || true
echo "$ID"
SCRIPT
chmod +x "$HOME/.local/bin/forge-compile-log"

cat > "$FORGE_HOME/state/observability-center.env" <<STATE
observability_center_installed=$(date --iso-8601=seconds)
db=$DB
logs=$LOG_DIR
artifacts=$ART_DIR
wiki=$WIKI_DIR
commands=forge-event,forge-model-call,forge-tool-call,forge-observe,forge-compile-log
STATE

forge-event observability.center.installed "ForgeOS observability center installed" >/dev/null || true
log "${GREEN}Observability center complete.${NC}"
log "DB: $DB"
log "Run: forge-observe"
