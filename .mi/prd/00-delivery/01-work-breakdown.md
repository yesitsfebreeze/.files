# Feature: Work breakdown

Parent: [Delivery epic](00-epic.md) · net-new

## Summary

Every task in the build, with its size, its files, and its *real*
dependencies. Sizes are agent-hours (one focused agent, including running the
acceptance criteria): **S** ≈ 1, **M** ≈ 2–3, **L** ≈ 4–6, **XL** ≈ 8+.

Dependency rules used throughout: a task depends on another only if it cannot
be *written and verified* without it. "Would be nicer afterwards" is not a
dependency — that ordering belongs to the wave layout in
[02-parallelization](02-parallelization.md).

## Wave 0 — corrections and missing inventories

These come first because they change what the later tasks build. Detail in
[04-corrections-backlog](04-corrections-backlog.md).

The 2026-08-20 audit made this wave much larger than first estimated: the
terminal epic must be rebuilt rather than adjusted, and three scope forks need
a human answer. Full detail in
[04-corrections-backlog](04-corrections-backlog.md).

| ID | Task | Size | Files | Depends on |
|---|---|---|---|---|
| W0.1 | Inventory live `~/.config/wezterm` + burrito → `docs/capabilities-terminal.md` | L | new doc | — |
| W0.2 | **Re-spec `02-terminal/*` from scratch** against W0.1 (S1: nearly every current requirement is wrong) | L | 02-terminal/ | W0.1, D.1 |
| W0.3 | Rewrite `05-platform` as the provisioning epic | M | 05-platform/ | — |
| W0.4 | Apply S2 corrections across the tree | M | various | — |
| W0.5 | Re-base `01-capsule` on "build once", fix binding collisions | M | 01-capsule/ | D.1 |
| W0.6 | Record live-config bugs so the rebuild fixes rather than copies them | S | backlog | — |
| D.1 | **Human decisions**: burrito vs nine-tab floor · does tinty stay · fzf exception or replace | — | backlog | *blocked on the human* |

**D.1 is the real Wave 0 gate.** W0.2 and W0.5 cannot be finished without it:
the first needs to know which layer owns tabs and panes, the second needs free
keybindings. Everything in Tracks P, S, E and H proceeds regardless.

## Track P — provisioning (the deploy mechanism)

Nothing reaches a machine without this, so it heads the critical path.

| ID | Task | Size | Files | Depends on | Spec |
|---|---|---|---|---|---|
| P.1 | Repo skeleton: chezmoi source layout, `home/`, justfile | M | repo root | W0.3 | [`05-platform/01`](../05-platform/01-deploy-mechanism.md) |
| P.2 | `packages.yaml` + `run_onchange` installer | L | `.chezmoidata/`, `run_onchange_*` | P.1 | [`05-platform/02`](../05-platform/02-package-provisioning.md) |
| P.3 | `run_once` homebrew bootstrap | S | `run_once_before_*` | P.1 | [`05-platform/02`](../05-platform/02-package-provisioning.md) |
| P.4 | `run_after` shell-init generator (starship/zoxide/tv) | M | `run_after_*` | P.2 | [`05-platform/03`](../05-platform/03-shell-init-generation.md) |
| P.5 | Managed config surface + `dot_gitconfig.tmpl` | S | `home/dot_config/` | P.1 | [`05-platform/01`](../05-platform/01-deploy-mechanism.md) |

## Track S — nushell

Mostly serial: almost every task edits `config.nu` (execution invariant 2).

| ID | Task | Size | Files | Depends on |
|---|---|---|---|---|
| S.1 | [`04-shell/01`](../04-shell/01-core-config.md) core config, mkcd funnel, start dir | L | `env.nu`, `config.nu`, `dirstack.nu` | P.4 |
| S.2 | [`04-shell/02`](../04-shell/02-aliases-utilities.md) aliases + `cf` + pass completion | S | `config.nu`, `pass.nu` | S.1 |
| S.3 | [`04-shell/06`](../04-shell/06-listing.md) decorated ls + auto-list | M | `config.nu` | S.1 |
| S.4 | [`04-shell/03`](../04-shell/03-zoxide.md) zoxide wrappers + bare-word fallback | L | `config.nu` | S.1, P.4 |
| S.5 | [`04-shell/04`](../04-shell/04-television.md) finder + cable channels | XL | `finder.nu`, `~/.config/television/` | S.1, P.4 |
| S.6 | [`04-shell/05`](../04-shell/05-history.md) directory-scoped history | M | `config.nu` | S.5 |
| S.7 | [`04-shell/07`](../04-shell/07-quicklist.md) quicklist recents | M | `quicklist.nu`, `finder.nu` | S.4, S.5 |
| S.8 | [`04-shell/08`](../04-shell/08-claude-launchers.md) `cc`/`cr` | S | `config.nu` | S.1 |

S.5 is the single largest task in the build and gates S.6/S.7 — it belongs on
the critical path and should start as early as its dependencies allow.

## Track E — Neovim

The most parallel track in the build: after the base, every task is a
separate file under `lua/plugins/`.

| ID | Task | Size | Files | Depends on |
|---|---|---|---|---|
| E.1 | [`03-editor/01`](../03-editor/01-options.md) options + `init.lua` | M | `init.lua`, `lua/config/options.lua` | — |
| E.2 | [`03-editor/04`](../03-editor/04-plugin-manager.md) lazy.nvim bootstrap | M | `lua/config/lazy.lua` | E.1 |
| E.3 | [`03-editor/02`](../03-editor/02-keymaps.md) core keymaps | S | `lua/config/keymaps.lua` | E.1 |
| E.4 | [`03-editor/03`](../03-editor/03-autocmds.md) autocmds | S | `lua/config/autocmds.lua` | E.1 |
| E.5 | [`03-editor/11`](../03-editor/11-colorscheme.md) colorscheme + cursor | M | `plugins/colorscheme.lua` | E.2 |
| E.6 | [`03-editor/05`](../03-editor/05-completion.md) blink.cmp | M | `plugins/completion.lua` | E.2 |
| E.7 | [`03-editor/09`](../03-editor/09-lsp.md) mason + native LSP | L | `plugins/lsp.lua` | E.6 |
| E.8 | [`03-editor/10`](../03-editor/10-treesitter.md) treesitter | M | `plugins/treesitter.lua` | E.2 |
| E.9 | [`03-editor/08`](../03-editor/08-telescope.md) telescope | M | `plugins/telescope.lua` | E.2 |
| E.10 | [`03-editor/06`](../03-editor/06-explorer.md) oil | S | `plugins/explorer.lua` | E.2 |
| E.11 | [`03-editor/07`](../03-editor/07-formatting.md) conform | S | `plugins/editor.lua` | E.2 |
| E.12 | [`03-editor/12`](../03-editor/12-small-plugins.md) gitsigns/which-key/pairs | S | `plugins/editor.lua` | E.2 |
| E.13 | [`03-editor/13`](../03-editor/13-statusline.md) lualine | M | `plugins/statusline.lua` | E.5 |
| E.14 | [`03-editor/14`](../03-editor/14-shift-select.md) shift-to-select + tests | L | `lua/config/keymaps.lua`, tests | E.3 |
| E.15 | [`03-editor/15`](../03-editor/15-markdown-tables.md) table mode | S | `plugins/editor.lua` | E.2, E.11 |

Note the one file collision in this track: E.11, E.12, and E.15 all write
`plugins/editor.lua`. Either serialize those three or split the file per
plugin; splitting is cheaper and is the recommendation.

## Track T — terminal

| ID | Task | Size | Files | Depends on |
|---|---|---|---|---|
Sizes here are provisional: W0.2 re-specs this track, and the audit found ~230
lines of uncovered live machinery (tab floor, grid centering, copy mode) that
will add tasks.

| ID | Task | Size | Files | Depends on |
|---|---|---|---|---|
| T.1 | Appearance + palette (per re-spec) | M | `wezterm.lua` | W0.2 |
| T.2 | Tab/window model — nine-tab floor **or** burrito, per D.1 | L | `wezterm.lua` | W0.2, D.1 |
| T.3 | F5 jump mode (letters `asdfghjkl`, split-creation order) | M | `wezterm.lua` | W0.2 |
| T.4 | Grid centering, copy mode, mouse + paste bindings | M | `wezterm.lua` | W0.2 |
| T.5 | burrito integration (scope set by D.1) | ? | TBD | D.1 |

## Track C — capsule

Serial by nature: each step needs the previous one to test against.

| ID | Task | Size | Files | Depends on |
|---|---|---|---|---|
| C.1 | [`01-capsule/02`](../01-capsule/02-dev-image.md) dev image | L | `Dockerfile` | P.2 (docker installed) |
| C.2 | [`01-capsule/01`](../01-capsule/01-container-lifecycle.md) lifecycle CLI | XL | capsule tool | C.1 |
| C.3 | [`01-capsule/03`](../01-capsule/03-credential-propagation.md) credentials | L | capsule tool, setup script | C.2 |
| C.4 | [`01-capsule/04`](../01-capsule/04-recent-workspaces.md) recents picker | M | `conf/`, capsule tool | C.2, T.1 |

## Track H — help

| ID | Task | Size | Files | Depends on |
|---|---|---|---|---|
| H.1 | [`06-help/01`](../06-help/01-content-model.md) content model + schema | M | `help/*.nuon` | S.1 |
| H.2 | [`06-help/02`](../06-help/02-help-command.md) `help` command + delegation | L | `help.nu` | H.1 |
| H.3 | [`06-help/03`](../06-help/03-browser.md) tv browser | S | cable channel | H.2, S.5 |
| H.4 | [`06-help/04`](../06-help/04-drift-check.md) drift check | L | `help.nu` | H.2, and every track it inspects |
| H.5 | [`06-help/05`](../06-help/05-agent-interface.md) json/md + AGENTS.md wiring | S | `help.nu`, `AGENTS.md` | H.2 |

**H.1 entries are written by the task that creates the binding**, not by H.1
itself (epic invariant 4). H.1 only builds the schema and the initial files;
every other task fills its own rows. H.4 therefore runs last and is the
build's final gate.

## Totals and the critical path

Roughly: 7 corrections + 5 provisioning + 8 shell + 15 editor + 5 terminal +
4 capsule + 5 help = **49 tasks**, ≈ 130–145 agent-hours if every task were
done once by one agent with no overlap.

The critical path is:

```
W0.3 → P.1 → P.2 → P.4 → S.1 → S.5 → S.7 → H.4
```

≈ 26 agent-hours. Note what this is *not*: H.2 (the `help` command) depends on
H.1 only, so it hangs off S.1 in parallel rather than sitting behind S.7 — but
H.4 (drift check) must wait for every track it inspects, which is what pulls
the tail of the shell track onto the path.

Everything else parallelizes against it, which is what
[02-parallelization](02-parallelization.md) does. Two consequences worth
acting on:

- **S.5 (television) is the fulcrum.** It is XL, it gates two shell tasks and
  the help browser, and it sits on the path. Start it the moment S.1 lands,
  and consider splitting it (channels vs. the typed decoder) so two agents can
  work it.
- **Capsule is expensive but off-path.** C.1–C.3 are ~L/XL but block nothing
  except each other. Run that track in parallel from the start of P.2 and it
  costs no wall-clock at all.

## Acceptance criteria

- Every feature PRD outside `00-delivery` appears exactly once as a task
  (the delivery PRDs are the plan, not planned work).
- Every task names its files, and no two concurrent tasks in the same wave
  name the same file.
- Every task's dependency edges exist in the other tasks' rows — no invented
  edges (the first draft had one: `S.7 → H.2`).
- The critical path is recomputed whenever a task's dependencies change.
