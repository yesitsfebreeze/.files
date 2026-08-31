---
state: done
priority: 37
est: 0h
task: W0.4
mode: afk
needs:
  - 00-delivery/corrections/w0-3-platform-rewrite
verify: ""
origin: derived
---

# Apply the S2/S3 corrections across the tree

Purpose: The corrections sweep, split one child per epic touched so each
writes only files it owns. Not resolved until all seven children are covered,
so every node depending on the sweep waits for the whole of it.

## Acceptance
- [ ] Every child is covered, and no S2 or S3 item is left unmarked in the
      backlog.
      *(b) — the body's Closing note admits the second clause is unmet:
      "twenty backlog rows stay unmarked because their owners have not
      landed". The children are all covered; the backlog is not fully
      marked.*

## Out of scope
- Any single epic's corrections. The children own those.

## Closing note

*Closed 2026-08-21 by the orchestrator.* **All nine children are `done`** —
`capsule`, `delivery`, `docs-inventories`, `editor`, `help`, `platform`,
`shell`, plus two created during the sweep when gaps surfaced that no lane
owned: `provisioning-rerate` (W0.4i) and `backlog-closeout` (W0.4h). This node
is a pure container; it closes because its children did.

The sweep ran as seven parallel lanes over disjoint file sets, then two
serialised close-outs. What it actually corrected, beyond the S2 items it was
scoped for:

- **A rated epic described deleted machinery.** `02-package-provisioning`
  (C 8 / U 9) specified a `packages.yaml` model that commit `8fe3a71` had
  removed two days before the PRD tree was written. Re-specced against
  `install.sh` and re-rated **C 4 · U 9** on the user's decision, with the
  parent invariant I3 "Tools are data" withdrawn in place.
- **The audit had measured the wrong tree.** `~/.local/share/chezmoi` is a
  stale June clone whose HEAD is a git *ancestor* of the live source. Every
  divergence L-12 and L-13 reported was an artefact of it. Decision 4's
  conclusion survived; its reasoning did not.
- **`8ecbbe4`'s conversion damage** — `Parent:` lines truncated mid-quote,
  losing inventory sources and per-source C/U numbers — was repaired across
  `05-platform`, `03-editor`, `01-capsule` and `14-shift-select`.
- **Two gates were repaired and one was found lying.** `tests/live-bugs.sh` had
  seven assertions that were green *and asserting the opposite of the record*,
  because they read the stale clone.

Four things it deliberately did **not** do, each recorded rather than quietly
closed: twenty backlog rows stay unmarked because their owners have not landed;
`capabilities.md` was edited only within the three typos and seven markers the
author confirmed; the legacy WezTerm block stays partly unmarked because the
author confirmed three named entries, not a block; and `docs-inventories` R7
stays `[~]` because its sweep used the pre-discovery baseline — re-measuring is
filed as backlog row `M-21`.
