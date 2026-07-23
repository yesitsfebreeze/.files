# §head home/dot_config/television/executable_theme-preview.sh:87-87 vis
# §sig vis()
 local s="$1"; s="${s//$'\033'\[*([0-9;])m/}"; printf '%s' "${#s}";
# §foot home/dot_config/television/executable_theme-preview.sh vis