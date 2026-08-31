---
state: done
claim: 
priority: 44
est: 2.75h
mode: afk
footprint:
  - gates/retired-phrases.sh
verify: ""
origin: derived
---

# The phrase sweep is green and its own `--selftest` is red

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: `gates/retired-phrases.sh` now reports **exit 0, 0 FAIL, `armed
carriers: 0`** — every retired phrase is gone from the board. And its
`--selftest` reports **exit 1, 46 PASS / 3 FAIL**:

```
FAIL  selftest: every armed claim has a per-phrase counterfactual (uncovered: RP9)
FAIL  CF12: the untouched copy is red — the six armed carriers stand
FAIL  CF12: dropping the three PENDING carriers does not change the exit status
```

Which makes `gates/selftest.sh` red, since it holds every gate to its
`--selftest` contract:

```
FAIL  contract: retired-phrases.sh accepts --selftest and exits 0 (rc 1)
      7 script(s) held to the contract · 45 external, reported not failed
```

**This was predicted at spec time and it is not a defect in the sweep.** CF12's
assertions are premised on the six armed carriers standing, and
`shell-down-spec-carriers` plus `capsule-rm-reworded-claim` repaired all six.
RP9 lost its counterfactual the same way — its retirer closed and its carriers
went with it.

**The generalisable point is sharper than the fix.** A selftest whose fixture
is *"the tree as it is today"* inverts the moment the tree is repaired — so its
red is a **success signal wearing a failure's clothes**, and the next reader
sees a broken gate rather than a finished cleanup. Every counterfactual on this
board has been careful to construct its own broken input; CF12 borrowed the
board's, and that is the difference.

**This blocks the wave-0 registration**, which is otherwise ready:
`grep -c 'retired-phrases' gates/waves.tsv` → 0, and wave 0 is ARMED and green.
The sweep cannot go in while the meta-gate is red on it.

## Requirements
- [x] **R1** — CF12 constructs its own red input: a `scratch_tree` copy whose
      baseline status it records and echoes, a precondition that the baseline
      names no FAIL line for the pair, the plant, red asserted as
      `rc != baseline` **and** as a FAIL line naming the phrase and the path,
      then the repair and `rc == baseline`. Seven chk lines, all PASS, quoted
      in [spec02](specs/spec02.md). The same relativisation was applied to
      CF9-green, CF10 and the pending half, which the orchestrator's ruling
      identified as the same defect.
- [x] **R2** — The floor asks whether a counterfactual is *available*: for
      every `ARMED` row in `--armstate` it asserts a `cf_table` row exists, and
      `cf_table` carries all eleven claims whether armed or not. Carriers are
      not consulted at all, so an armed row whose carriers are all repaired is
      covered. `PASS  selftest: every armed claim has a per-phrase
      counterfactual (uncovered: none)`, against `uncovered: RP9` on the
      pre-change script in the same session. RP9's plant now runs and is red on
      its own fixture; RP11's row exists, is skipped while its retirer is
      `open`, and was proved once out of band.
- [x] **R3** — Two arguments, one structural and one measured, and the
      measured one is permanent as CF14.

      *Structural:* no half asserts merely `rc != 0`. Each asserts a FAIL line
      naming **the phrase it planted** and **the path it planted it at**. A
      tautology — plant, repair, assert nothing about the output — cannot
      satisfy that.

      *Measured:* the matcher is blinded in a copy of this script
      (`$GREP -oFf "$pf"` → `$GREP -oFf /dev/null`) and run against CF12's own
      fixture. Real gate: `rc=1`, 3 FAILs, one of them
      `RP4 CARRIER prds/06-help/prd.md carries …`. Blinded: `rc=1`, **18**
      FAILs, none naming the plant. The blinded copy is *also red* — a matcher
      that finds nothing fails every anchored check and reports all 29 exempt
      pairs MISSING — so the exit status cannot be the discriminator.

      And one thing the spec did not predict: the blinded gate **does print the
      phrase**, in `FAIL  anchored: RP4 \`takes the whole shell down\` …`. A
      single grep for the phrase would have matched it. The discriminator is
      one FAIL line carrying the phrase *and* the planted path, which is why
      `names_in` greps the same line twice.
- [x] **R4** — `claims_table`, `phrases_table`, `exempt_table`, `node_state`,
      `sweep` and `sweep_files` are **byte-identical** to the pre-change copy,
      proved per function by sha256 rather than by a diff, and the arming
      verdict loop diffs empty. Zero table rows added or removed. The waiver is
      not an `exempt_table` row: it is tier 1, derived, and it **deleted** the
      hardcoded `SWEEP_NODE` — one hardcoded folder became one derived rule
      yielding two. `exempt_table` is still exactly 29 pairs.
- [x] **R5** — Delivered by the blocked lane and retained in
      [spec03](specs/spec03.md) (`est: 0h`); re-confirmed here rather than
      redone. The seven `selftest()` entry lines still resolve —
      `audit-findings:178`, `manual-coverage:146`, `nushell-module-staging:280`,
      `probes:113`, `tree-links:27`, `wave-status:265`, and
      `retired-phrases:725` (was `:586`; this node's edits moved it). The
      `nushell-module-staging.sh` finding reproduces read-only:
      `tests/shell-television.sh:471` reads
      `for m in dirstack pass theme claude zoxide history capsule finder
      copymode help; do`, so its GREEN repair `sed` is a no-op, both
      `PASS  selftest GREEN: …` halves pass anyway and the live gate exits `0`.
      Filed as [`staging-gate-vacuous-green`](../staging-gate-vacuous-green/prd.md)
      and **not** touched here — its mtime is unchanged.

## Acceptance
- [x] `bash gates/retired-phrases.sh --selftest` exits 0 with **77 PASS /
      0 FAIL**, run alone (`2:08.29`), and `bash gates/selftest.sh` exits 0
      with **38 PASS / 0 FAIL** (`3:44.60`) — including
      `PASS  contract: retired-phrases.sh accepts --selftest and exits 0
      (rc 0)`, the single FAIL this node was opened on.
- [x] `bash gates/retired-phrases.sh` exits 0 with `armed carriers: 0` and
      `MISSING []; UNEXPECTED []`, with this node's own spec files in place —
      which the waiver is what buys. Before this lane's first write the same
      command exited 1 with `armed carriers: 4` / `UNEXPECTED 5`, all five
      pairs inside this folder.
- [x] R3's argument is above and in the report, with the blinded-gate
      measurement and the trap it caught (the blinded gate prints the phrase;
      only the phrase-plus-path line discriminates). It is permanent as CF14,
      and CF14 itself fails closed: if the blinding `sed` stopped matching, the
      "blinded" copy would be the real gate and would name the plant.
- [x] The R5 census is spec03's table, one line per contract-held gate, seven
      lines — delivered and accepted before this lane. Confirmed here at the
      level the brief allows: every `selftest()` entry line re-resolved, and the
      one defective verdict (`nushell-module-staging.sh`, vacuous GREEN)
      reproduced read-only. No eighth gate was found; the sixth and seventh
      (`tree-links`, `wave-status`) carry the mild, loud, named live-tree
      preconditions spec03 records as the acceptable form.
- [x] `gates/waves.tsv` **unmodified**: md5 `b1f150ede6fb4f94d8b53be571987b71`
      before this lane's first write and after its last, identical to spec03's
      spec-time value; `grep -c 'retired-phrases' gates/waves.tsv` → `0`; mtime
      `Aug 23 17:46:30`, hours before this lane's only write at `21:41:50`. The
      segment to append to wave 0's `gates` cell, unchanged from spec03:

      ```
       | bash gates/retired-phrases.sh
      ```

      Wave 0's cell currently ends `… | bash gates/nushell-module-staging.sh`,
      but it must be **re-read at transition time** — it is another lane's
      file and the cell may have moved. Not `external`: this node owns the
      script and it now signs the `--selftest` contract.

## Out of scope
- The phrase table and the allow-list (R4).
- Registering the gate, which lands when this closes.

## Answers — orchestrator, 2026-08-23

The implementer returned **BLOCKED without writing a byte** (md5 of
`gates/retired-phrases.sh` unchanged) because this node's **own spec files**
became armed carriers: they quote four retired phrases verbatim as measured
evidence, plus RP11 pending. Proved isolated — removing only this folder from
a `scratch_tree` copy returns `armed carriers: 0`, `MISSING []; UNEXPECTED []`,
rc 0. The rest of the tree is exactly as green as this PRD says.

**Ruling on the five (phrase, path) pairs: option (A), derived from
`footprint:`, with a pinned ceiling.**

A node whose frontmatter `footprint:` names `gates/retired-phrases.sh` is a
node *maintaining the sweep*, and a phrase quoted there is by construction
being discussed as retired rather than asserted as true. That is the same
reasoning already accepted for the hardcoded `SWEEP_NODE`, and the same
derivation style the design prizes for arming (from `state:`) and for tier 1.
Exactly **two** nodes qualify today; three others mention the path in prose
only and have no `footprint:` field, so they do not qualify. This is not
allow-list growth — it generalises an existing tier-1 rule instead of buying
five tier-2 pairs to make a check pass, which is what (C) would be and what
R4 forbids.

(B) is the same fix that goes stale. (D) was tempting because
reference-not-quote is the discipline this board already paid for once — the
orchestrator created an armed carrier the same way earlier this session and
fixed it by citing the table row instead of typing the phrase. It is declined
here because a spec whose evidence *is* a FAIL line should be allowed to show
that line; eliding the string to satisfy the tool would weaken the record.

**The ceiling is not optional.** Derivation must be narrow and loud: report
how many folders the waiver covers and fail if that count exceeds a pinned
**2**. A waiver that silently absorbs new folders is the failure mode
[`gate-artifact-leakage`](../gate-artifact-leakage/prd.md) solved for its root
inventory with tracked-or-pinned-≤3; use that shape.

**And the actual fix is relativity, not the waiver.** The implementer's
closing observation is the finding of this whole node:

> A selftest anchored to "the tree as it is today" does not merely invert
> once; it oscillates with every commit.

Demonstrated twice over. The first inversion was the tree being *repaired*
under a selftest that assumed it broken. The second is the tree being
*re-broken by the very spec files written to fix the first* — so the two
halves this PRD reports as red now **pass for the wrong reason**, and three
others fail instead: `uncovered: RP9`, `CF9: the same phrase inside its own
retirer's folder is green`, and `CF10 … UNEXPECTED []`. spec01 fixes the
first; spec02 fixes CF12; **CF9-green and CF10 are absolute assertions and
were not respecced**, so they red whatever the implementer writes, and
spec02's acceptance pins CF10's exact string. Make both relative to a
self-computed baseline, exactly as spec02 already does for CF12. That, not the
waiver, is what stops this recurring.

**Unblocked and delivered:** spec03's R5 census (seven gates, each verified
against its `selftest()` entry line) and the wave-0 registration segment.
`gates/waves.tsv` md5 identical before and after,
`grep -c 'retired-phrases'` → 0. The registration stays held until
`--selftest` exits 0.

## Hold — orchestrator, 2026-08-23

`specced` at **2.75h** (spec01 0.5h + spec02 2.25h; spec03 is `est: 0h`,
delivered by the blocked lane and retained as the record, so the total does
not double-count). Amendments accepted — all three landed, each measured:

- the waiver **deletes** the hardcoded `SWEEP_NODE`, because
  `retired-phrase-sweep` qualifies under the derived rule by its own
  `footprint:`. One hardcoded folder becomes one derived rule yielding two.
  Prototyped on the live tree: `waiver: 2 … pin 2`, `armed carriers: 0`,
  `MISSING []; UNEXPECTED []`, rc 0, derivation in 0.039 s.
- the pin is **not environment-readable** — `SWEEP_MAINTAINER_PIN=9` still
  reports pin 2 — so CF15 demonstrates the ceiling with a planted third
  folder in a copy, not with an override.
- CF9-green and CF10 are relative; CF10's literal `UNEXPECTED []` is unpinned
  from the acceptance box.

**Not dispatched yet, and the reason is behavioural rather than a write
conflict.** `gates/retired-phrases.sh` sources `gates/lib.sh`, and
[`gate-artifact-leakage`](../gate-artifact-leakage/prd.md) is in flight
editing `lib.sh` **and** `gates/selftest.sh` — which is this node's `verify:`.
No footprint overlaps, so the overlap check passes, and taking that as
clearance would be the mistake: this lane's every measurement runs through a
file the other lane is rewriting, and a green here could be borrowed from a
half-applied `lib.sh`. Two lanes may not share a sourced dependency any more
safely than they may share a file.

Dispatches when that node closes. Two things this node's analyst caught are
worth carrying into that sequencing:

- the timing budget is now **relative** — the header's `2.84 s` was a warmer
  run, the unchanged script measures 3.09–3.10 s today, so the box is a delta
  against a pre-change baseline measured in the same session. Comparing a
  timing across sessions is the mistake this whole node is about.
- CF15 asserts the reported **count is 3**, not merely that the run is red. A
  derivation that stopped seeing footprints would report 0, pass its pin
  check, and take CF15 green when it must be red — the silent-green shape of
  [`staging-gate-vacuous-green`](../staging-gate-vacuous-green/prd.md).

**Hold released 2026-08-23T22:12Z.** `gate-artifact-leakage` is `done`:
`gates/lib.sh` and `gates/selftest.sh` are settled, the `/` pattern hole in the
scratch guard is closed, and the meta-gate re-ran solo at **37 PASS / 1 FAIL**
with the watched tree byte-identical across the window. That single FAIL is
this node's own `--selftest` contract, so this lane's `verify:` now has a clean
baseline to move.

## Closeout — orchestrator, 2026-08-23

`done`, and **the board's meta-gate is green for the first time.** Verified by
the orchestrator, solo, with a contamination detector rather than taken from
the report: `bash gates/selftest.sh` → **38 PASS / 0 FAIL, rc 0**, and the
watched tree (`gates`, `tests`, `docs`, the root inventory) hashed
**byte-identical across the whole window**.

**Wave 0 is registered.** The cell was re-read fresh at transition time as
spec03 required — md5 `b1f150ed…` unchanged, `grep -c` 0 — then the segment
appended. The diff is one line, and `gates/wave-status.sh --validate` passes
all four registry checks. `grep -c 'retired-phrases' gates/waves.tsv` → **1**.
This registration has been held all session; it was waiting on exactly this
`--selftest` contract.

**The derived rule proved itself under the growth that broke the hardcode.**
The waiver now covers **11** TIER1 pairs in this folder, up from 5, because the
amended boxes quote more FAIL lines — and the pin counts *folders*, so it stays
2/2. A hardcoded list would have needed editing again on the same day it was
written.

**One thing the spec did not predict, found by the implementer.** The blinded
matcher in CF14 *does* print the phrase once, inside an `anchored:` FAIL line —
so a single grep would have matched it and the counterfactual would have passed
for the wrong reason. The discriminator is one line carrying phrase **and**
planted path, which is why `names_in` greps the same line twice. CF14 also
asserts the blinded copy actually *ran*: its `REPO_ROOT` sits inside the
selftest scratch, so an inherited `GATES_KEEP_TMP` is an ancestor of it and
[`gate-artifact-leakage`](../gate-artifact-leakage/prd.md)'s new `lib.sh` guard
would `FATAL`, printing no FAIL line and taking the half green for the worst
possible reason. Two nodes' machinery interacting in a way neither spec saw.

**Two boxes left `[ ]`, and they are the `git diff` finding once more.**
`git diff --stat gates/` names *two* files — this script and another lane's
`waves.tsv` — while being blind to nineteen untracked entries in `gates/`,
including this node's entire footprint. Attribution went by content instead.
Owned by [`git-diff-integrity-boxes`](../git-diff-integrity-boxes/prd.md).

**`actual:` not recorded.** The first attempt returned BLOCKED and the specs
were amended between attempts, so this run does not measure a clean one — and
the BLOCKED was right: the node's own spec files had become armed carriers,
which is the node's thesis biting the node.

**The finding this node exists for, in one sentence, now in the script's own
header:** a selftest anchored to "the tree as it is today" does not invert
once, it oscillates with every commit — so every half asserts against a
self-computed baseline, and the timing figure is comparable only within a
session.
