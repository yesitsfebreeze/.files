---
state: done
mode: afk
priority: 3
verify: test "$(git ls-files home/ | grep -cE 'wp-stat-overlay|custom-topbar|layout-daemon')" = 0
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
- [x] README documents where the apps now live — section written, but the "external repos" framing is SUPERSEDED by the user reversal (2026-08-18): apps are deleted, not relocated; de-windows node rewrites the README
- [x] The apps still function from their new location — MOOT: user reversed the premise ("strip windows, git has everything") — the apps are deleted, not relocated; no new location exists

## Acceptance
- [x] `chezmoi apply` no longer manages wp-stat-overlay, custom-topbar, or layout-daemon (no tracked files under those paths), and the apps' install/run instructions are documented in README.

## Out of scope
- Building the apps' new repos (follow-on work after this plan)
- The glazewm config.yaml.tmpl itself (trimmed in trim-configs)

## Assumptions
- REVERSED by user (2026-08-18): the apps are NOT still wanted — the user is moving to Linux-first and wants Windows stripped ("i want to strip windows we have everything in git so its fine"). The removal from `home/` is exactly what de-windows needs; the "external repos" framing is superseded. Git history preserves the apps.
- Extraction target: one repo per app, named as documented in README. (Moot — no repos are built.)

## Decisions
- Extraction target per app (separate repos): wp-stat-overlay, zebar-custom-topbar, glazewm-layout-daemon — MOOT: user reversed to deletion; no repos are built
- `settings.json` kept under chezmoi (it's a config file pointing to the custom-topbar pack, not part of the extracted app) — de-windows deletes it (zebar is Windows-only)
- `zebar-colors.sh` (tinty theme hook) kept unchanged — de-windows deletes it (zebar is Windows-only)
- `config.yaml.tmpl` not touched (out of scope per parent node) — de-windows deletes it (glazewm is Windows-only)
- `wezterm.lua` comment not touched (just a comment referencing the daemon) — de-windows removes the reference
- Node.js install kept in `install-glazewm.sh.tmpl` (needed by externally-managed layout-daemon) — de-windows deletes the script (glazewm is Windows-only)

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
