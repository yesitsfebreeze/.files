# §source home/dot_config/television/executable_bg-preview.sh
#!/usr/bin/env bash
# television preview for the `bg` channel. $1 is the focused candidate line,
# "#rrggbb  <label>". Paints a self-contained swatch card and emits one OSC 11
# escape so the real (translucent) wezterm window previews the candidate for
# real — no tinty apply, no hook chain; theme.nu restores the active background
# when the picker closes.
set -u

line="${1:-}"
hex="${line%% *}"
label="${line#"$hex"}"
label="${label# }"
label="${label# }"
case "$hex" in
    \#[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]) ;;
    *) printf '%s\n' "$line"; exit 0 ;;
esac
h="${hex#\#}"
r=$((0x${h:0:2})); g=$((0x${h:2:2})); b=$((0x${h:4:2}))

color=1; [ -n "${NO_COLOR:-}" ] && color=0
if [ "$color" = 1 ]; then
    { printf '\033]11;%s\033\\' "$hex" > /dev/tty; } 2>/dev/null
    BG=$'\033[48;2;'"$r;$g;$b"m
    R=$'\033[0m'; DIM=$'\033[2m'; BOLD=$'\033[1m'
else
    BG=""; R=""; DIM=""; BOLD=""
fi

printf '%s%s%s\n' "$BOLD" "$hex" "$R"
printf '%s%s%s\n\n' "$DIM" "${label:-candidate}" "$R"
for _ in 1 2 3 4 5 6; do
    printf '%s%*s%s\n' "$BG" 40 "" "$R"
done
printf '\n R %3d   G %3d   B %3d\n' "$r" "$g" "$b"
