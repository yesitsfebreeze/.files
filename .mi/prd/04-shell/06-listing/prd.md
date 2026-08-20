---
state: open
mode: afk
deps:
  - .mi/prd/00-delivery/corrections/w0-4-s2-corrections
  - .mi/prd/04-shell/02-aliases-utilities
  - .mi/prd/06-help/01-content-model
verify: ""
---

# Decorated ls + auto-list

Parent: [Nushell epic](../prd.md) · C 5 · U 8 · source: "Decorated ls +

Purpose: Nushell's structured `ls`, upgraded: icons, useful ordering, opt-in
real directory sizes — and shown automatically after every navigation.

## Requirements
- [ ] **R1** — **Shadowed `ls`.** Builtin captured as `core-ls` before
      shadowing (alias targets bind at parse time). Wrapper redeclares the
      builtin's flags explicitly and defaults the pattern to `.`.
- [ ] **R2** — **Decoration.** Sort `type, modified` (dirs grouped, newest
      last, freshest nearest the prompt); prepend an `icon` column from an
      extension→glyph map with dir/generic fallbacks.
- [ ] **R3** — **`-D` (du).** Opt-in only: swap each dir's inode size for its
      recursive on-disk size via one `du` spawn. Never on by default
      (node_modules would stall every listing).
- [ ] **R4** — **Variants.** `l`, `ll`, `la`.
- [ ] **R5** — **Auto-list hook.** The PWD env_change hook runs `la` after
      every real directory change in an interactive shell — skipping the first
      fire at startup, and skipping when the bare-word fallback is about to
      clear the screen. `stty sane` first, so a crashed full-screen TUI can't
      staircase the table.

## Acceptance
- [ ] `cd` anywhere (including via zoxide/picker) prints the listing once,
      correctly aligned even right after quitting a TUI mid-render.
- [ ] Plain `ls` in a dir with node_modules returns instantly; `ls -D` shows
      real recursive sizes.

## Out of scope
- Anything this node's Requirements do not name. The epic ([`../prd.md`](../prd.md)) owns the shared invariants.
