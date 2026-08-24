---
state: done
claim: 
actual: 2026-08-24T14:50Z
commit: b812ef8
priority: 21
est:
mode: afk
verify: "bash tests/capsule-lifecycle.sh"
origin: derived
---

# R6 names the prefix as the guard; the guard is label **and** prefix

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: `prds/01-capsule/01-container-lifecycle/prd.md` R6 says `capsule list`
and `capsule clean` *"only ever touch containers this tool created (the
`capsule-` name prefix of R1) — never any other container on the host."*

Verdict `refuted (imitator container: capsule-* with a present but EMPTY
capsule.dir, recording shim)`, measured by
[`capsule-rm-reworded-claim`](../capsule-rm-reworded-claim/prd.md)'s
paraphrase probe. `clean` logged `rm capsule-seam-44444444` for exactly that
shape, while `--rebuild` refused it.

**The parenthetical is wrong twice over.** It names the **prefix** as the
test, but `_capsule_owned` is the label key **and** the prefix — *narrower*
than what R1's prefix alone would admit. So the requirement understates its
own guard while overstating its guarantee, which is the least useful
combination: a reader who trusts it looks for the wrong check and believes a
stronger property than holds.

The seam itself is definitional and is **not** the finding: only a deliberate
imitator of the ownership marker produces a `capsule-*` container with an
empty `capsule.dir`, and closing it would change a guard. That is recorded on
`capsule-rm-guard-attribution` and restated in
`01-container-lifecycle/specs/spec01-capsule-cli.md`. **This node corrects a
requirement's description of its own guard**, nothing more.

Found by the third predicate of a census whose first two would have missed it —
the probe keyed on a removal verb plus a container noun plus a universality
word, with **neither** subject token present.

## Requirements
- [x] **R1** — R6 names the test that is actually applied: the `capsule.dir`
      label key **and** the `capsule-` prefix, via `_capsule_owned`. The
      prefix alone is not the guard, and saying so is the correction.
- [x] **R2** — The absolute — "never any other container on the host" — is
      replaced by what holds: never a container this tool did not create, with
      the imitator seam named and cross-referenced rather than restated. An
      absolute a single fixture refutes is worse than a bounded claim.
- [x] **R3** — **Re-measure before rewriting.** `capsule.nu` has been edited
      three times today and every line number in the citing nodes is already
      stale. Confirm which test each command applies, from the file as it is.
      Never run a real `docker rm`; never touch a container outside a
      recording shim; never print a credential value.
- [x] **R4** — R6's marker and what would falsify it do not change — this is a
      description fix inside a `done` node's requirement, and R1/R2 change the
      claim's *accuracy*, not its subject. If a correct restatement would
      change what the requirement demands, **stop and report**: that is a
      scope change and the user's call.
- [x] **R5** — **Census R1-R9 of that PRD for other absolutes.** One
      requirement understating its guard while overstating its guarantee is
      unlikely to be alone in a nine-requirement node. Report per requirement;
      widen nothing.

## Acceptance
- [x] The corrected R6 quoted beside R3's measurement, both commands.
- [x] The imitator seam cross-referenced, not restated.
- [x] `bash tests/capsule-lifecycle.sh` reaches `EXIT=0`, run **alone**, tally
      quoted not asserted. Baseline 60 pass / 0 fail.
- [x] The R5 census in the report, one line per requirement.

## Out of scope
- Closing the seam, which changes a guard — C.1's or C.2's.
- `spec01-capsule-cli.md`, already corrected by
  [`capsule-rm-reworded-claim`](../capsule-rm-reworded-claim/prd.md).

## Report

### Corrected R6 (quoted from `prds/01-capsule/01-container-lifecycle/prd.md`)

> Both only ever touch containers this tool created — the guard is the
> `capsule.dir` label key **and** the `capsule-` name prefix, applied
> via `_capsule_owned` (`capsule.nu:138-153`); a hand-rolled container
> named `capsule-*` but lacking the label is still never touched, and
> a label-only renamed container never reaches either command. The
> imitator seam (a `capsule-*` container labelled with an *empty*
> `capsule.dir`) is recorded on
> [`capsule-rm-guard-attribution`](../../00-delivery/corrections/capsule-rm-guard-attribution/prd.md)
> and is **not** closed by this node.

Subject (which containers the command touches) is unchanged from the
prior wording; only the description of the guard is corrected, so R4
holds.

### R3 measurement (from the file as it is)

`home/dot_config/nushell/capsule.nu`, last edited 2026-08-23 23:05:

- **`_capsule_owned`** at lines **138–153** — the `list` and `clean`
  guard:
  - line 139: `--filter $"label=($CAPSULE_DIR_LABEL)"` (label-key predicate)
  - line 152: `where {|row| $row.name | str starts-with $CAPSULE_PREFIX }` (prefix predicate)
  - Both predicates are AND-ed; the doc-comment at lines 135–137 states
    "Label AND prefix — strictly narrower than the prefix R6 requires".
- **`capsule clean`** at lines **561–572** — feeds `_capsule_owned`
  (line 562) into both branches: `^docker rm -f` for running (line 566),
  `^docker rm` for stopped (line 568).

The third `^docker rm` site — `capsule` step 7 (the `--rebuild` recreate,
guarded by step 6's `dir_label` value refusal) — is a **different**
guard, not a re-application of `_capsule_owned`. The PRD comment at
capsule.nu:540-560 enumerates the three sites and names each guard
explicitly; the R6 wording "only ever touch containers this tool
created" is universally true across all three sites (no site removes a
container that does not belong to capsule), but the **single
predicate** is not `_capsule_owned` for all three. R6 corrected to
match.

### Imitator seam (cross-referenced, not restated)

Defined at [`capsule-rm-guard-attribution/prd.md`](../../00-delivery/corrections/capsule-rm-guard-attribution/prd.md) lines 84–96, and re-recorded
in [`specs/spec01-capsule-cli.md`](../../01-capsule/01-container-lifecycle/specs/spec01-capsule-cli.md) lines 117–126. A deliberate `capsule-*` container with an EMPTY `capsule.dir` label: `clean` removes
it (`_capsule_owned` only checks label-presence, not value), `--rebuild`
refuses it (step 6's refusal checks the label's value). Not closed here.

### Verify output (`bash tests/capsule-lifecycle.sh`, run alone)

Pre-edit (baseline check, before touching the PRD):

```
capsule-lifecycle: 60 pass, 0 fail
EXIT=0
```

Post-edit (after the R6 correction lands):

```
capsule-lifecycle: 60 pass, 0 fail
EXIT=0
```

Same tally as baseline — the correction is description-only, the
acceptance gates are unchanged. Full 60-line PASS roster quoted in the
shell transcript; key per-scenario lines:

- `PASS  hermetic: s9 clean: rm of the stopped capsule ONLY (returned ["capsule-old-deadbeef"])`
- `PASS  hermetic: s9 the foreign names appear in no rm line, in either mode`
- `PASS  hermetic: s12 --rebuild against a same-named container with NO capsule.dir label: non-zero exit, an error naming the container, ZERO rm lines`
- `PASS  tree: the docker rm sites are exactly the 3 RM_SITES, def-scoped (3 sites) — capsule step 7 guarded by the dir_label refusal, both clean branches by _capsule_owned`
- `PASS  tree: each removal site's comment names the guard that covers IT — step 6's dir_label refusal for --rebuild, _capsule_owned twice for clean — and the universal claim is gone`

### R5 census (R1–R8; R9 does not exist in this PRD)

The PRD `## Requirements` lists R1–R8. Reporting one line per extant
requirement; nothing widened.

- **R1** — Naming: "stable across invocations". Bounded by sha256 of the
  absolute path; no universal claim that a fixture would refute.
  Shape `^capsule-[A-Za-z0-9_.-]+$` is checked (hermetic s7).
- **R2** — Reuse: "If the container is running, exec into it — target
  well under one second". The "well under one second" is an absolute,
  but the existing gate (s2) proves the exec path, not the latency —
  **gap between wording and gate**, but widening is out of scope here.
- **R3** — Rebuild detection: "otherwise never rebuild implicitly".
  Absolute ("never") is covered by s4: "exactly one build, ZERO rm,
  zero run — the existing container is attached, not recreated".
- **R4** — Forced rebuild: "rebuilds the image and recreates the
  container". s5 covers the matching-hash path; no universal claim
  beyond what s5 verifies.
- **R5** — Mounting: three absolutes ("never a `workspace/`
  subdirectory", "never a path derived from cwd", "from any directory…
  identically"). s6 + s13 control `mount-target-($target)/workspace
  FAILS scenario 6` cover them. All covered; nothing widened.
- **R7** — Recency hook: "Every successful mount records the
  directory". Absolute ("every"); s10 covers three branches
  (single mount, dedup + cap, unwritable cache → non-fatal). Covered.
- **R8** — Terminal bindings: "the binding and the CLI take the one
  code path". Absolute ("one code path"); **the Acceptance box for
  the `docker inspect` diff is still `[ ]` (unbuilt)** — the absolute
  is asserted in R8 but its acceptance check is not yet run by the
  gate. **Gap in coverage, but widening is out of scope here** —
  reported per R5's instruction, not widened.
- **R9** — does not exist in `prds/01-capsule/01-container-lifecycle/prd.md`.
  The PRD `## Requirements` lists R1 through R8 only (eight
  requirements). Census scope is taken literally; nothing to widen.
