-- globals.lua: Persistent user preferences
-- Edit these values directly, or use the built-in pickers to change them at runtime.
-- WezTerm hot-reloads this file automatically when it changes.

return {
  color_scheme = "Atelier Cave (base16)",
  font_family = "DepartureMono Nerd Font Mono",
  font_size = 13,
  line_height = 1.01,
  opacity = 0.925,
  blur = 10,
  padding = {
    top = 0,
    bottom = 0,
    left = 0,
    right = 0,
  },

  -- Startup pane layout: list of pane widths (fractions, auto-normalized to 1).
  -- Example: { 0.25, 0.50, 0.25 } → three columns: 25% | 50% | 25%
  layout = { 0.3, 0.40, 0.3 },
  layout_focus = 2,    -- which pane to focus (1=first, 2=second, etc.)
  maximize = true,     -- start maximized

  -- Leader key: Ctrl+Q (Windows/Linux) or Cmd+Q (Mac).
  -- On Mac this also prevents accidental quit.
  leader = { key = "F12", mods = "SHIFT", timeout_ms = 1500 },

  -- Follower keys: triggered after pressing the leader key.
  -- "action" is the WezTerm action name, "args" are its arguments.
  -- "desc" is shown in the leader overlay (Leader + ? to open).
  followers = {
    -- Pane splitting
    { key = "\\", desc = "Split right",      action = "SplitHorizontal", args = { domain = "CurrentPaneDomain" } },

    -- Pane navigation
    { key = "a", desc = "Pane ←",  action = "ActivatePaneDirection", args = "Left" },
    { key = "d", desc = "Pane →",  action = "ActivatePaneDirection", args = "Right" },

    -- Close tab (only if more than one tab open)
    { key = "w", desc = "Close tab",  action = "CloseTabIfMultiple" },

    -- Tabs
    { key = "t", desc = "New tab (layout)", action = "SpawnTabWithLayout" },
    { key = "n", desc = "Next tab",    action = "ActivateTabRelative", args = 1 },
    { key = "p", desc = "Prev tab",    action = "ActivateTabRelative", args = -1 },
    { key = "1", desc = "Tab 1",       action = "ActivateTab", args = 0 },
    { key = "2", desc = "Tab 2",       action = "ActivateTab", args = 1 },
    { key = "3", desc = "Tab 3",       action = "ActivateTab", args = 2 },
    { key = "4", desc = "Tab 4",       action = "ActivateTab", args = 3 },
    { key = "5", desc = "Tab 5",       action = "ActivateTab", args = 4 },
    { key = "6", desc = "Tab 6",       action = "ActivateTab", args = 5 },
    { key = "7", desc = "Tab 7",       action = "ActivateTab", args = 6 },
    { key = "8", desc = "Tab 8",       action = "ActivateTab", args = 7 },
    { key = "9", desc = "Last tab",    action = "ActivateTab", args = -1 },

    -- Utilities
    { key = "c", desc = "Copy mode",        action = "ActivateCopyMode" },
    { key = "/", desc = "Search",            action = "Search", args = "CurrentSelectionOrEmptyString" },
    { key = "f", desc = "Quick select",      action = "QuickSelect" },
    { key = "r", desc = "Reload config",     action = "ReloadConfiguration" },
    { key = "x", desc = "Command palette",   action = "ActivateCommandPalette" },
  },
}
