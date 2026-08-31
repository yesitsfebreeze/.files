---
est: 0h            # DELIVERED 2026-08-23 — see the note below
footprint:          # report-only: this spec writes no file in the repo
---

# spec03 — the census of the other contract-held gates, and the wave-0 line

> **Delivered 2026-08-23 and accepted.** The BLOCKED implementer completed
> both halves: the seven-gate census (each verified against its `selftest()`
> entry line) and the wave-0 segment, with `gates/waves.tsv` md5 identical
> before and after and `grep -c 'retired-phrases'` → 0. `est` is set to **0h**
> so the node's total does not double-count it. Retained as the record; the
> registration itself stays held until `--selftest` exits 0. The
> `nushell-module-staging.sh` finding was confirmed by the orchestrator and is
> filed as `staging-gate-vacuous-green` — **do not touch that file here.**

Two report-only deliverables. This spec **writes nothing**: its whole output is
the implementer's report, and its footprint is empty on purpose so it can never
collide with the lane holding `gates/waves.tsv`.

## Part 1 — R5: the same shape, elsewhere

The defect class is *a `--selftest` whose fixture is the live tree*. It has two
symptoms, and only one of them is loud:

- **inverted** — asserts the tree is broken; the tree gets repaired; false red.
  That is CF12.
- **vacuous** — asserts it can repair the tree's brokenness; the tree gets
  repaired; the repair becomes a no-op and the half quietly stops testing.
  Silent, and therefore worse.

Seven scripts are held to the contract. The census below was measured
2026-08-23; the implementer's job is to **verify each line** (the commands are
given) and report it, correcting anything that does not reproduce.

| gate | verdict |
|---|---|
| `gates/audit-findings.sh:178` | Clean, and the model to copy. Its green half (`:232-243`) makes the copy red with its own `strip_id_everywhere` mutation before asserting red. One tolerant live-tree floor at `:189` — `test "$n" -ge 40` findings — a floor, not an equality, and it fails loudly. |
| `gates/manual-coverage.sh:146` | Clean. Its `baseline: the checklists as written pass` reads the live `gates/manual/`, but in the **green** direction: it reds exactly when the gate itself would red, which is a true red, not an inversion. Every other half copies the checklists and mutates the copy. |
| `gates/nushell-module-staging.sh:280` | **Defective — vacuous, already.** Details below. |
| `gates/probes.sh:113` | Clean. Reads only `gates/fixtures/` (nu, nvim, wezterm) plus counter-fixtures it writes itself (an empty `init.lua`, a keys-stripped `wezterm.lua`). No live-tree dependence at all. |
| `gates/tree-links.sh:27` | Clean in structure — every assertion is relative to a baseline it computes itself (`base="$(count_a "$S")"`). One mild live-tree fixture dependence at `:68`: it requires the wrapped link `TTY(../../../../../../prds/00-delivery/corrections/phrase-sweep-selftest-inversion/04-shell/04-television/prd.md)` to still be in `prds/06-help/prd.md`. Re-wrapping or retargeting that link reds the selftest for tree reasons — but it fails loudly and names itself a precondition, which is the acceptable form. |
| `gates/wave-status.sh:265` | Clean, and the strongest shape on the board: the arming halves run on a synthetic two-node board it writes itself. Its `baseline: the real registry validates` is green-direction, like manual-coverage. Shares tree-links' mild dependence at `:337` (`grep -n '\[tv needs a$' prds/06-help/prd.md`, asserted non-empty). |
| `gates/retired-phrases.sh:586` | The subject of this node; fixed by spec01 and spec02. |

### The nushell-module-staging finding, with its evidence

Its GREEN half (`:305-318`) repairs **a real miss on the live tree** —
`tests/shell-television.sh` not staging `help.nu` — in a copy, then asserts the
gate is green. That miss was fixed on the live tree by
`00-delivery/corrections/television-help-staging` (`done`).
`tests/shell-television.sh:471` now reads:

```
  for m in dirstack pass theme claude zoxide history capsule finder copymode help; do
```

so the repair `sed -E 's/^([[:space:]]*for m in [a-z ]*copymode)(; do)/\1 help\2/'`
no longer matches and is a **no-op** — and the check that is supposed to catch
exactly that, `selftest GREEN: the repair really landed in the copy`, passes
anyway, because it greps for the *end state* (`for m in .*copymode help; do`)
which the unmutated live file already satisfies. Both halves PASS, the gate
exits 0, and the green counterfactual proves nothing. Reproduce with:

```sh
grep -n 'for m in' tests/shell-television.sh
bash gates/nushell-module-staging.sh --selftest 2>&1 | grep GREEN
bash gates/nushell-module-staging.sh > /dev/null 2>&1; echo "live rc=$?"   # 0
```

This is **out of scope to fix here**: `gates/nushell-module-staging.sh` is not
in this node's footprint and widening it would put two writers on a file this
node has no claim to. Report it and recommend a sibling correction node; the
fix is the same port — construct the miss in the copy (add a `source` line the
copy's gates do not stage, or remove `help` from the copy's loop) instead of
borrowing the tree's.

## Part 2 — the wave-0 registration line

`gates/waves.tsv` is **orchestrator-owned and currently held** by the lane on
`03-editor/12-small-plugins` — `git status` shows it `AM`, staged with unstaged
edits. Do not touch it, and do not report a whole verbatim line for the
orchestrator to paste: the other lane may have rewritten wave 0's cell by the
time this node transitions. Report the **segment** instead.

Wave 0's `gates` cell is a `|`-separated list. The registration is one segment
appended to the end of that cell:

```
 | bash gates/retired-phrases.sh
```

For reference, wave 0's row as it read at spec time (`md5 gates/waves.tsv` =
`b1f150ede6fb4f94d8b53be571987b71`), tabs between the three fields:

```
0	W0.1 … D.1d	bash gates/tree-links.sh | bash gates/audit-findings.sh | bash gates/manual-coverage.sh | external bash tests/live-bugs.sh | bash gates/nushell-module-staging.sh
```

The sweep belongs in wave 0 because every claim it bans was retired by a wave-0
correction, and because `gates/wave-status.sh` reds an ARMED wave whose gate
set does not cover it. It is not `external`: this node owns the script and it
signs the `--selftest` contract, which is what spec01 and spec02 restore.

## Acceptance

- [x] The census reported, **one line per contract-held gate**, seven lines,
      each verified against the gate's own source and its `--selftest` output
      rather than copied from this spec.
- [x] The `nushell-module-staging.sh` finding reproduced and quoted: the live
      `for m in …` line, the two PASSing GREEN halves, and the gate's live
      `rc=0`. If it does **not** reproduce, say so with the evidence.
- [x] A sibling node recommended for it, named and scoped in one sentence, and
      explicitly **not** implemented here.
- [x] The wave-0 segment reported as a segment, with the note that
      `gates/waves.tsv` is held by another lane and the cell must be re-read at
      transition time.
- [x] `md5 gates/waves.tsv` quoted **before and after** this node's work, with
      the caveat that a change means the other lane wrote it — the check that
      matters is that this node's own diff names no `gates/waves.tsv` hunk.
- [~] **Half provable, and the unprovable half is the finding.**
      `git status --porcelain gates/waves.tsv gates/manual/` shows
      `AM gates/waves.tsv`, `A gates/manual/wave2.md` and six `??` wave files —
      all the `03-editor/12-small-plugins` lane's, `waves.tsv` stamped
      `17:46:30` against this lane's write at `21:41:50`. Attribution is by
      **content**, not by status: `md5 gates/waves.tsv` is
      `b1f150ede6fb4f94d8b53be571987b71` before and after, and
      `grep -c 'retired-phrases' gates/waves.tsv` is `0` — so this node wrote
      none of it. The second clause is **not tickable as written**:
      `git diff --stat gates/` names two files, because `waves.tsv` is one of
      the 4 tracked entries in `gates/` while being blind to the other
      nineteen — including `gates/retired-phrases.sh`, this node's entire
      footprint, which the diff cannot see at all. Owned by
      [`git-diff-integrity-boxes`](../../git-diff-integrity-boxes/prd.md).

## Verify and Proof

```sh
cd /Users/feb/dev/dotfiles

# the census: each gate's selftest entry point and its live verdict
for g in audit-findings manual-coverage nushell-module-staging probes \
         tree-links wave-status retired-phrases; do
  printf '%-28s selftest at line %s\n' "$g" "$(grep -n '^selftest()' gates/$g.sh | cut -d: -f1)"
done

# the nushell finding
grep -n 'for m in' tests/shell-television.sh
bash gates/nushell-module-staging.sh --selftest 2>&1 | grep -E 'GREEN|rc='

# waves.tsv untouched by this node
md5 -q gates/waves.tsv
grep -c 'retired-phrases' gates/waves.tsv        # still 0 until the orchestrator applies it
git diff --stat gates/
```
