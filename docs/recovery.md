# ForgeOS Post-Wipe Recovery Runbook

This repo is the public recovery anchor for rebuilding a Debian-based Forge/River command center after an OS wipe.

## Fast path

```bash
sudo apt-get update
sudo apt-get install -y git ca-certificates curl

git clone https://github.com/VibeCodingLabs/forge-os.git
cd forge-os
chmod +x install.sh
./install.sh
```

## Debian installer ISO

Use the official Debian installer download page and choose the current stable amd64 netinst or DVD image. For most machines, use the amd64 netinst ISO, then install only SSH server and standard system utilities for a clean headless base.

Official source: https://www.debian.org/CD/netinst/

## Recommended install profile

- Debian stable amd64
- SSH server enabled
- Standard system utilities enabled
- No desktop environment during initial install if you want headless-first
- Create a normal user with sudo rights
- Reboot, SSH in, then run the ForgeOS clone/install flow

## Bootstrap layers

1. Base packages: git, curl, build tools, shell utilities, TUI helpers, Node, Rust, Python.
2. River/Wayland dependencies: wayland protocols, xkbcommon, evdev, pixman, scdoc, Xwayland.
3. Desktop shell: Tauri 2 prerequisites, Rust toolchain, Bun/Node package path.
4. Terminals: Kitty, Alacritty, Foot, config templates.
5. Sandboxes: bubblewrap, firejail, podman, rootless container support.
6. Orchestration: systemd user timers for heartbeat and observer loops.
7. Observability: local logs under ~/.forge-os/logs and future metrics hooks.

## Safety note

Do not put secrets into this public repo. Store tokens in local environment files, keyrings, 1Password, pass, sops, or age-encrypted files that are never committed.
