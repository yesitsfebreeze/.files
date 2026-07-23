# §head home/dot_config/television/executable_theme-preview.sh:55-55 fg
# §sig fg()
 [ "$color" = 1 ] && printf '\033[38;2;%sm' "$(rgb "${C[$1]}")";
# §foot home/dot_config/television/executable_theme-preview.sh fg