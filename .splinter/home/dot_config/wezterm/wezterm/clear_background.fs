-- §head home/dot_config/wezterm/wezterm.lua:466-483 clear_background
-- §sig local function clear_background() -- Best-effort, no set -e: remove the committed copies first (always reachable), -- then the live copies. The live derivation reuses the same strict WIN_LIVE_DIR -- guard (FIX B) so a failed cmd.exe can never resolve live_dir to a relative "." -- and delete under the wrong CWD; on that failure it exits before the live rm, -- which is acceptable (the committed copy is already gone and the next reload -- falls back to the solid bg anyway).
local script = table.concat({
        'src_dir="$(chezmoi source-path "$HOME/.config/wezterm" 2>/dev/null)"',
        '[ -n "$src_dir" ] && rm -f "$src_dir/background.png"',
        "if grep -qi microsoft /proc/version 2>/dev/null; then " .. WIN_LIVE_DIR .. "; "
        .. 'else live_dir="$HOME/.config/wezterm"; fi',
        'rm -f "$live_dir/background.png"',
        "true",
    }, "; ")
    run_bg_script(script)
    wezterm.reload_configuration()
-- §foot home/dot_config/wezterm/wezterm.lua clear_background