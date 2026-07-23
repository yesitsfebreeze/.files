# §head home/dot_config/television/executable_theme-preview.sh:54-54 rgb
# §sig rgb()
 local h="${1#\#}"; printf '%d;%d;%d' "0x${h:0:2}" "0x${h:2:2}" "0x${h:4:2}";
# §foot home/dot_config/television/executable_theme-preview.sh rgb