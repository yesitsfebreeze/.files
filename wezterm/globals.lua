-- globals.lua: Persistent user preferences
-- Edit these values directly, or use the built-in pickers to change them at runtime.
-- WezTerm hot-reloads this file automatically when it changes.

return {
  color_scheme = "Belafonte Night (Gogh)",
  font_family = "DepartureMono Nerd Font Mono",
  font_size = 13,
  line_height = 1.01,
  opacity = 0.925,
  blur = 0,
  padding = {
    top = 0,
    bottom = 0,
    left = 0,
    right = 0,
  },

  -- Startup pane layout: list of pane widths (fractions, auto-normalized to 1).
  -- Example: { 0.25, 0.50, 0.25 } → three columns: 25% | 50% | 25%
  -- The 4th column is the session sidebar (narrow, rightmost).
  layout = { 0.25, 0.40, 0.25, 0.10 },
  layout_focus = 2,    -- which pane to focus (1=first, 2=second, etc.)
  maximize = true,     -- start maximized

  -- Leader key: Ctrl+Q (Windows/Linux) or Cmd+Q (Mac).
  -- On Mac this also prevents accidental quit.
  leader = { key = "F12", mods = "SHIFT", timeout_ms = 5000 },

  -- Follower keys: triggered after pressing the leader key.
  -- Items with "children" create sub-menus (multi-key sequences).
  -- e.g. leader → f → f runs "FindFiles", leader → f → g runs "FindGrep".
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
    
    { key = "9", desc = "Last tab",    action = "ActivateTab", args = -1 },


    { key = "t", desc = "Tabs…", children = {
        { key = "t", desc = "1",        action = "SpawnTabWithLayout" },
        { key = "n", desc = "Next", action = "ActivateTabRelative", args = 1 },
        { key = "p", desc = "Prev", action = "ActivateTabRelative", args = -1 },
        { key = "a", desc = "1", action = "ActivateTab", args = 0 },
        { key = "s", desc = "2", action = "ActivateTab", args = 1 },
        { key = "d", desc = "3", action = "ActivateTab", args = 2 },
        { key = "f", desc = "4", action = "ActivateTab", args = 3 },
    } },
    

    { key = "r", desc = "Reset…", children = {
        { key = "r", desc = "Back to Root", action = "ResetPanesToProject" },
        { key = "c", desc = "Reload Config", action = "ReloadConfiguration" },
    }},
    

    -- Sessions (multi-agent orchestration)
    { key = "e", desc = "Sessions…", children = {
        { key = "e", desc = "Sidebar",  action = "ToggleSidebar" },
        { key = "s", desc = "Pick",     action = "PickSession" },
        { key = "a", desc = "Add",      action = "AddSession" },
    }},

    -- Projects
    
    { key = "p", desc = "Projects",        action = "OpenProjectPicker" },

    -- Utilities
    { key = "c", desc = "Clear…", children = {
      { key = "c", desc = "Clear all panes", action = "ClearAllPanes" },
      { key = "y", desc = "Copy mode",       action = "ActivateCopyMode" },
    }},
    { key = "s", desc = "Scratch pane",     action = "ToggleScratch" },
    { key = "/", desc = "Search",            action = "Search", args = "CurrentSelectionOrEmptyString" },
    
    { key = ",", desc = "Command palette",   action = "ActivateCommandPalette" },

    -- Find (sub-menu: leader → f → …)
    { key = "f", desc = "Find…", children = {
      { key = "f", desc = "Files",      action = "FindFiles" },
      { key = "g", desc = "RipGrep", action = "FindGrep" },
      { key = "q", desc = "Quick select",    action = "QuickSelect" },
    }},
  },
}
