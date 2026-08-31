---
state: done
claim: 
priority: 26
est: 1.5h
actual: 15m
mode: afk
needs:
  - 00-delivery/corrections/zoxide-entry-count
verify: ""
origin: derived
from: 00-delivery/corrections/zoxide-entry-count
---

# Four more hardcoded counts, armed and green, waiting to fire

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: [`zoxide-entry-count`](../zoxide-entry-count/prd.md)'s R4 census swept
`tests/` for assertions of a hardcoded count over an artifact that another node
may legitimately change. It found the one that had already fired, and **four
more in the identical shape, currently green**. They are recorded here rather
than folded into that node, because a second instance of a defect class is its
own finding.

**Tier 1 — the exact shape that fired.** `grep -cF "source: \"$PRD_PATH\""`
against a literal, so any correction repointing a manual entry to that PRD
breaks the gate:

| File:line | Literal | Owner PRD |
|---|---|---|
| `tests/shell-claude.sh:237` | `-eq 2` | `04-shell/08-claude-launchers` |
| `tests/shell-history.sh:427` | `-eq 4` | `04-shell/05-history` |

Both are green today, so nothing is broken — the point is that
[`cdi-manual-source`](../cdi-manual-source/prd.md) was a two-file, one-field
correction that turned a sibling gate red with a green verify of its own, and
these two are the next places that happens.

**Tier 2 — literal counts over a generated key dump.** Two facts in this
paragraph were wrong when filed and are corrected here:

- **`home/dot_config/wezterm/keys.lua` does not exist.**
  `git ls-files home/dot_config/wezterm/` is exactly `wezterm.lua`, and this
  gate's own static stage asserts that. The dump is *generated* at the gate's
  line 140 by `wezterm --config-file "$SRC" show-keys --lua` into its scratch
  `HOME`.
- **The shared artifact is `wezterm.lua`, written by seven terminal nodes, not
  four** — T.1, T.2, T.3, T.4, T.6, T.7, T.8. Six are `done`; T.7
  ([`02-terminal/06-launchd-path`](../../../02-terminal/06-launchd-path/prd.md))
  was `claimed` while this was analysed and has since landed. Its spec01
  explicitly leaves `config.keys` and the key tables alone, so the dump should
  not have shifted — re-run if it did.

So the risk is real but indirect: the literal counts rows in a dump derived
from a file seven nodes write.

| File:line | Literal | Note |
|---|---|---|
| `tests/wezterm-f5-tab-select.sh:168` | `act.Nop` `-eq 27` | The comment admits it was "measured at spec time". Derivable from a declared roster: Escape plus 26 letters. |
| `tests/wezterm-f5-tab-select.sh:172` | `act.ActivatePaneDirection` `-eq 4` | **The four directions are enumerated in the loop immediately below it** — precisely this defect's shape, a literal duplicating an adjacent list's length. |

## Requirements
- [x] **R1** — The two Tier 1 checks take the form
      [`zoxide-entry-count`](../zoxide-entry-count/prd.md) landed: a declared
      roster, the count derived from it, and **set equality** with `MISSING`
      / `UNEXPECTED` in the failure message. This is a mechanical port of
      that node's `owned_ids_ok` — the roster differs, the function does not.
      Read what actually landed there rather than reimplementing from this
      description. Done: `cited_ids` and `owned_ids_ok` transcribed from
      `tests/shell-zoxide.sh:213-244` into both gates, with
      `CLAUDE_HELP_IDS=('cc [...args]' 'cr [...args]')` and
      `HISTORY_HELP_IDS=('Ctrl-R' 'Alt-R' 'Up / Down' 'Shift+Up /
      Shift+Down')` as the two rosters. `${#ARRAY[@]}` is the only place a
      number appears. The passing labels name their members: `tree: exactly 2
      entries name this PRD as their source, and they are the ones it owns:
      cc [...args] cr [...args]` and `tree: exactly 4 entries name this PRD
      as their source, and they are the ones it owns: Alt-R Ctrl-R Shift+Up /
      Shift+Down Up / Down`. **All four history ids are `key:` records**, so
      the presence loop greps `key: "$k"`; a `cmd:` loop finds none of them —
      `/usr/bin/grep -c 'cmd: "Ctrl-R"' …/shell.nuon` prints `0`.
- [x] **R2** — The two Tier 2 checks derive their count from the list each
      one duplicates: the letter roster for `act.Nop`, and the direction
      loop directly below for `act.ActivatePaneDirection`. Done:
      `JUMP_NOP_ROWS` is built as `Escape` plus `{a..z}`, a fact about the
      alphabet rather than a reading of the dump; `PANE_DIRS=(LeftArrow
      RightArrow UpArrow DownArrow)` is declared once and read twice — by
      `PANE_DIR_ROWS` and by the per-direction loop, which no longer restates
      its own length. The reader `bound_rows` is **table-scoped**, emitting
      `<table> <key> <mods>` triples, because a `Nop` arriving in `copy_mode`
      as the letter `a` is invisible to a key-only set: over that mutated
      dump the key-only `sort -u` set still holds 27 members.
- [x] **R3** — **Every rewritten check keeps a counterfactual that can go
      red, in both directions**, and each is executed and quoted: an
      expected member removed, and a foreign member arriving. A derived
      count is worthless if both sides move together — that failure mode is
      why `zoxide-entry-count` rejected deriving from the artifact under
      test, and the same trap applies here. Done: eight `chk_fail`
      counterfactuals **live in the gates**, not in a report. Each mutates
      exactly one citation or one row in a `$SCRATCH` copy; no artifact under
      test is written. All eight PASS, and each diagnosis names the offending
      member — the report carries all eight verbatim.
- [x] **R4** — No assertion becomes weaker. In particular do **not** adopt
      the set-filtered-length form at `tests/theme-switcher.sh:461`: it
      cannot see a foreign entry arriving, and that arrival is the event
      that fired in the first place. Confirmed: every replacement is set
      equality, and the four arrival counterfactuals prove the arrival side
      goes red. Nothing was dropped — the two Tier 1 literal presence lines
      became roster loops one-for-one, the four per-direction `chk_ok` lines
      are verbatim, and the static stage keeps its `for i = 1, 26` and
      `string.char(96 + i)` greps.
- [x] **R5** — Two counts the census found and deliberately **excluded** stay
      as they are, and the report says so: `tests/shell-zoxide.sh`'s
      "exactly two PWD append blocks in `config.nu`", which is the
      deliberate D4/R6 invariant — a sibling adding a third *should* fire —
      and every Tier 3 literal whose derivation is stated in its own label
      (`theme-switcher.sh:310`'s "7 role colours + 8 ansi + 8 brights = 23"
      is the exemplar of a literal done well). Checked, not changed:
      `diff -q` against `cp`-aside baselines reports `tests/shell-zoxide.sh`
      and `tests/theme-switcher.sh` both **identical**. Both literals still
      read as they did.

## Acceptance
- [x] `bash tests/shell-claude.sh`, `bash tests/shell-history.sh` and
      `bash tests/wezterm-f5-tab-select.sh` each reach `EXIT=0` with 0 FAIL,
      run **alone**, with tallies quoted and **not** asserted as fresh
      absolutes. Measured, each run alone: `shell-claude.sh` 49 → **51 PASS /
      0 FAIL**, `shell-history.sh` 62 → **68 PASS / 0 FAIL**,
      `wezterm-f5-tab-select.sh` 54 → **58 PASS / 0 FAIL**, `ALL PASS`. Every
      delta is a check added, none removed.
- [x] Eight counterfactuals — two directions per rewritten check — each
      quoted going red and naming the offending member. All eight PASS as
      `chk_fail`s inside the gates. Diagnoses: `MISSING [cc [...args] ]`,
      `UNEXPECTED [grep ]`, `MISSING [Ctrl-R ]`, `UNEXPECTED [grep ]`,
      `MISSING [jump_mode z NONE]`, `UNEXPECTED [copy_mode a NONE]`,
      `MISSING [keys DownArrow SHIFT|CTRL]`, `UNEXPECTED [keys LeftArrow
      SHIFT|ALT|CTRL]`.
- [x] `bash gates/wave-status.sh --run 5` **and** `--run 3` are green,
      proving no sibling gate regressed. *Corrected 2026-08-23: this PRD's
      `verify` and this box both named wave 4, which contains none of the
      three gates* — `shell-claude.sh` and `shell-history.sh` are in wave 5,
      `wezterm-f5-tab-select.sh` in wave 3. Measured baselines: `--run 5`
      green (~55 s), `--run 3` green (~3 min 15 s). Both green after the
      change: `--run 5` `rc=0`, 54.6 s, 3 gates PASS, 0 FAIL lines; `--run 3`
      `rc=0`, 3 min 7 s, 11 gate commands PASS, 0 FAIL lines — including
      `PASS  wave 3 gate: bash tests/nvim-telescope.sh --headless`, so the
      red spec02 called pre-existing does not exist. Wave 3's registry row
      grew from 11 gate commands to 14 at 16:10:21, mid-run, as a concurrent
      lane registered `tests/nvim-treesitter.sh`; this `rc=0` therefore
      covers the 11 that were registered when the run began, this node's gate
      among them.

## Out of scope
- The cosmetic label at `tests/nushell-aliases.sh:347,350`, which reads "the
  four managed nushell files" over a list-driven `diff`. The check stays
  honest if the list grows; only the prose starts lying. Worth a word if that
  gate is opened for another reason.
- Any count already in the durable form. The census named those as the
  patterns to copy: `tests/help-content-model.nu` carries **no** count
  literal at all, `gates/audit-findings.sh` uses per-id `-eq 1` and a `-ge 40`
  floor, and `gates/tree-links.sh` was already repaired away from absolute
  link counts.

## Orchestrator notes, 2026-08-23

**A "pre-existing red" the analyst recorded is a false alarm, and that matters
more than the alarm.** Its spec02 tells the implementer not to chase
`tests/nvim-telescope.sh --headless` exiting 2 on a bash syntax error at line
951 with 8 further FAILs. I checked, because a note saying "ignore this red"
is the dangerous direction for a note to be wrong in:

```
$ bash -n tests/nvim-telescope.sh          → exit 0
$ bash tests/nvim-telescope.sh --headless  → exit 0, 0 FAIL
```

The gate is clean. The analyst read it **mid-write**, while
[`03-editor/08-telescope`](../../../03-editor/08-telescope/prd.md)'s
implementer was still landing it. So the implementer of this node must **not**
treat any wave-3 red as pre-existing on that note's authority — if a red
appears, verify it.

**A fifth instance the census missed**, out of this node's footprint and worth
its own node: `tests/wezterm-tab-content-state.sh` carries the same literal
over the same dump plus two more of the shape, in its cross-node regression
block — `:271` `jump_mode … -eq 36`, `:274` `act.Nop … -eq 27`, `:277`
`copy_mode … -eq 55`. That file belongs to T.6. Filed as
[`tab-state-count-tripwires`](../tab-state-count-tripwires/prd.md).
