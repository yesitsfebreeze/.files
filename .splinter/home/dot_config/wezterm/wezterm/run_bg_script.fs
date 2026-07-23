-- §head home/dot_config/wezterm/wezterm.lua:367-378 run_bg_script
-- §sig local function run_bg_script(script)
local argv
    if is_windows then
        argv = { "wsl.exe", "-d", WSL_DISTRO, "-e", "bash", "-lc", script }
    else
        argv = { "sh", "-lc", script }
    end
    -- Login shell (-lc) so PATH resolves magick/convert/curl/wslpath/chezmoi.
    -- run_child_process is synchronous (returns success/stdout/stderr) so we can
    -- branch on failure; it briefly blocks the GUI thread during the download.
    return wezterm.run_child_process(argv)
-- §foot home/dot_config/wezterm/wezterm.lua run_bg_script