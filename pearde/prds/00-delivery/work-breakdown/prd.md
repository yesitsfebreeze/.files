---
state: done
claim:
priority: 0
est: 2h
actual: 20m
kind: doc
mode: afk
needs:
footprint:
  - prds/00-delivery/work-breakdown/check-tables.py
  - prds/00-delivery/work-breakdown/prd.md
verify: "python3 prds/00-delivery/work-breakdown/check-tables.py"
---

# Work breakdown

Parent: [Delivery epic](../prd.md) · net-new

Purpose: Every task in the build, with its size and its files. Nothing here is
authored twice: each row is a *projection* of one board node, and
`check-tables.py` re-derives every cell from that node's frontmatter and fails
when they disagree. The rule the schedule applies: a task depends on another
only if it cannot be *written and verified* without it. "Would be nicer
afterwards" is not a dependency — that ordering belongs to the wave layout in
[02-parallelization](../parallelization/prd.md).

**Size is the node's `est:`, copied verbatim.** The **S/M/L/XL** letters this
document used until 2026-08-24 are gone. They were fiction: 25 of the 56 rows
then present carried a letter whose own band excluded its node's `est:` — `S.1`
was `L` at 9.75h, `S.2` was `S` at 4h, `P.3` was `S` at 0h — and against the
`actual:` values that have since been recorded the letters did not even
rank-order reality, with `M` measuring lower than `S`. A second copy of a
number that drifts on 45% of rows is the same failure as the deleted
`Depends on` column, and C2 of the checker now guards it.

**An `est:` on this board is an estimate, and it runs high.** Measured
2026-08-24 over every node carrying both figures: 37 pairs, **62.75h of `est:`
against 15.08h of `actual:` — 4.2x high**. The ratio is not uniform and must
not be applied as a correction factor: three of the 37 came in *over* their
estimate. `actual:` is the only measured column in this document's inputs; a
Size cell is a forecast that has been wrong by a factor of four.

**Dependencies are not restated here.** The dependency graph lives in each
node's own `needs:` frontmatter — the board says *what*, the frontmatter says
*in what order*. These tables carried a `Depends on` column until 2026-08-21,
by which point all 44 of its cells disagreed with the schedule; it was deleted
rather than re-synced, because a second copy of the graph is exactly what
rotted. (The graph lived in `.mi/gantt/plan.json` until 2026-08-22, when the
plan file was retired and its edges folded into the frontmatter — same lesson:
the graph gets exactly one home.) `needs:` is read in **block form only**, and
the two forms that silently fail are both measured: an inline
`needs: [a, b]` parses as one bogus path string, and `needs: []` parses as the
literal string `"[]"`. The empty form is a bare `needs:`.

**Row shape**, one for every table below: the **ID** links the node it names,
so a row cannot point at the wrong PRD for long — `gates/tree-links.py`
already gates link targets under `prds/`. **Files** are repo-relative paths
from the repo root, and `(planned)` marks a path the task will create and has
not yet. A path may appear in many cells when it is an **append-only
registry** — the wave registry, the manual gates, `lazy-lock.json`, the
`config.nu` and `init.lua` module funnels, the `help/*.nuon` topics — because
epic invariant 4 and the module layout make one line per task the intended
shape there. Those files are excluded from collision detection and from
nothing else; the checker lists each with its reason.

## Acceptance
- [x] Every board `task:` appears exactly once as a row, and every row links
      the node that carries it — C1, green on 2026-08-24 against all 70 tasks.
- [x] Every row names its files, every path resolves from the repo root, and
      no two tasks that can still race in one wave name the same file — C3 and
      the gating half of C5. A pair where one task has already landed is
      reported and never gating; the reason is in the checker's docstring.
- [x] The dependency graph lives in the nodes' `needs:` frontmatter and no row
      here restates an edge — C4. (The first draft of these tables carried the
      graph itself and invented an edge that existed nowhere — `S.7 → H.2` —
      which is why this box exists.)
- [x] The critical path is computed on demand rather than stored, so it cannot
      go stale when a task's dependencies change — C7 recomputes it on every
      run and rejects a frozen chain in the body.

## Out of scope
- Anything this node's Requirements do not name. The epic
  ([`../prd.md`](../prd.md)) owns the shared invariants.

## Wave 0 — corrections, decisions and gates

These come first because they change what the later tasks build. Detail in
[04-corrections-backlog](../corrections/prd.md).

The 2026-08-20 audit made this wave much larger than first estimated: the
terminal epic had to be rebuilt rather than adjusted. The scope forks the audit
raised are no longer open — all five were answered on 2026-08-21 and each has
its own board node — so what is left of the wave is the terminal rebuild, the
corrections sweep, the gate work the sweep exposed, and the five recorded
decisions.

**The corrections epic holds 64 further nodes that carry no `task:` id and
appear in no wave**, so they are not rows here; the epic itself
([`../corrections/prd.md`](../corrections/prd.md)) is their index. A table that
grew a row per correction would need editing nightly, which is how a table
starts lying.

| ID | Task | Size | Files |
|---|---|---|---|
| [W0.1](../corrections/w0-1-terminal-inventory/prd.md) | Inventory the live WezTerm config as a rated capability doc | 2.5h | `docs/capabilities-terminal.md` |
| [W0.2](../corrections/w0-2-terminal-respec/prd.md) | Re-spec the terminal epic from scratch against that inventory — nearly every requirement it replaced was wrong | 8.2h | `prds/02-terminal/prd.md`, `prds/02-terminal/*/prd.md` |
| [W0.3](../corrections/w0-3-platform-rewrite/prd.md) | Rewrite the platform epic as the provisioning epic | 1h | `prds/05-platform/prd.md`, `prds/05-platform/*/prd.md` |
| [W0.4](../corrections/w0-4-s2-corrections/prd.md) | The S2 corrections sweep — a container, one child per epic touched so each writes only files it owns | 0h | `prds/00-delivery/corrections/w0-4-s2-corrections/prd.md` |
| [W0.4a](../corrections/w0-4-s2-corrections/docs-inventories/prd.md) | S2 corrections: the rated inventories | 1.5h | `docs/capabilities*.md` |
| [W0.4b](../corrections/w0-4-s2-corrections/shell/prd.md) | S2 corrections: the shell epic | 1.3h | `prds/04-shell/prd.md`, `prds/04-shell/*/prd.md` |
| [W0.4c](../corrections/w0-4-s2-corrections/editor/prd.md) | S2 corrections: the editor epic | 3.7h | `prds/03-editor/prd.md`, `prds/03-editor/*/prd.md` |
| [W0.4d](../corrections/w0-4-s2-corrections/help/prd.md) | S2 corrections: the help epic | 2h | `prds/06-help/prd.md`, `prds/06-help/*/prd.md` |
| [W0.4e](../corrections/w0-4-s2-corrections/capsule/prd.md) | S2 corrections: the capsule epic | 1.1h | `prds/01-capsule/prd.md`, `prds/01-capsule/*/prd.md` |
| [W0.4f](../corrections/w0-4-s2-corrections/platform/prd.md) | S2 corrections: the provisioning epic | 3.7h | `prds/05-platform/prd.md`, `prds/05-platform/*/prd.md` |
| [W0.4g](../corrections/w0-4-s2-corrections/delivery/prd.md) | S2 corrections: the delivery meta-epic | 4.5h | `prds/00-delivery/prd.md`, `prds/00-delivery/*/prd.md` |
| [W0.4h](../corrections/w0-4-s2-corrections/backlog-closeout/prd.md) | Backlog close-out: mark every swept row, and repair the gates the sweep found green while asserting the opposite of the record | 3.7h | `prds/00-delivery/corrections/prd.md`, `gates/audit-findings.sh`, `tests/live-bugs.sh` |
| [W0.4i](../corrections/w0-4-s2-corrections/provisioning-rerate/prd.md) | Re-rate the provisioning epic against the installer that actually exists | 1.6h | `prds/05-platform/02-package-provisioning/prd.md`, `prds/05-platform/02-package-provisioning/*/prd.md`, `docs/capabilities-provisioning.md` |
| [W0.5](../corrections/w0-5-capsule-rebase/prd.md) | Re-base the capsule epic on build-once, and fix the binding collisions | 0.75h | `prds/01-capsule/prd.md`, `prds/01-capsule/*/prd.md`, `prds/README.md` |
| [W0.6](../corrections/w0-6-live-bugs/prd.md) | Record the live-config bugs so the rebuild fixes them instead of copying them | 1.75h | `prds/00-delivery/corrections/prd.md`, `tests/live-bugs.sh` |
| [W0.7](../corrections/stale-framework-links/prd.md) | Repair the citations left pointing at framework documents that were deleted under them | 0.5h | `prds/06-help/01-content-model/prd.md`, `prds/00-delivery/corrections/stale-framework-links/prd.md` |
| [W0.8](../corrections/gate-reconciliation/prd.md) | Repoint the two gates that later, correct work turned red | 2h | `tests/deploy-skeleton.sh`, `tests/live-bugs.sh` |
| [W0.9](../corrections/gate-home-isolation/prd.md) | Pin `HOME` so a gate can never write into the machine it runs on | 2.75h | `tests/deploy-skeleton.sh`, `gates/lib.sh`, `tests/managed-config.sh`, `tests/shell-init.sh` |
| [G.1](../verification-gates/prd.md) | The gate runner: what must actually run before a wave counts as done | 7.5h | `gates/justfile`, `gates/*.sh`, `gates/tree-links.py`, `gates/waves.tsv`, `gates/manual/wave*.md` |
| [D.1b](../decisions/tinty/prd.md) | Decision: tinty stays the palette owner, verdict `SIMPLIFY` | 3.25h | `prds/00-delivery/decisions/tinty/prd.md`, `AGENTS.md` |
| [D.1c](../decisions/fzf/prd.md) | Decision: fzf is replaced — television owns every picker | 1.5h | `prds/00-delivery/decisions/fzf/prd.md`, `prds/README.md` |
| [D.1d](../decisions/wallpaper-opacity/prd.md) | Decision: the wallpaper pipeline and the opacity toggle come out | 1h | `prds/00-delivery/decisions/wallpaper-opacity/prd.md`, `prds/README.md` |
| [D.2](../decisions/odin-toolchain/prd.md) | Decision: the Odin toolchain leaves the base image and is layered per project | 1h | `prds/00-delivery/decisions/odin-toolchain/prd.md`, `prds/01-capsule/02-dev-image/prd.md` |
| [D.3](../decisions/shift-select-scope/prd.md) | Decision: shift-to-select is ported in full, with the tests | 1h | `prds/00-delivery/decisions/shift-select-scope/prd.md`, `prds/03-editor/14-shift-select/prd.md` |

What was open decision 1 — which layer owns panes and tabs — is not on that
list because it was **removed rather than resolved**: burrito was deleted on
2026-08-20, taking `D.1a` and the burrito-integration task with it, and
WezTerm's self-healing nine-tab floor owns panes and tabs with no competing
multiplexer. That is also why Track T has no fifth row. The reasoning and the
full list of what came out with it live in
[`README.md`'s exclusion entry](../../README.md).

The wave's own ordering is in the nodes, not here: the corrections sweep is the
gate the terminal rebuild and the capsule re-base wait on, and every one of
those edges is a line of `needs:` you can read at the node.


## Track P — provisioning (the deploy mechanism)

Nothing reaches a machine without this, so it heads the critical path.

| ID | Task | Size | Files |
|---|---|---|---|
| [P.1](../../05-platform/01-deploy-mechanism/repo-skeleton/prd.md) | Repo skeleton: the chezmoi source layout, `home/`, the justfile | 3h | `home/.chezmoi.toml.tmpl`, `home/.chezmoiignore`, `justfile`, `tests/deploy-skeleton.sh` |
| [P.2](../../05-platform/02-package-provisioning/packages-installer/prd.md) | Tool installation: the flat installer | 5h | `install.sh`, `tests/provisioning.sh`, `gates/waves.tsv` |
| [P.3](../../05-platform/02-package-provisioning/homebrew-bootstrap/prd.md) | Homebrew bootstrap — folded into the installer, not a chezmoi stage | 0h | `install.sh` |
| [P.4](../../05-platform/03-shell-init-generation/prd.md) | Shell-init generation for starship, zoxide and television | 3.25h | `home/run_after_generate-shell-init.sh`, `tests/shell-init.sh`, `gates/waves.tsv` |
| [P.5](../../05-platform/01-deploy-mechanism/managed-config/prd.md) | The managed config surface and the git config template | 2h | `home/dot_gitconfig.tmpl`, `tests/managed-config.sh` |

Two rows here record a scope change rather than a task. Commit `8fe3a71`
(2026-08-19) deleted `.chezmoidata/` and the onchange installer template in
favour of a single flat `install.sh`, which is why P.2 names one script and no
data model. P.3 is `0h` for the same reason: the `run_once_before_*` chezmoi
bootstrap stage it was written for no longer exists, and its own R3 places the
capability in `install.sh` §1 — so the row names the file the work landed in,
not the stage it was planned for.


## Track S — nushell

Serial by nature: almost every task adds to `config.nu` (execution invariant
2), and the whole track is one `needs:` chain.

| ID | Task | Size | Files |
|---|---|---|---|
| [S.1](../../04-shell/01-core-config/prd.md) | Core config, the `mkcd` funnel and the start directory | 9.75h | `home/dot_config/nushell/env.nu`, `home/dot_config/nushell/config.nu`, `home/dot_config/nushell/dirstack.nu`, `tests/nushell-core.sh` |
| [S.2](../../04-shell/02-aliases-utilities/prd.md) | Aliases, `cf`, and pass completion | 4h | `home/dot_config/nushell/pass.nu`, `home/dot_config/nushell/config.nu`, `tests/nushell-aliases.sh` |
| [S.3](../../04-shell/06-listing/prd.md) | Decorated `ls` and auto-list | 3h | `home/dot_config/nushell/config.nu`, `tests/shell-listing.sh` |
| [S.4](../../04-shell/03-zoxide/prd.md) | zoxide wrappers and the bare-word fallback | 5h | `home/dot_config/nushell/zoxide.nu`, `home/dot_config/nushell/config.nu`, `tests/shell-zoxide.sh` |
| [S.5](../../04-shell/04-television/prd.md) | television: config, the cable channels and the typed decoder | 8.5h | `home/dot_config/television/config.toml`, `home/dot_config/television/cable/`, `home/dot_config/nushell/finder.nu`, `home/dot_config/nushell/config.nu`, `home/dot_config/nushell/help/shell.nuon`, `tests/shell-television.sh` |
| [S.6](../../04-shell/05-history/prd.md) | Directory-scoped history | 4h | `home/dot_config/nushell/history.nu`, `home/dot_config/nushell/config.nu`, `tests/shell-history.sh` |
| [S.7](../../04-shell/07-quicklist/prd.md) | Quicklist recents: the log, the channel and its keybinding | 1.5h | `home/dot_config/nushell/recents.nu`, `home/dot_config/nushell/quicklist.nu` (planned), `home/dot_config/television/cable/quicklist.toml` (planned), `home/dot_config/nushell/finder.nu`, `home/dot_config/nushell/zoxide.nu`, `home/dot_config/nushell/config.nu`, `tests/shell-quicklist.sh`, `gates/manual/wave5.md` |
| [S.8](../../04-shell/08-claude-launchers/prd.md) | The `cc` / `cr` launchers | 3h | `home/dot_config/nushell/claude.nu`, `home/dot_config/nushell/config.nu`, `tests/shell-claude.sh` |
| [S.9](../../04-shell/09-theme-switcher/prd.md) | Theme switcher: the module, the A/B slots and the scheme picker | 3.5h | `home/dot_config/nushell/theme.nu`, `home/dot_config/nushell/config.nu`, `home/dot_config/tinted-theming/tinty/config.toml`, `home/dot_config/tinted-theming/tinty/executable_wezterm-colors.sh`, `home/dot_config/television/cable/theme.toml.tmpl`, `home/dot_config/television/executable_theme-preview.sh`, `tests/theme-switcher.sh` |

Every module here is its own file, sourced from `config.nu` — the cells that
say otherwise until 2026-08-24 were wrong about the file, not just the prefix.
The zoxide wrappers, the directory-scoped history and the Claude launchers all
named `config.nu` as their whole footprint; the code went to `zoxide.nu`,
`history.nu` and `claude.nu`, with one `source` line each in the funnel.

The theme switcher is **missing work, not deferred work**: the tinty decision
kept tinty as the palette owner, which turned `theme.nu` from something
excluded into something owed, and its node was created on 2026-08-21 to hold
it.


## Track E — Neovim

The most parallel track in the build: after the base, every task is a separate
file under `lua/plugins/`.

| ID | Task | Size | Files |
|---|---|---|---|
| [E.1](../../03-editor/01-options/prd.md) | Options and the entry point | 2.5h | `home/dot_config/nvim/init.lua`, `home/dot_config/nvim/lua/config/options.lua`, `tests/nvim-options.sh` |
| [E.2](../../03-editor/04-plugin-manager/prd.md) | lazy.nvim bootstrap | 2.5h | `home/dot_config/nvim/lua/config/lazy.lua`, `home/dot_config/nvim/lua/plugins/init.lua`, `home/dot_config/nvim/init.lua`, `home/dot_config/nvim/lazy-lock.json`, `tests/nvim-plugin-manager.sh` |
| [E.3](../../03-editor/02-keymaps/prd.md) | Core keymaps | 2h | `home/dot_config/nvim/lua/config/keymaps.lua`, `home/dot_config/nvim/init.lua`, `tests/nvim-keymaps.sh` |
| [E.4](../../03-editor/03-autocmds/prd.md) | Autocmds | 2h | `home/dot_config/nvim/lua/config/autocmds.lua`, `home/dot_config/nvim/init.lua`, `tests/nvim-autocmds.sh` |
| [E.5](../../03-editor/11-colorscheme/prd.md) | Colorscheme and cursor | 2.5h | `home/dot_config/nvim/lua/plugins/colorscheme.lua`, `home/dot_config/nvim/lazy-lock.json`, `tests/nvim-colorscheme.sh` |
| [E.6](../../03-editor/05-completion/prd.md) | blink.cmp completion | 2.5h | `home/dot_config/nvim/lua/plugins/completion.lua`, `home/dot_config/nvim/lazy-lock.json`, `tests/nvim-completion.sh` |
| [E.7](../../03-editor/09-lsp/prd.md) | mason and the native LSP setup | 3.5h | `home/dot_config/nvim/lua/plugins/lsp.lua`, `home/dot_config/nvim/lazy-lock.json`, `tests/nvim-lsp.sh` |
| [E.8](../../03-editor/10-treesitter/prd.md) | treesitter | 3h | `home/dot_config/nvim/lua/plugins/treesitter.lua`, `home/dot_config/nvim/lazy-lock.json`, `tests/nvim-treesitter.sh` |
| [E.9](../../03-editor/08-telescope/prd.md) | telescope | 2.5h | `home/dot_config/nvim/lua/plugins/telescope.lua`, `home/dot_config/nvim/lazy-lock.json`, `tests/nvim-telescope.sh` |
| [E.10](../../03-editor/06-explorer/prd.md) | oil as the explorer | 1.75h | `home/dot_config/nvim/lua/plugins/explorer.lua`, `home/dot_config/nvim/lazy-lock.json`, `tests/nvim-explorer.sh` |
| [E.11](../../03-editor/07-formatting/prd.md) | conform formatting | 1.75h | `home/dot_config/nvim/lua/plugins/conform.lua`, `home/dot_config/nvim/lazy-lock.json`, `install.sh`, `tests/nvim-formatting.sh` |
| [E.12](../../03-editor/12-small-plugins/prd.md) | gitsigns, which-key and autopairs | 4h | `home/dot_config/nvim/lua/plugins/gitsigns.lua`, `home/dot_config/nvim/lua/plugins/which-key.lua`, `home/dot_config/nvim/lua/plugins/autopairs.lua`, `home/dot_config/nvim/lazy-lock.json`, `tests/nvim-small-plugins.sh` |
| [E.13](../../03-editor/13-statusline/prd.md) | lualine statusline | 3h | `home/dot_config/nvim/lua/plugins/statusline.lua`, `home/dot_config/nvim/lazy-lock.json`, `tests/nvim-statusline.sh` |
| [E.14](../../03-editor/14-shift-select/prd.md) | Shift-to-select, with the tests that pin collapse-on-motion | 5h | `home/dot_config/nvim/lua/config/keymaps.lua`, `tests/nvim-shift-select.sh` (planned) |
| [E.15](../../03-editor/15-markdown-tables/prd.md) | Markdown table mode | 2h | `home/dot_config/nvim/lua/plugins/table-mode.lua`, `home/dot_config/nvim/lazy-lock.json`, `tests/nvim-markdown-tables.sh` |

This track's one file collision is **resolved**. Three plugin tasks used to
name a single shared plugin file, and the recommendation was to split it per
plugin rather than serialize them. The split happened: conform, table-mode,
gitsigns, which-key and autopairs each have their own file under
`home/dot_config/nvim/lua/plugins/`, and the shared file was never created at
all. The three cells kept the pre-split name for two days after the code had
stopped matching them — a note announcing an open fork that had already
closed, which is the class of rot C3 now catches.


## Track T — terminal

Re-specced from scratch by the terminal-respec node against the live
inventory. The ~230 lines of machinery the audit found uncovered — the tab
floor, grid centering, copy mode, the launchd PATH seeding — are rows here
rather than footnotes.

| ID | Task | Size | Files |
|---|---|---|---|
| [T.1](../../02-terminal/01-appearance/prd.md) | Appearance: font stack, palette reader, tab bar, baseline, theme toggle | 2.5h | `home/dot_config/wezterm/wezterm.lua`, `home/dot_config/nushell/help/terminal.nuon`, `tests/wezterm-appearance.sh` |
| [T.2](../../02-terminal/02-startup-layout/prd.md) | Tab and window model — the self-healing nine-tab floor | 4.75h | `home/dot_config/wezterm/wezterm.lua`, `tests/wezterm-startup-layout.sh` |
| [T.3](../../02-terminal/03-f5-jump-mode/prd.md) | F5 jump mode: the letter row, in split-creation order | 2.75h | `home/dot_config/wezterm/wezterm.lua`, `tests/wezterm-f5-tab-select.sh` |
| [T.4](../../02-terminal/04-copy-mode/prd.md) | Copy mode, the mouse bindings and bracketed paste | 2.5h | `home/dot_config/wezterm/wezterm.lua`, `home/dot_config/nushell/copymode.nu`, `tests/wezterm-copy-mode.sh` |
| [T.6](../../02-terminal/05-tab-content-state/prd.md) | Tab content-state coloring | 2.25h | `home/dot_config/wezterm/wezterm.lua`, `tests/wezterm-tab-content-state.sh` |
| [T.7](../../02-terminal/06-launchd-path/prd.md) | launchd PATH seeding, without which a GUI launch never reaches nushell | 2.5h | `home/dot_config/wezterm/wezterm.lua`, `tests/wezterm-launchd-path.sh` |
| [T.8](../../02-terminal/07-grid-centering/prd.md) | Dynamic grid centering | 2.5h | `home/dot_config/wezterm/wezterm.lua`, `tests/wezterm-grid-centering.sh`, `tests/wezterm-startup-layout.sh` |

Every row in this track writes one file, `wezterm.lua`, so the track is a
chain by construction — with one exception the checker reports: grid centering
hangs off appearance rather than off the rest of the chain, which put it in the
same wave as two tasks it does not order against. All three have landed, so the
race is history rather than a plan; the record is kept because the wave layout,
not the table, is where it would recur.


## Track C — capsule

Serial by nature: each step needs the previous one to test against.

| ID | Task | Size | Files |
|---|---|---|---|
| [C.1](../../01-capsule/02-dev-image/prd.md) | The dev image | 5h | `home/dot_config/capsule/Dockerfile`, `tests/dev-image.sh` |
| [C.2](../../01-capsule/01-container-lifecycle/prd.md) | The lifecycle CLI | 8h | `home/dot_config/nushell/capsule.nu`, `home/dot_config/nushell/config.nu`, `home/dot_config/wezterm/wezterm.lua`, `tests/capsule-lifecycle.sh` |
| [C.3](../../01-capsule/03-credential-propagation/prd.md) | Credential propagation | 7h | `home/dot_config/nushell/capsule.nu`, `home/dot_config/capsule/executable_setup-credentials.sh`, `tests/capsule-credentials.sh` |
| [C.4](../../01-capsule/04-recent-workspaces/prd.md) | The recent-workspace picker | 1.75h | `home/dot_config/nushell/capsule.nu`, `home/dot_config/wezterm/wezterm.lua`, `tests/capsule-recents.sh` |

The store question these rows used to record is **settled by the code**, and
the row that recorded it was itself stale — corrected 2026-08-23. The tool
landed as `home/dot_config/nushell/capsule.nu`, not as a `capsule-tool/`
directory, and its `_capsule_record` writes `~/.cache/capsule/recents.nuon`: a
cache path for a regenerable list, not a managed config file. Nothing in the
corrections sweep is left to reconcile there.


## Track H — help

| ID | Task | Size | Files |
|---|---|---|---|
| [H.1](../../06-help/01-content-model/prd.md) | The content model and its schema | 4h | `home/dot_config/nushell/help/`, `home/dot_config/nushell/help/README.md`, `tests/help-content-model.nu` |
| [H.1c](../../06-help/01-content-model/coverage/prd.md) | Coverage: every surface documented, and verify targets that resolve | 2.5h | `home/dot_config/nushell/help/`, `tests/help-content-model.nu` |
| [H.2](../../06-help/02-help-command/prd.md) | The `help` command and its delegation | 5h | `home/dot_config/nushell/help.nu`, `home/dot_config/nushell/config.nu`, `tests/shell-help.sh` |
| [H.3](../../06-help/03-browser/prd.md) | The fuzzy browser over the manual | 1h | `home/dot_config/television/cable/help.toml` (planned), `home/dot_config/nushell/help.nu`, `tests/shell-help.sh` |
| [H.4](../../06-help/04-drift-check/prd.md) | The drift check | 5h | `home/dot_config/nushell/help.nu`, `tests/shell-help.sh` |
| [H.5](../../06-help/05-agent-interface/prd.md) | Structured output and the agent wiring | 1h | `home/dot_config/nushell/help.nu`, `AGENTS.md`, `tests/shell-help.sh` |

**Manual entries are written by the task that creates the binding**, not by
the content model (epic invariant 4). The content model only builds the schema
and the initial files; every other task fills its own rows, which is why the
`help/*.nuon` topics are an append-only registry rather than one task's
footprint. The drift check therefore waits on every track it inspects — and it
is not the last node: the coverage node sits behind it and is the build's final
gate, because coverage can only be judged once the drift check has run over a
finished tree.


## Totals and the critical path

Computed from the nodes, not maintained by hand. `check-tables.py` fails when
these two figures disagree with the board, so they are as current as the last
green run.

| fact | value |
|---|---|
| tasks | 70 |
| total `est:` across task nodes | 213.8h |

Progress, measured 2026-08-24 and *not* gated — it moves whenever a node
closes, so read it as a dated snapshot and re-derive it from the board rather
than trusting this line: 62 of the 70 tasks are `done`, carrying 192.05h of
`est:` between them, and 11 of them have recorded an `actual:` — 6.0h in total
against 32.5h estimated.

The critical path is **computed on demand and never stored**:

```
python3 prds/00-delivery/work-breakdown/check-tables.py --critical-path
```

It ran 60.5h over 16 tasks on 2026-08-24. That is the number to distrust
first: the frozen chain this section carried until today claimed ≈49.5h for
the *same* sixteen nodes, because the chain was copied once and the `est:`
values under it moved afterwards. There is no fenced chain in this document any
more, and C7 rejects one if it comes back.

Two consequences are judgments rather than edges, so they stay in prose:

- **Television is the fulcrum.** It is the largest node on the path at 8.5h, it
  gates two shell tasks and the help browser, and it sits on the chain. Start
  it the moment its dependencies land, and consider splitting it (channels vs.
  the typed decoder) so two agents can work it.
- **Capsule is expensive but off-path.** The image, the lifecycle CLI and the
  credential work are ~5–8h each and block nothing outside their own track.
  Run that track in parallel from the start of the installer and it costs no
  wall-clock at all.

## Closed 2026-08-24 by the orchestrator

`done`, 15/15 boxes. `python3 prds/00-delivery/work-breakdown/check-tables.py`
→ **rc 0**, `70 task(s), 213.8h of est:, 0 red, 21 reported`, re-run by the
orchestrator on this transition. The document now has an executable proof
instead of a reader, and the checker was run **RED first** — `rc=1, 190 red`
against the old body, with all 14 missing rows named — so its green means
something.

**`actual: 20m` against `est: 2h`.** Clean run: one dispatch, every box proven,
no BLOCKED, no `## Failure`. That is 6x under a calibrated estimate, against
last night's gate-repair node which came in 25% **over** one. Two pairs, two
directions — the honest reading is that the 4.2x board ratio describes document
work and gate work differently, and neither should be estimated from the other.

**The worker corrected the analyst's numbers, and the numbers were the point:**
the `est:` total is **213.8h, not 214.8h** (re-derived twice, by `bc` and
`awk`, both `213.80` over 70 rows; the analyst's figure would have made the
checker red on its own summary), 62 tasks are `done` rather than 60, and the
calibration re-measures as 37 pairs at 62.75h against 15.08h — **4.2x**, with
three pairs *over* estimate.

**Two forced design deviations, both accepted:**

1. A task table is recognised by its `ID | Task` header **prefix**, not by
   header equality — Track P's extra `Spec` column made all five P rows
   invisible, so they reported as missing rows. The extra column is now its own
   violation line rather than a blind spot.
2. **C5 is split into a gating tier and a reported tier**, on the
   `tree-links.py` Tier A/B precedent. This deviates from the spec's single
   exit code and it was forced: both live collisions are defects in `needs:` or
   in `gates/waves.tsv`, **files this node may not write**, so gating on them
   would make the document permanently uncloseable. A pair with at least one
   `done` task prints `C5 historical:`; a pair where both are unlanded is red,
   which is what the acceptance box was actually about. 21 historical
   collisions are reported today, and that number is the honest measure of how
   much of this board's parallelism was luck.

**Two `(planned)` markers came off mid-session** because the quicklist lane
landed `recents.nu` and `tests/shell-quicklist.sh` while this worker was
writing, and C3 caught the stale markers. `quicklist.nu` and
`cable/quicklist.toml` are still `(planned)`; that lane landing will turn those
two red until the row is updated — which is the checker working, not a defect.

**Owed to the orchestrator, reported and not touched:** `gates/waves.tsv`'s
wave 6 row (`H.4 H.5 H.1c`) has an **empty gates cell**, and that file's own
header says an empty cell is red once the row's tasks are all `done`. They are
not done, so it is correct today and becomes wrong the moment `06-help`
finishes. Recorded here so it is not discovered by a red at the end.
