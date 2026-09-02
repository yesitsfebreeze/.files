---
state: done
claim:
priority: 26
est: 2.5h
task: T.1
mode: afk
needs:
  - 00-delivery/corrections/w0-2-terminal-respec
  - 00-delivery/decisions/tinty
  - 00-delivery/decisions/wallpaper-opacity
  - 06-help/01-content-model
verify: ""
---

# Terminal appearance — font, palette, baseline

Parent: [Terminal epic](../prd.md) · C 5 · U 9 · source: Live tinty theme,
read WezTerm-side

This node merges nine inventory entries, so per `AGENTS.md` it carries the
dominant entry's numbers and lists every source with its own: *Live tinty
theme, read WezTerm-side* **C 5 / U 9** (dominant) · *Font stack* C 2 / U 9 ·
*Appearance baseline* C 2 / U 7 · *Kitty keyboard protocol off* C 1 / U 7 ·
*Tab title is the digit and nothing else* C 1 / U 7 · *Per-pane OSC retint*
C 6 / U 7 · *Tab bar chrome* C 1 / U 6 · *Font zoom does not resize the
window* C 1 / U 6 · *OpenGL front end with capped frame rate* C 1 / U 6 ·
*F6 theme toggle* C 3 / U 6. All ten are in
[`capabilities-terminal.md`(../../../../docs/capabilities-terminal.md).

Purpose: give WezTerm the look it actually has — a Nerd Font that is
installed, a palette read from the file tinty writes, a retro tab bar derived
from that same palette, and a baseline of window, cursor and render settings
that the rest of the epic can assume. This node was rewritten from the
inventory on 2026-08-21; the text it replaced named a font that is not
installed, a palette source that does not exist, and four config fields the
installed WezTerm rejects at load time.

## Status after the tmux cutover

**AMENDED 2026-08-30 by [`07-multiplexer/08-wezterm-reduction`](../../07-multiplexer/08-wezterm-reduction/prd.md).**
What survives here is the local chrome and is untouched: the font stack,
`window_decorations = "RESIZE"`, opacity and blur, `inactive_pane_hsb`,
`scrollback_lines`, `enable_kitty_keyboard = false` and the zeroed
`window_padding`. What left this node, with the mechanism it named:

- **R2/R3, the palette reader** — the `colors.lua` `dofile`, the reload
  watch and the derived `colors.tab_bar` are deleted. The palette arrives
  as OSC now; see the epic's amended **I2**.
- **R4, the tab bar** — replaced by one line, `enable_tab_bar = false`.
- **R5, the digit tab title** — tmux's `window-status-format` draws it
  ([`07-multiplexer/03-status-bar`](../../07-multiplexer/03-status-bar/prd.md)).
- **R6, the per-pane OSC retint** — tinty writes the client tty directly.
- **R10, the clock** — tmux's `status-left`, beside the cwd. It was
  `status-right` until 2026-09-01, when the window digits took that edge.
- **R11, the F6 toggle** — `bind -n F6` in `tmux.conf`, PATH prefix and
  measured reason carried across whole.

`tests/wezterm-appearance.sh` was not deleted with them: every one of
those checks is INVERTED there and still runs, because a gate that simply
stopped looking would pass just as well against a file where the old code
came back.

## Requirements

- [x] **R1** — **Font stack, with the reason for the font directory**
      (finding **T-1**: the font is not the in-repo one the legacy inventory
      named).
      `font_with_fallback{ "CaskaydiaCove Nerd Font", "CaskaydiaCove NF",
      "JetBrainsMono Nerd Font", "Cascadia Code", "Menlo" }`, `font_size`
      14.0 on macOS and 9.0 elsewhere, `line_height = 1.0`. `font_dirs`
      points at `~/Library/Fonts` on macOS or `~/.local/share/fonts`
      otherwise, **so a freshly installed font resolves before the system
      font cache refreshes** — that reason is part of the requirement, not
      decoration. Platform is detected with `wezterm.target_triple` and
      `triple:find("darwin")`, which is the only platform surface WezTerm
      offers.
- [x] **R2** — **The palette is read, never owned** (finding **T-2**: the
      palette is not a fixed colorscheme, and there is no cursor-colour
      override — the style is `BlinkingBlock`, per R7). `dofile` of
      `~/.config/wezterm/colors.lua` — **not `require`**, which caches by
      module name, so a second `tinty apply` in the same GUI process would
      keep returning the first palette. The read is guarded by `pcall` plus
      an essential-key check, so a half-written file from a concurrent hook
      is rejected rather than painted as a half-empty theme. The path is
      registered with `add_to_config_reload_watch_list`, because WezTerm's
      auto-reload only watches files it loaded and a `dofile` is invisible to
      it. See the epic's I2 for who owns the palette.
- [x] **R3** — **No scheme name and no colour constant, anywhere.** The
      requirement is the mechanism; the active scheme is user state that
      tinty rewrites. The evidence that this is a requirement and not a style
      note: the inventory recorded one scheme as live on 2026-08-20 and
      `colors.lua` names a different one today. Both were true when written,
      and a PRD naming either would have been wrong within a day. The single
      permitted constant is the no-theme-picked fallback
      `config.color_scheme = "Gruvbox dark, hard (base16)"`, which is named
      as a fallback for a checkout that has never applied a theme — never as
      the palette.
- [x] **R4** — **The retro tab bar is derived from the same palette.**
      `use_fancy_tab_bar = false`, which is what makes `colors.tab_bar`
      apply at all; bar background = base00, active tab = base02 with base05
      bold, inactive tab = base00 with base03. Derived rather than fixed
      **because the retro bar does not inherit the scheme** and stayed
      near-black under a light one. `window_frame` is set from the same
      palette too, since it paints the resize border even with the fancy bar
      off. Also `tab_bar_at_bottom = false`,
      `show_new_tab_button_in_tab_bar = false`, and
      `hide_tab_bar_if_only_one_tab = true` — the last recorded as vestigial
      while the nine-tab floor holds, kept for a window opened by other
      means.
- [x] **R5** — **The tab title is the digit and nothing else.**
      `format-tab-title` returns `"  %d  "` for `tab.tab_index + 1`, so the
      tab bar **is** the F5 keymap legend. Nine process titles would not fit
      legibly and the opposite corner is reserved for the clock. This is
      load-bearing for [`03-f5-jump-mode`](../03-f5-jump-mode/prd.md): it is
      the whole reason the digit half needs neither an overlay nor a status
      legend.
- [x] **R6** — **The per-pane OSC retint, with both of its reasons.** On
      `window-config-reloaded`, build an OSC 4/10/11/12/17/19 payload from
      the palette and `inject_output` it into every live pane. Needed
      **because a pane that already received tinted-shell's per-pane escapes
      holds an override that outranks `config.colors`**, so a config reload
      alone leaves it on the old scheme — the "only this pane changed"
      symptom. Deduped on the payload in `wezterm.GLOBAL` (which survives the
      reload that resets every local) **because the event fires once per
      window and a theme switch reloads all of them**, so without the dedupe
      every font-size edit re-blasts every pane. OSC only — nothing is
      printed and the cursor never moves — so it is safe over a full-screen
      TUI; wrapped in `pcall` because `inject_output` is absent on older
      builds and a pane can die mid-iteration.
- [x] **R7** — **The appearance baseline.** `window_decorations = "RESIZE"`,
      `default_cursor_style = "BlinkingBlock"`,
      `window_background_opacity = 0.95` with the translucent tint set to the
      active scheme's base00 (never pure black, which would diverge from the
      scheme), `macos_window_background_blur = 30` so the OS frosts the
      desktop behind the window, `inactive_pane_hsb = { saturation 0.85,
      brightness 0.7 }`, `scrollback_lines = 10000`, and
      `audible_bell = "Disabled"`. There is no WezTerm image layer any more:
      the blur is the OS compositing the desktop through the translucent cell
      colour. These fields are the *Appearance baseline* entry (C 2 / U 7,
      take over as-is) and **no decision is owed on them** — the wallpaper
      decision covers the `Ctrl+Shift+B` pipeline and the transparency
      user-var toggle only, both of which are the epic's non-goals.
- [x] **R8** — **`window_padding` is zeroed *because* centering owns it at
      runtime.** All four sides zero, with
      [`07-grid-centering`](../07-grid-centering/prd.md) named as the runtime
      owner. This is a dependency, not a coincidence: it is finding **T-4**,
      and zeroed padding *without* that node is the one combination that
      leaves the terminal visibly wrong, since the sub-cell remainder then
      sits as an uneven gap on the right and bottom.
- [x] **R9** — **The rest of the baseline, each with its reason.**
      `adjust_window_size_when_changing_font_size = false`, because WezTerm
      otherwise resizes the OS window to land on a whole number of cells and
      a fullscreen window cannot grow, so it leaves a large gap and appears
      to change size. `front_end = "OpenGL"` rather than WebGpu, because
      transparency plus OS backdrop blur have the same backend sensitivity
      the old layered background had. `max_fps = 60` and `animation_fps = 60`
      — uncapping to 255 let WezTerm present every redraw at up to 255 Hz,
      which with the status repaint and cursor blink kept the GPU churning
      for no visible benefit. `enable_kitty_keyboard = false` as a **matched
      pair** with nushell's `use_kitty_protocol = false`
      ([`04-shell/01-core-config`](../../04-shell/01-core-config/prd.md)):
      with it on, reedline fires the support query at startup and the pty
      returns the reply too late to consume, leaking `^[[?...u` over the
      prompt — enabling only the WezTerm half reproduces the leak and buys
      nothing. `status_update_interval = 5000`, the one tick that drives the
      tab reconcile, the grid centering and the clock.
- [x] **R10** — **The top-right clock, and why nothing shares the corner.**
      `update-right-status` paints `  HH:MM  ` in `AnsiColor = "Silver"`,
      unconditionally and last, so nothing can displace it; the tab bar is at
      the top, so the right status *is* the top-right corner. HH:MM only,
      because the 5 s tick is what repaints it. Record that the OSC 7 cwd
      label that used to live here is **impossible on this build**:
      `pane:get_current_working_directory()` does not exist, and calling it
      raised on every status tick, which is why the corner sat empty.
      Independently re-checked for this re-spec — the string
      `get_current_working_directory` appears **0 times** in the `20240203`
      binary.
- [x] **R11** — **F6 toggles the theme, bound here.** It flips between the
      two theme slots `theme.nu` parks in the state dir. Both constraints are
      requirements: bound in **WezTerm** rather than in the shell, because a
      full-screen TUI would swallow a shell-level binding; and
      `background_child_process` rather than `run_child_process`, because
      `tinty apply` runs the whole hook chain and blocking the GUI thread
      freezes every window for its duration — nothing needs the exit status,
      since the visible effect arrives when tinty rewrites `colors.lua` and
      the reload watch fires. Its `sh -lc` repeats the PATH seeding inline
      for the reason [`06-launchd-path`](../06-launchd-path/prd.md) owns. The
      shell half is
      [`04-shell/09-theme-switcher`](../../04-shell/09-theme-switcher/prd.md);
      cross-link it, do not restate it.

## Acceptance
- [x] `fc-list` resolves the first family named in R1, and a probe config
      through `wezterm --config-file <probe> ls-fonts --list-system` loads
      without a "not a valid Config field" error for any field this node
      names. *(2026-08-22: `tests/wezterm-appearance.sh --probe` — fc-list
      36 hits for CaskaydiaCove Nerd Font; ls-fonts rc=0 with clean stderr
      in all three colors.lua states against wezterm 20240203-110809.)*
- [x] **(a) proven 2026-08-30, on the mechanism that replaced this one.**
      Applying a different theme with `tinty apply` recolours every open
      window and pane — including one that was already open before the
      switch — with no restart and no edit to any file in this epic.

      It is no longer a live-GUI-only claim, and that is the whole gain of
      the move. `bash tests/tmux-palette-delivery.sh --osc` reads the wire of
      a real attached client and asserts OSC 11 carries base00, OSC 10 and 12
      base05, and **all sixteen** ANSI slots are pushed — to every attached
      tty, not to the one the hook ran in. The old path could only be checked
      by a person looking at a screen because it depended on WezTerm's reload
      watch; this one is bytes on a wire.
- [~] Truncating `colors.lua` mid-write leaves the previous palette in place
      rather than painting a half-empty theme, and WezTerm keeps running.
      *(2026-08-22: static half proven — `--probe` state 3 loads a head-3
      truncation clean, the pcall + essential-key guard rejects it. The live
      reload-watch half is the "half-written palette" row in
      `gates/manual/wave2.md`.)*
- [x] `grep -E '#[0-9a-fA-F]{6}' home/dot_config/wezterm/wezterm.lua` returns
      nothing: no palette constant is hardcoded. *(2026-08-22: ran it — 0
      hits; also `tests/wezterm-appearance.sh --static`.)*
- [ ] **(c) obsolete — there is no tab bar.** `enable_tab_bar = false`
      since 2026-08-30; tmux draws the window digits and the clock, and
      `bash tests/tmux-status-bar.sh` proves both. Left unticked on purpose:
      ticking a box about a bar that does not exist would be a false record,
      and deleting it would erase what this node once promised. What it
      said: "The tab bar shows nine tabs titled `1`–`9`, and the top-right corner
      shows the clock and nothing else."
- [ ] **(c) obsolete here, and alive one layer down.** F6 is
      `bind -n F6 run-shell -b` in `tmux.conf`, and `-b` is the no-freeze
      property in its new form — `bash tests/tmux-key-tables.sh --keys`
      proves the key reaches the toggle (`F6 runs the theme toggle all the
      way into nu`). Whether a human perceives a freeze is a human check and
      is T.6 in `gates/manual/wave4.md`. What it said: "Pressing F6 switches
      the theme without the GUI freezing for the duration of the hook chain."

## Out of scope
- Grid centering itself, which is
  [`07-grid-centering`](../07-grid-centering/prd.md). Only the cross-link and
  the zeroed padding are written here.
- `theme.nu`, its A/B slots and the tv scheme picker, which are
  [`04-shell/09-theme-switcher`](../../04-shell/09-theme-switcher/prd.md)'s.
- The `Ctrl+Shift+B` wallpaper pipeline and the transparency user-var, both
  refused in the epic's non-goals.
- Anything this node's Requirements do not name. The epic
  ([`../prd.md`](../prd.md)) owns the shared invariants.
