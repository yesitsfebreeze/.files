#!/usr/bin/env bash
# Convert Gogh terminal themes (https://github.com/Gogh-Co/Gogh) into base24
# custom-schemes that tinty can list and apply. A Gogh theme is just background +
# foreground + 16 ANSI colors, which maps cleanly onto base24 (base00-base17).
# Output lands in the tinty data-dir custom-schemes/base24/ (gitignored runtime
# state, like our feb scheme), so `tinty list --custom-schemes` and the `theme`
# switcher pick them up as base24-gogh-<slug>. tinty builds + applies them through
# the normal pipeline (it auto-renders the tinted-shell script on first apply).
#
# Installs once: after the schemes exist it exits instantly on every apply (no
# git, no network). Pass --update to pull the latest Gogh themes and rebuild.
# Deliberately bash-3.2 safe (no associative arrays) and non-fatal end to end, so
# a missing network never breaks `chezmoi apply`. Invoked from
# run_after_generate-shell-init.sh.
set -uo pipefail

DATA="${XDG_DATA_HOME:-$HOME/.local/share}/tinted-theming/tinty"
SRC="$DATA/gogh-src"
OUT="$DATA/custom-schemes/base24"
REPO="https://github.com/Gogh-Co/Gogh.git"

command -v git >/dev/null 2>&1 || exit 0

FORCE=0
case "${1:-}" in --update | -u) FORCE=1 ;; esac

# Fast path: already installed. Every `chezmoi apply` calls this, so once the
# schemes exist we exit instantly — no git, no network. Run with `--update` to
# pull the latest Gogh themes and rebuild.
if [ "$FORCE" -eq 0 ] && [ -n "$(ls "$OUT"/gogh-*.yaml 2>/dev/null)" ]; then
    exit 0
fi

# Clone (shallow) or update. Non-fatal: no network must never break apply.
if [ -d "$SRC/.git" ]; then
    git -C "$SRC" pull --ff-only --depth 1 >/dev/null 2>&1 || true
else
    git clone --depth 1 "$REPO" "$SRC" >/dev/null 2>&1 || true
fi
[ -d "$SRC/themes" ] || exit 0

mkdir -p "$OUT"
rm -f "$OUT"/gogh-*.yaml   # drop schemes for themes renamed/removed upstream

# Pull one "#rrggbb" value (lowercased, no '#') for a Gogh key; handles ' or ".
val() { sed -n "s/^$1:[[:space:]]*['\"]#\([0-9A-Fa-f]\{6\}\)['\"].*/\1/p" "$2" | head -n1 | tr 'A-F' 'a-f'; }
str() { sed -n "s/^$1:[[:space:]]*['\"]\(.*\)['\"].*/\1/p" "$2" | head -n1 | tr -d '"'; }

count=0
for f in "$SRC"/themes/*.yml; do
    [ -f "$f" ] || continue
    bg=$(val background "$f"); fg=$(val foreground "$f")
    c01=$(val color_01 "$f"); c02=$(val color_02 "$f"); c03=$(val color_03 "$f"); c04=$(val color_04 "$f")
    c05=$(val color_05 "$f"); c06=$(val color_06 "$f"); c07=$(val color_07 "$f"); c08=$(val color_08 "$f")
    c09=$(val color_09 "$f"); c10=$(val color_10 "$f"); c11=$(val color_11 "$f"); c12=$(val color_12 "$f")
    c13=$(val color_13 "$f"); c14=$(val color_14 "$f"); c15=$(val color_15 "$f"); c16=$(val color_16 "$f")
    variant=$(str variant "$f")
    # Require the essentials; skip malformed themes rather than emit a broken one.
    [ -n "$bg" ] && [ -n "$fg" ] && [ -n "$c02" ] && [ -n "$c16" ] || continue

    base=$(basename "$f" .yml)
    slug=$(printf '%s' "$base" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//')
    [ -n "$slug" ] || continue

    # base24 mapping. ANSI slots are direct from Gogh; orange (base09) and brown
    # (base0F) have no Gogh equivalent, so they fall back to yellow/red; the extra
    # background shades (base10/11) reuse the background. WezTerm only consumes the
    # ANSI + bright slots, which are all faithful.
    {
        printf 'system: "base24"\n'
        printf 'name: "Gogh %s"\n' "$base"
        printf 'author: "Gogh (https://github.com/Gogh-Co/Gogh) — converted to base24"\n'
        printf 'variant: "%s"\n' "${variant:-dark}"
        printf 'palette:\n'
        printf '  base00: "#%s"\n' "$bg"   # background
        printf '  base01: "#%s"\n' "$c01"  # black
        printf '  base02: "#%s"\n' "$c09"  # bright black (selection)
        printf '  base03: "#%s"\n' "$c09"  # bright black (comments)
        printf '  base04: "#%s"\n' "$c08"  # white (dark foreground)
        printf '  base05: "#%s"\n' "$fg"   # foreground
        printf '  base06: "#%s"\n' "$c16"  # bright white
        printf '  base07: "#%s"\n' "$c16"  # bright white
        printf '  base08: "#%s"\n' "$c02"  # red
        printf '  base09: "#%s"\n' "$c04"  # orange -> yellow (no Gogh equivalent)
        printf '  base0A: "#%s"\n' "$c04"  # yellow
        printf '  base0B: "#%s"\n' "$c03"  # green
        printf '  base0C: "#%s"\n' "$c07"  # cyan
        printf '  base0D: "#%s"\n' "$c05"  # blue
        printf '  base0E: "#%s"\n' "$c06"  # magenta
        printf '  base0F: "#%s"\n' "$c02"  # brown -> red (no Gogh equivalent)
        printf '  base10: "#%s"\n' "$bg"   # darker background
        printf '  base11: "#%s"\n' "$bg"   # darkest background
        printf '  base12: "#%s"\n' "$c10"  # bright red
        printf '  base13: "#%s"\n' "$c12"  # bright yellow
        printf '  base14: "#%s"\n' "$c11"  # bright green
        printf '  base15: "#%s"\n' "$c15"  # bright cyan
        printf '  base16: "#%s"\n' "$c13"  # bright blue
        printf '  base17: "#%s"\n' "$c14"  # bright purple
    } > "$OUT/gogh-$slug.yaml"
    count=$((count + 1))
done

printf 'gogh: converted %d themes -> %s\n' "$count" "$OUT"
