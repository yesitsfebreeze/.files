-- modules/sessions.lua: Agent session tracker with sidebar pane
--
-- Tracks multi-agent sessions (Claude, OpenCode, Aider, etc.) in .sessions.json.
-- Uses a shell script with fzf in the sidebar pane for interactive session management.
-- When a session is selected, switches the center pane to run that agent.
--
-- Signals back via OSC 1337 user-var "session_action":
--   select:<id>            — switch center pane to this session
--   rename:<id>:<name>     — rename
--   add:<agent>:<name>     — new session added
--   delete:<id>            — session removed

local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

local config_dir = wezterm.config_dir:gsub("\\", "/")
local SESSIONS_FILE = config_dir .. "/.sessions.json"

-- Agent type → default command to launch in the center pane.
-- Users can customize these or the session can store a custom cmd.
local AGENT_COMMANDS = {
  claude   = "claude",
  opencode = "opencode",
  aider    = "aider",
  copilot  = "gh copilot",
  cursor   = "cursor",
  shell    = "",         -- just a shell, no agent
  other    = "",
}

-- ── Session persistence ─────────────────────────────────────────

local function load_sessions()
  local f = io.open(SESSIONS_FILE, "r")
  if not f then return {} end
  local content = f:read("*a")
  f:close()
  if not content or #content == 0 then return {} end
  local ok, data = pcall(wezterm.json_parse, content)
  if not ok or type(data) ~= "table" then return {} end
  return data
end

local function save_sessions(sessions)
  local ok, json = pcall(wezterm.json_encode, sessions)
  if not ok then return end
  local f = io.open(SESSIONS_FILE, "w")
  if not f then return end
  f:write(json)
  f:close()
end

local function find_session_by_id(sessions, id)
  for i, s in ipairs(sessions) do
    if tostring(s.id) == tostring(id) then
      return s, i
    end
  end
  return nil, nil
end

-- ── State (survives config reloads) ─────────────────────────────

local function get_state()
  if not wezterm.GLOBAL.sessions then
    wezterm.GLOBAL.sessions = {
      sidebar_pane_ids = {},   -- tab_id → sidebar pane_id
      session_pane_ids = {},   -- session_id → pane_id (center pane running the agent)
      active_session = nil,    -- currently selected session id
    }
  end
  return wezterm.GLOBAL.sessions
end

-- ── Pane helpers ────────────────────────────────────────────────

local function get_pane_roles(tab)
  local panes = tab:panes_with_info()
  table.sort(panes, function(a, b)
    if a.left ~= b.left then return a.left < b.left end
    return a.top < b.top
  end)
  -- With 4+ panes: left, center, right, sidebar (rightmost)
  -- With 3: left, center, sidebar
  -- With 2: center, sidebar
  -- With 1: center
  local roles = {}
  local n = #panes
  if n >= 4 then
    roles.left = panes[1].pane
    roles.center = panes[2].pane
    roles.right = panes[3].pane
    roles.sidebar = panes[n].pane  -- rightmost
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

local function pane_cwd(pane)
  local url = pane:get_current_working_dir()
  if not url then return nil end
  local path = url.file_path or tostring(url)
  path = path:gsub("^file:///", "")
  if path == "" then return nil end
  return path
end

-- ── Send agent command to center pane ───────────────────────────

local function send_to_center(tab, session)
  local roles = get_pane_roles(tab)
  if not roles.center then return end

  local agent = session.agent or "shell"
  local cmd = session.cmd or AGENT_COMMANDS[agent] or ""

  -- Batch: interrupt + clear + run agent in a single send_text
  local text = "\x03 clear\r"
  if cmd and #cmd > 0 then
    text = text .. " " .. cmd .. "\r"
  end
  roles.center:send_text(text)
end

-- ── Export sessions as text for fzf ─────────────────────────────

local function export_sessions_list()
  local sessions = load_sessions()
  local lines = {}
  local icon_map = {
    claude = "◈", opencode = "◆", aider = "▣",
    copilot = "◉", cursor = "◎", shell = "▸", other = "○",
  }
  for _, s in ipairs(sessions) do
    local icon = icon_map[s.agent or "other"] or "○"
    local active = s.active and "▶ " or "  "
    local line = string.format("%s%s %s [%s]", active, icon, s.name or "unnamed", tostring(s.id))
    table.insert(lines, line)
  end
  local list_file = config_dir .. "/.sessions_list"
  local f = io.open(list_file, "w")
  if f then
    f:write(table.concat(lines, "\n"))
    f:close()
  end
  return list_file
end

-- ── Start sidebar TUI in a pane (fzf-based) ─────────────────────

local function start_sidebar_tui(pane)
  local list_file = export_sessions_list()
  -- fzf session picker that signals back via OSC user-var
  local script = [=[
_signal() { printf '\033]1337;SetUserVar=session_action=%s\a' "$(printf '%s' "$1" | base64 | tr -d '\n')"; }
while true; do
  SEL=$(fzf --layout=reverse --prompt="Session > " --border --no-info < "]=] .. list_file .. [=[")
  if [ -z "$SEL" ]; then break; fi
  ID=$(echo "$SEL" | grep -o '\[.*\]' | tr -d '[]')
  [ -n "$ID" ] && _signal "select:$ID"
  sleep 0.2
done
]=]
  pane:send_text("\x03 clear\r bash -c " .. "'" .. script:gsub("'", "'\\''" ) .. "'" .. "\r")
end

-- ── Refresh the sidebar (re-run TUI to pick up changes) ─────────

local function refresh_sidebar(tab)
  local state = get_state()
  local tab_key = tostring(tab:tab_id())
  local sidebar_pane_id = state.sidebar_pane_ids[tab_key]
  if not sidebar_pane_id then return end

  local roles = get_pane_roles(tab)
  if roles.sidebar and tostring(roles.sidebar:pane_id()) == tostring(sidebar_pane_id) then
    start_sidebar_tui(roles.sidebar)
  end
end

-- ── Handle signals from sidebar TUI ────────────────────────────

wezterm.on("user-var-changed", function(window, pane, var_name, value)
  if var_name ~= "session_action" then return end
  if not value or value == "" then return end

  local tab = window:active_tab()

  -- Parse action
  local action, rest = value:match("^(%w+):(.+)$")
  if not action then return end

  if action == "select" then
    local session_id = rest
    local sessions = load_sessions()
    local session = find_session_by_id(sessions, session_id)
    if session then
      get_state().active_session = session.id
      send_to_center(tab, session)
      wezterm.log_info("sessions: switched to " .. (session.name or "unnamed"))
    end

  elseif action == "rename" then
    -- Format: rename:<id>:<new_name>
    -- TUI already saved to JSON, just log
    local id, name = rest:match("^([^:]+):(.+)$")
    if id and name then
      wezterm.log_info("sessions: renamed " .. id .. " → " .. name)
    end

  elseif action == "add" then
    -- Format: add:<agent>:<name>
    -- TUI already saved to JSON
    local agent, name = rest:match("^([^:]+):(.+)$")
    if agent and name then
      wezterm.log_info("sessions: added " .. agent .. " session '" .. name .. "'")
    end

  elseif action == "delete" then
    local session_id = rest
    local state = get_state()
    if tostring(state.active_session) == tostring(session_id) then
      state.active_session = nil
    end
    wezterm.log_info("sessions: deleted session " .. session_id)
  end
end)

-- ── Actions (for keybindings) ───────────────────────────────────

-- Toggle sidebar visibility: if sidebar is running, focus it; if not, start it
function M.toggle_sidebar()
  return wezterm.action_callback(function(window, pane)
    local tab = window:active_tab()
    local roles = get_pane_roles(tab)

    if roles.sidebar then
      -- Focus the sidebar pane
      roles.sidebar:activate()
    else
      -- Create a sidebar split on the right
      local new_pane = pane:split({
        direction = "Right",
        size = 0.12,
      })
      local state = get_state()
      local tab_key = tostring(tab:tab_id())
      state.sidebar_pane_ids[tab_key] = tostring(new_pane:pane_id())
      start_sidebar_tui(new_pane)
    end
  end)
end

-- Open session picker (InputSelector fallback if sidebar isn't available)
function M.pick_session()
  return wezterm.action_callback(function(window, pane)
    local sessions = load_sessions()
    if #sessions == 0 then
      wezterm.log_info("sessions: no sessions to pick from")
      return
    end

    local choices = {}
    for _, s in ipairs(sessions) do
      local icon = s.agent or "other"
      local label = icon .. "  " .. (s.name or "unnamed")
      if s.active then
        label = "▶ " .. label
      end
      table.insert(choices, {
        label = label,
        id = tostring(s.id),
      })
    end

    window:perform_action(
      act.InputSelector({
        title = "Agent Sessions",
        choices = choices,
        fuzzy = true,
        fuzzy_description = "Pick a session…",
        action = wezterm.action_callback(function(inner_window, inner_pane, id, _label)
          if not id then return end
          local sess = load_sessions()
          local session = find_session_by_id(sess, id)
          if session then
            -- Mark active
            for _, ss in ipairs(sess) do
              ss.active = (tostring(ss.id) == tostring(id))
            end
            save_sessions(sess)

            get_state().active_session = session.id
            local tab = inner_window:active_tab()
            send_to_center(tab, session)
            refresh_sidebar(tab)
          end
        end),
      }),
      pane
    )
  end)
end

-- Add a new session (uses InputSelector for agent type, then PromptInputLine for name)
function M.add_session()
  return wezterm.action_callback(function(window, pane)
    local agent_choices = {
      { label = "◈ claude",   id = "claude" },
      { label = "◆ opencode", id = "opencode" },
      { label = "▣ aider",    id = "aider" },
      { label = "◉ copilot",  id = "copilot" },
      { label = "◎ cursor",   id = "cursor" },
      { label = "▸ shell",    id = "shell" },
      { label = "○ other",    id = "other" },
    }

    window:perform_action(
      act.InputSelector({
        title = "New Session — Pick Agent",
        choices = agent_choices,
        fuzzy = true,
        action = wezterm.action_callback(function(inner_window, inner_pane, agent_id, _label)
          if not agent_id then return end
          inner_window:perform_action(
            act.PromptInputLine({
              description = "Session name:",
              action = wezterm.action_callback(function(w, p, line)
                if not line or #line == 0 then return end
                local sessions = load_sessions()
                local max_id = 0
                for _, s in ipairs(sessions) do
                  if type(s.id) == "number" and s.id > max_id then
                    max_id = s.id
                  end
                end
                table.insert(sessions, {
                  id = max_id + 1,
                  name = line,
                  agent = agent_id,
                  active = false,
                })
                save_sessions(sessions)
                local tab = w:active_tab()
                refresh_sidebar(tab)
                wezterm.log_info("sessions: added " .. agent_id .. " '" .. line .. "'")
              end),
            }),
            inner_pane
          )
        end),
      }),
      pane
    )
  end)
end

-- ── Module setup ────────────────────────────────────────────────

function M.setup_sidebar_on_layout(gui_win, tab, globals)
  -- Called after layout splits are applied.
  -- The rightmost pane becomes the sidebar.
  local roles = get_pane_roles(tab)
  if roles.sidebar then
    local state = get_state()
    local tab_key = tostring(tab:tab_id())
    state.sidebar_pane_ids[tab_key] = tostring(roles.sidebar:pane_id())
    start_sidebar_tui(roles.sidebar)
  end
end

-- Listen for layout completion to start the sidebar
wezterm.on("sessions-init-sidebar", function(gui_win, tab)
  local roles = get_pane_roles(tab)
  if roles.sidebar then
    local state = get_state()
    local tab_key = tostring(tab:tab_id())
    state.sidebar_pane_ids[tab_key] = tostring(roles.sidebar:pane_id())
    -- Small delay to let the pane settle before sending commands
    start_sidebar_tui(roles.sidebar)
  end
end)

function M.apply(config, globals)
  -- Sessions keybindings are wired through globals.followers in keys.lua
  -- via the custom actions registered below.
end

-- Export custom actions for keys.lua
M.ToggleSidebar = M.toggle_sidebar()
M.PickSession   = M.pick_session()
M.AddSession    = M.add_session()

return M
