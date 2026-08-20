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

## Escalation

Raised by session `cc-1787264229` on 2026-08-21. Nothing was written, no
branch was cut. This node cannot be worked as written: its Requirements and
Acceptance do not describe WezTerm, and the schedule already records that they
do not.

### What I hit

**1. Four of the five config fields this node names are rejected by the
installed WezTerm** (`20240203-110809-5046fc22`) at config-load time. Minimal
probe configs run through `wezterm --config-file <probe> ls-fonts
--list-system`, which forces WezTerm to validate the config table:

- R3 `font-sub-pixel-rendering` → "`font-sub-pixel-rendering` is not a valid
  Config field. Did you mean one of `font`, `font_size`, `font_shaper`?"
- Acceptance `italic-weight` → "not a valid Config field."
- R2 `scroll-margin` → "not a valid Config field. Did you mean one of
  `scrollback_lines`, `scroll_to_bottom_on_input`?"
- R2 `status-bar-height` → "not a valid Config field. Did you mean
  `status_update_interval`?"

R4's `wezterm.target-os = "macos"` is likewise not a WezTerm surface; the live
config detects the platform with `wezterm.target_triple` and
`triple:find("darwin")` (`~/.config/wezterm/wezterm.lua:10-11`). These are not
spelling slips a lane may silently correct — WezTerm has no scroll-margin or
status-bar-height concept at all, and its antialiasing knob is
`freetype_render_target`, not a fontconfig subpixel string. Implementing
R2/R3 requires inventing a design this node does not state, which is a
re-spec, not an implementation.

**2. R1 names a palette source that does not exist.** `ls /src` → "No such
file or directory". There is no Nix, flake, or lockfile anywhere in the repo;
a grep over `.mi/` and `home/` returns hits only in documents that cite this
PRD as the error. The real palette path is `~/.config/wezterm/colors.lua`,
tinty-generated, read via `dofile` under `pcall` with
`add_to_config_reload_watch_list` (`wezterm.lua:417-433`). R1 both names a
nonexistent source and omits the one constraint that makes palette reloading
work.

**3. The font named in Acceptance is not installed.** `fc-list | grep -ic
agave` = 0; `fc-list | grep -ic caskaydia` = 36. Live is `CaskaydiaCove Nerd
Font` at 14.0 on macOS / 9.0 elsewhere (`wezterm.lua:510-520`).
[`capabilities-terminal.md:22-27`](../../../docs/capabilities-terminal.md)
calls this out by name: "Three answers to 'what font and palette?', two of
them wrong… Do not trust a font or hex from any other file." This node is one
of the two wrong answers.

**4. Two acceptance lines are not checkable propositions.** "All glyphs render
with faint sub-pixel antialiasing visible at 6dpi" names no observable
procedure (6dpi is not a real display density), and "exactly 3.0 lines total
on 21-inch Mac display" conditions on unspecified geometry with no measurement
procedure.

**5. The node was dispatched unready.** All four `deps` are `state: open`, and
two of them are `hitl`. Under worker.md §2 a dep is resolved only when
`out-of-scope`, or `done` owing nothing. The two `hitl` decisions govern
exactly this node's subject: `decisions/tinty` decides whether tinty owns the
palette at all (if it is dropped, R1's whole inheritance mechanism has no
cause — `capabilities-terminal.md:351`), and `decisions/wallpaper-opacity`
decides `window_background_opacity` and the base00 tint
(`capabilities-terminal.md:220-229`).

**6. Most decisive — the schedule already says this text is not the spec.**
`.mi/gantt/plan.json:663`, the note on this very task, reads: "Current file
content (font 'agave', Flakes) is pre-re-spec and known wrong (T-1); real
requirements come from W0.2's rewrite, not this file as it stands today."
`CLAUDE.md` §Known gaps says the same. The record and this node disagree, and
this node is the stale copy.

### What change is needed

Hold this node closed until
[`00-delivery/corrections/w0-2-terminal-respec`](../../00-delivery/corrections/w0-2-terminal-respec/prd.md)
has rewritten it from `.mi/docs/capabilities-terminal.md`, and until
`decisions/tinty` and `decisions/wallpaper-opacity` are settled by the human.
Then re-dispatch. Reconciling the schedule note against this node's text is
itself worth a box on W0.2.

### Why no workaround was taken

A WezTerm config correct against the live source and the inventory was
available to write. That is the forbidden move: this repo has no
design-record layer, so this node's Requirements **are** its spec, and writing
a different, better config forks the spec rather than meeting it. It would
also pre-empt two decisions reserved for the human, and land palette code that
the W0.2 re-spec would then have to unpick.

### Corrections recorded for the re-spec

- **Textual damage, not merely mis-specification.** The Acceptance list ends
  with a stray `]` closing nothing, and the Notes line reads
  `capabilities-terminal.md\"appearance"’dictated` — mixed smart quotes, an
  escaped quote, a missing space. Left in place rather than edited, because
  the box text is evidence for "rewrite from the inventory" over "adjust in
  place".
- **Address correction (belongs to a shared file, not this node).** The
  schedule gives this task ownership of `home/.config/wezterm/wezterm.lua`.
  That path could not exist: this repo is chezmoi-sourced and uses the `dot_`
  prefix — the only content under `home/` today is
  `home/dot_config/nushell/help/*`. The correct address is
  `home/dot_config/wezterm/wezterm.lua`. `.mi/gantt/plan.json` is owned by no
  lane, so this is flagged for the conductor to fix before re-dispatch.
- **Scheduler readiness.** worker.md §2 warns that `plugin.lua` predates
  `deps` and "will hand out nodes with unresolved `deps`". This dispatch is
  consistent with that gap; worth checking whether the frontier computation
  applies the `deps` term, since other lanes in the same run may hold equally
  unready nodes.

### Material W0.2 should not have to rediscover

The inventory already carries what the rewrite needs: Appearance baseline
(`capabilities-terminal.md:220-231`), Font stack (`:140-146`), live tinty
theme read WezTerm-side (`:259-275`), `retint_all_panes` (`:340-351`). Two
constraints there are load-bearing and should survive into the rewritten
requirements **with their reason**:

- The palette is read with `dofile`, **not** `require`, because `require`
  caches by module name and would return the *first* palette on a second
  `tinty apply` (`wezterm.lua:432-433`).
- The OSC re-tint broadcast is guarded by `wezterm.GLOBAL.tinty_osc` so that
  every font-size edit and padding override does not re-blast every live pane
  (`wezterm.lua:583-589`).
