-- modules/workspaces.lua: Workspace / session picker
-- Keybinding: CTRL+SHIFT+ALT+W  → fuzzy-pick or create a workspace
-- Keybinding: CTRL+SHIFT+ALT+S  → switch between active workspaces

local wezterm = require("wezterm")
local act = wezterm.action
local mux = wezterm.mux

local M = {}

-- Project directories to scan for workspaces.
-- Adjust these to your own project roots.
local PROJECT_DIRS = {
  wezterm.home_dir .. "/projects",
  wezterm.home_dir .. "/dev",
  "C:/dev",
}

--- Scan project directories and return workspace choices.
local function discover_projects()
  local choices = {}
  local seen = {}

  for _, base in ipairs(PROJECT_DIRS) do
    local ok, entries = pcall(wezterm.read_dir, base)
    if ok and entries then
      for _, entry in ipairs(entries) do
        local name = entry:match("([^/\\]+)$")
        if name and not seen[name] then
          seen[name] = true
          table.insert(choices, {
            label = name,
            id = entry,
          })
        end
      end
    end
  end

  table.sort(choices, function(a, b) return a.label < b.label end)
  return choices
end

--- List active workspaces.
local function active_workspace_choices()
  local choices = {}
  for _, name in ipairs(mux.get_workspace_names()) do
    table.insert(choices, { label = name })
  end
  table.sort(choices, function(a, b) return a.label < b.label end)
  return choices
end

function M.apply(config, _globals)
  config.keys = config.keys or {}

  -- Open project in a new workspace
  table.insert(config.keys, {
    key = "W",
    mods = "CTRL|SHIFT|ALT",
    action = wezterm.action_callback(function(window, pane)
      local choices = discover_projects()
      table.insert(choices, 1, {
        label = "📁 Enter custom path…",
        id = "__custom__",
      })

      window:perform_action(
        act.InputSelector({
          title = "📂  Open Workspace",
          choices = choices,
          fuzzy = true,
          fuzzy_description = "Pick a project or type to search…",
          action = wezterm.action_callback(function(inner_window, inner_pane, id, label)
            if not id and not label then return end
            if id == "__custom__" then
              inner_window:perform_action(
                act.PromptInputLine({
                  description = "Enter workspace path:",
                  action = wezterm.action_callback(function(w, p, line)
                    if line and #line > 0 then
                      w:perform_action(act.SwitchToWorkspace({
                        name = line:match("([^/\\]+)$") or line,
                        spawn = { cwd = line },
                      }), p)
                    end
                  end),
                }),
                inner_pane
              )
            else
              inner_window:perform_action(act.SwitchToWorkspace({
                name = label,
                spawn = { cwd = id },
              }), inner_pane)
            end
          end),
        }),
        pane
      )
    end),
  })

  -- Switch between active workspaces
  table.insert(config.keys, {
    key = "S",
    mods = "CTRL|SHIFT|ALT",
    action = wezterm.action_callback(function(window, pane)
      local choices = active_workspace_choices()
      if #choices == 0 then
        wezterm.log_info("No other workspaces")
        return
      end

      window:perform_action(
        act.InputSelector({
          title = "🔀  Switch Workspace",
          choices = choices,
          fuzzy = true,
          fuzzy_description = "Pick a workspace…",
          action = wezterm.action_callback(function(_inner_window, inner_pane, _id, label)
            if not label then return end
            inner_pane:window():perform_action(
              act.SwitchToWorkspace({ name = label }),
              inner_pane
            )
          end),
        }),
        pane
      )
    end),
  })
end

return M
