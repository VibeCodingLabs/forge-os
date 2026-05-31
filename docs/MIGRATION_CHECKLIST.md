# Pop!_OS → Debian 13 + River — Migration Checklist

Step-by-step for a safe wipe + clean re-install + return to operator-ready
state. Tuned for the HP14 lab station and the main workstation.

## Pre-wipe (do these BEFORE you reboot to the Debian installer)

### 1. Capture today's delta

Most data is already on `/mnt/vault/backups/phantom-<YYYY-MM-DD>-prewipe/`
from a prior `backup-rsync` run. Today is about the **delta since that
snapshot**. Specifically:

- [ ] Every git repo with uncommitted / unpushed / stash work — pushed or
      stashed-and-pushed to its remote. Run from `~`:
      ```bash
      find . -name .git -type d -prune | while read -r r; do
        p="$(dirname "$r")"
        d=$(git -C "$p" status --porcelain | wc -l)
        u=$(git -C "$p" log --branches --not --remotes --oneline | wc -l)
        s=$(git -C "$p" stash list | wc -l)
        [ "$d" -gt 0 ] || [ "$u" -gt 0 ] || [ "$s" -gt 0 ] && \
          echo "DIRTY: $p (dirty=$d unpushed=$u stash=$s)"
      done
      ```
- [ ] Anything not in a git repo that you'd cry over — copy to
      `/mnt/vault/handoff/` (survives the wipe; lives outside `~`).
- [ ] Browser bookmarks / open tabs / extensions exported. Firefox:
      Settings → Sync → confirm last sync time. Brave: about://bookmarks
      → Export.
- [ ] Active terminal `tmux` / `zellij` sessions you care about — capture
      `tmux capture-pane -pS -10000 > ~/session-<date>.txt`.

### 2. Inventory what's irreplaceable

These are small but you cannot regenerate them after a wipe:

- [ ] `~/.ssh/` — keys + known_hosts + config
- [ ] `~/.gnupg/` — GPG keys (export with `gpg --export-secret-keys --armor`
      to a file in `/mnt/vault/handoff/` rather than relying on dir copy)
- [ ] `~/.gitconfig`, `~/.netrc`, `~/.pgpass`
- [ ] `~/.config/gh/hosts.yml` — GitHub CLI auth
- [ ] `~/.aws/credentials`, `~/.docker/config.json`, `~/.kube/config`
- [ ] `~/.zsh_history`, `~/.bash_history`, `~/.python_history`
- [ ] `~/.claude/` — Claude Code memory + skills + projects state
- [ ] `~/.npmrc`, `~/.cargo/credentials.toml`, `~/.pypirc`
- [ ] Wireguard / VPN configs from `/etc/wireguard/` (root)
- [ ] Any local SQLite databases NOT under a git repo (check `find ~ -name
      "*.sqlite" -not -path "*/node_modules/*" -not -path "*/.cache/*"`)

### 3. Capture environment state for re-keying

- [ ] `gh auth status` — confirm logged-in account; you'll re-auth post-wipe
- [ ] `aws configure list-profiles` — list of profiles to recreate
- [ ] `flatpak list --app` — list of flatpaks to reinstall
- [ ] `apt list --installed > ~/apt-installed-prewipe.txt` — package list
      (move to `/mnt/vault/handoff/`)
- [ ] `dpkg --get-selections > ~/dpkg-selections-prewipe.txt`
- [ ] `code --list-extensions > ~/vscode-extensions-prewipe.txt` (if applicable)
- [ ] Browser extension list (manual: settings → extensions → screenshot)

### 4. Run the full audit one more time

```bash
bash /tmp/audit-home.sh
cat /tmp/audit-home-$(date +%Y-%m-%d).md
```

Read the **DIRTY** section carefully. Anything that's still red is
unfinished business — decide for each: commit, push, stash-to-vault, or
deliberately drop.

### 5. Confirm `/mnt/vault` mount survives

```bash
# /mnt/vault should be its own block device, not a bind mount over ~/
lsblk
findmnt /mnt/vault
```

If `/mnt/vault` is on a USB enclosure, **unplug it physically before
booting the Debian installer** so the installer can't accidentally
target the wrong disk. Re-plug after install completes.

### 6. Take a final fresh snapshot

```bash
bash backup-rsync.sh    # or your equivalent — see backup-rsync skill
# writes to /mnt/vault/backups/phantom-$(date +%Y-%m-%d-%H%M)-prewipe/
```

This is the rollback path. If anything goes wrong on Debian, you can
boot a live USB, mount /mnt/vault, and restore.

---

## During wipe / install

- [ ] Boot Debian 13 installer (netinst or live image, your call)
- [ ] **Do NOT format `/mnt/vault`**. In the partitioner, leave that
      device untouched. Only format the OS disk.
- [ ] Set hostname matching `~/.gitconfig` so signed commits stay coherent
- [ ] Skip the "additional software" picker — minimal install is best;
      ForgeOS will bring everything else.

---

## Post-wipe — first 30 minutes

### 1. Network + base tools

```bash
sudo apt-get update
sudo apt-get install -y git ca-certificates curl
```

### 2. Re-mount vault + restore irreplaceable dotfiles

```bash
sudo mkdir -p /mnt/vault
sudo mount /dev/disk/by-label/VAULT /mnt/vault   # adjust to your label
ls /mnt/vault/backups/                            # confirm snapshots present
```

Restore ONLY the small irreplaceable things first (don't sync the whole
home — let ForgeOS install the rest):

```bash
LATEST=/mnt/vault/backups/phantom-2026-05-30-prewipe   # or newer
mkdir -p ~/.ssh ~/.gnupg ~/.config/gh ~/.aws
cp -a $LATEST/.ssh/.        ~/.ssh/
cp -a $LATEST/.gnupg/.      ~/.gnupg/
cp -a $LATEST/.gitconfig    ~/
cp -a $LATEST/.config/gh/.  ~/.config/gh/
cp -a $LATEST/.aws/.        ~/.aws/
chmod 700 ~/.ssh ~/.gnupg
chmod 600 ~/.ssh/* ~/.gnupg/*
```

### 3. Clone + bootstrap ForgeOS

```bash
cd ~
git clone https://github.com/VibeCodingLabs/forge-os.git
cd forge-os
chmod +x install.sh
./install.sh
```

Pick **Minimal Recovery Base** first. Only after that smoke-tests, run
**HP14 Lab Stack** (this machine) or **Ghostnode Secure Workstation**.

### 4. Re-key

```bash
cp env.master.example ~/.env.forge
chmod 600 ~/.env.forge
# edit ~/.env.forge — fill in the keys you actually use
# (the file has sign-up URLs above each variable for the ones you forgot)
echo 'set -a; source ~/.env.forge; set +a' >> ~/.zshrc
```

Then `source ~/.zshrc` (or open a new terminal) and verify:

```bash
echo $GROQ_API_KEY  # should print your key
```

### 5. Install the prompt enhancer

```bash
bash scripts/install-forge-enhance.sh
```

Bind the global hotkey for your compositor (the installer prints the
exact recipe — copy-paste it):

- River: `riverctl map normal Super E spawn forge-enhance-popup`
- GNOME: Settings → Keyboard → Custom Shortcuts → Super+E

Test:

```bash
forge-enhance "build me a quick CLI that does X"
```

### 6. Re-clone the operator repos

The repo list lives in your GitHub account; clone what you need on demand
rather than mass-syncing:

```bash
gh auth login            # uses your restored ~/.config/gh
cd ~
gh repo clone VibeCodingLabs/forge-autoresearch
gh repo clone VibeCodingLabs/forge-symphony
# ...etc as needed
```

Anything else lives in `/mnt/vault/backups/phantom-2026-05-30-prewipe/`
and can be copied back selectively.

### 7. Sanity checks

- [ ] `git config user.email` matches your GitHub identity
- [ ] `ssh -T git@github.com` returns the expected user
- [ ] `gpg --list-secret-keys` shows your signing key
- [ ] `gh auth status` shows you logged in
- [ ] Prompt enhancer responds: `forge-enhance "test"` returns rewritten text
- [ ] Hotkey works: press Super+E, popup appears, type, result lands in
      clipboard, notification fires

If all seven pass, you're operator-ready.

---

## What you intentionally do NOT restore

These are regenerable and would just slow the restore:

- `~/.cache/`, `~/.npm`, `~/.pnpm-store/`, `~/.bun/cache/`
- All `node_modules/`, `__pycache__/`, `.venv/`, `target/`, `dist/`, `build/`
- `~/.local/share/Trash/`, `~/.local/share/flatpak/repo/`
- Browser `Cache*/`, `cache2/` dirs
- `~/snap/`, `~/google-cloud-sdk/` (reinstall via apt / official installer)

The `rsync-excludes.txt` from the audit captures all of this.

---

## If something goes wrong

1. The `/mnt/vault/backups/phantom-*-prewipe/` snapshot is your rollback.
   Boot a live USB, mount vault, copy back to a fresh home dir.
2. ForgeOS itself is on GitHub — `git clone` always works as long as you
   have `git` and a network.
3. `env.master.example` is in this repo with every sign-up URL — you can
   re-key from scratch on any machine in under an hour.
4. This checklist is in `docs/MIGRATION_CHECKLIST.md` in this repo — clone
   forge-os anywhere to re-read it.
