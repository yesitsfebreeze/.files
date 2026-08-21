---
state: open
mode: afk
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
- [~] **R2** — **Entry schema.** Every entry carries:
  - Demoted `[x]` → `[~]` 2026-08-21 (`cc-1787301962`) by refutation. **Stub:**
    the `use` sub-box below is `[~]`, and a parent cannot be more met than its
    children. Recorded with it, because it is the same shape: "well-typed" is
    gated as field-presence plus closed-set membership, never value *shape* —
    `verify: [{kind: "command", name: ""}]` exits 0, so an empty required
    value is accepted. Seven of the eight sub-boxes were re-broken
    individually and each failed with its own named message; the refutation
    is in the Evidence block for that session.
  - [x] `key` or `cmd` — the binding (`ctrl-r`, `F5 <digit>`) or invocation
        (`z <query>`)
  - [x] `title` — one line: what it does
  - [~] `use` — how to use it: the actual gesture, in order, including what to
        press next and what comes back
    - Demoted `[x]` → `[~]` 2026-08-21 (`cc-1787301962`). **Stub:**
      field-presence-and-non-emptiness, plus the `restates-key` opener check,
      standing in for the *gesture* clause — with hand review, demonstrably
      fallible on exactly this clause, as the only support. Replacing
      `capsule list`'s `use` with the single character `"x"` exits **0**. No
      exemption covers this: R2 carves the resolution half out of the
      `verify` sub-box only, and [`coverage`](coverage/prd.md) R5 is about
      verify targets resolving, not about `use` prose. The gap has already
      bitten once — `shell.nuon [Ctrl-T]`'s `use` skipped a step of the live
      gesture, sat `[x]` for a cycle and was fixed by hand, not by the gate.
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
      period — and *imperative* now means the first word is a base-form verb
      on the gate's `IMPERATIVE_VERBS` list, with an **unknown opener a
      violation**: the check fails **closed** (gated: `nu
      tests/help-content-model.nu`, `selftest` asserts it can fail).
      `use` describes the real gesture, never restates the key on
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
  - Amended 2026-08-21 (`cc-1787301962`), sharpen + **stub list replaced**.
    The imperative clause above was sharpened to say what the gate now does:
    `non-imperative` was rewritten from a 33-opener blocklist into a
    fail-closed `IMPERATIVE_VERBS` allowlist. Both stubs the 2026-08-20
    refutation named are **retired**: the first-word-opener heuristic (the
    five escapes recorded in `## Findings` were run verbatim against the old
    predicate — all five passed it, all five now exit 1; three are permanent
    selftest controls), and the author's-own-hand-review stub (the review is
    now a recorded, digest-keyed obligation in
    `home/dot_config/nushell/help/why-review.nuon`, swept over all 51 pairs
    by a reader who wrote none of them, and the gate refuses a `why` with no
    current row, a stale row, a deleted file, or an empty record). **The two
    stubs that replace them:**
    1. Four of the 51 `why-review.nuon` rows carry a self-declared
       `reviewer is also the author` note, so [`laws.md`](../../../workflows/refs/laws.md)
       rung 3 is unsatisfied for those four — the record vouches for its own
       writing. They are marked in the data and are the first rows a later
       reader should re-read.
    2. "`use` describes the real gesture" is truth against a **live surface**,
       and 80 of 84 entries have no deployed surface to be checked against.
       The one live-checkable defect (`shell.nuon [Ctrl-T]`) was found and
       fixed; the clause cannot close here.

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

### 2026-08-21 · `cc-1787301962` — latest; shadows every block below where they disagree

Landed `dca40ba`, merged as `2b04399`
(`tests/help-content-model.nu`; `home/dot_config/nushell/help/README.md`,
`shell.nuon`, `nvim.nuon`, `terminal.nuon`, and the new `why-review.nuon`).
Nothing under `.mi/prd` from the lane worktree; no shared build file.

**Gate.** Still no wave-gate runner in this tree —
[`verification-gates`](../../00-delivery/verification-gates/prd.md) is fully
open — so this is again the ecosystem's plain equivalent, said plainly rather
than dressed up as the gate the board asks for: `bash tests/live-bugs.sh` →
`OK — every live-bug record still matches the config it describes`, exit 0;
this node's `verify:`, `nu tests/help-content-model.nu` → `help content model:
84 entries across 4 files, 9 topics, 10 prose-only … ok`, exit 0. Both re-run
by the landing session on the merge commit. Neither can speak for any surface
that is not deployed.

Every `[x]` on this node was **re-established by mutation this session**
rather than inherited, and then handed to a reader who did not write the
claims and was asked to refute each one. Two survived as demotions.

- **R1, R3, R4** — stay `[x]`. R1: `mv nvim.nuon` out of the help dir → exit
  1, ``nvim.nuon: missing — R1 names one file per surface``; restored → exit
  0. A present-but-empty file is caught separately (`no entries`), and
  `git ls-files home/dot_config/nushell/help/` lists all four `.nuon` files,
  so "under version control" holds by inspection. R3: the ordering clause was
  attacked directly — **swapping** the `git` and `containers` ids, leaving all
  nine present and resolvable, exits 1 naming both spines, so the comparison
  is list equality and not set equality; renaming `git` → `vcs` exits 1 on
  both the transcribed-`TOPICS` arm and the referential arm independently; an
  empty topic list aborts with "refusing to pass a check with nothing to
  check". R4: flipping `credentials in a capsule` to a `command` target exits
  1; the arm the previous block only asserted was run too — renaming
  `cmd: "mkcd"` → `"mkcd2"` exits 1 with ``concept entry `mkcd` is missing —
  R4`` plus the dangling `also` pointers and the stale review row it predicts.
- **R2** — **demoted `[x]` → `[~]`**, see the note on the box. Seven sub-boxes
  survive on their own mutations, each with a distinct named message: both
  `key` *and* `cmd` (and, separately reachable, *neither*); missing `title`;
  a `tmux` `mode`; an unresolvable `topic`; an `also` pointing at a non-entry
  (resolved cross-file, over `$all`, after every file loads); an unknown field
  `notes`; an `incantation` verify kind and a `wezterm-key` target missing
  `mods`. The `title` sub-box is gated past mere presence: non-empty after
  trim, no embedded newline, no trailing period, imperative opener, with
  `Frobnicate the widget` wired as a permanent selftest control. `VERIFY_KINDS`
  was diffed against `README.md`'s schema table and matches kind for kind.
- **R5** — stays `[~]`, with both prior stubs retired and two smaller ones
  named on the box. Proofs run: re-inserting `Ctrl+C`'s restating clause exits
  1 (`changed since the recorded review`); deleting a review row exits 1
  twice (unreviewed entry + stale row); deleting `why-review.nuon` exits 1; an
  empty record exits 1 rather than passing vacuously; making the digest blind
  to `why` exits 1 on its selftest control; forcing the imperative predicate
  to always return `""` exits 1 on seven controls.
- **Acceptance (readable as plain text)** — stays `[x]`, still held by
  reading the real artifact and by nothing else. All four surface files were
  opened raw by the refuting reader, not the two the prior block names:
  `capsule.nuon` 61 lines with a 6-line commented header then one field per
  line; `shell.nuon` a 13-line header then `# ------ navigate` section rules
  mirroring `topics.nuon`'s order; `terminal.nuon` and `nvim.nuon` the same
  shape. Nothing generated, escaped or minified anywhere in 1228 lines.
  Noted, not scored against the box: `why-review.nuon`'s rows are 16-hex
  digests and are *not* readable-as-manual — it is a review record, not one of
  the four surface files R1 names, and its header explains the digest and the
  ritual.

**Not done: owes 3 stubbed (R2, its `use` sub-box, R5).** The rest of
`06-help/01` is its [`coverage`](coverage/prd.md) child, deliberately left
unclaimed: its R5 (targets resolving against a live surface) is the contract
that would close R5's second stub, and building a live-resolution checker here
would poach [`04-drift-check`](../04-drift-check/prd.md)'s interface while
making the box look closable.

### 2026-08-20 · `cc-1787260422` — superseded by the block above

Landed `3b19ed0`, merged as `8a3d396` (`tests/help-content-model.nu`,
`home/dot_config/nushell/help/README.md`, `terminal.nuon`, `shell.nuon`).

**Gate.** No wave-gate runner exists in this tree —
[`verification-gates`](../../00-delivery/verification-gates/prd.md) is fully
open (13 boxes, none met) and no script anywhere in the repo runs the set — so
the close fell back to the ecosystem's plain equivalent: this node's own
`verify:`, `nu tests/help-content-model.nu` → `help content model: 84 entries
across 4 files, 9 topics, 10 prose-only … ok`, exit 0; plus `bash
tests/live-bugs.sh` → `OK — every live-bug record still matches the config it
describes`, exit 0, as the lane regression check. Both green after the merge.
Said plainly because it matters: this is not the gate the board asks for, and
it cannot speak for any surface that is not deployed.

- **R1, R3, R4** — stay `[x]`, and were **re-proved by mutation this run**
  rather than inherited from the sessions that first claimed them. R1: moving
  `nvim.nuon` out of the help dir exits 1 with ``nvim.nuon: missing — R1 names
  one file per surface`` — the file list is the `COVERAGE` const transcribed
  from the spec, not a directory read, so a missing surface cannot pass as an
  empty one. R3: renaming `id: "git"` → `"vcs"` exits 1 naming the drift, and
  so does *reversing* `topics.nuon`, so the list-not-set comparison is real;
  an empty topic list exits 1 with "refusing to pass a check with nothing to
  check". R4: filtering out the `mkcd` record exits 1 with ``concept entry
  `mkcd` is missing — R4`` plus the two dangling `also` violations it
  predicts, and flipping its verify to `{kind: "command"}` exits 1.
- **R2** — restored to `[x]`. Seven of the eight sub-boxes were mutation-run
  again this session against the real `.nuon` files (unknown field, both `key`
  and `cmd`, missing required field, bad `mode`, bad `verify` kind,
  `wezterm-key` target missing `mods`, dangling `also`) — each exits 1 with a
  named message. The `verify` sub-box no longer carries the drift-check stub
  that demoted it in `cc-1787256992`: the resolution half moved to
  [`coverage`](coverage/prd.md) R5 by the split in `26fc669`, so what remains
  here is well-typedness, and that is gated.
- **R5** — stays `[~]`, and the demotion survived a second adversary. What
  landed is real: `non-imperative` (`tests/help-content-model.nu:145`) is new,
  it exits 1 on three mutations of a live title (`Jumping…` gerund, `Jumps…`
  third-person, `The number keys…` noun phrase) and on three mutations of the
  predicate itself (empty `IMPERATIVE_S_VERBS`, forced-empty return, empty
  `NOUN_PHRASE_OPENERS`), so it has controls and is not a check that cannot
  fail. Two real `why`-restates-`use` defects were found by reading and fixed
  (`terminal.nuon [Ctrl+V]`, `shell.nuon [Ctrl-T]`), the second with its
  replacement read off the live route rather than asserted. **Two named
  stubs keep the box open**, both established by the refuting reader and
  recorded in `## Findings` below: a first-word opener heuristic standing in
  for the imperative *mood*, and the author's own hand review standing in for
  a gate on the `why` clause.
- **Acceptance (readable as plain text)** — stays `[x]`, held by review
  against the real artifact and by nothing else, which is stated rather than
  dressed up: `open` returning a table would pass a minified blob too.
  `terminal.nuon` carries a 51-line commented header then one record per
  entry, one field per line, human strings throughout; `shell.nuon` around
  both edited entries is the same shape. If these files are ever generated
  programmatically, this box has nothing standing behind it.

**Not done: owes 1 stubbed (R5).** The rest of `06-help/01` is its
[`coverage`](coverage/prd.md) child, blocked on the terminal respec, the
capsule CLI and [`04-drift-check`](../04-drift-check/prd.md).

### 2026-08-20 · `cc-1787256992` — superseded by the block above; shadows the block below

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

## Findings

### 2026-08-21 · the second failed proxy, so a third is not built

**Best-sentence containment fails too, and it fails *worse* than the
whole-text measurement it followed** — which matters, because it is the
obvious next thing a reader reaches for when told whole-text containment was
too coarse. Measured over all 51 `why`-carrying pairs, taking the maximum
containment of `why`'s content words in any single sentence of `use`: mean
**0.157**; the two known defects land at `terminal.nuon [Ctrl+C]` **0.167,
rank 23 of 51** and `terminal.nuon [Ctrl+Shift+B]` **0.143, rank 27 of 51** —
one at the mean, one below it. Finer granularity did not separate the
defects; it moved them nowhere. Both failed measurements are now written into
the gate's comments, into `home/dot_config/nushell/help/README.md` and into
`why-review.nuon`'s own header, so the next worker does not build a third
proxy that reads as enforcement and enforces nothing.

**Superseding the 2026-08-20 finding below on the imperative check.** That
block records the check as "gated against three openers, not against the
mood", with `Tab jumping by number`, `Fast tab access by number` and
`Jumped to a tab by its number` as confirmed escapes at exit 0. Those escapes
were re-run verbatim against the shipped predicate this session (plus
`Fast copying of the selection` and `Selection copying, …`): all five passed
it. The predicate is now a fail-closed base-form-verb allowlist and all five
exit 1 as live-file mutations; three are permanent selftest controls. The
finding is kept because it is the record of why the rewrite happened.

### 2026-08-21 · the four `why` entries rewritten in the sweep, and the four left standing

Swept by a reader who wrote none of the 51 pairs. Rewritten, with the reason,
so the next reader can check the judgement rather than trust it:

- **`shell.nuon [Ctrl-T]`** — the `use` skipped a whole step of the gesture.
  The live route (`config.nu:635` `finder_pick` → `tv_finder`
  (`config.nu:686`) → `finder` with no `--start` → `finder.nu:33`
  `_finder_pick_channel`) opens the **channel remote first**, exactly as
  `Ctrl-Space`'s own entry says. The `use` now says so and the `why` keeps
  only the shared-cable consequence.
- **`nvim.nuon` shift-arrow** — one insert-cursor fact was stated in both
  `use` and `why`, mirrored for Left and Right. The mechanism now lives once,
  in `why`.
- **`terminal.nuon [Ctrl+C]`** — the `why` opened by re-saying its `use`'s two
  branches. (This is the residual the 2026-08-20 finding below predicted.)
- **`terminal.nuon [Ctrl+Shift+B]`** — the `why` carried a copy of
  `capsule.nuon [capsule --rebuild]`'s `why` *and* re-said its own `use`; it
  now points at the entry that owns the fact.

Four further pairs are borderline and were **left standing deliberately, with
the reason recorded in their own review row** rather than silently:
`shell.nuon [help --check]`, `shell.nuon [mkcd]`, `terminal.nuon [F5 <digit>]`,
`capsule.nuon [capsule --rebuild]`.

### 2026-08-21 · `why-review.nuon` puts an obligation on sibling nodes — the epic may want it stated

**Flagged rather than acted on, because it is not this node's to write.**
`why-review.nuon` closes R5's review clause by gating the *obligation*: from
now on, any task that adds or edits a `why` must also read it against its
`use` and add a review row, or `nu tests/help-content-model.nu` exits 1 naming
the entry and the digest to set. The file carries the three-step ritual and
the gate prints the digest.

That is a contract touching **siblings**, not just this node. The epic's
invariant 4 already says every other task fills its own rows, which is why the
mechanism was implemented here rather than escalated — this node owns the
schema and its gate, and the alternative was to leave R5's review clause where
[`laws.md`](../../../workflows/refs/laws.md) rung 3 calls it a wish. But if
[the epic](../prd.md) wants the obligation stated in its invariants, that is an
amendment to another node's contract and neither the working session nor the
landing session may write it (law 2). Recorded here so it is not lost.

### 2026-08-21 · lane edge, said loudly

The working session edited `tests/help-content-model.nu`. This node's lane
owns `home/dot_config/nushell/help/`; the gate for that data lives in
`tests/`, is this node's own `verify:`, and every prior session on this node
edited it — so it was judged in-contract. It is nevertheless **outside the
directory the lane was handed**, and no other lane should be in that file.

### 2026-08-20 · why R5 is `[~]`, and the measurement that keeps it there

**The `why`-restates-`use` clause cannot be gated by word containment, and
that is a measured result, not an excuse.** Containment of `why`'s content
words in `use`, over all 51 `why`-carrying entries: mean 0.11–0.12
(independently reproduced twice, 0.11 and 0.118). The known defect
`terminal.nuon [Ctrl+V]` scores **0.097 — rank 28 of 51, below the mean**, so
any threshold catching it fires on more than half the manual, and the
top-ranked entry at 0.571 is not a defect at all. A check built on this proxy
would read as enforcement and enforce nothing, which is the failure this node
has already been burned by twice. The measurement is written into
`home/dot_config/nushell/help/README.md` so the next worker does not rebuild
the same failed proxy.

**But hand review is not a sufficient substitute either, and that is also
measured.** The reviewing session swept all 51 pairs and fixed two; a second
reader sweeping the same 51 immediately found a residual by the reviewer's own
standard — `terminal.nuon [Ctrl+C]`, the `also` partner of the `Ctrl+V` entry
that *was* fixed, in the same file: its `use` already says "With text selected
… copies it. With nothing selected the same key is the ordinary interrupt",
and its `why` restates that conditional. It scores 0.167, **rank 8 of 51,
above the mean** — the discarded proxy would have flagged it and the human
pass did not. Weaker same-shape residuals: `capsule.nuon [capsule --rebuild]`
and `terminal.nuon [Ctrl+Shift+B]`. Two independent methods, each catching
what the other missed, neither sufficient alone: that is the state of this
clause, and it is why the box is a stub rather than a close.

**The imperative check is gated against three openers, not against the mood.**
`non-imperative` decides from the first word only, and catches a noun phrase
only when that word is one of 33 hardcoded determiners/pronouns/prepositions.
Confirmed escapes, all the same failure class, all exit 0: `Tab jumping by
number`, `Fast tab access by number`, `Jumped to a tab by its number`. Also
established, and worth keeping: the check finds **0 violations in the 84 live
titles**, and all 84 were read by hand and are in fact imperative — so this is
a passing check with real subjects, not law 3's empty check. The distinction
is carried entirely by the `selftest` controls, and both the gate comment and
`README.md` say so, so that a future reader does not "clean up" a check that
never fires.

**One defect outside this node's boxes, recorded where it will be found.**
`shell.nuon [Ctrl-T]`'s `use` reads "Mid-command, press `Ctrl-T`, pick a file
or directory: it is inserted at the cursor", but the live route
(`~/.config/nushell/config.nu:635-639` `finder_pick` → `tv_finder`
(`config.nu:686`) → `finder` with no `--start` → `finder.nu:33`
`_finder_pick_channel`) opens the **channel remote first**, exactly as
`Ctrl-Space`'s own entry says. The entry skips a step of the gesture. This
lands on R5's "`use` describes the real gesture" clause and, read literally,
on R2's `use` sub-box too — R2's gate checks presence and non-emptiness, not
truth against the live surface, which is
[`coverage`](coverage/prd.md) R5's contract.

**Protocol gap, recorded not hidden.** worker.md §5 asks for a verifier
prompted to refute each `[x]`. The working session had no subagent-spawn tool
and ran its own refutation; the independent refutation that produced the
findings above ran afterwards, in the landing session, by a reader who did not
write the claims. Both objections that survive are in this section rather than
in a private transcript.

## Out of scope
- Anything this node's Requirements do not name. The epic ([`../prd.md`](../prd.md)) owns the shared invariants.
