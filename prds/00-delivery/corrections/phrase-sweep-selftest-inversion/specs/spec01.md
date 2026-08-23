---
est: 0.5h
footprint:
  - gates/retired-phrases.sh
---

# spec01 — the counterfactual floor covers every claim, armed or not

The floor check `selftest: every armed claim has a per-phrase counterfactual`
reads a hand-maintained string, `cf_claims="RP1 RP2 ... RP10"`, and compares it
against derived arming. RP9 armed on its own when
`00-delivery/corrections/wezterm-repairing-latch-claim` closed `done`, and the
string was not updated, so the floor says `uncovered: RP9` — a true gap, not an
inversion: RP9 has no counterfactual at all. RP11 will do the same thing the
moment `listing-order-comment` closes.

The fix is to stop maintaining the roster in two places. Turn the nine
hand-written plants into a **table** with one row per claim in `claims_table`
— all eleven, armed or not — and drive both the plants and the floor from it.
Then arming a row cannot open a gap: the row is already covered, and the plant
starts running by itself, exactly the way arming already fires by itself.

This spec lands **before** spec02; spec02 rewrites CF12 in the same file.

> **Amended 2026-08-23.** Two things changed around this spec, neither of them
> its design.
>
> **(a) Its evidence quotes are now waived, deliberately.** The verbatim
> phrases below made this node's own folder an armed carrier
> (`armed carriers: 4`). spec02 now derives the tier-1 waiver from
> `footprint:`, which covers this folder, so the evidence **stays** — a spec
> whose proof *is* a FAIL line is allowed to show that line. See spec02
> § Waiver.
>
> **(b) `uncovered: RP9` was re-derived against that waiver and still holds.**
> Details and measurement under **RP9 after the waiver** below.
>
> One ordering consequence: until spec02's waiver lands, a bare
> `bash gates/retired-phrases.sh` reports `armed carriers: 4` for this folder's
> own specs. The live-run box below is therefore written in the isolation form,
> so this spec stays independently verifiable in either order.

## Design

Add a table beside the existing helpers, in the house heredoc style
(`claims_table` / `phrases_table` / `exempt_table` are the models):

```
# Fields: claim | phrase | host relpath | sentence
cf_table() { cat <<'EOF'
RP1|stops EVERY PWD closure firing|prds/06-help/prd.md|An error raised in one …
…
EOF
}
```

Every row's `phrase` and `host relpath` are the ones the nine existing
`cf_plant` calls already use, moved verbatim — no wording is invented for a
row that already had one. Two rows are new:

| claim | phrase | host | why it is safe |
|---|---|---|---|
| RP9 | `silently disable healing for the rest of the session` | `prds/06-help/prd.md` | no exempt row for that phrase, and the host is inside no retirer folder — **measured red**, see below |
| RP11 | `the auto-list append that names it` | `prds/06-help/prd.md` | same, and PENDING today so it plants nothing yet |

Then:

- **plants** — loop the table, skip rows that `--armstate` reports `PENDING`
  (a pending row's carrier is reported and never counted, so `chk_fail` on it
  would be wrong; spec02 owns the pending direction), and call the existing
  `cf_plant` per armed row. `cf_plant` itself does not change.
- **floor** — for each `ARMED` row in `--armstate`, assert the claim has a
  `cf_table` row. Keep the label and the `(uncovered: …)` rendering, so the
  line stays greppable.
- **table integrity** — assert every `cf_table` phrase occurs in
  `phrases_table` under the same claim id. A typo in the new table would
  otherwise plant a string the gate does not ban, and the plant would go green
  for a reason nobody could see. Costs no gate run.

`claims_table`, `phrases_table`, `exempt_table` and the arming derivation are
**not touched** (PRD R4).

## Evidence the two new rows are real

Measured 2026-08-23 on a `scratch_tree` copy with the RP9 sentence appended to
`prds/06-help/prd.md`:

```
FAIL  RP9 CARRIER prds/06-help/prd.md carries `silently disable healing for the
      rest of the session` — retired by
      00-delivery/corrections/wezterm-repairing-latch-claim (done). Not exempt.
rc=1
```

RP11 cannot be proved that way today because its retirer is `open`. Prove it
out of band instead, once: in a scratch copy, force
`prds/00-delivery/corrections/listing-order-comment/prd.md` to `state: done`,
append the RP11 sentence to the host, and show the `FAIL … RP11 CARRIER …`
line. That check is a one-off quoted in the report, not a permanent selftest
half — the permanent half arrives on its own when the row arms.

## RP9 after the waiver (amendment 3)

The concern is fair: RP9's phrase is one of the four now standing in this very
file, so does the waiver make `uncovered: RP9` go away by itself? **No.**
Measured against the prototype waiver, 2026-08-23:

- `--armstate` still reports
  `RP9 ARMED 00-delivery/corrections/wezterm-repairing-latch-claim (done)` —
  arming reads the retirer's `state:` and has nothing to do with carriers.
- The floor check compares `--armstate` against the **counterfactual roster**,
  not against carriers. RP9 is armed and unrostered, so the gap is real and
  this spec is still what closes it.
- The waiver only reclassifies *this file's* occurrence from `CARRIER` to
  `TIER1`. `--pairs` after the waiver:
  `TIER1 RP9 … phrase-sweep-selftest-inversion/specs/spec01.md`.
- The anchored check is unaffected and still resolves to the **retirer's**
  folder, not to this spec:
  `PASS anchored: RP9 … is quoted inside its own retirer's folder
  (prds/00-delivery/corrections/wezterm-repairing-latch-claim/)`.

So the waiver silences a carrier, and the floor still catches the missing
counterfactual. Those are two different checks, which is the design working.

## Acceptance

- [x] `cf_table` holds one row per claim in `claims_table` — 11 rows, ids
      matching exactly, no id twice. The gate asserts it itself:
      `PASS  selftest: cf_table covers claims_table exactly — one row per
      claim, no id twice (11 rows)` (sorted comparison, not `sort -u`, so a
      duplicated id is caught too).
- [x] Every `cf_table` phrase is a `phrases_table` string under the same claim
      id, asserted by the gate itself, and that assertion PASSes:
      `PASS  selftest: every cf_table phrase is a phrases_table string under
      the same claim (mismatched: none)`.
- [x] The plants are driven from `cf_table`; no hand-written roster survives
      anywhere in the file — `grep -c cf_claims gates/retired-phrases.sh` → `0`
      (the comment that records why the string is gone was reworded to avoid
      re-introducing the token). The run reports
      `      ROSTER: 10 armed row(s) planted, 1 pending row(s) skipped`
      and `      SKIPPED RP11  PENDING on the live board — its plant starts
      running when the row arms`.
- [x] The floor line reads `(uncovered: none)` and is a PASS:
      `PASS  selftest: every armed claim has a per-phrase counterfactual
      (uncovered: none)` — against `uncovered: RP9` on the pre-change script
      in the same session.
- [x] RP9's plant produces the FAIL line. Reproduced by hand on a
      `scratch_tree` copy with the row's own sentence appended to the host:

      ```
      FAIL  RP9 CARRIER prds/06-help/prd.md carries `silently disable healing
            for the rest of the session` — retired by
            00-delivery/corrections/wezterm-repairing-latch-claim (done). Not
            exempt.
      FAIL  sweep: no armed row's phrase stands outside its allow-list (armed
            carriers: 1)
      ```

      and inside the selftest the same plant is asserted by
      `PASS  CF-RP9: and one FAIL line names both the phrase and
      prds/06-help/prd.md`.
- [x] RP11's row proved live once, out of band, per **Evidence** above. In a
      copy with `listing-order-comment` forced to `state: done` (`11 claims, 18
      phrases, 11 armed, 0 pending`):

      ```
      FAIL  RP11 CARRIER prds/06-help/prd.md carries `the auto-list append
            that names it` — retired by
            00-delivery/corrections/listing-order-comment (done). Not exempt.
      ```

      RP11 stays PENDING on the live board and plants nothing in the normal
      run — the `SKIPPED RP11` line above is the gate saying so.
- [x] The live run is unchanged **by this spec**. spec02's waiver has landed,
      so the bare form is the one quoted — this node's folder in place, no
      isolation needed:

      ```
      PASS  sweep: no armed row's phrase stands outside its allow-list (armed carriers: 0)
            MISSING []; UNEXPECTED []
      rc=0
      ```
- [x] Amendment 3 confirmed, all three measured before the edit in this
      session:

      ```
      RP9	ARMED	00-delivery/corrections/wezterm-repairing-latch-claim	00-delivery/corrections/wezterm-repairing-latch-claim (`done`)
      FAIL  selftest: every armed claim has a per-phrase counterfactual (uncovered: RP9)
      PASS  anchored: RP9 `silently disable healing for the rest of the session` is quoted inside its own retirer's folder (prds/00-delivery/corrections/wezterm-repairing-latch-claim/)
      ```

      The waiver reclassified this folder's occurrence to
      `TIER1	RP9	…	prds/00-delivery/corrections/phrase-sweep-selftest-inversion/specs/spec01.md`
      and the floor still caught the missing counterfactual — two different
      checks, which is the design working.
- [ ] **Not ticked, and the box is wrong rather than the work.**
      `git diff --stat gates/` names **two** files:

      ```
       gates/retired-phrases.sh | 577 +++++++++++++++++++++++++++++++++++++----------
       gates/waves.tsv          |  12 +-
      ```

      `gates/waves.tsv` is another lane's staged-with-unstaged-edits state
      (`AM`), mtime `Aug 23 17:46:30`, hours before this lane's first write at
      `21:41:50`; its md5 is `b1f150ede6fb4f94d8b53be571987b71` before and
      after this node's work, identical to the spec-time value. So the diff
      reports a file this lane never touched, and is simultaneously blind to
      the nineteen untracked entries in `gates/` — including
      `gates/retired-phrases.sh` itself, which only appears because another
      lane once `git add`ed it. Integrity is proved by content instead:
      per-function sha256 of the protected tables, mtimes across `gates/`, and
      the `waves.tsv` md5. See
      [`git-diff-integrity-boxes`](../../git-diff-integrity-boxes/prd.md) —
      not this node's to fix.

## Verify and Proof

```sh
cd /Users/feb/dev/dotfiles

# the floor, and the new RP9 plant
bash gates/retired-phrases.sh --selftest 2>&1 \
  | grep -E 'per-phrase counterfactual|RP9|^FAIL'

# no roster left behind
grep -c cf_claims gates/retired-phrases.sh

# the live run is unchanged
bash gates/retired-phrases.sh 2>&1 | tail -5; echo "rc=$?"

# nothing else in gates/ moved
git diff --stat gates/
```
