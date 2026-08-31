---
est: 2.25h
footprint:
  - gates/retired-phrases.sh
---

# spec02 — CF12 builds its own red input, and proves it is not a tautology

CF12 asserts `the untouched copy is red — the six armed carriers stand`. The
carriers were repaired by `shell-down-spec-carriers` and
`capsule-rm-reworded-claim`, so the untouched copy is green and the assertion
fails. Its sibling, `dropping the three PENDING carriers does not change the
exit status`, fails for the same reason: it too expected the copy to be red,
and RP9 is no longer pending either — it armed. Both halves borrowed the
board's brokenness instead of constructing their own.

Rebuild both on fixtures the selftest makes itself, then add the check that
keeps the rebuild from becoming a tautology.

**Apply after spec01**, which rewrites the plant roster in the same file.

> **Amended 2026-08-23**, after an implementer returned BLOCKED without writing
> a byte. It was right to: **this node's own spec files became armed carriers.**
> spec01 and spec02 quote four retired phrases verbatim as measured evidence,
> plus RP11's pending one, so the live sweep now reports `armed carriers: 4` /
> `UNEXPECTED 5`, all five pairs inside this folder. The node's thesis bit the
> node — and it proved the thesis is bigger than one inversion: **a selftest
> anchored to "the tree as it is today" does not invert once, it oscillates
> with every commit.** Three sections are new or rewritten below: the derived
> waiver (§ Waiver), and the relativisation of CF9-green and CF10 (§ Relative),
> which were absolute assertions that would red whatever an implementer wrote.

## The pattern, and where it comes from

`gates/audit-findings.sh:232-243` — its green counterfactual. It makes the
copy red **with its own mutation** (`strip_id_everywhere "$S4" "$probe"`),
asserts red (`chk_fail "green: the copy is red before repair" run_q "$S4"`),
repairs, and asserts green. Nothing in it reads the live tree's health.
`gates/tree-links.sh:34` contributes the second half of the shape:
every assertion is **relative to a baseline it computed itself**
(`base="$(count_a "$S")"`, then `test "$after_agents" -gt "$base"`), so a
changing tree moves both sides together. This spec is a port of those two, not
an invention.

## Waiver — tier 1, derived from `footprint:`, with a pinned ceiling

Five (phrase, path) pairs now stand inside this node's own folder because its
specs quote the FAIL lines they were measured from. The ruling
(PRD `## Answers`) is **option (A)**: derive the tier-1 waiver from
frontmatter. A node whose `footprint:` names `gates/retired-phrases.sh` is a
node *maintaining the sweep*, so a phrase in its folder is being discussed as
retired, not asserted as true.

This **generalises an existing rule rather than growing the allow-list**, and
the structural proof is that it *deletes* code: the hardcoded

```sh
SWEEP_NODE="prds/00-delivery/corrections/retired-phrase-sweep"
```

goes away, because `retired-phrase-sweep` qualifies under the derived rule by
its own `footprint:`. One hardcoded folder becomes one derived rule yielding
that same folder plus this one. Buying five tier-2 pairs instead is what R4
forbids.

### The derivation

For each `prds/**/prd.md`, read the **first** frontmatter block only, and
qualify the node when a `footprint:` key's value names
`gates/retired-phrases.sh`. Reset the in-footprint flag at the next top-level
key, so an unrelated key that happens to mention the path does not qualify.
Both YAML forms must work — inline `footprint: [gates/retired-phrases.sh]` and
the block list. One `find` plus one `awk`, **once per run**, never per phrase.

Measured 2026-08-23 — exactly the two the ruling names, in **0.039 s**:

```
prds/00-delivery/corrections/phrase-sweep-selftest-inversion
prds/00-delivery/corrections/retired-phrase-sweep
```

Five files under `prds/` mention `gates/retired-phrases.sh`; only these two
name it in `footprint:`. `capsule-rm-reworded-claim`, `gate-artifact-leakage`,
`mi-rooted-verify-commands`, `shell-down-spec-carriers` and
`staging-gate-vacuous-green` mention it in prose and are correctly **not**
waived. The derivation reads the tree under measurement, so it composes with
`--root` and every counterfactual.

### The ceiling is not optional

A waiver that silently absorbs new folders is the same silent-green failure
this node's own R5 census found in `nushell-module-staging.sh`. So, in the
shape [`gate-artifact-leakage`](../../gate-artifact-leakage/specs/spec02.md)
used for its root inventory:

```sh
SWEEP_MAINTAINER_PIN=2
```

- **Not overridable from the environment.** An overridable ceiling is not a
  ceiling. `gate-artifact-leakage` allows either an override or a
  reverted-in-the-same-box edit to demonstrate it; a fixture is better than
  both, and CF15 below is one.
- Report the count **and every folder**, one per line, in the report body.
- `chk` red when the count exceeds the pin, with the remedy in the label: a
  third maintainer folder is a design change, so raise the pin deliberately in
  the same commit or do not add the folder.

### CF15 — the ceiling, proved on a fixture

Plant a node carrying `footprint: [gates/retired-phrases.sh]` into a
`scratch_tree` copy and assert the gate goes red naming the count. Measured on
the prototype:

```
      waiver: 3 sweep-maintainer folder(s), pin 2
FAIL  waiver: the derived sweep-maintainer set is within its pinned ceiling (3 <= 2)
rc=1
```

Board-independent, needs no env override, and it fails closed: if the
derivation stopped seeing footprints the count would be 0, the pin check would
pass, and **CF15 would go green when it must be red** — so assert the *count*
CF15 reports is 3, not merely that the run is red.

### Measured: the live tree goes back to green

The prototype, run against the real tree with the four carriers standing:

```
      waiver: 2 sweep-maintainer folder(s), pin 2
PASS  waiver: the derived sweep-maintainer set is within its pinned ceiling (2 <= 2)
PASS  sweep: no armed row's phrase stands outside its allow-list (armed carriers: 0)
      MISSING []; UNEXPECTED []
PASS  allow-list: exactly the 29 declared pairs, plus 0 pending-row carriers (MISSING 0, UNEXPECTED 0)
rc=0
```

RP11's pending pair in spec01 is absorbed by tier 1 too, which is why the
pending-row count returns to 0. Nothing in `claims_table`, `phrases_table`,
`exempt_table` or the arming derivation is touched to achieve this.

## CF12 — red and green, both self-constructed

Relative, not absolute, so it holds on a dirty board as well as a clean one:

1. `d="$(mk cf12)"` — a plain `scratch_tree` copy. Record `base_rc` (the
   copy's exit status, whatever it is) and echo it, so a reader can see what
   the fixture started from. Do **not** assert `base_rc` is 0; that is the
   live-tree assertion this node exists to remove.
2. Precondition, loudly: assert the baseline does **not** already carry a FAIL
   line naming (phrase, host) for the plant about to be made. Without it a
   board that already carries the plant's phrase at the host would make step 3
   vacuous. This is the same guard `gates/tree-links.sh:68` uses ("the wrapped
   link is still where this test expects it").
3. Plant one armed claim's phrase, as an assertion sentence, at a host with no
   exemption — reuse `cf_plant`'s conventions. Assert the mutation landed,
   assert `run_q` is non-zero, and assert `fail_names` matches **both** the
   phrase and the host path. The `fail_names` half is the load-bearing one:
   see **R3** below.
4. Repair the plant in that same copy (delete the appended paragraph, or
   rewrite the phrase). Assert the mutation landed. Assert `fail_names` no
   longer matches, and that `run_q`'s status is back to `base_rc`.

Step 4 gives the true green direction for free on a clean board — `base_rc` is
0 today — while surviving a dirty one.

## CF12-pending — a pending row the selftest makes pending itself

The old half needed RP9 to be PENDING on the live board. Arming is derived
from the retirer's `state:` **inside the tree under measurement**, and
`--root` points at a copy, so the fixture can simply write the state it wants.
That removes the dependency entirely and exercises the arming derivation
without changing a line of it.

Pick any single-retirer row (RP8 / `refreshed out of the host keychain on
every mount`, retirer `00-delivery/corrections/capsule-creds-refresh-wording`,
is the measured one). Two copies, same plant:

| copy | retirer `state:` in the copy | expected |
|---|---|---|
| pending | forced `open` | `run_q` status equals `base_rc`; the run **reports** `PENDING RP8 <host> carries …` |
| armed | left `done` | `run_q` non-zero; `fail_names` matches phrase and host |

Both measured 2026-08-23 on scratch copies with the sentence appended to
`prds/06-help/prd.md`:

```
# retirer forced open
      PENDING RP8 prds/06-help/prd.md carries `refreshed out of the host
      keychain on every mount` — owned by
      00-delivery/corrections/capsule-creds-refresh-wording (`open`), so it is
      reported and not counted
rc: 0

# retirer left done
FAIL  RP8 CARRIER prds/06-help/prd.md carries `refreshed out of the host
      keychain on every mount` — retired by … (done). Not exempt.
rc: 1
```

The pair is what makes it a check rather than a coincidence: one bit of
fixture state flips the verdict, and both directions are asserted.

## R3 — why the rebuild still fails if the matcher breaks

Two things carry the argument, one structural and one measured.

**Structural.** Neither half asserts merely `rc != 0`. Each asserts a `FAIL`
line naming *the phrase it planted* and *the path it planted it at* —
`fail_names`, already in the file. A gate that stopped matching produces no
such line, whatever else it prints, so the red half fails. A tautology — plant
a string, repair it, assert nothing about the gate's output — cannot satisfy
that assertion at all.

**Measured, and made permanent as CF14.** Copy `retired-phrases.sh` and
`lib.sh` into the selftest's scratch root, blind the matcher in the copy
(`$GREP -oFf "$pf"` → `$GREP -oFf /dev/null`, one `sed`), assert the sed
actually landed, then run the **blinded** copy with `--root` against CF12's
own planted fixture and assert **no FAIL line names the plant**. Measured on
that exact fixture:

| gate | rc | FAIL line naming (phrase, path)? |
|---|---|---|
| real | 1 | yes |
| matcher blinded | 1 | **no** — 18 FAILs, none of them the plant |

Note the trap this measurement caught, and do not spec around it: the blinded
copy is **also red**, because a matcher that finds nothing fails the anchored
checks and reports all 29 exempt pairs MISSING. So the discriminator must be
the FAIL line, never the exit status. A blinded run costs 2.06 s.

CF14 fails closed: if the `sed` stops matching the source, the "blinded" copy
is the real gate, it names the plant, and the assertion goes red.

`gates/probes.sh:128` is the house precedent for this shape — the same probe
run against a fixture and against an emptied one, "the probe is not vacuous".

## Relative — CF9-green and CF10 stop asserting things about the tree

These two were **not** in the original spec and are the amendment that matters.
CF12 was only the loudest instance; these are the same defect, and they are why
the implementer could not have written a green selftest whatever it did.

### CF9-green

Asserts `run_q "$d" == 0` **absolutely** — that a scratch copy carrying a
tier-1 plant is green. It fails today because the copy also carries this
folder's four carriers, and it will fail again for the next unrelated reason.
Its actual claim is narrower than its assertion: *tier 1 waives this pair*.
Make it relative, exactly as CF12 now is:

1. Record `base_rc` from an unmutated `scratch_tree` copy and echo it.
2. Precondition: assert the baseline names no FAIL line for the (phrase, path)
   about to be planted.
3. Plant the phrase inside its own retirer's folder. Assert the mutation
   landed; assert `no_fail_names` for that (phrase, path) — the waiver's real
   content; and assert `run_q`'s status equals `base_rc` — unchanged, not zero.

The `repair_known_reds "$d"` call that used to make green reachable goes away
with the helper (§ Dead helpers). It is what made the half tree-dependent.

### CF10

`chk_fail "CF10: a stale exemption makes the gate red"` is fine as-is: the
mutation deletes a declared exempt occurrence, so `MISSING` is ≥ 1 and the run
is red no matter what the baseline was. What must change is the assertion
beside it, which pins a literal:

```
MISSING [the terminal owns the palette :: AGENTS.md]; UNEXPECTED []
```

The `UNEXPECTED []` half is an assertion about the whole tree, and **the
original spec's acceptance box pinned it** — so that box would have failed a
correct implementation the moment any node anywhere added a pair in tier-2
territory, which is precisely what happened. Unpinned, and replaced by two
relative halves:

- the `MISSING [...]` segment names the deleted pair — grep the phrase and
  `AGENTS.md` **within that segment**, not within the whole line;
- the `UNEXPECTED [...]` segment is **byte-identical to the baseline copy's**,
  which proves the mutation moved `MISSING` and nothing else. On a clean board
  both are `[]` and the check reads exactly as before; on a dirty one it still
  measures what it was written to measure.

## Dead helpers, removed

`repair_known_reds` and `drop_pending` exist only to make the live tree's
brokenness go away in a copy. After this spec nothing calls them for that, and
their remaining call sites in CF9-green and CF10 are **provably no-ops** —
every string they rewrite occurs zero times in its target file, raw and
normalised (measured 2026-08-23: all five `repair_known_reds` targets 0, all
three `drop_pending` targets 0). Delete both functions and all four call
sites. CF10's exact-string assertion
(`MISSING [the terminal owns the palette :: AGENTS.md]; UNEXPECTED []`) must
still PASS afterwards, which is the check that the deletion was a no-op.

## Budget — measured relatively, like everything else

Do not spend the gate's performance to buy the fixture. Nothing here touches
`sweep()` or `run()`'s single `grep -oFf`.

| what | measured 2026-08-23 |
|---|---|
| live run, gate as it stands | **3.09 s / 3.10 s** (two runs) |
| live run, prototype with the waiver | **3.12 s / 3.15 s** |
| waiver derivation alone | **0.039 s** |
| `--selftest`, gate as it stands | **91.8 s**, 16 scratch copies |

The `2.84 s` in the gate's own header comment was a warmer run; 3.10 s is
today's figure for the unchanged script, and the two must be compared in the
same session or not at all. So the budget is **relative**: the delta against
the pre-change script must be **≤ 0.25 s**, with an absolute ceiling of
**4.0 s** as a backstop. The selftest gains roughly three copies and two short
runs (CF14 blinded ≈ 2.1 s, CF15 ≈ 3 s); budget **≤ 180 s**.

## Acceptance

- [x] `bash gates/retired-phrases.sh --selftest` exits **0** with **0 FAIL**,
      run alone: `77` PASS, `0` FAIL, `rc=0`, closing
      `── selftest rc=0 ──`. (An earlier run in the same session came back
      `76 PASS / 1 FAIL` on `CF13: prds/, docs/ and AGENTS.md are
      byte-identical`; `find prds -newermt` named the writers as
      `w0-4-s2-corrections/{help,shell}/prd.md`,
      `mi-lowercase-verify-sections/{prd.md,specs/spec03.md}`,
      `prds/README.md` and `prds/.plane-map.json` — other lanes, none of them
      this one. Re-run solo, it PASSes.)
- [x] `bash gates/selftest.sh` exits **0** with 0 FAIL — `38` PASS, `0` FAIL,
      `rc=0`, in `3:44` with no live-tree file touched in the window:

      ```
      ── retired-phrases.sh: rc=0, 23 mutation line(s), host …/retired-phrases-selftest
      PASS  contract: retired-phrases.sh accepts --selftest and exits 0 (rc 0)
      PASS  contract: retired-phrases.sh really changed its scratch tree — a claimed mutation is not a made one
      PASS  contract: retired-phrases.sh wrote nothing outside its scratch (sha256 over gates, tests, docs, …)
            7 script(s) held to the contract · 45 external, reported not failed
      ```
- [x] `bash gates/retired-phrases.sh` still exits 0 and prints
      `armed carriers: 0` and `MISSING []; UNEXPECTED []` — with this node's
      own spec files in place, no isolation:

      ```
      PASS  sweep: no armed row's phrase stands outside its allow-list (armed carriers: 0)
            MISSING []; UNEXPECTED []
      PASS  allow-list: exactly the 29 declared pairs, plus 0 pending-row carriers (MISSING 0, UNEXPECTED 0)
      rc=0
      ```
- [x] Timing, both figures from the same session, alternated old/new/old/new
      against the same live tree (the pre-change script copied aside before the
      first edit, sha256 `e52a95b570ea7643369215697b6e1414a51eb66a450284b0dfb81466496e8e3f`,
      run beside its own `lib.sh` so both halves resolve identically):

      | script | run 1 | run 2 |
      |---|---|---|
      | pre-change | 2.88 s | 2.89 s |
      | post-change | 2.90 s | 2.90 s |

      Delta **+0.01–0.02 s** (budget 0.25 s), absolute **2.90 s** (backstop
      4.0 s). For the record of why the budget is relative: this same
      unchanged script measured 3.01–3.12 s earlier in this session and
      2.84 s when the header comment was written, so a cross-session
      comparison would have read the +0.02 s change as a −0.2 s improvement.
- [x] The selftest completes in **≤ 180 s**: `2:08.29` total
      (`108.94s user 118.17s system`), against `1:38.59` for the pre-change
      script in the same session — the added copies and runs cost ~30 s.

Waiver and ceiling:

- [x] `SWEEP_NODE`'s hardcoded path is **gone** — `grep -c SWEEP_NODE
      gates/retired-phrases.sh` → `0` — and `retired-phrase-sweep` is waived
      by the derived rule instead, which is what the report's second `waiver:`
      line names.
- [x] The run reports the waiver count **and every folder by name**:

      ```
      ── waiver ───────────────────────────────────────────────────────────
            waiver: 2 sweep-maintainer folder(s), pin 2
            waiver: prds/00-delivery/corrections/phrase-sweep-selftest-inversion
            waiver: prds/00-delivery/corrections/retired-phrase-sweep
      PASS  waiver: the derived sweep-maintainer set is within its pinned ceiling (2 <= 2) — a third folder is a design change: raise SWEEP_MAINTAINER_PIN in the same commit, or do not add the folder
      ```
- [x] The derivation qualifies only `footprint:`, not prose. The derived list
      is the two folders quoted above. `grep -rl 'gates/retired-phrases.sh'
      prds` now names **16 files across 8 nodes** — the spec's "five files" has
      grown by `git-diff-integrity-boxes` (2 files) and this node's own
      spec03 — and the six non-maintainer nodes
      (`capsule-rm-reworded-claim`, `gate-artifact-leakage`,
      `git-diff-integrity-boxes`, `mi-rooted-verify-commands`,
      `shell-down-spec-carriers`, `staging-gate-vacuous-green`) are all
      correctly **not** waived. Two of them would qualify under a looser rule
      and do not under this one: `retired-phrase-sweep` names the script in
      `verify:` as well as `footprint:` and qualifies on the `footprint:`
      alone, and `staging-gate-vacuous-green` has a `footprint:` naming a
      *different* gate. The five pairs inside this folder are now
      `TIER1`:

      ```
      TIER1	RP1	stops EVERY PWD closure firing	…/specs/spec01.md
      TIER1	RP9	silently disable healing for the rest of the session	…/specs/spec01.md
      TIER1	RP11	the auto-list append that names it	…/specs/spec01.md
      TIER1	RP7	the terminal owns the palette	…/specs/spec02.md
      TIER1	RP8	refreshed out of the host keychain on every mount	…/specs/spec02.md
      ```
- [x] Both YAML footprint forms qualify. The real tree uses only the inline
      form (both maintainer nodes), so CF15's planted node writes the **block
      list** — and it is derived: `PASS  CF15: the planted node IS derived as a
      maintainer — the block-list footprint form parses (waiver: 3)`. Five
      further negative forms were measured on a throwaway fixture before the
      code went in: prose-only, a `verify:` naming the script, a `footprint:`
      naming a different gate, a file with no frontmatter, and a `deps:` block
      list *following* a `footprint:` — none qualified, which is the
      reset-at-the-next-top-level-key rule working.
- [x] `SWEEP_MAINTAINER_PIN` is **not** readable from the environment:
      `SWEEP_MAINTAINER_PIN=9 bash gates/retired-phrases.sh` still prints
      `waiver: 2 sweep-maintainer folder(s), pin 2` and PASSes the ceiling at
      `(2 <= 2)`.
- [x] CF15: a third maintainer folder planted in a scratch copy makes the gate
      red, and the assertion is on the **count**:

      ```
      PASS  CF15: the planted node IS derived as a maintainer — the block-list footprint form parses (waiver: 3)
      PASS  CF15: and the report names the folder, not just the count
      PASS  CF15: a third maintainer folder makes the gate red (rc 1)
      PASS  CF15: and the FAIL line reports the COUNT — a derivation that stopped seeing footprints would report 0, pass the pin check, and take this half green when it must be red
      ```

      The third and fourth are separate on purpose: red alone would be
      satisfied by any unrelated carrier on the copy, and the count is what
      distinguishes a firing ceiling from a blind derivation.

Relativity — the amendment that stops the oscillation:

- [x] No half asserts an absolute exit status or an absolute report string for
      a tree it did not build. The four baseline echoes, verbatim from the
      run:

      ```
            BASELINE: the unmutated copy exits 0 — this half asserts against THAT, never against 0        (CF9-green)
            BASELINE: the unmutated copy exits 0, MISSING [], UNEXPECTED []                               (CF10)
            BASELINE: the unmutated copy exits 0 — CF12 asserts against THAT and never against 0          (CF12)
            MUTATION: forced RP8's retirer to `open` in …/cf12-pending, so the row is PENDING in the tree under measurement (baseline rc 0)
      ```

      The fourth half's sibling, CF12-armed, echoes its own baseline in its
      precondition label (`baseline rc 0`). Every assertion downstream of these
      compares to the echoed value, never to a literal `0`.
- [x] CF10 no longer matches a pinned literal — `seg_missing` / `seg_unexpected`
      split the report line and each half is asserted separately:

      ```
      PASS  CF10: a stale exemption makes the gate red (rc 1) — without this half an allow-list only ever grows
      PASS  CF10: and the MISSING segment names the pair whose occurrence was deleted ([the terminal owns the palette :: AGENTS.md])
      PASS  CF10: and the UNEXPECTED segment is byte-identical to the baseline copy's ([]) — the mutation moved MISSING and nothing else
      ```

      On today's clean board both segments read exactly as the old literal did,
      which is the point: the check is unchanged in what it measures and no
      longer breaks when an unrelated node adds a pair.
- [x] CF9-green asserts the absence of the FAIL line and a status equal to its
      own baseline:

      ```
      PASS  CF9: precondition — the baseline copy names no FAIL line for `dies immediately` at gui-dies-claim-carriers/prd.md, so the plant below is what makes any difference
      PASS  CF9: the tier-1 plant really landed inside RP2's retirer folder
      PASS  CF9: the same phrase inside its own retirer's folder names no FAIL line — tier 1 is a deliberate waiver
      PASS  CF9: and the tier-1 plant did not move the exit status (rc 0, baseline 0)
      ```
- [x] CF12 contains no assertion about the live tree's exit status. Its chk
      lines, all seven — red and green both self-constructed:

      ```
      PASS  CF12: precondition — the baseline copy names no FAIL line for `takes the whole shell down` at prds/06-help/prd.md, so the plant below is the only thing that can make it red
      PASS  CF12: the mutation really landed in prds/06-help/prd.md — a claimed mutation is not a made one
      PASS  CF12: the self-planted claim makes the gate red (rc 1, baseline 0)
      PASS  CF12: and one FAIL line names both the phrase and prds/06-help/prd.md — the load-bearing half, see CF14
      PASS  CF12: the repair really landed — the planted phrase is gone from the copy
      PASS  CF12: with the plant repaired, no FAIL line names it any more
      PASS  CF12: and the status is back to the baseline this half measured itself (rc 0 == 0)
      ```

      The repair restores the host file from a copy taken before the plant,
      rather than `sed`-ing the phrase out: exact, and the "repair landed"
      assertion is then a real check rather than a restatement of the sed.
- [x] The pending half asserts both directions on copies whose retirer `state:`
      the selftest wrote itself (`force_state`), same plant, one bit of fixture
      state apart:

      ```
      PASS  CF12-pending: the fixture really forced RP8's retirer to `open` in the copy
      PASS  CF12-pending: an UNARMED row's carrier does not move the exit status (rc 0 == 0) — reported, never counted
      PASS  CF12-pending: and it IS reported, so it cannot hide (PENDING RP8 … prds/06-help/prd.md)
      PASS  CF12-pending: and no FAIL line names it while the row is pending
      PASS  CF12-armed: precondition — with the retirer left `done`, the baseline copy names no FAIL line for the pair yet (baseline rc 0)
      PASS  CF12-armed: the same plant under an ARMED row is red (rc 1) — one bit of fixture state flips the verdict
      PASS  CF12-armed: and one FAIL line names both the phrase and prds/06-help/prd.md
      ```

      The report line itself, reproduced by hand on the same fixture:

      ```
            PENDING RP8 prds/06-help/prd.md carries `refreshed out of the host
            keychain on every mount` — owned by
            00-delivery/corrections/capsule-creds-refresh-wording (`open`), so it
            is reported and not counted
      rc=0
      ```

Non-tautology, hygiene, footprint:

- [x] CF14 present, and the measurement is sharper than the spec expected.
      Both runs against the same planted fixture:

      ```
      real   rc=1  3 FAILs   FAIL  RP4 CARRIER prds/06-help/prd.md carries `takes the whole shell down` — retired by 00-delivery/corrections/config-nu-parse-claims (done). Not exempt.
      blind  rc=1  18 FAILs  (no FAIL line names both the phrase and prds/06-help/prd.md)
      ```

      **The blinded copy does print the phrase** — once, in
      `FAIL  anchored: RP4 \`takes the whole shell down\` is quoted inside its
      own retirer's folder (none of: …)` — so a one-pattern grep for the phrase
      would have matched the blinded gate and taken this half red for the wrong
      reason. The discriminator is a FAIL line naming the phrase **and** the
      planted path, which is exactly why `names_in` greps the same line twice.
      In-gate:

      ```
      PASS  CF14: the blinding sed really landed — the copy's matcher reads /dev/null
      PASS  CF14: and the real matcher line is gone from the copy — if this sed stopped matching, the "blinded" gate would BE the real gate and the half below would go red
      PASS  CF14: the real gate names the plant on this fixture (rc 1)
      PASS  CF14: the blinded copy still RAN (rc 1, 18 FAIL lines) — a FATAL or empty output would make the next assertion vacuous
      PASS  CF14: and NO FAIL line of the blinded copy names the plant — so the discriminator is the FAIL line and not the exit status, and a matcher that stopped matching fails CF12
      ```

      One mechanism worth carrying: the blinded child is invoked with
      `GATES_KEEP_TMP=` emptied. Its `REPO_ROOT` is inside this selftest's own
      scratch, so an inherited scratch root is an **ancestor** of it and
      `lib.sh`'s leakage guard refuses to run — a `FATAL` prints no FAIL line
      at all, which would have taken the assertion GREEN for the worst possible
      reason. Emptied, the child mktemps a sibling scratch and runs. The
      "blinded copy still RAN" assertion exists for the same reason.
- [x] The R3 argument is in the report and in the box above: the blinded gate
      is *also red* (18 FAILs — a matcher that finds nothing fails every
      anchored check and reports all 29 exempt pairs MISSING), so the exit
      status cannot discriminate; only the FAIL line naming the planted
      (phrase, path) can, and a tautology cannot produce one.
- [x] `grep -c 'repair_known_reds\|drop_pending' gates/retired-phrases.sh` →
      **0** (both functions and all five call sites deleted; the fifth was
      CF10's, which took both), and CF10 still PASSes afterwards — all three of
      its assertions are quoted two boxes up. The unused `says()` helper went
      with them: CF10's pinned literal was its only caller.
- [x] CF13's isolation halves still PASS on the solo run:

      ```
      PASS  CF13: no stray artifact was left in the repo root (181ff688ce3d69350764c80e8ae49d82656af03c1b2aeedbf8b14b3c43485074)
      PASS  CF13: prds/, docs/ and AGENTS.md are byte-identical across the whole selftest
      ```
- [x] Nothing in `claims_table`, `phrases_table`, `exempt_table` or the arming
      derivation changed. Proved by content rather than by diff — each function
      extracted from the pre-change copy and from the current file and hashed:

      ```
      claims_table     pre=3e16682ee1e9 post=3e16682ee1e9 IDENTICAL
      phrases_table    pre=5b6aaa7aa53e post=5b6aaa7aa53e IDENTICAL
      exempt_table     pre=8dc8071632cc post=8dc8071632cc IDENTICAL
      node_state       pre=87cb6b01e803 post=87cb6b01e803 IDENTICAL
      sweep            pre=646d8b3b1472 post=646d8b3b1472 IDENTICAL
      sweep_files      pre=89e3f7f330e1 post=89e3f7f330e1 IDENTICAL
      arming block IDENTICAL   (diff of the verdict loop, empty)
      ```

      And in the diff: `0` added or removed lines matching a table
      *definition*, `0` added or removed table *rows*. The five `+` lines that
      mention a table name are new READERS in the selftest (`cf_table` vs
      `phrases_table`, `cf_table` vs `claims_table`) plus one comment. The
      waiver is not an `exempt_table` row — `exempt_table` is byte-identical
      and still 29 pairs.
- [ ] **Half true, so not ticked.** `gates/waves.tsv` md5 is
      `b1f150ede6fb4f94d8b53be571987b71` **before and after** this node's work
      (identical to the value spec03 recorded at spec time), `grep -c
      'retired-phrases' gates/waves.tsv` → `0`, `gates/manual/` is untouched,
      and `gates/nushell-module-staging.sh` was never opened for writing — its
      mtime is `Aug 23 14:52:45`, and the finding was reproduced read-only.
      But `git diff --stat gates/` names **two** files, not one:
      `gates/retired-phrases.sh` and `gates/waves.tsv`, the latter being
      another lane's `AM` state with mtime `Aug 23 17:46:30` — hours before
      this lane's first write at `21:41:50`. The command is also blind to the
      nineteen untracked entries under `gates/`. Content proof instead: the
      only file in `gates/` with an mtime inside this lane's window is
      `gates/retired-phrases.sh`. See
      [`git-diff-integrity-boxes`](../../git-diff-integrity-boxes/prd.md).

## Verify and Proof

```sh
cd /Users/feb/dev/dotfiles

# 1. the gate's own selftest, alone, timed
time bash gates/retired-phrases.sh --selftest 2>&1 | tee /tmp/rp-selftest.txt | tail -3
grep -c '^PASS' /tmp/rp-selftest.txt; grep -c '^FAIL' /tmp/rp-selftest.txt

# 2. the CF12, CF14 and pending lines, quoted
grep -E '^(PASS|FAIL) +CF1[24]|PENDING RP' /tmp/rp-selftest.txt

# 3. the meta-gate
bash gates/selftest.sh 2>&1 | grep -E 'retired-phrases|^FAIL|held to the contract'; echo "rc=$?"

# 4. the live run: still green, still fast, and the waiver reported
time bash gates/retired-phrases.sh 2>&1 | grep -E 'waiver|armed carriers|MISSING|^FAIL'

# 4b. the pin is not buyable from the environment
SWEEP_MAINTAINER_PIN=9 bash gates/retired-phrases.sh 2>&1 | grep waiver

# 4c. the ceiling, on a fixture (CF15's shape, run by hand once)
bash -c '. gates/lib.sh && scratch_tree /tmp/pin3 >/dev/null'
mkdir -p /tmp/pin3/prds/00-delivery/corrections/planted-maintainer
printf -- '---\nstate: open\nfootprint: [gates/retired-phrases.sh]\n---\n' \
  > /tmp/pin3/prds/00-delivery/corrections/planted-maintainer/prd.md
bash gates/retired-phrases.sh --root /tmp/pin3 2>&1 | grep -E 'waiver'

# 4d. SWEEP_NODE is gone
grep -c SWEEP_NODE gates/retired-phrases.sh

# 5. the dead helpers are gone, the protected tables are not touched
grep -c 'repair_known_reds\|drop_pending' gates/retired-phrases.sh
git diff gates/retired-phrases.sh | grep -E '^[-+].*(claims_table|phrases_table|exempt_table|node_state)' || echo "no hunk in the protected tables"

# 6. footprint
git diff --stat gates/
md5 -q gates/waves.tsv
```
