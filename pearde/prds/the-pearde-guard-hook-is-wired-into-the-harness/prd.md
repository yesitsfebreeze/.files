---
state: blocked
origin: requested
priority: 0
complexity: 7
blast-radius:
needs: 09-simplify/08-litellm-out
---

# the pearde guard hook is wired into the harness

<The request, for an analyst who knows the codebase but not this conversation:
what exists at the end and why, what must not change, pointers to files and
prior PRDs. One contract per PRD — a second is a second PRD, or a split via
refine.>

Purpose: `pearde doctor` (2026-09-04): `guard off — not wired in
.claude/settings.json`. Without the hook, a session can stage a path
another node holds under a live claim; `just board-guard` catches it only
when someone runs it. The 2026-09-02 baseline commit that swept a held node
(`00-delivery/corrections/baseline-commit-absorbs-live-claims`) is what
the hook exists to prevent.

## Requirements

- [ ] **R1** — `pearde guard on` writes the block of
      `@references/parts/guard.md` into `.claude/settings.json`; the file
      is committed.
- [ ] **R2** — The manual's agents guide says the guard is on and what it
      refuses, in one sentence.

## Acceptance

- [ ] `pearde doctor` shows `guard ok`.
- [ ] Staging a path held by a `claimed` node in a fresh session is
      refused by the hook, not only by `just board-guard`.
