// forge-enhance — a v0-style "enhance my prompt" button for the terminal,
// global hotkey, and dock applet.
//
// Reads a raw prompt from stdin, an argument, or a popup dialog. Calls a free
// LLM API to rewrite it as a clearer, more structured, more specific prompt.
// Writes the result to stdout, the clipboard, or a desktop notification.
//
// Provider order (first one with a non-empty env key wins; on failure, falls
// through to the next):
//   1. Groq         GROQ_API_KEY      https://console.groq.com/keys
//   2. Cerebras     CEREBRAS_API_KEY  https://cloud.cerebras.ai/
//   3. Google AI    GEMINI_API_KEY    https://aistudio.google.com/app/apikey
//   4. Ollama       (no key)          http://127.0.0.1:11434
//
// Designed to be invoked three ways from the same binary:
//   pe "raw prompt here"              # CLI; result to stdout
//   echo "raw" | pe                   # CLI; piped
//   pe --popup --copy --notify        # hotkey / dock; popup -> clipboard
//
// See bin/forge-enhance-popup.sh for the hotkey wrapper and
// configs/desktop/forge-enhance.desktop for the dock applet.
package main

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"flag"
	"fmt"
	"io"
	"net/http"
	"os"
	"os/exec"
	"strings"
	"time"
)

const version = "0.1.0"

const systemPrompt = `You are a Prompt Enhancer. The user will give you a raw prompt — possibly vague, telegraphic, or missing detail. Rewrite it as a clearer, more specific, better-structured prompt that an LLM or agent can act on with high confidence.

Rules:
- Preserve the user's intent and voice. Do not invent new requirements.
- Add structure only when it helps: numbered steps for multi-part requests, bullet acceptance criteria when missing, explicit constraints when implied.
- Add specificity where the original is vague (concrete file paths, library names, frameworks, versions, expected output format) ONLY if the original gave you enough to infer them.
- Keep it tight. A good enhancement is usually 1.5–3× the length of the original, not 10×.
- Do NOT answer the prompt. Do NOT execute it. Only rewrite it.
- Do NOT add a preamble like "Here is the enhanced version:". Output the enhanced prompt directly, nothing else.
- Strip nothing the user said. If they wrote "please" or used informal language, preserve their style.

Output: the enhanced prompt, and nothing else.`

// ─────────────────────────────────────────────────────────────────────────────
// Provider definitions

type apiShape int

const (
	shapeOpenAI apiShape = iota // /v1/chat/completions, OpenAI-compatible
	shapeGemini                 // Google generativelanguage v1beta
)

type provider struct {
	name    string
	envKey  string // env var holding the API key (or "" for keyless like Ollama)
	baseURL string // overridable via <NAME>_BASE_URL env var
	model   string // overridable via <NAME>_MODEL env var
	shape   apiShape
}

var providers = []provider{
	{name: "groq", envKey: "GROQ_API_KEY", baseURL: "https://api.groq.com/openai/v1", model: "llama-3.3-70b-versatile", shape: shapeOpenAI},
	{name: "cerebras", envKey: "CEREBRAS_API_KEY", baseURL: "https://api.cerebras.ai/v1", model: "llama-3.3-70b", shape: shapeOpenAI},
	{name: "gemini", envKey: "GEMINI_API_KEY", baseURL: "https://generativelanguage.googleapis.com/v1beta", model: "gemini-2.5-flash", shape: shapeGemini},
	{name: "ollama", envKey: "", baseURL: "http://127.0.0.1:11434/v1", model: "llama3.2:3b", shape: shapeOpenAI},
}

// ─────────────────────────────────────────────────────────────────────────────
// CLI

type config struct {
	popup    bool
	copyOut  bool
	notify   bool
	quiet    bool
	provider string
	model    string
	timeout  time.Duration
	input    string
}

func main() {
	cfg := parseFlags()

	text, err := readInput(cfg)
	if err != nil {
		die(err)
	}
	if strings.TrimSpace(text) == "" {
		die(errors.New("empty prompt"))
	}

	ctx, cancel := context.WithTimeout(context.Background(), cfg.timeout)
	defer cancel()

	enhanced, usedProvider, err := enhance(ctx, text, cfg)
	if err != nil {
		if cfg.notify {
			_ = sendNotify("forge-enhance failed", err.Error())
		}
		die(err)
	}

	if cfg.copyOut {
		if err := copyClipboard(enhanced); err != nil {
			fmt.Fprintf(os.Stderr, "forge-enhance: clipboard copy failed: %v\n", err)
		}
	}
	if cfg.notify {
		preview := enhanced
		if len(preview) > 200 {
			preview = preview[:200] + "…"
		}
		_ = sendNotify(fmt.Sprintf("Enhanced via %s", usedProvider), preview)
	}
	if !cfg.quiet {
		fmt.Println(enhanced)
	}
}

func parseFlags() config {
	var cfg config
	flag.BoolVar(&cfg.popup, "popup", false, "open a GUI popup to enter the prompt (zenity / wofi / bemenu)")
	flag.BoolVar(&cfg.copyOut, "copy", false, "copy the enhanced prompt to the clipboard")
	flag.BoolVar(&cfg.notify, "notify", false, "send a desktop notification with a preview of the result")
	flag.BoolVar(&cfg.quiet, "quiet", false, "suppress stdout (use with --copy or --notify)")
	flag.StringVar(&cfg.provider, "provider", "", "force a specific provider (groq|cerebras|gemini|ollama). default: first with a key")
	flag.StringVar(&cfg.model, "model", "", "override the model id for the chosen provider")
	flag.DurationVar(&cfg.timeout, "timeout", 30*time.Second, "request timeout")

	showVersion := flag.Bool("version", false, "print version and exit")
	flag.Usage = func() {
		fmt.Fprintf(os.Stderr, `forge-enhance %s — v0-style prompt enhancer

Usage:
  forge-enhance [flags] [prompt]
  echo "raw prompt" | forge-enhance [flags]
  forge-enhance --popup --copy --notify          # hotkey / dock mode

Flags:
`, version)
		flag.PrintDefaults()
		fmt.Fprintf(os.Stderr, `
Providers (free tiers — set the env var that matches the provider you want):
  GROQ_API_KEY       https://console.groq.com/keys
  CEREBRAS_API_KEY   https://cloud.cerebras.ai/
  GEMINI_API_KEY     https://aistudio.google.com/app/apikey
  (Ollama needs no key; runs on http://127.0.0.1:11434)

Examples:
  forge-enhance "build me a CLI that does X"
  cat prompt.md | forge-enhance --quiet --copy
  forge-enhance --popup --copy --notify   # bind to Super+E
`)
	}
	flag.Parse()

	if *showVersion {
		fmt.Println(version)
		os.Exit(0)
	}

	if args := flag.Args(); len(args) > 0 {
		cfg.input = strings.Join(args, " ")
	}
	return cfg
}

func readInput(cfg config) (string, error) {
	if cfg.input != "" {
		return cfg.input, nil
	}
	if cfg.popup {
		return popupInput()
	}
	stat, _ := os.Stdin.Stat()
	if (stat.Mode() & os.ModeCharDevice) == 0 {
		b, err := io.ReadAll(os.Stdin)
		if err != nil {
			return "", err
		}
		return string(b), nil
	}
	return "", errors.New("no input — pass a prompt as an argument, pipe via stdin, or use --popup")
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider routing + HTTP

func enhance(ctx context.Context, text string, cfg config) (string, string, error) {
	chosen := selectProviders(cfg.provider)
	if len(chosen) == 0 {
		return "", "", errors.New("no provider available: set GROQ_API_KEY (or CEREBRAS_API_KEY / GEMINI_API_KEY) — or install + run Ollama")
	}

	var lastErr error
	for _, p := range chosen {
		if cfg.model != "" {
			p.model = cfg.model
		}
		if v := os.Getenv(strings.ToUpper(p.name) + "_BASE_URL"); v != "" {
			p.baseURL = v
		}
		if v := os.Getenv(strings.ToUpper(p.name) + "_MODEL"); v != "" {
			p.model = v
		}
		out, err := callProvider(ctx, p, text)
		if err == nil {
			return out, p.name, nil
		}
		lastErr = fmt.Errorf("%s: %w", p.name, err)
		if !cfg.quiet {
			fmt.Fprintf(os.Stderr, "forge-enhance: %s failed, trying next provider — %v\n", p.name, err)
		}
	}
	return "", "", fmt.Errorf("all providers failed; last error: %w", lastErr)
}

func selectProviders(forced string) []provider {
	if forced != "" {
		for _, p := range providers {
			if p.name == forced {
				return []provider{p}
			}
		}
		return nil
	}
	out := make([]provider, 0, len(providers))
	for _, p := range providers {
		if p.envKey == "" || os.Getenv(p.envKey) != "" {
			out = append(out, p)
		}
	}
	return out
}

func callProvider(ctx context.Context, p provider, text string) (string, error) {
	switch p.shape {
	case shapeOpenAI:
		return callOpenAICompat(ctx, p, text)
	case shapeGemini:
		return callGemini(ctx, p, text)
	}
	return "", fmt.Errorf("unknown provider shape for %s", p.name)
}

type openAIRequest struct {
	Model       string          `json:"model"`
	Messages    []openAIMessage `json:"messages"`
	Temperature float64         `json:"temperature"`
	Stream      bool            `json:"stream"`
}
type openAIMessage struct {
	Role    string `json:"role"`
	Content string `json:"content"`
}
type openAIResponse struct {
	Choices []struct {
		Message openAIMessage `json:"message"`
	} `json:"choices"`
	Error *struct {
		Message string `json:"message"`
	} `json:"error,omitempty"`
}

func callOpenAICompat(ctx context.Context, p provider, text string) (string, error) {
	body := openAIRequest{
		Model: p.model,
		Messages: []openAIMessage{
			{Role: "system", Content: systemPrompt},
			{Role: "user", Content: text},
		},
		Temperature: 0.4,
	}
	buf, _ := json.Marshal(body)
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, p.baseURL+"/chat/completions", bytes.NewReader(buf))
	if err != nil {
		return "", err
	}
	req.Header.Set("Content-Type", "application/json")
	if p.envKey != "" {
		key := os.Getenv(p.envKey)
		if key == "" {
			return "", fmt.Errorf("%s not set", p.envKey)
		}
		req.Header.Set("Authorization", "Bearer "+key)
	}
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()
	rb, _ := io.ReadAll(resp.Body)
	if resp.StatusCode >= 400 {
		return "", fmt.Errorf("http %d: %s", resp.StatusCode, truncate(string(rb), 300))
	}
	var out openAIResponse
	if err := json.Unmarshal(rb, &out); err != nil {
		return "", fmt.Errorf("decode: %w", err)
	}
	if out.Error != nil {
		return "", errors.New(out.Error.Message)
	}
	if len(out.Choices) == 0 {
		return "", errors.New("no choices in response")
	}
	return strings.TrimSpace(out.Choices[0].Message.Content), nil
}

type geminiRequest struct {
	Contents          []geminiContent      `json:"contents"`
	SystemInstruction *geminiContent       `json:"systemInstruction,omitempty"`
	GenerationConfig  geminiGenerationConf `json:"generationConfig"`
}
type geminiContent struct {
	Parts []geminiPart `json:"parts"`
	Role  string       `json:"role,omitempty"`
}
type geminiPart struct {
	Text string `json:"text"`
}
type geminiGenerationConf struct {
	Temperature float64 `json:"temperature"`
}
type geminiResponse struct {
	Candidates []struct {
		Content geminiContent `json:"content"`
	} `json:"candidates"`
	Error *struct {
		Message string `json:"message"`
	} `json:"error,omitempty"`
}

func callGemini(ctx context.Context, p provider, text string) (string, error) {
	key := os.Getenv(p.envKey)
	if key == "" {
		return "", fmt.Errorf("%s not set", p.envKey)
	}
	body := geminiRequest{
		SystemInstruction: &geminiContent{Parts: []geminiPart{{Text: systemPrompt}}},
		Contents:          []geminiContent{{Role: "user", Parts: []geminiPart{{Text: text}}}},
		GenerationConfig:  geminiGenerationConf{Temperature: 0.4},
	}
	buf, _ := json.Marshal(body)
	url := fmt.Sprintf("%s/models/%s:generateContent?key=%s", p.baseURL, p.model, key)
	req, err := http.NewRequestWithContext(ctx, http.MethodPost, url, bytes.NewReader(buf))
	if err != nil {
		return "", err
	}
	req.Header.Set("Content-Type", "application/json")
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		return "", err
	}
	defer resp.Body.Close()
	rb, _ := io.ReadAll(resp.Body)
	if resp.StatusCode >= 400 {
		return "", fmt.Errorf("http %d: %s", resp.StatusCode, truncate(string(rb), 300))
	}
	var out geminiResponse
	if err := json.Unmarshal(rb, &out); err != nil {
		return "", fmt.Errorf("decode: %w", err)
	}
	if out.Error != nil {
		return "", errors.New(out.Error.Message)
	}
	if len(out.Candidates) == 0 || len(out.Candidates[0].Content.Parts) == 0 {
		return "", errors.New("no candidates in response")
	}
	return strings.TrimSpace(out.Candidates[0].Content.Parts[0].Text), nil
}

func truncate(s string, n int) string {
	if len(s) <= n {
		return s
	}
	return s[:n] + "…"
}

// ─────────────────────────────────────────────────────────────────────────────
// Desktop integration

// popupInput opens a GUI text dialog. Tries zenity (X11 + Wayland on GNOME),
// then wofi (River / Sway / Hyprland), then bemenu (any wlroots compositor).
// Reads what the user typed and returns it.
func popupInput() (string, error) {
	candidates := []struct {
		bin  string
		args []string
	}{
		{"zenity", []string{"--entry", "--title=forge-enhance", "--text=Prompt to enhance:", "--width=600"}},
		{"yad", []string{"--entry", "--title=forge-enhance", "--text=Prompt to enhance:", "--width=600"}},
		{"wofi", []string{"--dmenu", "--prompt=Enhance:"}},
		{"bemenu", []string{"-p", "Enhance:", "-l", "0"}},
		{"rofi", []string{"-dmenu", "-p", "Enhance"}},
		{"dmenu", []string{"-p", "Enhance:"}},
	}
	for _, c := range candidates {
		if _, err := exec.LookPath(c.bin); err != nil {
			continue
		}
		cmd := exec.Command(c.bin, c.args...)
		cmd.Stdin = strings.NewReader("")
		out, err := cmd.Output()
		if err != nil {
			// User cancelled — return empty (caller will treat as no input).
			return "", err
		}
		return strings.TrimRight(string(out), "\n"), nil
	}
	return "", errors.New("no popup helper found (install zenity, yad, wofi, bemenu, rofi, or dmenu)")
}

// copyClipboard tries wl-copy first (Wayland), then xclip, then xsel.
func copyClipboard(text string) error {
	candidates := []struct {
		bin  string
		args []string
	}{
		{"wl-copy", nil},
		{"xclip", []string{"-selection", "clipboard"}},
		{"xsel", []string{"--clipboard", "--input"}},
	}
	for _, c := range candidates {
		if _, err := exec.LookPath(c.bin); err != nil {
			continue
		}
		cmd := exec.Command(c.bin, c.args...)
		cmd.Stdin = strings.NewReader(text)
		if err := cmd.Run(); err == nil {
			return nil
		}
	}
	return errors.New("no clipboard helper found (install wl-clipboard, xclip, or xsel)")
}

// sendNotify uses notify-send (libnotify) for a desktop notification.
func sendNotify(title, body string) error {
	if _, err := exec.LookPath("notify-send"); err != nil {
		return err
	}
	return exec.Command("notify-send",
		"--app-name=forge-enhance",
		"--expire-time=5000",
		title,
		body,
	).Run()
}

func die(err error) {
	fmt.Fprintf(os.Stderr, "forge-enhance: %v\n", err)
	os.Exit(1)
}
