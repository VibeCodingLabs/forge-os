local wezterm = require 'wezterm'
local act = wezterm.action

local config = wezterm.config_builder()

config.color_scheme = 'Builtin Solarized Dark'
config.font = wezterm.font_with_fallback({ 'JetBrainsMono Nerd Font', 'FiraCode Nerd Font', 'monospace' })
config.font_size = 12.0
config.window_background_opacity = 0.94
config.enable_tab_bar = true
config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = false
config.window_padding = { left = 8, right = 8, top = 8, bottom = 8 }
config.audible_bell = 'Disabled'
config.default_cursor_style = 'BlinkingBar'
config.scrollback_lines = 20000

config.leader = { key = 'Space', mods = 'CTRL', timeout_milliseconds = 1500 }

config.keys = {
  { key = 'c', mods = 'LEADER', action = act.SpawnTab 'CurrentPaneDomain' },
  { key = 'x', mods = 'LEADER', action = act.CloseCurrentPane { confirm = true } },
  { key = 'v', mods = 'LEADER', action = act.SplitHorizontal { domain = 'CurrentPaneDomain' } },
  { key = 's', mods = 'LEADER', action = act.SplitVertical { domain = 'CurrentPaneDomain' } },
  { key = 'h', mods = 'LEADER', action = act.ActivatePaneDirection 'Left' },
  { key = 'j', mods = 'LEADER', action = act.ActivatePaneDirection 'Down' },
  { key = 'k', mods = 'LEADER', action = act.ActivatePaneDirection 'Up' },
  { key = 'l', mods = 'LEADER', action = act.ActivatePaneDirection 'Right' },
  { key = 'r', mods = 'LEADER', action = act.ReloadConfiguration },
  { key = 'o', mods = 'LEADER', action = act.ShowLauncherArgs { flags = 'FUZZY|WORKSPACES' } },
  { key = 'f', mods = 'LEADER', action = act.Search 'CurrentSelectionOrEmptyString' },
  { key = 't', mods = 'LEADER', action = act.SpawnCommandInNewTab { args = { 'bash', '-lc', 'btop || top' } } },
  { key = 'g', mods = 'LEADER', action = act.SpawnCommandInNewTab { args = { 'bash', '-lc', 'cd ~/forge-os 2>/dev/null || cd ~; git status; exec bash' } } },
  { key = 'a', mods = 'LEADER', action = act.SpawnCommandInNewTab { args = { 'bash', '-lc', 'tail -f ~/.forge-os/logs/heartbeat.log ~/.forge-os/logs/observer.log 2>/dev/null; exec bash' } } },
}

wezterm.on('format-tab-title', function(tab)
  local title = tab.active_pane.title
  return '  ' .. tab.tab_index + 1 .. ': ' .. title .. '  '
end)

return config
