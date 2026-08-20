---
state: open
mode: afk
deps:
  - .mi/prd/00-delivery/corrections/w0-4-s2-corrections
  - .mi/prd/00-delivery/corrections/w0-6-live-bugs
verify: ""
---

# Re-base 01-capsule on build-once and free the colliding bindings

Purpose: The capsule epic rests on legacy code that never worked and claims
keybindings that are already taken. Re-base it before anything is built.

## Requirements
- [ ] **R1** — Re-base the epic on "build once": one image definition, built
      once, reused. C-2 records that no live capsule implementation exists to
      consolidate from, so this is design, not porting.
- [ ] **R2** — Resolve the `Ctrl+Shift+B` / `Ctrl+Shift+T` collisions (C-1).
      `Ctrl+Shift+B` is contested with the live wallpaper feature; the answer
      comes from the wallpaper-opacity decision.
- [ ] **R3** — Do not preserve legacy `mount` behaviour. C-3: it cd'd to a
      nonexistent `~/docker`, passed wrong `just` recipe arguments, and
      mounted `./workspace` rather than `$PWD`. Design the lifecycle semantics
      fresh.
- [ ] **R4** — Correct C-4: `devzsh` has no zsh baked in (`CMD ["bash"]`), so
      zsh, oh-my-zsh and Claude Code come only from the new image.
- [ ] **R5** — Give the capsule terminal keybinding an owner. `01-capsule/01`
      req 4 requires `capsule --rebuild` bound in the terminal and the epic
      success criterion requires one keybinding; no task binds it.

## Acceptance
- [ ] No capsule PRD describes behaviour of the legacy `mount` script.
- [ ] Every binding the epic claims is free, or its conflict is recorded with
      the resolution.
- [ ] C-1 through C-5 are each fixed or recorded as accepted with a reason.

## Out of scope
- Building the image or the CLI. C.1 and C.2 do that.
