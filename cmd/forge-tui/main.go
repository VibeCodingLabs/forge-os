package main

import (
	"fmt"
	"os"
	"os/exec"
	"strings"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

type model struct {
	cursor int
	items  []string
	status string
}

var (
	accent = lipgloss.Color("205")
	cyan   = lipgloss.Color("51")
	green  = lipgloss.Color("42")
	muted  = lipgloss.Color("245")

	titleStyle = lipgloss.NewStyle().Bold(true).Foreground(accent).MarginBottom(1)
	boxStyle   = lipgloss.NewStyle().Border(lipgloss.RoundedBorder()).BorderForeground(cyan).Padding(1, 2).Margin(1, 0)
	itemStyle  = lipgloss.NewStyle().Foreground(lipgloss.Color("252"))
	selected   = lipgloss.NewStyle().Bold(true).Foreground(green)
	mutedStyle = lipgloss.NewStyle().Foreground(muted)
)

func initialModel() model {
	return model{
		items: []string{
			"Run shell installer menu",
			"Preflight report",
			"Install ZSH productivity shell",
			"Install Bubble Tea/Lip Gloss dev deps",
			"Install Rich/Textual Python UI stack",
			"Exit",
		},
		status: "ForgeOS command center ready",
	}
}

func (m model) Init() tea.Cmd { return nil }

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tea.KeyMsg:
		switch msg.String() {
		case "ctrl+c", "q":
			return m, tea.Quit
		case "up", "k":
			if m.cursor > 0 { m.cursor-- }
		case "down", "j":
			if m.cursor < len(m.items)-1 { m.cursor++ }
		case "enter":
			return m, m.execute()
		}
	}
	return m, nil
}

func (m model) execute() tea.Cmd {
	choice := m.items[m.cursor]
	return func() tea.Msg {
		switch choice {
		case "Run shell installer menu":
			return runCmd("bash", "bin/forge-menu.sh")
		case "Preflight report":
			return runCmd("bash", "-lc", "df -h; free -h; uname -a")
		case "Install ZSH productivity shell":
			return runCmd("bash", "scripts/install-zsh-productivity.sh")
		case "Install Bubble Tea/Lip Gloss dev deps":
			return runCmd("bash", "scripts/install-tui-dev.sh")
		case "Install Rich/Textual Python UI stack":
			return runCmd("bash", "scripts/install-python-rich-ui.sh")
		default:
			return tea.Quit()
		}
	}
}

type statusMsg string

func runCmd(name string, args ...string) tea.Msg {
	cmd := exec.Command(name, args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Stdin = os.Stdin
	if err := cmd.Run(); err != nil {
		return statusMsg(fmt.Sprintf("command failed: %v", err))
	}
	return statusMsg("command complete")
}

func (m model) View() string {
	var b strings.Builder
	b.WriteString(titleStyle.Render("ForgeOS Command Center"))
	b.WriteString("\n")
	b.WriteString(mutedStyle.Render("↑/↓ or j/k to move • enter to run • q to quit"))
	b.WriteString("\n\n")
	for i, item := range m.items {
		cursor := "  "
		line := itemStyle.Render(item)
		if m.cursor == i {
			cursor = "▸ "
			line = selected.Render(item)
		}
		b.WriteString(cursor + line + "\n")
	}
	b.WriteString("\n")
	b.WriteString(mutedStyle.Render(m.status))
	return boxStyle.Render(b.String())
}

func main() {
	p := tea.NewProgram(initialModel(), tea.WithAltScreen())
	if _, err := p.Run(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}
