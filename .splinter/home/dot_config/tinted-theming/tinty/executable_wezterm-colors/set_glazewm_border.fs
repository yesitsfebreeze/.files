# §head home/dot_config/tinted-theming/tinty/executable_wezterm-colors.sh:64-70 set_glazewm_border
# §sig set_glazewm_border()
    local file="$1"
    [[ -n "$base0d" && -f "$file" ]] || return 0
    sed -i.bak -E \
        "s|^([[:space:]]*color:[[:space:]]*')#[0-9A-Fa-f]{6}('[[:space:]]*#[[:space:]]*tinty:accent.*)\$|\\1${base0d}\\2|" \
        "$file" 2>/dev/null && rm -f "$file.bak"
# §foot home/dot_config/tinted-theming/tinty/executable_wezterm-colors.sh set_glazewm_border