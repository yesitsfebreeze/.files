-- WezTerm: a PLAIN cross-platform host terminal. Multiplexing (tabs, panes,
-- named sessions, restore-across-restart) has been moved OUT of WezTerm and into
-- the shell via Zellij, so the setup is portable to any terminal. See
-- /.proj/plans/zellij-wsl-multiplexer.md for the decision and rollout.
--
-- Status: the resurrect.wezterm plugin (which flashed console windows on Windows)
-- is removed. The remaining LEADER mux keybindings below are transitional and are
-- retired in the cutover slice, once Zellij is provisioned (incl. inside WSL on
-- Windows, where Zellij runs since it has no native Windows build).
--
-- OS branching is done at runtime via wezterm.target_triple, so this file is
-- shipped verbatim by chezmoi (no template processing).

local wezterm = require("wezterm")
local act = wezterm.action
local mux = wezterm.mux
local config = wezterm.config_builder()

-- ---------------------------------------------------------------------------
-- Platform detection
-- ---------------------------------------------------------------------------
local triple = wezterm.target_triple
local is_windows = triple:find("windows") ~= nil
local is_mac = triple:find("darwin") ~= nil

local home = os.getenv("HOME") or os.getenv("USERPROFILE") or ""

-- Launch Nushell with an explicit config dir so the SAME ~/.config/nushell files
-- are used on every OS, regardless of Nushell's per-platform default config dir.
local nu_config = home .. "/.config/nushell/config.nu"
local nu_env = home .. "/.config/nushell/env.nu"

if is_windows then
    config.default_prog = { "nu.exe", "--config", nu_config, "--env-config", nu_env }
else
    config.default_prog = { "nu", "--config", nu_config, "--env-config", nu_env }
end

config.set_environment_variables = {
    XDG_CONFIG_HOME = home .. "/.config",
}

-- ---------------------------------------------------------------------------
-- Appearance (Catppuccin Mocha)
-- ---------------------------------------------------------------------------
config.color_scheme = "Catppuccin Mocha"

-- Font: DepartureMono Nerd Font. Identity + cross-platform install live in
-- packages.yaml (entry `nerd-font`); the run_onchange installer downloads it
-- from the nerd-fonts release if no package manager provides it, so the primary
-- entry below always resolves. The remaining entries are graceful fallbacks.
config.font = wezterm.font_with_fallback({
    "DepartureMono Nerd Font",
    "Departure Mono",
    "JetBrainsMono Nerd Font",
    "Cascadia Code",
    "Menlo",
})
config.font_size = is_mac and 14.0 or 11.0
config.line_height = 1.05

-- Also search the per-user OS font directory the installer writes to, so a
-- freshly-downloaded font resolves even before the system font cache refreshes.
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

-- Show the active workspace (session) name in the right status area.
wezterm.on("update-right-status", function(window, _pane)
    window:set_right_status(wezterm.format({
        { Foreground = { Color = "#89b4fa" } },
        { Text = "  " .. window:active_workspace() .. "  " },
    }))
end)

-- ---------------------------------------------------------------------------
-- NOTE: no WezTerm plugins are loaded here, by design.
-- Session persistence / multiplexing is being moved OUT of WezTerm and INTO the
-- shell (Zellij), so WezTerm stays a plain terminal that works identically under
-- any host. The previous resurrect.wezterm plugin was removed because, at config
-- load, it shells out via os.execute() ("mkdir", git) and -- since wezterm-gui is
-- a GUI process with no console -- Windows allocated a NEW visible conhost window
-- for each call, flashing several terminals and slowing every launch.
-- ---------------------------------------------------------------------------
-- Keybindings: a tmux-like leader (CTRL-a) so muscle memory is consistent.
-- ---------------------------------------------------------------------------
config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 1000 }

config.keys = {
    -- Splits
    { key = "|", mods = "LEADER|SHIFT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
    { key = "-", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },

    -- Pane navigation
    { key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
    { key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down") },
    { key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
    { key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right") },

    -- Pane resize
    { key = "LeftArrow", mods = "LEADER", action = act.AdjustPaneSize({ "Left", 5 }) },
    { key = "DownArrow", mods = "LEADER", action = act.AdjustPaneSize({ "Down", 5 }) },
    { key = "UpArrow", mods = "LEADER", action = act.AdjustPaneSize({ "Up", 5 }) },
    { key = "RightArrow", mods = "LEADER", action = act.AdjustPaneSize({ "Right", 5 }) },

    -- Pane lifecycle
    { key = "x", mods = "LEADER", action = act.CloseCurrentPane({ confirm = true }) },
    { key = "z", mods = "LEADER", action = act.TogglePaneZoomState },

    -- Tabs
    { key = "c", mods = "LEADER", action = act.SpawnTab("CurrentPaneDomain") },
    { key = "n", mods = "LEADER", action = act.ActivateTabRelative(1) },
    { key = "p", mods = "LEADER", action = act.ActivateTabRelative(-1) },
    { key = "&", mods = "LEADER|SHIFT", action = act.CloseCurrentTab({ confirm = true }) },
    { key = "1", mods = "LEADER", action = act.ActivateTab(0) },
    { key = "2", mods = "LEADER", action = act.ActivateTab(1) },
    { key = "3", mods = "LEADER", action = act.ActivateTab(2) },
    { key = "4", mods = "LEADER", action = act.ActivateTab(3) },
    { key = "5", mods = "LEADER", action = act.ActivateTab(4) },

    -- Copy mode + clipboard
    { key = "[", mods = "LEADER", action = act.ActivateCopyMode },
    { key = "v", mods = "LEADER", action = act.PasteFrom("Clipboard") },

    -- Standard clipboard shortcuts.
    -- CTRL-V pastes from the system clipboard.
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

    -- Config reload
    { key = "r", mods = "LEADER", action = act.ReloadConfiguration },

    -- ---- Sessions / workspaces (tmux-style) ----
    -- Switch session: fuzzy launcher over all live workspaces.
    { key = "w", mods = "LEADER", action = act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }) },
    -- Create / switch to a named workspace.
    {
        key = "N",
        mods = "LEADER|SHIFT",
        action = act.PromptInputLine({
            description = "New session name:",
            action = wezterm.action_callback(function(window, pane, line)
                if line and line ~= "" then
                    window:perform_action(act.SwitchToWorkspace({ name = line }), pane)
                end
            end),
        }),
    },
    -- Rename current workspace.
    {
        key = "$",
        mods = "LEADER|SHIFT",
        action = act.PromptInputLine({
            description = "Rename session:",
            action = wezterm.action_callback(function(_window, _pane, line)
                if line and line ~= "" then
                    mux.rename_workspace(mux.get_active_workspace(), line)
                end
            end),
        }),
    },
    -- Cycle workspaces without the launcher.
    { key = ")", mods = "LEADER|SHIFT", action = act.SwitchWorkspaceRelative(1) },
    { key = "(", mods = "LEADER|SHIFT", action = act.SwitchWorkspaceRelative(-1) },
}

return config
