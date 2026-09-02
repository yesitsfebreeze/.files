# PRD Tree — dotfiles rebuild

Derived from four rated inventories in [`../docs/`(../../docs):
[`capabilities.md`(../../docs/capabilities.md) (the legacy `~/.files` repo),
[`capabilities-nushell.md`(../../docs/capabilities-nushell.md) (the live nushell
daily driver), [`capabilities-nvim.md`(../../docs/capabilities-nvim.md) (the live
Neovim config), and
[`capabilities-provisioning.md`(../../docs/capabilities-provisioning.md) (the
chezmoi layer that actually deploys all of it). The goal is a **minimal
daily-driver base** — every capability is rated and only the ones that earn
their place are taken over. See [`AGENTS.md`(../../AGENTS.md) for the rating
system and PRD conventions.

**Execution:** the ordered, parallelized plan for building this lives in
[`00-delivery/`](00-delivery/prd.md), with the schedule in each node's own
frontmatter (`needs`, `priority`, `complexity`). Run
`python3 ~/dev/infra/pearde/resources/board/plan.py plan` for the operational
order — a wave list written into this file goes stale the day dependencies
change, which is why none is kept here.

Items marked `DO NOT PORT` / `DEFER` are excluded by design (listed at the
bottom so the decision stays visible). The docker/mount capabilities are
**consolidated into one tool** ("Capsule"), as required by the note in
`capabilities.md`.

Ratings carried over from the sources: `C` = complexity, `U` = usefulness,
`V` = value ratio (U − C). Epics and features are ordered best-value-first.

```
prds/
├── prd.md                              the root node · max-workers
├── README.md                           this index
├── 00-delivery/                        Delivery — the workload plan
│   ├── corrections/                    Corrections backlog
│   │   ├── w0-1-terminal-inventory/    Inventory the live WezTerm config
│   │   ├── w0-2-terminal-respec/       Re-spec the terminal epic from the…
│   │   ├── w0-3-platform-rewrite/      Finish the 05-platform provisioning…
│   │   ├── w0-4-s2-corrections/        Apply the S2/S3 corrections across…
│   │   │   ├── backlog-closeout/       Backlog close-out
│   │   │   ├── capsule/                01-capsule corrections
│   │   │   ├── delivery/               Delivery + readme corrections
│   │   │   ├── docs-inventories/       Docs inventories
│   │   │   ├── editor/                 03-editor corrections
│   │   │   ├── help/                   06-help corrections
│   │   │   ├── platform/               05-platform corrections + burrito…
│   │   │   ├── provisioning-rerate/    Provisioning inventory re-rate
│   │   │   └── shell/                  04-shell corrections
│   │   ├── w0-5-capsule-rebase/        Re-base 01-capsule on build-once and…
│   │   ├── w0-6-live-bugs/             Record the live-config bugs so the…
│   │   ├── gate-home-isolation/        Gate scripts must not touch the live…
│   │   ├── gates-frontmatter-port/     Port gates/ off the retired .mi layout
│   │   └── stale-framework-links/      Repair citations to deleted protocol…
│   ├── decisions/                      Open decisions
│   │   ├── fzf/                        HITL · Decision: fzf accepted…
│   │   ├── fzf-model-picker/           HITL · Decision: fzf as `cll`'s model…
│   │   ├── odin-toolchain/             HITL · Decision: does the Odin-from-…
│   │   ├── shift-select-scope/         HITL · Decision: shift-to-select full…
│   │   ├── tinty/                      HITL · Decision: does tinty stay as…
│   │   └── wallpaper-opacity/          HITL · Decision: wallpaper cycling +…
│   ├── finish-line/                    The settled contract for closing…
│   │   ├── agent-overview-derived-tools/  Overview names its tools, no…
│   │   ├── doctor-debt-live-nodes/     Doctor debt, repaired where live
│   │   ├── drift-check-terminal-surface/  `help --check` vs WezTerm…
│   │   └── epic-invariants-prose/      Epic invariants stop being boxes
│   ├── parallelization/                Parallelization
│   ├── verification-gates/             Verification gates
│   └── work-breakdown/                 Work breakdown
├── 01-capsule/                         Capsule — one consolidated dev-…
│   ├── 01-container-lifecycle/         C9 U9 V0 · Container lifecycle
│   ├── 02-dev-image/                   C7 U8 V1 · Dev image
│   ├── 03-credential-propagation/      C8 U8 V0 · Credential propagation…
│   └── 04-recent-workspaces/           C5 U7 V2 · Recent-workspace picker
├── 02-terminal/                        Terminal (WezTerm)
│   ├── 01-appearance/                  C5 U9 V4 · Terminal appearance — font,…
│   ├── 02-startup-layout/              C10 U7 V-3 · Startup layout — the self-…
│   ├── 03-f5-jump-mode/                C6 U8 V2 · F5 one-shot tab select
│   ├── 04-copy-mode/                   C4 U9 V5 · Copy mode, paste, and the…
│   ├── 05-tab-content-state/           C4 U7 V3 · Tab content-state colouring
│   ├── 06-launchd-path/                C2 U10 V8 · launchd PATH seeding + nushell default_prog
│   └── 07-grid-centering/              C8 U6 V-2 · Dynamic grid centering
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
│   ├── 08-claude-launchers/            C7 U6 V-1 · Claude launchers…
│   ├── 09-theme-switcher/              C8 U5 V-3 · Theme switcher (tinty…
│   └── 10-litellm-launcher/            C6 U8 V2 · LiteLLM model launcher…
├── 05-platform/                        Provisioning — how the config reaches…
│   ├── 01-deploy-mechanism/            C3 U9 V6 · Deploy mechanism
│   │   ├── managed-config/             Managed config surface +…
│   │   └── repo-skeleton/              Repo skeleton: chezmoi source layout,…
│   ├── 02-package-provisioning/        C8 U9 V1 · Package provisioning
│   │   ├── homebrew-bootstrap/         run_once homebrew bootstrap
│   │   └── packages-installer/         packages.yaml + run_onchange installer
│   └── 03-shell-init-generation/       C3 U9 V6 · Shell-init generation
├── 06-help/                            `help` — the environment manual
│   ├── 01-content-model/               C4 U9 V5 · Content model
│   │   └── coverage/                   every surface covered; verify targets resolve
│   ├── 02-help-command/                C5 U9 V4 · The `help` command
│   ├── 03-browser/                     C3 U7 V4 · Fuzzy browser
│   ├── 04-drift-check/                 C5 U8 V3 · Drift check
│   ├── 05-agent-interface/             C3 U8 V5 · Agent interface
│   └── 06-manual-markdown/             C3 U8 V5 · The manual as markdown, and `?`
├── 07-multiplexer/                     C7 U9 V2 · tmux — the portable layer
    ├── 01-session-and-windows/         one `main` session, stable indices, the
    │                                   terminal-integration floor
    ├── 02-key-tables/                  F4 split · F5 window/pane · F6 theme
    ├── 03-status-bar/                  digits, occupied tint, host, cwd, clock
    ├── 04-palette-delivery/            tinty → OSC + tmux colors.conf
    ├── 05-copy-and-clipboard/          copy-mode-vi, the c-cycle, OSC 52
    ├── 06-nvim-session/                something for resurrect to restore
    ├── 07-persistence/                 resurrect + continuum, cloned by install.sh
    ├── 08-wezterm-reduction/           the cutover; WezTerm keeps local chrome
    └── 09-manual-entries/              terminal.nuon on tmux bindings
├── 08-claude-agent/                     C7 U8 V1 · Claude agent — Claude Code manages tmux panes and edits in nvim
│   ├── 01-tmux-mcp/                     the tmux MCP server
│   ├── 02-nvim-plugin/                  claudecode.nvim + claude-tmux.nvim
│   ├── 03-tmux-config/                  Claude Code inside tmux
│   └── 04-help-entries/                 the manual entries for the new bindings
└── 09-simplify/                         Simplify — smaller and more straightforward, everywhere (meta)
    ├── 01-hygiene/                      baseline commit, duplicates and stale ignores out
    ├── 02-board/                        every prd.md stays; specs, process memos, AGENTS.md bulk go
    ├── 03-help-system/                  no drift checker, no review files, one renderer
    ├── 04-nushell/                      built-ins, one keybinding append, no tombstones
    ├── 05-terminal/                     tmux.conf to ~250 lines, tv-all on command-prompt
    ├── 06-neovim-television/            five channels, keymodel, theme = "tinted"
    ├── 07-provisioning/                 a Brewfile and sixty lines
    └── 08-litellm-out/                  the litellm stack leaves the repo
```

## Excluded

**`DO NOT PORT` — legacy `~/.files`:** zsh/oh-my-zsh environment · `reload`
sync command · symlink deployment · Claude Code context-routing policy ·
three-pane split layout · OpenCode configuration · quake-style dropdown pane ·
Karabiner launcher shortcuts · container-aware status bar · Obsidian vault
dashboards · background image cycling · Karabiner Windows-keyboard rules ·
Vicky knowledge-base vault · kern local store / pi surface index · OpenCode
theme generation · Neovim insert-mode-first inversion · cross-platform
Lua/shell/PowerShell parity (Windows out of scope) · cross-platform
dependency bootstrap (`conf/bootstrap.lua` and its `.cache/.bootstrap`
stamp — superseded by `05-platform`).

**`DO NOT PORT` — nushell:** leader mode (superseded by the tv remote on
Ctrl+Space; `input listen` can't do reliable modifiers) · `overlay.nu`
(explicit WIP, never sourced) · the `bb`/`ba` session aliases (burrito — see
below; they actually invoked `brr`, per M-7).

**`DO NOT PORT` — burrito**, decided 2026-08-20: it is no longer used. This
also settled what was open decision 1, "which layer owns panes/tabs" —
**and the answer to that half was reversed on 2026-08-30**: tmux owns them
now, WezTerm binds no tab or pane key at all, and
[`07-multiplexer`](07-multiplexer/prd.md) carries the argument. The
exclusion itself is unchanged and the reason needs restating rather than
repeating: what was deleted in 2026-08-20 was a *second* multiplexer under a
WezTerm that already was one. Two live key schemes was the hazard then and
is the hazard now; only the surviving one changed. What
comes out with it: the `bb`/`ba` aliases, the `burrito-sessions` tv channel
(which also dissolves the `cht.sh=f5` shortcut collision), `burrito/brr` from
the required package set, burrito from the managed-config surface, and the
whole `T.5 burrito integration` task. The removal is scheduled as
[`w0-4-s2-corrections`](00-delivery/corrections/w0-4-s2-corrections/prd.md).

**`DO NOT PORT` — Neovim:** the mini.nvim plugin set and `mini.deps`
bootstrap (superseded by the live lazy.nvim config).

**`DO NOT PORT` — the dev image's Odin/pi toolchain**, decided 2026-08-21:
the compiler built from source and the `pi` agent with its ~20 pi-oilrig
extensions come out of the consolidated capsule image. They
dominate cold build time and serve a minority of projects. Relocated rather
than lost — a project that needs them layers them per-project on top of the
base image. Recorded in
[`01-capsule/02-dev-image`](01-capsule/02-dev-image/prd.md).

**`DO NOT PORT` — the live wallpaper and opacity surfaces**, decided
2026-08-21: the `Ctrl+Shift+B` WezTerm pipeline that blurs an image and
applies it as the OS desktop wallpaper — together with the 2.8 MB
`background.png` it writes into the config dir, which nothing reads — and the
OSC-1337 `opacity` user-var toggle. The legacy `Ctrl+Shift+P` /
`Ctrl+Shift+O` versions are already excluded above; this adds the live
rebuilds of the same two ideas, which the audit (T-11) found still standing
and unrefused. `Ctrl+Shift+B` is thereby free and goes to
`capsule --rebuild`. Two things are **not** excluded by it: the interactive
opacity picker keeps its `DEFER` below, and the static
`window_background_opacity` of the appearance baseline is untouched.
Recorded in
[`00-delivery/decisions/wallpaper-opacity`](00-delivery/decisions/wallpaper-opacity/prd.md).

**`DO NOT PORT` — provisioning**, per
[`capabilities-provisioning.md`(../../docs/capabilities-provisioning.md):
Windows config mirroring (`run_after_mirror-config-to-windows.sh`) — the host
is macOS-only, so the mirror has no destination. Non-goal recorded in
[`05-platform`](05-platform/prd.md).

**`DEFER` — provisioning:** the `wp-stat-overlay` installer · the published
docs site (`docs/`). Both rated in
[`capabilities-provisioning.md`(../../docs/capabilities-provisioning.md) and
held out of the minimal base by [`05-platform`](05-platform/prd.md).

**`DEFER` — real, but not in the minimal base:** opacity picker ·
smear cursor · `cl` goal-loop and `jj` journal launchers · the long tail
of tv cable channels.

**Retained — the tinty theme switcher**, decided 2026-08-21: it does not
leave the minimal base after all. `tinty apply` is the palette source of
truth; **since 2026-08-30 its hook writes `~/.config/tmux/colors.conf` and
pushes OSC 4/10/11/12 to every attached client's tty** (the `colors.lua`
path and WezTerm's reload watch are deleted — see
[`07-multiplexer/04-palette-delivery`](07-multiplexer/04-palette-delivery/prd.md)),
`config.nu` re-asserts
its tinted-shell artifact in every new shell, F6 delegates the switch to
`theme.nu`, and Neovim (base16 + transparent) and television (`default`
ANSI theme) inherit downstream. Dropping it would have left four scheduled
nodes with no palette owner, so the `DEFER` came off and the inventory
verdict is now `SIMPLIFY`: the palette-owning core is in, the background
override ladder and its tuner stay out. Recorded in
[`00-delivery/decisions/tinty`](00-delivery/decisions/tinty/prd.md) and open
decision 2 of the
[corrections backlog](00-delivery/corrections/prd.md). The shell half now
has a node — [`04-shell/09-theme-switcher`](04-shell/09-theme-switcher/prd.md)
(S.9), created 2026-08-21 — and the F6 binding is
[`w0-2-terminal-respec`](00-delivery/corrections/w0-2-terminal-respec/prd.md)
R5's to place.
