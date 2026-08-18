---
state: claimed
mode: afk
priority: 3
verify: test "$(git ls-files home/ | grep -cE 'wp-stat-overlay|custom-topbar|layout-daemon')" = 0
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
- [x] wp-stat-overlay removed from `home/` (moved to its own repo/location)
- [x] zebar custom-topbar removed from `home/` (moved to its own repo/location)
- [x] layout-daemon.js removed from `home/` (moved to its own repo/location)
- [x] The run scripts that install/manage these apps are removed or reduced to a pointer to the external repo
- [x] README documents where the apps now live
- [x] The apps still function from their new location (install/run instructions preserved)

## Acceptance
- [x] `chezmoi apply` no longer manages wp-stat-overlay, custom-topbar, or layout-daemon (no tracked files under those paths), and the apps' install/run instructions are documented in README.

## Out of scope
- Building the apps' new repos (follow-on work after this plan)
- The glazewm config.yaml.tmpl itself (trimmed in trim-configs)

## Assumptions
- The user still uses these apps (they are the desktop setup); extraction preserves them.
- Extraction target: one repo per app, named as documented in README.

## Decisions
- Extraction target per app (separate repos): wp-stat-overlay, zebar-custom-topbar, glazewm-layout-daemon
- `settings.json` kept under chezmoi (it's a config file pointing to the custom-topbar pack, not part of the extracted app)
- `zebar-colors.sh` (tinty theme hook) kept unchanged — it writes to the runtime path `~/.glzr/zebar/custom-topbar/theme.css` which will still exist when custom-topbar is deployed from its new repo
- `config.yaml.tmpl` not touched (out of scope per parent node)
- `wezterm.lua` comment not touched (just a comment referencing the daemon)
- Node.js install kept in `install-glazewm.sh.tmpl` (needed by externally-managed layout-daemon)

## Changes made
| File | Change |
|---|---|
| home/dot_config/wp-stat-overlay/ (17 files) | Removed |
| home/dot_glzr/zebar/custom-topbar/ (2 files) | Removed |
| home/dot_glzr/glazewm/layout-daemon.js | Removed |
| home/run_onchange_after_install-wp-stat-overlay.sh.tmpl | Removed (app extracted) |
| home/run_onchange_after_restart-glazewm-zebar.sh.tmpl | Reduced (removed layout-daemon mgmt + deleted file hashes) |
| home/run_onchange_install-glazewm.sh.tmpl | Comments updated to reflect extraction |
| README.md | Added "Desktop apps (external repos)" section |
