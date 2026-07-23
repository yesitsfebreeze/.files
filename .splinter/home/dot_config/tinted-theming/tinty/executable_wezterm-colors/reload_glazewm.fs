# §head home/dot_config/tinted-theming/tinty/executable_wezterm-colors.sh:75-81 reload_glazewm
# §sig reload_glazewm()
    if command -v glazewm.exe >/dev/null 2>&1; then
        glazewm.exe command wm-reload-config >/dev/null 2>&1 || true
    elif command -v glazewm >/dev/null 2>&1; then
        glazewm command wm-reload-config >/dev/null 2>&1 || true
    fi
# §foot home/dot_config/tinted-theming/tinty/executable_wezterm-colors.sh reload_glazewm