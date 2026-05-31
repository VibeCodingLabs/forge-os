# FOS-001 — `forge-install`: unified installer for .deb, .AppImage, PPA, GitHub releases

**Status:** scoped, not started
**Lane:** Command Center UX / Install layer (new)
**Estimated diff:** 600–900 LOC across `cmd/forge-install/`, `internal/installers/`, `internal/registry/`
**Estimated time:** 6–10 h focused build

---

## Goal

One unified TUI (later, optionally, a Tauri shell) that installs anything you'd want on a Debian operator workstation — `.deb` files, AppImages, third-party apt repos (the Debian equivalent of "PPAs"), and binaries from GitHub releases — with a ledger of what got installed and a single rollback path per install.

Invoked as:

```bash
forge-install         # opens the TUI
forge-install <file>  # auto-detect type, dry-run, then prompt
```

## Motivation

Today, installing a piece of software on a fresh Debian box means picking the right command per source type:

- `.deb`: `sudo apt install ./pkg.deb` (and remember to use `apt`, not `dpkg -i`, so deps resolve)
- AppImage: download, `chmod +x`, drop somewhere on `$PATH`, optionally write a `.desktop` entry, optionally register with `appimaged`
- PPA / third-party repo: write a keyring, write a sources entry in the deb822 format Debian 12+ prefers, `apt update`, `apt install <pkg>` — different commands per source
- GitHub release binary: open the releases page, find the right asset for your arch, download, extract, `chmod +x`, place on `$PATH`

Each of those is a 5-step chore with at least one footgun (wrong codename for the PPA, wrong arch asset for the release, AppImage with no desktop entry). `forge-install` makes them one TUI with one mental model.

It's also the single place where the install **ledger** lives, so post-wipe you have a queryable record of "what did I install and why?" instead of scraping `dpkg -l` + `~/.local/bin/` + `/etc/apt/sources.list.d/`.

## Out of scope (this ticket)

- Tauri / GTK desktop shell. TUI first. A graphical wrapper can layer on later if the TUI proves out.
- Snap and Flatpak. Snap is deliberately excluded (bloat + Canonical lock-in). Flatpak support may land later as a fifth source, but only if a clear use case appears.
- App **discovery** / "browse the Flathub-style catalog". This ticket is "I know what I want, install it." Discovery is a follow-up ticket if at all.
- Updating already-installed apps. Update flow is its own ticket (`FOS-002` or similar) — needs a different UX than install.
- Cross-distro support. Debian 13+ only. No Ubuntu-specific shims; no RPM.

## Source types (the contract)

### 1. `.deb` file

| Aspect | Behavior |
|---|---|
| Detection | extension `.deb` |
| Install command | `sudo apt install ./<file>` (not `dpkg -i`; lets apt resolve deps) |
| Privilege | sudo prompt once per install |
| Ledger record | `{type: deb, name, version, file_path, installed_at, sha256}` |
| Rollback | `sudo apt remove <pkg>` (apt knows the name from the install) |

### 2. `.AppImage` file

| Aspect | Behavior |
|---|---|
| Detection | extension `.AppImage` OR `file <path>` returns "ELF 64-bit ... AppImage" |
| Install command | move into `~/.local/bin/<name>`; `chmod +x`; extract icon + .desktop via `--appimage-extract-desktop`; write `.desktop` into `~/.local/share/applications/` |
| Privilege | none (user-scoped) |
| Ledger record | `{type: appimage, name, version, file_path, installed_at, sha256, desktop_file}` |
| Rollback | remove the binary + the .desktop entry |

### 3. PPA / third-party apt repo

| Aspect | Behavior |
|---|---|
| Input | one of: `ppa:user/name` shorthand; full repo URL + signing-key URL; pasted deb822 stanza |
| Translate | `ppa:user/name` → `https://ppa.launchpadcontent.net/<user>/<name>/ubuntu` with the appropriate Launchpad signing key |
| Install command | write key to `/etc/apt/keyrings/<slug>.asc`; write source to `/etc/apt/sources.list.d/<slug>.sources` (deb822 format); `sudo apt update`; if a package name was provided, `sudo apt install <pkg>` |
| Privilege | sudo prompt once per install |
| Debian-codename quirk | if the PPA targets only Ubuntu codenames, prompt the user with "this PPA targets Ubuntu noble; install anyway by overriding `Suites:`? (risky)" — never silently override |
| Ledger record | `{type: ppa, source_url, key_url, key_fingerprint, suites, components, installed_at}` |
| Rollback | remove the `.sources` file + the keyring + `sudo apt update` |

### 4. GitHub release binary

| Aspect | Behavior |
|---|---|
| Input | `owner/repo` or full release URL |
| Discovery | `gh api repos/<owner>/<repo>/releases/latest` → list assets, filter by arch (`x86_64`, `linux`, `gnu`), let user pick if ambiguous |
| Install command | download asset, verify checksum if a `*.sha256` sibling exists, untar/unzip if needed, place binary in `~/.local/bin/<name>`, `chmod +x` |
| Privilege | none (user-scoped) |
| Ledger record | `{type: github_release, owner, repo, tag, asset_name, asset_url, sha256, installed_at}` |
| Rollback | remove the binary |

## UX shape (TUI, Bubble Tea — matches existing `cmd/forge-tui` pattern)

Top-level menu:

```
forge-install
─────────────────────────────────────
  [d] install from .deb file
  [a] install from .AppImage file
  [p] add PPA / third-party apt repo
  [g] install from GitHub release
  [l] show install ledger
  [r] rollback a previous install
  [q] quit
```

Each path is a 2–4-step wizard:

1. Input (file picker, URL paste, owner/repo paste — depending on source)
2. Dry-run preview (here is the exact command, here is the file/sources entry that will be written, here is what gets sudo'd)
3. Confirm
4. Execute with streaming output in the TUI; record to ledger on success

If invoked with a single arg (`forge-install ~/Downloads/cool-app.deb`), skip step 1 — auto-detect type by extension/magic and jump straight to step 2.

## File layout

```
cmd/forge-install/
  main.go                  Bubble Tea root model + flag handling
internal/installers/
  deb.go                   apt install ./pkg.deb
  appimage.go              ~/.local/bin + .desktop integration
  apt_source.go            keyring + deb822 sources.d
  github_release.go        gh api + asset picker + download
  detect.go                source-type auto-detection from arg
internal/registry/
  ledger.go                SQLite ledger (~/.forge-os/installs.sqlite)
  schema.sql               one table: installs (id, type, name, ..., installed_at, status)
internal/privilege/
  sudo.go                  single sudo-with-explanation prompt; never silent
scripts/install-forge-install.sh
  go build → ~/.local/bin/forge-install, no further wiring
```

No new Go modules; stdlib + Bubble Tea + Lip Gloss (already in the repo's intended dep set per `COMMAND_CENTER_TASK_MAP.md` "Tauri 2 shell lane" + "Command Center UX lane").

## State + persistence

`~/.forge-os/installs.sqlite`:

```sql
CREATE TABLE IF NOT EXISTS installs (
  id           INTEGER PRIMARY KEY AUTOINCREMENT,
  type         TEXT NOT NULL CHECK (type IN ('deb','appimage','ppa','github_release')),
  name         TEXT NOT NULL,
  version      TEXT,
  source       TEXT NOT NULL,           -- file path, URL, ppa:user/name, owner/repo
  sha256       TEXT,                    -- for files; null for apt sources
  payload_json TEXT NOT NULL,           -- per-type metadata blob
  status       TEXT NOT NULL CHECK (status IN ('installed','removed','failed')),
  installed_at TEXT NOT NULL,
  removed_at   TEXT,
  notes        TEXT
);
CREATE INDEX IF NOT EXISTS idx_installs_status ON installs(status);
CREATE INDEX IF NOT EXISTS idx_installs_type   ON installs(type);
```

Driver: `modernc.org/sqlite` (pure Go, no cgo) — consistent with forge-autoresearch's choice.

## Security / privilege model (AGENTS.md alignment)

- `.deb` and PPA paths are **Tier 3** (system mutation: apt + sources.list.d). Single sudo prompt per install with the exact command shown. Never silent.
- AppImage and GitHub-release paths are **Tier 2** (user-scoped writes to `~/.local/`). No sudo.
- The "override Ubuntu codename for a PPA" path is **Tier 5** (high-impact: can brick apt). Explicit prompt with a "type the codename to confirm" gate.
- All actions log to `~/.forge-os/logs/forge-install-<date>.log` per the repo's "Watcher" / observability convention.

## Acceptance criteria

- [ ] `go build ./cmd/forge-install/` produces a working binary
- [ ] `forge-install --help` lists all four source types + the ledger + rollback subcommands
- [ ] `forge-install ~/Downloads/<some>.deb` auto-detects, dry-runs, prompts, installs, records to ledger
- [ ] `forge-install ~/Downloads/<some>.AppImage` auto-detects, writes to `~/.local/bin/`, drops a `.desktop` entry, records to ledger
- [ ] `forge-install` (no args) opens the TUI menu, all 4 source paths are reachable and complete the happy path on the dev machine
- [ ] PPA path: writes keyring + deb822 sources file, runs `apt update`, installs the named package, records to ledger
- [ ] PPA path with an Ubuntu-only codename: refuses without explicit confirmation
- [ ] GitHub release path: picks correct arch asset for `x86_64` Linux, downloads, places, marks executable, records to ledger
- [ ] Ledger `forge-install --list` shows all four install types from above with `status=installed`
- [ ] Rollback removes the file/source AND flips ledger row to `status=removed` with `removed_at` set
- [ ] `~/.forge-os/logs/forge-install-<date>.log` has timestamped entries for every install
- [ ] `forge-install --version` returns a real version string
- [ ] No silent sudo; no silent overwrites of existing files in `~/.local/bin/`
- [ ] Public-repo discipline: no embedded credentials, no real tokens in tests

## Open questions (decide before build)

1. **Should `forge-install` ALSO own update/upgrade flow** (`forge-install --update` to re-fetch latest GH release versions for all `github_release` ledger rows)? Or is that strictly a follow-up ticket?
2. **Should the ledger live in a single shared DB** (`~/.forge-os/forge.sqlite` with many tables) or its own (`installs.sqlite`)? Forge-autoresearch chose split DBs; this could go either way.
3. **AppImage desktop-integration**: do we just write `.desktop` files ourselves, or do we recommend installing `appimaged` and skip the manual integration? `appimaged` is one less thing to maintain but adds a background service.
4. **GitHub release auth**: assume `gh` CLI is installed + logged in (which forge-os already requires for clone), or do an unauthenticated fallback with stricter rate limits?
5. **Where to put rollback metadata** — should ledger record a `rollback_cmd` blob at install time (resilient to future code changes) or rebuild the command from `type + payload_json` at rollback time (always uses latest logic)?

## Cross-refs

- `AGENTS.md` — Tier system + agent roles (Operator orchestrates installs; Archivist maintains ledger; Watcher monitors logs)
- `docs/COMMAND_CENTER_TASK_MAP.md` — Command Center UX lane (where this slots in)
- `docs/MIGRATION_CHECKLIST.md` — post-wipe re-keying happens before forge-install runs; install ledger from prior box can guide what to reinstall
- `cmd/forge-tui/main.go` — the Bubble Tea pattern this should match
- `cmd/forge-enhance/main.go` — sibling binary, same stdlib-first discipline

## Follow-up tickets to file once this ships

- **FOS-002** — `forge-install --update`: re-fetch latest releases for all GH-tracked installs; offer apt-source upgrade where applicable
- **FOS-003** — `forge-install discover`: optional curated catalog of "operator essentials" (jq, ripgrep, fzf, bat, eza, lazygit, etc.) for one-click base setup post-wipe
- **FOS-004** — Tauri shell over the same TUI binary, for dock/applet users who prefer GUI to keystrokes
- **FOS-005** — Restore-from-ledger: post-wipe, point `forge-install` at a ledger JSON exported from the prior box, and have it replay the entire install history
