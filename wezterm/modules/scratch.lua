-- modules/scratch.lua: Togglable scratch pane overlay
--
-- Leader+s  → splits a pane at the bottom, zooms it to take over the view.
-- Leader+s again → unzooms, returns to the original pane (scratch stays alive).
-- Leader+s again → zooms back into the scratch pane.
-- Works per-tab: each tab can have its own scratch pane.

local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

-- ── State (wezterm.GLOBAL survives config reloads) ──────────────
-- Keyed by tostring(tab_id) → { scratch_id, original_id }

local function scratch_state()
  if not wezterm.GLOBAL.scratch_panes then
    wezterm.GLOBAL.scratch_panes = {}
  end
  return wezterm.GLOBAL.scratch_panes
end

-- Find a pane object in a tab by its string pane_id
local function find_pane(tab, pane_id_str)
  for _, p in ipairs(tab:panes()) do
    if tostring(p:pane_id()) == pane_id_str then
      return p
    end
  end
end

-- Check if something in this tab is zoomed
local function tab_is_zoomed(tab)
  for _, info in ipairs(tab:panes_with_info()) do
    if info.is_zoomed then return true end
  end
  return false
end

-- Get CWD from a pane for the split
local function get_cwd(pane)
  local cwd = pane:get_current_working_dir()
  local dir = cwd and (cwd.file_path or tostring(cwd)) or wezterm.home_dir
  return dir:gsub("^file:///", "")
end

-- ── Toggle action ───────────────────────────────────────────────

function M.toggle_scratch()
  return wezterm.action_callback(function(window, pane)
    local tab = window:active_tab()
    local tab_key = tostring(tab:tab_id())
    local st = scratch_state()
    local info = st[tab_key]

    -- Verify stored scratch pane is still alive
    local scratch_pane = nil
    if info then
      scratch_pane = find_pane(tab, info.scratch_id)
      if not scratch_pane then
        st[tab_key] = nil
        info = nil
      end
    end

    -- ── No scratch pane → create one ───────────────────────────
    if not scratch_pane then
      local dir = get_cwd(pane)
      local new_pane = pane:split({
        direction = "Bottom",
        size = 0.15,   -- small sliver when unzoomed
        cwd = dir,
      })
      st[tab_key] = {
        scratch_id  = tostring(new_pane:pane_id()),
        original_id = tostring(pane:pane_id()),
      }
      -- Zoom the scratch pane to fill the view
      window:perform_action(act.TogglePaneZoomState, new_pane)
      wezterm.log_info("scratch: created pane " .. tostring(new_pane:pane_id()))
      return
    end

    -- ── Scratch exists — toggle between scratch and original ───
    local active_id = tostring(tab:active_pane():pane_id())

    if active_id == info.scratch_id then
      -- ON the scratch pane → hide it, return to original
      if tab_is_zoomed(tab) then
        window:perform_action(act.TogglePaneZoomState, scratch_pane)
      end
      local orig = find_pane(tab, info.original_id)
      if orig then
        orig:activate()
      end
      wezterm.log_info("scratch: hidden, back to original")
    else
      -- NOT on scratch → show it
      info.original_id = active_id  -- remember current pane
      if tab_is_zoomed(tab) then
        window:perform_action(act.TogglePaneZoomState, pane)
      end
      scratch_pane:activate()
      window:perform_action(act.TogglePaneZoomState, scratch_pane)
      wezterm.log_info("scratch: shown (zoomed)")
    end
  end)
end

return M
