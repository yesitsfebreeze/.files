---
state: open
priority: 2
est: 2.5h
task: H.1c
mode: afk
needs:
  - 06-help/01-content-model
  - 00-delivery/corrections/w0-2-terminal-respec
  - 06-help/04-drift-check
  - 00-delivery/decisions/shift-select-scope
verify: ""
---

# Coverage

Parent: [Content model](../prd.md) · C 4 · U 9 · net-new

Purpose: Split out of [`01-content-model`](../prd.md) on 2026-08-20, which
held two contracts and so could never close. The parent owns the **schema and
format** — what an entry is, and that the files parse and validate. This node
owns the other half: that the manual actually **covers every surface**, and
that each entry's `verify` target resolves against a real binding rather than
merely being well-typed.

Everything here is blocked by construction. The surfaces being documented do
not exist yet, so a coverage claim can only be written against a spec, never
proved. That is what the parent's seven `[~]` marks were recording, one node
too high up to be scheduled honestly.

## Requirements
- [ ] **R1** — **Coverage — shell.** Keybindings `Ctrl-R` / `Alt-R` /
      `Up`/`Down` / `Shift+Up`/`Down`, `Ctrl-Space` + `F1` / `Ctrl-T` /
      `Ctrl-Q`, `Esc`; navigation `z` / `zi` / `zz` / `zl` / `zc` / `cdi` /
      bare-word fallback / `cd` auto-create; aliases and utilities; `cc` /
      `cr`; `ls` variants and `-D`.
      (Was the parent's R4. Its keybinding names were checked against the 11
      defined in the live `~/.config/nushell/*.nu` and all 11 are covered —
      but the shell being *built* is `04-shell`, which is entirely open, so
      this closes against that, not against the live config.)
- [ ] **R2** — **Coverage — Neovim.** Leader groups and their maps,
      window/buffer/move maps, telescope incl. the mark→quickfix flow, LSP
      maps — **both** our aliases and the Neovim 0.11 defaults we deliberately
      do not re-map — completion keys, oil, formatting, shift-select
      semantics, table mode.
      (Was the parent's R5. All 54 `nvim-map` `lhs` values resolve in the live
      `~/.config/nvim/`. The open fork is what the shift-select entries *say*:
      see [`shift-select-scope`](../../../00-delivery/decisions/shift-select-scope/prd.md).)
- [ ] **R3** — **Coverage — terminal.** F5 jump mode, tab/window/quit keys,
      and the capsule bindings.
      (Was the parent's R6, and the one with a proven defect: entries for
      `Ctrl+Shift+D` and `Ctrl+Shift+S` were transcribed from the
      known-invalid `02-terminal` PRDs and match nothing in the live config.
      `Ctrl+Shift+T` resolves only because `CTRL|SHIFT`+`T` is WezTerm's own
      `SpawnTab` default, so its drift check passes whether or not a capsule
      binding is ever written — a named blind spot for
      [`04-drift-check`](../../04-drift-check/prd.md). Gated on
      [`w0-2-terminal-respec`](../../../00-delivery/corrections/w0-2-terminal-respec/prd.md).)
- [ ] **R4** — **Coverage — capsule.** The CLI surface: mount, `--rebuild`,
      list, clean, and the recents picker.
      (Was the parent's R7. `capsule` is absent from `PATH`; all four entries
      carry live-handle `verify` kinds where the schema says an entry with no
      live counterpart takes `prose`. Either the CLI lands or they become
      prose — they cannot stay as they are.)
- [ ] **R5** — **`verify` targets resolve.** Every entry's `verify` target
      names something that actually exists on the live surface — a real
      nushell keybinding `name`, a real nvim `lhs`+mode, a real wezterm key
      spec — not merely a well-typed record. The parent's schema gate proves
      the field is present and typed; only
      [`04-drift-check`](../../04-drift-check/prd.md) can prove it resolves.
      (Split out of the parent's R2 `verify` sub-box, which sat `[x]` for a
      full cycle while carrying 11 targets that resolved to nothing. Proof the
      distinction is real: reverting the wezterm-key spelling fix, or renaming
      `table: "copy_mode"` to `table: "no_such_table"`, both still exit 0
      under the schema gate.)

## Acceptance
- [ ] Every keybinding defined in the shell, Neovim, and terminal configs has
      an entry, confirmed by [`04-drift-check`](../../04-drift-check/prd.md).
- [ ] No description text exists anywhere else in the repo; renderers contain
      layout only. (Was the parent's A3. Holds today, but the renderers it
      constrains — [02](../../02-help-command/prd.md),
      [03](../../03-browser/prd.md), [05](../../05-agent-interface/prd.md) —
      do not exist yet, so it cannot be met against the real thing.)

## Out of scope
- The schema, the file format, the topic spine, the concept entries and the
  writing rules. Those are the parent's, and they close on their own gate.

## Filed findings to absorb when this node specs

- **Ex-commands have no verify kind** (E.2's analyst, 2026-08-22): `:Lazy`
  is a user-facing command with no `nvim.nuon` entry, and none of the
  schema's six verify kinds can resolve a Neovim ex-command (`nvim-map` is
  maps, `command` is nushell scope). Either R2 grows an ex-command surface
  with a resolvable kind, or the exclusion is recorded on the schema —
  silently uncovered is the one wrong outcome.

## Note on `deps`

`04-drift-check` is listed as a dependency even though it depends on the
parent. That resolves rather than deadlocking: a node's `deps` need the target
**resolved** (§1: `done`, owing nothing), while only the *parent's own*
readiness needs its children **covered**. The parent closes on its schema
boxes, `04-drift-check` then becomes ready, and this node follows. It would
deadlock only if the parent were reopened — if that happens, drop this edge
and close R5 against a hand-run resolution instead.

## Added 2026-08-24 by the orchestrator — the browser's own reason is missing

`shell.nuon`'s `help --fuzzy` entry carries **no `why` at all**, so the single
most non-obvious fact about the manual browser is undocumented: the channel is
named **`manual`, not `help`**, because `help` is a clap **subcommand** of
`tv` — `tv help` prints tv's usage at rc 0 and never opens the channel. The
accepted cost is that typing "help" in the `Ctrl-Space` remote will never match
it, since `_finder_pick_channel` matches channel names only.

Found by the independent reader of the `tv channel` entry while reviewing
[`06-help/03-browser`](../../03-browser/prd.md)'s revision — it declined to put
the fact in the entry it was reviewing, which was right: a reader may not
become the author. R1 of that node carries the measurement.

This node's R4 already owns the CLI surface, so the entry belongs here rather
than in a new node. Write it as a `why` on `help --fuzzy`, and remember the
review ritual applies: whoever writes it cannot also vouch for it.
