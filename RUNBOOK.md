# ForgeOS RUNBOOK

This runbook is the operator manual for installing, validating, organizing, and operating ForgeOS after a fresh Debian 13 Trixie install.

It covers:

- post-install order
- filesystem layout
- River window-manager setup
- WezTerm terminal command center
- Forge Foundry monorepo layout
- local observability
- agents, skills, automations, watchdogs, and timers
- security hardening
- validation commands
- recovery/debugging
- future architecture rules

---

## 0. Validation Notes

This runbook was written against the current architecture and checked against these upstream patterns:

- Tauri v2: Rust commands use `#[tauri::command]`, frontend calls use `invoke`, sidecars should be launched through shell/sidecar APIs, and permissions/capabilities must be explicit.
- River: River is a Wayland compositor configured with `riverctl`; tiling should be handled by layout generators such as `rivertile`; River should spawn launchers, not own heavy daemon work.
- WezTerm: configuration is Lua-based; use `wezterm.lua`, key assignments, launch menu entries, workspaces, and `SpawnCommandInNewTab` for terminal command-center behavior.
- systemd timers: timer units activate matching services, support `OnBootSec`, `OnStartupSec`, `OnUnitActiveSec`, `OnCalendar`, `AccuracySec`, and `Persistent`; use user timers for user-level heartbeats and watchdogs.

Important honesty:

- Static architecture and shell patterns were reviewed.
- The repo still needs live validation on the target Debian 13 machine.
- Package availability can differ by Debian install profile and enabled repositories.
- Any optional package failure should be logged and handled without killing the full install.

---

## 1. Quick Start From Fresh Debian 13 Trixie

After the Debian installer completes and you are logged into your user account:

```bash
sudo apt-get update
sudo apt-get install -y git ca-certificates curl

git clone https://github.com/VibeCodingLabs/forge-os.git
cd forge-os
chmod +x install.sh scripts/*.sh
```

Run preflight first:

```bash
./install.sh
```

Choose:

```text
1) Preflight + disk report
```

Then install the full command center stack:

```bash
bash scripts/install-full-command-center.sh
```

Reboot:

```bash
sudo reboot
```

After reboot:

```bash
forge-doctor
forge-observe
```

From a TTY, launch River:

```bash
river
```

---

## 2. Golden Rule: What Goes Where

Do not scatter code and state across random folders.

Use this permanent map:

```text
~/.forge-os/        Local machine runtime, state, logs, observability, artifacts
~/forge-foundry/    Main monorepo for apps, services, tools, agents, contracts, docs
~/forge-work/       Active external clones and temporary worktrees
~/forge-vault/      Private manual notes and sensitive local-only material
~/.config/          App configs: river, waybar, eww, wezterm, systemd/user
~/.local/bin/       User commands, spawn scripts, wrappers, local CLIs
```

Decision rule:

```text
Source code?                 ~/forge-foundry/
Active cloned work?          ~/forge-work/
Runtime state/logs/artifacts? ~/.forge-os/
Application config?          ~/.config/
Executable command?          ~/.local/bin/
Private manual material?     ~/forge-vault/
Long-running automation?     systemd user service/timer
Desktop visual control?      River, Waybar, Eww, Tauri v2
Terminal workspace?          WezTerm + tmux/zellij
```

---

## 3. ForgeOS Runtime Layout

`~/.forge-os` is the local operating state.

Recommended tree:

```text
~/.forge-os/
  bin/
  logs/
    system/
    network/
    filesystem/
    agents/
    automations/
    security/
    model-calls/
    tool-calls/
    compiler-runs/
    heartbeats/
    watchdogs/
    river/
    wezterm/
  state/
  observability/
    forge-observability.db
    schema.sql
    dashboards/
    reports/
  artifacts/
    captures/
    har/
    flows/
    screenshots/
    html/
    json/
    reports/
    builds/
    packages/
  wiki/
  agents/
  automations/
  skills/
  workflows/
  mirrors/
  raw/
  generated/
  secrets/
  sandboxes/
  worktrees/
  backups/
```

`~/.forge-os` should usually not be committed to Git. It is the local machine brain.

---

## 4. Forge Foundry Monorepo Layout

`~/forge-foundry` is the project factory.

Recommended tree:

```text
~/forge-foundry/
  README.md
  ARCHITECTURE.md
  ROADMAP.md
  RUNBOOK.md

  apps/
    command-center/       Tauri v2 GUI
    api-gateway/          Hono or FastAPI gateway
    dashboard/            optional web dashboard
    forge-studio/         IDE/project builder later

  services/
    agent-python/         PydanticAI/FastAPI agent runtime
    capture-worker/       authorized browser/HAR/flow worker
    compiler/             mirror -> contracts/tools/wiki
    mcp-server/           FastMCP servers
    observability/        ingest/query APIs
    webhook-gateway/      GitHub/webhook intake

  tools/
    forge-cli/            Cobra/Go CLI
    forge-tui/            Bubble Tea terminal UI
    agentic-press/        automation/compiler factory
    openapi-press/        OpenAPI compiler
    har-press/            HAR/XHR compiler
    sidecars/             Rust sidecars

  agents/
    scout/
    scribe/
    archivist/
    operator/
    watcher/
    analyst/
    security-engineer/
    sidecar-engineer/
    ui-engineer/
    cli-engineer/
    python-worker-engineer/

  skills/
  workflows/
  contracts/
    openapi/
    arazzo/
    schemas/
    zod/
    pydantic/
  observability/
  wiki/
  raw/
  generated/
  mirrors/
  config/
    foundry/
    agents/
    workflows/
    automations/
    targets/
    policies/
  scripts/
  docs/
  .github/workflows/
```

---

## 5. Canonical Pipeline

Forge Foundry is not just an API wrapper generator.

Canonical pipeline:

```text
capture
  -> mirror
  -> contract
  -> tools
  -> MCPs
  -> Python scripts
  -> Go CLIs
  -> Rust sidecars
  -> Tauri v2 GUI
  -> agents
  -> skills
  -> sub-agents
  -> cronjobs
  -> watchdogs
  -> heartbeats
  -> GitHub Actions
  -> issue triaging
  -> pull requests
  -> code review
  -> APIs
  -> commands
  -> workflows
  -> applications
  -> automations
  -> products
```

Core rule:

```text
Agents query local mirrors first.
Generated tools expose local mirrors.
Automations run through typed commands and log everything.
```

---

## 6. River Window Manager Role

River should do:

- window placement
- tags/workspaces
- keybindings
- spawn scripts
- status-bar startup
- notification startup
- compositor-level rules

River should not do:

- long-running agents
- heavy Python workers
- capture jobs
- compiler jobs
- GitHub automation loops
- model routing daemons

Those belong in:

- systemd user services
- systemd user timers
- Go daemons
- Rust sidecars
- Python workers
- tmux/zellij sessions

Correct flow:

```text
River keybind
  -> ~/.local/bin/forge-spawn-*
    -> WezTerm/tmux/forge command
      -> Python worker / Go binary / Rust sidecar
        -> SQLite + JSONL observability
          -> Waybar/Eww/Tauri displays state
```

Incorrect flow:

```text
River directly runs giant forever scripts
```

---

## 7. River Config Files

Use:

```text
~/.config/river/init
~/.config/river/env
~/.config/river/spawn.d/
~/.config/river/rules.d/
```

Create base directories:

```bash
mkdir -p ~/.config/river/{spawn.d,rules.d}
mkdir -p ~/.forge-os/logs/river
```

### `~/.config/river/env`

```bash
cat > ~/.config/river/env <<'EOF'
export XDG_CURRENT_DESKTOP=river
export XDG_SESSION_TYPE=wayland
export MOZ_ENABLE_WAYLAND=1
export ELECTRON_OZONE_PLATFORM_HINT=wayland
export QT_QPA_PLATFORM=wayland
export GDK_BACKEND=wayland
export SDL_VIDEODRIVER=wayland
export FORGE_HOME="$HOME/.forge-os"
export FOUNDRY_ROOT="$HOME/forge-foundry"
export PATH="$HOME/.local/bin:$PATH"
EOF
```

### `~/.config/river/init`

```bash
cat > ~/.config/river/init <<'EOF'
#!/usr/bin/env sh

[ -f "$HOME/.config/river/env" ] && . "$HOME/.config/river/env"

MOD=Super

command -v rivertile >/dev/null 2>&1 && \
  rivertile -view-padding 6 -outer-padding 8 -main-ratio 0.55 \
  >"$FORGE_HOME/logs/river/rivertile.log" 2>&1 &

riverctl default-layout rivertile
riverctl border-width 2
riverctl border-color-focused 0xffd08770
riverctl border-color-unfocused 0xff3b4252

command -v waybar >/dev/null 2>&1 && waybar >"$FORGE_HOME/logs/river/waybar.log" 2>&1 &
command -v eww >/dev/null 2>&1 && eww daemon >"$FORGE_HOME/logs/river/eww.log" 2>&1 &
command -v mako >/dev/null 2>&1 && mako >"$FORGE_HOME/logs/river/mako.log" 2>&1 &

command -v wl-paste >/dev/null 2>&1 && command -v cliphist >/dev/null 2>&1 && \
  wl-paste --type text --watch cliphist store >"$FORGE_HOME/logs/river/cliphist.log" 2>&1 &

systemctl --user start forge-heartbeat.timer forge-observer.timer forge-net-watch.timer forge-fs-watch.timer 2>/dev/null || true

riverctl map normal "$MOD" Return spawn 'wezterm'
riverctl map normal "$MOD+Shift" Return spawn 'kitty'
riverctl map normal "$MOD+Alt" Return spawn 'foot'

riverctl map normal "$MOD" D spawn 'wofi --show drun'
riverctl map normal "$MOD" Space spawn 'fuzzel'

riverctl map normal "$MOD" A spawn 'forge-spawn-agents'
riverctl map normal "$MOD" O spawn 'forge-spawn-observe'
riverctl map normal "$MOD" G spawn 'forge-spawn-foundry'
riverctl map normal "$MOD" T spawn 'forge-spawn-tui'
riverctl map normal "$MOD" W spawn 'eww open forge-panel'

riverctl map normal "$MOD" B spawn 'firefox-esr'
riverctl map normal "$MOD+Shift" B spawn 'chromium'

riverctl map normal "$MOD" S spawn 'grim -g "$(slurp)" "$HOME/.forge-os/artifacts/screenshots/shot-$(date +%Y%m%d-%H%M%S).png"'

riverctl map normal "$MOD" Q close
riverctl map normal "$MOD+Shift" E spawn 'riverctl exit'
riverctl map normal "$MOD" J focus-view next
riverctl map normal "$MOD" K focus-view previous
riverctl map normal "$MOD+Shift" J swap next
riverctl map normal "$MOD+Shift" K swap previous
riverctl map normal "$MOD" F toggle-fullscreen
riverctl map normal "$MOD+Shift" Space toggle-float

for i in $(seq 1 9); do
  tags=$((1 << (i - 1)))
  riverctl map normal "$MOD" "$i" set-focused-tags "$tags"
  riverctl map normal "$MOD+Shift" "$i" set-view-tags "$tags"
done

riverctl map-pointer normal "$MOD" BTN_LEFT move-view
riverctl map-pointer normal "$MOD" BTN_RIGHT resize-view

riverctl rule-add -app-id pavucontrol float
riverctl rule-add -app-id nm-connection-editor float
riverctl rule-add -title observability tags 8
riverctl rule-add -title agent-workspace tags 2

printf '[%s] River started\n' "$(date -Iseconds)" >> "$FORGE_HOME/logs/river/session.log"
EOF

chmod +x ~/.config/river/init
```

---

## 8. Spawn Scripts

Keep River clean by using launch scripts.

```bash
cat > ~/.local/bin/forge-spawn-agents <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
cd "$HOME/forge-foundry"
forge-event desktop.spawn.agents "opening agent workspace" >/dev/null 2>&1 || true
exec wezterm start --class forge-agents -- tmux new-session -A -s forge-agents
EOF

cat > ~/.local/bin/forge-spawn-observe <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
forge-event desktop.spawn.observe "opening observability" >/dev/null 2>&1 || true
exec wezterm start --class forge-observe -- zsh -lc 'forge-observe; exec zsh'
EOF

cat > ~/.local/bin/forge-spawn-foundry <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
forge-event desktop.spawn.foundry "opening foundry root" >/dev/null 2>&1 || true
exec wezterm start --class forge-foundry --cwd "$HOME/forge-foundry" -- zsh -l
EOF

cat > ~/.local/bin/forge-spawn-tui <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
forge-event desktop.spawn.tui "opening forge tui" >/dev/null 2>&1 || true
exec wezterm start --class forge-tui -- zsh -lc 'forge-tui || echo forge-tui not installed; exec zsh'
EOF

chmod +x ~/.local/bin/forge-spawn-*
```

---

## 9. WezTerm Command Center

WezTerm should own terminal workspaces, project shells, and tmux sessions.

Config path:

```text
~/.config/wezterm/wezterm.lua
```

Install config:

```bash
mkdir -p ~/.config/wezterm
cat > ~/.config/wezterm/wezterm.lua <<'EOF'
local wezterm = require 'wezterm'
local act = wezterm.action

local config = {}

config.default_prog = { 'zsh', '-l' }
config.font = wezterm.font_with_fallback({ 'JetBrains Mono', 'Fira Code', 'Noto Color Emoji' })
config.font_size = 11.5
config.color_scheme = 'Builtin Solarized Dark'
config.window_background_opacity = 0.96
config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = false
config.use_fancy_tab_bar = false
config.audible_bell = 'Disabled'
config.scrollback_lines = 20000

config.leader = { key = 'a', mods = 'CTRL', timeout_milliseconds = 1000 }

config.keys = {
  { key = '|', mods = 'LEADER|SHIFT', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = '-', mods = 'LEADER', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },
  { key = 'h', mods = 'LEADER', action = act.ActivatePaneDirection 'Left' },
  { key = 'j', mods = 'LEADER', action = act.ActivatePaneDirection 'Down' },
  { key = 'k', mods = 'LEADER', action = act.ActivatePaneDirection 'Up' },
  { key = 'l', mods = 'LEADER', action = act.ActivatePaneDirection 'Right' },
  { key = 'c', mods = 'LEADER', action = act.SpawnTab 'CurrentPaneDomain' },
  { key = 'n', mods = 'LEADER', action = act.ActivateTabRelative(1) },
  { key = 'p', mods = 'LEADER', action = act.ActivateTabRelative(-1) },
  { key = 'f', mods = 'LEADER', action = act.SpawnCommandInNewTab { cwd = wezterm.home_dir .. '/forge-foundry', args = { 'zsh', '-lc', 'forge-observe; exec zsh' } } },
  { key = 'a', mods = 'LEADER', action = act.SpawnCommandInNewTab { cwd = wezterm.home_dir .. '/forge-foundry', args = { 'tmux', 'new-session', '-A', '-s', 'forge-agents' } } },
  { key = 'd', mods = 'LEADER', action = act.SpawnCommandInNewTab { args = { 'zsh', '-lc', 'forge-doctor; exec zsh' } } },
  { key = 't', mods = 'LEADER', action = act.SpawnCommandInNewTab { cwd = wezterm.home_dir .. '/forge-foundry', args = { 'zsh', '-lc', 'forge-tui || echo forge-tui not installed; exec zsh' } } },
}

config.launch_menu = {
  { label = 'Forge Observe', args = { 'zsh', '-lc', 'forge-observe; exec zsh' } },
  { label = 'Forge Doctor', args = { 'zsh', '-lc', 'forge-doctor; exec zsh' } },
  { label = 'Forge Agents tmux', cwd = wezterm.home_dir .. '/forge-foundry', args = { 'tmux', 'new-session', '-A', '-s', 'forge-agents' } },
  { label = 'Foundry Root', cwd = wezterm.home_dir .. '/forge-foundry', args = { 'zsh', '-l' } },
}

return config
EOF
```

---

## 10. Observability Center

The repo installer creates:

```text
~/.forge-os/observability/forge-observability.db
~/.forge-os/logs/events.jsonl
~/.forge-os/logs/model-calls.jsonl
~/.forge-os/logs/tool-calls.jsonl
~/.forge-os/logs/compiler-runs.jsonl
~/.forge-os/logs/agent-runs.jsonl
~/.forge-os/artifacts/
~/.forge-os/wiki/
```

Core commands:

```bash
forge-event manual.test "hello"
forge-model-call provider model route 10 20 300
FORGE_COMMAND="git status --short" forge-tool-call git ok 0
forge-observe
forge-doctor
```

Rule:

```text
Every model call, tool call, compiler run, automation run, and important system action must write a JSONL event and a SQLite row.
```

---

## 11. systemd User Timers

Use systemd user timers for:

- heartbeats
- watchdogs
- resource snapshots
- network snapshots
- filesystem snapshots
- stale mirror checks
- model usage reports
- repo scans

Timer/service pattern:

```text
~/.config/systemd/user/name.service
~/.config/systemd/user/name.timer
```

Example watchdog:

```bash
cat > ~/.local/bin/forge-agent-watchdog <<'EOF'
#!/usr/bin/env bash
set -Eeuo pipefail
FORGE_HOME="${FORGE_HOME:-$HOME/.forge-os}"
LOG="$FORGE_HOME/logs/watchdogs/agent-watchdog.log"
mkdir -p "$(dirname "$LOG")"
{
  echo "=== $(date -Iseconds) ==="
  tmux ls 2>/dev/null || true
  pgrep -af "agent-python|pydantic|uvicorn|mcp" || true
} >> "$LOG"
forge-event watchdog.agent.checked "agent watchdog checked" >/dev/null || true
EOF
chmod +x ~/.local/bin/forge-agent-watchdog

cat > ~/.config/systemd/user/forge-agent-watchdog.service <<'EOF'
[Unit]
Description=Forge agent watchdog

[Service]
Type=oneshot
ExecStart=%h/.local/bin/forge-agent-watchdog
EOF

cat > ~/.config/systemd/user/forge-agent-watchdog.timer <<'EOF'
[Unit]
Description=Run Forge agent watchdog every 5 minutes

[Timer]
OnBootSec=2m
OnUnitActiveSec=5m
Persistent=true

[Install]
WantedBy=timers.target
EOF

systemctl --user daemon-reload
systemctl --user enable --now forge-agent-watchdog.timer
```

List timers:

```bash
systemctl --user list-timers
```

---

## 12. Agents, Skills, and Sub-Agents

Agent folder standard:

```text
~/forge-foundry/agents/<agent-name>/
  README.md
  agent.yaml
  prompts/
  skills/
  workflows/
  tools/
  memory/
  evals/
  inbox/
  outbox/
  logs/
```

Create standard agents:

```bash
for agent in scout scribe archivist operator watcher analyst security-engineer sidecar-engineer ui-engineer cli-engineer python-worker-engineer; do
  mkdir -p ~/forge-foundry/agents/$agent/{prompts,skills,workflows,tools,memory,evals,inbox,outbox,logs}
  cat > ~/forge-foundry/agents/$agent/agent.yaml <<EOF
id: agent.$agent
name: $agent
status: draft
rules:
  - mirror_first
  - log_tool_calls
  - no_live_capture_without_approval
EOF
done
```

Agent rules:

```text
1. Query SQLite mirrors first.
2. Use generated MCP/CLI/API tools second.
3. Use local wiki third.
4. Use raw artifacts only when required.
5. Live capture requires explicit approval.
6. Log every model call and tool call.
```

---

## 13. Python Scripts and Pydantic Agents

Python belongs in services:

```text
~/forge-foundry/services/agent-python/
~/forge-foundry/services/capture-worker/
~/forge-foundry/services/compiler/
```

Setup example:

```bash
mkdir -p ~/forge-foundry/services/agent-python/{src,tests}
cd ~/forge-foundry/services/agent-python
python3 -m venv .venv
source .venv/bin/activate
pip install --upgrade pip wheel
pip install pydantic pydantic-ai fastapi uvicorn httpx rich typer sqlite-utils
```

Use Python for:

- PydanticAI agents
- schema inference
- HAR/JSON parsing
- report generation
- wiki generation
- FastMCP servers
- compiler glue

---

## 14. Go CLIs and Binaries

Go belongs in tools:

```text
~/forge-foundry/tools/forge-cli/
~/forge-foundry/tools/openapi-press/
~/forge-foundry/tools/har-press/
```

Install compiled binaries to:

```text
~/.local/bin/
```

Cobra CLI setup:

```bash
mkdir -p ~/forge-foundry/tools/forge-cli/cmd/forge
cd ~/forge-foundry/tools/forge-cli
go mod init forge-foundry/tools/forge-cli
go get github.com/spf13/cobra@latest
```

Build:

```bash
go build -o ~/.local/bin/forge ./cmd/forge
```

Go owns:

```text
forge capture ...
forge mirror ...
forge compile ...
forge agent ...
forge observe ...
forge doctor ...
forge validate ...
forge github ...
```

---

## 15. Rust Sidecars and Tauri v2

Rust belongs in:

```text
~/forge-foundry/tools/sidecars/
~/forge-foundry/apps/command-center/src-tauri/
```

Use Rust for:

- Tauri backend commands
- sidecars
- file watchers
- secure command runners
- process supervision
- system telemetry
- high-performance log ingestion

Tauri v2 architecture rule:

```text
Tauri GUI = human control surface
Rust commands = typed local control boundary
Rust sidecars = supervised local workers
Python/Go workers = heavy logic and generated tooling
SQLite/JSONL = state and observability
```

Do not put heavy scraping/capture loops directly inside the GUI.

---

## 16. Browser Profiles

Never use your personal browser profile for automation.

Use:

```text
~/.forge-os/browsers/
  personal/
  research/
  capture-authorized/
  testing/
```

Create:

```bash
mkdir -p ~/.forge-os/browsers/{personal,research,capture-authorized,testing}
```

Rules:

```text
personal browser        = human only
research browser        = docs/research
capture-authorized      = authorized capture jobs only
testing                 = local labs and dummy accounts
```

---

## 17. Security Hardening

Baseline installed by the repo modules:

- UFW
- fail2ban
- auditd
- AppArmor
- ClamAV
- unattended-upgrades
- Lynis
- AIDE
- rkhunter
- chkrootkit
- debsums
- debsecan

Check status:

```bash
sudo ufw status verbose
sudo fail2ban-client status
sudo aa-status
sudo systemctl status auditd --no-pager
clamscan --version
freshclam --version
```

Security rules:

```text
1. Raw capture artifacts are sensitive.
2. Do not promote HAR/flow data without redaction.
3. Mutating replay actions require approval.
4. Agents must not read secrets by default.
5. Browser automation uses isolated profiles.
6. Logs should store references to large/private content, not giant raw bodies.
```

---

## 18. Validation Commands

After full install:

```bash
forge-doctor
forge-observe
systemctl --user list-timers
systemctl --user status forge-heartbeat.timer forge-observer.timer forge-net-watch.timer forge-fs-watch.timer --no-pager
sudo ufw status verbose
sudo systemctl status fail2ban auditd apparmor clamav-freshclam --no-pager
```

Check files:

```bash
ls -lah ~/.forge-os
ls -lah ~/.forge-os/observability
ls -lah ~/.forge-os/logs
ls -lah ~/forge-foundry
ls -lah ~/.config/river
ls -lah ~/.config/wezterm
```

Check River config:

```bash
test -x ~/.config/river/init && echo OK
riverctl -h 2>/dev/null | head || true
```

Check database:

```bash
sqlite3 ~/.forge-os/observability/forge-observability.db '.tables'
sqlite3 ~/.forge-os/observability/forge-observability.db 'SELECT * FROM v_recent_events LIMIT 5;'
```

---

## 19. Common Failure Modes

### River starts but no bar

```bash
waybar
cat ~/.forge-os/logs/river/waybar.log
```

### River starts but no tiling

```bash
command -v rivertile
cat ~/.forge-os/logs/river/rivertile.log
```

### Spawn keybind does nothing

```bash
command -v forge-spawn-agents
bash -x ~/.local/bin/forge-spawn-agents
```

### Timers not running

```bash
systemctl --user daemon-reload
systemctl --user list-timers
loginctl enable-linger "$USER"
```

### forge commands missing

```bash
echo "$PATH"
ls -lah ~/.local/bin/forge-*
export PATH="$HOME/.local/bin:$PATH"
```

### SQLite DB missing

```bash
bash scripts/install-observability-center.sh
forge-event manual.repair "recreated observability center"
```

---

## 20. GitHub / CI / PR Automation Rules

GitHub Actions should validate:

- shell scripts with `bash -n` and shellcheck where available
- Go binaries with `go test ./...`
- Rust sidecars with `cargo check` and `cargo test`
- Python scripts with `python -m compileall` and pytest
- OpenAPI contracts
- YAML registries
- generated docs links
- redaction tests

Every PR should answer:

```text
What changed?
What files were touched?
What validation ran?
What logs/events are emitted?
What rollback exists?
What docs were updated?
```

---

## 21. Final Operating Model

Keep this mental model:

```text
River = compositor and launch keys
WezTerm = terminal command center
tmux/zellij = persistent terminal sessions
systemd user timers = scheduled local automations
Python = agents, parsers, compilers, AI glue
Go = CLIs and operator commands
Rust = sidecars and Tauri backend
Tauri = visual command center
SQLite = local source of truth
JSONL = append-only event trail
Markdown wiki = human-readable memory
Git = durable project history
```

The system is successful when a fresh agent session can understand the machine by reading:

```text
~/forge-foundry/README.md
~/forge-foundry/ARCHITECTURE.md
~/forge-foundry/ROADMAP.md
~/forge-foundry/config/
~/.forge-os/observability/forge-observability.db
~/.forge-os/logs/
```

No more mystery folders. No more untracked automation spaghetti. Everything has a home, a command, a log, a timer, a schema, and a runbook.
