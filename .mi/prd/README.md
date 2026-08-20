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
[`00-delivery/`](00-delivery/prd.md), with the schedule in
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
├── prd.md                              the root node · max-workers
├── README.md                           this index
├── 00-delivery/                        Delivery — the workload plan
│   ├── corrections/                    Corrections backlog
│   │   ├── w0-1-terminal-inventory/    Inventory the live WezTerm config
│   │   ├── w0-2-terminal-respec/       Re-spec the terminal epic from the…
│   │   ├── w0-3-platform-rewrite/      Finish the 05-platform provisioning…
│   │   ├── w0-4-s2-corrections/        Apply the S2/S3 corrections across…
│   │   │   ├── capsule/                01-capsule corrections
│   │   │   ├── delivery/               Delivery + readme corrections
│   │   │   ├── docs-inventories/       Docs inventories
│   │   │   ├── editor/                 03-editor corrections
│   │   │   ├── help/                   06-help corrections
│   │   │   ├── platform/               05-platform corrections + burrito…
│   │   │   └── shell/                  04-shell corrections
│   │   ├── w0-5-capsule-rebase/        Re-base 01-capsule on build-once and…
│   │   └── w0-6-live-bugs/             Record the live-config bugs so the…
│   ├── decisions/                      Open decisions
│   │   ├── fzf/                        HITL · Decision: fzf accepted…
│   │   ├── odin-toolchain/             HITL · Decision: does the Odin-from-…
│   │   ├── shift-select-scope/         HITL · Decision: shift-to-select full…
│   │   ├── tinty/                      HITL · Decision: does tinty stay as…
│   │   └── wallpaper-opacity/          HITL · Decision: wallpaper cycling +…
│   ├── parallelization/                Parallelization
│   ├── verification-gates/             Verification gates
│   └── work-breakdown/                 Work breakdown
├── 01-capsule/                         Capsule — one consolidated dev-…
│   ├── 01-container-lifecycle/         C9 U9 V0 · Container lifecycle…
│   ├── 02-dev-image/                   C7 U8 V1 · Dev image
│   ├── 03-credential-propagation/      C8 U8 V0 · Credential propagation…
│   └── 04-recent-workspaces/           C5 U7 V2 · Recent-workspace picker
├── 02-terminal/                        Terminal (WezTerm)
│   ├── 01-appearance/                  Terminal Appearance
│   ├── 02-startup-layout/              C3 U7 V4 · Startup layout — nine-tab…
│   ├── 03-f5-jump-mode/                C6 U8 V2 · F5 one-shot jump mode
│   ├── 04-copy-mode/                   Copy Mode
│   ├── 05-tab-content-state/           C4 U7 V3 · Tab content-state coloring
│   └── 06-launchd-path/                launchd PATH seeding
├── 03-editor/                          Neovim
│   ├── 01-options/                     C2 U9 V7 · Options baseline
│   ├── 02-keymaps/                     C2 U9 V7 · Core keymaps
│   ├── 03-autocmds/                    C3 U8 V5 · Autocmds
│   ├── 04-plugin-manager/              C4 U9 V5 · Plugin manager (lazy.nvim)
│   ├── 05-completion/                  C4 U9 V5 · Completion (blink.cmp)
│   ├── 06-explorer/                    C2 U8 V6 · File explorer (oil.nvim)
│   ├── 07-formatting/                  C3 U8 V5 · Format on save…
│   ├── 08-telescope/                   C5 U9 V4 · Fuzzy finder (telescope)
│   ├── 09-lsp/                         C6 U9 V3 · LSP (mason + native 0.11)
│   ├── 10-treesitter/                  C5 U8 V3 · Treesitter
│   ├── 11-colorscheme/                 C5 U8 V3 · Colorscheme + mode-aware…
│   ├── 12-small-plugins/               C2 U7 V5 · Git signs, discovery,…
│   ├── 13-statusline/                  C6 U7 V1 · Statusline (lualine)
│   ├── 14-shift-select/                C7 U7 V0 · Shift-to-select (SIMPLIFY)
│   └── 15-markdown-tables/             C3 U5 V2 · Markdown table mode
├── 04-shell/                           Nushell daily driver
│   ├── 01-core-config/                 C3 U9 V6 · Core config
│   ├── 02-aliases-utilities/           C2 U8 V6 · Aliases and small utilities
│   ├── 03-zoxide/                      C4 U9 V5 · Zoxide navigation
│   ├── 04-television/                  C8 U9 V1 · Television finder
│   ├── 05-history/                     C5 U8 V3 · Directory-scoped history
│   ├── 06-listing/                     C5 U8 V3 · Decorated ls + auto-list
│   ├── 07-quicklist/                   C6 U6 V0 · Quicklist — cross-channel…
│   └── 08-claude-launchers/            C7 U6 V-1 · Claude launchers…
├── 05-platform/                        Provisioning — how the config reaches…
│   ├── 01-deploy-mechanism/            C3 U9 V6 · Deploy mechanism
│   │   ├── managed-config/             Managed config surface +…
│   │   └── repo-skeleton/              Repo skeleton: chezmoi source layout,…
│   ├── 02-package-provisioning/        C8 U9 V1 · Package provisioning
│   │   ├── homebrew-bootstrap/         run_once homebrew bootstrap
│   │   └── packages-installer/         packages.yaml + run_onchange installer
│   └── 03-shell-init-generation/       C3 U9 V6 · Shell-init generation
└── 06-help/                            `help` — the environment manual
    ├── 01-content-model/               C4 U9 V5 · Content model
    │   └── coverage/                   every surface covered; verify targets resolve
    ├── 02-help-command/                C5 U9 V4 · The `help` command
    ├── 03-browser/                     C3 U7 V4 · Fuzzy browser
    ├── 04-drift-check/                 C5 U8 V3 · Drift check
    └── 05-agent-interface/             C3 U8 V5 · Agent interface
```

Windows/PowerShell support was dropped from scope entirely; see the exclusion
list at the end for the full set.

## Build order

Generated from [`../gantt/plan.json`](../gantt/plan.json) — the wave layout is
the operational order and this is its summary. A node is claimable when its
`deps` are resolved and its children are covered, so the waves below are what
the dependency graph permits, not a preference.

1. **D.2** · **D.3** · H.1 · W0.1 · W0.3 · W0.6
2. **D.1b** · **D.1c** · **D.1d** · E.1 · P.1 · W0.4 · W0.4a · W0.4b · W0.4c · W0.4d · W0.4e · W0.4f · W0.4g
3. E.2 · E.3 · E.4 · G.1 · H.2 · P.2 · P.3 · P.5 · W0.2 · W0.5
4. C.1 · E.10 · E.11 · E.12 · E.14 · E.15 · E.5 · E.6 · E.8 · E.9 · P.4 · T.1
5. C.2 · E.13 · E.7 · S.1 · T.2
6. C.3 · S.2 · T.3
7. S.3 · T.4
8. S.8 · T.6
9. S.4 · T.7
10. C.4 · S.6
11. S.5
12. S.7
13. H.3
14. H.5
15. H.4

Bold is `hitl` — a person answers it; an agent must not.

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
(explicit WIP, never sourced) · the `bb`/`ba` session aliases (burrito — see
below; they actually invoked `brr`, per M-7).

**`DO NOT PORT` — burrito**, decided 2026-08-20: it is no longer used. This
also settles what was open decision 1, "which layer owns panes/tabs": WezTerm's
self-healing nine-tab floor owns them, with no competing multiplexer. What
comes out with it: the `bb`/`ba` aliases, the `burrito-sessions` tv channel
(which also dissolves the `cht.sh=f5` shortcut collision), `burrito/brr` from
the required package set, burrito from the managed-config surface, and the
whole `T.5 burrito integration` task. The removal is scheduled as
[`w0-4-s2-corrections`](00-delivery/corrections/w0-4-s2-corrections/prd.md).

**`DO NOT PORT` — Neovim:** the mini.nvim plugin set and `mini.deps`
bootstrap (superseded by the live lazy.nvim config).

**`DEFER` — real, but not in the minimal base:** theme switcher (tinty +
tv) · opacity picker · smear cursor · `cl` goal-loop and `jj` journal
launchers · the long tail of tv cable channels.
