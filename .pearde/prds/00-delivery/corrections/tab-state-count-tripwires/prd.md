---
state: done
claim: 
priority: 20
est: 0.5h
actual: 1h
mode: afk
needs:
  - 00-delivery/corrections/armed-count-tripwires
verify: ""
origin: derived
from: 00-delivery/corrections/armed-count-tripwires
---

# Three more key-dump counts, in the gate the census did not reach

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: the fifth, sixth and seventh instances of the count-literal defect,
found by [`armed-count-tripwires`](../armed-count-tripwires/prd.md)'s analyst
in a file that node's requirements do not name — so out of its footprint, and
its own node rather than a silent widening.

`tests/wezterm-tab-content-state.sh`'s cross-node regression block asserts
three hardcoded row counts over the **same generated key dump** that node's
Tier 2 checks cover:

| line | literal |
|---|---|
| `:271` | `jump_mode … -eq 36` |
| `:274` | `act.Nop … -eq 27` |
| `:277` | `copy_mode … -eq 55` |

The dump is generated inside the gate by
`wezterm --config-file … show-keys --lua`, from `home/dot_config/wezterm/wezterm.lua`
— a file **seven** terminal nodes write (T.1, T.2, T.3, T.4, T.6, T.7, T.8).
So each literal can be invalidated by work with nothing to do with what the
check means to assert. That is a cross-node regression block whose own
tripwires are cross-node.

This file belongs to
[`02-terminal/05-tab-content-state`](../../../02-terminal/05-tab-content-state/prd.md)
(T.6), which is `done`.

## Requirements
- [x] **R1** — Each of the three counts becomes set equality against an
      independent declaration, with `MISSING` / `UNEXPECTED` in the failure
      message — the form
      [`armed-count-tripwires`](../armed-count-tripwires/prd.md) lands.
      **Port `bound_rows` / `rows_ok` from what actually shipped there**
      rather than reimplementing: that is the reason this node deps on it,
      and the reason it is cheap.
- [x] **R2** — The reader stays **table-scoped**, emitting
      `<table> <key> <mods>` triples. A key-only set with `sort -u` cannot
      see a member arriving in a *different* table — the sibling analyst
      proved that by making a `Nop` arrive in `copy_mode` as the letter `a`,
      which a key-only set misses entirely. Table scoping is strictly
      stronger than the count it replaces: the count saw 28 rows but could
      not say where.
- [x] **R3** — Six counterfactuals — one member removed and one foreign
      member arriving, per check — each **landed in the gate as a
      `chk_fail`**, not merely run by hand at implementation time. A
      counterfactual that lives only in a report decays; one in the gate
      keeps proving itself. This is where
      [`zoxide-entry-count`](../zoxide-entry-count/prd.md) stopped and where
      `armed-count-tripwires` went further.
- [x] **R4** — No other assertion in the file changes, and the three
      cross-node checks keep asserting the same thing about the same tables.
      This node changes how they are expressed, never what they conclude.

## Acceptance
- [x] `bash tests/wezterm-tab-content-state.sh` reaches `EXIT=0` with 0 FAIL,
      run **alone**, tally quoted and **not** asserted as a fresh absolute.
      Measured: 62 → **70 PASS / 0 FAIL**, `rc=0`,
      `wezterm-tab-content-state gate: ALL PASS`. The delta is +8 and every
      one of it is a check added; the only removals are the 11 lines of the
      old count block.
- [x] Six counterfactuals quoted going red, each naming the offending
      `<table> <key> <mods>` triple. All six PASS as `chk_fail`s in the gate;
      `chk_fail` discards the diagnosis, so each was re-derived by calling
      the same helper on the same mutation: `MISSING [jump_mode 9 NONE]`,
      `UNEXPECTED [jump_mode Tab NONE]`, `MISSING [jump_mode z NONE]`,
      `UNEXPECTED [copy_mode a NONE]`, `MISSING [copy_mode c NONE]`,
      `UNEXPECTED [copy_mode Escape SHIFT]`.
- [x] `bash gates/wave-status.sh --run 4` green — wave confirmed at
      `gates/waves.tsv:25`, which lists `external bash
      tests/wezterm-tab-content-state.sh`. Run alone after the board went
      quiet: `WAVE4 EXIT=0`, ~7 min, 13 gate commands all
      `PASS  wave 4 gate: …`, this gate's leg among them. The three `FAIL`
      lines in that log are `tests/shell-television.sh`'s hermetic
      Ctrl-T/F1-PWD rows (S.9), which the runner itself reports as
      "exited 1 — reported, not gating (wave is PENDING)"; they are another
      node's gate and outside this footprint. `tests/nvim-lsp.sh`, red
      earlier in the day under
      [`lsp-gate-parser-seed`](../lsp-gate-parser-seed/prd.md), was green in
      this run on both legs.
- [x] `grep -nE '\-eq (36|27|55)' tests/wezterm-tab-content-state.sh` prints
      nothing — `/usr/bin/grep` exits 1 with no output.

## Out of scope
- The four checks in
  [`armed-count-tripwires`](../armed-count-tripwires/prd.md), which must land
  first — this node ports its helpers.
- Any count already in the durable form, and the two deliberate exclusions
  that node's R5 confirmed: `shell-zoxide.sh`'s two-PWD-append invariant, and
  `theme-switcher.sh:310`'s literal whose arithmetic is in its own label.

## Orchestrator note, 2026-08-23

The open risk in this node's brief — whether all three sets have an
**independent** declaration to compare against, or whether one would have to
fall back to a floor — resolved cleanly. **None needed a floor:**

- `jump_mode` = 36 is `1 + 9 + 26`: Escape, one digit per tab of epic I1's
  nine-tab floor, and the alphabet. A board invariant, not the dump.
- `act.Nop` = 27 ports `JUMP_NOP_ROWS` verbatim from
  `tests/wezterm-f5-tab-select.sh:59-60`.
- `copy_mode` = 55 was the hard one and it derives exactly.
  `wezterm.lua:634` is `wezterm.gui.default_key_tables().copy_mode` plus one
  `table.insert`, so the gate writes its **own bare config**, dumps it with
  the same `show-keys`, drops the eight uppercase+SHIFT duplicates the printer
  shows but `default_key_tables()` folds away, and adds T.4's `c` row:
  62 − 8 + 1 = **55**, with `comm` confirming the delta is exactly those eight
  plus `c NONE`. It reads the **pinned build**, never `$SRC`, so none of the
  seven terminal nodes can move it — and it survives a WezTerm upgrade rather
  than going red for the wrong reason.

`wezterm.lua:619-628` already carries that arithmetic as a comment ending *"Do
not 'fix' the count"*. This node makes that comment executable, which is the
best possible outcome for a constraint that was previously only prose.

## Orchestrator note on the elapsed time, 2026-08-23

`actual: 1h` against `est: 0.5h` is the first over-run of the session, and
almost none of it was the work. Its implementer killed a first wave-4 run on
finding another agent's `wave-status --run 4` clobbering the same scratchpad
log filename, then waited ~4 minutes for **four** concurrent `--run 4`
processes and two `tests/nvim-lsp.sh` runs to drain before re-running into a
unique log.

That is a real cost of a three-worker board sharing one gate runner, and it is
worth recording rather than smoothing into the estimate: the node's own gate
takes 1 second. Two things it suggests, neither built here — the runner could
take a unique log path per invocation, and the board could treat
`wave-status --run N` as a footprint.
