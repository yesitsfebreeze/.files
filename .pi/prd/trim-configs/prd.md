---
state: open
mode: afk
priority: 4
verify: just gate
---

# Trim over-engineered configs

Purpose: Several configs are frameworks rather than configs: finder.nu (592
lines, a typed chainable pipe engine with resume/back-forward), theme.nu (382
lines, recency/liked/bg-tune), config.nu (727 lines), wezterm.lua (738 lines),
6 tinty scripts (615 lines), 30 television cables, and a 732-line package
installer. Trim each to its essential behavior.

## Requirements
- [ ] finder.nu simplified from the chainable framework to plain pickers (or removed if unused) — its 353-line test updated or dropped to match
- [ ] theme.nu trimmed to apply/switch (drop recency/liked/bg-tune if unused)
- [ ] config.nu trimmed of dead/rarely-used aliases and commands
- [ ] wezterm.lua trimmed of unused features (copy mode, retro tab bar, etc. — keep what is used)
- [ ] tinty scripts consolidated (6 scripts → fewer; drop cmdpal-colors.sh if cmdpal is unused)
- [ ] television exact_cable reduced from 30 to the channels actually used
- [ ] run_onchange_install-packages.sh.tmpl simplified (732 lines → package-manager-driven or per-tool split)
- [ ] glazewm config.yaml.tmpl trimmed of unused bindings/workspaces
- [ ] All configs still load: `just gate` passes, wezterm config parses, nushell libs parse

## Acceptance
- [ ] `just gate` passes after trimming, and each trimmed file is measurably smaller (line counts recorded in the node's close note).

## Out of scope
- Rewriting the nvim config (already reasonable)
- Removing tools the user actively uses (each trim is a judgment call at execution, recorded per file)

## Assumptions
- "Trim" means cut unused/dead behavior, not rewrite from scratch.
- The finder framework's resume/back-forward features are rarely used and can be dropped (the plain picker path covers daily use).
