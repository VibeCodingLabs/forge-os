// forge-agent-obs — Bubble Tea TUI for real-time agent call observability.
//
// Reads $FORGE_HOME/logs/agent-calls.jsonl and displays a live multi-pane dashboard:
//
//   Left pane  — scrollable call list (timestamp, agent, provider, status, latency)
//   Right pane — detail view of selected call (full fields + input/output previews)
//   Bottom bar — stats: total calls, ok/error counts, avg latency, provider breakdown
//   Header bar — filter bar (type to filter by agent/provider/status)
//
// Keybindings:
//   j/k or ↑↓   navigate list
//   /           enter filter mode
//   Esc         clear filter
//   r           reload log from disk
//   t           toggle tail mode (auto-scroll to newest)
//   e           export filtered view to ~/.forge-os/logs/agent-calls-export-<ts>.jsonl
//   d           toggle detail pane
//   q / Ctrl+C  quit
package main

import (
	"bufio"
	"encoding/json"
	"fmt"
	"math"
	"os"
	"path/filepath"
	"strings"
	"time"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

// ─────────────────────────────────────────────────────────────────────────────
// Data model (must match forge-enhance AgentCallRecord)

type CallStatus string

const (
	StatusOK      CallStatus = "ok"
	StatusError   CallStatus = "error"
	StatusTimeout CallStatus = "timeout"
)

type CallRecord struct {
	ID              string     `json:"id"`
	Timestamp       string     `json:"timestamp"`
	Agent           string     `json:"agent"`
	Provider        string     `json:"provider"`
	Model           string     `json:"model"`
	Status          CallStatus `json:"status"`
	DurationMS      int64      `json:"duration_ms"`
	TotalDurationMS int64      `json:"total_duration_ms"`
	InputTokens     int        `json:"input_tokens"`
	OutputTokens    int        `json:"output_tokens"`
	InputLen        int        `json:"input_len"`
	OutputLen       int        `json:"output_len"`
	HTTPStatus      int        `json:"http_status"`
	ErrorMsg        string     `json:"error_msg,omitempty"`
	FallbackCount   int        `json:"fallback_count"`
	InputPreview    string     `json:"input_preview"`
	OutputPreview   string     `json:"output_preview,omitempty"`
	Host            string     `json:"host"`
	User            string     `json:"user"`
	Mode            string     `json:"mode"`
}

// ─────────────────────────────────────────────────────────────────────────────
// Styles

var (
	colorAccent  = lipgloss.Color("205")
	colorCyan    = lipgloss.Color("51")
	colorGreen   = lipgloss.Color("42")
	colorRed     = lipgloss.Color("196")
	colorYellow  = lipgloss.Color("220")
	colorMuted   = lipgloss.Color("245")
	colorWhite   = lipgloss.Color("252")
	colorBg      = lipgloss.Color("235")
	colorBgSel   = lipgloss.Color("238")

	styleTitle = lipgloss.NewStyle().
			Bold(true).Foreground(colorAccent).
			BorderStyle(lipgloss.NormalBorder()).
			BorderBottom(true).BorderForeground(colorCyan).
			PaddingLeft(1).MarginBottom(0)

	styleHeader = lipgloss.NewStyle().
			Bold(true).Foreground(colorCyan).PaddingLeft(1)

	styleRowNormal = lipgloss.NewStyle().
			Foreground(colorWhite).PaddingLeft(1)

	styleRowSelected = lipgloss.NewStyle().
			Bold(true).Foreground(colorCyan).
			Background(colorBgSel).PaddingLeft(1)

	styleOK      = lipgloss.NewStyle().Bold(true).Foreground(colorGreen)
	styleError   = lipgloss.NewStyle().Bold(true).Foreground(colorRed)
	styleTimeout = lipgloss.NewStyle().Bold(true).Foreground(colorYellow)
	styleMuted   = lipgloss.NewStyle().Foreground(colorMuted)
	styleLabel   = lipgloss.NewStyle().Bold(true).Foreground(colorCyan)
	styleValue   = lipgloss.NewStyle().Foreground(colorWhite)

	stylePane = lipgloss.NewStyle().
			Border(lipgloss.RoundedBorder()).BorderForeground(colorCyan).
			Padding(0, 1)

	styleFilterActive = lipgloss.NewStyle().
			Bold(true).Foreground(colorYellow).
			Border(lipgloss.NormalBorder()).BorderForeground(colorYellow).
			PaddingLeft(1)

	styleStatusBar = lipgloss.NewStyle().
			Background(lipgloss.Color("236")).Foreground(colorMuted).
			PaddingLeft(1).PaddingRight(1)
)

// ─────────────────────────────────────────────────────────────────────────────
// Messages

type tickMsg time.Time
type reloadMsg []CallRecord

// ─────────────────────────────────────────────────────────────────────────────
// Model

type mode int

const (
	modeNormal mode = iota
	modeFilter
)

type Model struct {
	// data
	allRecords      []CallRecord
	filteredRecords []CallRecord
	logPath         string

	// navigation
	cursor     int
	scrollTop  int // first visible row in list

	// layout
	width      int
	height     int
	showDetail bool

	// filter
	currentMode mode
	filterText  string

	// tail mode
	tailMode bool

	// status
	lastReload time.Time
	status     string
}

func logPath() string {
	forgeHome := os.Getenv("FORGE_HOME")
	if forgeHome == "" {
		h, _ := os.UserHomeDir()
		forgeHome = filepath.Join(h, ".forge-os")
	}
	return filepath.Join(forgeHome, "logs", "agent-calls.jsonl")
}

func loadRecords(path string) ([]CallRecord, error) {
	f, err := os.Open(path)
	if err != nil {
		if os.IsNotExist(err) {
			return nil, nil
		}
		return nil, err
	}
	defer f.Close()

	var records []CallRecord
	scanner := bufio.NewScanner(f)
	scanner.Buffer(make([]byte, 1024*1024), 1024*1024)
	for scanner.Scan() {
		line := strings.TrimSpace(scanner.Text())
		if line == "" {
			continue
		}
		var r CallRecord
		if err := json.Unmarshal([]byte(line), &r); err != nil {
			continue // skip malformed lines
		}
		records = append(records, r)
	}
	return records, scanner.Err()
}

func applyFilter(records []CallRecord, filter string) []CallRecord {
	if filter == "" {
		return records
	}
	f := strings.ToLower(filter)
	out := make([]CallRecord, 0)
	for _, r := range records {
		if strings.Contains(strings.ToLower(r.Agent), f) ||
			strings.Contains(strings.ToLower(r.Provider), f) ||
			strings.Contains(strings.ToLower(string(r.Status)), f) ||
			strings.Contains(strings.ToLower(r.Model), f) ||
			strings.Contains(strings.ToLower(r.Mode), f) ||
			strings.Contains(strings.ToLower(r.InputPreview), f) ||
			strings.Contains(strings.ToLower(r.ErrorMsg), f) {
			out = append(out, r)
		}
	}
	return out
}

func initialModel() Model {
	p := logPath()
	recs, err := loadRecords(p)
	status := fmt.Sprintf("loaded %d records", len(recs))
	if err != nil {
		status = fmt.Sprintf("error loading: %v", err)
	}
	filt := applyFilter(recs, "")
	return Model{
		allRecords:      recs,
		filteredRecords: filt,
		logPath:         p,
		showDetail:      true,
		tailMode:        true,
		lastReload:      time.Now(),
		status:          status,
		cursor:          max(0, len(filt)-1),
	}
}

func max(a, b int) int {
	if a > b {
		return a
	}
	return b
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}

// ─────────────────────────────────────────────────────────────────────────────
// Bubbletea lifecycle

func (m Model) Init() tea.Cmd {
	return tea.Batch(
		tea.EnterAltScreen,
		tickCmd(),
	)
}

func tickCmd() tea.Cmd {
	return tea.Tick(3*time.Second, func(t time.Time) tea.Msg {
		return tickMsg(t)
	})
}

func doReload(path string) tea.Cmd {
	return func() tea.Msg {
		recs, _ := loadRecords(path)
		return reloadMsg(recs)
	}
}

func (m Model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {

	case tea.WindowSizeMsg:
		m.width = msg.Width
		m.height = msg.Height
		return m, nil

	case tickMsg:
		return m, tea.Batch(doReload(m.logPath), tickCmd())

	case reloadMsg:
		m.allRecords = []CallRecord(msg)
		m.filteredRecords = applyFilter(m.allRecords, m.filterText)
		m.lastReload = time.Now()
		m.status = fmt.Sprintf("auto-reloaded %d records (%d filtered)", len(m.allRecords), len(m.filteredRecords))
		if m.tailMode && len(m.filteredRecords) > 0 {
			m.cursor = len(m.filteredRecords) - 1
		}
		return m, nil

	case tea.KeyMsg:
		return m.handleKey(msg)
	}
	return m, nil
}

func (m Model) handleKey(msg tea.KeyMsg) (tea.Model, tea.Cmd) {
	if m.currentMode == modeFilter {
		switch msg.String() {
		case "esc":
			m.currentMode = modeNormal
			m.filterText = ""
			m.filteredRecords = applyFilter(m.allRecords, "")
			m.cursor = max(0, len(m.filteredRecords)-1)
		case "enter":
			m.currentMode = modeNormal
			m.filteredRecords = applyFilter(m.allRecords, m.filterText)
			m.cursor = 0
			if len(m.filteredRecords) > 0 {
				m.cursor = len(m.filteredRecords) - 1
			}
		case "backspace":
			if len(m.filterText) > 0 {
				m.filterText = m.filterText[:len(m.filterText)-1]
			}
		default:
			if len(msg.Runes) > 0 {
				m.filterText += string(msg.Runes)
			}
		}
		return m, nil
	}

	// normal mode
	switch msg.String() {
	case "ctrl+c", "q":
		return m, tea.Quit

	case "up", "k":
		if m.cursor > 0 {
			m.cursor--
			m.tailMode = false
		}

	case "down", "j":
		if m.cursor < len(m.filteredRecords)-1 {
			m.cursor++
		}

	case "g":
		m.cursor = 0
		m.tailMode = false

	case "G":
		m.cursor = max(0, len(m.filteredRecords)-1)
		m.tailMode = true

	case "/":
		m.currentMode = modeFilter
		m.filterText = ""

	case "esc":
		m.filterText = ""
		m.filteredRecords = applyFilter(m.allRecords, "")
		m.cursor = max(0, len(m.filteredRecords)-1)

	case "r":
		return m, doReload(m.logPath)

	case "t":
		m.tailMode = !m.tailMode
		if m.tailMode && len(m.filteredRecords) > 0 {
			m.cursor = len(m.filteredRecords) - 1
		}

	case "d":
		m.showDetail = !m.showDetail

	case "e":
		m.status = m.exportFiltered()
	}

	return m, nil
}

func (m *Model) exportFiltered() string {
	forgeHome := os.Getenv("FORGE_HOME")
	if forgeHome == "" {
		h, _ := os.UserHomeDir()
		forgeHome = filepath.Join(h, ".forge-os")
	}
	out := filepath.Join(forgeHome, "logs",
		fmt.Sprintf("agent-calls-export-%s.jsonl", time.Now().Format("20060102-150405")))
	f, err := os.Create(out)
	if err != nil {
		return fmt.Sprintf("export failed: %v", err)
	}
	defer f.Close()
	for _, r := range m.filteredRecords {
		line, _ := json.Marshal(r)
		_, _ = fmt.Fprintf(f, "%s\n", line)
	}
	return fmt.Sprintf("exported %d records → %s", len(m.filteredRecords), out)
}

// ─────────────────────────────────────────────────────────────────────────────
// View

func (m Model) View() string {
	if m.width == 0 {
		return "loading…"
	}

	headerH := 3
	bottomH := 3
	bodyH := m.height - headerH - bottomH
	if bodyH < 4 {
		bodyH = 4
	}

	header := m.renderHeader()
	bottom := m.renderStatusBar()

	var body string
	if m.showDetail {
		listW := m.width*2/3 - 2
		detailW := m.width - listW - 4
		listPane := m.renderList(listW, bodyH)
		detailPane := m.renderDetail(detailW, bodyH)
		body = lipgloss.JoinHorizontal(lipgloss.Top, listPane, detailPane)
	} else {
		body = m.renderList(m.width-4, bodyH)
	}

	return lipgloss.JoinVertical(lipgloss.Left, header, body, bottom)
}

func (m Model) renderHeader() string {
	tailIndicator := styleMuted.Render("[tail:off]")
	if m.tailMode {
		tailIndicator = styleOK.Render("[tail:ON]")
	}

	filterStr := ""
	if m.currentMode == modeFilter {
		filterStr = styleFilterActive.Render("filter: " + m.filterText + "█")
	} else if m.filterText != "" {
		filterStr = styleMuted.Render("filter: " + m.filterText)
	}

	title := styleTitle.Render(" ⬡ ForgeOS Agent Call Observability")
	right := lipgloss.NewStyle().Width(m.width - lipgloss.Width(title) - 2).Align(lipgloss.Right).
		Render(tailIndicator + "  " + filterStr)

	keys := styleMuted.Render(" j/k navigate  /  filter  r reload  t tail  d detail  e export  q quit")
	return lipgloss.JoinVertical(lipgloss.Left,
		lipgloss.JoinHorizontal(lipgloss.Top, title, right),
		keys,
	)
}

func statusStyle(s CallStatus) string {
	switch s {
	case StatusOK:
		return styleOK.Render("✓ ok     ")
	case StatusError:
		return styleError.Render("✗ error  ")
	case StatusTimeout:
		return styleTimeout.Render("⏱ timeout")
	}
	return styleMuted.Render(string(s))
}

func providerColor(p string) string {
	switch p {
	case "groq":
		return lipgloss.NewStyle().Foreground(lipgloss.Color("213")).Render(p)
	case "cerebras":
		return lipgloss.NewStyle().Foreground(lipgloss.Color("214")).Render(p)
	case "gemini":
		return lipgloss.NewStyle().Foreground(lipgloss.Color("75")).Render(p)
	case "ollama":
		return lipgloss.NewStyle().Foreground(lipgloss.Color("82")).Render(p)
	}
	return styleMuted.Render(p)
}

func (m Model) renderList(width, height int) string {
	// column widths
	const tsW, agentW, provW, statusW, latW, tokW = 20, 15, 9, 10, 8, 10

	headerRow := styleHeader.Width(width).Render(
		fmt.Sprintf("%-*s %-*s %-*s %-*s %-*s %-*s",
			tsW, "TIMESTAMP",
			agentW, "AGENT",
			provW, "PROVIDER",
			statusW, "STATUS",
			latW, "LAT(ms)",
			tokW, "IN/OUT",
		),
	)

	visibleRows := height - 3
	if visibleRows < 1 {
		visibleRows = 1
	}

	// scroll so cursor is always visible
	if m.cursor < m.scrollTop {
		m.scrollTop = m.cursor
	}
	if m.cursor >= m.scrollTop+visibleRows {
		m.scrollTop = m.cursor - visibleRows + 1
	}

	var rows []string
	for i := m.scrollTop; i < min(m.scrollTop+visibleRows, len(m.filteredRecords)); i++ {
		r := m.filteredRecords[i]

		ts := r.Timestamp
		if len(ts) > tsW {
			ts = ts[:tsW]
		}

		agent := r.Agent
		if len(agent) > agentW {
			agent = agent[:agentW]
		}

		prov := r.Provider
		if len(prov) > provW {
			prov = prov[:provW]
		}

		lat := fmt.Sprintf("%d", r.TotalDurationMS)
		if r.TotalDurationMS == 0 {
			lat = "-"
		}

		tok := fmt.Sprintf("%d/%d", r.InputTokens, r.OutputTokens)

		line := fmt.Sprintf("%-*s %-*s %-*s %-*s %-*s %-*s",
			tsW, ts,
			agentW, agent,
			provW, prov,
			statusW, string(r.Status),
			latW, lat,
			tokW, tok,
		)

		if i == m.cursor {
			rows = append(rows, "▸ "+styleRowSelected.Width(width-2).Render(line))
		} else {
			rows = append(rows, "  "+styleRowNormal.Width(width-2).Render(line))
		}
	}

	if len(m.filteredRecords) == 0 {
		rows = append(rows, styleMuted.Render("  no records (run forge-enhance to generate calls)"))
	}

	scrollInfo := styleMuted.Render(fmt.Sprintf(" %d/%d", m.cursor+1, len(m.filteredRecords)))
	content := lipgloss.JoinVertical(lipgloss.Left,
		headerRow,
		strings.Join(rows, "\n"),
		scrollInfo,
	)
	return stylePane.Width(width).Height(height).Render(content)
}

func (m Model) renderDetail(width, height int) string {
	if len(m.filteredRecords) == 0 {
		return stylePane.Width(width).Height(height).Render(
			styleMuted.Render("no record selected"),
		)
	}

	r := m.filteredRecords[m.cursor]

	var b strings.Builder

	label := func(k, v string) string {
		return styleLabel.Render(k+":") + "  " + styleValue.Render(v)
	}

	b.WriteString(styleTitle.Render(" Call Detail") + "\n\n")

	b.WriteString(label("ID", r.ID) + "\n")
	b.WriteString(label("Time", r.Timestamp) + "\n")
	b.WriteString(label("Agent", r.Agent) + "\n")
	b.WriteString(label("Provider", providerColor(r.Provider)) + "\n")
	b.WriteString(label("Model", r.Model) + "\n")
	b.WriteString(label("Status", statusStyle(r.Status)) + "\n")
	b.WriteString(label("Mode", r.Mode) + "\n")
	b.WriteString(label("Host", r.Host) + "\n")
	b.WriteString(label("User", r.User) + "\n")
	b.WriteString("\n")

	b.WriteString(label("Latency", fmt.Sprintf("%dms total", r.TotalDurationMS)) + "\n")
	b.WriteString(label("Fallbacks", fmt.Sprintf("%d", r.FallbackCount)) + "\n")
	b.WriteString(label("Input", fmt.Sprintf("%d chars / ~%d tokens", r.InputLen, r.InputTokens)) + "\n")
	b.WriteString(label("Output", fmt.Sprintf("%d chars / ~%d tokens", r.OutputLen, r.OutputTokens)) + "\n")
	if r.HTTPStatus > 0 {
		b.WriteString(label("HTTP", fmt.Sprintf("%d", r.HTTPStatus)) + "\n")
	}
	if r.ErrorMsg != "" {
		b.WriteString("\n" + styleError.Render("Error: "+r.ErrorMsg) + "\n")
	}

	b.WriteString("\n" + styleLabel.Render("Input preview:") + "\n")
	inputLines := wordWrap(r.InputPreview, width-4)
	for _, line := range inputLines {
		b.WriteString(styleMuted.Render("  "+line) + "\n")
	}

	if r.OutputPreview != "" {
		b.WriteString("\n" + styleLabel.Render("Output preview:") + "\n")
		outputLines := wordWrap(r.OutputPreview, width-4)
		for _, line := range outputLines {
			b.WriteString(styleValue.Render("  "+line) + "\n")
		}
	}

	return stylePane.Width(width).Height(height).Render(b.String())
}

func (m Model) renderStatusBar() string {
	if len(m.allRecords) == 0 {
		return styleStatusBar.Width(m.width).Render(
			fmt.Sprintf(" No calls yet | log: %s | reloads every 3s", m.logPath),
		)
	}

	ok, errs, timeouts := 0, 0, 0
	provCounts := map[string]int{}
	var totalLat int64
	latCount := 0
	totalIn, totalOut := 0, 0

	for _, r := range m.filteredRecords {
		switch r.Status {
		case StatusOK:
			ok++
		case StatusError:
			errs++
		case StatusTimeout:
			timeouts++
		}
		provCounts[r.Provider]++
		if r.TotalDurationMS > 0 {
			totalLat += r.TotalDurationMS
			latCount++
		}
		totalIn += r.InputTokens
		totalOut += r.OutputTokens
	}

	avgLat := 0.0
	if latCount > 0 {
		avgLat = math.Round(float64(totalLat)/float64(latCount)*10) / 10
	}

	provParts := make([]string, 0, len(provCounts))
	for p, n := range provCounts {
		provParts = append(provParts, fmt.Sprintf("%s:%d", p, n))
	}

	errorRate := ""
	total := ok + errs + timeouts
	if total > 0 && (errs+timeouts) > 0 {
		pct := float64(errs+timeouts) / float64(total) * 100
		errorRate = styleError.Render(fmt.Sprintf(" err_rate:%.0f%%", pct))
	}

	bar := fmt.Sprintf(
		" total:%d  %s  %s  %s  avg_lat:%.0fms  tokens_in:%d out:%d  providers:[%s]  %s",
		len(m.filteredRecords),
		styleOK.Render(fmt.Sprintf("ok:%d", ok)),
		styleError.Render(fmt.Sprintf("err:%d", errs)),
		styleTimeout.Render(fmt.Sprintf("timeout:%d", timeouts)),
		avgLat,
		totalIn, totalOut,
		strings.Join(provParts, " "),
		time.Now().Format("15:04:05"),
	) + errorRate

	return styleStatusBar.Width(m.width).Render(bar)
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers

func wordWrap(s string, width int) []string {
	if width <= 0 {
		width = 60
	}
	var lines []string
	words := strings.Fields(s)
	line := ""
	for _, w := range words {
		if len(line)+len(w)+1 > width {
			if line != "" {
				lines = append(lines, line)
			}
			line = w
		} else {
			if line == "" {
				line = w
			} else {
				line += " " + w
			}
		}
	}
	if line != "" {
		lines = append(lines, line)
	}
	if len(lines) == 0 {
		lines = []string{s}
	}
	return lines
}

// ─────────────────────────────────────────────────────────────────────────────
// Main

func main() {
	p := tea.NewProgram(initialModel(), tea.WithAltScreen())
	if _, err := p.Run(); err != nil {
		fmt.Fprintln(os.Stderr, err)
		os.Exit(1)
	}
}
