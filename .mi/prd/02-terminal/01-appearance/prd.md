---
state: open
mode: afk
deps:
  - .mi/prd/00-delivery/corrections/w0-2-terminal-respec
  - .mi/prd/00-delivery/decisions/tinty
  - .mi/prd/00-delivery/decisions/wallpaper-opacity
  - .mi/prd/06-help/01-content-model
verify: ""
---

# Terminal Appearance

**Parent:** [Terminal epic](../prd.md) • C4 • U9 • V5

Purpose: Enforce a minimal, job-friendly WezTerm aesthetic with consistent
palette inheritance, subtle chrome (status bar height, scroll margin), and
anti-aliased text rendering.

## Requirements
- [ ] **R1** — **Palette Propagation** – New terminals inherit color scheme
      from `/src/colors`, must pass through without Flakes locks.
- [ ] **R2** — **UI Skeleton** – Fixed horizontal scroll margin (1.0 lines),
      status bar height (2.0 lines), no extraneous UI elements.
- [ ] **R3** — **Text Anti-Aliasing** – Enable sub-pixel rendering via
      `font-sub-pixel-rendering = "fontconfig_render_subpixel".
- [ ] **R4** — **Terminal-Specific Overrides** – Explicit `wezterm.target-os =
      "macos"` sets proper window title handling.

## Acceptance
- [ ] New windows use system font (`agave`, 18pt) with `italic-weight =
      "100"`.
- [ ] Color profiles are applied without Flakes Flake dependencies.
- [ ] Scroll margin and status bar occupy exactly 3.0 lines total on 21-inch
      Mac display.
- [ ] All glyphs render with faint sub-pixel antialiasing visible at 6dpi.
- [ ] Palette entries are preserved identical across console sessions]

## Out of scope
- Anything this node's Requirements do not name. The epic ([`../prd.md`](../prd.md)) owns the shared invariants.

## Notes
Color profiles in `capabilities-terminal.md\"appearance"’dictated by system settings, with inverse transparency intentionally omitted for consistency
