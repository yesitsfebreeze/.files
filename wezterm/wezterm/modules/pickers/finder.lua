-- modules/pickers/finder.lua: Finder picker extension registry
--
-- Each picker defines metadata that modules/finder.lua uses
-- to build the appropriate fzf command.
--
-- Source types (each corresponds to a shell command pipeline):
--   "rg_files"       — list files via rg --files / fd
--   "rg_grep"        — live ripgrep search (query-driven via fzf --disabled)
--   "fd_dirs"        — list directories via fd / find
--   "themes_cache"   — read .themes_list
--   "projects_json"  — read .projects_list
--
-- Result types (determine the signal emitted on selection):
--   "file"   → open:<path>
--   "grep"   → open:<path>:<line>
--   "dir"    → cd:<path>
--   "theme"  → theme:<name>

local wezterm = require("wezterm")

local M = {}

local config_dir = wezterm.config_dir:gsub("\\", "/")

-- ── Picker extensions ───────────────────────────────────────────

M.pickers = {
  {
    name      = "Files",
    filter    = "fcf",
    source    = "rg_files",
    result    = "file",
    min_query = 2,
    accepts   = { "none", "file", "grep", "dir" },
    produces  = "file",
  },
  {
    name      = "Grep",
    filter    = "none",          -- rg does the filtering
    source    = "rg_grep",
    result    = "grep",
    min_query = 2,
    accepts   = { "none", "file", "grep", "dir" },
    produces  = "grep",
  },
  {
    name      = "Dirs",
    filter    = "fcf",
    source    = "fd_dirs",
    result    = "dir",
    min_query = 0,
    accepts   = { "none", "dir" },
    produces  = "dir",
  },
  {
    name      = "Projects",
    filter    = "fcf",
    source    = "projects_json",
    result    = "dir",
    min_query = 0,
    accepts   = { "none" },
    produces  = "dir",
  },
  {
    name      = "Themes",
    filter    = "fcf",
    source    = "themes_cache",
    result    = "theme",
    min_query = 0,
    accepts   = { "none" },
    produces  = "none",
  },
}

-- ── Export picker definitions for the TUI ───────────────────────

function M.export()
  local ok, json = pcall(wezterm.json_encode, M.pickers)
  if ok then
    local f = io.open(config_dir .. "/.pickers.json", "w")
    if f then
      f:write(json)
      f:close()
    end
  end
end

return M
