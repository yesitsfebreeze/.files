---
est: 1h
footprint:
  - gates/retired-phrases.sh
verify: "bash gates/retired-phrases.sh --selftest"
---

# spec02 — `--selftest`: eight counterfactuals, landed, plus R5's limitation

Two deliverables, one sitting.

1. Add `--selftest` to `gates/retired-phrases.sh`: eight per-phrase red
   counterfactuals, the narrowness counterfactual R2's acceptance box asks
   for, a `MISSING` counterfactual, a normalisation counterfactual, and the
   green counterfactual `gates/selftest.sh` requires.
2. Relay **R5's limitation** in the implementer report, already resolved
   below. Change no file it names.

Depends on [spec01](spec01.md). Run spec01 first.

## The contract every gate in `gates/` signs

`gates/selftest.sh` enumerates from `gates/waves.tsv`, so an unregistered
gate is not held to the contract automatically — sign it anyway, because
[spec01](spec01.md) hands registration to the orchestrator and the gate must
be ready for it:

1. `--selftest` accepted, exit 0 iff every half held.
2. Every mutation against a `scratch_tree` copy, never the real tree, on a
   `MUTATION:` line, under a declared `MUTATION HOST:`.
3. A green counterfactual: repair the known-red condition in a copy and
   assert exit 0. A gate that only proves it can fail has not proved it can
   pass.
4. The mutation is **checked, not claimed** — the meta-gate hashes the
   scratch root before and after.

Two mechanics `gates/audit-findings.sh` learned the hard way and this gate
inherits:

- **Never call `run` in the selftest's own shell.** `run` accumulates into
  the shared `rc`, so a scratch copy's deliberate FAIL would be counted as
  this script's own failure. Every selftest invocation goes through a
  subshell wrapper (`run_q`, `says`).
- **`--root DIR`** must be a real flag, exercised by every half, so the
  override the counterfactuals lean on is itself tested.

## The eight per-phrase counterfactuals — R3

One per **claim**, eight claims armed. Each plants the row's first phrase
string into a file that is **not** exempt for it, then requires the gate red
and the FAIL line to name that phrase and that file.

The planting host is chosen per row to be a file with no exemption for that
phrase and no plausible reason to carry it, so the counterfactual measures
the matcher and not a coincidence.

| # | claim | phrase planted | planted into |
|---|---|---|---|
| CF1 | RP1 | `stops EVERY PWD closure firing` | `prds/06-help/prd.md` |
| CF2 | RP2 | `the window dies` | `prds/04-shell/prd.md` |
| CF3 | RP3 | `resolves a closure's command calls at PARSE time` | `prds/02-terminal/prd.md` |
| CF4 | RP4 | `takes the whole shell down` | `prds/01-capsule/prd.md` |
| CF5 | RP5 | `no code path that reaches` | `prds/05-platform/prd.md` |
| CF6 | RP6 | ``where neither `nu` nor `tinty` resolves`` | `prds/03-editor/prd.md` |
| CF7 | RP7 | `the terminal owns the palette` | `docs/capabilities-nvim.md` |
| CF8 | RP8 | `refreshed out of the host keychain on every mount` | `docs/capabilities.md` |

Each is asserted twice, and both halves matter:

- `chk_ok` — **the mutation really landed.** A claimed mutation is not a made
  one; `gates/nushell-module-staging.sh` asserts this on every half for the
  same reason.
- `chk_fail` — the gate goes red, and `says` finds the FAIL line carrying
  both the phrase and the planted path.

Each planted line is appended as a **new paragraph naming the retired claim
as an assertion**, not as a quote, so the counterfactual is the defect and
not a near-miss. Example for CF4, appended to the copy's
`prds/01-capsule/prd.md`:

```
A `source` of a missing file is a parse error that takes the whole shell
down, so the module and its line land together.
```

## CF9 — the allow-list is not a blanket

This is the PRD's acceptance box *"a phrase planted in a correction body
that is not about that phrase goes red"*. It is the whole argument for
pair-keying, so it gets its own half.

Plant RP2's `dies immediately` into
`prds/00-delivery/corrections/stale-pwd-latch-carriers/prd.md` — a
correction body, under `corrections/`, exempt for RP1 and inside RP1's
retirer folder. Require:

- the gate red, and the FAIL line naming `dies immediately` **and** that
  path;
- and, in the same run, RP1's own phrases at that same path still exempt and
  reported in no FAIL line. The waiver is per phrase, and the run proves it
  is per phrase.

Then the mirror, so the tier boundary is measured from both sides: plant
RP2's `dies immediately` into
`prds/00-delivery/corrections/gui-dies-claim-carriers/prd.md`, which **is**
RP2's retirer folder, and require the gate **green** on that mutation alone.
Tier 1 is a deliberate waiver, and a counterfactual that never exercises it
leaves the design unproven.

## CF10 — `MISSING`, the half that keeps the list from becoming a blanket

Delete the exempted occurrence of `the terminal owns the palette` from
`AGENTS.md` in the copy. Require the gate red with
`MISSING [the terminal owns the palette :: AGENTS.md]` and `UNEXPECTED []`.

Without this half an allow-list only ever grows. A stale exemption is a hole
that nobody can see, and it is how a pair table turns into the blanket R2
forbids.

## CF11 — normalisation, both halves, in one mutation

Append RP3's phrase to `prds/06-help/01-content-model/prd.md` **wrapped
across two lines at a space**, at ~78 columns like the rest of the tree:

```
The old note said nushell resolves a closure's command calls at PARSE
time, which is why the anchor order is what it is.
```

Require:

- the gate red and the FAIL line naming the file — the normalised matcher
  sees it;
- and, in the same half, `/usr/bin/grep -qF` for the same phrase in the same
  file exits **non-zero** — the raw matcher does not.

That pairing is R4's whole argument and it is cheap to assert. Then the same
mutation inside a `>` blockquote, wrapped the same way, to hold the
blockquote strip down.

## CF12 — the green counterfactual

Repair the six armed carriers in a copy — Findings A and B from
[spec01](spec01.md) — and require exit 0.

The repair is mechanical and must not be mistaken for the fix those nodes
owe: in the copy only, replace `takes the whole shell down` with
`discards the whole file` in the four RP4 carriers, and drop the sentence
carrying `no code path that calls … outside the \`_capsule_owned\` set` from
the RP5 carrier. Assert the copy is red **before** the repair and green
after, so the green half cannot pass by accident.

Say in the report that this is a scratch repair with no bearing on the real
files: the wording those two nodes land is theirs to choose.

## CF13 — isolation

`snapshot_paths --deep` over `prds`, `docs` and `AGENTS.md` around the whole
selftest, and `assert_unchanged` at the end. `docs/` is in
`gates/selftest.sh`'s HARD guarded set, so a byte written there is an
attributable failure; `prds/` is SOFT and reported INDETERMINATE, which is
exactly why this gate must carry its own guard rather than relying on the
meta-gate.

## R5 — what this cannot do, and why it is still worth having

**Relay this in the report. It is the PRD's third acceptance box.**

### The limitation

The gate catches a retired phrase coming back **verbatim**, over normalised
text, with per-word width. It cannot catch the same false claim **reworded**,
and rewording is the likelier failure. The instance is in the tree today and
[spec01](spec01.md)'s Finding B names it: `capsule.nu` said *"no code path
that **reaches** `docker rm`"*, and
`prds/01-capsule/01-container-lifecycle/specs/spec01-capsule-cli.md:102`
says *"no code path that **calls**"*. One verb. The retirer's own closing
grep returned zero and the carrier stood.

### The recommendation: do not attack it

Three measurements, not three opinions.

**1. The semantic sweep's noise floor is too high to gate, and it grows.**
[`gui-dies-claim-carriers`](../../gui-dies-claim-carriers/prd.md)'s
three-dimensional census is the most developed prior art on this board, and
it is a **human-read** sweep: dimension A gave 160 hits over `prds/ docs/`,
60 after intersecting with a launch-noun set, every one triaged by hand.
Re-run 2026-08-23: **216 raw, 107 intersected** — up 35% and 78% in one day,
because five lanes are writing the tree. That is one claim. Eight claims put
~850 lines in front of a reader on every sweep. A gate a human must triage
is a report, and this suite already learned what a report that always prints
becomes.

**2. Any narrowing of that sweep fails open, which is the defect.** The
alternative to 107 lines is an intersection tight enough to be quiet, and a
tight intersection is a guard that misses. `gui-dies-claim-carriers`' own
spec lists four classes its census would still miss *after* three
dimensions, including "a claim that names neither a death verb nor the
subject". Shipping that as a gate would promise semantic coverage and
deliver a lexicon — the same shape as the eight wrong reasons this family of
nodes exists to correct.

**3. The board's own record says a word never caught one of these.**
[`census-verdict-discipline`](../../census-verdict-discipline/prd.md) closed
`done` with exactly this on the record: *"These rules catch nothing on their
own."* Eight wrong reasons, every one found by someone running the claim or
widening a grep. Nothing found by matching text.

### Why the verbatim guard still earns its place

Because **verbatim is the measured propagation mechanism on this board.**
Every one of the eight claims was written once and then travelled by
copy-paste, because a later document quotes an earlier one:

- `gui-dies` — `terminal-inventory-path-claim` R4 asserted "this inventory
  is the last carrier"; **five** more stood, three of them byte-identical.
- `stale-pwd-latch-carriers` — the same claim, two more carriers, both in a
  `done` PRD, both quoting the original.
- [`truncated-source-attributions`](../../truncated-source-attributions/prd.md)
  — seven became nine on a re-census, same shape.
- Finding A in [spec01](spec01.md) — four carriers of RP4, all four using
  the same fifteen-word sentence.

Fifteen of the sixteen carriers found across those four nodes were verbatim
or near-verbatim. One — Finding B — changed a verb. The guard covers the
class that has actually happened, at the cost of one 3.3 s grep, and it
covers it *forward*: a pending row arms itself when its retirer reaches
`done`, so the next node that claims "the last carrier" has that claim
checked rather than believed.

### The answer for `census-verdict-discipline`

That node's Out of scope left one question open: *"Whether prose discipline
can be gated at all is a real question."* Settled here, and the line is
sharp:

- **A closed vocabulary is gateable.** "The word `exact` must not appear as
  a census verdict" has an enumerable violation set — one word — and the
  same normalised matcher and pair-keyed allow-list this gate ships would
  hold it. That node's R1 is gateable; the row would look exactly like RP1.
- **A mechanism claim is not.** "This sentence must not assert a false
  radius" has an open violation set. No table enumerates it, and every
  approximation fails open.

So the gateable half of that node is its vocabulary, not its verdicts, and
its R5 caution binds any node that tries: recommend the vocabulary row, and
do not let it be presented as catching wrong reasons. It catches one word.

## Acceptance

- [x] **Eight per-phrase counterfactuals, landed.** All eight quoted going
      red, each naming its phrase and its planted path. Eight `MUTATION:`
      lines, eight mutation-landed `chk_ok` PASSes.
      **Nine**, not eight, and the ninth is the design working:
      `autolist-width-guard-reason` closed `done` while the gate was being
      written, so `RP10` armed itself and arrived with no counterfactual.
      R3's whole point is that an armed row nobody has seen go red is a list,
      so `CF8b` plants `HANGS the shell inside the hook` into
      `prds/04-shell/prd.md`. A tenth check makes the *next* such arrival a
      FAIL rather than a silent gap: `selftest: every armed claim has a
      per-phrase counterfactual (uncovered: none)`, a maintained floor
      asserted against derived arming, the same shape as
      `nushell-module-staging.sh`'s `GATE_FLOOR`.
- [x] **CF9, both directions.** The phrase planted in a correction body that
      is not about it goes red and is named; the same phrase planted in its
      **own** retirer's folder is green. Both quoted. In the first run, RP1's
      phrases at that same path appear in no FAIL line — the waiver is per
      phrase, proved.
      Five PASS lines. The green half needed the six armed carriers
      scratch-repaired in the *same* copy first: otherwise "green" is
      unreachable for reasons that have nothing to do with the waiver under
      test, and a half that cannot go green proves nothing about tier 1.
- [x] **CF10, `MISSING`.** Deleting an exempted occurrence prints
      `MISSING [the terminal owns the palette :: AGENTS.md]` and
      `UNEXPECTED []`, quoted verbatim, and the gate is red. Reaching a bare
      `UNEXPECTED []` needs the six armed carriers repaired **and** RP9's
      three pending ones dropped in the same copy, because both flow into the
      printed `UNEXPECTED` list. The first attempt at the pending drop
      substituted the whole phrase per line and changed nothing — all three
      carriers wrap — and the half failed with three entries still listed.
      Fixed by rewriting `silently disable`.
- [x] **CF11, normalisation.** The wrapped plant is caught by the gate and
      **not** by `/usr/bin/grep -qF` on the same file — both results quoted
      side by side. The blockquote-wrapped plant is caught too. Five PASS
      lines across two copies, each asserting the raw miss and the normalised
      hit on the same file in the same half.
- [x] **CF12, green.** The copy is red before the scratch repair and exits
      **0** after. Quote both exit codes. `CF12: the untouched copy is red`
      (a `chk_fail`, so the copy exited non-zero) and `CF12: with the six
      armed carriers repaired, the gate exits 0`. A fourth half shows an
      unarmed row's carriers do not move the verdict: dropping RP9's three
      leaves the copy red for the six armed ones.
- [x] **CF13, isolation.** `assert_unchanged` over `prds`, `docs` and
      `AGENTS.md` PASSes at the end of the selftest, and every mutation host
      is a `scratch_tree` copy under the declared `MUTATION HOST:`. A second
      half hashes the repo root's own listing across the whole selftest
      (`c5b638fb…`, identical), because counterfactual runs have been leaking
      zero-byte artifacts into the root — three sit there now, owned by
      [`gate-artifact-leakage`](../../gate-artifact-leakage/prd.md), and this
      selftest runs 17 mutations.
- [x] **`bash gates/retired-phrases.sh --selftest` exits 0.** Tally quoted,
      not asserted. Run **alone** — three implementers are working and a
      concurrent lane writing `prds/` changes what the sweep reads.
      `selftest exit=0`, **49 PASS / 0 FAIL**, 17 `MUTATION:` lines, 1:30
      wall. Run alone; `CF13` would have caught a concurrent write to
      `prds/`, `docs/` or `AGENTS.md` and did not fire.
- [x] **The contract holds.** `--selftest` prints at least one `MUTATION:`
      line and one `MUTATION HOST:` line, and `run` is never called in the
      selftest's own shell — grep the script and quote the wrapper. 17
      `MUTATION:` lines and one `MUTATION HOST:`. The wrappers are
      `run_root()`, `run_q()`, `says()`, `fail_names()` and
      `no_fail_names()`, each a subshell around
      `bash "$GATES_DIR/retired-phrases.sh" --root "$1"`;
      `grep -n '^  *run '` over the script returns nothing, so `run` is
      never reached in the selftest's own shell.
- [x] **R5 is in the report, plainly.** The limitation, the recommendation
      not to attack it with the three measurements, the reason the verbatim
      guard still earns its place, and the answer handed to
      `census-verdict-discipline`. All four are in the implementer report and
      the first three are also in the script's own header, so a reader of the
      gate cannot mistake a lexicon for semantics.
- [x] **The plain run is still red for the same six carriers**, unchanged by
      this spec. `bash gates/retired-phrases.sh` exits 1 with six FAIL
      CARRIER lines. `plain exit=1`,
      `grep -c '^FAIL  RP[0-9]* CARRIER'` = **6**, the same four RP4 paths
      and the one RP5 path.
- [x] **`gates/waves.tsv` unedited**, read and confirmed.
      `grep -c 'retired-phrases' gates/waves.tsv` = `0`, and wave 0's cell
      still ends `bash gates/nushell-module-staging.sh`.

## Verify and Proof

```sh
cd /Users/feb/dev/dotfiles

# the selftest, alone
bash gates/retired-phrases.sh --selftest 2>&1 \
  | tee /tmp/rp-selftest-$$.txt | tail -5
echo "exit=$?"                                              # 0
/usr/bin/grep -c '^PASS' /tmp/rp-selftest-$$.txt
/usr/bin/grep -c '^FAIL' /tmp/rp-selftest-$$.txt            # 0

# the contract
/usr/bin/grep -c 'MUTATION:' /tmp/rp-selftest-$$.txt        # >= 13
/usr/bin/grep -m1 'MUTATION HOST:' /tmp/rp-selftest-$$.txt

# every counterfactual named its phrase
/usr/bin/grep -E '^PASS  (CF[0-9]+|selftest)' /tmp/rp-selftest-$$.txt

# CF9's per-phrase waiver, and CF10's MISSING line
/usr/bin/grep -F 'stale-pwd-latch-carriers' /tmp/rp-selftest-$$.txt
/usr/bin/grep -F 'MISSING [the terminal owns the palette' /tmp/rp-selftest-$$.txt

# CF11: normalised finds it, raw does not — the same pair, printed together
/usr/bin/grep -A2 -F 'CF11' /tmp/rp-selftest-$$.txt

# run() is never called in the selftest's own shell
/usr/bin/grep -nE '^(run_q|says|run_root)\(\)' gates/retired-phrases.sh

# the plain run is unchanged: still six armed carriers
bash gates/retired-phrases.sh | /usr/bin/grep -c '^FAIL.*CARRIER'   # 6
bash gates/retired-phrases.sh > /dev/null; echo "plain exit=$?"     # 1

# the registry, read not written
/usr/bin/grep -n 'retired-phrases' gates/waves.tsv || echo "not registered, as designed"
git status --porcelain
```
