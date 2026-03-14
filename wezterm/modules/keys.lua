-- modules/keys.lua: Leader key bindings with multi-key sequence support.
-- Builds keybindings + key_tables from globals.followers tree structure.
-- Items with "children" create sub-menus via WezTerm key_tables.

local wezterm = require("wezterm")
local act = wezterm.action
local projects = require("modules.projects")
local finder = require("modules.pickers.finder")
local scratch = require("modules.scratch")
local sessions = require("modules.sessions")

local M = {}

-- Custom actions that need callbacks (not simple wezterm.action calls).
local custom_actions = {
  CloseTabIfMultiple = wezterm.action_callback(function(window, pane)
    local tab = window:active_tab()
    local tabs = window:mux_window():tabs()
    if #tabs > 1 then
      tab:activate()
      window:perform_action(act.CloseCurrentTab({ confirm = false }), pane)
    end
  end),

  SpawnTabWithLayout = wezterm.action_callback(function(window, pane)
    local tab, _, _ = window:mux_window():spawn_tab({})
    wezterm.emit("apply-pane-layout", window, tab)
  end),

  ToggleScratch   = scratch.toggle_scratch(),
  CloseCurrentPane = act.CloseCurrentPane({ confirm = false }),
  ResetPanesToProject = wezterm.action_callback(projects.reset_panes),
  OpenProjectPicker   = wezterm.action_callback(projects.open_project_picker),
  FindFiles           = finder.find_files_action(),
  FindGrep            = finder.find_grep_action(),
  ToggleSidebar       = sessions.ToggleSidebar,
  PickSession         = sessions.PickSession,
  AddSession          = sessions.AddSession,

  ClearAllPanes = wezterm.action_callback(function(window, pane)
    local tab = window:active_tab()
    for _, p in ipairs(tab:panes()) do
      p:inject_output("\x0c")
      window:perform_action(act.SendString("clear\n"), p)
    end
  end),
}

-- Map action name strings from globals to actual wezterm.action calls.
local function resolve_action(name, args)
  if custom_actions[name] then return custom_actions[name] end

  local fn = act[name]
  if not fn then
    wezterm.log_warn("Unknown action: " .. tostring(name))
    return nil
  end
  if args ~= nil then
    return fn(args)
  else
    return fn
  end
end

-- Build key_table entries from a list of follower entries.
-- Populates config.key_tables for any children.
local function build_subtable(entries, key_tables, timeout_ms)
  local keys = {}
  for _, entry in ipairs(entries) do
    if entry.children then
      local table_name = "leader_" .. entry.key
      key_tables[table_name] = build_subtable(entry.children, key_tables, timeout_ms)
      table.insert(keys, {
        key = entry.key,
        action = act.ActivateKeyTable({
          name = table_name,
          one_shot = true,
          timeout_milliseconds = timeout_ms,
        }),
      })
    else
      local action = resolve_action(entry.action, entry.args)
      if action then
        table.insert(keys, {
          key = entry.key,
          mods = entry.mods or nil,
          action = action,
        })
      end
    end
  end
  table.insert(keys, { key = "Escape", action = act.PopKeyTable })
  return keys
end

function M.apply(config, globals)
  config.keys = config.keys or {}
  config.key_tables = config.key_tables or {}

  -- ── Native leader key (handled at Rust level — zero Lua overhead) ──
  local ldr = globals.leader or {}
  local is_mac = wezterm.target_triple:find("apple") ~= nil
  local default_mods = is_mac and "SUPER" or "CTRL"
  local timeout_ms = ldr.timeout_ms or 1500
  config.leader = {
    key = ldr.key or "q",
    mods = ldr.mods or default_mods,
    timeout_milliseconds = timeout_ms,
  }

  -- ── Standard clipboard shortcuts ──
  table.insert(config.keys, { key = "v", mods = "CTRL",       action = act.PasteFrom("Clipboard") })
  table.insert(config.keys, { key = "c", mods = "CTRL|SHIFT", action = act.CopyTo("Clipboard") })
  table.insert(config.keys, { key = "v", mods = "CTRL|SHIFT", action = act.PasteFrom("Clipboard") })

  -- ── Follower keybindings (LEADER mod) + key_tables for sub-menus ──
  local followers = globals.followers or {}
  for _, entry in ipairs(followers) do
    if entry.children then
      -- Branch: LEADER + key → activate a key table for the sub-menu
      local table_name = "leader_" .. entry.key
      config.key_tables[table_name] = build_subtable(
        entry.children, config.key_tables, timeout_ms
      )
      table.insert(config.keys, {
        key = entry.key,
        mods = "LEADER",
        action = act.ActivateKeyTable({
          name = table_name,
          one_shot = true,
          timeout_milliseconds = timeout_ms,
        }),
      })
    else
      -- Leaf: LEADER + key → execute action directly
      local action = resolve_action(entry.action, entry.args)
      if action then
        table.insert(config.keys, {
          key = entry.key,
          mods = "LEADER" .. (entry.mods and ("|" .. entry.mods) or ""),
          action = action,
        })
      end
    end
  end
end

-- Export for leader_overlay
M.resolve_action = resolve_action

return M
