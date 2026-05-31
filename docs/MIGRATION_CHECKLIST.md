# Pop!_OS → Debian 13 + River — Migration Checklist

## Mental model

This is **not a restore**. The plan is:

1. **Archive** the old system to `/mnt/vault/` (one final snapshot)
2. **Wipe** the OS disk and install Debian 13 cleanly
3. **Bootstrap** fresh: clone `forge-os`, run `install.sh`, re-key, done
4. **Mine the archive later** — when you actually want something from the
   old box, you reach into vault and pull just that one thing. You do
   *not* sync your old home back. The bloat stays in vault.

The vault snapshot is a **museum**, not a backup-you-restore-from. It's
there so you can find old files when you need them, not so you can
recreate the old chaos on the new machine.

---

## Before the wipe

### 1. Take one final delta snapshot to vault

```bash
bash backup-rsync.sh    # writes to /mnt/vault/backups/phantom-$(date +%Y-%m-%d-%H%M)-prewipe/
```

Today's delta (anything that happened since
`/mnt/vault/backups/phantom-2026-05-30-prewipe/`) lands in vault and is
preserved forever. This is the *only* archive step — everything else is
already in earlier snapshots.

### 2. Export the 2-3 things that genuinely can't be regenerated

Most "irreplaceable" stuff (gh auth, AWS profiles, npm tokens, etc.) is
easier to re-auth fresh than to carefully copy across machines. The
exceptions — actual cryptographic material you generated yourself — go
into a small handoff dir:

```bash
mkdir -p /mnt/vault/handoff
cp -a ~/.ssh                       /mnt/vault/handoff/    # private SSH keys
gpg --export-secret-keys --armor > /mnt/vault/handoff/gpg-secret-keys.asc
gpg --export-ownertrust          > /mnt/vault/handoff/gpg-ownertrust.txt
chmod 600 /mnt/vault/handoff/gpg-* /mnt/vault/handoff/.ssh/*
```

Anything else (`.gitconfig`, `.zshrc`, browser bookmarks, dotfiles in
general) is small enough to **rewrite intentionally on the new system**
or pull selectively from the snapshot later. Don't pre-stage it.

### 3. Confirm vault is its own block device (won't be wiped)

```bash
findmnt /mnt/vault          # confirm it's a separate device, not a bind mount
lsblk                       # confirm which device the OS is on vs vault
```

If `/mnt/vault` is on a USB enclosure, **physically unplug it before
booting the installer** so the partitioner can't see it. Re-plug after
Debian is installed and you're logged in.

### 4. (Optional) Push any forge-os / forge-autoresearch work-in-progress

Today's work is already on GitHub — `forge-os` is at commit `feb73fc` on
main, and the three forge-autoresearch PRs (#1, #2, #3) are pushed. If
you've made any uncommitted edits since reading this, `git push` them
now so they don't need to be mined from vault later.

---

## During the wipe

- [ ] Boot Debian 13 installer (netinst is fine)
- [ ] **Do NOT format `/mnt/vault`**. In the partitioner, the OS disk is
      the only target. Leave the vault device untouched.
- [ ] Skip the "additional software" picker. Minimal install. ForgeOS
      brings the rest.
- [ ] Set the hostname you actually want — this is a clean-slate moment,
      pick something deliberate.

---

## After the wipe — operator-ready in ~30 min

### 1. Base tools

```bash
sudo apt update && sudo apt install -y git ca-certificates curl
```

### 2. Re-mount vault (read-only is safest until you trust the new env)

```bash
sudo mkdir -p /mnt/vault
sudo mount -o ro /dev/disk/by-label/VAULT /mnt/vault    # adjust label
ls /mnt/vault/backups/                                  # confirm snapshots present
ls /mnt/vault/handoff/                                  # confirm SSH + GPG export
```

### 3. Bring back ONLY the cryptographic essentials

```bash
mkdir -p ~/.ssh && chmod 700 ~/.ssh
sudo cp -a /mnt/vault/handoff/.ssh/. ~/.ssh/
sudo chown -R $USER:$USER ~/.ssh
chmod 600 ~/.ssh/*

gpg --import /mnt/vault/handoff/gpg-secret-keys.asc
gpg --import-ownertrust /mnt/vault/handoff/gpg-ownertrust.txt
```

That's it for "restore." Everything else, you re-auth fresh.

### 4. Clone + bootstrap forge-os

```bash
cd ~ && git clone https://github.com/VibeCodingLabs/forge-os.git
cd forge-os && chmod +x install.sh && ./install.sh
```

Pick **Minimal Recovery Base** first. Only after that smoke-tests, run
**HP14 Lab Stack** or the workstation profile.

### 5. Re-key from the master env catalog

```bash
cp env.master.example ~/.env.forge
chmod 600 ~/.env.forge
$EDITOR ~/.env.forge          # fill in only the keys you actively use
                              # (the file has sign-up URLs above every var)
echo 'set -a; source ~/.env.forge; set +a' >> ~/.zshrc
```

This is the deliberate part — you're choosing which providers come
forward, not inheriting all 75 from the old box.

### 6. Install the prompt enhancer

```bash
bash scripts/install-forge-enhance.sh
# then bind the global hotkey per the installer's printed instructions
# River:  riverctl map normal Super E spawn forge-enhance-popup
# GNOME:  Settings → Keyboard → Custom Shortcuts → Super+E
```

### 7. Re-auth fresh (do NOT copy old configs back)

```bash
gh auth login                       # new session, new device approval
aws configure --profile <name>      # only the profiles you actually use
npm login                           # only if publishing
gcloud auth login                   # only if using GCP
flatpak remote-add --user --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
```

Skip everything you don't actively use. The point of starting fresh is
not auto-restoring credentials for services you've drifted away from.

### 8. Sanity checks

- [ ] `ssh -T git@github.com` returns the expected user
- [ ] `gpg --list-secret-keys` shows your signing key
- [ ] `gh auth status` shows you logged in
- [ ] `forge-enhance "test prompt"` returns rewritten text
- [ ] Super+E hotkey opens the popup, result lands in clipboard

If all five pass, you're operator-ready on a clean machine.

---

## Mining the archive (do this later, on demand)

The vault snapshot at `/mnt/vault/backups/phantom-<date>-prewipe/` is
your museum. When you remember "wait, I wrote a script that did X" or
"that one tmux config I liked":

```bash
# search the archive by name
find /mnt/vault/backups/phantom-2026-05-30-prewipe/ -iname '*tmux*' -type f
find /mnt/vault/backups/phantom-2026-05-30-prewipe/ -iname '*<thing>*'

# search the archive by content
grep -r --include='*.sh' 'function-name' /mnt/vault/backups/phantom-*-prewipe/

# pull one specific thing forward
cp -a /mnt/vault/backups/phantom-2026-05-30-prewipe/.config/<thing> ~/.config/
```

**The rule**: bring something forward only if you've consciously decided
you want it on the new system. If you haven't touched it in 6 months,
leaving it in vault is the right call. The whole point of the wipe is
not re-importing things on autopilot.

When you find something genuinely worth bringing forward as a *pattern*
(not just a file), promote it: copy it into a `forge-os` config under
`configs/`, commit it, push it. That way it ships with the next bootstrap.

---

## If something goes wrong

- **Lost a credential**: vault snapshot has it; mount and dig
- **Broke the new OS during install.sh**: re-run `./install.sh` (idempotent)
- **Vault didn't mount on first boot**: `lsblk`, find the label, `sudo
  mount /dev/disk/by-label/VAULT /mnt/vault`
- **Need something from yesterday's work**: GitHub has all of today's
  forge-os + forge-autoresearch commits; just `gh repo clone`
- **This checklist itself**: `git clone
  https://github.com/VibeCodingLabs/forge-os.git` from any machine
