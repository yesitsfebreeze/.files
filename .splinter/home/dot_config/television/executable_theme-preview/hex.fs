# §head home/dot_config/television/executable_theme-preview.sh:33-36 hex
# §sig hex()
    grep -iE "^[[:space:]]*$1:[[:space:]]*\"?#[0-9A-Fa-f]{6}" "$scheme" \
        | head -n1 | sed -E 's/.*(#[0-9A-Fa-f]{6}).*/\1/' | tr 'A-F' 'a-f'
# §foot home/dot_config/television/executable_theme-preview.sh hex