---
est: 1.5h
footprint:
  - gates/retired-phrases.sh
verify: "bash gates/retired-phrases.sh"
---

# spec01 — `gates/retired-phrases.sh`, the banned-phrase table and its sweep

Build the gate: a banned-phrase table, a normalised sweep of the
specification surface, and a pair-keyed allow-list asserted as set equality.
The counterfactuals are [spec02](spec02.md) and **this node is not done
without them** — R3 says a table nobody has seen go red is a list.

**The gate ships RED, and the red is correct.** Six carriers of two already
retired claims survive in the tree, measured below. Do not fix them: the
PRD's Out of scope forbids it and each is its own node. Registration in
`gates/waves.tsv` is the orchestrator's and is **held** until they land —
`gates/nushell-module-staging.sh`'s precedent, argued in **Wave 0** below.

Write `gates/retired-phrases.sh` and nothing else. `gates/waves.tsv` is not
this executor's file.

## The measurement this spec rests on

Run 2026-08-23 over `prds/**/*.md` + `docs/*.md` + `AGENTS.md`, 354 files,
18 phrase strings, matched over normalised text: **69 (phrase, path)
pairs.** 3.3 s for the whole sweep.

The file count read **359** within the hour, because three lanes were
writing the board. Quote what you measure; the pair set below is stable and
the file count is not.

Three facts from that run, each of which changes the design:

1. **R4 is measured, not stylistic.** Two hits in the tree today are
   invisible to a per-line `grep -F` and visible only normalised:
   `takes the whole shell down` wraps across
   `prds/04-shell/02-aliases-utilities/specs/spec02-pass-completion.md:27-28`,
   and `the terminal owns the palette` wraps across
   `prds/00-delivery/corrections/w0-4-s2-corrections/delivery/prd.md:44-45`.
   Both `/usr/bin/grep -c` to **0**. A raw matcher passes on a red file
   forever.
2. **Blockquote markers survive whitespace collapse**, and that costs a
   match. `capsule-rm-guard-attribution/prd.md` quotes the retired claim in a
   `>` block that wraps, so collapsed text reads
   `outside the > \`_capsule_owned\` set` and the fixed string misses. This is
   the markdown analogue of `tests/nushell-core.sh`'s `prose()` stripping the
   leading `#`. Stripping leading `>` adds exactly **one** pair — that
   quote — and no other. Measured both ways.
3. **A `corrections/`-keyed allow-list is refuted by the tree.** Three
   legitimate quotes of a retired phrase live outside `corrections/`:
   `prds/04-shell/06-listing/prd.md` (a `done` **feature** PRD whose bullet
   list quotes the PWD-latch claim to retire it),
   `prds/03-editor/11-colorscheme/specs/spec01-colorscheme-config.md` (three
   quotes of the palette claim) and
   `prds/02-terminal/06-launchd-path/specs/spec02-launchd-path-gate.md` (its
   gate's own phrase list). A path allow-list would have to admit feature
   PRDs anyway, and once it does, "under `corrections/`" buys nothing.

## The scope

```
prds/**/*.md        the board: prd.md and specs/*.md alike. gui-dies found
                    carriers in both, and truncated-source-attributions
                    found nine because it looked at both.
docs/*.md           the rated inventories. PRDs are specced FROM these, and
                    two of the eight retired claims originated in one.
AGENTS.md           the working contract. It carries one retired phrase as a
                    quote today.
```

Symlinks are skipped (`! -type l`): `CLAUDE.md` is a symlink onto
`AGENTS.md`, and counting it twice makes every pair count one too high.

**Out of scope, deliberately: `home/`, `tests/`, `gates/`.** Those are
implementation, each already guarded by its owner's own gate — `PB.1` in
`tests/nushell-core.sh` for `config.nu`, `tests/wezterm-launchd-path.sh:292`
for `wezterm.lua`, and
[`launchd-path-phrase-guard`](../../launchd-path-phrase-guard/prd.md) adding
three more. Worse, a gate script *contains* the banned phrases as its own
grep arguments: sweeping `tests/` would demand an allow-list row per phrase
per gate, and the table would be mostly exemptions. Excluding `gates/` also
means this script cannot flag itself.

## The banned-phrase table — R1's deliverable

Eleven claims, eighteen phrase strings. `retired by` is a board node path;
the gate reads that node's `state:` and arms the row only when it is `done`.

| # | claim | phrase strings | retired by | state | armed |
|---|---|---|---|---|---|
| RP1 | an error in one PWD closure latches for the session, dirstack included | `stops EVERY PWD closure firing` · `stops every PWD closure` · `dirstack included` | `00-delivery/corrections/pwd-closure-blast-radius` + `00-delivery/corrections/stale-pwd-latch-carriers` | done | yes |
| RP2 | without the launchd PATH seeding the GUI window dies | `the window dies` · `dies on the spot` · `dies immediately` | `00-delivery/corrections/terminal-inventory-path-claim` + `00-delivery/corrections/gui-dies-claim-carriers` | done | yes |
| RP3 | nushell resolves a closure's command calls at parse time | `resolves a closure's command calls at PARSE time` | `00-delivery/corrections/config-nu-parse-claims` | done | yes |
| RP4 | a `source` of a missing file takes the whole shell down | `takes the whole shell down` | `00-delivery/corrections/config-nu-parse-claims` | done | yes |
| RP5 | no `docker rm` runs outside the `_capsule_owned` set | `no code path that reaches` · `no code path that calls` · ``outside the `_capsule_owned` set`` | `00-delivery/corrections/capsule-rm-guard-attribution` | done | yes |
| RP6 | the F6 subshell resolves neither `nu` nor `tinty` | ``where neither `nu` nor `tinty` resolves`` | `00-delivery/corrections/terminal-inventory-path-claim` | done | yes |
| RP7 | the terminal owns the palette | `the terminal owns the palette` | `00-delivery/decisions/tinty` | done | yes |
| RP8 | capsule credentials refresh on every mount | `refreshed out of the host keychain on every mount` | `00-delivery/corrections/capsule-creds-refresh-wording` | done | yes |
| RP9 | a latched tab-healing guard disables healing for the session | `silently disable healing for the rest of the session` | `00-delivery/corrections/wezterm-repairing-latch-claim` | open | no |
| RP10 | `la \| print` hangs the shell inside the hook, and the print path does not guard | `HANGS the shell inside the hook` · `the print path does not` | `00-delivery/corrections/autolist-width-guard-reason` | claimed | no |
| RP11 | `la` must be defined above the auto-list closure that names it | `the auto-list append that names it` | `00-delivery/corrections/listing-order-comment` | open | no |

Eight armed rows — **the eight already corrected**. Three pending rows arm
themselves the moment their node reaches `done`, and that is the highest
value in the whole design: it turns a "last carrier" assertion into a
checked one. `terminal-inventory-path-claim` R4 said *"this inventory is the
last carrier"* and left five;
[`gui-dies-claim-carriers`](../../gui-dies-claim-carriers/prd.md) swept them
three days later. With this gate armed, that node could not have closed
`done` while a carrier stood.

### Width — why each phrase is this long and not shorter

Every row below was cut to width against a measured collision. These are
not stylistic choices; each shorter form was tried and produces a false
positive in the tree today.

| shorter form | why it is rejected |
|---|---|
| `for the rest of the session` | 23 hits. `prds/02-terminal/02-startup-layout/prd.md:88` and `w0-2-terminal-respec/specs/spec03.md:76` use it about a **different subsystem**, which [`autolist-width-guard-reason`](../../autolist-width-guard-reason/prd.md)'s Out of scope explicitly declines to call wrong. RP1 and RP9 each carry the subject-bearing clause instead. |
| `HANGS` | The replacement text quotes **both** retired readings in order to retire them. `autolist-width-guard-reason` R5 names this width for the same reason. |
| `on every mount` | `prds/01-capsule/03-credential-propagation/specs/spec01-host-side.md:131` says "Done synchronously on every mount that is ~1.5 s added" — true, and the latency argument the correction rests on. RP8 carries the whole clause. |
| `rather than dying` | `prds/06-help/01-content-model/specs/spec01.md` has a `verify` walk that "continues rather than dying on the first element". Unrelated subject. Dropped from RP2 entirely. |
| `dies` | 216 raw hits over `prds/ docs/`. Most are a pane or a tab dying, which is true. |
| `no code path` | Would match any correctly-bounded negative claim. RP5 carries the verb. |

### `no code path that calls` — the one string no correction quotes

RP5's second string exists because this sweep **found** it, not because a
retirer wrote it. `capsule.nu` said *reaches*;
`prds/01-capsule/01-container-lifecycle/specs/spec01-capsule-cli.md:102-103`
says *"There is no code path that **calls** `docker rm` outside the
`_capsule_owned` set."* Same claim, one verb changed.

So RP5 is marked `variant` in the `ANCHORED` column and every other row is
marked `retirer`. The gate asserts that a `retirer` row's phrase occurs at
least once **inside its retirer's folder** — a correction quotes what it
retires, so a phrase that does not is mis-transcribed, and a mis-transcribed
banned phrase is decoration. `variant` rows are exempt from that check,
because after the carrier is corrected the string will occur **zero** times
anywhere, which is the correct end state for a banned phrase.

## The allow-list — R2

Two tiers. The derived tier carries the traffic; the explicit tier does the
biting.

**Tier 1, derived — the retirer's own folder.** A phrase is always allowed
anywhere under `prds/**/<its retirer>/**`, for every retirer in its own row.
Derived from the table's `retired by` column, so it adds no maintained rows
and it does not go stale. It exists because a retiring node's body and specs
are exactly where the phrase must be quoted, and they **grow**: a correction
that lands next week writes new spec files carrying the phrase, and an
explicit list would go red on the very edit that fixes the defect. Measured:
this tier absorbs **32 of the 69** pairs.

`prds/00-delivery/corrections/retired-phrase-sweep/**` is treated as a
retirer folder for **every** row. This node's PRD and specs hold the table,
so they quote all eighteen strings. Named as a limitation below, not
smuggled.

**Tier 2, explicit — a `(phrase, path)` pair table, asserted as set
equality.** 28 pairs, listed below. The comparator is the one the board
already settled on for this shape: `armed-count-tripwires`'s set equality
and `capsule-rm-guard-attribution`'s `sites_ok`, reporting `MISSING [...]`
and `UNEXPECTED [...]` rather than a count.

- `UNEXPECTED` — a hit at a path the table does not exempt. **This is a
  returned carrier.** FAIL for an armed row.
- `MISSING` — an exempted pair that no longer occurs. The exemption is
  stale; delete the row. Without this half an allow-list only ever grows,
  and a list that only grows becomes the blanket R2 forbids.

**Why the key is the pair and not the path.** R2's failure mode is "the
phrase returns inside a *new* correction that is not about it". Pair-keying
answers it directly: `stale-pwd-latch-carriers/prd.md` may hold RP1's
phrases and nothing else, so RP2's `dies immediately` planted there is
`UNEXPECTED` and red. A path-keyed list waives every phrase at that path and
cannot make that distinction.

**Why not a heuristic exemption** — a phrase near the word "retired", or
inside a blockquote. Because it fails **open**, and the tree contains the
counterexample already. `prds/04-shell/06-listing/prd.md:120-131` has a
bullet reading `- **Retired.** "la | print hangs the shell outright on a
0-column pty" does not reproduce`, and
[`autolist-width-guard-reason`](../../autolist-width-guard-reason/prd.md)
has since measured that **the retirement itself is wrong** — the claim is
true in an empty directory. A false claim sitting directly under a
retirement marker is not a hypothetical. An explicit table fails **closed**:
a new legitimate quote goes red until a human adds one row and, in adding
it, judges that the quote really is a retirement. That is the whole value.

### The 28 exempt pairs

Transcribe exactly. Each is a quote of the retired claim, a correction's
cross-reference to another node's finding, or a gate's own phrase list.

| phrase | path | what it is |
|---|---|---|
| `stops EVERY PWD closure firing` | `prds/00-delivery/corrections/unguarded-startup-externals/specs/spec01.md` | the spec that first drove the claim |
| `stops EVERY PWD closure firing` | `prds/00-delivery/corrections/autolist-width-guard-reason/specs/spec01.md` | sibling quoting the retired wording |
| `stops every PWD closure` | `prds/04-shell/06-listing/prd.md` | feature PRD, quoted as retired |
| `dirstack included` | `prds/04-shell/06-listing/prd.md` | same bullet |
| `the window dies` | `prds/00-delivery/corrections/pwd-closure-blast-radius/prd.md` | R4's census naming the claim |
| `the window dies` | `prds/00-delivery/corrections/pwd-closure-blast-radius/specs/spec02.md` | census entry C2 |
| `the window dies` | `prds/00-delivery/corrections/launchd-path-phrase-guard/prd.md` | names the three guarded phrases |
| `the window dies` | `prds/02-terminal/06-launchd-path/specs/spec01-launch-environment.md` | finding 1, which corrected it |
| `the window dies` | `prds/02-terminal/06-launchd-path/specs/spec02-launchd-path-gate.md` | the gate's own phrase list |
| `dies on the spot` | `prds/00-delivery/corrections/pwd-closure-blast-radius/specs/spec02.md` | census entry C2 |
| `dies on the spot` | `prds/02-terminal/06-launchd-path/specs/spec02-launchd-path-gate.md` | the gate's own phrase list |
| `dies immediately` | `prds/00-delivery/corrections/pwd-closure-blast-radius/specs/spec02.md` | census entry C2 |
| `dies immediately` | `prds/02-terminal/06-launchd-path/prd.md` | R3, quoting the wording it corrects |
| `dies immediately` | `prds/02-terminal/06-launchd-path/specs/spec01-launch-environment.md` | finding 1 |
| `dies immediately` | `prds/02-terminal/06-launchd-path/specs/spec02-launchd-path-gate.md` | the gate's own phrase list |
| `resolves a closure's command calls at PARSE time` | `prds/00-delivery/corrections/pwd-closure-blast-radius/specs/spec02.md` | census entry C3 |
| `takes the whole shell down` | `prds/00-delivery/corrections/pwd-closure-blast-radius/specs/spec02.md` | census entry C5 |
| `no code path that reaches` | `prds/00-delivery/corrections/pwd-closure-blast-radius/specs/spec02.md` | census entry C6 |
| ``outside the `_capsule_owned` set`` | `prds/00-delivery/corrections/pwd-closure-blast-radius/specs/spec02.md` | census entry C6 |
| ``where neither `nu` nor `tinty` resolves`` | `prds/02-terminal/06-launchd-path/prd.md` | R4, cross-linking the inventory defect |
| ``where neither `nu` nor `tinty` resolves`` | `prds/02-terminal/06-launchd-path/specs/spec01-launch-environment.md` | the F6 cross-link finding |
| `the terminal owns the palette` | `AGENTS.md` | the working contract, recording the correction |
| `the terminal owns the palette` | `prds/00-delivery/corrections/prd.md` | T-3 and its answer |
| `the terminal owns the palette` | `prds/00-delivery/corrections/w0-2-terminal-respec/specs/spec01.md` | a `verify` asserting the phrase is absent |
| `the terminal owns the palette` | `prds/00-delivery/corrections/w0-4-s2-corrections/delivery/prd.md` | the carrier count, closed as discharged |
| `the terminal owns the palette` | `prds/03-editor/11-colorscheme/specs/spec01-colorscheme-config.md` | feature spec, quoted as retired |
| `HANGS the shell inside the hook` | `prds/00-delivery/corrections/pwd-closure-blast-radius/specs/spec01.md` | the comment under measurement |
| `HANGS the shell inside the hook` | `prds/00-delivery/corrections/stale-pwd-latch-carriers/specs/spec01.md` | the same comment |

## What the gate reports

```
retired-phrase sweep — <root>
── table ────────────────────────────────────────────────────────────
      11 claims, 18 phrases, 8 armed, 3 pending
      RP9  pending — its retirer
            00-delivery/corrections/wezterm-repairing-latch-claim is `open`
      …
── sweep ────────────────────────────────────────────────────────────
      354 files, 69 (phrase, path) pairs, 32 in a retirer folder
FAIL  RP4 CARRIER prds/04-shell/04-television/specs/spec03.md carries
      `takes the whole shell down` — retired by
      00-delivery/corrections/config-nu-parse-claims (done). Not exempt.
…
      PENDING RP9 prds/02-terminal/02-startup-layout/prd.md carries
      `silently disable healing for the rest of the session` — owned by
      00-delivery/corrections/wezterm-repairing-latch-claim (open)
── allow-list ───────────────────────────────────────────────────────
FAIL  allow-list is exactly the 28 declared pairs
      MISSING []; UNEXPECTED [...]
```

Checks, each its own `chk` line so a reader knows which one moved:

1. **Table well-formed.** Every `retired by` path resolves to an existing
   `prds/<path>/prd.md`; every phrase is non-empty; no phrase string is a
   substring of another (a nested pair makes two rows report one hit and the
   set equality unresolvable).
2. **Anchored.** Every `retirer`-anchored phrase occurs at least once inside
   its retirer's folder. 17 rows; RP5's `no code path that calls` is
   `variant` and skipped.
3. **Set equality** over the explicit tier: `MISSING` and `UNEXPECTED`,
   named.
4. **One FAIL per armed carrier**, naming the phrase, the path, the claim id
   and the retirer, so the line says what to fix and who retired it.
5. **PENDING lines** for unarmed rows' carriers — reported, never counted.
   A wave-0 gate must not fail for work another node owns.
6. **Isolation.** `assert_unchanged` over `prds`, `docs` and `AGENTS.md`
   across the run. Not `git diff`: the tree carries staged work no gate
   caused.

Mechanics that are load-bearing:

- **`GREP=/usr/bin/grep`.** Bare `grep` resolves to `ugrep` on this machine
  and its dialect differs. `gates/nushell-module-staging.sh` pins the system
  binary for the same reason.
- **Normalise each file ONCE, then match all 18 phrases in one
  `grep -oFf`.** The naive shape — re-normalise per phrase — measured
  **68 s** for this file set. Normalise-once measured **3.3 s**. A wave-0
  gate pays that cost on every sweep.
- **Normalisation is `sed -E 's/^[[:space:]]*>+[[:space:]]?//'` per line,
  then `lib.sh`'s `norm`.** Both halves measured necessary above. Do not
  substitute a bare `norm`.
- **`grep -oF` output is sorted `-u` per file**, so the unit is a pair, not
  an occurrence. Occurrence counts were considered and rejected: the
  orchestrator appends transition sections to `done` correction bodies, so a
  count would go red on edits that add no claim.

## Wave 0 — R6, reported not registered

**Wave: 0. Segment: the wave-0 gates cell of `gates/waves.tsv`, appended
after `bash gates/nushell-module-staging.sh`.** It belongs in wave 0 because
it sweeps the board itself, alongside `tree-links.sh`,
`audit-findings.sh` and `manual-coverage.sh`, and because it depends on no
task.

**Hold the registration.** Wave 0 is ARMED and green today, so adding a red
gate is a real regression rather than a pending one. The precedent is exact:
`gates/nushell-module-staging.sh` was written with one known MISS, kept out
of `waves.tsv` while that MISS stood, and registered only after
[`television-help-staging`](../../television-help-staging/prd.md) landed —
it is row 0 of `waves.tsv` now. Follow it. The two findings below are what
unblocks registration; both are prose-only, one line each.

Do not write `gates/waves.tsv` or `gates/manual/wave0.md` from this spec.

## The two findings that make it red — file, do not fix

Both are the `gui-dies-claim-carriers` shape for the third and fourth time:
a correction fixed the code and left the tree that specs it.

**Finding A — `takes the whole shell down`, four carriers.**
[`config-nu-parse-claims`](../../config-nu-parse-claims/prd.md) (`done`)
corrected two sites in `config.nu` and retargeted
`tests/nushell-core.sh:564`. It reported `tests/shell-help.sh:99` as a
residue for `06-help/02`. It did not sweep the board:

| carrier | line |
|---|---|
| `prds/02-terminal/04-copy-mode/specs/spec02-copymode-command.md` | 50 |
| `prds/04-shell/02-aliases-utilities/specs/spec02-pass-completion.md` | 27-28 (wrapped) |
| `prds/04-shell/04-television/specs/spec03.md` | 23 |
| `prds/04-shell/08-claude-launchers/specs/spec01-claude-module.md` | 64 |

All four use the claim to justify the same true thing — the module and its
`source` line land in one change. The measured radius is a **better**
argument for that atomicity, not a weaker one: interactively the whole file
is discarded in both directions and the shell comes up naked, and `nu -c`
exits 1 without running the command. So this is prose, four one-line edits,
and the conclusion does not move.

**Finding B — the `_capsule_owned` universal claim, reworded.**
`prds/01-capsule/01-container-lifecycle/specs/spec01-capsule-cli.md:102-103`
reads *"There is no code path that **calls** `docker rm` outside the
`_capsule_owned` set."*
[`capsule-rm-guard-attribution`](../../capsule-rm-guard-attribution/prd.md)
(`done`) measured that false — `capsule.nu:405` reaches `docker rm` from
`_capsule_name` on the `--rebuild` path, guarded by the `dir_label` check at
`:399-401`. The accurate wording is that node's: "no `docker rm` runs
without the `capsule.dir` ownership check."

This carrier is the highest-stakes shape on the board — it points an auditor
of a destructive path at a guard that does not cover it — **and it is a live
instance of R5's limitation.** One verb changed and the retirer's own
closing grep for `no code path that reaches` returned zero.

## Acceptance

- [ ] **The table is transcribed exactly.** `gates/retired-phrases.sh`
      declares 11 claims and 18 phrase strings, and the run prints
      `11 claims, 18 phrases, 8 armed, 3 pending`.
      *Not ticked, because the arming half of that line is stale and a `[x]`
      against a stale value is a false record.* The table is transcribed
      exactly — 11 claims, 18 phrase strings — but the run measured on
      2026-08-23 prints `11 claims, 18 phrases, 9 armed, 2 pending`.
      `autolist-width-guard-reason` closed `done` while this gate was being
      written, so `RP10` armed itself. That is the derived arming working, not
      a defect, and it is why the count is not written in the table. One
      pending row also moved state twice inside the hour: `RP9`'s retirer
      read `open` at spec time, `analyzing`, then `specced`.
- [x] **Arming is derived, not written.** Grep the script: no literal
      `armed`/`pending` verdict per row. Each row's verdict comes from
      reading `state:` in its retirer's `prd.md`. Proved by pointing the
      gate at a `scratch_tree` copy where
      `wezterm-repairing-latch-claim/prd.md` has `state: open` rewritten to
      `state: done`, and showing RP9's three carriers move from `PENDING` to
      `FAIL`.
      `/usr/bin/grep -nE '\b(armed|pending)\b *= *(yes|no|1|0)'` prints
      nothing. The flip was run against a `scratch_tree` copy — the live
      `state:` reads `specced`, not `open`, so the rewrite was
      `s/^state: specced$/state: done/` — and the header moved from
      `9 armed, 2 pending` to `10 armed, 1 pending` while all three RP9 lines
      turned from `PENDING RP9 …` into
      `FAIL  RP9 CARRIER … retired by … (done). Not exempt.`
- [x] **Table well-formed.** Every `retired by` path resolves to a real
      `prd.md`; no phrase is a substring of another. Both asserted, both
      PASS: `unresolved: none` over 11 retirer nodes, `nested: none` over the
      18 strings, plus a third — `every phrase string is non-empty
      (18 strings)`.
- [x] **Anchored.** All 17 `retirer` rows occur inside their retirer's
      folder; RP5's `no code path that calls` is `variant` and reported as
      such rather than skipped in silence. 17 PASS lines, each naming the
      folder that satisfied it, and one `RP5  VARIANT` report line saying no
      retirer ever wrote the string and that this sweep found it.
- [x] **The sweep numbers are quoted, not asserted.** File count, pair
      count, and how many pairs the derived tier absorbed. Expected on
      2026-08-23: **69 pairs, 32 absorbed**, over 354-359 files — quote what
      you measure, the tree moves.
      Measured, and the tree moved: `376 files, 100 (phrase, path) pairs, 62
      in a retirer folder`. The file count read 359 on the first pass of this
      session and 376 two hours later. Most of the growth is this node's own
      folder, which quotes all 18 strings and is tier-1 exempt for every row,
      plus the two findings filed out of the sweep.
- [x] **R4, normalisation, proved both ways.** The two wrapped carriers
      (`spec02-pass-completion.md`, `w0-4-s2-corrections/delivery/prd.md`)
      are found by the gate, and `/usr/bin/grep -c` on the same phrase in
      the same file returns **0**. Quote both. Raw: `0` for
      `takes the whole shell down` in `spec02-pass-completion.md` and `0` for
      `the terminal owns the palette` in
      `w0-4-s2-corrections/delivery/prd.md`. Gate, via `--pairs`:
      `CARRIER RP4 takes the whole shell down …/spec02-pass-completion.md`
      and
      `EXEMPT RP7 the terminal owns the palette …/w0-4-s2-corrections/delivery/prd.md`.
      The second is exempt, so it appears in no FAIL line — which is why
      `--pairs` exists: the report prints only what is wrong, and two of R4's
      boxes are about pairs the gate gets right.
- [x] **R4, the blockquote strip, proved.** With the `>` strip the sweep
      finds ``outside the `_capsule_owned` set`` in
      `capsule-rm-guard-attribution/prd.md`; without it, it does not. One
      pair difference, quoted. Two back-to-back sweeps of the same tree:
      `strip=100  nostrip=99`, and the single `diff` line is
      ``outside the `_capsule_owned` set  prds/00-delivery/corrections/capsule-rm-guard-attribution/prd.md``.
      Per file, the collapsed text greps `1` with the strip and `0` without.
      A first attempt measured `98` against `99` and looked like the strip
      *losing* two pairs — a lane was writing `wezterm-repairing-latch-claim`
      between the two runs. Re-run interleaved; quote the interleaved pair.
- [x] **The six armed carriers are named.** Exactly six FAIL lines, one per
      (phrase, path): four for RP4, two for RP5 (both strings hit the same
      file). Each names the phrase, the path, the claim id and the retirer.
      `grep -c '^FAIL  RP[0-9]* CARRIER'` = **6**, and both RP5 lines name
      `01-capsule/01-container-lifecycle/specs/spec01-capsule-cli.md`.
- [x] **The three pending carriers are reported and not counted.** RP9's
      three PENDING lines appear, and removing them from the tree in a
      scratch copy does not change the exit status. `grep -c 'PENDING RP9'`
      = **3**, and the `CF12` pending half is red both with and without them.
      All three carriers **wrap**, so the first version of the scratch drop
      substituted the whole phrase per line and changed nothing — a per-line
      editor is as blind to a wrapped phrase as a per-line matcher is, which
      is R4 arriving from the other side. The drop rewrites
      `silently disable`, the longest fragment on one line in all three.
- [x] **Set equality both directions.** `MISSING []` and
      `UNEXPECTED [<the six armed carriers plus the three pending ones>]`,
      printed verbatim. A `MISSING` row means the exemption is stale.
      `MISSING []` and `UNEXPECTED [...]` with exactly those nine entries.
      The **verdict** excludes the three pending ones — R6 says a wave-0 gate
      must not fail for work another node owns — so the chk reads
      `MISSING 0, UNEXPECTED 9` and fails on the six armed ones only. The
      nine are still printed, so a pending carrier cannot hide.
      The declared tier is **29** pairs, not 28: hours after this spec was
      written, this node's own analyst filed
      [`capsule-rm-reworded-claim`](../../capsule-rm-reworded-claim/prd.md),
      whose purpose is to retire RP5's reworded carrier and which therefore
      quotes the claim at a path no retirer folder covers. That is the
      fail-closed property working exactly as specified — a new legitimate
      quote goes red until a human adds one row and, in adding it, judges
      that the quote really is a retirement. Judged, added, and reported as
      29 rather than passed off as 28.
- [x] **Isolation.** `assert_unchanged` over `prds`, `docs` and `AGENTS.md`
      PASSes, and `gates/retired-phrases.sh` is the only file
      `git status --porcelain` names for this spec — `A  gates/retired-phrases.sh`.
      Three zero-byte files sit in the repo root
      (`cf-rm-site-dropped.nu`, `cf-rm-site-in-another-def.nu`, `nvim.log`);
      they predate this run, they belong to
      [`gate-artifact-leakage`](../../gate-artifact-leakage/prd.md), and the
      selftest's `CF13` root-listing hash came out identical
      (`c5b638fb…`), so this gate added none of them.
- [x] **Cost.** The full run completes in under 10 s, timed and quoted. A
      wave-0 gate pays this on every sweep; the naive per-phrase shape
      measured 68 s. **2.87 s** wall for the full run over 376 files
      (`2.43s user 2.72s system 179% cpu 2.866 total`).
- [x] **`gates/waves.tsv` is unedited**, confirmed by reading it. Wave 0's
      cell still ends `bash gates/nushell-module-staging.sh`. Read back:
      `bash gates/tree-links.sh | bash gates/audit-findings.sh | bash
      gates/manual-coverage.sh | external bash tests/live-bugs.sh | bash
      gates/nushell-module-staging.sh`, and
      `grep -c 'retired-phrases' gates/waves.tsv` = `0`.
- [x] **The gate exits 1**, and the report says plainly that this red is
      correct and names Findings A and B as what clears it. `plain exit=1`,
      21 PASS / 8 FAIL. The script's own header says the red is correct and
      names both nodes, so the statement travels with the file.

## Verify and Proof

```sh
cd /Users/feb/dev/dotfiles

# the run, timed
time bash gates/retired-phrases.sh; echo "exit=$?"        # expect 1

# the table's shape, from the run's own header
bash gates/retired-phrases.sh | /usr/bin/grep -E '^      [0-9]+ claims'

# the six armed carriers and the three pending ones
bash gates/retired-phrases.sh | /usr/bin/grep -c '^FAIL  RP[0-9]* CARRIER'  # 6
bash gates/retired-phrases.sh | /usr/bin/grep -c 'PENDING RP9'              # 3

# R4: the two wrapped carriers a raw grep cannot see
/usr/bin/grep -c 'takes the whole shell down' \
  prds/04-shell/02-aliases-utilities/specs/spec02-pass-completion.md   # 0
/usr/bin/grep -c 'the terminal owns the palette' \
  prds/00-delivery/corrections/w0-4-s2-corrections/delivery/prd.md     # 0
bash gates/retired-phrases.sh | /usr/bin/grep -F 'spec02-pass-completion.md'
bash gates/retired-phrases.sh | /usr/bin/grep -F 'w0-4-s2-corrections/delivery'

# R4: the blockquote strip, one pair of difference
/usr/bin/grep -c 'outside the' \
  prds/00-delivery/corrections/capsule-rm-guard-attribution/prd.md

# arming is derived — flip one state in a copy, watch RP9 arm
T="$(mktemp -d)"; bash -c '
  . gates/lib.sh; scratch_tree "'"$T"'"'
LC_ALL=C sed -i "" "s/^state: open$/state: done/" \
  "$T/prds/00-delivery/corrections/wezterm-repairing-latch-claim/prd.md"
bash gates/retired-phrases.sh --root "$T" | /usr/bin/grep 'RP9'
# expect FAIL … CARRIER, not PENDING

# no per-row literal verdict in the script
/usr/bin/grep -nE '\b(armed|pending)\b *= *(yes|no|1|0)' gates/retired-phrases.sh
# expect no output

# the registry is untouched
/usr/bin/grep -n 'nushell-module-staging' gates/waves.tsv
git status --porcelain
```
