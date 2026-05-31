# Forge Enhance — prompt enhancer

A v0-style "Enhance prompt" button for your terminal, global hotkey, and
dock. Reads a raw prompt, rewrites it as a clearer / more specific /
better-structured prompt via a free LLM API, drops the result in your
clipboard with a desktop notification.

Designed for ForgeOS on Debian + River (and equally happy on GNOME / Sway /
Hyprland / X11).

## Three ways to use it from one binary

```bash
forge-enhance "build me a CLI that does X"          # CLI, result to stdout
echo "raw prompt" | forge-enhance --quiet --copy    # piped, result to clipboard
forge-enhance --popup --copy --notify               # popup → clipboard + toast
```

The third invocation is what the **global hotkey** (`<Super>E` by default)
and the **dock applet** (`Forge Enhance` in the launcher) both fire.

## Install

```bash
bash scripts/install-forge-enhance.sh
```

The installer:

1. Builds the Go binary into `~/.local/bin/forge-enhance`
2. Installs the popup wrapper as `~/.local/bin/forge-enhance-popup`
3. Drops the `.desktop` entry into `~/.local/share/applications/`
4. Checks for popup helper (zenity / wofi / bemenu / rofi / dmenu)
5. Checks for clipboard helper (wl-copy / xclip / xsel)
6. Checks for `notify-send` (libnotify)
7. Checks for an API key in your env (Groq / Cerebras / Gemini) or Ollama
8. Prints compositor-specific hotkey-binding instructions

## Free API providers (set the env var that matches the one you use)

Provider order (first one with a non-empty key wins; on failure, falls
through to the next):

| Provider | env var            | Sign up                                       |
|----------|--------------------|-----------------------------------------------|
| Groq     | `GROQ_API_KEY`     | https://console.groq.com/keys                 |
| Cerebras | `CEREBRAS_API_KEY` | https://cloud.cerebras.ai/                    |
| Gemini   | `GEMINI_API_KEY`   | https://aistudio.google.com/app/apikey        |
| Ollama   | (none)             | install: https://ollama.com/, runs on `:11434` |

All four are free tiers (Ollama is entirely local). Add the key to
`~/.env.forge` then `set -a; source ~/.env.forge; set +a` in your shell rc.

Override the model with `--model` or with `<NAME>_MODEL` env var:

```bash
GROQ_MODEL=llama-3.3-70b-versatile forge-enhance "..."
forge-enhance --provider cerebras --model llama-3.3-70b "..."
```

## Hotkey binding per compositor

### GNOME (Pop!_OS, Debian + GNOME, Ubuntu)
Settings → Keyboard → Custom Shortcuts → +

```
name:    forge-enhance
command: /home/$USER/.local/bin/forge-enhance-popup
binding: <Super>E
```

### River
```bash
echo 'riverctl map normal Super E spawn forge-enhance-popup' >> ~/.config/river/init
```

### Sway
```
bindsym Mod4+e exec forge-enhance-popup
```

### Hyprland
```
bind = SUPER, E, exec, forge-enhance-popup
```

## Dock applet

The installer drops `forge-enhance.desktop` into `~/.local/share/applications/`.
After `update-desktop-database` runs, it shows up as **Forge Enhance** in
your app launcher. Right-click → *Pin to favorites* (GNOME) or drag to your
dock to keep it one click away.

## The enhancement prompt

The binary ships with a fixed system prompt (`systemPrompt` in
`cmd/forge-enhance/main.go`). The rules:

- Preserve user intent and voice; don't invent new requirements
- Add structure (numbered steps, bullet acceptance criteria, explicit
  constraints) only when it helps
- Add specificity (file paths, lib names, versions) only when the original
  gave enough to infer them
- Stay tight — typically 1.5–3× the original length
- Don't answer or execute the prompt — only rewrite it
- No preamble, no "Here is the enhanced version:" — output the prompt
  directly

To customize: fork the prompt in `main.go` and rebuild. (A future revision
may load it from `~/.config/forge-enhance/system.md` for easier
customization without rebuilding.)

## Troubleshooting

| Symptom                            | Fix                                                      |
|------------------------------------|----------------------------------------------------------|
| "no input — pass a prompt..."      | You ran it with no args + no stdin + no `--popup`        |
| "no provider available"            | Set `GROQ_API_KEY` (free) or install + run `ollama serve`|
| Popup never appears (`--popup`)    | Install `zenity` (GNOME) or `wofi` (River/Sway)          |
| Clipboard copy silently fails      | Install `wl-clipboard` (Wayland) or `xclip` (X11)        |
| Notifications don't show           | Install `libnotify-bin`                                  |
| Hotkey doesn't see API key         | Source `~/.env.forge` in your DE session, not just shell |

The last one is the most common gotcha — GNOME's custom-shortcut runner
doesn't inherit your interactive shell environment. The wrapper script
(`forge-enhance-popup`) sources `~/.env.forge` itself to work around this.
