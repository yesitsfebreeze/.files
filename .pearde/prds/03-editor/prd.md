---
state: done
claim: 
priority: 0
est: 0h
kind: epic
mode: afk
needs:
verify: "sh -c 'n=$(grep -L \"^state: done\" prds/03-editor/*/prd.md | wc -l | tr -d \" \"); echo \"children not done: $n\"; test \"$n\" -eq 0'"
---

# Epic: Neovim

Purpose: Two Neovim configs exist. `capabilities.md` describes an older
mini.nvim one (self-bootstrapping `mini.deps`, vague theme, startify, noice);
the live config in `~/.config/nvim` is a newer, different setup — lazy.nvim +
telescope + blink.cmp + Neovim's native LSP API, 683 lines across 14 files.
Only the live one gets ported; the mini.nvim entries are superseded.

Goal: A minimal Neovim base that keeps the config's real value — the options
baseline, the modern plugin stack (LSP/completion/treesitter/telescope), and
the editor-style selection behavior — and sheds eye candy and dead lineage.

## Requirements

**Architecture invariants**

**I1** — **Load order is load-bearing.** `options` → `keymaps` →
`autocmds` → `lazy`. The leader key must be set before any plugin spec
is evaluated.

**I2** — **Lean on Neovim's built-ins.** `gc` commenting, and the
default LSP and diagnostic maps, ship in core at or below the version
floor (see I6). Add only what's missing — never a plugin that
duplicates core.

**I3** — **One plugin per concern.** blink.cmp replaces the whole
nvim-cmp stack; telescope replaces finder.nvim; conform owns formatting.

**I4** — **Palette is derived, never duplicated.** Everything that needs
colors reads tinted-nvim's live palette and re-derives on `ColorScheme`.

**I5** — **Plugin-specific keymaps live in their spec** (`keys = …`) so
they lazy-load; only general maps live in `keymaps.lua`.

**I6** — **Version floor, and version target.** This epic references
the Neovim version floor recorded in
[`packages-installer`](../05-platform/02-package-provisioning/packages-installer/prd.md)
req 6 rather than restating a version number.

The floor is what the config may not require below. The **target** —
the binary every acceptance check in this epic is executed against —
is the live 0.12.4, so a 0.12 deprecation binds even where the floor
is lower: `vim.highlight.*` is deprecated in favour of `vim.hl.*`, and
[`03-autocmds`](03-autocmds/prd.md) R1 is written to the new name
(correction M-3).

**I7** — **Every autocmd lives in a cleared augroup.** Every
`nvim_create_autocmd` call in the config passes
`group = nvim_create_augroup("<name>", { clear = true })` — including
the ones declared inside a plugin spec's `config`/`init` function,
which is where this rule is actually broken. Without it, re-sourcing
the config or re-running a plugin's `config` registers a second copy
of the callback and it fires twice per event; `clear = true` is what
makes the registration idempotent. **Live bug L-8, do not reproduce.**
Three sites break it live (swept 2026-08-21):
`lua/plugins/treesitter.lua:31` (`FileType`),
`lua/config/keymaps.lua:58` (`ModeChanged`), and
`lua/plugins/editor.lua:80` (`FileType`, vim-table-mode — a third site
the backlog's L-8 row does not list). All four autocmds in
`lua/config/autocmds.lua` *are* grouped, and so are the ones in
`statusline.lua`, `colorscheme.lua` and `lsp.lua`, so a grep for
`augroup` finds seven hits and passes falsely — the check has to be
per call site, not per file. Binds
[`03-autocmds`](03-autocmds/prd.md),
[`09-lsp`](09-lsp/prd.md),
[`10-treesitter`](10-treesitter/prd.md),
[`11-colorscheme`](11-colorscheme/prd.md),
[`13-statusline`](13-statusline/prd.md),
[`14-shift-select`](14-shift-select/prd.md) and
[`15-markdown-tables`](15-markdown-tables/prd.md) — every node that
registers an autocmd.

**I8** — **One file per plugin under `lua/plugins/`.** Each plugin
spec lives in a file named for the **concern it delivers**, not the
plugin itself — a concern name survives replacing the plugin behind
it. There is no catch-all.
The live config has one — `lua/plugins/editor.lua`, holding five
unrelated specs (gitsigns, which-key, nvim-autopairs, conform,
vim-table-mode) — and three nodes of this epic write to it:
[`07-formatting`](07-formatting/prd.md) (conform),
[`12-small-plugins`](12-small-plugins/prd.md) (the first three) and
[`15-markdown-tables`](15-markdown-tables/prd.md) (vim-table-mode).
Until this invariant existed the filename appeared nowhere in this
epic, so nothing warned the three that they collide, and the
resolution lived only in
[`parallelization`](../00-delivery/parallelization/prd.md) — a
document none of them links. Splitting is what makes the three
buildable in parallel instead of serialised, and it is why each node
below names its own target files.

## Acceptance
- [x] Every child of this epic is `state: done`. This is the epic's own
      proof and it is the only claim an epic can make on its own behalf —
      the substance is proved by each child's `verify:`, run at that child's
      own transition.

      `verify:` above, run 2026-08-28 → `children not done: 0`, `EXIT=0`.
      **Proved by its own red**, per `G.1`: flipping `15-markdown-tables`
      to `state: open` gives `children not done: 1`, `EXIT=1`; restoring it
      returns `EXIT=0`. All 15 children counted.

## Out of scope
- The mini.nvim plugin set and its `mini.deps` bootstrap (`DO NOT PORT`).
- Insert-mode-first modal inversion and its `<F24>` Karabiner dependency
  (`DO NOT PORT` — Karabiner is out of scope entirely).
- Smear cursor (`DEFER` — pure eye candy).

## Note on children

The `## Children` table this epic used to carry is gone on purpose. Node
membership is by existence — a child is a subdirectory holding its own
`prd.md` — so a maintained list beside it is a second copy that goes stale
silently (laws.md law 4: "membership by existence, not by a maintained
list"). `find . -name prd.md` is the index.

## Closed 2026-08-28 — what `done` rests on, and the correction that got it there

Transitioned by the orchestrator under
[`epic-invariants-prose`](../00-delivery/finish-line/epic-invariants-prose/prd.md)
R4.

**This epic was first closed with an empty `## Acceptance` and `verify: ""`,
and that was an overclaim.** A skeptic put the case plainly: the board's own
contract says `done` requires the verify commands actually run with output,
`verify: ""` means there is no command, and "all acceptance boxes closed" over
an empty set is vacuously true — so the epic closed because it was never
specified, not because it was finished. The tell was that the epics holding
real acceptance boxes were held to them, and the two that closed were exactly
the two with nothing to bite.

The fix is the acceptance box above, not an argument: one claim an epic can
honestly make, a command that produces output, and a demonstrated red. `done`
here now means what the contract says it means.

What it still does **not** mean: that this file was checked against the live
config. The substance lives in the children, each proved at its own
transition, and that is the correct place for it —
[`done-node-proof-gate`](../00-delivery/corrections/done-node-proof-gate/prd.md)
is the node that will assert every `done` node's `verify:` actually exits 0,
and this epic now passes that test rather than adding to its list.
