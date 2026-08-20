# Feature: Terminal Appearance

**Parent:** [Terminal epic](00-epic.md) • C4 • U9 • V5

## Summary
Enforce a minimal, job-friendly WezTerm aesthetic with consistent palette inheritance, subtle chrome (status bar height, scroll margin), and anti-aliased text rendering.

## Requirements
1. **Palette Propagation** – New terminals inherit color scheme from `/src/colors`, must pass through without Flakes locks.
2. **UI Skeleton** – Fixed horizontal scroll margin (1.0 lines), status bar height (2.0 lines), no extraneous UI elements.
3. **Text Anti-Aliasing** – Enable sub-pixel rendering via `font-sub-pixel-rendering = "fontconfig_render_subpixel".
4. **Terminal-Specific Overrides** – Explicit `wezterm.target-os = "macos"` sets proper window title handling.

## Acceptance Criteria
- [ ] New windows use system font (`agave`, 18pt) with `italic-weight = "100"`.
- [ ] Color profiles are applied without Flakes Flake dependencies.
- [ ] Scroll margin and status bar occupy exactly 3.0 lines total on 21-inch Mac display.
- [ ] All glyphs render with faint sub-pixel antialiasing visible at 6dpi.
- [ ] Palette entries are preserved identical across console sessions]

## Notes
Color profiles in `capabilities-terminal.md\"appearance"’dictated by system settings, with inverse transparency intentionally omitted for consistency