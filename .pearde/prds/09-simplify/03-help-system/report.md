# 03-help-system — implementer report

Verdict: DONE

All four specs verified; `probe/verify.sh` green twice with identical output,
and non-zero at the right line under three deliberate falsifications. Boxes in
`prd.md`: **15 `[x]`, 1 `[~]`, 0 open**. `help.nu` 198 lines, 113 entries,
`internals/help.md` 691 → 314, `help/README.md` 366 → 64.

| spec | subject | state |
|---|---|---|
| spec01 | one `help`, no checker, no second picker | `spec01 OK` — stood from pass one, re-verified |
| spec02 | corpus carries content, not bookkeeping | `spec02 OK` — stood from pass one, re-verified |
| spec03 | internals stop describing machinery that is gone | `spec03 OK` — **the bulk of this pass** |
| spec04 | deletions leave the machine, not just the repo | `spec04 OK` — net-new `home/.chezmoiremove` |

Per-box proof is in each spec's `## Acceptance`, quoted where I ran it.

## Workflow cut-a-feature-its-readers-still-name

| # | step | outcome |
|---|---|---|
| 1 | measure-the-premise-not-the-prd | Pass — its own `Fails when` case. R1–R7's premises were already acted on by pass one, so the commands measured the *result*; measured the survivors instead and named the pass. R8's premise reproduces exactly: 7+2+3+9+4+5 = **30** citations across six files. |
| 2 | prove-nothing-reads-it | Pass. Whole-tree grep for the four retired basenames: every remaining hit is in `docs/simplification-plan.md`, `.pearde/wiki` or a PRD — mentions, not readers. The one code-shaped reader left was `internals/help.md`, which spec03 rewrites. `chezmoi managed` lists no `cable/manual.toml`. |
| 3 | carry-the-why-across-the-rewrite | Pass. Listed the constraint comments in the 691-line `help.md` before cutting; all four load-bearing ones re-lodged and grep-confirmed (`use std/help`, `path join ".config"`, `no custom bindings`, `ls --help`). Constraints whose mechanism died are deleted **with a line saying so** — the corpus-row-index rule and the `--delegate` escape hatch both carry a dated sentence. No comment in the new file names a def the same change deleted (11/11 quoted `def` blocks verbatim in `help.nu`). |
| 4 | regenerate-every-derived-surface | Pass. `just manual` → `reference: 9 pages, 113 entries`. Snapshot, re-run, `diff -r` silent on `guide/` and `reference/` — generation is a fixed point. No generated page carries a removed string. |
| 5 | apply-scoped-not-bare | Pass. `chezmoi diff` read first; the three `home/run_after_*.sh` entries rendering as new files at `$HOME` root are the atomic's documented alarm, not a defect — left alone. Applied by naming `~/.config/nushell`, `~/.config/television`, `~/.config/nvim`; those paths now diff clean and the three run-scripts are still pending, exactly as before. |
| 6 | prove-in-a-shell-that-loaded-the-config | Pass. Both forms in `probe/verify.sh`: the explicit `--env-config`/`--config` pair, then `tmux new-session -d -s helpprobe nu` with 6 s / 8 s waits. Success shapes matched **positively**; `tmux` absent now *fails* the probe rather than skipping quietly. |
| 7 | check-what-apply-left-behind | Pass, and it caught something. All four deleted files were absent — but only because pass one removed them by hand. The retirement now has a repo mechanism, `home/.chezmoiremove`, proven by falsification rather than by their prior absence. |
| 8 | run-the-verify-twice | Pass, and it caught the defect it exists for. See below. |

### Edits

Nothing in the workflow files misfired: every atomic's `Do` was runnable as
written, and the two `Fails when` clauses that fired (step 1's already-acted-on
premise, step 5's `run_after_*` alarm) described what happened accurately. One
addition worth folding into step 8, because it cost the most here:

**`run-the-verify-twice` → `Do` 2, an addition.** The rule says write negatives
as `if cmd; then echo FAIL; exit 1; fi`. It is worth naming the *silent* half:
a `! cmd` that fails does not merely skip errexit, it is **swallowed entirely
whenever any command follows it** — and a verify block almost always ends in
`echo "VERIFY OK"`. Suggested replacement text for the second bullet:

> 2. Read every negative assertion: `! cmd` is exempt from `set -e`, and
>    `grep -c` exits 1 on a count of 0, so both can report success on a
>    violation or failure on the correct state. `! cmd` is worse than it
>    looks: its non-zero status is discarded by the next command, so a block
>    ending `echo "VERIFY OK"` prints OK and exits 0 with every negative
>    violated. Measured 2026-09-02 — `set -e; ! true; echo "VERIFY OK"` prints
>    VERIFY OK and exits 0. Write them as
>    `if cmd; then echo FAIL; exit 1; fi`.

## The verify block was passing on nine violated assertions

`probe/verify.sh` as pass one left it carried nine `! rg -q …` assertions and
ended in `echo "VERIFY OK"`. POSIX exempts a `!`-negated command from `set -e`,
and its status is then discarded by the next command — so **the block would
have printed VERIFY OK and exited 0 with every one of the nine violated.**
Confirmed on a two-line reduction: `set -e; ! true; echo "VERIFY OK"` → `VERIFY
OK`, exit 0.

Rewritten with `fail()` and `if cmd; then fail …; fi` throughout, extended to
cover spec03 and spec04, and given the step-6 shell checks. Falsified three
ways, each failing at its own line and returning to green:

| planted violation | result |
|---|---|
| a `tests/` citation appended to `capsule.md` | `FAIL: a tests/gates/docs-site citation survives` |
| `~/.config/nushell/help/use-review.nuon` recreated | `FAIL: …/use-review.nuon is still deployed` |
| a `def _help_ghost` block quoted in `help.md` | `FAIL: help.md quotes a def that is not in help.nu` |

## `.chezmoiremove` was proven by falsification, not by absence

The four retired files were already gone (pass one removed them by hand), so
spec04's verify block passed on a mechanism it never exercised. Recreating
`~/.config/television/cable/manual.toml` and re-applying gave `REMOVED —
.chezmoiremove fires`.

**A trap worth more than the box.** A recreated target is `M`odified relative
to what chezmoi last wrote, so chezmoi asks a TTY before removing it and dies
`could not open a new TTY` where there is none. My first attempt sent stderr to
`/dev/null` and read the surviving file as "the mechanism did not fire" — a
false negative that would have condemned a working file. **Read `chezmoi
status`:** `D` in the second column says the removal is armed regardless of
whether a prompt let it run. `--force` clears the guard non-interactively.

The file is written bare, with no comment header, because spec04's own verify
block forbids one: `grep -c .` counts comment lines toward its `-eq 4`, and
`grep -q 'dot_'` matches the words "dot_ prefix" in any prose explaining the
rule. The why is therefore in spec04, not in the file.

## Two checks were deleted rather than reworded

`unverified.md` keeps its list; R8's "loses the gate vocabulary" took two rows
with it, because both name a command this change deleted and so could never be
run:

- **H.4's completeness proof** — "`help --check` exits 0 … the closest thing
  this build has to a completeness proof". The spec named this one.
- **G.1** — "prove each gate by introducing its violation and watching it
  fail … run `just gate-selftest`". Same shape, unnamed by the spec: the gates
  and that recipe were deleted on 2026-08-31. It was Wave 0's only row, so the
  heading went with it.

A third H.4 row was a signpost ("the fresh-machine run, below"), not a check.
The one real survivor, `ls --help` on a fresh machine, is re-keyed to **H.2** —
the node that actually owns the `--help` delegation.

## Three things the specs' verify blocks could not have passed as written

1. **`index.md` failed its own last assertion.** `for f in $I/*.md; do rg -qF
   "$(basename $f)" $I/index.md` iterates over `index.md` too, and the index is
   the one page that cannot sensibly link to itself — it was `UNLISTED`.
   Resolved by a paragraph that names the file while saying something worth
   saying: `index.md` and every page it lists are hand-written, `guide/` and
   `reference/` are generated and cannot drift, so nothing but a person
   corrects these.
2. **`rg -q 'H\.4'` cannot tell a live check id from prose recording its
   retirement.** Writing down *which* id was retired would have failed the
   check. Resolved by naming the retired node by its path,
   `06-help/04-drift-check`, which is what the letter was always shorthand for.
3. **spec03's `sh` block is not machine-extractable.** Its Python contains a
   literal triple-backtick, so fence matching truncates the block at
   `re.findall(r'`. It runs correctly when transcribed; only automatic
   extraction breaks. Suggested fix for a future spec: build the fence as
   `chr(96)*3` rather than writing it literally inside a fenced block.

## The PRD's own acceptance had one more wording defect

`nu -l -c 'help --check'` was to fail with **"unknown flag"**. nushell 0.115.1
answers `` the `help` command doesn't have flag `check`. `` under a
`nu::parser::unknown_flag` banner — "unknown flag" is the error's *code*, never
its text, so a probe grepping that literal fails on the correct state. Asserted
as `doesn't have flag`. Same family as the workflow's own warning about
grading a missing alias OK.

## Findings outside my scope — reported, not fixed

1. **`just board-guard-blocks` is red, on two other nodes.** Five lines in
   `09-simplify/01-hygiene/specs/spec01.md` (`git reset`, `git add --all`,
   `git commit`) and `00-delivery/corrections/ls-icons-glyphs/specs/spec03.md`
   (`git stash push`/`pop`) act on the repo instead of asserting its state.
   None of this node's specs is named; my footprint passes `board-guard`.
2. **`internals/wezterm.md` carries a near-duplicate block.** Lines ~75–81
   hold two paragraphs saying the same thing ("THE RESERVE IS ZERO SINCE
   2026-08-30" and "THE RESERVE IS AN ARGUMENT SINCE 2026-08-30"), each
   followed by an identical "What changed:" paragraph and an all-but-identical
   "The old text said the reserve…" paragraph. I removed the citations from
   both and left the duplication: merging is a content decision outside a
   citation pass.
3. **`unverified.md`'s count line was false.** It read *81 checks still open
   across 7 waves*; the file held **84**. Fixed inside my footprint — it now
   says 81 across 6 waves, computed from the file and saying what it replaced.
   Worth flagging as a class: this is the stale-number shape AGENTS.md records
   six corrections of, found inside the file whose subject is unverified
   claims.

## Health floor

The one file named under the floor, `home/dot_local/bin/executable_tv-all`
(28, "longest, branching"), was already cut by pass one: the `manual` lane, its
`_key` helper and its `LANES_FAST` slot are gone, which removes one branch and
one function from the longest path. Nothing further was in this spec's scope —
the remaining length is the other lanes, and touching them is
`09-simplify/06-neovim-television`'s footprint, not mine. `sh -n` clean.

## Vocabulary

No term in the contract was undefined for me, and I coined none. One word I
reached for that `grammar.py show` does not define: a name for **a check that
names a command the same change deleted** — an assertion that is not merely
failing but unrunnable. "Dead check" is what I used in the spec and here. It is
distinct enough from a failing check to be worth a row, since the correct
action differs: a failing check is investigated, a dead one is deleted.
