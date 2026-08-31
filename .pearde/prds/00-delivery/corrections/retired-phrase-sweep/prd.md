---
state: done
claim: 
priority: 28
est: 2.5h
actual: 35m
mode: afk
footprint:
  - gates/retired-phrases.sh
  - gates/waves.tsv
verify: ""
origin: derived
---

# Nothing stops a retired claim coming back

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: eight recorded reasons have been corrected on this board, several of
them in more than one carrier. Every correction so far guards **its own
file** — `PB.1` guards `config.nu`, the width-guard node will guard
`config.nu` — and **nothing guards the PRD bodies**, which is where the
carriers keep turning up. `terminal-inventory-path-claim` asserted it had
fixed "the last carrier" of one claim and left **four**.

So the class needs a tree-wide sweep, and `autolist-width-guard-reason`'s R5
established why it cannot live in any existing gate:

1. A PRD-body grep inside a wave-3 **config** gate red-lights the wrong lane.
2. A gate asserting another node's PRD body is a cross-node write lock
   against one-writer-per-file.
3. Decisively: **a naive tree-wide grep goes red on its own correction.**
   `stale-pwd-latch-carriers/prd.md` still carries one
   `for the rest of the session` — quoted as retired, by design. The same trap
   appears in miniature everywhere: a correction must quote the wording it
   retires in order to retire it.

`gates/audit-findings.sh` already walks every board `prd.md`, so the shape
exists. `gates/nushell-module-staging.sh` is the precedent for a
cross-cutting gate that derives both sides.

## Requirements
- [x] **R1** — A tree-wide gate with a **banned-phrase table**, one row per
      retired claim, each carrying the node that retired it. Start from the
      eight already corrected; the table is the deliverable, not the script.
- [x] **R2** — **An allow-list for correction bodies**, because a node that
      retires a phrase must quote it. Design this carefully: an allow-list
      keyed on "any file under `corrections/`" is too wide — it would let the
      phrase return inside a *new* correction that is not about it. Recommend
      a form that is narrow enough to bite, and say what it cannot catch.
- [x] **R3** — **A red counterfactual per phrase**, landed in the gate, not
      run by hand. Eight phrases, eight counterfactuals. A banned-phrase
      table nobody has seen go red is a list, not a check.
- [x] **R4** — Phrases are matched over **normalised** text. The retired hang
      claim wraps across two comment lines, so a raw `grep -qF` for it passes
      on a red file forever — measured. And phrases must be chosen at the
      right width: `HANGS the shell inside the hook`, never `HANGS`.
- [x] **R5** — Say what this **cannot** do. It catches a phrase coming back
      verbatim; it cannot catch the same false claim **reworded**, which is
      the likelier failure. Recommend whether that is worth attacking at all,
      and if not, say so — an overclaimed guard is exactly the defect this
      whole family of nodes is about.
- [x] **R6** — Registration in `gates/waves.tsv` is the **orchestrator's**;
      report the wave and the segment. Wave 0 is the precedent for a
      tree-wide gate, and it is currently ARMED and green, so a red
      registration would be a real regression rather than a pending one.

## Acceptance
- [ ] The gate is green, and every one of the eight counterfactuals is quoted
      going red and naming its phrase.
      *(b) — the open half is the settled design: the gate is red on purpose
      (six armed carriers filed as `shell-down-spec-carriers` and
      `capsule-rm-reworded-claim`), and this box closes when those two
      land.*
      *Half met, and the open half is the settled design.* The
      counterfactuals hold: **nine**, not eight — `CF1`–`CF8` plus `CF8b`,
      because `autolist-width-guard-reason` closed `done` while the gate was
      being written and armed `RP10` by itself — each quoted going red and
      naming its phrase, `--selftest` exiting 0 at 49 PASS / 0 FAIL. The gate
      itself is **red on purpose**: six armed carriers stand, filed as
      [`shell-down-spec-carriers`](../shell-down-spec-carriers/prd.md) (four)
      and [`capsule-rm-reworded-claim`](../capsule-rm-reworded-claim/prd.md)
      (two), and correcting them is forbidden by this node's Out of scope.
      This box closes when those two land.
- [x] The allow-list is shown **not** to be a blanket exemption: a phrase
      planted in a correction body that is not about that phrase goes red.
      `CF9`: `dies immediately` planted in
      `stale-pwd-latch-carriers/prd.md` — a correction body that is exempt
      for `RP1` and sits inside `RP1`'s retirer folder — goes red and is
      named, while `RP1`'s own `dirstack included` and `stops every PWD
      closure` at that same path stay exempt in the same run. The waiver is
      per phrase, and the run proves it is per phrase.
- [x] R5's limitation is in the report, plainly stated. It is also in the
      script's own header, so a reader of the gate cannot mistake a lexicon
      for semantics.
- [ ] `bash gates/wave-status.sh --run 0` green after registration.
      **Not runnable yet, and deliberately so.** R6 holds the registration
      until the two findings above land: wave 0 is ARMED and green, so a red
      gate there is a real regression rather than a pending one.
      *(b) — deliberately not runnable: registration is held until the two
      findings above land.*
      `gates/waves.tsv` is unedited — its wave-0 cell still ends
      `bash gates/nushell-module-staging.sh`.

## Out of scope
- Correcting any carrier. Each is its own node, and several are already done.
- Enforcing the census vocabulary, which is
  [`census-verdict-discipline`](../census-verdict-discipline/prd.md).

## Settled at spec time, 2026-08-23 — read this before implementing

**R5: do not attack the reworded case.** Recommended `no`, on three
measurements, and the orchestrator accepts it.

1. The semantic sweep's noise floor is a **report, not a gate**:
   `gui-dies-claim-carriers`' dimension A measured 160/60 yesterday and
   **216/107 today**, for one claim. Eight claims put ~850 lines in front of a
   reader per run, and the floor **grows with the tree** while the verbatim
   guard stays one 3.3 s grep.
2. Any narrowing tight enough to be quiet **fails open** — `gui-dies`' own
   spec lists four classes it still missed after three dimensions. Shipping
   that as a gate promises semantics and delivers a lexicon: the exact defect
   this family of nodes exists to correct.
3. `census-verdict-discipline` closed `done` today saying it on the record —
   *"These rules catch nothing on their own."*

**The verbatim guard still earns its place, because verbatim is the measured
propagation mechanism.** Of the sixteen carriers found across
`gui-dies-claim-carriers` (5), `stale-pwd-latch-carriers` (2),
`truncated-source-attributions` (7→9) and Finding A below (4), **fifteen were
verbatim or near-verbatim. Exactly one changed a verb.**

**The highest-value design decision: arming is derived from the retirer's
`state:`, not written per row.** Eleven claims, 18 phrase strings, 8 armed;
three PENDING rows arm themselves when their retirer flips to `done`. So
`terminal-inventory-path-claim` **could not have closed `done`** while five
carriers of its claim stood. That is the class fixed forward, not just the
instances fixed backward.

**Width was measured, not chosen.** Every shorter form collides today:
`for the rest of the session` → 23 hits, two about a different subsystem;
`on every mount` → collides with the latency argument the correction rests on;
`rather than dying` → collides with `06-help/01`'s unrelated `verify` walk, so
it is dropped from the GUI row entirely; `dies` → 216 raw hits.

**R2's allow-list is two-tier, and the obvious form was refuted by the tree.**
A `corrections/`-keyed list fails because three legitimate quotes live
**outside** `corrections/` — including a `done` *feature* PRD
(`04-shell/06-listing`) quoting the PWD latch to retire it. Tier 1 is derived
(a phrase is allowed under its own retirer's folder, so a retiring node's body
can grow without going red); Tier 2 is 28 explicit `(phrase, path)` pairs with
set equality. A heuristic exemption — "phrase near *Retired*" — was rejected
because it **fails open**, and the counterexample is already in the tree:
`04-shell/06-listing/prd.md:120-131` carries a `- **Retired.**` bullet whose
retirement `autolist-width-guard-reason` has since measured to be *itself*
wrong.

**R4 turned up a third normalisation case nobody predicted.** Markdown
blockquote markers survive whitespace collapse: `capsule-rm-guard-attribution`
quotes its retired claim in a wrapped `>` block, so collapsed text reads
`outside the > \`_capsule_owned\` set` and a fixed string misses. Stripping
leading `>` — the markdown analogue of `nushell-core.sh`'s `prose()` stripping
`#` — adds exactly that one pair and no others. Also: normalising per-phrase
costs **68 s**, normalising once and matching all 18 in one `grep -oFf` costs
**3.3 s**.

**The gate ships RED, and the red is correct.** Two findings, both prose,
neither this node's to fix — filed as
[`shell-down-spec-carriers`](../shell-down-spec-carriers/prd.md) and
[`capsule-rm-reworded-claim`](../capsule-rm-reworded-claim/prd.md). They are
what unblocks R6's registration.

**R6: hold the wave-0 registration until those two land.** Wave 0 is ARMED and
green, so a red gate there is a real regression rather than a pending one. The
precedent is exact: `gates/nushell-module-staging.sh` was written with one
known MISS, kept out of `waves.tsv` while it stood, and registered only after
`television-help-staging` closed it.

**One answer handed back to `census-verdict-discipline`** (`done`), whose Out
of scope left the gating question here: **a closed vocabulary is gateable** —
"the word `exact` must not appear as a census verdict" has an enumerable
violation set of one word, and this gate's matcher plus pair-keyed allow-list
would hold it as a row identical in shape to any other. **A mechanism claim is
not** — its violation set is open and every approximation fails open. So the
gateable half of that node is its **vocabulary**, not its verdicts.

## Landed 2026-08-23 — the gate ships red, with exactly the settled red

`bash gates/retired-phrases.sh` → **exit 1, 21 PASS / 8 FAIL, 2.84 s** over
377 files, re-run by the orchestrator. The naive per-phrase shape measured
68 s, so normalising once and matching all 18 in one pass is a **24× saving**
on a gate wave 0 pays every sweep.

Header: **`11 claims, 18 phrases, 9 armed, 2 pending`** — and the arming
number is the design working. `autolist-width-guard-reason` closed `done`
**during** the implementation, so **RP10 armed itself**; RP9's retirer moved
twice in the same hour. Arming is derived from each retirer's `state:`, never
written per row, which is why nothing had to be edited when that happened.

The six armed carriers are precisely the two filed findings — four RP4
([`shell-down-spec-carriers`](../shell-down-spec-carriers/prd.md)) and two RP5
at one path ([`capsule-rm-reworded-claim`](../capsule-rm-reworded-claim/prd.md))
— plus three `PENDING RP9` lines printed but excluded from the verdict. **No
carrier was corrected**, which is the rule.

**`--selftest`: 49 checks, and the fail-closed property fired for real.** The
declared allow-list is **29 pairs, not 28**: hours after spec01 was written,
this node's own analyst filed `capsule-rm-reworded-claim`, whose *purpose* is
retiring RP5's reworded carrier and which therefore quotes the claim at a path
no retirer folder covers. So a new legitimate quote went red until a human
added one row and, in adding it, judged that the quote really is a retirement.
The implementer also **rejected** the shortcut of adding that node to RP5's
`retired by` — arming is all-retirers-done, so it would have *disarmed* a
`done` correction and dropped the known red from 6 to 4.

**CF11 is the evidence that mattered**: a wrapped plant is missed by raw
`grep -qF` and caught by the gate, and a `>`-blockquote plant likewise —
`strip=100 nostrip=99`, one diff line, the `capsule-rm-guard-attribution`
quote.

## CF13 is a confirmed concurrent-write artifact, not a defect

`CF13: prds/, docs/ and AGENTS.md are byte-identical across the whole
selftest` **failed on both of my runs** and PASSed twice for its implementer.
The cause is measured, not guessed: the
[`mi-rooted-verify-commands`](../mi-rooted-verify-commands/prd.md) implementer
is repointing 62 carriers **right now**, and
`find prds -type f -newermt <4 min ago>` returned **12 files** under
`decisions/*/specs/`, `w0-4-s2-corrections/*/specs/` and
`gate-home-isolation/specs/`. An isolation check that hashes a tree another
lane is writing cannot pass while that lane runs.

**That is the third distinct concurrency artifact today** — after four
`wave-status --run 4` processes colliding on one scratchpad log filename, and
`gates/selftest.sh`'s root-hash false positive. The pattern is now clear
enough to state: **an isolation check that hashes a shared tree is not
trustworthy on a busy board**, and the durable fix is the one
[`gate-artifact-leakage`](../gate-artifact-leakage/prd.md) R4 already asks for
— derive the hash from tracked files plus an explicit allow-list, so a stray
or concurrent write is a *named* failure rather than a hash that silently
moved.

## Two acceptance boxes stay open, correctly

"The gate is green" cannot close while the two filed findings stand, and
`wave-status.sh --run 0` is not runnable until registration. **Registration is
held**: wave 0 is ARMED and green, a red gate there is a real regression, and
`gates/nushell-module-staging.sh` is the exact precedent. `grep -c
'retired-phrases' gates/waves.tsv` → **0**. The segment lands when
`shell-down-spec-carriers` (four one-line prose edits) and
`capsule-rm-reworded-claim` (one verb) close.
