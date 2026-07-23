# §head home/dot_config/tinted-theming/tinty/executable_gogh-to-base24.sh:47-47 str
# §sig str()
 sed -n "s/^$1:[[:space:]]*['\"]\(.*\)['\"].*/\1/p" "$2" | head -n1 | tr -d '"';
# §foot home/dot_config/tinted-theming/tinty/executable_gogh-to-base24.sh str