# 02-board — implementer report (pass two)

Verdict: DONE

Pass one built R1–R5 and left one mechanical piece: three sibling `specs/`
directories it could not remove because those PRDs were `claimed` mid-flight.
All three are `state: done` now. This pass removed them, plus this node's own
`specs/`, and re-measured every acceptance box rather than inheriting it.

Numbers: **4 `specs/` directories removed (10 files, 51,728 bytes)**; `find
.pearde/prds -type d -name specs | wc -l` → **0**; `du -sh .pearde/prds` →
**3.2M**; repo gate (`just board-guard-blocks`) → **exit 0, silent**;
requirements **R1–R5 `[x]`, R6 `[ ]` on a false premise**; acceptance
**5 of 6 `[x]`, one box unclosable and named below**.

## What this pass did

`git rm -r -f` on `09-simplify/{01-hygiene,03-help-system,07-provisioning}/specs`
(9 tracked files) and `rm -r` on `09-simplify/02-board/specs` (1 untracked
file, this pass's own brief, removed last). Byte counts recorded before the
removal:

| path | bytes |
|---|---|
| `01-hygiene/specs/spec01.md` | 4875 |
| `01-hygiene/specs/spec02.md` | 7536 |
| `03-help-system/specs/spec01.md` | 4455 |
| `03-help-system/specs/spec02.md` | 5388 |
| `03-help-system/specs/spec03.md` | 9487 |
| `03-help-system/specs/spec04.md` | 4728 |
| `07-provisioning/specs/spec01-brewfile-and-installer.md` | 4542 |
| `07-provisioning/specs/spec02-run-after-and-dockerfile.md` | 3779 |
| `07-provisioning/specs/spec03-internals-provisioning-page.md` | 3545 |
| `02-board/specs/spec01-cleanup.md` | 3393 |

One line changed in `AGENTS.md`: the where-things-live table named a
`cutover` justfile target that `just --list` does not list. It now reads
`push`, `manual`, the two board-guard targets — the recipes that exist.

## Acceptance, box by box

| box | ran | result |
|---|---|---|
| `find … -name specs \| wc -l` prints 0 | yes | `0` — `[x]` |
| `grep -rlE 'verify: …' \| wc -l` prints 0 | yes | `2` — `[ ]`, see below |
| memos = 6, `memo check` silent | yes | `6`, check printed nothing, exit 0 — `[x]` |
| `wc -l AGENTS.md` ≤ 80, `Corrected 20` = 0 | yes | `63`, `0` — `[x]` |
| `prd.md` count unchanged | yes | `208` worktree, `208` HEAD — `[x]` |
| `du -sh .pearde/prds` < 3.5 MB | yes | `3.2M` — `[x]` |

## Findings

1. **The `verify:` acceptance box cannot pass, and R2 is met anyway.** The
   box's command is unanchored and runs over every file, so it matches body
   prose *quoting* a `verify:` value as readily as a frontmatter field. Both
   hits are quotations in a historical narrative —
   `00-delivery/wave-registry-keying` line 129 and
   `00-delivery/corrections/gate-reconciliation` line 105. Rewriting either
   would falsify the record of what those nodes carried, and both are
   outside this node's PRD anyway. The counter that answers R2 is
   `grep -rlE '^verify: "?[^"]*(tests|gates|docs-site)/' .pearde/prds --include=prd.md | wc -l`
   → `0`. Two honest counters, written down beside their numbers, per the
   workflow's step-1 `Fails when`. **The box is left `[ ]` with the
   replacement command in its body; changing an acceptance command is the
   orchestrator's call, not the implementer's.**

2. **R6's premise is false in three separate ways** — confirmed
   independently of pass one. `grep -rl '^state: open' .pearde/prds
   --include=prd.md` returns exactly one path, the board root
   `.pearde/prds/prd.md`; there are not "three open nodes outside this
   epic". The path R6 names,
   `00-delivery/finish-line/done-node-proof-gate`, does not exist — the node
   is `00-delivery/corrections/done-node-proof-gate`, and it is already
   `state: deferred` carrying the pearde-tooling line at line 20.
   `00-delivery/corrections/pearde-shell-wiring` is `state: done`, so
   deferring it would undo a landed node. Per the workflow, a premise that
   does not reproduce is a finding and the requirement is not implemented:
   **nothing was edited to fit R6**, and the box stays `[ ]` with the
   measurement in its body.

3. **One uncommitted local modification was destroyed, deliberately, after
   proving the knowledge survives it.** `01-hygiene/specs/spec02.md` carried
   a 14-line uncommitted correction (`! git check-ignore …` cannot fail
   under `set -e`; the working form is `cmd && exit 1`). `git rm` refused it
   without `-f`, which is the last warning before live work is lost. The
   fact is on the knowledge base at `[[260902-f116]]` ("a bang-prefixed
   assertion is exempt from set -e, so it cannot fail a verify"), and
   `01-hygiene` is `state: done` and committed at `b5268a2`, so the only
   thing lost was a second copy. Forced.

4. **The knowledge check on the ten deleted specs found nothing to move.**
   Grepping them for `TRAP` and `measured` surfaced two carriers.
   `07-provisioning/spec02` says the three-line TRAP header is kept verbatim
   *in the script itself*, so it is already where it belongs.
   `03-help-system/spec04` line 69 carries the real one — a recreated
   chezmoi target is `M`odified, so `.chezmoiremove` asks a TTY and dies
   `could not open a new TTY` with none; read `chezmoi status` for `D`, or
   pass `--force`. It survives in two kept files:
   `03-help-system/report.md` line 82 and `03-help-system/probe/verify.sh`
   line 110. Nothing was moved because nothing needed moving.

## Defects outside this node's footprint — reported, not fixed

- **The shipped manual points at two deleted spec files.**
  `home/dot_config/nushell/help/manual/internals/nushell-modules.md` lines
  17 and 108 say "See prds/04-shell/01-core-config/specs/spec01.md" and
  "…/spec02.md". Pass one deleted both. These are dangling pointers in a
  page a person reads with `?`. Footprint is `home/`, not mine.
- **`.pearde/wiki` holds 357 dangling spec wikilinks across 155 files.**
  The wiki is generated; a regeneration clears them. Not in this node's
  footprint.
- **`scripts/board-guard.py` lines 101–106 walk `specs/` and are now dead.**
  Guarded by `os.path.isdir`, so it goes silent rather than breaking — which
  is exactly why a wrong deletion would not have shown up there. Harmless
  today; a candidate for deletion when `scripts/` is next in a footprint.
- `docs/simplification-plan.md` still quotes the pre-deletion spec counts.
  Explicitly out of scope — the last child of this epic deletes the file.

## Workflow delete-what-nothing-reads

| step | atomic | ran | outcome |
|---|---|---|---|
| 1 | `measure-the-premise-not-the-prd` | yes | 6 requirements, each with a command and its output. R1–R5 measure the *result* of pass one, not the premise — flagged per the atomic's first `Fails when` and re-measured on the survivors. R6's premise did not reproduce (finding 2). The spec's own claim that `find … -name specs` prints 3 measured 4 — its counter excluded this node's own `specs/`. |
| 2 | `prove-nothing-reads-it` | yes | Whole-tree grep for `specs`, every hit classified. Readers: `scripts/board-guard.py` (guarded, tolerates absence). Mentions: `docs/simplification-plan.md`, 4 memos, `.pearde/wiki` (generated), `internals/neovim.md` (lazy.nvim plugin specs, unrelated). `chezmoi managed \| grep -c specs` → `0`: no deployed target. No back-edge taken. |
| 3 | `run-the-surface-that-consumed-it` | yes | `just --list` → 5 recipes, none names a spec. `just board-guard-blocks` → exit 0, silent (it is the surface that walks `specs/`). `workflows.py list .pearde` → 6 workflows, 16 atomics, unchanged. `plan.py plan` → `6 PRDs · workers=3 · 1 parked`. All clean; no surface names a deleted thing. No back-edge taken. |

### Edits

Two shapes the atomics' `## Fails when` does not list, both hit in this run.

**`prove-nothing-reads-it` — its `## Fails when` is empty. Add:**

> - The file to delete carries an **uncommitted local modification**, and
>   `git rm` refuses it. That refusal is the last warning before live work is
>   destroyed, not an obstacle to `-f` past. Read the diff, then prove its
>   content survives elsewhere — a knowledge-base note, a kept `report.md`, a
>   probe script — and say where, in the report, before forcing. A byte count
>   is not enough here: the question is whether the *knowledge* has a second
>   home, not whether the file did.

**`run-the-surface-that-consumed-it` — add to its `## Fails when`:**

> - The consumer guards its read (`if os.path.isdir(specs):`,
>   `[ -d … ] &&`). Then the surface runs clean whether the deletion was
>   right or wrong, and "it runs clean" proves nothing. Read the consumer's
>   source for the guard before trusting its silence, and say in the report
>   that the surface is guarded — otherwise a green run is recorded as
>   evidence it cannot be.

Also, for the record rather than as an edit: step 1's second `Fails when`
(two honest counters disagreeing on the same class) fired exactly as written,
on the `verify:` box in finding 1. Writing the counter beside the number is
what made the disagreement legible instead of a failed check.

## Vocabulary

No term was needed that `grammar.py show` does not define.

## Knowledge

No fact was learned outside this repo. The one external fact this run leaned
on — `!`-negation is exempt from `set -e` — was already on record at
`[[260902-f116]]`; nothing new was enqueued.
