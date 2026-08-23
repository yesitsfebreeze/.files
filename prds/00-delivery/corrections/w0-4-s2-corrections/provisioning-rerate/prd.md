---
state: done
priority: 37
est: 1.6h
task: W0.4i
mode: afk
needs:
  - 00-delivery/corrections/w0-4-s2-corrections/docs-inventories
  - 00-delivery/corrections/w0-4-s2-corrections/platform
verify: ""
origin: derived
from: 00-delivery/corrections/w0-4-s2-corrections
---

# Provisioning inventory re-rate

Parent: [S2 corrections](../prd.md) · net-new

Purpose: fold the three inventory entries that rate deleted machinery into one
entry that rates what actually exists, and re-rate it.

**Created 2026-08-21 by the orchestrator.** The user decided
([`platform`](../platform/prd.md) Q2) to re-spec `05-platform/02-package-provisioning`
against `install.sh` and re-rate it C 8 → C 4, because commit **`8fe3a71`**
(2026-08-19) deleted `.chezmoidata/packages.yaml`, the 486-line `run_onchange`
installer and the Homebrew `run_once_before` template — 2490 deletions —
replacing them with a flat 233-line `install.sh`.

Neither existing lane can do this half.
[`docs-inventories`](../docs-inventories/prd.md) owns the file but its landed
spec03 **guards the opposite**: it asserts `Package installer` 8/9,
`Declarative package set` 2/9 and `Homebrew bootstrap` 2/8 stay put as separate
entries at those ratings, so folding them would turn a closed ticket's gate
red. [`platform`](../platform/prd.md) made the decision but does not own
`.mi/docs/`. Rather than let either lane reach outside its footprint, or let
the inventory keep rating machinery that no longer exists, the work gets its
own node with a replacement verify.

## Requirements
- [x] **R1** — `Package installer` (C 8 / U 9), `Declarative package set`
      (C 2 / U 9) and `Homebrew bootstrap` (C 2 / U 8) fold into **one** entry,
      suggested `## Tool installation (install.sh)`, rated **C 4 · U 9**.
      U stays 9: every epic still depends on its tools existing. C falls to 4
      because what is rated now is a guarded shell script with three mechanisms
      — package-manager batch install, a `latest_tag`/`fetch_release` GitHub
      ladder for tools distros lack, and a few cargo/git/npm builds — not a
      559-line template rendering a YAML model behind a sha256 gate.
- [x] **R2** — `Neovim version gating` (C 4 / U 8) stays its **own** entry. It
      survives inside `install.sh`, which parses `nvim --version` and installs
      the official tarball when the minor is `< 11`.
- [x] **R3** — The entry records that `8fe3a71` deleted the machinery the three
      folded entries rated, so a later reader does not restore them from the
      inventory.
- [~] **R4** — `.mi/docs/capabilities-provisioning.md`'s ratio sort is
      re-established after the fold, and `docs-inventories`' spec03 verify is
      **replaced**, not left failing. A closed ticket's gate may not be
      abandoned red; it is superseded on the record, as
      [`odin-toolchain`](../../../decisions/odin-toolchain/prd.md) and
      [`tinty`](../../../decisions/tinty/prd.md) were.
      *Half met 2026-08-21.* The sort is re-established and proven —
      `check01.sh` and `check03.sh` both print `OK`. The replacement of
      W0.4a's verify is recorded below and **routed**; it is outside this
      node's one-file footprint, so this box stays `[~]`.
- [x] **R5** — Every PRD header citing the three folded entries is reconciled,
      or the mismatch is routed to the node that owns it. The contract requires
      a PRD header's C/U to match its inventory entry.

## Acceptance
- [x] `capabilities-provisioning.md` names no entry rating deleted machinery.
      *Proven 2026-08-21* — `check01.sh` prints `OK`: the three folded
      headings are gone, and the two remaining references to deleted
      machinery (the burrito `cargo_git` bullet and `Neovim version gating`'s
      `run_onchange` pointer) now name it as deleted rather than as present.
- [x] The file's ratios are descending after the fold.
      *Proven 2026-08-21* — `check01.sh`'s ratio walk passes: `6 6 6 6 5 5 4
      0 -1 -2`.
- [x] No entry outside the fold moved or was re-rated.
      *Proven 2026-08-21* — `check01.sh` and `check03.sh` both assert the
      full ten-entry order and every C/U pair; both print `OK`.
- [~] `docs-inventories`' superseded assertions are replaced by ones that pass,
      and the supersession is recorded in that ticket.
      *Half met 2026-08-21, and it cannot close from here.* The record is
      written in [`## Superseded guard`](#superseded-guard) below and the two
      edits it needs — mirroring the record into `docs-inventories/prd.md`
      and repointing that ticket's `specs/spec03.md` verify — are routed to
      the orchestrator. W0.4i's `files` list is
      `.mi/docs/capabilities-provisioning.md` alone, so this node may not
      make either edit and may not mark this `[x]`.

## Out of scope
- The PRD-side re-spec of `05-platform/02-package-provisioning`, which is
  [`platform`](../platform/prd.md)'s (spec03/spec04/spec06/spec07).

## Superseded guard

**Recorded 2026-08-21 by W0.4i.** Three assertions in
[`docs-inventories`](../docs-inventories/prd.md)' (W0.4a) landed
`specs/spec03.md` verify are **superseded** by this node's pass over
`.mi/docs/capabilities-provisioning.md`. They are not violated and the
inventory is not wrong: they guard an entry set the user has since folded.

That verify was run against the tree before this node touched it and printed
`OK`, exit 0. After this pass it fails on exactly **three** of its
assertions, named concretely so nobody has to re-derive them:

1. the entry count, `[ "$(RAT | wc -l)" = "12" ]` — **12** becomes **10**;
2. the exact-order `WANT` string, which begins `Declarative package set|` and
   also contains `Homebrew bootstrap|` and `Package installer|`. All three
   names leave the file and `Tool installation` enters between `Small tool
   configs` and `Neovim version gating`;
3. three entries of the `RL` C/U table — the `8 / 9`, `2 / 9` and `2 / 8`
   pairs, written there as `Package installer@8 9`, `Declarative package
   set@2 9` and `Homebrew bootstrap@2 8`. Those headings stop existing, so
   `NUM` returns empty for each.

**Why they are stale.** The user's Q2 decision on
[`platform`](../platform/prd.md) folded those three entries into a single
`Tool installation (install.sh)` at **C 4 · U 9**, because commit `8fe3a71`
(2026-08-19) deleted the machinery all three rated. The guard therefore now
asserts an inventory that rates deleted machinery, which is exactly what this
ticket's first acceptance box forbids.

**One coordinated pass, not a fragment.** The same pass also landed spec03's
corrections to the same file: the head correction naming
`~/.local/share/chezmoi` as the **stale clone** whose HEAD `a2544e4` is an
ancestor of the live source's `8e99f58` (the live source is
`/Users/feb/dev/.files`); the `L-13` correction to `1149 vs 1149` /
`715 vs 715` / `221 vs 221` and the `L-12` correction to one real file; the
`just push` / `just cutover` rewrite of `Idempotent apply + push workflow`;
and the `tinted-theming` reconciliation of `Small tool configs` with
[`decisions/tinty`](../../../decisions/tinty/prd.md). **None of it costs a
fourth stale assertion**, and that was engineered rather than lucky: the
`L-12`, `L-13`, `solo-window` and `1149` tokens inside `Managed config
surface`, and the `Decision 4` / `canonical` / `not a port target` phrases in
the head, were all corrected **in place** — the guarded literals were
deliberately **kept** while the sentences around them were made true. Do not
tidy them away later; three assertions is the whole cost, and it stays three
only while those tokens survive.

**The replacement.** This node's own `specs/check01.sh` re-asserts every one
of spec03's surviving guards — the ratio-descending rule, the six surviving
C/U pairs, the burrito-out-of-the-surface checks, the `L-12` / `L-13` /
`solo-window` / `1149` records, the `Decision 4` canonicality note, the
stale-`../prd/`-link ban and the relative-link walk — plus the post-fold order
and ratings. `specs/check03.sh` re-asserts the order and the corrections.
Both print `OK`.

**Do not** "fix" `.mi/docs/capabilities-provisioning.md` back to make the
dead guard green. That would restore three entries rating files `8fe3a71`
deleted, undoing a user decision to satisfy a stale assertion — the failure
mode [`odin-toolchain`](../../../decisions/odin-toolchain/prd.md) warned
about and [`tinty`](../../../decisions/tinty/prd.md) closed on.

### Routed to the orchestrator

W0.4i's `files` list is `.mi/docs/capabilities-provisioning.md` alone, so
this node **may not edit** `docs-inventories/prd.md` or its spec files — one
writer per file. The record is therefore written here and **routed**, the way
odin-toolchain's was ("recorded by the orchestrator, after this ticket
closed") and tinty's was ("the orchestrator repointed the guard"). Two edits,
so this is a work item rather than a wish:

1. Mirror this section into `../docs-inventories/prd.md` as its own
   `## Superseded guard`, dated and attributed.
2. Repoint `../docs-inventories/specs/spec03.md`'s verify: `12` → `10`; drop
   `Declarative package set|`, `Homebrew bootstrap|` and `Package installer|`
   from `WANT` and insert `Tool installation|` after `Small tool configs|`;
   drop the `Declarative package set@2 9`, `Package installer@8 9` and
   `Homebrew bootstrap@2 8` pairs from `RL`. **Three edits, no more** — every
   other assertion in that verify still passes against the file this node
   leaves behind, so there is no fourth to go looking for.

## Closing note

*Closed 2026-08-21 by the orchestrator.* All three checks `OK`, exit 0, from
RED baselines of 12 / 32 / 3. R1–R3, R5 `[x]`; **R4 `[~]`** and acceptance 4
`[~]`, correctly — the routed half could not close from this footprint, and it
has now been done: `docs-inventories`' spec03 verify was repointed and a
`## Superseded guard` section written into that ticket.

**The supersession landed exactly as designed.** `docs-inventories`' verify was
confirmed green *before* this pass, and afterwards failed on **precisely the
three superseded assertions and nothing else** — no fourth failure, which was
the stop condition. Every guarded literal survived: `L-12`, `L-13`,
`solo-window`, `1149` (as `1149 vs 1149`), `Decision 4`, `canonical`,
`not a port target`, the burrito/`DO NOT PORT`/`2026-08-20`/`packages.yaml`
set, the `](../prd/` ban and the link walk.

**Two constructions are load-bearing and must not be tidied:** `1149 vs 1149`
carries both the corrected figure and a token a closed gate greps for; and
`not a port target` was re-attached to the rebuild-from-scratch clause, because
Decision 4(a) withdrew the word *abandoned*, not that phrase. A first draft
that reworded the latter turned two checks red immediately — the guard works.

The tinty split is recorded accurately: `8fe3a71` deleted the source-side
management, but the capability is **live and canonical** in the deployed tree,
and the check fails if that entry ever acquires `DO NOT PORT`, `DEFER` or
"dropped" — the inventory may not contradict `decisions/tinty`.
