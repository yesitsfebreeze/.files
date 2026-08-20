---
state: claimed
mode: afk
deps: []
claim: cc-1787256992
verify: "nu tests/help-content-model.nu"
---

# Content model

Parent: [Help epic](../prd.md) · C 4 · U 9 · net-new

Purpose: The manual's single data source: one structured file per surface,
holding every entry a reader needs plus the prose that introspection can't
produce. Every renderer ([02](../02-help-command/prd.md), [03](../03-browser/prd.md),
[05](../05-agent-interface/prd.md)) reads this and nothing else.

## Requirements
- [x] **R1** — **Format.** NUON or YAML under version control (NUON preferred
      — nushell opens it natively with no parser). One file per surface:
      `shell.nuon`, `nvim.nuon`, `terminal.nuon`, `capsule.nuon`.
- [x] **R2** — **Entry schema.** Every entry carries:
  - [x] `key` or `cmd` — the binding (`ctrl-r`, `F5 <digit>`) or invocation
        (`z <query>`)
  - [x] `title` — one line: what it does
  - [x] `use` — how to use it: the actual gesture, in order, including what to
        press next and what comes back
  - [x] `topic` — the section it belongs to (see below)
  - [x] `mode` — where it applies: `shell`, `nvim:normal`, `nvim:visual`,
        `nvim:insert`, `terminal`, `container`
  - [x] `also` — optional related entries, by key/cmd
  - [x] `why` — optional; the non-obvious reason it works this way. This is
        where the hard-won constraints live (e.g. "`Alt-R`, not
        `Ctrl-Shift-R`: shift is indistinguishable on control+letter without
        kitty protocol").
  - [x] `verify` — how the drift check confirms it exists
        ([04](../04-drift-check/prd.md)): a nushell keybinding `name`, an nvim `lhs`
        + mode, a wezterm key spec, or `prose` for entries with no live
        counterpart.
- [x] **R3** — **Topics.** The manual's spine, ordered by how often it's
      needed: `navigate` · `find` · `history` · `edit` · `git` · `containers`
      · `terminal` · `agents` · `config`.
- [x] **R4** — **Coverage — shell.** Keybindings `Ctrl-R` / `Alt-R` /
      `Up`/`Down` / `Shift+Up`/`Down`
      ([04-shell/05](../../04-shell/05-history/prd.md)), `Ctrl-Space` + `F1` /
      `Ctrl-T` / `Ctrl-Q` ([04-shell/04](../../04-shell/04-television/prd.md),
      [07](../../04-shell/07-quicklist/prd.md)), `Esc`; navigation `z` / `zi` / `zz`
      / `zl` / `zc` / `cdi` / bare-word fallback / `cd` auto-create
      ([03](../../04-shell/03-zoxide/prd.md), [01](../../04-shell/01-core-config/prd.md));
      (note, R5: [14-shift-select](../../03-editor/14-shift-select/prd.md)
      has an unresolved fork — port-with-tests vs. downgrade to plain
      Shift+arrow — gated on `deps:
      .mi/prd/00-delivery/decisions/shift-select-scope` and still `state:
      open`. Confirmed by reading that node in full: its "Simplification
      option" section says "Record the decision here if taken," meaning no
      decision is recorded yet. Content-model's shift-select entry can only
      be written accurately once that fork resolves; sequence R5's
      shift-select coverage after 14 closes, or write it provisionally and
      expect rework. Had the fork already been resolved, 14 would show
      `state: done` with the choice recorded and this note would not
      apply.)
      aliases and utilities ([02](../../04-shell/02-aliases-utilities/prd.md)); `cc`
      / `cr` ([08](../../04-shell/08-claude-launchers/prd.md)); `ls` variants and
      `-D` ([06](../../04-shell/06-listing/prd.md)).
- [~] **R5** — **Coverage — Neovim.** Leader groups and their maps,
      window/buffer/move maps ([03-editor/02](../../03-editor/02-keymaps/prd.md)),
      telescope incl. the mark→quickfix flow
      ([08](../../03-editor/08-telescope/prd.md)), LSP maps — **both** our aliases
      and the Neovim 0.11 defaults we deliberately don't re-map
      ([09](../../03-editor/09-lsp/prd.md)), completion keys
      ([05](../../03-editor/05-completion/prd.md)), oil
      ([06](../../03-editor/06-explorer/prd.md)), formatting
      ([07](../../03-editor/07-formatting/prd.md)), shift-select semantics
      ([14](../../03-editor/14-shift-select/prd.md)), table mode
      ([15](../../03-editor/15-markdown-tables/prd.md)).
- [~] **R6** — **Coverage — terminal.** F5 jump mode
      ([02-terminal/03](../../02-terminal/03-f5-jump-mode/prd.md)), tab/window/quit
      keys ([02](../../02-terminal/02-startup-layout/prd.md)), and the capsule
      bindings ([01-capsule](../../01-capsule/prd.md)).
      (note: CLAUDE.md's Known gaps flags `02-terminal` as "invalid as
      written" — wrong font/palette, non-existent `Cmd+N` and
      `gui-attached`, wrong F5 letter set, pending a from-scratch respec at
      tasks W0.1/W0.2. Confirmed directly: `grep -n 'Cmd+N\|gui-attached'
      .mi/prd/02-terminal/02-startup-layout/prd.md` still matches both
      terms today. R6's links resolve and the schema/format work in this
      node is unaffected, but the terminal coverage *content* R6 asks for
      will need rewriting once the respec lands — don't treat
      `02-terminal`'s current PRDs as stable ground truth for entry text in
      the meantime. Had the respec already landed, those terms would be
      absent from `02-startup-layout/prd.md` and this note would not
      apply.)
- [~] **R7** — **Coverage — capsule.** The CLI surface: mount, `--rebuild`,
      list, clean, and the recents picker.
- [x] **R8** — **Concept entries.** A small number of prose entries (`verify:
      prose`) for the mental models a list of keys can't convey: the `mkcd`
      funnel and why every navigation route updates start dir and recents; why
      a bare word jumps; what a tv channel is and how to add one; how
      credentials reach a capsule.
- [x] **R9** — **Writing rules.** `title` is one line, imperative, no trailing
      period. `use` describes the real gesture ("press `F5`, then a digit
      1–9"), never restates the key. `why` only where the reason is
      non-obvious — most entries won't have one.

## Acceptance
- [ ] Every keybinding defined in the shell, Neovim, and terminal configs has
      an entry, confirmed by [04-drift-check](../04-drift-check/prd.md).
- [x] Opening a content file directly is readable as plain text — the data is
      the manual, not a serialization artifact.
- [~] No description text exists anywhere else in the repo; renderers contain
      layout only.

## Evidence

Reconciled 2026-08-20. Session `cc-1787250953` landed `9ea3b1b` (6 content
files + `tests/help-content-model.nu`, 1488 lines) but died before marking any
box; the claim was cleared and the work verified rather than re-run.

`verify:` now names the gate that exists. Ran `nu tests/help-content-model.nu`
→ `81 entries across 4 files, 9 topics, 10 prose-only … ok`, exit 0. It is
strict (an unknown field is an error), so a malformed entry fails it rather
than passing quietly.

- **R1, R2 (all sub-boxes), R3, R9** — `[x]`. The gate enforces each one
  directly: four `.nuon` files; `REQUIRED`/`OPTIONAL` field sets with exactly
  one of `key`/`cmd`; `mode` from the six; `topic` from the nine; the typed
  `verify` kinds; and the writing rules. Removing a required field or an
  unlisted topic makes it exit non-zero.
- **R4** — `[x]`, and checked past the gate: every `kind: keybinding` name in
  `shell.nuon` (`tv_remote`, `tv_remote_f1`, `finder_pick`, `quicklist`,
  `hist_picker_local`, `hist_picker_global`, `hist_up_local`,
  `hist_down_local`, `hist_up_global`, `hist_down_global`, `esc_clear`) is one
  of the 11 keybinding names actually defined in `~/.config/nushell/*.nu` —
  all 11 live names covered, none invented.
- **R5** — `[~]`. All 54 `nvim-map` `lhs` values resolve in `~/.config/nvim/`
  (0 missing). Stubbed only on the shift-select fork: the maps exist, but what
  the entries *say* about them depends on
  [`shift-select-scope`](../../00-delivery/decisions/shift-select-scope/prd.md),
  still `open`.
- **R6** — `[~]`, and the stub is load-bearing. Checked every `wezterm-key`
  against `~/.config/wezterm/wezterm.lua`: `F5`, `Escape`, `Ctrl+Shift+Q` and
  the whole F5 table resolve (digits 1–9 and letters `asdfghjkl` are generated
  in a loop at `wezterm.lua:706,957`, so they are real). But
  **`Ctrl+Shift+D`, `Ctrl+Shift+S` and `Ctrl+Shift+T` do not exist in the live
  config at all** — 0 hits each — and `Ctrl+Shift+B` exists only as the
  wallpaper pipeline that
  [`capabilities-terminal.md`](../../../docs/capabilities-terminal.md) rates
  `DO NOT PORT`. They were transcribed from the known-invalid `02-terminal`
  PRDs. `w0-2-terminal-respec` must delete or correct those four entries.
- **R7** — `[~]`. `capsule.nuon` documents a CLI that does not exist yet;
  `01-capsule` is entirely open, so there is nothing to verify it against.
- **R8** — `[x]`. The gate asserts all four concepts (`mkcd`, `<word>`,
  `tv channel`, `credentials in a capsule`) exist and are `verify: prose`.
- **A2** — `[x]`. `open shell.nuon` is a commented, readable table; the header
  comment names the four behaviours documented as specified rather than as
  currently implemented.
- **A3** — `[~]`. Holds today (`README.md` carries schema, not entry text),
  but the renderers it constrains ([02](../02-help-command/prd.md),
  [03](../03-browser/prd.md), [05](../05-agent-interface/prd.md)) do not exist
  yet, so it cannot be met against the real thing.
- **A1** — still `[ ]`. It requires
  [`04-drift-check`](../04-drift-check/prd.md), which is open; the gate's own
  header says it cannot check whether a `verify` target resolves against a
  live shell, editor or terminal, and no configuration is deployed.

**Not done: owes 1 open + 4 stubbed.** Ready again once the terminal respec,
the shift-select fork, the capsule CLI and the drift check land.

## Out of scope
- Anything this node's Requirements do not name. The epic ([`../prd.md`](../prd.md)) owns the shared invariants.
