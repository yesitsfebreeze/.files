---
state: done
priority: 15
est:
mode: afk
needs:
verify: "bash gates/wave-status.sh --validate"
complexity: 20
blast-radius: mid
origin: derived
from: 04-shell/10-litellm-launcher
claim:
---

# `S.10`'s gate is committed and registered nowhere, so the registry's own validation is red

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: `gates/waves.tsv` names no row for **`S.10`**
([`04-shell/10-litellm-launcher`](../../../04-shell/10-litellm-launcher/prd.md)),
and its gate `tests/shell-litellm.sh` is committed but referenced by nothing.
Measured 2026-08-28, `bash gates/wave-status.sh --validate` → `EXIT=1`:

```
FAIL  registry: every board task appears in a wave row (missing: S.10)
FAIL  registry: every script under tests/ is named by a row
      (unreferenced: shell-litellm.sh)
```

`grep -n "S\.10\|litellm" gates/waves.tsv` returns **nothing**. Both files are
clean in git, so this predates the round that found it: `S.10` landed at
`0b77a71` with its gate, and the registry row was never added.

**The consequence, and it is the reason this is a node rather than a memo.**
The registry exists so that "every landed node has a registered gate" is a
checkable claim. For `04-shell/10-litellm-launcher` that claim is **false
today**, and `tests/shell-litellm.sh` is therefore never run by
`just gates` — the one command the delivery epic points at for the whole set.
A node whose gate no sweep executes is a `done` node whose proof is not wired
up, which is the property this family of corrections exists to protect.

It also makes `bash gates/selftest.sh` exit 1, so any node that treats a green
`selftest` as a precondition reads a red as a green.

**Found while collecting `06-help/05-agent-interface`**, whose implementer hit
it running the repo gates over its own footprint and reported it rather than
fixing it. Nothing in that node's footprint touches either file.

## Requirements
- [x] **R1** — `gates/waves.tsv` gains the row that registers
      `tests/shell-litellm.sh` against `S.10`, in the wave the dependency
      graph actually puts it in. Read the wave off the node's `needs:` and the
      existing rows' shape; do not guess a wave to make the validation pass.
      Wave **5**, argued from the graph and not from convenience:
      `04-shell/10-litellm-launcher`'s `needs:` holds one edge,
      `04-shell/08-claude-launchers` = `S.8`, and `S.8` is in wave 5. The
      alternative, wave 6, is measurably worse — the same `--matrix` run
      shows `6      PENDING  0/3      1 registered`, and `wave-status.sh`
      runs a PENDING wave's gates but does not fail on them, so registering
      there would have turned `--validate` green while leaving the gate
      unable to fail the sweep. Wave 5 reads `ARMED 6/6` after the addition,
      so the gate genuinely gates. One changed line
      (`git diff --numstat` → `1	1	gates/waves.tsv`).
- [x] **R2** — `bash gates/wave-status.sh --validate` exits 0 with both
      assertions still saying something true, tally quoted not asserted.
      Run 2026-08-28, `EXIT=0`, seven of seven PASS — the two that were red
      quoted from the output:
      `PASS  registry: every board task appears in a wave row (missing: none)`
      and `PASS  registry: every script under tests/ is named by a row
      (unreferenced: none)`. That they say something true is shown by
      counterfactual, not assumed: against the pre-fix registry
      (`git show HEAD:gates/waves.tsv`), `wave-status.sh --selftest
      --registry` exits **1** on `FAIL  baseline: the real registry validates
      against a board copy`, while the same command on the live registry
      exits 0 with all 20 lines PASS.
- [x] **R3** — `bash gates/selftest.sh` exits 0, or the remaining reason it
      does not is named here and shown to be a different fault from this one.
      It exits **1**, and the reason is named. The reproducible red is
      `FAIL  contract: tree-links.sh accepts --selftest and exits 0 (rc 1)`,
      whose two inner failures are `FAIL  fail-closed: the prd.md marker
      exempts nothing — the exempt count stays 9` and `FAIL  green: the real
      tree's exemptions are exactly 9 links in 4 files`, against a live
      `bash gates/tree-links.sh` (rc 0) reporting `exempt 13 links in 5 files
      (target-file-vantage)`. Re-measured today and the count has not moved
      since this node was filed: still 13 in 5 against a pin of 9 in 4. It
      is a stale pin in another gate's selftest and cannot be this node's
      fault — `grep -n waves.tsv gates/tree-links.sh gates/tree-links.py`
      prints nothing and exits 1, so no registry row can move that count.
      Per Out of scope it is not fixed here.

      One further red appeared in each of two runs and is a **concurrency
      artifact**: at 13:26 `FAIL  contract: retired-phrases.sh wrote nothing
      outside its scratch`, at 13:31 the identical failure attached to a
      different gate, `FAIL  contract: wezterm-config-fields.sh wrote nothing
      outside its scratch` — both preceded by the same line, `changed:
      /Users/feb/dev/dotfiles/tests/help-agent.sh`. A failure that migrates
      between two unrelated gates while naming one constant file is a
      concurrent lane editing `tests/help-agent.sh` inside the sha256 window
      (`stat -f '%Sm'` → `Aug 28 13:26:22`, mid-run), not either gate writing
      outside its scratch.
- [x] **R4** — **Sweep for the same class rather than fixing the instance.**
      `S.10` was missed because nothing failed loudly when its row was
      omitted. Check every `done` node with a `tests/` gate for a registry
      row, and report the count — if `S.10` is the only one, that is worth
      knowing; if it is not, the others are the same defect. Swept over all
      67 `done` nodes: **B = 0, `S.10` was the only one of its class.** The
      sweep also turned up C = 2, D = 2 and E = 20, and — the part worth more
      than the count — that `--validate` cannot detect a mispaired registry
      at all. Full table and method under [Census](#census).

## Acceptance
- [x] `bash gates/wave-status.sh --validate` exits 0, both previously failing
      assertions quoted as passing. Run 2026-08-28 — see R2 for the seven
      quoted lines and the pre-fix counterfactual that exits 1.
- [x] `tests/shell-litellm.sh` runs as part of its wave's sweep, shown by the
      sweep's own output naming it — not by the row existing.
      `bash gates/wave-status.sh --run 5` exits 0 over 614 lines opening
      `══ wave 5 — ARMED 6/6 ═══`, and the sixth gate it runs is the new one:
      `── wave 5: bash tests/shell-litellm.sh (external — owned by another
      node, …)` followed by `PASS  wave 5 gate: bash tests/shell-litellm.sh`.
      The row is also shown to be load-bearing rather than decorative: on a
      scratch copy of `prds/` with `S.10` flipped to `state: open`,
      `--matrix --board <scratch>` reports `5      PENDING  5/6`, so the
      tasks cell is genuinely read.
- [x] The census from R4 is written down, whatever number it comes to — see
      [Census](#census) below, table and all, including the four findings
      that are not this node's to fix.

## Out of scope
- The content of `tests/shell-litellm.sh`. It is committed and passes; this is
  about the registry never naming it.
- Every other assertion in `wave-status.sh --validate`. The other four pass.

## Census

R4 asked how many other `done` nodes carry `S.10`'s gap. Re-running
`wave-status.sh --validate` could not answer it: its two assertions are
exactly the two that were red, so after the fix they report zero by
construction. The probe is
`prds/00-delivery/corrections/waves-registry-missing-s10/census.py`, which
walks the **pairing** — each `done` node against the wave row naming *its own*
gate — a relation nothing on this board checks.

Measured **2026-08-28**, live tree with the wave 5 row applied, by
`python3 prds/00-delivery/corrections/waves-registry-missing-s10/census.py`
(exit 0). The population is every node under `prds/` whose frontmatter carries
both `task:` and `state: done`, enumerated before the answer was known and
with no-gate nodes counted rather than filtered out, because "no gate" is the
same defect one step earlier. The denominator is confirmed independently:
`grep -l '^state: done' $(find prds -name prd.md) | xargs grep -l '^task:' |
wc -l` → 67.

| class | count | what it means |
|---|---|---|
| population | 67 of 71 `task:` nodes are `done` | the denominator |
| A | 44 | gate registered against its own wave row |
| B | **0** | `S.10` was the only node whose gate no row named |
| C | 2 | `W0.8`, `W0.9` — both verify with `tests/deploy-skeleton.sh`, registered in wave 1 while their tasks sit in wave 0 |
| D | 2 | `W0.4d`, `W0.4b` — real, runnable `verify.sh` scripts under `prds/`, named by no row and run by no sweep |
| E | 20 | `verify:` names no script: 18 empty, `G.1` self-referential (`just gates`), `S.7` prose (`quicklist round-trips a pick (wave-5 gate)`) |

**The finding is not the row, it is what `--validate` cannot see.** Its
assertion 1 says every board `task:` id appears in *some* row's tasks cell;
its assertion 6 says every script under `tests/` is named by *some* row's
gates cell. The two are independent set-coverage checks and **nothing ties a
node to its own gate**, so a mispaired registry is invisible to it. Proved on
three distinct pairs rather than argued:

- `S.10` / `shell-litellm.sh` (`census.py --selftest`, exit 0) — dropping the
  gate from every row raises B 0 → 1; *moving* it to wave 1 while `S.10`
  stays in wave 5 raises C 2 → 3 and `--validate` **stays exit 0**.
- `E.3` / `nvim-keymaps.sh` moved from wave 3 into wave 0 — C = 3,
  `--validate` exit **0**.
- `S.9` / `theme-switcher.sh` dropped from every row — B = 1, `--validate`
  exit **1**.

Dropping a gate is caught; moving it to a wave that has nothing to do with
its node is not, even though the gate then arms on the wrong wave. Class C's
two live members, `W0.8` and `W0.9`, sit in exactly that state today.

**Why `S.10` slipped, since B = 0 makes it one event rather than a pattern.**
`0b77a71` landed the node and `tests/shell-litellm.sh` across 36 files and did
not touch `gates/waves.tsv`. That node's own Provenance says it was built
ahead of the board at the user's direction — "code now, PRD after" — so it
skipped `open → specced → claimed`, and the registry row a spec's footprint
would have carried was never written by anybody. The mechanism is a skipped
board transition, not a silent check.

C, D and E are **reported, not fixed** — they are other lanes' frontmatter and
other rows, and R4 asked for the count.
