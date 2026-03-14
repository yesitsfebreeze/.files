-- modules/finder.lua: Full-screen finder overlay (replicates finder.nvim)
--
-- Opens a Python TUI in a zoomed overlay pane.
-- The TUI signals back via OSC 1337 user-var "finder_action":
--   open:<path>            — open file in center pane
--   open:<path>:<line>     — open file at line
--   cd:<path>              — cd all panes to directory
--   theme:<name>           — switch color scheme
--   close                  — just close the overlay
--
-- Keybinding: Leader + f + f → FinderOpen (Files picker)
-- Keybinding: Leader + f + g → FinderOpen (Grep picker)
-- Keybinding: Leader + f + <Space> → FinderOpen (picker select mode)

local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

local config_dir = wezterm.config_dir:gsub("\\", "/")
local TUI_SCRIPT = config_dir .. "/finder_tui.py"

-- ── State (survives config reloads) ─────────────────────────────

local function finder_state()
  if not wezterm.GLOBAL.finder then
    wezterm.GLOBAL.finder = {
      pane_ids = {},     -- tab_id → finder pane_id
      original_ids = {}, -- tab_id → original pane_id (to return to)
    }
  end
  return wezterm.GLOBAL.finder
end

local function find_pane(tab, pane_id_str)
  for _, p in ipairs(tab:panes()) do
    if tostring(p:pane_id()) == pane_id_str then
      return p
    end
  end
end

local function tab_is_zoomed(tab)
  for _, info in ipairs(tab:panes_with_info()) do
    if info.is_zoomed then return true end
  end
  return false
end

local function get_cwd(pane)
  local cwd = pane:get_current_working_dir()
  local dir = cwd and (cwd.file_path or tostring(cwd)) or wezterm.home_dir
  dir = dir:gsub("^file:///", "")
  dir = dir:gsub("^/(%a:)", "%1")
  return dir
end

-- ── Export themes list for the TUI ──────────────────────────────

local function export_themes()
  local themes_file = config_dir .. "/.themes_cache.json"
  local schemes = wezterm.get_builtin_color_schemes()
  local names = {}
  for name in pairs(schemes) do
    table.insert(names, name)
  end
  table.sort(names)
  local ok, json = pcall(wezterm.json_encode, names)
  if ok then
    local f = io.open(themes_file, "w")
    if f then
      f:write(json)
      f:close()
    end
  end
end

-- ── Open finder ─────────────────────────────────────────────────

local function open_finder(window, pane, initial_picker)
  local tab = window:active_tab()
  local tab_key = tostring(tab:tab_id())
  local st = finder_state()

  -- Check if finder pane already exists
  local existing = st.pane_ids[tab_key]
  if existing then
    local finder_pane = find_pane(tab, existing)
    if finder_pane then
      -- Already open — toggle: if we're on it, close it
      local active_id = tostring(tab:active_pane():pane_id())
      if active_id == existing then
        close_finder(window, tab)
        return
      else
        -- Switch to finder pane and zoom
        finder_pane:activate()
        if not tab_is_zoomed(tab) then
          window:perform_action(act.TogglePaneZoomState, finder_pane)
        end
        return
      end
    else
      -- Pane was killed, clean up
      st.pane_ids[tab_key] = nil
      st.original_ids[tab_key] = nil
    end
  end

  -- Export themes for TUI
  export_themes()

  -- Remember current pane
  st.original_ids[tab_key] = tostring(pane:pane_id())

  -- Get CWD
  local cwd = get_cwd(pane)

  -- Create finder pane (bottom split, then zoom)
  local new_pane = pane:split({
    direction = "Bottom",
    size = 0.15,
    cwd = cwd,
  })

  st.pane_ids[tab_key] = tostring(new_pane:pane_id())

  -- Zoom the finder pane to fill the view
  window:perform_action(act.TogglePaneZoomState, new_pane)

  -- Build and send the TUI command
  local args = {
    'python',
    '"' .. TUI_SCRIPT .. '"',
    '"' .. cwd:gsub('"', '\\"') .. '"',
  }
  if initial_picker then
    table.insert(args, '"' .. initial_picker .. '"')
  end
  local cmd = " " .. table.concat(args, " ") .. "\r"
  new_pane:send_text(cmd)

  wezterm.log_info("finder: opened" .. (initial_picker and (" with " .. initial_picker) or ""))
end

local function close_finder(window, tab)
  local tab_key = tostring(tab:tab_id())
  local st = finder_state()

  local finder_pane_id = st.pane_ids[tab_key]
  if not finder_pane_id then return end

  local finder_pane = find_pane(tab, finder_pane_id)
  if finder_pane then
    -- Unzoom first
    if tab_is_zoomed(tab) then
      window:perform_action(act.TogglePaneZoomState, finder_pane)
    end
    -- Return to original pane
    local orig = find_pane(tab, st.original_ids[tab_key] or "")
    if orig then
      orig:activate()
    end
    -- Close the finder pane
    window:perform_action(act.CloseCurrentPane({ confirm = false }), finder_pane)
  end

  st.pane_ids[tab_key] = nil
  st.original_ids[tab_key] = nil
end

-- ── Handle signals from finder TUI ─────────────────────────────

wezterm.on("user-var-changed", function(window, pane, var_name, value)
  if var_name ~= "finder_action" then return end
  if not value or value == "" then return end

  local tab = window:active_tab()

  -- Always close finder first
  close_finder(window, tab)

  -- Parse action
  if value == "close" then
    return
  end

  local action, rest = value:match("^(%w+):(.+)$")
  if not action then return end

  if action == "open" then
    -- rest could be "path" or "path:line"
    local path, line = rest:match("^(.+):(%d+)$")
    if not path then
      path = rest
    end
    if line then
      line = tonumber(line)
    end

    -- Normalize path
    path = path:gsub("\\", "/")

    -- Get center pane to send command to
    local roles = get_pane_roles(tab)
    local target = roles.center or tab:active_pane()

    -- Open file in the active pane's editor (send to shell)
    local is_windows = wezterm.target_triple:find("windows") ~= nil

    -- Try opening in nvim/vim if available, fall back to just printing the path
    local editor = os.getenv("EDITOR") or "nvim"
    if line then
      target:send_text(string.format(" %s +%d %s\r", editor, line, shell_escape(path)))
    else
      target:send_text(string.format(" %s %s\r", editor, shell_escape(path)))
    end

    wezterm.log_info("finder: open " .. path .. (line and (":" .. line) or ""))

  elseif action == "cd" then
    local dir = rest:gsub("\\", "/")
    local is_windows = wezterm.target_triple:find("windows") ~= nil
    local cd_cmd = is_windows and ('cd /d "' .. dir .. '"') or ('cd "' .. dir .. '"')

    -- cd all panes in the tab
    for _, p in ipairs(tab:panes()) do
      p:send_text(cd_cmd .. "\r")
    end

    -- Track project
    local projects = require("modules.projects")
    projects.track(dir)

    wezterm.log_info("finder: cd " .. dir)

  elseif action == "theme" then
    local theme_name = rest
    -- Update globals.lua
    local globals_path = wezterm.config_dir .. "/globals.lua"
    local f = io.open(globals_path, "r")
    if f then
      local content = f:read("*a")
      f:close()
      local updated = content:gsub(
        '(color_scheme%s*=%s*)"[^"]*"',
        '%1"' .. theme_name .. '"'
      )
      local fw = io.open(globals_path, "w")
      if fw then
        fw:write(updated)
        fw:close()
      end
    end
    wezterm.log_info("finder: theme → " .. theme_name)
  end
end)

-- ── Pane role detection (shared with sessions.lua) ──────────────

local function get_pane_roles(tab)
  local panes = tab:panes_with_info()
  table.sort(panes, function(a, b)
    if a.left ~= b.left then return a.left < b.left end
    return a.top < b.top
  end)
  local roles = {}
  local n = #panes
  if n >= 4 then
    roles.left = panes[1].pane
    roles.center = panes[2].pane
    roles.right = panes[3].pane
    roles.sidebar = panes[n].pane
  elseif n == 3 then
    roles.left = panes[1].pane
    roles.center = panes[2].pane
    roles.sidebar = panes[3].pane
  elseif n == 2 then
    roles.center = panes[1].pane
    roles.sidebar = panes[2].pane
  elseif n == 1 then
    roles.center = panes[1].pane
  end
  return roles
end

-- ── Shell escape ────────────────────────────────────────────────

local function shell_escape(path)
  if wezterm.target_triple:find("windows") then
    -- Windows: wrap in double quotes, escape internal doubles
    return '"' .. path:gsub('"', '""') .. '"'
  else
    return "'" .. path:gsub("'", "'\\''") .. "'"
  end
end

-- ── Actions (for keys.lua) ──────────────────────────────────────

function M.open_action(initial_picker)
  return wezterm.action_callback(function(window, pane)
    open_finder(window, pane, initial_picker)
  end)
end

-- ── Module apply ────────────────────────────────────────────────

function M.apply(config, globals)
  -- Nothing to configure at config-build time.
  -- The finder is invoked via actions from keys.lua.
end

return M
