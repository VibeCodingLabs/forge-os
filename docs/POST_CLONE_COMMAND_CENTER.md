# ForgeOS Post-Clone Command Center Runbook

This is the safest install order after a fresh Debian install.

## 1. Clone

```bash
sudo apt-get update
sudo apt-get install -y git ca-certificates curl

git clone https://github.com/VibeCodingLabs/forge-os.git
cd forge-os
chmod +x install.sh scripts/*.sh
```

## 2. Run preflight first

```bash
./install.sh
```

Choose:

```text
1) Preflight + disk report
```

Review disk, memory, Debian version, and network before installing the larger stack.

## 3. Install the upgraded full command center stack

```bash
bash scripts/install-full-command-center.sh
```

This wrapper installs the recovery base and then runs the upgraded modules:

- ZSH productivity shell
- River/Sway/i3 desktop command-center tooling
- Waybar
- Eww widgets
- wallpaper helper
- clipboard manager tooling
- terminal/session tools
- performance tuning
- firewall/security hardening
- ClamAV antivirus tooling
- AppArmor/audit/fail2ban baseline
- dictation/accessibility prerequisites
- Bubble Tea/Lip Gloss Go TUI
- Rich/Textual Python UI stack

## 4. Reboot

```bash
sudo reboot
```

After reboot, log in and launch River from a TTY with:

```bash
river
```

## 5. Useful commands after install

```bash
forge-tui
forge-security-report
forge-dictation-note
forge-wallpaper
```

## Notes

- Put PNG wallpapers in `~/.config/wallpapers/`.
- Run `forge-wallpaper` after adding a wallpaper.
- The dictation lane installs audio and Python prerequisites, but offline speech models should be installed manually so the installer does not download large models without review.
- Firewall defaults deny incoming traffic and allow outgoing traffic, with OpenSSH allowed.
