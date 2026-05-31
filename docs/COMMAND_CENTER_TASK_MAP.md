# ForgeOS / River Command Center Task Map

## Mission

ForgeOS is the post-wipe recovery and command-center bootstrap layer for rebuilding a Debian-based AI automation workstation from a public GitHub clone.

## Recovery contract

After a clean OS install, the minimum path is:

1. Install git, curl, and certificates.
2. Clone this repository or your renamed public mirror.
3. Run `chmod +x install.sh`.
4. Run `./install.sh`.
5. Use the interactive menu to install layers.

## Setup lanes

### 1. Debian base

- Headless-first Debian install.
- SSH enabled.
- Standard utilities installed.
- No secrets committed to the repo.

### 2. River / Wayland lane

- Track River compositor dependencies.
- Install Wayland libraries, xkbcommon, libevdev, pixman, wlroots-compatible dependencies, scdoc, and Xwayland.
- Keep River build commands isolated until the exact River version and distro package availability are confirmed.

### 3. Tauri 2 shell lane

- Install Rust, Cargo, webkitgtk, ayatana appindicator, librsvg, libsoup, JavaScriptCoreGTK, Node/Bun.
- Scaffold desktop UI separately from this recovery bootstrap.
- Keep frontend app code in `apps/desktop` when ready.

### 4. Rust backend lane

- Use Rust services for local orchestration, filesystem watchers, sandbox launchers, and Tauri commands.
- Keep privileged actions behind explicit prompts and logs.

### 5. Theme system lane

- Store terminal themes under `configs/`.
- Store future app themes under `themes/`.
- Prefer okLCH design tokens for web UI work.

### 6. Agent sandboxing lane

- Default to rootless containers, bubblewrap, and explicit allowlists.
- Keep per-agent worktrees under `~/.forge-os/worktrees`.
- Keep ephemeral scratch under tmpfs when possible.
- Never mount secrets into untrusted agent sandboxes by default.

### 7. Orchestration lane

- Use systemd user services and timers for local daemons.
- Later add a Rust event bus, SQLite state store, and WebSocket bridge.
- Keep every automation observable and reversible.

### 8. Observability lane

- Heartbeat every 5 minutes.
- Observer snapshot every 15 minutes.
- Logs live under `~/.forge-os/logs`.
- State lives under `~/.forge-os/state`.

### 9. Deployment hardening lane

- Use least privilege.
- Separate public bootstrap code from private secrets.
- Add shellcheck and installer smoke tests.
- Pin risky external installers where practical.
- Document every privileged command.

## Next implementation targets

- Add a production Bubble Tea Go TUI under `cmd/forge-bootstrap`.
- Add `scripts/sandbox-run.sh` for bubblewrap profiles.
- Add `themes/forge-dark.oklch.json`.
- Add GitHub Actions for shellcheck and markdown lint.
- Add Tauri 2 app scaffold under `apps/desktop`.
- Add Rust daemon scaffold under `crates/forge-daemon`.

## Open tickets

Scoped work-in-progress items live in `docs/tickets/`. Each ticket is a
single design contract — what + why + acceptance — not the implementation.

- [FOS-001](tickets/FOS-001-forge-install-gui.md) — `forge-install`: unified TUI installer for `.deb`, `.AppImage`, PPA / third-party apt repos, and GitHub release binaries. Owns the install ledger at `~/.forge-os/installs.sqlite`. (scoped, not started)
