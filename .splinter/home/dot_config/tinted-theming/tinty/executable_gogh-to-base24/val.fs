# §head home/dot_config/tinted-theming/tinty/executable_gogh-to-base24.sh:46-46 val
# §sig val()
 sed -n "s/^$1:[[:space:]]*['\"]#\([0-9A-Fa-f]\{6\}\)['\"].*/\1/p" "$2" | head -n1 | tr 'A-F' 'a-f';
# §foot home/dot_config/tinted-theming/tinty/executable_gogh-to-base24.sh val