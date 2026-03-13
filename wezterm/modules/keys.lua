-- modules/keys.lua: Leader key bindings.
-- Builds follower keybindings from globals.followers using native LEADER modifier.

local wezterm = require("wezterm")
local act = wezterm.action

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

function M.apply(config, globals)
  config.keys = config.keys or {}

  -- ── Native leader key (handled at Rust level — zero Lua overhead) ──
  local ldr = globals.leader or {}
  local is_mac = wezterm.target_triple:find("apple") ~= nil
  local default_mods = is_mac and "SUPER" or "CTRL"
  config.leader = {
    key = ldr.key or "q",
    mods = ldr.mods or default_mods,
    timeout_milliseconds = ldr.timeout_ms or 1500,
  }

  -- ── Standard clipboard shortcuts ──
  table.insert(config.keys, { key = "v", mods = "CTRL",       action = act.PasteFrom("Clipboard") })
  table.insert(config.keys, { key = "c", mods = "CTRL|SHIFT", action = act.CopyTo("Clipboard") })
  table.insert(config.keys, { key = "v", mods = "CTRL|SHIFT", action = act.PasteFrom("Clipboard") })

  -- ── Follower keybindings (LEADER mod) ──
  local key_defs = globals.followers or {}
  for _, k in ipairs(key_defs) do
    local action = resolve_action(k.action, k.args)
    if action then
      table.insert(config.keys, {
        key = k.key,
        mods = "LEADER" .. (k.mods and ("|" .. k.mods) or ""),
        action = action,
      })
    end
  end
end

return M
