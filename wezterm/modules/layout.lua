-- modules/layout.lua: Pane layout for every tab + pane cycling
-- Reads layout config from globals.lua to create splits on startup
-- AND whenever a new tab is opened (Leader+t, + button, etc.).
-- Keybinding: CTRL+SHIFT+/  → cycle focus between panes

local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

-- Module-level reference so event handlers can read the layout config.
local saved_globals = nil

-- ── Reusable split logic ────────────────────────────────────────
-- Apply pane splits to a single-pane tab.
-- widths: list of fractions, e.g. { 0.3, 0.4, 0.3 }
local function apply_splits(gui_win, tab, widths, focus_idx)
  if #widths < 2 then return end
  if #tab:panes() ~= 1 then return end   -- already split

  -- Normalize to sum = 1
  local total = 0
  for _, w in ipairs(widths) do total = total + w end
  local norm = {}
  for _, w in ipairs(widths) do table.insert(norm, w / total) end

  local remaining = 1.0
  for i = 1, #norm - 1 do
    local frac = norm[i] / remaining
    gui_win:perform_action(
      act.SplitPane({
        direction = "Right",
        size = { Percent = math.floor((1 - frac) * 100) },
      }),
      tab:active_pane()
    )
    remaining = remaining - norm[i]
    gui_win:perform_action(act.ActivatePaneDirection("Right"), tab:active_pane())
  end

  -- Focus the configured pane (default: first)
  focus_idx = focus_idx or 1
  local pane_info = tab:panes_with_info()
  table.sort(pane_info, function(a, b)
    if a.left ~= b.left then return a.left < b.left end
    return a.top < b.top
  end)
  if pane_info[focus_idx] then
    pane_info[focus_idx].pane:activate()
  end
end

-- ── Startup layout (first window, first tab) ───────────────────
local function setup_startup_layout(globals)
  wezterm.on("gui-attached", function(_domain)
    local widths = globals.layout or {}
    if #widths < 2 then return end

    local window = wezterm.mux.all_windows()[1]
    if not window then return end

    local gui_win = window:gui_window()
    if globals.maximize then gui_win:maximize() end

    apply_splits(gui_win, window:active_tab(), widths, globals.layout_focus)
  end)
end

-- ── Custom event: other modules can emit "apply-pane-layout" ───
-- Usage: wezterm.emit("apply-pane-layout", gui_window, mux_tab)
wezterm.on("apply-pane-layout", function(gui_win, tab)
  local g = saved_globals
  if not g then return end
  apply_splits(gui_win, tab, g.layout or {}, g.layout_focus)
end)

-- ── + button on tab bar → new tab with layout ──────────────────
wezterm.on("new-tab-button-click", function(window, pane, is_default_click)
  if not is_default_click then return true end   -- right-click: default menu
  local g = saved_globals
  local widths = (g and g.layout) or {}
  if #widths < 2 then return true end            -- no layout: default behavior

  local tab, _, _ = window:mux_window():spawn_tab({})
  apply_splits(window, tab, widths, g.layout_focus)
  return false   -- suppress default new-tab
end)

--- Cycle focus: left → center → right → left …
local function cycle_pane_focus(window, _pane)
  local tab = window:active_tab()
  local panes = tab:panes_with_info()

  if #panes < 2 then return end

  -- Sort panes by their left edge (leftmost first)
  table.sort(panes, function(a, b)
    if a.left ~= b.left then return a.left < b.left end
    return a.top < b.top
  end)

  -- Find which pane is currently active
  local active_idx = 1
  for i, p in ipairs(panes) do
    if p.is_active then
      active_idx = i
      break
    end
  end

  -- Cycle to the next pane
  local next_idx = (active_idx % #panes) + 1
  panes[next_idx].pane:activate()
end

function M.apply(config, globals)
  config.keys = config.keys or {}
  saved_globals = globals

  -- Startup layout (first tab)
  setup_startup_layout(globals)

  -- Cycle between panes with Ctrl+Shift+/
  table.insert(config.keys, {
    key = "/",
    mods = "CTRL|SHIFT",
    action = wezterm.action_callback(cycle_pane_focus),
  })
end

return M
