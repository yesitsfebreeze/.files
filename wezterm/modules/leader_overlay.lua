-- modules/leader_overlay.lua: Visual cheat-sheet for leader key mode.
-- • Status bar shows "LEADER" + hint when leader is active.
-- • Leader + ? opens a fuzzy picker overlay listing every follower key.
--   Selecting an entry executes the action immediately.

local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

local function resolve_action(name, args)
  local fn = act[name]
  if not fn then return nil end
  if args ~= nil then return fn(args) end
  return fn
end

function M.apply(config, globals)
  local followers = globals.followers or {}

  -- ── Build InputSelector choices ──────────────────────────────
  local choices = {}
  for i, f in ipairs(followers) do
    local desc = f.desc or f.action
    local label = string.format(" %-5s  %s", f.key, desc)
    table.insert(choices, { id = tostring(i), label = label })
  end

  -- ── Leader + ? → open the overlay ──────────────────────────────
  -- "?" is Shift+/ on most layouts.
  config.keys = config.keys or {}
  table.insert(config.keys, {
    key = "/",
    mods = "LEADER|SHIFT",
    action = act.InputSelector({
      title = "  Leader Key Actions",
      choices = choices,
      fuzzy = true,
      action = wezterm.action_callback(function(window, pane, id, label)
        if not id then return end
        local idx = tonumber(id)
        local f = followers[idx]
        if f then
          local a = resolve_action(f.action, f.args)
          if a then window:perform_action(a, pane) end
        end
      end),
    }),
  })

  -- ── Status bar: LEADER indicator ─────────────────────────────
  wezterm.on("update-right-status", function(window, pane)
    if not window:leader_is_active() then
      window:set_right_status("")
      return
    end

    window:set_right_status(wezterm.format({
      { Attribute = { Intensity = "Bold" } },
      { Foreground = { Color = "#f9e2af" } },
      { Background = { Color = "#313244" } },
      { Text = "  LEADER  " },
      "ResetAttributes",
      { Foreground = { Color = "#a6adc8" } },
      { Background = { Color = "#1e1e2e" } },
      { Text = "  ? help  " },
      "ResetAttributes",
    }))
  end)
end

return M
