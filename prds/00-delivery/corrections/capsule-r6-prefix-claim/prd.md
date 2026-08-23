---
state: open
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
- [ ] **R1** — R6 names the test that is actually applied: the `capsule.dir`
      label key **and** the `capsule-` prefix, via `_capsule_owned`. The
      prefix alone is not the guard, and saying so is the correction.
- [ ] **R2** — The absolute — "never any other container on the host" — is
      replaced by what holds: never a container this tool did not create, with
      the imitator seam named and cross-referenced rather than restated. An
      absolute a single fixture refutes is worse than a bounded claim.
- [ ] **R3** — **Re-measure before rewriting.** `capsule.nu` has been edited
      three times today and every line number in the citing nodes is already
      stale. Confirm which test each command applies, from the file as it is.
      Never run a real `docker rm`; never touch a container outside a
      recording shim; never print a credential value.
- [ ] **R4** — R6's marker and what would falsify it do not change — this is a
      description fix inside a `done` node's requirement, and R1/R2 change the
      claim's *accuracy*, not its subject. If a correct restatement would
      change what the requirement demands, **stop and report**: that is a
      scope change and the user's call.
- [ ] **R5** — **Census R1-R9 of that PRD for other absolutes.** One
      requirement understating its guard while overstating its guarantee is
      unlikely to be alone in a nine-requirement node. Report per requirement;
      widen nothing.

## Acceptance
- [ ] The corrected R6 quoted beside R3's measurement, both commands.
- [ ] The imitator seam cross-referenced, not restated.
- [ ] `bash tests/capsule-lifecycle.sh` reaches `EXIT=0`, run **alone**, tally
      quoted not asserted. Baseline 60 pass / 0 fail.
- [ ] The R5 census in the report, one line per requirement.

## Out of scope
- Closing the seam, which changes a guard — C.1's or C.2's.
- `spec01-capsule-cli.md`, already corrected by
  [`capsule-rm-reworded-claim`](../capsule-rm-reworded-claim/prd.md).
