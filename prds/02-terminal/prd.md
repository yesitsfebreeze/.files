---
state: open
priority: 0
est: 0h
kind: epic
mode: afk
needs:
verify: ""
---

# Epic: Terminal (WezTerm)

Purpose: WezTerm is the daily driver, and its look, startup shape and
navigation speed set the tone for everything else. Every requirement in this
epic is specced from
[`capabilities-terminal.md`](../../docs/capabilities-terminal.md), which was
read live off the deployed config on 2026-08-20 after an audit found the
earlier terminal PRDs had been written from the legacy inventory and were
wrong on font, palette, keys and model. Only the rated keepers are taken over.

Goal: a WezTerm config that comes up fullscreen with nine addressable tabs,
inherits its palette from tinty without hardcoding a colour anywhere, and puts
tab addressing, copy mode and paste one keystroke away.

## Requirements

**Architecture invariants**

These are what make the pieces compose. Every child leans on them by
reference; none of them restates one.

- [ ] **I1** — **The self-healing nine-tab floor owns tabs and panes.**
      There is no second multiplexer. The shell-side one was deleted on
      2026-08-20 and took `DO NOT PORT` in
      [`README.md`](../README.md)'s exclusion list; open decision 1 of the
      [corrections backlog](../00-delivery/corrections/prd.md) records the
      answer where the question was asked. `TAB_COUNT = 9` is a floor, not a
      target, and a digit is a stable address —
      [`02-startup-layout`](02-startup-layout/prd.md) owns the mechanism and
      [`03-f5-jump-mode`](03-f5-jump-mode/prd.md) is what the guarantee is
      for. Children cite I1 rather than re-arguing it.
- [ ] **I2** — **tinty owns the palette; WezTerm is its first reader, not
      its owner.** `tinty apply` writes `~/.config/wezterm/colors.lua`, and
      WezTerm `dofile`s that file — never `require`, which caches by module
      name and would hand back the *first* palette on a second apply. Reading
      it here rather than accepting per-pane escapes is what makes a theme
      switch global: `config.colors` is WezTerm-wide, so every window, tab
      and pane retints at once. Nothing below WezTerm hardcodes a hex value,
      and no PRD in this epic names a scheme — the scheme is user state that
      tinty rewrites. Any earlier wording that put ownership the other way
      round is finding T-3, corrected by open decision 2 on 2026-08-21
      ([`decisions/tinty`](../00-delivery/decisions/tinty/prd.md)).
- [ ] **I3** — **`PaneSelect` is forbidden, and the reason is the
      requirement.** A key bound in `config.keys` or in a key table is
      consumed in the raw-key pass before the modal ever sees it, while an
      unbound key reaches the modal, which answers only to a complete label,
      `Escape` and `ctrl+g` and silently eats everything else. Nothing in Lua
      closes it: `cancel_modal` is reachable from no `KeyAssignment`, and
      `PaneSelector::perform_assignment` returns false unconditionally
      (checked in this build's source and in main). This invariant outlives
      the pane-letter overlay that discovered it — it is what stops a later
      lane "simplifying" one-key navigation back onto the modal.
- [ ] **I4** — **The deployed `~/.config/wezterm/` is the artifact every
      child is written against.** Decided 2026-08-21, open decision 4:
      `chezmoi source-path` prints `/Users/feb/dev/.files/home`, and
      `~/.local/share/chezmoi` is a stale June clone whose HEAD is a git
      *ancestor* of that source. No terminal PRD may cite the stale clone as
      the chezmoi source; the only permitted mention of it is as the clone
      that produced wrong findings, labelled as such. Reading a clone instead
      of the live tree is the failure class that invalidated this epic the
      first time.

## Acceptance
- [ ] Every child's header cites an entry of
      [`capabilities-terminal.md`](../../docs/capabilities-terminal.md) by
      name, or `net-new`, with `C`/`U` numbers matching that entry.
- [ ] No child names a WezTerm config field that the installed build
      (`20240203-110809-5046fc22`) rejects at config-load time — the check is
      a minimal probe config through
      `wezterm --config-file <probe> ls-fonts --list-system`.
- [ ] The child count agrees in three places: the directories under this
      epic, the tree in [`README.md`](../README.md), and README's build
      order.
- [ ] No file under this epic hardcodes a palette hex or names a colour
      scheme, the single exception being the no-theme-picked fallback
      recorded in [`01-appearance`](01-appearance/prd.md).

## Out of scope

Non-goals, each with the reason it is refused and the rating it was refused
at. The canonical list is [`README.md`](../README.md)'s exclusion section;
this is the terminal-local view of it.

- **The `Ctrl+Shift+B` wallpaper pipeline** (`DO NOT PORT`, C 8 / U 3) — a
  terminal keybinding that reaches out and rewrites the OS desktop wallpaper
  *and* a chezmoi source tree, depends on ImageMagick, and is cosmetic. The
  key itself is freed and goes to `capsule --rebuild`.
- **`background.png`** (C 2 / U 0) — a 2.8 MB output artifact sitting in a
  config directory that nothing in `wezterm.lua` reads. Drops out with the
  pipeline above.
- **The OSC-1337 background-transparency user-var** — the live rebuild of the
  legacy opacity toggle. Both are refused by
  [`decisions/wallpaper-opacity`](../00-delivery/decisions/wallpaper-opacity/prd.md)
  (2026-08-21).
- **The dead `config.lua`** (`DO NOT PORT`, C 1 / U 1) — 23 lines next to
  `wezterm.lua`, never loaded, not valid Lua, and unmanaged by chezmoi. Its
  whole danger is as a decoy: it asserts a font and a colorscheme a reader
  would plausibly believe. Delete rather than port.
- **`wsl-clip-prime.sh`** (`DO NOT PORT`, C 4 / U 0) — orphaned binding,
  WSL-only, against a macOS-host-only scope decision.
- **The four `solo-window.*` scripts** (`DO NOT PORT`, C 5 / U 0) — deployed
  dead code; the `ctrl+shift+m` binding each of them names does not exist.
- Legacy surfaces already refused before this re-spec: the three-pane split
  layout, the quake-style dropdown pane, the container-aware status bar, and
  **background image cycling** with its opacity toggle. Finding **T-11** is
  why the last of those is spelled out here: this line once refused only the
  *legacy* implementations while the live config had rebuilt both ideas in new
  form, and an unrefused rebuild is how an excluded capability walks back in.

The carve-out that keeps being mistaken for one of the above: **none of this
touches the static `window_background_opacity`, its base00 tint, or
`macos_window_background_blur`.** Those are the *Appearance baseline* entry
(C 2 / U 7, take over as-is) and belong to
[`01-appearance`](01-appearance/prd.md). The wallpaper decision covers the
pipeline and the user-var toggle only, and owes this epic no further answer.

## Note on children

The `## Children` table this epic used to carry is gone on purpose. Node
membership is by existence — a child is a subdirectory holding its own
`prd.md` — so a maintained list beside it is a second copy that goes stale
silently (laws.md law 4: "membership by existence, not by a maintained
list"). `find . -name prd.md` is the index.
