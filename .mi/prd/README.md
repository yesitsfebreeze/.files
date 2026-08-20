# PRD Tree — dotfiles rebuild

Derived from four rated inventories in [`../docs/`](../docs):
[`capabilities.md`](../docs/capabilities.md) (the legacy `~/.files` repo),
[`capabilities-nushell.md`](../docs/capabilities-nushell.md) (the live nushell
daily driver), [`capabilities-nvim.md`](../docs/capabilities-nvim.md) (the live
Neovim config), and
[`capabilities-provisioning.md`](../docs/capabilities-provisioning.md) (the
chezmoi layer that actually deploys all of it). The goal is a **minimal
daily-driver base** — every capability is rated and only the ones that earn
their place are taken over. See [`AGENTS.md`](../../AGENTS.md) for the rating
system and PRD conventions.

**Execution:** the ordered, parallelized plan for building this lives in
[`00-delivery/`](00-delivery/00-epic.md), with the schedule in
[`../docs/delivery-gantt.md`](../docs/delivery-gantt.md). The build order
below is the human-readable summary; the wave layout is the operational one.

Items marked `DO NOT PORT` / `DEFER` are excluded by design (listed at the
bottom so the decision stays visible). The docker/mount capabilities are
**consolidated into one tool** ("Capsule"), as required by the note in
`capabilities.md`.

Ratings carried over from the sources: `C` = complexity, `U` = usefulness,
`V` = value ratio (U − C). Epics and features are ordered best-value-first.

```
.mi/prd/
├── README.md                          ← this index
├── 00-delivery/                       Meta: how the work gets executed
│   ├── 00-epic.md                     the workload plan
│   ├── 01-work-breakdown.md           49 tasks, sizes, dependencies
│   ├── 02-parallelization.md          waves, agent fan-out, conflict rules
│   ├── 03-verification-gates.md       what must run before a wave is done
│   └── 04-corrections-backlog.md      audit findings as Wave 0
├── 01-capsule/                        Epic: one consolidated dev-container tool
│   ├── 00-epic.md
│   ├── 01-container-lifecycle.md      C9 U9 V0   (capsule + mount + just, merged)
│   ├── 02-dev-image.md                C7 U8 V1
│   ├── 03-credential-propagation.md   C8 U8 V0
│   └── 04-recent-workspaces.md        C5 U7 V2
├── 02-terminal/                       Epic: WezTerm — INVALID, awaiting re-spec (W0.2)
│   ├── 00-epic.md
│   ├── 01-appearance.md               C4 U9 V5
│   ├── 02-startup-layout.md           C3 U7 V4
│   └── 03-f5-jump-mode.md             C6 U8 V2
├── 03-editor/                         Epic: Neovim (lazy.nvim, live config)
│   ├── 00-epic.md                     (architecture invariants live here)
│   ├── 01-options.md                  C2 U9 V7   opts, whitespace, lsp-log
│   ├── 02-keymaps.md                  C2 U9 V7
│   ├── 03-autocmds.md                 C3 U8 V5
│   ├── 04-plugin-manager.md           C4 U9 V5   lazy.nvim bootstrap
│   ├── 05-completion.md               C4 U9 V5   blink.cmp
│   ├── 06-explorer.md                 C2 U8 V6   oil.nvim
│   ├── 07-formatting.md               C3 U8 V5   conform.nvim
│   ├── 08-telescope.md                C5 U9 V4   + qflist multiselect
│   ├── 09-lsp.md                      C6 U9 V3   mason + native 0.11
│   ├── 10-treesitter.md               C5 U8 V3
│   ├── 11-colorscheme.md              C5 U8 V3   tinted-nvim + mode cursor
│   ├── 12-small-plugins.md            C2 U7 V5   gitsigns/which-key/pairs
│   ├── 13-statusline.md               C6 U7 V1   lualine, palette-built
│   ├── 14-shift-select.md             C7 U7 V0   (SIMPLIFY)
│   └── 15-markdown-tables.md          C3 U5 V2
├── 04-shell/                          Epic: nushell daily driver
│   ├── 00-epic.md                     (architecture invariants live here)
│   ├── 01-core-config.md              C3 U9 V6   env, mkcd funnel, start dir
│   ├── 02-aliases-utilities.md        C2 U8 V6
│   ├── 03-zoxide.md                   C4 U9 V5   wrappers + bare-word fallback
│   ├── 04-television.md               C8 U9 V1   typed finder + channels
│   ├── 05-history.md                  C5 U8 V3   directory-scoped history
│   ├── 06-listing.md                  C5 U8 V3   decorated ls + auto-list
│   ├── 07-quicklist.md                C6 U6 V0   cross-channel recents
│   └── 08-claude-launchers.md         C7 U6 V-1  (SIMPLIFY)
├── 05-platform/                       Epic: provisioning (chezmoi deploy)
│   ├── 00-epic.md
│   ├── 01-deploy-mechanism.md         C3 U9 V6   source layout, apply/push
│   ├── 02-package-provisioning.md     C8 U9 V1   packages.yaml + installer
│   └── 03-shell-init-generation.md    C3 U9 V6   starship/zoxide/tv init
└── 06-help/                           Epic: `help` — the manual (NET-NEW)
    ├── 00-epic.md
    ├── 01-content-model.md            C4 U9 V5   the manual's data source
    ├── 02-help-command.md             C5 U9 V4   dispatch + delegation
    ├── 03-browser.md                  C3 U7 V4   tv fuzzy search
    ├── 04-drift-check.md              C5 U8 V3   documented vs live config
    └── 05-agent-interface.md          C3 U8 V5   --json / --md, discovery
```

Windows/PowerShell support was dropped from scope entirely; see the exclusion
list at the end for the full set.

## Suggested build order

0. **Wave 0 corrections** — the terminal epic needs a from-scratch re-spec and
   three decisions need answering. See
   [`00-delivery/04`](00-delivery/04-corrections-backlog.md).
1. **05-platform** — provisioning; nothing reaches a machine without it, and
   `04-shell/01` depends on its generated init files.
2. **04-shell/01 + 02** — the foundation everything else assumes, plus the
   highest-value-ratio ergonomics.
3. **02-terminal** — only after W0.2 re-specs it.
4. **04-shell/03 + 05 + 06** — navigation, history, listing: the daily loop.
5. **04-shell/04** — television finder; biggest shell surface, do it once the
   loop above is solid.
6. **01-capsule** — the flagship consolidation; biggest scope, do it as one
   coherent tool rather than porting the five old pieces separately.
7. **03-editor/01–07** — the editor base: options, keymaps, autocmds, plugin
   manager, then completion / explorer / formatting.
8. **03-editor/08–13** — finder, LSP, treesitter, colors, statusline.
9. **02-terminal/03**, **04-shell/07 + 08**, **03-editor/14 + 15** — polish
   tier.
10. **06-help** — the manual. Deliberately last as a full epic (it documents
    what the earlier steps built), but start its content file alongside each
    feature as you go: writing the entry while the decision is fresh is
    cheaper than reconstructing it, and `help --check` will demand it anyway.

## Excluded

**`DO NOT PORT` — legacy `~/.files`:** zsh/oh-my-zsh environment · `reload`
sync command · symlink deployment · Claude Code context-routing policy ·
three-pane split layout · OpenCode configuration · quake-style dropdown pane ·
Karabiner launcher shortcuts · container-aware status bar · Obsidian vault
dashboards · background image cycling · Karabiner Windows-keyboard rules ·
Vicky knowledge-base vault · kern local store / pi surface index · OpenCode
theme generation · Neovim insert-mode-first inversion · cross-platform
Lua/shell/PowerShell parity (Windows out of scope).

**`DO NOT PORT` — nushell:** leader mode (superseded by the tv remote on
Ctrl+Space; `input listen` can't do reliable modifiers) · `overlay.nu`
(explicit WIP, never sourced).

**`DO NOT PORT` — Neovim:** the mini.nvim plugin set and `mini.deps`
bootstrap (superseded by the live lazy.nvim config).

**`DEFER` — real, but not in the minimal base:** theme switcher (tinty +
tv) · opacity picker · smear cursor · `cl` goal-loop and `jj` journal
launchers · the long tail of tv cable channels.
