#!/usr/bin/env bash
# WezTerm Nerd-Font picker helper (macOS + Linux).
#
# RUNTIME USER STATE — not provisioning. packages.yaml still owns the guaranteed
# default font (JetBrainsMono Nerd Font); this script installs *extra* Nerd Fonts
# that the user picks interactively via CTRL+SHIFT+F. Fonts installed here are
# deliberately outside the package manifest (project-law #1 boundary).
#
# Modes:
#   fontpicker.sh                 -> open the fzf picker (spawned by wezterm)
#   fontpicker.sh --install NAME  -> debounced download+install of a hovered font
#                                    (invoked by fzf's `focus` bind)
#
# State files (all under $WZ, runtime-only, never chezmoi-tracked):
#   font-catalog.txt    cached list of Nerd Font release assets
#   preview-request.txt latest hovered asset name (debounce arbiter)
#   preview-font.txt    family name wezterm should preview live
#   active-font.txt     family name to persist as the default at next launch
#   picker-closed.txt   KEEP | REVERT — signals the wezterm watch loop to stop
#   installed/<name>    marker: this asset has already been installed

set -u
# nullglob: unmatched globs vanish instead of leaking literal patterns.
# globstar: `**` recurses, so nested .ttf paths in an asset zip are caught.
shopt -s nullglob globstar 2>/dev/null || true

SELF="$0"
WZ="${XDG_CONFIG_HOME:-$HOME/.config}/wezterm"
mkdir -p "$WZ/installed"

API_URL="https://api.github.com/repos/ryanoasis/nerd-fonts/releases/latest"
DL_BASE="https://github.com/ryanoasis/nerd-fonts/releases/latest/download"

case "$(uname -s)" in
    Darwin) FONT_DIR="$HOME/Library/Fonts"; IS_MAC=1 ;;
    *)      FONT_DIR="$HOME/.local/share/fonts"; IS_MAC=0 ;;
esac
mkdir -p "$FONT_DIR"

# --- extract any .ttf files from a zip into a target dir (resilient fallbacks) -
extract_ttf() {
    zip="$1"; dest="$2"
    mkdir -p "$dest"
    if command -v unzip >/dev/null 2>&1; then
        unzip -oq "$zip" '*.ttf' -d "$dest" 2>/dev/null && return 0
    fi
    if command -v python3 >/dev/null 2>&1; then
        python3 -m zipfile -e "$zip" "$dest" >/dev/null 2>&1 && return 0
    fi
    # bsdtar (macOS `tar`) can read zips; GNU tar cannot, hence the guards above.
    tar -xf "$zip" -C "$dest" 2>/dev/null && return 0
    return 1
}

# --- install one font asset by its release name (e.g. "JetBrainsMono") ---------
install_font() {
    name="$1"
    marker="$WZ/installed/$name"
    [ -f "$marker" ] && return 0

    tmp="$(mktemp -d)"
    if ! curl -fsSL -o "$tmp/$name.zip" "$DL_BASE/$name.zip"; then
        rm -rf "$tmp"; return 1
    fi
    if ! extract_ttf "$tmp/$name.zip" "$tmp/ttf"; then
        rm -rf "$tmp"; return 1
    fi
    # Copy every .ttf the asset ships (Regular/Bold/Italic, plus Mono/Propo).
    found=0
    for f in "$tmp/ttf"/*.ttf "$tmp/ttf"/**/*.ttf; do
        [ -f "$f" ] || continue
        cp -f "$f" "$FONT_DIR/" && found=1
    done
    rm -rf "$tmp"
    [ "$found" = 1 ] || return 1

    if [ "$IS_MAC" = 0 ] && command -v fc-cache >/dev/null 2>&1; then
        fc-cache -f "$FONT_DIR" >/dev/null 2>&1
    fi
    : > "$marker"
    return 0
}

# --- mode: --install NAME (debounced, called from fzf focus) -------------------
if [ "${1:-}" = "--install" ]; then
    name="${2:-}"
    [ -n "$name" ] || exit 0
    # Debounce: record this hover as the latest request, wait, then bail if the
    # user has since moved to a different font (last writer wins on the file).
    printf '%s' "$name" > "$WZ/preview-request.txt"
    sleep 0.4
    [ "$(cat "$WZ/preview-request.txt" 2>/dev/null)" = "$name" ] || exit 0

    install_font "$name" || exit 0
    # WezTerm font family name for a Nerd Font base variant is "<Name> Nerd Font".
    printf '%s Nerd Font' "$name" > "$WZ/preview-font.txt"
    exit 0
fi

# --- mode: open the picker -----------------------------------------------------
# Refresh the catalog when missing or older than a day; tolerate offline by
# falling back to whatever is cached.
need_fetch=1
if [ -f "$WZ/font-catalog.txt" ]; then
    if find "$WZ/font-catalog.txt" -mtime -1 >/dev/null 2>&1; then
        # only skip the fetch if it is also non-empty
        [ -s "$WZ/font-catalog.txt" ] && need_fetch=0
    fi
fi
if [ "$need_fetch" = 1 ]; then
    fresh="$(curl -fsSL "$API_URL" 2>/dev/null \
        | grep -oE '"name": "[^"]+\.zip"' \
        | sed -e 's/.*"name": "//' -e 's/\.zip"//' \
        | grep -viE 'FontPatcher' \
        | sort -u)"
    if [ -n "$fresh" ]; then
        printf '%s\n' "$fresh" > "$WZ/font-catalog.txt"
    fi
fi

if [ ! -s "$WZ/font-catalog.txt" ]; then
    printf 'Could not fetch the Nerd Fonts catalog (offline and no cache).\n'
    printf 'Press Enter to close.\n'
    read -r _ || true
    printf 'REVERT' > "$WZ/picker-closed.txt"
    exit 1
fi

rm -f "$WZ/preview-font.txt" "$WZ/preview-request.txt" "$WZ/picker-closed.txt"

header='Enter: keep   Esc: revert   |   hover to preview (downloads on hover)'
sel="$(fzf \
    --prompt 'Nerd Font> ' \
    --header "$header" \
    --height 100% \
    --layout reverse \
    --bind "focus:execute-silent(sh '$SELF' --install {})" \
    < "$WZ/font-catalog.txt")"

if [ -n "$sel" ]; then
    # Ensure the chosen font is actually installed (in case Enter beat the
    # debounce timer), then persist + keep the live override.
    install_font "$sel" >/dev/null 2>&1 || true
    printf '%s Nerd Font' "$sel" > "$WZ/active-font.txt"
    printf '%s Nerd Font' "$sel" > "$WZ/preview-font.txt"
    printf 'KEEP' > "$WZ/picker-closed.txt"
else
    printf 'REVERT' > "$WZ/picker-closed.txt"
fi

rm -f "$WZ/preview-request.txt"
exit 0
