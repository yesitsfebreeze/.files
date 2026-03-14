-- modules/finder.lua: Finder overlays using native WezTerm InputSelector
--
-- Uses InputSelector (mux overlay) instead of spawning fzf panes.
-- No shell scripts, no OSC signals, no pane management needed.
--
-- Keybinding: Leader + f + f → FindFiles
-- Keybinding: Leader + f + g → FindGrep
-- Keybinding: Leader + f + t → Themes
-- Keybinding: Leader + f + <Space> → FinderOpen (picker select)

local wezterm = require("wezterm")
local act = wezterm.action
local utils = require("modules.utils")

local M = {}

local get_cwd = utils.get_cwd

-- ── Helpers ───────────────────────────────────────────────────────

local function shell_escape(path)
  if wezterm.target_triple:find("windows") then
    return '"' .. path:gsub('"', '""') .. '"'
  else
    return "'" .. path:gsub("'", "'\\''") .. "'"
  end
end

--- Run a shell command and return stdout lines as InputSelector choices.
local function run_choices(cmd, formatter)
  local success, stdout, stderr = wezterm.run_child_process({ "bash", "-c", cmd })
  if not success or not stdout or stdout == "" then return {} end
  local choices = {}
  for line in stdout:gmatch("[^\r\n]+") do
    if formatter then
      local choice = formatter(line)
      if choice then table.insert(choices, choice) end
    else
      table.insert(choices, { label = line, id = line })
    end
  end
  return choices
end

-- ── Pane role detection ───────────────────────────────────────────

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

-- ── Actions ───────────────────────────────────────────────────────

local function open_file(tab, path, line)
  local roles = get_pane_roles(tab)
  local target = roles.center or tab:active_pane()
  local editor = os.getenv("EDITOR") or "nvim"
  if line then
    target:send_text(string.format(" %s +%d %s\r", editor, line, shell_escape(path)))
  else
    target:send_text(string.format(" %s %s\r", editor, shell_escape(path)))
  end
end

local function cd_all(tab, dir)
  local is_windows = wezterm.target_triple:find("windows") ~= nil
  local cd_cmd = is_windows and ('cd /d "' .. dir .. '"') or ('cd "' .. dir .. '"')
  for _, p in ipairs(tab:panes()) do
    p:send_text(cd_cmd .. "\r")
  end
  local projects = require("modules.projects")
  projects.track(dir)
end

local function set_theme(name)
  local globals_path = wezterm.config_dir .. "/globals.lua"
  local f = io.open(globals_path, "r")
  if not f then return end
  local content = f:read("*a")
  f:close()
  local updated = content:gsub(
    '(color_scheme%s*=%s*)"[^"]*"',
    '%1"' .. name .. '"'
  )
  local fw = io.open(globals_path, "w")
  if fw then
    fw:write(updated)
    fw:close()
  end
end

-- ── Pickers ───────────────────────────────────────────────────────

local function pick_files(window, pane)
  local cwd = get_cwd(pane)
  local cmd = 'cd ' .. shell_escape(cwd) .. ' && '
    .. '{ fd --type f --hidden --follow --exclude .git --exclude node_modules --exclude __pycache__ --exclude .venv 2>/dev/null'
    .. ' || rg --files --hidden --glob "!.git" --glob "!node_modules" --glob "!__pycache__" --glob "!.venv" 2>/dev/null'
    .. ' || find . -type f -not -path "*/.git/*"; }'
  local choices = run_choices(cmd)
  if #choices == 0 then return end
  window:perform_action(act.InputSelector({
    title = "Files",
    choices = choices,
    fuzzy = true,
    fuzzy_description = " Files > ",
    action = wezterm.action_callback(function(w, p, id, label)
      if not id then return end
      open_file(w:active_tab(), id)
    end),
  }), pane)
end

local function pick_grep(window, pane)
  window:perform_action(act.PromptInputLine({
    description = " Grep > ",
    action = wezterm.action_callback(function(w, p, query)
      if not query or #query < 2 then return end
      local cwd = get_cwd(p)
      local cmd = 'cd ' .. shell_escape(cwd)
        .. ' && rg --line-number --no-heading --color=never --smart-case -- '
        .. shell_escape(query) .. ' 2>/dev/null'
      local choices = run_choices(cmd, function(line)
        local file, lnum, text = line:match("^(.+):(%d+):(.*)$")
        if file then
          return { label = file .. ":" .. lnum .. "  " .. text, id = file .. ":" .. lnum }
        end
        return nil
      end)
      if #choices == 0 then return end
      w:perform_action(act.InputSelector({
        title = "Grep: " .. query,
        choices = choices,
        fuzzy = true,
        fuzzy_description = " Filter > ",
        action = wezterm.action_callback(function(w2, p2, id, label)
          if not id then return end
          local file, lnum = id:match("^(.+):(%d+)$")
          if file then
            open_file(w2:active_tab(), file, tonumber(lnum))
          end
        end),
      }), p)
    end),
  }), pane)
end

local function pick_dirs(window, pane)
  local cwd = get_cwd(pane)
  local cmd = 'cd ' .. shell_escape(cwd) .. ' && '
    .. '{ fd --type d --hidden --follow --exclude .git --exclude node_modules --exclude __pycache__ 2>/dev/null'
    .. ' || find . -type d -not -path "*/.git/*"; }'
  local choices = run_choices(cmd)
  if #choices == 0 then return end
  window:perform_action(act.InputSelector({
    title = "Dirs",
    choices = choices,
    fuzzy = true,
    fuzzy_description = " Dirs > ",
    action = wezterm.action_callback(function(w, p, id, label)
      if not id then return end
      cd_all(w:active_tab(), id)
    end),
  }), pane)
end

local function pick_projects(window, pane)
  local projects_file = wezterm.config_dir .. "/.projects.json"
  local pf = io.open(projects_file, "r")
  if not pf then return end
  local content = pf:read("*a")
  pf:close()
  local ok, data = pcall(wezterm.json_parse, content)
  if not ok or type(data) ~= "table" then return end
  local choices = {}
  for _, proj in ipairs(data) do
    if proj.path and #proj.path > 0 then
      table.insert(choices, { label = proj.path, id = proj.path })
    end
  end
  if #choices == 0 then return end
  window:perform_action(act.InputSelector({
    title = "Projects",
    choices = choices,
    fuzzy = true,
    fuzzy_description = " Projects > ",
    action = wezterm.action_callback(function(w, p, id, label)
      if not id then return end
      cd_all(w:active_tab(), id)
    end),
  }), pane)
end

local function pick_themes(window, pane)
  local schemes = wezterm.color.get_builtin_schemes()
  local names = {}
  for name in pairs(schemes) do
    table.insert(names, name)
  end
  table.sort(names)
  local choices = {}
  for _, name in ipairs(names) do
    table.insert(choices, { label = name, id = name })
  end
  window:perform_action(act.InputSelector({
    title = "Themes",
    choices = choices,
    fuzzy = true,
    fuzzy_description = " Theme > ",
    action = wezterm.action_callback(function(w, p, id, label)
      if not id then return end
      set_theme(id)
    end),
  }), pane)
end

-- ── Picker dispatch ───────────────────────────────────────────────

local pickers = {
  Files    = pick_files,
  Grep     = pick_grep,
  Dirs     = pick_dirs,
  Projects = pick_projects,
  Themes   = pick_themes,
}

local function open_finder(window, pane, initial_picker)
  if initial_picker and pickers[initial_picker] then
    pickers[initial_picker](window, pane)
    return
  end

  -- No picker specified — let user choose
  local picker_choices = {
    { label = " Files  — fuzzy file finder",    id = "Files" },
    { label = " Grep   — ripgrep search",       id = "Grep" },
    { label = " Dirs   — directory picker",     id = "Dirs" },
    { label = " Projects — tracked projects",   id = "Projects" },
    { label = " Themes — color scheme picker",  id = "Themes" },
  }
  window:perform_action(act.InputSelector({
    title = "Finder",
    choices = picker_choices,
    fuzzy = true,
    fuzzy_description = "Pick a finder: ",
    action = wezterm.action_callback(function(w, p, id, label)
      if not id then return end
      if pickers[id] then pickers[id](w, p) end
    end),
  }), pane)
end

-- ── Public API (same interface as before for keys.lua) ────────────

function M.open_action(initial_picker)
  return wezterm.action_callback(function(window, pane)
    open_finder(window, pane, initial_picker)
  end)
end

function M.theme_fzf_action()
  return wezterm.action_callback(function(window, pane)
    pick_themes(window, pane)
  end)
end

function M.apply(config, globals)
  -- No setup needed — everything is lazy.
end

return M
