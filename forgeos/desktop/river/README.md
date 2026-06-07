# ForgeOS River Desktop Prep

This directory prepares ForgeOS for a River Wayland compositor setup.

River is a dynamic tiling Wayland compositor. ForgeOS should treat River as a modular desktop target, not as a hard dependency for every install.

## Goals

- Prepare package checklist for River development.
- Store a starter River config.
- Keep desktop setup separate from the AI/tool-gateway stack.
- Make the install path explicit and reviewable.

## Files

```txt
forgeos/desktop/river/
  README.md
  install-river-dev-env.txt
  config/init
```

## Suggested packages by distro family

### Arch / BlackArch / Endeavour-style

```bash
sudo pacman -S river wayland wayland-protocols wlroots foot wmenu mako grim slurp wl-clipboard xdg-desktop-portal-wlr
```

### Debian / Ubuntu / Parrot-style

River package availability varies by release. Start with Wayland dependencies:

```bash
sudo apt update
sudo apt install -y wayland-protocols foot mako-notifier grim slurp wl-clipboard xdg-desktop-portal-wlr
```

If River is not packaged for your distro release, build it from source or use a distro package source that supports your OS version.

## ForgeOS desktop rule

Do not mix River bootstrap with agent tool execution. River setup belongs under:

```txt
forgeos/desktop/river
```

Agent gateway setup belongs under:

```txt
forgeos/tool-gateway
forgeos/integrations/pi-runpod-vllm
```

## First test

After installing River, copy the config:

```bash
mkdir -p ~/.config/river
cp forgeos/desktop/river/config/init ~/.config/river/init
chmod +x ~/.config/river/init
```

Then launch River from a TTY or display manager session.
