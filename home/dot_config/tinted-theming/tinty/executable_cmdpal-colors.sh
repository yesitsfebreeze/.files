#!/usr/bin/env bash
# Retints the PowerToys Command Palette from the active tinty base16/base24 scheme,
# so win+alt+space opens on the same surface as WezTerm and the Zebar bar. Run as a
# tinty hook after tinted-shell, alongside wezterm-colors.sh / zebar-colors.sh.
#
# Windows-only, and unlike its sibling hooks there is no dual-write: CmdPal keeps its
# settings inside the MSIX's per-user LocalState, not under ~/.config, so there is no
# Linux/macOS copy and nothing for run_after_mirror-config-to-windows.sh to carry.
# PowerToys itself is installed by run_onchange_install-powertoys.sh, which also
# enforces the >= 0.98.0 floor these keys need.
#
# What it writes, and why those values:
#   Theme                     Dark        the schemes we ship are dark; Default would
#                                         let a light Windows session invert the palette
#   ColorizationMode          CustomColor otherwise CmdPal tints from the Windows accent
#   CustomThemeColor          base00      the exact hex WezTerm uses for config.colors.background
#   CustomThemeColorIntensity 100         full tint — the surface IS the theme background
#   BackdropStyle             Clear       solid color + alpha, no blur. Matches WezTerm on
#                                         Windows, which gets no reliable per-window blur
#                                         either (see wezterm.lua); the wallpaper is already
#                                         gaussian-blurred, so plain transparency reads right
#                                         and Acrylic would only add a flat gray fallback.
#   BackdropOpacity           95          WezTerm's window_background_opacity = 0.95, in percent
#
# Font is deliberately absent: CmdPal exposes no font setting anywhere in its settings
# model, so CaskaydiaCove cannot reach it. The only lever would be a system-wide Segoe UI
# FontSubstitutes override, which repaints every Windows surface — not a theme hook's job.

ARTIFACTS="$HOME/.local/share/tinted-theming/tinty/artifacts"
SCHEMES_DIR="$HOME/.local/share/tinted-theming/tinty/repos/schemes"
CUSTOM_DIR="$HOME/.local/share/tinted-theming/tinty/custom-schemes"

# Scheme from $1 (chezmoi apply passes the default-scheme), else the last pick.
SCHEME="${1:-$(cat "$ARTIFACTS/current_scheme" 2>/dev/null)}"
[[ -z "$SCHEME" ]] && exit 0

SYSTEM="${SCHEME%%-*}"
NAME="${SCHEME#*-}"
YAML="$SCHEMES_DIR/$SYSTEM/$NAME.yaml"
[[ -f "$YAML" ]] || YAML="$CUSTOM_DIR/$SYSTEM/$NAME.yaml"
[[ -f "$YAML" ]] || exit 0

# Extract one palette entry by base key (portable: macOS bash 3.2, BSD+GNU sed).
color() {
	grep -iE "^[[:space:]]*$1:[[:space:]]*\"#[0-9A-Fa-f]{6}\"" "$YAML" |
		head -n1 |
		sed -E 's/.*"(#[0-9A-Fa-f]{6})".*/\1/' |
		tr 'A-F' 'a-f'
}

base00=$(color base00) # background

# Bail if the scheme didn't parse, so we never paint the palette a half-read color.
[[ -z "$base00" ]] && exit 0

# Optional background-override from config.toml overrides the scheme's base00, the
# same way it does for the terminal and the bar.
bg_override=$(grep -iE '^[[:space:]]*background-override[[:space:]]*=[[:space:]]*"#[0-9A-Fa-f]{6}"' \
	"$HOME/.config/tinted-theming/tinty/config.toml" 2>/dev/null |
	head -n1 | sed -E 's/.*"(#[0-9A-Fa-f]{6})".*/\1/' | tr 'A-F' 'a-f')
[[ -n "$bg_override" ]] && base00="$bg_override"

# CmdPal stores the color as a WinRT Color struct — four byte fields, not a hex string.
r=$((16#${base00:1:2}))
g=$((16#${base00:3:2}))
b=$((16#${base00:5:2}))

desired="Dark CustomColor $base00 100 Clear 95"

# tinty runs this hook on every `tinty init` (each shell start), not only on a `theme`
# switch. Stamp what we last wrote on the Linux side and diff against it FIRST, so an
# unchanged scheme costs one file read — never the cmd.exe/wslpath spawn, the /mnt/c
# write, or the CmdPal restart below. Same guard the sibling hooks get from diffing
# their generated artifact; CmdPal has no Linux-side artifact to diff, hence the stamp.
STAMP="$HOME/.cache/tinty-cmdpal-applied"
[[ -f "$STAMP" && "$desired" == "$(cat "$STAMP" 2>/dev/null)" ]] && exit 0

grep -qi microsoft /proc/version 2>/dev/null || exit 0
command -v jq >/dev/null 2>&1 || exit 0

# Resolve (and cache) the palette's settings.json under the Windows profile. The
# derivation matches zebar-colors.sh: cmd.exe is ~100ms and the `theme` picker fires
# this hook on every focus, so it is paid once. Strict guards (drive letter + absolute
# wslpath result) keep a failed cmd.exe from writing under the wrong dir.
cache="$HOME/.cache/tinty-cmdpal-settings-path"
if [[ -s "$cache" ]]; then
	settings="$(cat "$cache")"
else
	settings=""
	winhome=""
	up="$(cmd.exe /c 'echo %USERPROFILE%' 2>/dev/null | tr -d '\r\n')"
	case "$up" in
	[A-Za-z]:*)
		winhome="$(wslpath -u "$up" 2>/dev/null)" || winhome=""
		case "$winhome" in
		/*) [[ -d "$winhome" ]] || winhome="" ;;
		*) winhome="" ;;
		esac
		;;
	esac
	if [[ -n "$winhome" ]]; then
		candidate="$winhome/AppData/Local/Packages/Microsoft.CommandPalette_8wekyb3d8bbwe/LocalState/settings.json"
		# The file appears on CmdPal's first run. Don't cache a path that isn't there
		# yet and don't stamp — a later run picks it up once the palette has launched.
		[[ -f "$candidate" ]] && settings="$candidate"
	fi
	if [[ -n "$settings" ]]; then
		mkdir -p "$(dirname "$cache")"
		printf '%s\n' "$settings" >"$cache"
	fi
fi
[[ -n "$settings" && -f "$settings" ]] || exit 0

# Version floor: before PowerToys 0.98.0 the CmdPal settings model has no Appearance
# properties, so these keys survive in the file only until the palette's next in-app
# save rewrites it from a record that never knew them. Skip without stamping so the
# retint lands by itself once run_onchange_install-powertoys.sh has upgraded.
winroot="${settings%%/AppData/*}"
pt_version="$(grep -o '"powertoys_version"[[:space:]]*:[[:space:]]*"v\?[0-9][0-9.]*"' \
	"$winroot/AppData/Local/Microsoft/PowerToys/settings.json" 2>/dev/null |
	head -n1 | sed -E 's/.*"v?([0-9][0-9.]*)".*/\1/')"
if [[ -n "$pt_version" && "$pt_version" != "0.98.0" ]]; then
	[[ "$(printf '%s\n%s\n' "$pt_version" "0.98.0" | sort -V | head -n1)" == "$pt_version" ]] && exit 0
fi

# CmdPal reads settings.json once at startup and rewrites the whole model from memory
# on its next in-app save, so an edit made underneath a running palette is both lost
# and able to clobber. Stop it first, patch, then bring it back exactly how it ran —
# headless, no window — through its x-cmdpal:// protocol handler. taskkill's exit code
# is the "was it running" signal (pgrep can't see Windows processes from WSL).
was_running=0
if command -v taskkill.exe >/dev/null 2>&1 && taskkill.exe /IM Microsoft.CmdPal.UI.exe /F >/dev/null 2>&1; then
	was_running=1
fi

tmp="$(mktemp)"
if jq --argjson r "$r" --argjson g "$g" --argjson b "$b" '
      .Theme = "Dark"
    | .ColorizationMode = "CustomColor"
    | .CustomThemeColor = { A: 255, R: $r, G: $g, B: $b }
    | .CustomThemeColorIntensity = 100
    | .BackdropStyle = "Clear"
    | .BackdropOpacity = 95
' "$settings" >"$tmp" 2>/dev/null && [[ -s "$tmp" ]]; then
	# Write through the existing file rather than mv'ing onto it: the target lives on
	# DrvFs, where a rename from /tmp would replace the Windows-side file wholesale.
	cat "$tmp" >"$settings" && printf '%s\n' "$desired" >"$STAMP"
fi
rm -f "$tmp"

if [[ "$was_running" == 1 ]]; then
	# Fully detached — `( … & )` with stdin from /dev/null — so the GUI's inherited
	# handles can't keep WSL interop (and the shell) blocked. Best-effort: a failed
	# relaunch must never break `theme`.
	(cmd.exe /c start "" "x-cmdpal://background" </dev/null >/dev/null 2>&1 &) || true
fi
