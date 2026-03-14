-- modules/utils.lua: Shared pane helpers used by finder, scratch, etc.

local wezterm = require("wezterm")

local M = {}

--- Find a pane object in a tab by its string pane_id.
function M.find_pane(tab, pane_id_str)
  for _, p in ipairs(tab:panes()) do
    if tostring(p:pane_id()) == pane_id_str then
      return p
    end
  end
end

--- Check if any pane in this tab is zoomed.
function M.tab_is_zoomed(tab)
  for _, info in ipairs(tab:panes_with_info()) do
    if info.is_zoomed then return true end
  end
  return false
end

--- Get CWD from a pane, with Windows path normalization.
function M.get_cwd(pane)
  local cwd = pane:get_current_working_dir()
  local dir = cwd and (cwd.file_path or tostring(cwd)) or wezterm.home_dir
  dir = dir:gsub("^file:///", "")
  dir = dir:gsub("^/(%a:)", "%1")
  return dir
end

return M
