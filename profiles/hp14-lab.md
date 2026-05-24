# HP14 ForgeOS Compositor Lab Profile

## Purpose

Use the HP14 Debian 13/i3WM machine as the safe compositor and agent-telemetry development station before promoting anything to the main workstation.

This machine should be treated as the ForgeOS proving ground for:

- River compositor experiments
- Sway fallback testing
- Hyprland exploration where packages/builds are practical
- WezTerm Lua terminal/multiplexer workflows
- tmux and Zellij session persistence
- local agent telemetry, token accounting, evals, and observability
- sandbox profiles for GUI and CLI agents

## Operating model

Keep i3WM installed as the stable rescue window manager. Test River/Sway/Hyprland as separate sessions so a failed compositor experiment does not kill the machine.

Recommended session order:

1. i3WM: current stable rescue environment.
2. Sway: wlroots baseline and Wayland sanity check.
3. River: command-center compositor experiments.
4. Hyprland: eye-candy/premium UX lane if hardware and packages behave.

## Best terminal stack

### Primary terminal/multiplexer

- WezTerm for Lua scripting, tabs, panes, workspaces, multiplexing, and programmable command-center UX.

### Native Wayland terminal

- Kitty for graphics protocol, kittens, fast rendering, and agent-dashboard workflows.

### Fast fallback terminal

- Alacritty as a minimal GPU terminal fallback.

### Session persistence

- tmux for universal remote/SSH persistence.
- Zellij for rich local TUI layouts.
- systemd user services for long-lived local daemons.

## Agent observability target

Track every agent run with:

- run id
- task id
- agent id
- model provider
- model name
- input tokens
- output tokens
- cached tokens when available
- estimated cost
- wall-clock latency
- tool calls
- shell commands
- files changed
- git branch/worktree
- eval result
- benchmark score
- logs
- screenshots/HARs for browser agents

## First HP14 test plan

1. Run the normal ForgeOS bootstrap.
2. Install lab terminals and session tools.
3. Enable heartbeat and observer timers.
4. Install Sway as Wayland baseline.
5. Test River in a separate session.
6. Keep i3WM as the rescue path.
7. Add token/cost accounting into the local SQLite event store.
8. Promote stable configs back into ForgeOS main workstation profile.
