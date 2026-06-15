-- WezTerm: a plain cross-platform host terminal. Multiplexing lives in the shell
-- via burrito, not here, so the setup is portable to any terminal. Colors come
-- from WezTerm's builtin "Gruvbox dark, hard (base16)" scheme as the base; the
-- shell's tinty `theme` switcher retints the ANSI palette live on top via
-- tinted-shell OSC sequences, so WezTerm follows your pick without templating.

local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder()

local triple = wezterm.target_triple
local is_windows = triple:find("windows") ~= nil
local is_mac = triple:find("darwin") ~= nil

local home = os.getenv("HOME") or os.getenv("USERPROFILE") or ""

-- Explicit config dir so the same ~/.config/nushell files are used on every OS.
local nu_config = home .. "/.config/nushell/config.nu"
local nu_env = home .. "/.config/nushell/env.nu"

if is_windows then
    -- Windows is a thin host: launch into WSL. The login shell (-lic) sets PATH
    -- so `nu` resolves; `|| exec bash` keeps the terminal usable if nu isn't
    -- installed in WSL yet.
    config.default_prog = { "wsl.exe", "-d", "Ubuntu", "--cd", "~", "-e", "bash", "-lic", "exec nu || exec bash" }
else
    config.default_prog = { "nu", "--config", nu_config, "--env-config", nu_env }
end

config.set_environment_variables = {
    XDG_CONFIG_HOME = home .. "/.config",
}

-- Appearance — builtin base16 gruvbox base; tinty retints ANSI live on top.
config.color_scheme = "Gruvbox dark, hard (base16)"
config.default_cursor_style = "BlinkingBlock"

-- Font: DepartureMono Nerd Font (installed via packages.yaml `nerd-font`);
-- the rest are fallbacks.
config.font = wezterm.font_with_fallback({
    "DepartureMono Nerd Font",
    "Departure Mono",
    "JetBrainsMono Nerd Font",
    "Cascadia Code",
    "Menlo",
})
config.font_size = is_mac and 14.0 or 11.0
config.line_height = 1.05

-- Also search the installer's per-user font dir, so a freshly-downloaded font
-- resolves before the system font cache refreshes.
if is_windows then
    config.font_dirs = { (os.getenv("LOCALAPPDATA") or (home .. "/AppData/Local")) .. "/Microsoft/Windows/Fonts" }
elseif is_mac then
    config.font_dirs = { home .. "/Library/Fonts" }
else
    config.font_dirs = { home .. "/.local/share/fonts" }
end

config.window_background_opacity = 0.97
config.macos_window_background_blur = 20
config.window_decorations = "RESIZE"
config.window_padding = { left = 8, right = 8, top = 6, bottom = 6 }
config.inactive_pane_hsb = { saturation = 0.85, brightness = 0.7 }
config.scrollback_lines = 10000
config.audible_bell = "Disabled"

config.use_fancy_tab_bar = false
config.hide_tab_bar_if_only_one_tab = true
config.tab_bar_at_bottom = false
config.show_new_tab_button_in_tab_bar = false

wezterm.on("update-right-status", function(window, _pane)
    window:set_right_status(wezterm.format({
        { Foreground = { AnsiColor = "Blue" } },
        { Text = "  " .. window:active_workspace() .. "  " },
    }))
end)

-- No WezTerm plugins, by design: resurrect.wezterm was removed because at config
-- load it shells out via os.execute(), and wezterm-gui has no console, so Windows
-- spawned a visible conhost window per call — flashing terminals on every launch.
-- Keybindings are terminal-level only; burrito owns the grid (its leader is
-- ctrl+space), so there's no leader or mux emulation here.
config.keys = {
    { key = "v", mods = "CTRL", action = act.PasteFrom("Clipboard") },
    -- CTRL-C copies when a selection exists, otherwise falls through to the
    -- shell as a normal interrupt (SIGINT) so it keeps its terminal meaning.
    {
        key = "c",
        mods = "CTRL",
        action = wezterm.action_callback(function(window, pane)
            local sel = window:get_selection_text_for_pane(pane)
            if sel and sel ~= "" then
                window:perform_action(act.CopyTo("ClipboardAndPrimarySelection"), pane)
                window:perform_action(act.ClearSelection, pane)
            else
                window:perform_action(act.SendKey({ key = "c", mods = "CTRL" }), pane)
            end
        end),
    },
}

return config
