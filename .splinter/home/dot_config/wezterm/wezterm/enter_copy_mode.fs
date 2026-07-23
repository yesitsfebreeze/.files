-- §head home/dot_config/wezterm/wezterm.lua:498-502 enter_copy_mode
-- §sig local function enter_copy_mode(window, pane)
copy_selecting[pane:pane_id()] = nil
    window:perform_action(act.ClearSelection, pane)
    window:perform_action(act.ActivateCopyMode, pane)
-- §foot home/dot_config/wezterm/wezterm.lua enter_copy_mode