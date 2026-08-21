---
state: open
mode: afk
deps:
  - .mi/prd/05-platform/01-deploy-mechanism/repo-skeleton
verify: ""
---

# Managed config surface + dot_gitconfig.tmpl

Parent: [`01-deploy-mechanism`](../prd.md) · source:
[`01-deploy-mechanism`](../prd.md) requirements R2

## Requirements
- [ ] **R2** — **Managed config surface.** One source of truth per tool under
      `home/dot_config/`: nushell, nvim, wezterm, television, burrito,
      `starship.toml`, bat, gh, lazygit, tinted-theming. Templated only where
      it must differ per machine (`dot_gitconfig.tmpl`).

## Acceptance
- [ ] Every requirement box above is `[x]` against the real thing.

## Out of scope
- The sibling node's requirements. This document held two contracts and was split;
  the parent lists which requirement went where.

## Notes

 Footprint narrowed from home/dot_config/ to the file it actually owns
      (05-platform/01 req 1 puts dot_gitconfig.tmpl at the home/ root). The
      managed-surface declaration lists directories owned by other tracks; it
      does not write them.
