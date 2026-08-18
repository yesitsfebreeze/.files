---
state: claimed
mode: afk
priority: 3
verify: test "$(git ls-files | grep -cE 'wp-stat-overlay|custom-topbar|layout-daemon')" = 0
claim: 01a01605-6d60-7e7e-adc5-36557224f3f4
---

# Extract desktop apps from chezmoi management

Purpose: Three full applications live inside the dotfiles: wp-stat-overlay (Go
stats agent + JS wallpaper, ~1000 lines), zebar custom-topbar (1115-line HTML
bar), and glazewm layout-daemon (419-line Node daemon). They are desktop
customization, not dev configuration, and their install scripts
(run_onchange_after_install-wp-stat-overlay.sh.tmpl,
run_onchange_after_restart-glazewm-zebar.sh.tmpl, etc.) add ~300 lines of
chezmoi machinery.

## Requirements
- [ ] wp-stat-overlay removed from `home/` (moved to its own repo/location)
- [ ] zebar custom-topbar removed from `home/` (moved to its own repo/location)
- [ ] layout-daemon.js removed from `home/` (moved to its own repo/location)
- [ ] The run scripts that install/manage these apps are removed or reduced to a pointer to the external repo
- [ ] README documents where the apps now live
- [ ] The apps still function from their new location (install/run instructions preserved)

## Acceptance
- [ ] `chezmoi apply` no longer manages wp-stat-overlay, custom-topbar, or layout-daemon (no tracked files under those paths), and the apps' install/run instructions are documented in README.

## Out of scope
- Building the apps' new repos (follow-on work after this plan)
- The glazewm config.yaml.tmpl itself (trimmed in trim-configs)

## Assumptions
- The user still uses these apps (they are the desktop setup); extraction preserves them.
- Extraction target is a separate repo per app (or one `desktop` repo) — decided at execution.
