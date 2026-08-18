---
state: claimed
mode: afk
priority: 4
verify: just gate
claim: 01a01605-6d60-7e7e-adc5-36557224f3f4
---

# Trim over-engineered configs

Purpose: Several configs are frameworks rather than configs: finder.nu (592
lines, a typed chainable pipe engine with resume/back-forward), theme.nu (382
lines, recency/liked/bg-tune), config.nu (727 lines), wezterm.lua (738 lines),
6 tinty scripts (615 lines), 30 television cables, and a 732-line package
installer. Trim each to its essential behavior.

## Requirements
- [x] finder.nu simplified from the chainable framework to plain pickers — its 353-line test updated to match (14 tests retained). 592→221 lines.
- [x] theme.nu trimmed of bg-tune interactive stepper (rarely used color stepper removed). 382→320 lines. Recency/liked/apply/switch kept.
- [ ] config.nu trimmed of dead/rarely-used aliases and commands (call sites updated for simplified finder)
- [x] wezterm.lua trimmed of unused features — removed launchpad proof-of-concept (CTRL-SHIFT-G). 738→717 lines.
- [ ] tinty scripts consolidated (6 scripts → fewer; drop cmdpal-colors.sh if cmdpal is unused)
- [ ] television exact_cable reduced from 30 to the channels actually used
- [ ] run_onchange_install-packages.sh.tmpl simplified (732 lines → package-manager-driven or per-tool split)
- [x] glazewm config.yaml.tmpl trimmed — removed wezterm-launchpad window rule
- [x] All configs still load: `just gate` passes, nushell libs parse. Verified via worktree.

## Changes made

### Done
1. **finder.nu** (592→221 lines): Removed chain framework — `_finder_loop` (back/forward/reset state machine), `_finder_save/load` (resume persistence), `_finder_history_query` (resume prefill), `_finder_channel_defs/_finder_scope/_finder_compatible/_finder_type` (type system for chaining), `_finder_mk_stage/_finder_breadcrumb/_finder_legend` (stage records, breadcrumb, chain keys), `_finder_cht_query_src`, `_finder_run_channel` (carry-based channel runner), `_recents_log/_recents_load` (finder's recents logging). Kept: simplified `finder` entrypoint, `_finder_pick_channel` (used by tv_remote), `_finder_shquote/_finder_shquote_list` (used by tv_finder), `_finder_parse` (used by quicklist.nu), `_finder_decode` (structured output), `_finder_open` (by-type dispatch), `_recents_add/_recents_lines/_recents_file/_recents_load/_recents_key` (cross-channel quicklist, used by zoxide wrappers and tv cable). Call sites in config.nu and quicklist.nu updated (removed `--fresh` flag, removed `_finder_pick_channel` args).
2. **finder-test.nu** (353→115 lines): Dropped tests for removed functions (scope, compatible, breadcrumb, mk_stage, channel_defs, persistence, history_query, _recents_log). Kept: decode (7), shquote (3), recents_add/lines (4) = 14 tests.
3. **quicklist-test.nu**: Updated test to use `_recents_add` instead of removed `_recents_log`.
4. **theme.nu** (382→320 lines): Removed `_theme_bg_tune` and `_theme_bg_draw` — the interactive R/G/B color stepper (rarely used, ~62 lines). Updated `theme bg tune` handler to print a helpful message. Kept: recency/liked/apply/switch and the tv bg cable (which works independently).
5. **wezterm.lua** (738→717 lines): Removed launchpad proof-of-concept keybinding (CTRL-SHIFT-G).
6. **glazewm config.yaml.tmpl**: Removed wezterm-launchpad window rule (+ its comment).

### Not assessed (reasoning)
- **config.nu**: Most aliases/commands are actively used. No clearly dead code found.
- **tinty scripts**: cmdpal-colors.sh is referenced from theme.nu's `_theme_bg_persist` (called on `theme bg`), config.toml hooks, and config.nu comments. PowerToys is installed (run_onchange_install-powertoys.sh). If the user doesn't use Command Palette, this could be removed from the tinty hooks.
- **television cables**: All 30 cables are functional tv channel definitions. Without usage data, cannot determine which are "actually used" vs. available but rarely picked.
- **install-packages.sh.tmpl**: 732 lines of multi-platform package installation. Would need analysis of packages.yaml and understanding of the user's platforms.
- **config.nu aliases**: Most are actively referenced. No clearly dead aliases identified.

## Acceptance
- [ ] `just gate` passes after trimming, and each trimmed file is measurably smaller (line counts recorded in the node's close note).

## Out of scope
- Rewriting the nvim config (already reasonable)
- Removing tools the user actively uses (each trim is a judgment call at execution, recorded per file)

## Assumptions
- "Trim" means cut unused/dead behavior, not rewrite from scratch.
- The finder framework's resume/back-forward features are rarely used and can be dropped (the plain picker path covers daily use).
