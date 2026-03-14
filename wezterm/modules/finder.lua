-- modules/finder.lua: Full-screen finder overlay using fzf
--
-- Opens fzf in a zoomed overlay pane for each picker type.
-- The fzf wrapper scripts signal back via OSC 1337 user-var "finder_action":
--   open:<path>            — open file in center pane
--   open:<path>:<line>     — open file at line
--   cd:<path>              — cd all panes to directory
--   theme:<name>           — switch color scheme
--   close                  — just close the overlay
--
-- Keybinding: Leader + f + f → FindFiles (Files picker)
-- Keybinding: Leader + f + g → FindGrep (Grep picker)
-- Keybinding: Leader + f + <Space> → FinderOpen (picker select mode)

local wezterm = require("wezterm")
local act = wezterm.action
local utils = require("modules.utils")

local M = {}

local config_dir = wezterm.config_dir:gsub("\\", "/")

-- ── fzf script builders ─────────────────────────────────────────

-- OSC signal helper (reused by all fzf scripts).
-- Works on macOS (no -w flag) and Linux (uses tr to strip newlines).
local SIGNAL_FN = [[
_signal() { printf '\033]1337;SetUserVar=finder_action=%s\a' "$(printf '%s' "$1" | base64 | tr -d '\n')"; }
]]

local function fzf_files_script(cwd)
  return SIGNAL_FN .. [[
cd "]] .. cwd .. [["
if command -v fd >/dev/null 2>&1; then
  SRC="fd --type f --hidden --follow --exclude .git --exclude node_modules --exclude __pycache__ --exclude .venv"
elif command -v rg >/dev/null 2>&1; then
  SRC="rg --files --hidden --glob '!.git' --glob '!node_modules' --glob '!__pycache__' --glob '!.venv'"
else
  SRC="find . -type f -not -path '*/.git/*'"
fi
RESULT=$(eval "$SRC" | fzf --layout=reverse --prompt=" Files > " --border \
  --preview 'bat --color=always --style=numbers --line-range=:500 {} 2>/dev/null || cat {}' \
  --preview-window 'right,50%,border-left')
[ -n "$RESULT" ] && _signal "open:$RESULT" || _signal "close"
]]
end

local function fzf_grep_script(cwd)
  return SIGNAL_FN .. [[
cd "]] .. cwd .. [["
RESULT=$(: | fzf --layout=reverse --prompt=" Grep > " --disabled --border \
  --bind "change:reload:rg --line-number --no-heading --color=never --smart-case -- {q} || true" \
  --delimiter=: \
  --preview 'bat --color=always --highlight-line {2} {1} 2>/dev/null' \
  --preview-window 'right,50%,border-left,+{2}/2')
if [ -n "$RESULT" ]; then
  FILE=$(echo "$RESULT" | cut -d: -f1)
  LINE=$(echo "$RESULT" | cut -d: -f2)
  _signal "open:$FILE:$LINE"
else
  _signal "close"
fi
]]
end

local function fzf_dirs_script(cwd)
  return SIGNAL_FN .. [[
cd "]] .. cwd .. [["
if command -v fd >/dev/null 2>&1; then
  SRC="fd --type d --hidden --follow --exclude .git --exclude node_modules --exclude __pycache__"
else
  SRC="find . -type d -not -path '*/.git/*'"
fi
RESULT=$(eval "$SRC" | fzf --layout=reverse --prompt=" Dirs > " --border)
[ -n "$RESULT" ] && _signal "cd:$RESULT" || _signal "close"
]]
end

local function fzf_projects_script()
  local projects_list = config_dir .. "/.projects_list"
  return SIGNAL_FN .. [[
RESULT=$(fzf --layout=reverse --prompt=" Projects > " --border < "]] .. projects_list .. [[")
[ -n "$RESULT" ] && _signal "cd:$RESULT" || _signal "close"
]]
end

--- Build the fzf script for a given picker name.
local function build_fzf_script(picker_name, cwd)
  if picker_name == "Files" then
    return fzf_files_script(cwd)
  elseif picker_name == "Grep" then
    return fzf_grep_script(cwd)
  elseif picker_name == "Dirs" then
    return fzf_dirs_script(cwd)
  elseif picker_name == "Projects" then
    return fzf_projects_script()
  end
  return nil
end

local function shell_escape(path)
  if wezterm.target_triple:find("windows") then
    return '"' .. path:gsub('"', '""') .. '"'
  else
    return "'" .. path:gsub("'", "'\\''") .. "'"
  end
end

-- ── Pane role detection ─────────────────────────────────────────

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

local find_pane = utils.find_pane
local tab_is_zoomed = utils.tab_is_zoomed
local get_cwd = utils.get_cwd

-- ── Write theme names (plain text, one per line) — lazy, once ───

local function export_themes()
  if wezterm.GLOBAL._themes_exported then return end
  local themes_file = config_dir .. "/.themes_list"
  local schemes = wezterm.color.get_builtin_schemes()
  local names = {}
  for name in pairs(schemes) do
    table.insert(names, name)
  end
  table.sort(names)
  local f = io.open(themes_file, "w")
  if f then
    f:write(table.concat(names, "\n"))
    f:close()
  end
  wezterm.GLOBAL._themes_exported = true
end

-- ── Write project paths (plain text, one per line) — lazy ───────

local function export_projects()
  local projects_list = config_dir .. "/.projects_list"
  local projects_file = config_dir .. "/.projects.json"
  local pf = io.open(projects_file, "r")
  if not pf then
    local out = io.open(projects_list, "w")
    if out then out:close() end
    return
  end
  local content = pf:read("*a")
  pf:close()
  local ok, data = pcall(wezterm.json_parse, content)
  if not ok or type(data) ~= "table" then return end
  local paths = {}
  for _, proj in ipairs(data) do
    if proj.path and #proj.path > 0 then
      table.insert(paths, proj.path)
    end
  end
  local out = io.open(projects_list, "w")
  if out then
    out:write(table.concat(paths, "\n"))
    out:close()
  end
end

-- ── Close finder ────────────────────────────────────────────────

local function close_finder(window, tab)
  local tab_key = tostring(tab:tab_id())
  local st = finder_state()

  local finder_pane_id = st.pane_ids[tab_key]
  if not finder_pane_id then return end

  local finder_pane = find_pane(tab, finder_pane_id)
  if finder_pane then
    -- Unzoom first if zoomed
    if tab_is_zoomed(tab) then
      window:perform_action(act.TogglePaneZoomState, finder_pane)
    end
    -- Return to original pane
    local orig = find_pane(tab, st.original_ids[tab_key] or "")
    if orig then
      orig:activate()
    end
    -- Close the finder pane (may already be closing if fzf exited)
    pcall(function()
      window:perform_action(act.CloseCurrentPane({ confirm = false }), finder_pane)
    end)
  else
    -- Pane already closed (fzf exited); restore focus to original pane
    local orig = find_pane(tab, st.original_ids[tab_key] or "")
    if orig then
      orig:activate()
    end
  end

  st.pane_ids[tab_key] = nil
  st.original_ids[tab_key] = nil
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
      local active_id = tostring(tab:active_pane():pane_id())
      if active_id == existing then
        close_finder(window, tab)
        return
      else
        finder_pane:activate()
        if not tab_is_zoomed(tab) then
          window:perform_action(act.TogglePaneZoomState, finder_pane)
        end
        return
      end
    else
      st.pane_ids[tab_key] = nil
      st.original_ids[tab_key] = nil
    end
  end

  -- Remember current pane
  st.original_ids[tab_key] = tostring(pane:pane_id())

  local cwd = get_cwd(pane)

  -- If no picker specified, let the user choose via InputSelector
  if not initial_picker then
    local picker_choices = {
      { label = " Files  — fuzzy file finder",    id = "Files" },
      { label = " Grep   — live ripgrep search",  id = "Grep" },
      { label = " Dirs   — directory picker",     id = "Dirs" },
      { label = " Projects — tracked projects",   id = "Projects" },
      { label = " Themes — color scheme picker",  id = "Themes" },
    }
    window:perform_action(
      act.InputSelector({
        title = "Finder",
        choices = picker_choices,
        fuzzy = true,
        fuzzy_description = "Pick a finder: ",
        action = wezterm.action_callback(function(inner_window, inner_pane, id, _label)
          if not id then return end
          if id == "Themes" then
            -- Theme picker has its own fzf action
            inner_window:perform_action(M.theme_fzf_action(), inner_pane)
          else
            open_finder(inner_window, inner_pane, id)
          end
        end),
      }),
      pane
    )
    return
  end

  local script = build_fzf_script(initial_picker, cwd)
  if not script then
    wezterm.log_warn("finder: unknown picker '" .. initial_picker .. "'")
    return
  end

  -- Lazy export: write cache files only when the picker that needs them opens
  if initial_picker == "Projects" then export_projects() end

  -- Create finder pane (bottom split, then zoom)
  local new_pane = pane:split({
    direction = "Bottom",
    size = 0.15,
    cwd = cwd,
    args = { "bash", "-c", script },
  })

  st.pane_ids[tab_key] = tostring(new_pane:pane_id())
  window:perform_action(act.TogglePaneZoomState, new_pane)

  wezterm.log_info("finder: opened" .. (initial_picker and (" with " .. initial_picker) or ""))
end

-- ── Handle signals from finder TUI ─────────────────────────────

wezterm.on("user-var-changed", function(window, pane, var_name, value)
  if var_name ~= "finder_action" then return end
  if not value or value == "" then return end

  local tab = window:active_tab()
  close_finder(window, tab)

  if value == "close" then return end

  local action, rest = value:match("^(%w+):(.+)$")
  if not action then return end

  if action == "open" then
    local path, line = rest:match("^(.+):(%d+)$")
    if not path then path = rest end
    if line then line = tonumber(line) end

    path = path:gsub("\\", "/")

    local roles = get_pane_roles(tab)
    local target = roles.center or tab:active_pane()

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

    for _, p in ipairs(tab:panes()) do
      p:send_text(cd_cmd .. "\r")
    end

    local projects = require("modules.projects")
    projects.track(dir)

    wezterm.log_info("finder: cd " .. dir)

  elseif action == "theme" then
    local theme_name = rest
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

-- ── Actions (for keys.lua) ──────────────────────────────────────

function M.open_action(initial_picker)
  return wezterm.action_callback(function(window, pane)
    open_finder(window, pane, initial_picker)
  end)
end

--- Theme picker: fzf in a zoomed scratch pane → updates globals.lua directly.
function M.theme_fzf_action()
  return wezterm.action_callback(function(window, pane)
    export_themes()  -- lazy: writes .themes_list on first use only
    local themes_file = config_dir .. "/.themes_list"
    local globals_file = config_dir .. "/globals.lua"

    -- Bash script: fzf selection → sed updates globals.lua → WezTerm hot-reloads.
    local script = [[
THEME=$(fzf --layout=reverse --prompt=" Theme > " < "$1")
[ -z "$THEME" ] && exit 0
sed -i "s/color_scheme = \"[^\"]*\"/color_scheme = \"$THEME\"/" "$2"
]]

    local new_pane = pane:split({
      direction = "Bottom",
      size = 0.15,
      args = { "bash", "-c", script, "_", themes_file, globals_file },
    })
    window:perform_action(act.TogglePaneZoomState, new_pane)
  end)
end

function M.apply(config, globals)
  -- Exports are lazy: themes/projects lists are written on first picker use,
  -- not at config-load time, to keep startup fast.
end

return M
