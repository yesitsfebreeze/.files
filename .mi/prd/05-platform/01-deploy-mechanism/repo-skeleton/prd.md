---
state: open
mode: afk
deps:
  - .mi/prd/00-delivery/corrections/w0-3-platform-rewrite
verify: "chezmoi apply on a scratch target is idempotent (second apply is a no-op); just push round-trips a local edit"
---

# Repo skeleton: chezmoi source layout, home/, justfile

Parent: [`01-deploy-mechanism`](../prd.md) · source:
[`01-deploy-mechanism`](../prd.md) requirements R1, R3, R5

## Requirements
- [ ] **R1** — **Source layout.** `home/` holds the managed tree
      (`dot_config/`, `dot_gitconfig.tmpl`, `run_*` scripts, `.chezmoidata/`),
      with the repo root carrying the `justfile` and docs.
- [ ] **R3** — **Apply.** `chezmoi apply` is the single deploy step and must
      be idempotent — a second apply changes nothing.
- [ ] **R5** — **Push recipe.** One `just push`: init from this source, apply,
      commit, push, then update. Mirrors the live workflow so muscle memory
      carries over.

## Acceptance
- [ ] chezmoi apply on a scratch target is idempotent (second apply is a
      no-op); just push round-trips a local edit

## Out of scope
- The sibling node's requirements. This document held two contracts and was split;
  the parent lists which requirement went where.

## Notes

 Footprint narrowed: P.1 creates the skeleton and the chezmoi root, not the
      managed files inside it. Each per-app config dir is owned by its own
      track (nushell/ by S.x, nvim/ by E.x, wezterm/ by T.x, help/ by H.x) — a
      wholesale home/ claim made every nested write invisible to the
      string-equality collision check.
