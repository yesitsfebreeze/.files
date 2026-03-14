-- modules/projects.lua: Project tracking and pane reset
-- Maintains a list of project root directories sorted by last access.
--
-- Keybindings (LEADER):
--   Leader + h  → Reset all panes in current tab to project root ("home")
--   Leader + o  → Open project picker (spawns new pane to project)

local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

local PROJECTS_FILE = wezterm.config_dir .. "/.projects.json"

-- ── Persistence ─────────────────────────────────────────────────

local function load_projects()
  local f = io.open(PROJECTS_FILE, "r")
  if not f then return {} end
  local content = f:read("*a")
  f:close()
  if not content or #content == 0 then return {} end
  local ok, data = pcall(wezterm.json_parse, content)
  if not ok or type(data) ~= "table" then return {} end
  return data
end

local function save_projects(projects)
  table.sort(projects, function(a, b)
    return (a.last_access or 0) > (b.last_access or 0)
  end)
  local ok, json = pcall(wezterm.json_encode, projects)
  if not ok then return end
  local f = io.open(PROJECTS_FILE, "w")
  if not f then return end
  f:write(json)
  f:close()
end

-- ── Path helpers ────────────────────────────────────────────────

local function normalize(path)
  return path:gsub("\\", "/"):gsub("/+$", ""):lower()
end

local function is_child_of(child, parent)
  local nc = normalize(child)
  local np = normalize(parent)
  if nc == np then return true end
  return nc:sub(1, #np + 1) == np .. "/"
end

-- ── Core logic ─────────────────────────────────────────────────

local function track(path)
  if not path or #path == 0 then return end
  path = path:gsub("[/\\]+$", "")

  local projects = load_projects()
  for i, proj in ipairs(projects) do
    if is_child_of(path, proj.path) then
      projects[i].last_access = os.time()
      save_projects(projects)
      return
    end
  end

  table.insert(projects, {
    path = path,
    last_access = os.time(),
  })
  save_projects(projects)
end

local function find_project_root(path)
  if not path then return nil end
  local projects = load_projects()
  for _, proj in ipairs(projects) do
    if is_child_of(path, proj.path) then
      return proj.path
    end
  end
  return nil
end

local function pane_cwd(pane)
  local url = pane:get_current_working_dir()
  if not url then return nil end
  local path = url.file_path or tostring(url)
  path = path:gsub("^file:///", "")
  if path == "" then return nil end
  return path
end

-- ── Actions ─────────────────────────────────────────────────────

local function reset_panes(window, pane)
  local cwd = pane_cwd(pane)
  local root = find_project_root(cwd)
  if not root then
    wezterm.log_info("projects: no project root found for " .. tostring(cwd))
    return
  end

  track(cwd)
  local quoted = '"' .. root:gsub('"', '\\"') .. '"'
  local tab = window:active_tab()
  for _, p in ipairs(tab:panes()) do
    p:send_text("cd " .. quoted .. "\r")
  end
end

local function project_choices()
  local projects = load_projects()
  local choices = {}
  for _, proj in ipairs(projects) do
    local name = proj.path:match("([^/\\]+)$") or proj.path
    local ago = ""
    if proj.last_access then
      local diff = os.time() - proj.last_access
      if diff < 60 then ago = "just now"
      elseif diff < 3600 then ago = math.floor(diff / 60) .. "m ago"
      elseif diff < 86400 then ago = math.floor(diff / 3600) .. "h ago"
      else ago = math.floor(diff / 86400) .. "d ago"
      end
    end
    table.insert(choices, {
      label = name .. "  (" .. ago .. ")  " .. proj.path,
      id = proj.path,
    })
  end
  return choices
end

local function open_project_picker(window, pane)
  local cwd = pane_cwd(pane)
  if cwd then track(cwd) end

  local choices = project_choices()
  if #choices == 0 then
    wezterm.log_info("projects: no projects tracked yet")
    return
  end

  window:perform_action(
    act.InputSelector({
      title = "Projects",
      description = "Select project to open",
      choices = choices,
      fuzzy = true,
      fuzzy_description = "Filter: ",
      action = wezterm.action_callback(function(inner_window, inner_pane, id, label)
        if not id then return end
        track(id)
        inner_window:perform_action(
          act.SpawnCommandInNewPane({
            args = {},
            cwd = id,
          }),
          inner_pane
        )
      end),
    }),
    pane
  )
end

-- ── Module setup ─────────────────────────────────────────────────

function M.apply(config, _globals)
end

M.track = track
M.reset_panes = reset_panes
M.open_project_picker = open_project_picker

return M
