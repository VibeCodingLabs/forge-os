# ForgeOS River Command Center Task Graph

## Purpose

This document turns the ForgeOS River Command Center direction into an implementation task graph.

ForgeOS is the host layer for a secure agent workstation: Debian base, River/Sway Wayland command center, terminal/TUI installer, agent directories, workflows, skills, policies, browser workers, API capture, mirrors, observability, and a future Tauri 2 desktop command-center UI.

## Build Philosophy

- Recovery first: a fresh Debian system must be able to clone the repo and recover a working environment.
- Brand neutral: public defaults use generic ForgeOS naming.
- Safe by default: privileged actions require clear installer prompts, logs, and approval gates.
- Layered execution: stable packages first, optional source builds second, experimental lab features last.
- Observable runtime: every worker, install action, and agent run should produce logs and status events.

## Phase 0 — Documentation and Governance

### Goals

Create the canonical task map and make it clear where project truth lives.

### Tasks

- [ ] Add `docs/COMMAND_CENTER_TASK_GRAPH.md`.
- [ ] Link this document from `README.md`.
- [ ] Link this document from `ROADMAP.md` if present.
- [ ] Add or update `AGENTS.md`.
- [ ] Add or update `SECURITY.md`.
- [ ] Add or update `OBSERVABILITY.md`.
- [ ] Add or update `DEPLOYMENT.md`.
- [ ] Add document ownership table.
- [ ] Add recovery-first install notes.
- [ ] Remove hardcoded personal or private branding from public docs.

### Acceptance Gates

- [ ] A new contributor can understand the Command Center roadmap from docs alone.
- [ ] Public docs contain no private credentials, personal secrets, private screenshots, or private operational data.
- [ ] The task graph has an obvious next implementation step.

## Phase 1 — Debian Base and Recovery Installer

### Goals

Make ForgeOS usable after a full OS wipe.

### Tasks

- [ ] Keep `install.sh` as the universal entrypoint.
- [ ] Add `--dry-run` support.
- [ ] Add `--doctor` support.
- [ ] Add profile selection support.
- [ ] Add install audit log.
- [ ] Add post-install report.
- [ ] Validate APT availability and sources.
- [ ] Install base packages: `git`, `curl`, `wget`, `ca-certificates`, `gnupg`, `jq`, `yq`, `ripgrep`, `fd-find`, `fzf`, `sqlite3`, `build-essential`, `pkg-config`.
- [ ] Install runtime basics: Python, Node.js, `pnpm`, Go, Rust, SQLite.
- [ ] Add systemd user service/timer support.
- [ ] Add recovery docs.

### Acceptance Gates

- [ ] Fresh Debian user can run `bash install.sh --doctor`.
- [ ] Installer can run without destroying user data.
- [ ] Installer produces a readable action log.
- [ ] Failed installs show recovery instructions.

## Phase 2 — River and Wayland Foundation

### Goals

Install and configure a stable River command-center environment, with Sway as fallback.

### Tasks

- [ ] Add River install profile.
- [ ] Add Sway fallback profile.
- [ ] Install Wayland packages.
- [ ] Install `wayland-protocols`.
- [ ] Install `libwayland-dev`.
- [ ] Install `libwlroots-dev` or document source-build requirement.
- [ ] Install `libxkbcommon-dev`.
- [ ] Install `libevdev-dev`.
- [ ] Install `libpixman-1-dev`.
- [ ] Install `pkg-config`.
- [ ] Install `scdoc`.
- [ ] Install or pin Zig for River source builds.
- [ ] Add packaged River lane where available.
- [ ] Add River source-build lane.
- [ ] Add XWayland support.
- [ ] Add `~/.config/river/init` template.
- [ ] Add keybindings template.
- [ ] Add autostart template.
- [ ] Add monitor profile template.
- [ ] Add launcher, notification, screenshot, clipboard, and portal tools.
- [ ] Add recovery path if River fails to start.

### Known River Source Build Commands

```bash
zig build -Doptimize=ReleaseSafe --prefix ~/.local install
zig build -Doptimize=ReleaseSafe -Dxwayland --prefix ~/.local install
```

### Acceptance Gates

- [ ] River can be installed through the installer menu.
- [ ] Sway fallback remains available.
- [ ] XWayland apps can launch.
- [ ] `riverctl` can configure windows/tags at runtime.
- [ ] User can recover to a TTY or fallback session if River config breaks.

## Phase 3 — Terminal Command Layer

### Goals

Make the terminal a fast operator cockpit.

### Tasks

- [ ] Install ZSH.
- [ ] Install fast syntax highlighting.
- [ ] Install autosuggestions.
- [ ] Install completions.
- [ ] Install `fzf`.
- [ ] Install `zoxide`.
- [ ] Install `direnv`.
- [ ] Install `starship`.
- [ ] Install `eza`, `bat`, `ripgrep`, `fd`.
- [ ] Add Kitty config.
- [ ] Add Foot config.
- [ ] Add Alacritty or WezTerm optional profile.
- [ ] Add tmux/T-Max session templates.
- [ ] Add terminal logging conventions.
- [ ] Add stripped-down shell profile for agent workers.

### Acceptance Gates

- [ ] Human shell loads quickly.
- [ ] Agent worker shell avoids heavy interactive plugins.
- [ ] Terminal sessions can be restored or reattached.
- [ ] Logs can be captured without leaking secrets.

## Phase 4 — CLI/TUI Installer

### Goals

Turn ForgeOS from loose scripts into an interactive module installer.

### Tasks

- [ ] Keep bash menu fallback.
- [ ] Expand Go Bubble Tea/Lip Gloss TUI.
- [ ] Add checkbox-based profile selection.
- [ ] Add module metadata.
- [ ] Add install method labels: apt, cargo, pipx, npm, manual, source.
- [ ] Add risk labels: stable, external, experimental.
- [ ] Add disk usage estimates where practical.
- [ ] Add confirmation screen.
- [ ] Add install summary.
- [ ] Add failure summary.

### Acceptance Gates

- [ ] `forge-tui` can launch if built.
- [ ] `bin/forge-menu.sh` remains usable without Go.
- [ ] Installer never silently runs experimental installers.
- [ ] Every selected module writes status to the install log.

## Phase 5 — Tauri 2 Desktop Shell

### Goals

Create the future native command-center shell.

### Tasks

- [ ] Add Tauri 2 dependency profile.
- [ ] Install Rust via rustup.
- [ ] Install Tauri Linux prerequisites.
- [ ] Create `command-center/` scaffold or document external repo handoff.
- [ ] Add React + TypeScript + Tailwind scaffold.
- [ ] Add shadcn/ui-ready component plan.
- [ ] Add Tauri permissions plan.
- [ ] Add sidecar execution policy.
- [ ] Add local WebSocket/SSE bridge plan.
- [ ] Add dashboard layout plan.

### Acceptance Gates

- [ ] Tauri prerequisite profile completes on Debian.
- [ ] Shell architecture is documented.
- [ ] Privileged commands are not exposed directly to frontend JS.
- [ ] Sidecars require explicit allowlist entries.

## Phase 6 — Rust Backend Runtime

### Goals

Define the local command and orchestration backend.

### Tasks

- [ ] Add Rust backend architecture doc.
- [ ] Define command registry.
- [ ] Define process supervisor.
- [ ] Define job queue.
- [ ] Define event bus.
- [ ] Define SQLite state store.
- [ ] Define approval gates.
- [ ] Define audit logger.
- [ ] Define error taxonomy.
- [ ] Define service health checks.
- [ ] Define safe command execution interface.

### Acceptance Gates

- [ ] Runtime has a deny-by-default command policy.
- [ ] Every command can emit structured events.
- [ ] Jobs have status, logs, artifacts, and exit codes.
- [ ] Approvals are required for privileged actions.

## Phase 7 — Theme System

### Goals

Use one theme source for terminal, Wayland, and desktop UI.

### Tasks

- [ ] Add `themes/` directory.
- [ ] Define theme YAML schema.
- [ ] Add terminal palette export plan.
- [ ] Add Waybar color export plan.
- [ ] Add Tauri/Tailwind token export plan.
- [ ] Add light/dark variants.
- [ ] Add high contrast variant.
- [ ] Add OLED-safe dark variant.
- [ ] Keep brand-specific themes optional overlays.

### Acceptance Gates

- [ ] Base theme names are public-safe and neutral.
- [ ] Theme tokens can map to terminal and UI colors.
- [ ] Experimental themes do not break default readability.

## Phase 8 — Agent Filesystem

### Goals

Create a consistent local agent operating structure.

### Tasks

- [ ] Add `.agents/` or document generated-agent directory policy.
- [ ] Add Scribe agent.
- [ ] Add Scout agent.
- [ ] Add Courier agent.
- [ ] Add Artisan agent.
- [ ] Add Watcher agent.
- [ ] Add Archivist agent.
- [ ] Add Analyst agent.
- [ ] Add Operator agent.
- [ ] For each agent add: `AGENT.md`, `workflows/`, `skills/`, `prompts/`, `tools/`, `policies/`, `memory/`, `evals/`, `logs/`, `examples/`.
- [ ] Add `registry/agents.yaml`.
- [ ] Add permission levels.
- [ ] Add approval requirements.

### Acceptance Gates

- [ ] Each agent has a clear role.
- [ ] No agent has unrestricted host access by default.
- [ ] Agent roles map to real installer/runtime workflows.

## Phase 9 — Sandboxing and Security

### Goals

Run agent and automation tasks with clear containment.

### Tasks

- [ ] Add sandbox docs.
- [ ] Add bubblewrap profile.
- [ ] Add tmpfs workspace policy.
- [ ] Add Git worktree isolation policy.
- [ ] Add rootless Podman profile.
- [ ] Add optional Firecracker research lane.
- [ ] Add no-network mode.
- [ ] Add restricted-network mode.
- [ ] Add read-only source mount mode.
- [ ] Add denylisted host paths.
- [ ] Add secret isolation rules.
- [ ] Add approval gates for sudo, deletion, package installs, secrets, network, and systemd changes.

### Acceptance Gates

- [ ] Untrusted jobs do not run directly on host by default.
- [ ] Sandbox runs produce logs and artifacts.
- [ ] Secrets are not mounted into jobs unless explicitly approved.
- [ ] Destructive actions require human approval.

## Phase 10 — Orchestration and Event Bus

### Goals

Make ForgeOS observable and controllable through one local event model.

### Tasks

- [ ] Define event schema.
- [ ] Add JSONL event logs.
- [ ] Add SQLite event mirror.
- [ ] Add job lifecycle events.
- [ ] Add agent heartbeat events.
- [ ] Add approval events.
- [ ] Add service health events.
- [ ] Add installer events.
- [ ] Add webhook intake plan.
- [ ] Add n8n/self-hosted workflow integration plan.
- [ ] Add replay/recovery model.

### Acceptance Gates

- [ ] Jobs and installs produce structured events.
- [ ] Event logs are append-only.
- [ ] SQLite can project current status from logs.
- [ ] UI/TUI can read status without scraping terminal text.

## Phase 11 — Browser Automation and API Discovery

### Goals

Support controlled browser workers and API capture.

### Tasks

- [ ] Add Playwright install profile.
- [ ] Add Chromium/Firefox profile.
- [ ] Add Xvfb/noVNC plan for visual sessions.
- [ ] Add browser profile isolation.
- [ ] Add mitmproxy install profile.
- [ ] Add HAR capture directory.
- [ ] Add OpenAPI extraction workflow.
- [ ] Add cookie/session vault policy.
- [ ] Add approval requirements for authenticated browsing.
- [ ] Add artifact retention policy.

### Acceptance Gates

- [ ] Browser jobs run in isolated profiles.
- [ ] Captures are stored as artifacts.
- [ ] Authenticated sessions are not exposed to general agents.
- [ ] API capture workflow is documented.

## Phase 12 — Observability

### Goals

Make agent work, install work, browser work, and service work debuggable.

### Tasks

- [ ] Add `observability/` directory.
- [ ] Add structured JSONL logs.
- [ ] Add errors log.
- [ ] Add audit log.
- [ ] Add approvals log.
- [ ] Add heartbeat timer.
- [ ] Add service status summary.
- [ ] Add run history model.
- [ ] Add token/cost tracking placeholder.
- [ ] Add OpenTelemetry/Langfuse future integration notes.
- [ ] Add log redaction rules.

### Acceptance Gates

- [ ] Failures have enough context to debug.
- [ ] Logs avoid raw secret capture.
- [ ] Heartbeats show live/stale agent state.
- [ ] Dashboards can render from structured data.

## Phase 13 — Workflow UI and Command Center Panels

### Goals

Define the future dashboard surfaces.

### Tasks

- [ ] Add agent status panel spec.
- [ ] Add active jobs panel spec.
- [ ] Add approval queue spec.
- [ ] Add service health panel spec.
- [ ] Add browser session panel spec.
- [ ] Add log viewer spec.
- [ ] Add workflow graph spec.
- [ ] Add model/provider routing panel spec.
- [ ] Add install profile manager spec.
- [ ] Add theme editor spec.

### Acceptance Gates

- [ ] UI panels map to actual backend/event data.
- [ ] No panel requires reading private secrets.
- [ ] Operators can see what is running, blocked, failed, and waiting approval.

## Phase 14 — Deployment and Hardening

### Goals

Make the repo safer to run, ship, and recover.

### Tasks

- [ ] Add GitHub Actions lint workflow.
- [ ] Add shellcheck workflow.
- [ ] Add markdown lint workflow.
- [ ] Add secret scanning guidance.
- [ ] Add dependency scanning plan.
- [ ] Add SBOM generation plan.
- [ ] Add signed release plan.
- [ ] Add rollback docs.
- [ ] Add disaster recovery runbook.
- [ ] Add public/private data boundary doc.

### Acceptance Gates

- [ ] CI catches broken scripts and docs.
- [ ] Release artifacts have a verification path.
- [ ] Recovery flow is documented.
- [ ] Public repo does not require private data to bootstrap.

## Immediate Next Actions

1. Link this file from the README.
2. Convert phases into installer modules.
3. Add River profile implementation.
4. Expand `forge-tui` to read module manifests.
5. Add sandbox runner prototype.
6. Add JSONL event logger.
7. Add Tauri prerequisite profile.
8. Add observability heartbeat timer.
