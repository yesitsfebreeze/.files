---
state: done
priority: 45
est: 2h
task: W0.8
mode: afk
needs:
verify: ""
origin: derived
from: 00-delivery/verification-gates
---

# Gate reconciliation

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: two of the repo's real gates are **red right now**, each broken by
later work that was itself correct. Repoint them at what is true, without
weakening what they check.

**Created 2026-08-21 by the orchestrator**, from reds that
[`verification-gates`](../../verification-gates/prd.md) (G.1) surfaced by
running the first full sweep, both confirmed independently. This is the
supersession pattern that has recurred all session — a closed ticket's
assertion stranded by a later landing — but in the repo's **executable gates**
rather than in spec verifies, which makes it louder and more urgent: a red gate
that everyone learns to ignore is worse than no gate.

Both owning nodes are `done`, so neither can repair its own gate. Hence this
node.

## Requirements
- [x] **R1** — `tests/deploy-skeleton.sh:212` asserts `gates/justfile` is
      **absent**, proving the root justfile's `import?` is genuinely optional.
      G.1 then created `gates/justfile`, so the assertion now fails on the
      success of another node. **The intent is still worth checking** — the
      import must stay optional, or a fresh clone without `gates/` breaks.
      Re-express it against a repo copy with `gates/` removed, rather than
      deleting the check. Owner of the file: `repo-skeleton` (P.1), `done`.
- [x] **R2** — `tests/live-bugs.sh` fails `doc: the L-12 correction is
      recorded` and `doc: L-13 recorded`. Both grep
      `.mi/docs/capabilities-provisioning.md`, which
      [`provisioning-rerate`](../w0-4-s2-corrections/provisioning-rerate/prd.md)
      (W0.4i) rewrote on the user's decision. The records **still exist and are
      now more accurate** — L-12's five phantom files are struck and L-13's
      figures read `1149 vs 1149`. Repoint the greps at the corrected text.
      Owner of the file: `w0-6-live-bugs` (W0.6), `done`.
- [x] **R3** — Neither repair may weaken its check. Each repointed assertion is
      proved to still **fail** against the pre-correction text, so it is a
      moved goalpost and not a deleted one.
- [x] **R2b** — **`tests/live-bugs.sh:31` reads the wrong tree.** It sets
      `SRC="$HOME/.local/share/chezmoi/home/dot_config"` — the stale June clone
      that [`provisioning-rerate`](../w0-4-s2-corrections/provisioning-rerate/prd.md)
      forbade citing as the source. The real source is
      `/Users/feb/dev/.files/home/dot_config`, which is what `chezmoi
      source-path` reports. Repoint `SRC` and re-express the **eleven** L-12/L-13
      **live** assertions against it (4 under L-12, 7 under L-13 — measured;
      the orchestrator first wrote "nine").
      *Seven of those eleven currently assert the opposite of the record and pass
      only because of the wrong tree* — measured: `solo-window.sh` is absent
      from the real source (present in the clone), the source `wezterm.lua` has
      **0** references to it (the clone has 3), source and deployed
      `wezterm.lua` are `1149 vs 1149` and `finder.nu` `221 vs 221`
      (byte-identical, not "far shorter"/"longer"), and `dirstack.nu`,
      `quicklist.nu`, `overlay.nu`, `opacity.nu` **are** in the real source.
      Same standard as R3: each re-expressed assertion is proved to fail
      against the clone reading.
- [x] **R4** — The backlog-table and Owner-cell routing machinery must survive
      **untouched** — no assertion added, removed or reworded there. Changes
      are confined to the two doc greps, the `SRC` definition, and the
      L-12/L-13 live blocks. Note `rr` is a substring of "correction" and ids
      collide (`T-1` inside `T-10`, `M-2` inside `M-20`); BSD `grep`'s `\b` is
      unusable here.
- [x] **R5** — Record both supersessions in the closing notes of the nodes that
      owned them (P.1 and W0.6), so the audit trail shows why an assertion
      moved rather than leaving it looking like drift.

## Acceptance
- [x] `bash tests/live-bugs.sh` exits 0.
- [x] `bash tests/deploy-skeleton.sh` exits 0.
- [x] `just gates` still exits 0, and its PASS count has not fallen.
- [x] Each repointed assertion is demonstrated red against the old text.
- [x] No assertion in `tests/live-bugs.sh` measures `~/.local/share/chezmoi`.

## Out of scope
- Tier B's 95 broken links, which G.1 reports without gating.
- The three `.mi/workflows/refs/` links, owned by
  [`stale-framework-links`](../stale-framework-links/prd.md).

## Amendment — 2026-08-21

*Amended by the orchestrator, on the analyst's REFINE.* It declined to spec
this as written, correctly.

R4 originally said "only the two doc greps change". Implementing that literally
would have produced **a green gate that lies**: `live-bugs.sh` would exit 0
while its doc half asserted "the record says `solo-window.*` are absent from
the live source" and its live half asserted "`solo-window.sh` **is** in the
chezmoi source" — a self-contradicting pass, built on the one tree the record
forbids citing. That is strictly worse than today's honest red, and it is the
exact failure this ticket exists to prevent.

It also had a downstream victim.
[`backlog-closeout`](../w0-4-s2-corrections/backlog-closeout/prd.md) (W0.4h)
carries `verify: "bash tests/live-bugs.sh"`, and its **R9** exists to route
"the sweep used the wrong baseline — re-measure against `/Users/feb/dev/.files`,
never the clone". R9 routes the inventory *docs*; nobody owned the same defect
in the *gate script*. Greening the gate first would have let W0.4h close
against a check that reads the clone.

R2b is added, R4 narrowed to the machinery it was actually protecting, one
acceptance line added, and est raised 1h → 2h.

## Implementation note — 2026-08-21

Implemented by `impl-W0-8` across spec01–spec04. Measured outcome:

| gate | before | after |
|---|---|---|
| `tests/live-bugs.sh` | exit 1, 144 PASS / 2 FAIL, 146 assertions | exit 0, **159 PASS / 0 FAIL** |
| `tests/deploy-skeleton.sh` | exit 1, 1 assertion in the import stage | exit 0, **56 PASS / 0 FAIL**, 4 in that stage |
| `just gates` | exit 1, 429 PASS / 8 FAIL | exit 0, **571 PASS / 0 FAIL** |

`table:` 40 and `routing:` 50 are unchanged either side — R4's machinery was
not touched. The +13 in `live-bugs.sh` is 2 `source:` guards, L-12 4→6,
L-13 7→9, and the 7-assertion `goalpost:` block.

**R5 is not done.** Recording the two supersessions in P.1's and W0.6's
closing notes falls outside this implementation's footprint (which was
`tests/deploy-skeleton.sh`, `tests/live-bugs.sh` and this file), and no spec
covers it. It needs a separate pass over the two owning nodes.

**Two spec discrepancies, recorded rather than worked around:**

1. **spec01's `verify:` is off by one.** It asserts the new-label PASS count
   is `-eq 3`, but its own design and boxes specify **four** assertions, all
   four of whose labels match the verify's regex
   `^PASS  push: (optional import|NEGATIVE|control)`. The count is 4. The
   design was implemented in full — dropping an assertion or renaming a label
   to satisfy the numeral would be exactly the weakening this ticket forbids.
   With `-eq 4` the verify exits 0; as literally written it exits 1.
2. **spec03's count correction holds.** Eleven live assertions were found
   where R2b originally said nine, and all seven contradictions listed in R2b
   were reproduced against the real source before the rewrite.

## Closing note

*Closed 2026-08-21 by the orchestrator.* All four spec verifies green from
reproduced RED baselines. Independently re-run:

| gate | before | after |
|---|---|---|
| `tests/live-bugs.sh` | exit 1 · 144 PASS / 2 FAIL | **exit 0 · 159 PASS / 0 FAIL** |
| `tests/deploy-skeleton.sh` | exit 1 · 25 PASS | **exit 0 · 56 PASS / 0 FAIL** |
| `just gates` | exit 1 · 429 PASS / 8 FAIL | **exit 0 · 571 PASS / 0 FAIL** |

**PASS counts rose in every gate.** The only assertion removed is the one R1
explicitly replaces, confirmed by a label-set diff of the before/after runs —
so this was a moved goalpost, not a deleted one, which was the whole standard.

**What this ticket actually caught.** The stale-clone error — the one that
invalidated `02-terminal`, then `02-package-provisioning` — had also colonised
`tests/live-bugs.sh` itself, a gate built to catch exactly that class. Seven of
its eleven L-12/L-13 assertions were green *and asserting the opposite of the
record*, passing only because `SRC` pointed at the June clone. It had been
passing all session, and every lane that ran it read the green as evidence.
`SRC` is now guarded against `chezmoi source-path` so it cannot drift back.

**R5 discharged by the orchestrator**, correctly left open by the implementer:
the two supersession records are outside a test-file footprint. They are now in
[`repo-skeleton`](../../../05-platform/01-deploy-mechanism/repo-skeleton/prd.md)
and [`w0-6-live-bugs`](../w0-6-live-bugs/prd.md).

**One spec defect, recorded not obeyed.** spec01's `verify:` hard-codes a
new-label PASS count of `-eq 3`, while its own design and boxes specify **four**
assertions. The implementer built the four and reported that the literal verify
string therefore exits 1 — refusing to drop an assertion or rename a label to
satisfy a numeral, which would have been exactly the weakening this ticket
forbids. The orchestrator repointed the numeral to `-eq 4`.

Design choices worth keeping: `cmp -s` rather than line counts (byte-identity is
what the record claims; line counts are the weaker proxy that produced the
original error); a `control:` assertion that `background.png` **is** in the real
source, because three L-12 checks assert absence and would pass vacuously
against a mistyped path; and the silent `else echo "SKIP"` arm replaced by a
real check — a silent skip is how this rotted, and it is the third instance
this session of a check degrading quietly rather than failing loudly.
