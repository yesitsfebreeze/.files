# §head home/dot_config/television/executable_theme-preview.sh:127-136 swatch
# §sig swatch()
  # key -> "████ 0D #a78bfa" sized to 15 cells
    local k="$1"; local hx="${C[$k]}"
    if [ "$color" = 1 ]; then
        # `████` are foreground glyphs: colour them with `fg`, not `bg` (bg paints behind
        # a block that already fills the cell, so the glyph stayed default-fg = white).
        printf '%b████%b %b%s%b %b%s%b' "$(fg "$k")" "$R" "$HI" "$k" "$R" "$DIM" "$hx" "$R"
    else
        printf '%-4s %s %s' "$k" "$k" "$hx"
    fi
# §foot home/dot_config/television/executable_theme-preview.sh swatch