#!/usr/bin/env bash
# chezmoi run_onchange — installs PowerToys on the Windows host. PowerToys is
# Windows-only, so WSL is the only place this does anything; macOS and plain Linux
# fall out at the first guard.
#
#   WSL     → winget.exe installs Microsoft.PowerToys
#   macOS   → skipped (no build exists)
#   Linux   → skipped
#
# The Command Palette is NOT a separate package: CmdPal ships inside the PowerToys
# MSIX and is enabled by default, so installing PowerToys is what puts win+alt+space
# on the machine. GlazeWM already treats its window as a transient overlay (the
# 'ignore' rule in glazewm/config.yaml.tmpl).
# bump to force a re-run: v1
set -uo pipefail

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

if "$winget" list --id Microsoft.PowerToys -e >/dev/null 2>&1; then
	log "PowerToys already installed on Windows."
else
	log "install Microsoft.PowerToys on Windows (winget)"
	"$winget" install --id Microsoft.PowerToys -e --silent \
		--accept-source-agreements --accept-package-agreements >/dev/null 2>&1 &&
		log "  installed PowerToys on Windows" ||
		warn "  winget install failed; run manually in Windows: winget install Microsoft.PowerToys"
fi
