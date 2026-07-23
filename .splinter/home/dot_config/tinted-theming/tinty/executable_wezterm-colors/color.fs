# §head home/dot_config/tinted-theming/tinty/executable_wezterm-colors.sh:29-34 color
# §sig color()
    grep -iE "^[[:space:]]*$1:[[:space:]]*\"#[0-9A-Fa-f]{6}\"" "$YAML" \
        | head -n1 \
        | sed -E 's/.*"(#[0-9A-Fa-f]{6})".*/\1/' \
        | tr 'A-F' 'a-f'
# §foot home/dot_config/tinted-theming/tinty/executable_wezterm-colors.sh color