---
est: 0.5h
footprint:
  - prds/01-capsule/01-container-lifecycle/specs/spec01-capsule-cli.md
executor: orchestrator   # the one file belongs to
                         # 01-capsule/01-container-lifecycle, a `done` node;
                         # no gate, no guard, no second file
---

# spec01 — one passage, three sites, three named guards

`prds/01-capsule/01-container-lifecycle/specs/spec01-capsule-cli.md` closes
its `capsule clean` paragraph with a universal claim about `docker rm`. The
claim is the one
[`capsule-rm-guard-attribution`](../../capsule-rm-guard-attribution/prd.md)
measured false and retired in `capsule.nu`, carried here with one verb
changed. Replace that paragraph with the pre-resolved text below. One file
changes. No box changes. No guard changes. Nothing in `home/`, `tests/` or
`gates/` is this spec's.

The footprint is another PRD's spec file, and that PRD is `done`, so **the
orchestrator makes this edit**. No implementer may write another PRD's body.
The precedent is
[`stale-pwd-latch-carriers`](../../stale-pwd-latch-carriers/specs/spec01.md)
and
[`wezterm-repairing-latch-claim`](../../wezterm-repairing-latch-claim/prd.md)
spec02. What makes this one the orchestrator's and not an implementer's is
that the footprint holds no gate: R2's measurement and R3's census are done
here, at spec time, and the executor runs three existing gates rather than
writing one.

## Two strings this spec must never quote, and neither may the edit

`gates/retired-phrases.sh` arms two RP5 phrase strings at this one path: the
verb variant of the retired sentence, and its trailing clause. Read the exact
strings from that file's `phrases_table` — the three rows keyed `RP5`. **Do
not retype either string into any file under
`prds/00-delivery/corrections/capsule-rm-reworded-claim/`.**

That is measured, not stylistic. The gate's tier-1 waiver covers a retirer's
own folder, and RP5's retirer is `capsule-rm-guard-attribution`; this node's
folder gets no waiver, and its `exempt_table` row names this node's `prd.md`
alone. Planting both strings into a scratch copy at
`…/capsule-rm-reworded-claim/specs/spec01.md` and running the gate against
that root printed:

```
FAIL  RP5 CARRIER prds/00-delivery/corrections/capsule-rm-reworded-claim/specs/spec01.md carries ... Not exempt.
FAIL  sweep: no armed row's phrase stands outside its allow-list (armed carriers: 2)
```

Two new armed carriers, on a tree where the six real ones were repaired. A
spec that quotes what it retires re-arms the gate it exists to disarm.

The mirror image is just as load-bearing: **this node's `prd.md` must keep its
quote.** `exempt_table` is asserted as set equality, so deleting the quote
makes the pair MISSING rather than tidy. Measured on the same copy:

```
MISSING [outside the ... :: prds/00-delivery/corrections/capsule-rm-reworded-claim/prd.md]
FAIL  allow-list: exactly the 29 declared pairs, plus 3 pending-row carriers (MISSING 1, UNEXPECTED 3)
```

## The one edit

Target: the paragraph that opens `**`def "capsule clean" [--all]`** (R6):`.
It is lines 99–103 today, and it ends with a sentence beginning `There is no
code path`. Replace all five lines with the block below.

Anchor on the paragraph text, not on the line numbers. The numbers move:
this node's PRD cites `:405`, `:459`, `:461` and `:399-401` for the same
sites, and those numbers were already stale when it was written —
`capsule-rm-guard-attribution`'s comment edits pushed the three `^docker rm`
sites to **`:423`, `:497`, `:499`** and the `dir_label` refusal to
**`:414-416`**. The replacement text therefore names sites by their step and
branch and cites no line number at all.

### The replacement text — final, do not re-derive

```markdown
**`def "capsule clean" [--all]`** (R6): from `_capsule_owned`, remove the
stopped rows with `^docker rm`; with `--all` also the running rows with
`^docker rm -f`. Return the removed names; an empty set returns an empty
list and touches nothing.

**The three `^docker rm` sites, and the guard over each.** Enumerated,
never claimed universally: what stood here was a universal claim that every
removal went through `_capsule_owned`, and the `--rebuild` recreate never
reads that set at all — measured false and retired by
[`capsule-rm-guard-attribution`(../../../../../../prds/00-delivery/00-delivery/corrections/capsule-rm-guard-attribution/prd.md).

- `capsule` step 7, the `--rebuild` recreate (`^docker rm -f $name`) —
  guarded by step 6's refusal on an empty `dir_label`.
- `capsule clean`'s stopped branch (`^docker rm $row.name`) — guarded by
  `_capsule_owned`.
- `capsule clean`'s running branch, `--all` only (`^docker rm -f
  $row.name`) — guarded by `_capsule_owned`.

The two guards are not the same test. `_capsule_owned` is label-key AND
name prefix; step 6 tests the label's VALUE. They agree on every container
this tool can create, because the create line always writes a non-empty
`capsule.dir`. They diverge on one input nothing here can produce: a
container someone else named `capsule-*` and labelled with an EMPTY
`capsule.dir` — step 6 refuses that one, `clean` removes it. That seam is
definitional rather than a reach onto a genuinely foreign container, and
closing it would change a guard. `capsule.nu`'s `capsule clean` header
carries the same enumeration, and `tests/capsule-lifecycle.sh` holds it
down as `RM_SITES` plus `attribution_ok`.
```

Three properties of that text, each deliberate.

**It paraphrases the false claim and never restates it.** "a universal claim
that every removal went through `_capsule_owned`" carries neither armed
string. `capsule.nu`'s corrected comment took the same route for the same
reason.

**Its enumeration matches `capsule.nu`'s, wording included.** `guarded by
_capsule_owned` twice and the label-key-versus-value paragraph are what
`attribution_ok` pins in the module. A reader who diffs the two now finds
them saying the same thing.

**It carries the seam.** R4 asks for the seam wherever a universal claim is
replaced, and this passage is the only other place the claim stood.

The block was applied to a scratch copy of `prds/`, `docs/` and `AGENTS.md`
and swept: armed carriers **6 → 4**, MISSING **0**, and no FAIL line names
any path under `prds/01-capsule/`. The four that remain are RP4's, owned by
[`shell-down-spec-carriers`](../../shell-down-spec-carriers/prd.md).

## R2 — the property, re-measured, both routes

Re-run at spec time, 2026-08-23, against `capsule.nu` as it stands. **The
property is `reproduced`.** Every run drove the real CLI under `nu 0.114.1`
with `env -i`, `HOME` on a scratch machine, and `PATH` = a recording `docker`
shim plus `/usr/bin:/bin`, where no `docker` exists. No daemon was contacted,
no real `docker rm` ran, no container outside the shim's control files was
named, no credential was read (`git` and `security` shimmed to exit 1).

Route A, the `--rebuild` removal at step 7. Four inputs, two of them new
against the fixture `capsule-rm-guard-attribution` used:

| input | exit | `rm` lines |
|---|---|---|
| exists, **running**, `capsule.dir` empty | 1, `capsule: a container named capsule-proj-b972abd2 exists but was not created by capsule` | **0** |
| exists, **stopped**, `capsule.dir` empty | 1, same refusal | **0** |
| exists, `capsule.dir` = the target | 0 | 1 — `rm -f capsule-proj-ebb00d7f` |
| no `--rebuild`, exists, `capsule.dir` empty | 1, same refusal | **0** |

Route B, the two `clean` removals, against a fixture built for this run:
`capsule-alpha-11111111` (labelled, running), `capsule-beta-22222222` and
`capsule-gamma-33333333` (labelled, stopped), `moved-away` (labelled, no
prefix), `capsule-imposter` (prefix, no label), `redis`.

| input | `rm` lines |
|---|---|
| `capsule clean` | `rm capsule-beta-22222222`, `rm capsule-gamma-33333333` |
| `capsule clean --all` | those two plus `rm -f capsule-alpha-11111111` |

`moved-away`, `capsule-imposter` and `redis` appear in no `rm` line, and the
returned names equal the removed ones.

Both guards are load-bearing, measured by neutering each one in a scratch
copy and re-running the same inputs:

- `dir_label` refusal replaced by `if false {` — the label-less container is
  removed on **both** Route A empty-label inputs (`rm -f
  capsule-proj-599aec86`, `rm -f capsule-proj-83bc2bb1`). Nothing else covers
  step 7.
- `--filter label=capsule.dir` dropped from `_capsule_owned` — `clean` also
  removes `capsule-imposter`. The label filter is what excludes it.

Verdict: `reproduced (nu 0.114.1, recording docker shim, scratch HOME;
Route A four inputs incl. stopped-container, Route B a six-container mixed
fixture; both guards neutered as controls)`.

## R3 — the census, verb-varied

Predicates, over `prds/**`, `docs/**`, `home/**`, `tests/**`, `gates/**` and
`AGENTS.md` — 528 files, symlinks skipped, each file normalised to one line
and split into sentences, because the retired form wraps in three of its
carriers and a per-line `grep` returns 0 for those.

- **P1, verb-free.** `no` … `path` … `that` within one sentence, any verb,
  up to 40 characters between the anchors. Keyed on the *shape* of the
  claim, so `reaches`, `calls`, `invokes`, `runs` and `hits` all land. 31
  sentences.
- **P2, subject plus universality.** `docker rm` or `_capsule_owned` in the
  same sentence as one of `no|none|never|nothing|nowhere|every|all|only|`
  `outside|any|always|sole|solely|cannot|neither`. 76 sentences, 56 inside a
  retirer folder, the sweep node's folder, or `gates/retired-phrases.sh`
  itself.
- **P3, the paraphrase probe.** A removal verb
  (`remove|removal|delete|destroy|kill|rm|prune`) plus `container` or
  `capsule` plus a universality word, in sentences carrying **neither**
  subject token. 71 sentences, 53 outside a retirer folder.

**Result: one live carrier of this claim, and it is the one the node was
filed for** —
`prds/01-capsule/01-container-lifecycle/specs/spec01-capsule-cli.md`.
Every other P1/P2 hit outside a retirer folder is `capsule.nu`'s or
`tests/capsule-lifecycle.sh`'s corrected enumeration, this node's own PRD, or
a different subject (`docker rmi` in `01-capsule/02-dev-image`, WezTerm's
`No viable candidates found in PATH`, treesitter's `no seed`). Verdict:
`refuted for further rewordings (verb-free P1 plus two subject-keyed
predicates, normalised, over prds+docs+home+tests+gates+AGENTS.md)` — the
phrasing the board's census rules require instead of "the last carrier".

**What these predicates would still miss.** Three classes, stated because an
overclaimed census is the defect this family of nodes exists to correct.

1. **A claim with no subject token and no universality word.** "Removal goes
   through the owned set" carries `removal` and `set` and none of P1–P3's
   anchors. P3 catches the subset that also says `container` or `capsule`
   *and* a universality word; a bare declarative escapes all three.
2. **A claim about a *different* destructive command.** `docker kill`,
   `docker stop`, `docker rmi` and `docker system prune` are not in P2's
   subject, and P3 needs a container noun in the same sentence.
3. **A claim split across two sentences.** "Only `_capsule_owned` is
   iterated. Nothing else removes anything." Each half is under one
   predicate's threshold; sentence-level matching sees neither.

None of the three is worth a gate. `retired-phrase-sweep` R5 declined the
semantic sweep on three measurements — a noise floor of 160/60 and then
216/107 hits, growing with the tree; any narrowing quiet enough to ship fails
open; and no wrong reason on this board was ever found by matching text. This
census is a report for that reason, and the fix is by hand.

## R3's residue — one paraphrase, filed, not fixed here

P3 found a universal claim about the same destructive path, in a wording with
neither subject token, at a path no armed row covers:
`prds/01-capsule/01-container-lifecycle/prd.md` R6 —

> Both only ever touch containers this tool created (the `capsule-` name
> prefix of R1) — never any other container on the host, which is what the
> old `dk` force-remove alias could not promise.

The same sentence is quoted in
`prds/00-delivery/corrections/w0-4-s2-corrections/capsule/specs/spec01.md`.

It is `refuted (imitator container: `capsule-*` with a present but EMPTY
`capsule.dir`, recording docker shim)`. Measured on that input: `capsule
clean` logged `rm capsule-seam-44444444`, and the same shape through
`--rebuild` was refused with zero `rm` lines. A container this tool did not
create is removed, so "never any other container on the host" does not hold,
and the parenthetical is wrong twice over — `_capsule_owned` is label
**and** prefix, strictly narrower than the prefix R1 names.

**Out of scope here, and this is the argument.** It is a different claim: it
is scoped to `list` and `clean`, it never mentions the `--rebuild` removal,
and it therefore carries no mis-attribution of a guard. It is not one of the
gate's armed carriers, so it does not block registration. And it sits inside
requirement R6 of a `done` node, where correcting it changes what the
requirement promises — substance, which
[`shell-down-spec-carriers`](../../shell-down-spec-carriers/prd.md) R2 puts
off limits to a carrier sweep. File it as its own correction. The board's
rule is to file, not to implement the wrong thing.

## R4 — the seam, stated where the claim was

`capsule-rm-guard-attribution` R3 recorded it: `_capsule_owned` tests the
label **key** plus the name prefix, while step 6 tests the label's **value**.
The two agree on every container this tool can create, because the create
line always writes a non-empty `capsule.dir`. They diverge on exactly one
input, and the divergence is measured above: `--rebuild` refuses a
`capsule-*` container whose `capsule.dir` is empty, `clean` removes it.

Only a deliberate imitator of the ownership marker produces that container,
and under the label-as-marker convention such a container has declared itself
capsule's. That makes it a definitional seam, not a destructive reach on a
genuinely foreign container. The replacement text states both predicates and
the divergence, so the next reader sees the seam instead of rediscovering it.
Closing it means changing a guard, which is C.1's or C.2's.

## The measured baseline, before the edit

Run alone, 2026-08-23, on the live tree:

| command | result |
|---|---|
| `bash gates/retired-phrases.sh` | `rc=1`, 8 FAIL, `armed carriers: 6` |
| `bash tests/capsule-lifecycle.sh` | `capsule-lifecycle: 60 pass, 0 fail`, `rc=0` |
| `python3 gates/tree-links.py --root . --tier a --count-only` | `0`, then `1` twenty minutes later — see below |
| `bash gates/wave-status.sh --run 0` | `rc=0`, 0 FAIL |
| box counts in the carrier file | `- [ ]` 0, `- [~]` 7, `- [x]` 3 |

`tests/capsule-lifecycle.sh` reads no file this spec touches, so it is a
regression check here and not the proof. The proof is the sweep.

**Run every gate alone, and attribute every red.** Two implementers are live
and one writes many files under `prds/`, so an isolation or `--deep` snapshot
check that hashes a shared tree can go red for that reason alone. Three
things moved under the tree during this analysis:

- `wezterm-repairing-latch-claim` went `specced` → `claimed` → `done`, so
  the sweep's pending-carrier line went from 3 to 0. Only the armed count
  matters to this node.
- `prds/00-delivery/corrections/listing-order-lookup-regression/prd.md:219`
  appeared, linking to `../gates-lib-anchored-lookup/prd.md`, a node folder
  that does not exist. Tier A therefore reads **1 broken, not 0**, and the
  one broken link is not this node's. If the count is still 1 after the
  edit and that line is the only `BROKEN` row, the box passes.
- `tests/capsule-lifecycle.sh` and `home/dot_config/nushell/capsule.nu` are
  another lane's staged work. Neither is in this footprint.

## Acceptance

- [ ] The `capsule clean` paragraph in
      `prds/01-capsule/01-container-lifecycle/specs/spec01-capsule-cli.md`
      is the replacement block, byte for byte — a `grep` of the block over the
      file as it stands today, output quoted. The original `git diff --stat`
      clause is not a check here: that file is untracked (`git ls-files --error-unmatch`, 2026-08-23),
      so the diff is silent over it and "names that one file and no other" is
      equally true of every file it cannot see. Unprovable in retrospect: the
      pre-edit state was untracked, so git never held a copy and no `cp` aside
      was kept. What would have proved it: `shasum -a 256` of the file before
      the edit, or a `cp` aside plus `diff -q` after.
- [ ] `bash gates/retired-phrases.sh`, run **alone**: `armed carriers: 4`,
      down from 6, with `MISSING 0`. No FAIL line names a path under
      `prds/01-capsule/` or under
      `prds/00-delivery/corrections/capsule-rm-reworded-claim/`. The gate
      still exits 1 on RP4's four carriers, which are
      `shell-down-spec-carriers`'.
- [ ] No RP5 string occurs anywhere under `prds/01-capsule/` or under
      `prds/00-delivery/corrections/capsule-rm-reworded-claim/specs/`. The
      `grep -rnF -f` line in **Verify and Proof** prints **2** before the
      edit — both from the carrier's lines 102 and 103 — and must print
      **0** after it. The strings are read out of
      `gates/retired-phrases.sh`, never retyped into a tracked file.
- [ ] This node's `prd.md` still carries its exempted quote — the allow-list
      line reports `MISSING 0`, not `MISSING 1`.
- [ ] `bash tests/capsule-lifecycle.sh`, run **alone**, reaches `EXIT=0`
      with the tally quoted: `capsule-lifecycle: 60 pass, 0 fail`, unchanged
      from the baseline.
- [ ] `python3 gates/tree-links.py --root . --tier a` names no `BROKEN` row
      under `prds/01-capsule/`, so the new cross-link into
      `00-delivery/corrections/capsule-rm-guard-attribution/prd.md`
      resolves. Asserted against the baseline and by naming the rows, never
      as an absolute count — the one broken row standing today belongs to
      another node.
- [ ] `bash gates/wave-status.sh --run 0` exits 0 with no `^FAIL` line.
- [ ] No box moved in the carrier file: `- [ ]` 0, `- [~]` 7, `- [x]` 3,
      the same three counts as the baseline.
- [ ] The R3 residue is in the report, with its verdict and the argument for
      filing it separately, so the orchestrator can open the node.

## Verify and Proof

```sh
cp prds/01-capsule/01-container-lifecycle/specs/spec01-capsule-cli.md /tmp/carrier-baseline.md

# the sweep — the actual proof, run alone
bash gates/retired-phrases.sh 2>&1 | tee /tmp/rp.log; echo "rc=$?"
/usr/bin/grep -cE '^FAIL' /tmp/rp.log
/usr/bin/grep -E 'armed carriers|allow-list:' /tmp/rp.log
/usr/bin/grep -E '^FAIL' /tmp/rp.log | /usr/bin/grep -cE '01-capsule/|capsule-rm-reworded-claim/'

# the armed strings, read out of the gate and never retyped
sed -n '/^phrases_table/,/^EOF/p' gates/retired-phrases.sh \
  | /usr/bin/grep '^RP5' | cut -d'|' -f3 > /tmp/rp5-strings.txt
cat /tmp/rp5-strings.txt          # 3 rows
/usr/bin/grep -rnF -f /tmp/rp5-strings.txt \
  prds/01-capsule \
  prds/00-delivery/corrections/capsule-rm-reworded-claim/specs | wc -l

# regression checks
bash tests/capsule-lifecycle.sh 2>&1 | tail -1
python3 gates/tree-links.py --root . --tier a --count-only
bash gates/wave-status.sh --run 0 > /tmp/w0.log 2>&1; echo "rc=$?"
/usr/bin/grep -cE '^FAIL' /tmp/w0.log

# boxes and blast radius
for p in '- [ ]' '- [~]' '- [x]'; do
  printf '%s => %s\n' "$p" \
    "$(/usr/bin/grep -cF -- "$p" prds/01-capsule/01-container-lifecycle/specs/spec01-capsule-cli.md)"
done
git status --porcelain
```

## Out of scope

- Every guard. `capsule.nu`'s `dir_label` refusal, `_capsule_owned`'s label
  and prefix filter, and the `docker ps` filter stay exactly as they are.
- Closing the R4 seam. It is a definitional divergence over an input this
  tool cannot produce; closing it changes a guard, which is C.1's or C.2's.
- A semantic gate for rewordings. `retired-phrase-sweep` R5 declined it on
  three measurements, and this node is the hand-fix that decision implies.
- `gates/retired-phrases.sh`, including its `exempt_table`. This edit needs
  no new row: the replacement text carries neither armed string, measured on
  a scratch copy.
- Registering the gate in `gates/waves.tsv`. That waits on
  `shell-down-spec-carriers` too, and belongs to whoever registers it. One
  fact for that owner, measured here: with all six armed carriers repaired
  in a scratch copy the sweep exits 0 with 0 FAIL — and at that point the
  gate's own `--selftest` CF12 inverts, because its first assertion is that
  an *untouched* copy is red.
- The R6 paraphrase in `01-capsule/01-container-lifecycle/prd.md`. Filed
  above, argued above, not fixed here.
