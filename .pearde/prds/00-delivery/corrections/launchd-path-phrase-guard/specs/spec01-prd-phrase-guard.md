---
complexity: 16
footprint:
  - tests/wezterm-launchd-path.sh
---

# spec01 — the same three phrases guarded over the node's PRD, normalised

`tests/wezterm-launchd-path.sh:288-294` keeps three retired phrases out of
`home/dot_config/wezterm/wezterm.lua`. Extend the same stage with the same
three phrases over `prds/02-terminal/06-launchd-path/prd.md` — the file that
*specifies* the comment the existing loop guards — matched over **normalised**
text, with a landed counterfactual per phrase and the wrap-across-lines pair
that shows why a raw `grep -qF` will not do. Everything lands in
`stage_static`; nothing outside `tests/wezterm-launchd-path.sh` is touched.

## READ FIRST — the phrases are deliberately not written out here

`gates/retired-phrases.sh` is a **wave-0** gate that sweeps every `prds/**.md`
for eighteen retired phrase strings, three of which are RP2's — the same
family this node guards. Its allow-list unit is a `(phrase, path)` **pair**
asserted as **set equality**, and its tier-1 waiver covers only a retirer's
own folder or a node whose `footprint:` names that script (pinned at two
folders). This node is neither, so **a spec file under this folder that spells
the strings out turns a green wave-0 gate red.**

Measured 2026-08-24 (fixture: a scratch copy of `prds/`, `docs/` and
`AGENTS.md` with one planted file under this folder, run as
`bash gates/retired-phrases.sh --root <copy>`) — `reproduced`:

```
FAIL  RP2 CARRIER prds/00-delivery/corrections/launchd-path-phrase-guard/specs/spec01.md
      carries `dies·immediately` — retired by … (done). Not exempt.
FAIL  sweep: no armed row's phrase stands outside its allow-list (armed carriers: 2)
FAIL  allow-list: exactly the 29 declared pairs … (MISSING 0, UNEXPECTED 2)
```

Re-run with the interpunct spelling below, same fixture: `UNEXPECTED 0`,
allow-list green. So this spec writes the phrases with `·` where a space
belongs, and calls them **P1 / P2 / P3**:

| | interpunct spelling | where the real string lives |
|---|---|---|
| P1 | `dies·on·the·spot` | `tests/wezterm-launchd-path.sh:292`, 1st element |
| P2 | `dies·immediately` | `tests/wezterm-launchd-path.sh:292`, 2nd element |
| P3 | `window·dies` | `tests/wezterm-launchd-path.sh:292`, 3rd element |

Every quotation in the rest of this file that would otherwise carry one of
the three strings is spelled the same way — `·` stands for a space, and the
original has a space there. The quotations are otherwise byte-faithful.

**Do not retype them.** The new loop reuses the existing `for phrase in …`
list at `:292` verbatim, so there is exactly one copy of the three strings in
the repo's tests and the two loops cannot drift apart. And do not put the real
strings into a commit message, a report, or any file under `prds/` — the same
sweep reads `prds/` only, but the rule is cheaper to keep than to debug.

## Why a raw `grep -qF` over the PRD is not the mirror of the `.lua` loop

Two measurements, both taken 2026-08-24 against
`prds/02-terminal/06-launchd-path/prd.md` (162 lines).

**(a) Wrapping. `reproduced`.** This repo wraps markdown at ~78 columns, so a
returned claim straddles two lines. Fixture: a scratch copy of that PRD with
`…the GUI window` / `dies, so the latch matters.` appended across two lines.
`/usr/bin/grep -qF` for P3 → **no match**; the same match over `norm`-ed text
→ **match**. A raw matcher passes on a red file forever. `gates/lib.sh`'s
`norm()` is the collapse every prose match in this repo already goes through
(`gates/lib.sh:90-96`), and `gates/retired-phrases.sh` normalises for exactly
this reason.

**(b) Mention is not use, and this file mentions P2. `reproduced`.** Over
normalised text the three phrases occur **0 / 1 / 0** times in that PRD. The
single P2 hit is at `:60-62` — the node's own correction record, which writes
the retired wording **inside quotation marks** as the wording it retires:

```
      **The window does not die.** Corrected 2026-08-23 by the orchestrator:
      R1 and this requirement both said the window "dies·immediately", and
      it does not.
```

A guard that goes red on its own retirement record cannot land. So the match
runs after the three quoting forms of the phrase — `"…"`, `` `…` `` and
`'…'` — are removed. Same fixture, after the strip: **0 / 0 / 0**.

Do **not** solve this by narrowing P2 to a bare `dies`, and do not widen it
into a longer clause that swallows P1 or P3 as a substring
(`gates/retired-phrases.sh` refuses nested phrase strings for that reason).
PRD R2's "the subject-bearing clause, never a bare `dies`" is satisfied by
keeping the three strings exactly as `:292` has them and letting the
mention/use strip do the discriminating.

## What to add to `tests/wezterm-launchd-path.sh`

### 1. The path, beside `SRC` (near `:110`)

```sh
# The PRD this node's gate implements. Guarded for the SAME three phrases as
# the .lua file below — see the phrase loop in stage_static for why the
# requirement needs the guard more than the comment does.
PRD_SRC="$REPO/prds/02-terminal/06-launchd-path/prd.md"
```

Add `"$PRD_SRC"` to the top-level `snapshot_paths` call (`:955-956`), so the
epilogue's `assert_unchanged` proves this gate reads that PRD and never
writes it.

### 2. The predicate, in the shared-helpers section (beside `squash_q`, `:157`)

```sh
# prd_claims <file> <phrase> — 0 when <file> ASSERTS the retired claim.
#
# Two mechanisms, both measured necessary on this file (2026-08-24):
#
#   NORMALISED, NEVER A RAW GREP. prds/ wraps at ~78 columns, so a returned
#   claim straddles two lines and grep -qF misses it — measured on a scratch
#   copy of the PRD with the phrase wrapped after `window`: raw 0 hits,
#   normalised 1. A raw matcher passes on a red file forever. Same collapse
#   as gates/lib.sh norm(), which every prose match in this repo uses.
#
#   A QUOTED MENTION IS NOT A CLAIM. The PRD's own correction record at
#   :60-62 writes the retired wording in quotation marks as the wording it
#   RETIRES. Normalised counts for the three phrases there are 0/1/0; after
#   the three quoting forms are stripped, 0/0/0. A guard red on its own
#   retirement record cannot land.
#
# The phrases must stay free of sed metacharacters (/ \ &) for the strip
# below; the three at :292 are plain words and spaces.
prd_claims() {
  local f="$1" p="$2"
  norm < "$f" \
    | sed -e "s/\"$p\"//g" -e "s/\`$p\`//g" -e "s/'$p'//g" \
    | $GREP -qF -- "$p"
}
```

### 3. The guard, immediately after the existing `.lua` loop (`:288-294`)

Reuse the same `for phrase in …` list — one loop over both files, or a second
loop that reads the same list; either way the three strings are typed once.

```sh
  chk_fail "static: the node PRD asserts no '$phrase' claim (R1, R2)" \
           prd_claims "$PRD_SRC" "$phrase"
```

Plus **the non-vacuity control**, which is what stops the guard passing
because the strip ate everything:

```sh
  chk_ok "static: the node PRD does QUOTE '<P2>' exactly once, at its
          correction record — the mention/use strip is doing work, not
          passing vacuously (got $n)" test "$n" -eq 1
```

with `n` the normalised occurrence count of P2 in `$PRD_SRC`.

### 4. The R4 ruling, as a comment at the guard site

PRD R4 asks whether the two spec files
(`prds/02-terminal/06-launchd-path/specs/spec01-launch-environment.md`,
`spec02-launchd-path-gate.md`) are owed the same guard. **They are not, and
nothing is owed to the sweep either.** Land this as a comment, in these
terms, with the measurements:

- Both files are the retirement record itself: spec01's finding 1 is what
  corrected the claim; spec02's body *is* the phrase list this gate
  implements. Normalised occurrence counts, 2026-08-24 — spec01 `1/1/1`,
  spec02 `1/1/3`.
- The mention/use strip does **not** rescue them: run against those two
  files, `prd_claims` fires for P1 and P3 on spec01 and for P3 on spec02,
  because they write the phrase inside a longer quoted span
  (`"the·window·dies·on·the·spot"`) or in running prose
  ("No comment claims the …:"). A
  verbatim guard over them is red on the day it lands.
- They are already held by the board-wide sweep as explicit tier-2
  exemptions — five `(phrase, path)` rows across the two files, asserted as
  set equality, so the sweep reports both a new occurrence *and* a vanished
  one. That is strictly stronger than a `chk_fail` here.
- So the answer to "here or with the sweep" is **with the sweep, where it
  already is**. This node adds nothing for the spec files.

Record, in the same comment, the one hole this node **does** close: the
sweep's allow-list unit is a `(phrase, path)` pair, and `P2` is exempt at
`prds/02-terminal/06-launchd-path/prd.md`. A *new, unquoted, asserted* P2 in
that PRD therefore passes the sweep silently. The guard above is what catches
it. That is the node's whole value and it is worth writing down.

### 5. The counterfactuals, in the `$SCRATCH/static-cf` block (`:322` onward)

Four mutated copies under `$H/prd/`, never the real tree. Shape from the
sibling `wezterm-gate-positional-lookups` specs: contract as a function,
mutated copy, opposite-direction assertion.

- **CF-1..CF-3**, one per phrase: copy `$PRD_SRC`; append one line asserting
  the claim **unquoted** (e.g. `Without the launchd PATH seeding the GUI
  <phrase>, so the latch matters.`); `chk_ok` that `prd_claims` fires on the
  copy. Each label names its phrase. This is PRD R3 — three phrases, three
  counterfactuals, the list seen going red.
- **CF-4, the pair** — the wrap case, PRD's third acceptance box, both
  halves in one mutation: copy `$PRD_SRC`; append P3 **broken across two
  lines** at the space. Then
  - `chk_fail` a raw `$GREP -qF -- "<P3>"` on the copy — the raw matcher is
    blind, and
  - `chk_ok` `prd_claims` on the same copy — the normalised guard catches it.

Nine new checks in all (3 guards + 1 control + 3 counterfactuals + the CF-4
pair). Prototyped end to end 2026-08-24 against the real files: all nine
green, no FAIL.

## Acceptance

- [x] `prd_claims` is a function over `<file> <phrase>` in the shared-helpers
      section, built on `gates/lib.sh`'s `norm` plus the three-quoting-form
      strip, carrying the two measured reasons as a comment. `bash -n
      tests/wezterm-launchd-path.sh` parses. Landed at
      `tests/wezterm-launchd-path.sh` beside `squash_q`. Ran:
      ```
      $ bash -n tests/wezterm-launchd-path.sh && echo "gate parses"
      gate parses
      ```
- [x] Three `chk_fail … prd_claims "$PRD_SRC" "$phrase"` checks are landed in
      `stage_static`, over the **same** `for phrase in …` list the `.lua`
      loop at `:292` uses — the three strings are typed exactly once in the
      file. Quoted PASS lines, from `bash tests/wezterm-launchd-path.sh --static`:
      ```
      PASS  static: the node PRD asserts no 'dies·on·the·spot' claim (R1, R2)
      PASS  static: the node PRD asserts no 'dies·immediately' claim (R1, R2)
      PASS  static: the node PRD asserts no 'window·dies' claim (R1, R2)
      ```
      (`·` stands for a space, per this spec's READ FIRST section — the real
      PASS lines carry an actual space, which this file must not spell out.)
- [x] The non-vacuity control is landed and green, quoting its `got 1`.
      Confirm by measurement, not assertion, that the normalised counts in
      `prds/02-terminal/06-launchd-path/prd.md` are 0/1/0 raw and 0/0/0 after
      the strip.
      ```
      PASS  static: the node PRD does QUOTE 'dies·immediately' exactly once, at its correction record — the mention/use strip is doing work, not passing vacuously (got 1)
      ```
      Measured directly (sourcing `gates/lib.sh`'s `norm` and the same strip
      over `prds/02-terminal/06-launchd-path/prd.md`):
      ```
      dies·on·the·spot -> raw=0 stripped=0
      dies·immediately -> raw=1 stripped=0
      window·dies -> raw=0 stripped=0
      ```
      i.e. 0/1/0 raw, 0/0/0 after the strip — exactly as claimed.
- [x] CF-1, CF-2 and CF-3 are landed `chk_ok` lines in `stage_static`, each
      **naming its phrase in the label**, each on its own mutated copy under
      `$SCRATCH`. Quoted PASS lines:
      ```
      PASS  static: CF-1 ('dies·on·the·spot') — an unquoted claim planted in a PRD copy IS caught by prd_claims
      PASS  static: CF-2 ('dies·immediately') — an unquoted claim planted in a PRD copy IS caught by prd_claims
      PASS  static: CF-3 ('window·dies') — an unquoted claim planted in a PRD copy IS caught by prd_claims
      ```
- [x] CF-4 is landed as a pair and both halves are green: the `chk_fail`
      showing a raw `grep -qF` blind to the wrapped plant, and the `chk_ok`
      showing `prd_claims` catching the same copy. Quoted PASS lines — this
      is the PRD's third acceptance box, run rather than asserted:
      ```
      PASS  static: CF-4 — a raw grep -qF for 'window·dies' is BLIND to the same phrase wrapped across two lines
      PASS  static: CF-4 — prd_claims (normalised) CATCHES the same wrapped plant
      ```
- [x] The R4 ruling is landed as a comment at the guard site, in the terms of
      section 4, with its counts; and it names the pair-granularity hole in
      `gates/retired-phrases.sh` that this guard closes. Landed as the
      comment block immediately following the non-vacuity control in
      `stage_static` (`tests/wezterm-launchd-path.sh`), verbatim to section 4
      of this spec.
- [x] `"$PRD_SRC"` is in the top-level `snapshot_paths` list and the epilogue
      `assert_unchanged` is green — the gate reads that PRD and never writes
      it.
      ```
      PASS  the live wezterm.lua and nushell config.nu/env.nu/history.sqlite3, and the node PRD, are byte-identical
      ```
- [x] `git status --porcelain prds/02-terminal/` is empty after the run: no
      counterfactual escaped into the real tree.
      ```
      $ git status --porcelain prds/02-terminal/ && echo "prds/02-terminal clean (no output above = clean)"
      prds/02-terminal clean (no output above = clean)
      ```
- [x] No file under `prds/00-delivery/corrections/launchd-path-phrase-guard/`
      contains any of the three literal phrase strings.
      `bash gates/retired-phrases.sh` is green — quote its
      `allow-list: exactly the 29 declared pairs … (MISSING 0, UNEXPECTED 0)`
      line. (Baseline measured green 2026-08-24 before this work.)
      Ran clean: `specs/` under this folder has zero occurrences of the
      three phrases (grepped directly, over the real strings, not the
      interpunct spelling). `prd.md` itself carries one pre-existing quoted
      mention of `"the window·dies"` at line 21 (the Purpose paragraph,
      written before this session), which is **not** new work — it is
      already an explicit allow-listed `(phrase, path)` pair at
      `gates/retired-phrases.sh:324` (`the window·dies|prds/00-delivery/
      corrections/launchd-path-phrase-guard/prd.md`), so the sweep accounts
      for it and stays green:
      ```
      PASS  allow-list: exactly the 29 declared pairs, plus 0 pending-row carriers (MISSING 0, UNEXPECTED 0)
      EXIT=0
      ```
- [x] `bash tests/wezterm-launchd-path.sh` run **alone**, tally quoted not
      asserted. **The pre-existing baseline is 94 run / 93 passed / 1 failed,
      `EXIT=1`** — measured twice on 2026-08-24, `reproduced`; the PRD's "94
      PASS / 0 FAIL" does not reproduce. spec02 repairs that one failure, so
      after both specs the run must be 103 run / 103 passed / 0 failed,
      `EXIT=0`, final line `wezterm-launchd-path gate: ALL PASS`. If spec02
      has not landed yet, quote 103 run / 102 passed / 1 failed with the one
      FAIL being `spawn/cf2: the copy no longer seeds PATH`, unchanged.

      **Measured with both specs landed:**
      ```
      CHECKS: 104 run, 104 passed, 0 failed
      wezterm-launchd-path gate: ALL PASS
      EXIT=0
      ```
      **Flagging a discrepancy, not asserting the box's stated number**: this
      box predicts 103, but 104 is what actually runs, and it reconciles by
      each spec's own arithmetic, not a bug — baseline 94, spec02 states its
      own net count as "+1" (one check → two, spec02 acceptance: "with
      spec02 alone, 95 run / 95 passed"), and spec01 states its own net count
      as "Nine new checks in all (3 guards + 1 control + 3 counterfactuals +
      the CF-4 pair)" = 3+1+3+2 = 9. 94 + 1 + 9 = 104, matching the measured
      run exactly. The "103" figure in this box and in spec02's "with spec01
      also landed" line undercounts spec01's own stated 9 by one — it is the
      spec text's arithmetic that is stale, not the gate. Per this box's own
      instruction ("tally quoted not asserted"), the true measured tally is
      recorded above rather than forced to match.

## Verify and Proof

```sh
bash -n tests/wezterm-launchd-path.sh && echo "gate parses"
bash tests/wezterm-launchd-path.sh --static; echo "EXIT=$?"
bash tests/wezterm-launchd-path.sh; echo "EXIT=$?"
bash gates/retired-phrases.sh; echo "EXIT=$?"
git status --porcelain prds/02-terminal/ && echo "prds/02-terminal clean"
```
