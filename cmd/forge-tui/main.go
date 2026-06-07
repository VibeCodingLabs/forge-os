package main

import (
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"time"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

type screen int

const (
	screenMain screen = iota
	screenInstall
	screenDesktop
	screenSecurity
	screenOps
	screenLogs
)

type menuItem struct {
	Title       string
	Desc        string
	Command     []string
	Next        screen
	Quit        bool
	Dangerous   bool
}

type model struct {
	cursor int
	screen screen
	status string
	root   string
	items  []menuItem
}

var (
	accent = lipgloss.Color("208")
	cyan   = lipgloss.Color("81")
	green  = lipgloss.Color("114")
	red    = lipgloss.Color("167")
	muted  = lipgloss.Color("245")
	fg     = lipgloss.Color("252")

	titleStyle  = lipgloss.NewStyle().Bold(true).Foreground(accent).MarginBottom(1)
	helpStyle   = lipgloss.NewStyle().Foreground(muted)
	boxStyle    = lipgloss.NewStyle().Border(lipgloss.RoundedBorder()).BorderForeground(cyan).Padding(1, 2).Margin(1, 0)
	itemStyle   = lipgloss.NewStyle().Foreground(fg)
	selectStyle = lipgloss.NewStyle().Bold(true).Foreground(green)
	warnStyle   = lipgloss.NewStyle().Bold(true).Foreground(red)
	pillStyle   = lipgloss.NewStyle().Foreground(lipgloss.Color("16")).Background(green).Padding(0, 1)
)

func initialModel() model {
	root, _ := os.Getwd()
	m := model{screen: screenMain, status: "ForgeOS command center ready", root: root}
	m.items = m.menu()
	return m
}

func (m model) Init() tea.Cmd { return nil }

func (m model) menu() []menuItem {
	switch m.screen {
	case screenInstall:
		return []menuItem{
			{"Full Command Center Install", "Recovery base + ZSH + River/Waybar/Eww + performance + security + dictation + TUI", []string{"bash", "scripts/install-full-command-center.sh"}, 0, false, false},
			{"Minimal Recovery Base", "Core Debian recovery packages, directories, scripts, and timers", []string{"bash", "-lc", "printf '2\\n\\n' | bash install.sh"}, 0, false, false},
			{"ZSH Productivity Shell", "ZSH, completions, autosuggestions, syntax highlighting, Starship, fzf, zoxide", []string{"bash", "scripts/install-zsh-productivity.sh"}, 0, false, false},
			{"Dev Runtime", "Python, Node, Go, Rust, SQLite and build tooling via shell installer", []string{"bash", "-lc", "printf '5\\n4\\n\\n19\\n15\\n' | bash bin/forge-menu.sh"}, 0, false, false},
			{"Tauri Desktop Stack", "Rust/Tauri desktop prerequisites", []string{"bash", "-lc", "printf '5\\n5\\n\\n19\\n15\\n' | bash bin/forge-menu.sh"}, 0, false, false},
			{"Back", "Return to main menu", nil, screenMain, false, false},
		}
	case screenDesktop:
		return []menuItem{
			{"Desktop Command Center", "River/Sway/i3, Waybar, Eww, terminals, wallpaper, clipboard, portals", []string{"bash", "scripts/install-desktop-command-center.sh"}, 0, false, false},
			{"Copy Desktop Configs", "Install repo configs to ~/.config for River, Waybar, Eww, terminals", []string{"bash", "-lc", "printf '7\\n\\n15\\n' | bash bin/forge-menu.sh"}, 0, false, false},
			{"Start River", "Launch River compositor from current TTY/session", []string{"bash", "-lc", "river"}, 0, false, false},
			{"Start Eww Panel", "Open ForgeOS Eww panel widget", []string{"bash", "-lc", "eww daemon >/tmp/forge-eww.log 2>&1 || true; eww open forge-panel"}, 0, false, false},
			{"Set Wallpaper", "Apply wallpaper helper from ~/.config/wallpapers", []string{"bash", "scripts/forge-wallpaper.sh"}, 0, false, false},
			{"Back", "Return to main menu", nil, screenMain, false, false},
		}
	case screenSecurity:
		return []menuItem{
			{"Security Hardening", "Firewall, antivirus, auditd, AppArmor, fail2ban, Lynis/AIDE baseline", []string{"bash", "scripts/install-security-hardening.sh"}, 0, false, false},
			{"Performance Tuning", "zram/tuned/powertop/thermald/earlyoom/irqbalance/fstrim/sysstat", []string{"bash", "scripts/install-performance-tuning.sh"}, 0, false, false},
			{"Security Report", "Run ForgeOS firewall/security verification report", []string{"bash", "-lc", "forge-security-report || ~/.local/bin/forge-security-report"}, 0, false, false},
			{"Firewall Status", "Show current UFW status", []string{"bash", "-lc", "sudo ufw status verbose"}, 0, false, false},
			{"ClamAV Version", "Verify ClamAV tooling", []string{"bash", "-lc", "clamscan --version; freshclam --version || true"}, 0, false, false},
			{"Back", "Return to main menu", nil, screenMain, false, false},
		}
	case screenOps:
		return []menuItem{
			{"Forge Doctor", "Verify installed commands, configs, services, timers, firewall", []string{"bash", "scripts/forge-doctor.sh"}, 0, false, false},
			{"Preflight Report", "Disk, memory, kernel, Debian version", []string{"bash", "-lc", "df -h / $HOME; free -h; uname -a; cat /etc/debian_version 2>/dev/null || true"}, 0, false, false},
			{"Dictation/Accessibility", "Install audio, speech, clipboard, and offline STT prerequisites", []string{"bash", "scripts/install-dictation-accessibility.sh"}, 0, false, false},
			{"Open Dictation Note", "Create/edit a local dictation note", []string{"bash", "-lc", "forge-dictation-note || ~/.local/bin/forge-dictation-note"}, 0, false, false},
			{"Shell Installer Menu", "Fallback bash menu with all legacy options", []string{"bash", "bin/forge-menu.sh"}, 0, false, false},
			{"Back", "Return to main menu", nil, screenMain, false, false},
		}
	case screenLogs:
		return []menuItem{
			{"Tail Forge Logs", "Follow recent ForgeOS install and runtime logs", []string{"bash", "-lc", "mkdir -p ${FORGE_HOME:-$HOME/.forge-os}/logs; find ${FORGE_HOME:-$HOME/.forge-os}/logs -type f | sort | tail -20; echo; tail -n 120 -f $(find ${FORGE_HOME:-$HOME/.forge-os}/logs -type f | sort | tail -1)"}, 0, false, false},
			{"List State Files", "Show install state markers", []string{"bash", "-lc", "find ${FORGE_HOME:-$HOME/.forge-os}/state -maxdepth 1 -type f -print -exec sed -n '1,80p' {} \\;"}, 0, false, false},
			{"Systemd User Timers", "Show ForgeOS user timer status", []string{"bash", "-lc", "systemctl --user status forge-heartbeat.timer forge-observer.timer --no-pager || true"}, 0, false, false},
			{"Open btop", "System performance dashboard", []string{"bash", "-lc", "btop || htop || top"}, 0, false, false},
			{"Back", "Return to main menu", nil, screenMain, false, false},
		}
	default:
		return []menuItem{
			{"Install", "Install profiles and stacks", nil, screenInstall, false, false},
			{"Desktop", "River, Waybar, Eww, wallpaper, clipboard, window tiling", nil, screenDesktop, false, false},
			{"Security + Performance", "Firewall, hardening, antivirus, performance tuning", nil, screenSecurity, false, false},
			{"Ops + Doctor", "Preflight, doctor, dictation, fallback shell menu", nil, screenOps, false, false},
			{"Logs + Observability", "Logs, state files, timers, system dashboard", nil, screenLogs, false, false},
			{"Quit", "Exit ForgeOS Command Center", nil, 0, true, false},
		}
	}
}

func (m model) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case statusMsg:
		m.status = string(msg)
		return m, nil
	case tea.KeyMsg:
		switch msg.String() {
		case "ctrl+c", "q":
			if m.screen != screenMain {
				m.screen = screenMain
				m.cursor = 0
				m.items = m.menu()
				m.status = "Returned to main menu"
				return m, nil
			}
			return m, tea.Quit
		case "esc", "backspace", "left", "h":
			if m.screen != screenMain {
				m.screen = screenMain
				m.cursor = 0
				m.items = m.menu()
				m.status = "Returned to main menu"
			}
		case "up", "k":
			if m.cursor > 0 { m.cursor-- }
		case "down", "j":
			if m.cursor < len(m.items)-1 { m.cursor++ }
		case "enter":
			item := m.items[m.cursor]
			if item.Quit { return m, tea.Quit }
			if item.Next != 0 || (item.Next == screenMain && item.Command == nil && item.Title == "Back") {
				m.screen = item.Next
				m.cursor = 0
				m.items = m.menu()
				m.status = "Opened " + item.Title
				return m, nil
			}
			if len(item.Command) > 0 {
				m.status = "Running: " + item.Title
				return m, m.execute(item)
			}
		}
	}
	return m, nil
}

func (m model) execute(item menuItem) tea.Cmd {
	cmdArgs := append([]string{}, item.Command...)
	root := m.root
	return func() tea.Msg {
		if len(cmdArgs) == 0 { return statusMsg("nothing to run") }
		return runCmd(root, item.Title, cmdArgs[0], cmdArgs[1:]...)
	}
}

type statusMsg string

func runCmd(root, title, name string, args ...string) tea.Msg {
	cmd := exec.Command(name, args...)
	cmd.Stdout = os.Stdout
	cmd.Stderr = os.Stderr
	cmd.Stdin = os.Stdin
	cmd.Dir = root
	cmd.Env = append(os.Environ(), "FORGE_TUI=1")
	started := time.Now()
	if err := cmd.Run(); err != nil {
		return statusMsg(fmt.Sprintf("%s failed after %s: %v", title, time.Since(started).Round(time.Second), err))
	}
	return statusMsg(fmt.Sprintf("%s complete in %s", title, time.Since(started).Round(time.Second)))
}

func screenName(s screen) string {
	switch s {
	case screenInstall:
		return "Install"
	case screenDesktop:
		return "Desktop"
	case screenSecurity:
		return "Security + Performance"
	case screenOps:
		return "Ops + Doctor"
	case screenLogs:
		return "Logs + Observability"
	default:
		return "Main"
	}
}

func (m model) View() string {
	var b strings.Builder
	b.WriteString(titleStyle.Render("ForgeOS Command Center"))
	b.WriteString(" ")
	b.WriteString(pillStyle.Render(screenName(m.screen)))
	b.WriteString("\n")
	b.WriteString(helpStyle.Render("↑/↓ or j/k move • enter run/open • esc/backspace back • q quit/back"))
	b.WriteString("\n")
	b.WriteString(helpStyle.Render("repo: " + filepath.Base(m.root)))
	b.WriteString("\n\n")
	for i, item := range m.items {
		cursor := "  "
		line := itemStyle.Render(item.Title)
		if item.Dangerous { line = warnStyle.Render(item.Title) }
		if m.cursor == i {
			cursor = "▸ "
			line = selectStyle.Render(item.Title)
			if item.Dangerous { line = warnStyle.Render(item.Title) }
		}
		b.WriteString(cursor + line)
		if item.Desc != "" {
			b.WriteString("\n    " + helpStyle.Render(item.Desc))
		}
		b.WriteString("\n")
	}
	b.WriteString("\n")	b.WriteString(helpStyle.Render(m.status))
	return boxStyle.Render(b.String())
}

func main() {
	p := tea.NewProgram(initialModel(), tea.WithAltScreen())
	if _, err := p.Run(); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}
}
