# §head home/dot_config/television/executable_theme-preview.sh:96-99 _row
# §sig _row()
    local b="$1" c="$2" pad; pad=$((INNER - $(vis "$c"))); ((pad<0)) && pad=0
    printf '%b%s│%s %b%*s %b│%b\n' "$b" "$BRD" "$R$b" "$c" "$pad" "" "$BRD" "$R"
# §foot home/dot_config/television/executable_theme-preview.sh _row