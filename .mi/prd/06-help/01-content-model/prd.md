---
state: claimed
mode: afk
claim: cc-1787260422
deps: []
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
  - [x] `verify` — present and well-typed: one of the six kinds, with that
        kind's required fields. That the target *resolves* against a live
        surface is [`coverage`](coverage/prd.md)'s R5, not this node's —
        the distinction the old wording lost.
- [x] **R3** — **Topics.** The manual's spine, ordered by how often it's
      needed: `navigate` · `find` · `history` · `edit` · `git` · `containers`
      · `terminal` · `agents` · `config`.
- [x] **R4** — **Concept entries.** A small number of prose entries (`verify:
      prose`) for the mental models a list of keys can't convey: the `mkcd`
      funnel and why every navigation route updates start dir and recents; why
      a bare word jumps; what a tv channel is and how to add one; how
      credentials reach a capsule.
- [~] **R5** — **Writing rules.** `title` is one line, imperative, no trailing
      period (gated: `nu tests/help-content-model.nu`, `selftest` asserts it
      can fail). `use` describes the real gesture, never restates the key on
      `key`-typed entries — bare or backticked (gated, same test,
      `restates-key` + `selftest`). `why` only where the reason is
      non-obvious, and never restates what `use` already said (reviewed by
      hand, not gated). Drop the "most entries won't have one" prediction:
      measured 51/84 (61%) carry a `why`, each reviewed as a real constraint,
      and `home/dot_config/nushell/help/README.md:146-152` records the
      mismatch as an open question against R5's own wording rather than a
      defect to fix by removing whys — a worker should not treat this box as
      asking them to cut `why` fields down.
  - Amended 2026-08-20 (`cc-1787260422`), sharpen. Ran `nu
    tests/help-content-model.nu` on HEAD (26fc669): exit 0, `84 entries
    across 4 files, 9 topics, 10 prose-only … ok`. Commit 9c4141b
    (`06-help/01: make R3 and R9 checks able to fail, and fix the nine
    entries they catch`) landed the mechanical gate: `restates-key`
    (backtick-aware, scoped to `key` entries) plus a `selftest` that runs
    positive/negative controls every invocation — proven per that commit by
    reverting the predicate to bare-only (exits 1 on the positive control)
    and widening it to `str contains` (exits 1 on the negative control).
    Recomputed the `why` count independently against the live `.nuon`
    files: `total=84 with_why=51` (61%), matching README.md's own recorded
    measurement at lines 146–152, which already states the prediction, not
    the entries, is the open question. Still open and ungated: `why`
    restating `use` is caught only by hand review.

## Acceptance
- [x] Opening a content file directly is readable as plain text — the data is
      the manual, not a serialization artifact.

## Children

- [`coverage`](coverage/prd.md) — that the manual covers every surface, and
  that each entry's `verify` target resolves against a real binding. Split out
  2026-08-20: this node held two contracts and could never close, so the
  scheduler re-took it three times while its blocked half sat as `[~]`.

**Renumbering, same date.** R4–R7 (the four coverage requirements) moved to
that child, so the old R8 is now R4 and R9 is R5. The Evidence below predates
the move and cites the old numbers; read it against this map rather than
assuming it drifted:

| was | now |
|---|---|
| R1, R2, R3 | unchanged |
| R4 shell · R5 nvim · R6 terminal · R7 capsule | `coverage` R1–R4 |
| R2's `verify` sub-box (resolution half) | `coverage` R5 |
| R8 concepts | R4 |
| R9 writing rules | R5 |
| A1 drift-check · A3 no-duplication | `coverage` acceptance |

## Evidence

### 2026-08-20 · `cc-1787256992` — latest; shadows the block below where they disagree

Landed `05fb17d` (`home/dot_config/nushell/help/terminal.nuon`,
`home/dot_config/nushell/help/README.md`, `tests/help-content-model.nu`).
Ran `verify:` — `nu tests/help-content-model.nu` → `help content model: 84
entries across 4 files, 9 topics, 10 prose-only … ok`, exit 0. Falsification:
renaming the new `Ctrl+Shift+X` entry produced 2 named violations and exit 1.

**The `wezterm-key` target contract, measured — belongs here because it cost a
silent 4-of-5 miss.** A target is written *as `wezterm show-keys --lua`
prints it, which is not as `wezterm.lua` writes it*. Two normalizations,
both measured against the live WezTerm on 2026-08-20 (263-line dump; 143
top-level rows plus tables `copy_mode` 55, `jump_mode` 36, `search_mode` 10):

- **ordering** — `mods = "CTRL|SHIFT"` in Lua prints as `SHIFT|CTRL`;
- **shift folds into the letter** — `key="q", mods="CTRL|SHIFT"` prints as
  `key='Q', mods='CTRL'`, with no `SHIFT` at all. Same fold
  `nvim_get_keymap` does to `<S-h>` → `H`.

Every control+shift entry had been written `{key: "q", mods: "SHIFT|CTRL"}`
and `README.md` told the next writer to keep doing it. Resolving the five old
targets against live output: **4 of 5 miss**, silently — WezTerm's own
*defaults* carry `SHIFT|CTRL` letter rows, so the wrong spelling sits beside
rows that make it look plausible. All five corrected; the corrected set of 29
misses 2 (`D|CTRL`, `S|CTRL`), which are the genuinely unbuilt capsule keys.

**`Ctrl+Shift+T` is a false pass, and `06-help/04-drift-check` inherits it.**
`T`+`CTRL` is WezTerm's own `SpawnTab` default, so that entry's drift check
resolves whether or not a capsule binding is ever written. Recorded in the
entry's `why` and in `README.md` as a named blind spot for `04`.

- **R2** — demoted `[x]` → `[~]` by refutation, and the demotion is the
  point. Eight sub-boxes survive, each mutation-proved to fail exactly once
  with a named message (unknown field, both `key` and `cmd`, missing required
  field, bad `mode`, bad `verify` kind, wezterm target missing `mods`,
  dangling `also`). The `verify` sub-box does not: it says "how the drift
  check confirms it exists ([04](../04-drift-check/prd.md))", and `04` does
  not exist — the gate's own header states it cannot check whether a `verify`
  target resolves. A schema validator is standing in for the drift check.
  Proof the stub is load-bearing, not cosmetic: reverting this run's exact
  fix (`{kind: "wezterm-key", key: "Q", mods: "CTRL"}` back to `{key: "q",
  mods: "SHIFT|CTRL"}`) exits 0; renaming `table: "copy_mode"` to
  `table: "no_such_table"` exits 0. The field sat `[x]` for a whole cycle
  carrying 11 targets that resolved to nothing. Separately, R2 says entries
  with no live counterpart take `prose`; `Ctrl+Shift+D`, `Ctrl+Shift+S` and
  all four `capsule` entries carry live-handle kinds instead (`capsule` is
  absent from `PATH`).
- **R3** — stays `[x]`, but **not on the gate**: `topics.nuon` was read by
  hand and holds exactly R3's nine ids in R3's order. The gate reads the
  topic list *out of the data it is checking* and only asserts referential
  integrity, so it cannot notice the data drifting from R3 — renaming
  `git` → `vcs` and deleting `history` still exits 0. The nine names should
  become a const in the gate; until then only review protects R3.
- **R4** — stays `[x]`, re-derived rather than inherited. All 11 documented
  `kind: keybinding` names appear live in `~/.config/nushell/*.nu`
  (`comm -23` empty; the lone live-not-documented row `string` is a regex
  false positive on a `name: string` annotation). Keycodes checked too, not
  just names: `config.nu:550-637` gives `hist_picker_local`=`control+char_r`,
  `hist_picker_global`=`alt+char_r`, `hist_up/down_local`=`none+up/down`,
  `hist_up/down_global`=`shift+up/down`, `tv_remote`=`control+space`,
  `tv_remote_f1`=`none+f1`, `quicklist`=`control+char_q`,
  `finder_pick`=`control+char_t`, `esc_clear`=`none+escape` — all match. The
  29 `alias`/`command` verify names all resolve live except `help`, this
  epic's own net-new subject.
- **R6** — `[~]`, stub materially smaller than before. Corrected the spelling
  on every control+shift target (above) and added the three live keybindings
  that had no entry at all and are rated take-over-as-is by W0.1's
  [`capabilities-terminal.md`](../../../docs/capabilities-terminal.md):
  `Ctrl+Shift+X` copy mode plus its two-press `c` cycle (C4/U9), `Ctrl+V`
  bracketed paste (C1/U8), `Ctrl+C` copy-or-SIGINT (C3/U9). All four of their
  targets resolve live. `F6` (DEFER) and `Ctrl+Shift+B`-as-wallpaper
  (DO NOT PORT) are deliberately left undocumented. **Stub named:**
  [`w0-2-terminal-respec`](../../00-delivery/corrections/w0-2-terminal-respec/prd.md)
  is `open` with three unresolved deps, so the F5 letter *ordering* fork
  (geometric vs. split-creation) is unsettled, and `{key:"D",mods:"CTRL"}` /
  `{key:"S",mods:"CTRL"}` still resolve to nothing — correctly, because those
  capsule keys are unbuilt.
- **R8** — stays `[x]`, and it is the best-gated box here: deleting the
  `mkcd` record exits 1 (3 violations, incl. two dangling `also` pointers),
  and changing its verify from `prose` to `{kind: "command"}` exits 1 with
  ``concept entry `mkcd` is not verify: prose — R8``. The gate's `CONCEPTS`
  const transcribes R8's prose rather than reading the data back, so unlike
  R3 it survives a rename of the data.
- **R9** — demoted `[x]` → `[~]` by refutation. The mechanical half is real
  (forcing a trailing period on `Ctrl+V`'s title exits 1 with `title ends
  with a period`; all 84 titles read one-line, imperative, period-free). The
  substantive half is not gated. The restatement check tests
  `$e.use | str starts-with $eid` against the **bare** id, while this corpus
  universally writes ids in backticks: measured across all 84 entries,
  bare-prefix hits = 0 and backtick-prefix hits = 24. A check that fires on
  nothing across the whole corpus, defeated by one backtick, is law 3's "a
  gate that finds nothing to check must fail, not pass" — and it is the only
  clause separating R9 from R2's field-presence check. "Imperative" has no
  test at all, and "`why` only where non-obvious — most entries won't have
  one" is contradicted by the data: 51 of 84 entries (61%) carry a `why`
  (shell 22/41, nvim 16/27, terminal 10/11, capsule 3/5). **Stub named:** the
  vacuous restatement check standing in for R9's substance. One concrete
  defect left in the new work: `Ctrl+V`'s `use` and `why` state the same fact
  twice — the `use` is carrying `why` material.
- **A1** — still `[ ]`, and deliberately so. Hand-resolution got closer (27/29
  terminal targets, 11/11 shell) but a one-off script run in a scratchpad is
  not the standing check A1 names. It was **not** committed: building a
  live-resolution checker is
  [`04-drift-check`](../04-drift-check/prd.md)'s contract, and landing one
  here would poach another node's interface while making A1 look closable.
- **A2** — stays `[x]`, held by reading rather than by the check previously
  cited (`open` returning a table proves parseability, which a minified blob
  would also pass). `terminal.nuon` opens with a ~50-line commented header —
  surface, schema pointer, caveats, the mods-spelling rule, the live-bindings
  inventory — then one readable record per entry. Its load-bearing factual
  claim was spot-checked: `grep -nE "key *= *['\"]" ~/.config/wezterm/wezterm.lua`
  returns exactly `F5`, `F6`, `Ctrl+Shift+X`, `Ctrl+Shift+Q`, `Ctrl+V`,
  `Ctrl+C`, `Ctrl+Shift+B` plus `jump_mode`/`copy_mode` (lines 818, 951,
  1003, 1032, 1044, 1058, 1076, 1080, 1094). No committed check covers A2;
  it is held by review alone.

**Lane discipline.** Touched only `home/dot_config/nushell/help/terminal.nuon`,
`home/dot_config/nushell/help/README.md` and `tests/help-content-model.nu`.
`nvim.nuon`, `shell.nuon`, `capsule.nuon`, `topics.nuon` untouched; nothing
under `.mi/prd` from the lane worktree; no shared build file.

**Three `Ctrl+Shift+*` entries were NOT deleted, contrary to the previous
block's instruction.** They are unbuilt, which is the normal state of
everything in this repo (`capsule.nuon` documents a CLI that does not exist
either), and `Ctrl+Shift+S`/`Ctrl+Shift+T` are named explicitly in
[`01-capsule`](../../01-capsule/prd.md)'s `R2` — removing them would be a
law-2 edit to another node's contract. The one live collision,
`Ctrl+Shift+B`'s wallpaper prompt, is rated `DO NOT PORT` (C8/U3), so the key
comes free with the port.

**Not done: owes 1 open + 7 stubbed** (R2 and its `verify` sub-box, R5, R6,
R7, R9, A3 stubbed; A1 open). Ready again once the terminal respec, the shift-select fork, the
capsule CLI and the drift check land.

### 2026-08-20 · `cc-1787250953` — prior record

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
  **Superseded by the block above:** only `Ctrl+Shift+T` needs re-picking;
  `Ctrl+Shift+B` is freed by the `DO NOT PORT` verdict; `D` and `S` are
  merely unbuilt, and belong to `01-capsule`.
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

**Not done: owes 1 open + 4 stubbed.** *(Superseded: R2 and R9 were demoted
to `[~]` on refutation, so the count is now 1 open + 7 stubbed.)*

## Out of scope
- Anything this node's Requirements do not name. The epic ([`../prd.md`](../prd.md)) owns the shared invariants.
