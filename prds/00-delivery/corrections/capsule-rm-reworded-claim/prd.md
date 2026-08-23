---
state: done
claim: 
priority: 39
est: 0.5h
actual: 35m
mode: afk
verify: "bash tests/capsule-lifecycle.sh"
origin: derived
from: 00-delivery/corrections/capsule-rm-guard-attribution
---

# The `docker rm` universal claim survives, reworded by one verb

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: [`capsule-rm-guard-attribution`](../capsule-rm-guard-attribution/prd.md)
(`done`) retired `capsule.nu:453`'s claim that "there is no code path that
**reaches** `docker rm` outside the `_capsule_owned` set" — measured false,
because `:405` reaches it from `_capsule_name` on the `--rebuild` path, guarded
instead by the `dir_label` check at `:399-401`.

`retired-phrase-sweep`'s analyst found the same claim alive at
`prds/01-capsule/01-container-lifecycle/specs/spec01-capsule-cli.md:102-103`,
reworded: **"no code path that `calls` `docker rm`"**.

**One verb, and the retirer's own closing grep returned zero.** This is the
single reworded carrier out of sixteen found across four sweeps — fifteen were
verbatim — which is exactly why that node recommended *against* building a
semantic gate, and exactly why this one has to be fixed by hand.

**It is the highest-stakes shape on the board.** An auditor of a destructive
path reads a universal claim about `docker rm`, checks `_capsule_owned`, finds
it sound, and never looks at the guard that actually covers `:405`. The
property holds; the attribution does not, and the attribution is what a
reviewer follows.

## Requirements
- [x] **R1** — The passage names the guard covering each of the three
      `docker rm` sites, as `capsule.nu`'s corrected comment now does:
      `_capsule_owned` for `:459`/`:461`, the `dir_label` refusal at
      `:399-401` for `:405`. **No universal claim** — the universal claim is
      what was wrong, in both wordings.
- [x] **R2** — **Re-verify the property before rewriting the prose**, briefly.
      `capsule-rm-guard-attribution` measured it on both routes against a
      recording docker shim, and its finding stands — but `capsule.nu` has
      been edited since, and the board's own rule now says a cheap claim gets
      run rather than inherited. Never run a real `docker rm`; never touch a
      container outside a scratch fixture.
- [x] **R3** — **Census for further rewordings of the same claim**, across
      `prds/`, `docs/` and `home/`. Vary the verb, not just the noun: this
      carrier differs by one word from the retired form, so a search keyed on
      `reaches` finds nothing. Report what the pattern would still miss.
- [x] **R4** — The seam
      [`capsule-rm-guard-attribution`](../capsule-rm-guard-attribution/prd.md)
      R3 recorded — `_capsule_owned` tests the label **key** plus prefix while
      `:399-401` tests its **value**, diverging on a `capsule-*` container
      with an empty `capsule.dir` — is stated wherever a universal claim is
      replaced, so the next reader sees it rather than rediscovering it.

## Acceptance
- [x] The corrected passage quoted beside `capsule.nu`'s comment, with the
      three sites and their guards.
- [x] R2's re-measurement quoted, both routes, with zero `rm` lines on the
      foreign-container case.
- [x] The R3 census in the report, with its stated blind spot.
- [x] `bash tests/capsule-lifecycle.sh` reaches `EXIT=0`, run **alone**,
      tally quoted not asserted. Baseline was 60 pass / 0 fail.

## Out of scope
- Changing any guard, or closing the R4 seam. Both are C.1's or C.2's.
- Building a semantic gate for rewordings.
  [`retired-phrase-sweep`](../retired-phrase-sweep/prd.md) R5 recommended
  against it on three measurements, and this node is the hand-fix that
  recommendation implies.

## Landed 2026-08-23 — executed by the orchestrator

The footprint is another `done` PRD's spec file and holds no gate, so this was
mine. The one edit replaced the paragraph whose closing sentence is RP5's
`variant` string in `gates/retired-phrases.sh`'s `phrases_table` — **quoted
here by table row rather than typed, because this node's folder carries no
waiver for it.** Its own analyst proved that trap by planting the string into
a scratch copy of its spec and watching two FAIL lines appear; I then walked
straight into it in this very paragraph, and the gate caught me. The
replacement is an **enumeration** of the three sites and the guard over each — and the
seam stated where the universal claim stood. Verified after:
`gates/retired-phrases.sh` armed carriers **6 → 4**, with no `CARRIER` line
naming any path under `prds/01-capsule/`; `gates/tree-links.sh` exit 0, Tier A
**885 links / 0 broken**. Exactly the pre-validated result.

**R2: `reproduced`, both routes, run rather than inherited.** Recording docker
shim, scratch `HOME`, no daemon, no real `docker rm`. Route A gained a **new
input** — a *stopped* container with an empty label — and refused it with zero
`rm`, same as running. Route B's mixed fixture left `moved-away` (label, no
prefix), `capsule-imposter` (prefix, no label) and `redis` out of every `rm`
line. Both controls confirm both guards load-bearing: neuter the `dir_label`
test and the label-less container is removed on **both** empty-label inputs;
drop `--filter label=capsule.dir` and `clean` takes `capsule-imposter` too.

**This PRD's own line numbers were stale when I wrote them.** `:405`/`:459`/
`:461`/`:399-401` are now `:423`/`:497`/`:499` and `:414-416` — moved by
`capsule-rm-guard-attribution`'s own comment edits. The replacement text
therefore **cites no line number at all**, naming step and branch instead.
That is the right lesson from a session in which stale line numbers have
bitten five specs.

**R3: `refuted for further rewordings`** — three predicates over 528 files,
each file normalised to one line then split into sentences because the retired
form wraps. **P1 is verb-free** (`no` … `path` … `that`), which is what
catches `calls` as readily as `reaches`. One live carrier: the filed one.
Honestly stated blind spots: a claim with neither subject token nor a
universality word, a claim about a *different* destructive command
(`docker kill`/`stop`/`rmi`/`system prune`), and a claim split across two
sentences. None worth a gate — `retired-phrase-sweep` R5's measurements stand.

## The trap it found while writing the spec

**The gate's tier-1 waiver covers a *retirer's* folder, and RP5's retirer is
`capsule-rm-guard-attribution` — not this node.** So neither the spec nor the
replacement text may quote either armed string. Planted both into a scratch
copy of this node's own spec: `armed carriers: 2`, two new FAIL lines. The
mirror is equally load-bearing — deleting the quote from this node's `prd.md`
gives `MISSING 1` on the set-equality allow-list. The spec instructs the
executor to read the strings out of `phrases_table` with `grep -f` rather than
retype them, which is the only safe way to verify a phrase you are forbidden
to write.

## Two things for whoever registers the wave-0 gate

1. **With the four RP4 carriers also repaired, the sweep exits 0** — measured
   on a scratch copy. So registration is reachable the moment
   [`shell-down-spec-carriers`](../shell-down-spec-carriers/prd.md) lands.
2. **The gate's own `--selftest` CF12 will then invert**, because its first
   assertion is that an *untouched* copy is red. Not this node's to fix, and
   recorded so it is not mistaken for a regression.

## R3's residue — filed, not fixed

P3, the paraphrase probe, earned its place by finding one:
`prds/01-capsule/01-container-lifecycle/prd.md` R6 says both commands *"only
ever touch containers this tool created (the `capsule-` name prefix of R1) —
never any other container on the host."* Verdict
`refuted (imitator container: capsule-* with a present but EMPTY capsule.dir,
recording shim)` — `clean` logged `rm capsule-seam-44444444` while `--rebuild`
refused the same shape. **The parenthetical is wrong twice over**: it names the
prefix as the test, when `_capsule_owned` is label **and** prefix — narrower
than R1's prefix. Left out of scope with the argument on the record: different
claim, not an armed carrier, and inside a requirement of a `done` node where a
fix changes substance. Filed as
[`capsule-r6-prefix-claim`](../capsule-r6-prefix-claim/prd.md).
