#!/usr/bin/env bash
# chezmoi run_onchange — installs PowerToys on the Windows host. PowerToys is
# Windows-only, so WSL is the only place this does anything; macOS and plain Linux
# fall out at the first guard.
#
#   WSL     → winget.exe installs (or version-floor upgrades) Microsoft.PowerToys
#   macOS   → skipped (no build exists)
#   Linux   → skipped
#
# The Command Palette is NOT a separate package: CmdPal ships inside the PowerToys
# MSIX and is enabled by default, so installing PowerToys is what puts win+alt+space
# on the machine. GlazeWM already treats its window as a transient overlay (the
# 'ignore' rule in glazewm/config.yaml.tmpl), and its surface is retinted from the
# active tinty scheme by dot_config/tinted-theming/tinty/cmdpal-colors.sh.
#
# MIN_VERSION is that themer's floor: 0.98.0 is the first PowerToys release whose
# CmdPal settings model carries the Appearance keys (Theme, ColorizationMode,
# CustomThemeColor, BackdropStyle, BackdropOpacity). Older builds deserialize
# settings.json into a record with no such properties and drop them on their next
# save, so a below-floor install is upgraded here rather than left to silently
# discard the theme on first use. The installed version is read from PowerToys' own
# settings.json (`powertoys_version`) because that is exact — `winget list` output is
# column-wrapped and locale-dependent, so parsing it is not.
# bump to force a re-run: v1
set -uo pipefail

MIN_VERSION="0.98.0"

log() { printf '\033[1;34m::\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*"; }

# Windows host reachable only from WSL over interop.
grep -qiE 'microsoft|wsl' /proc/version 2>/dev/null || {
	log "PowerToys: not WSL, skipping."
	exit 0
}

winget="$(command -v winget.exe 2>/dev/null || true)"
[ -z "$winget" ] && {
	warn "PowerToys: winget.exe not on PATH from WSL; install manually: winget install Microsoft.PowerToys"
	exit 0
}

# True when $1 is strictly older than $2 (sort -V orders version strings correctly).
ver_lt() {
	[ "$1" = "$2" ] && return 1
	[ "$(printf '%s\n%s\n' "$1" "$2" | sort -V | head -n1)" = "$1" ]
}

# Read the installed version out of PowerToys' settings.json on the Windows profile.
# Empty when PowerToys was never run (the file appears on first launch) — treated as
# "version unknown", which never triggers an upgrade on its own.
installed_version() {
	local up winhome settings
	up="$(cmd.exe /c 'echo %USERPROFILE%' 2>/dev/null | tr -d '\r\n')"
	case "$up" in
	[A-Za-z]:*) winhome="$(wslpath -u "$up" 2>/dev/null)" || return 0 ;;
	*) return 0 ;;
	esac
	settings="$winhome/AppData/Local/Microsoft/PowerToys/settings.json"
	[ -f "$settings" ] || return 0
	grep -o '"powertoys_version"[[:space:]]*:[[:space:]]*"v\?[0-9][0-9.]*"' "$settings" 2>/dev/null |
		head -n1 | sed -E 's/.*"v?([0-9][0-9.]*)".*/\1/'
}

if "$winget" list --id Microsoft.PowerToys -e >/dev/null 2>&1; then
	cur="$(installed_version)"
	if [ -n "$cur" ] && ver_lt "$cur" "$MIN_VERSION"; then
		log "PowerToys $cur predates $MIN_VERSION (CmdPal has no Appearance settings yet); upgrading"
		"$winget" upgrade --id Microsoft.PowerToys -e --silent \
			--accept-source-agreements --accept-package-agreements >/dev/null 2>&1 &&
			log "  upgraded PowerToys on Windows" ||
			warn "  winget upgrade failed; run manually in Windows: winget upgrade Microsoft.PowerToys"
	else
		log "PowerToys already installed on Windows${cur:+ (v$cur)}."
	fi
else
	log "install Microsoft.PowerToys on Windows (winget)"
	"$winget" install --id Microsoft.PowerToys -e --silent \
		--accept-source-agreements --accept-package-agreements >/dev/null 2>&1 &&
		log "  installed PowerToys on Windows (Command Palette included)" ||
		warn "  winget install failed; run manually in Windows: winget install Microsoft.PowerToys"
fi
