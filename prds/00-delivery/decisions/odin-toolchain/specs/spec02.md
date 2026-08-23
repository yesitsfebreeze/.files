# spec02 — Propagate the exclusion to the three places a reader looks

est: 0.5h

## Goal

`SYSTEM.md` requires that a `DO NOT PORT` decision "belongs in the epic's
Non-goals and the README's exclusion list, not just in the inventory". None of
the three carry it, and one of them is actively **wrong**: `.mi/SYSTEM.md`'s
Known gaps still tells every agent that reads the working contract that this
fork is "not decided". A stale gap is worse than a missing one — it invites a
second round of the same question.

There is also a real reconciliation here, not just three copies of a
sentence. The capsule epic's `## Out of scope` currently reads *"Multiple
images or per-project Dockerfile customization (later, if ever)"* — which, on
its face, forbids the escape hatch the decision depends on. The decision says
projects that need Odin add it per-project on top of the base. Both are true
once the boundary is stated: **capsule** ships and runs exactly one image and
will not customize per project; a **project** may build its own image `FROM`
that base, and capsule neither manages nor discovers it. That sentence is the
substance of this spec.

Kept separate from spec01 deliberately: spec01 touches one uncontended file,
this one touches three shared ones (see the ownership notes below), so the
orchestrator can serialize this without holding up the record itself.

## Files touched

Body text only in all three. **Do not edit any frontmatter.**

- `.mi/prds/01-capsule/prd.md` — `## Out of scope` only.
- `.mi/prds/README.md` — the `## Excluded` section only.
- `.mi/SYSTEM.md` — one bullet under `## Known gaps` (`AGENTS.md` and
  `CLAUDE.md` are symlinks to this file; edit the target, not the links).

### Ownership hazards, read before writing

- `w0-4-s2-corrections/delivery` (W0.4g) declares in its Purpose that it
  **owns `.mi/prds/README.md`**, and its R4 rewrites the exclusions because
  they are currently stated twice. Put the new entry **only inside the
  `## Excluded` section** — never in the prose paragraph near the top of the
  file — so W0.4g's de-duplication has nothing of ours to delete. W0.4g runs
  after this task in the wave order; if it has already landed, re-read
  `## Excluded` and match whatever shape it left behind.
- `w0-5-capsule-rebase` (W0.5) re-bases `01-capsule` on "build once" and will
  revisit the epic. It runs later. Nothing here contradicts "build once" —
  it sharpens it — but if W0.5 has already landed, merge into its wording
  rather than reverting it.
- The other four decision nodes (`tinty`, `fzf`, `shift-select-scope`,
  `wallpaper-opacity`) also have business in `.mi/SYSTEM.md`'s Known gaps,
  specifically the *"Three scope decisions are blocked on the human"* bullet.
  **Do not touch that bullet.** Only the `01-capsule/02` bullet is ours, and
  the verify asserts the fzf bullet survived untouched.

## What to write

### 1. `.mi/prds/01-capsule/prd.md` — `## Out of scope`

Replace the existing first bullet with a version that states the boundary,
and add the exclusion:

- Multiple images, or per-project Dockerfile customization by the capsule
  tool: it builds and runs exactly one image definition. A project that needs
  more is free to build its own image `FROM` that base — capsule neither
  manages nor discovers it, which is what keeps "one image definition" true.
- The Odin compiler built from source, and the `pi` agent with its pi-oilrig
  extensions. Dropped from the image 2026-08-21; the decision and its reason
  are recorded in [`02-dev-image`](02-dev-image/prd.md) under
  `## Decisions`, and projects needing them layer them per-project.

Leave the other two bullets alone.

### 2. `.mi/prds/README.md` — `## Excluded`

Add a dated paragraph, in the shape the burrito entry already established a
few lines above it:

> **`DO NOT PORT` — the dev image's Odin/pi toolchain**, decided 2026-08-21:
> the Odin compiler built from source and the `pi` agent with its ~20
> pi-oilrig extensions come out of the consolidated capsule image. They
> dominate cold build time and serve a minority of projects. Relocated rather
> than lost — a project that needs them layers them per-project on top of the
> base image. Recorded in
> [`01-capsule/02-dev-image`](01-capsule/02-dev-image/prd.md).

Do **not** touch `.mi/docs/capabilities.md`, even though its line 95
("Standalone dev container image") is where this toolchain is inventoried.
That file is user-authored and `w0-4-s2-corrections/docs-inventories` R1
blocks edits to it until the author confirms. This spec's paragraph names the
capability precisely enough that the inventory sweep can pick it up.

### 3. `.mi/SYSTEM.md` — `## Known gaps`

**Delete** the third bullet in full:

> - **`01-capsule/02` has an open question** — whether the Odin-from-source
>   and pi/pi-oilrig toolchain survives into the consolidated image.
>   Recommendation recorded in the PRD; not decided.

Delete, do not rewrite in place. It is no longer a gap, and the section's own
opening line scopes it to things "recorded so nobody mistakes them for
finished work".

Do **not** add a replacement bullet under `## Scope decisions already made`.
That section's own last bullet says the canonical exclusion list is the
README's, "don't duplicate it here" — and step 2 just put it there.

## Acceptance

- [x] `01-capsule/prd.md`'s `## Out of scope` names `Odin`, carries the date
      `2026-08-21`, points at `02-dev-image`, and states the `FROM`-the-base
      escape hatch.
- [x] Its bullet about multiple images no longer reads as a blanket ban on
      per-project layering; it scopes the ban to the capsule tool.
- [x] `README.md`'s `## Excluded` section carries a dated Odin entry that
      records the `per-project` relocation.
- [x] The entry appears exactly once in `README.md` — it is not also added to
      the prose exclusion pointer near the top of the file.
- [x] `.mi/SYSTEM.md`'s `## Known gaps` no longer mentions Odin.
- [x] The `## Known gaps` bullet about the three human-blocked scope
      decisions is untouched, and the other two gap bullets still exist.
- [x] `.mi/docs/capabilities.md` is unmodified.
- [x] No box anywhere is flipped to `[x]` or `[~]` by this spec.
- [x] All three files still wrap at ~78 columns (tables exempt).

verify: ""

Proven RED against the current tree before being written here: it reports the
four missing strings in the epic's Out of scope, the three missing in the
README's `## Excluded`, and `SYSTEM.md still lists the Odin fork as an open
gap`, exiting 1. The two negative guards (fzf bullet intact, `capabilities.md`
unmodified) pass now and are there to fail if the implementer overreaches.

## Spent proof

`AGENTS.md`'s Known gaps holds two bullets and no longer carries "and is fzf
an accepted", because `decisions/fzf` answered and removed that
open-question bullet after this node closed, and `docs/capabilities.md` is
dirty in the working tree under another lane — while every assertion on this
node's own capsule-epic and README edits still passes.

Retired from `verify:` by
[`mi-rooted-verify-commands`](../../../corrections/mi-rooted-verify-commands/prd.md)
spec02. The command below is byte-identical to what spec01 left in this
file's `verify:`; it is kept because it is the execution record of a check
that once ran green.

```text
verify: `bash -c 'cd "$(git rev-parse --show-toplevel)"; rc=0; e=prds/01-capsule/prd.md; E() { awk "/^## Out of scope/{o=1;next} /^## /{o=0} o" "$e"; }; for s in "Odin" "2026-08-21" "02-dev-image" "FROM"; do E | grep -qF "$s" || { echo "FAIL: capsule epic Out of scope lacks: $s"; rc=1; }; done; r=prds/README.md; R() { awk "/^## Excluded/{x=1;next} /^## /{x=0} x" "$r"; }; for s in "Odin" "2026-08-21" "per-project"; do R | grep -qF "$s" || { echo "FAIL: README Excluded lacks: $s"; rc=1; }; done; [ "$(grep -c "Odin" "$r")" -le 2 ] || { echo "FAIL: README states the Odin exclusion more than once"; rc=1; }; s=AGENTS.md; awk "/^## Known gaps/{k=1;next} /^## /{k=0} k" "$s" | grep -qi "odin" && { echo "FAIL: SYSTEM.md still lists the Odin fork as an open gap"; rc=1; }; grep -qF "and is fzf an accepted" "$s" || { echo "FAIL: an unrelated Known-gaps bullet was disturbed"; rc=1; }; [ "$(awk "/^## Known gaps/{k=1;next} /^## /{k=0} k" "$s" | grep -c "^- \*\*")" -eq 3 ] || { echo "FAIL: Known gaps should hold exactly 3 bullets after the removal"; rc=1; }; git diff --quiet -- docs/capabilities.md || { echo "FAIL: capabilities.md was modified"; rc=1; }; [ $rc -eq 0 ] && echo OK; exit $rc'`
```
