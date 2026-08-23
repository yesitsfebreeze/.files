-- gates/fixtures/wezterm/wezterm.lua — the self-test fixture for
-- `wezterm_probe`. One key, with a payload no default binding carries, so the
-- probe cannot pass on WezTerm's own defaults.
--
-- `show-keys --lua` prints the MERGED set (defaults PLUS this file's keys), so
-- a gate asserts presence of the intended bindings rather than diffing the
-- whole list. It needs no display, which is what makes it usable headlessly.
local wezterm = require 'wezterm'
return {
  keys = {
    { key = 'F20', mods = 'NONE', action = wezterm.action.SendString 'gate_probe' },
  },
}
