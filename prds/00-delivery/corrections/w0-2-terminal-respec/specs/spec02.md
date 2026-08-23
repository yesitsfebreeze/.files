verify: `bash -c 'cd "$(git rev-parse --show-toplevel)"; f=prds/02-terminal/01-appearance/prd.md; rc=0; T="$(tr "\n" " " < "$f" | tr -s " ")"; has() { echo "$T" | grep -qF "$1" || { echo "FAIL: missing: $1"; rc=1; }; }; no() { echo "$T" | grep -qiF "$1" && { echo "FAIL: still asserts: $1"; rc=1; }; }; has "CaskaydiaCove Nerd Font"; has "font_dirs"; has "14.0"; has "dofile"; has "require"; has "pcall"; has "add_to_config_reload_watch_list"; has "use_fancy_tab_bar"; has "window_frame"; has "inject_output"; has "window_background_opacity"; has "macos_window_background_blur"; has "inactive_pane_hsb"; has "enable_kitty_keyboard"; has "front_end"; has "F6"; has "background_child_process"; has "C 5"; has "U 9"; no "agave"; no "Flakes"; no "/src/colors"; no "font-sub-pixel-rendering"; no "italic-weight"; no "scroll-margin"; no "status-bar-height"; no "target-os"; no "6dpi"; no "21-inch"; no "## Escalation"; for s in everforest caroline "Gruvbox Material"; do echo "$T" | grep -qiF "$s" && { echo "FAIL: names a live scheme, which is user state: $s"; rc=1; }; done; echo "$T" | grep -qE "#[0-9a-fA-F]{6}" && { echo "FAIL: a hex colour is hardcoded; nothing below WezTerm may carry one"; rc=1; }; [ $rc -eq 0 ] && echo OK; exit $rc'`

est: 1h15m

# spec02 — `01-appearance`: font, palette, baseline, retint, F6

Goal: rewrite the node the audit called one of the "two wrong answers" about
font and palette. Every requirement comes from `capabilities-terminal.md`,
none from the current file, which names a font that is not installed
(`fc-list | grep -ic agave` = 0), a palette source that does not exist
(`/src/colors`), and four config fields the installed WezTerm rejects at
load time.

Files: `.mi/prds/02-terminal/01-appearance/prd.md` — and nothing else.

**Proved RED 2026-08-21 — 23 failures.** Eleven are the wrong assertions the
file still makes (`agave`, `Flakes`, `/src/colors`,
`font-sub-pixel-rendering`, `italic-weight`, `scroll-margin`,
`status-bar-height`, `target-os`, `6dpi`, `21-inch`, and the
`## Escalation` section itself); twelve are requirements that are absent
(`font_dirs`, `use_fancy_tab_bar`, `window_frame`, `inject_output`,
`macos_window_background_blur`, `inactive_pane_hsb`, `enable_kitty_keyboard`,
`front_end`, `F6`, `background_child_process`, and the `C 5` / `U 9` header).

**Four assertions are already green, and the pairing is deliberate.**
`CaskaydiaCove Nerd Font`, `14.0`, `dofile` and `pcall` pass **today** —
but only because the escalation section quotes them while refuting the
requirements above it. They are not evidence the node is right; they are
evidence of the contradiction. Paired with the RED `no "## Escalation"`
guard they become discriminating: after the rewrite the escalation is gone
**and** those facts must still be present, which no copy of the current file
satisfies.

**Rating.** This node merges nine inventory entries, so per AGENTS.md it
carries the dominant entry's numbers and lists every source with its own:
Live tinty theme read WezTerm-side **C 5 / U 9** (dominant) · Font stack
C 2 / U 9 · Appearance baseline C 2 / U 7 · Kitty keyboard protocol off
C 1 / U 7 · Tab title is the digit C 1 / U 7 · Per-pane OSC retint C 6 / U 7 ·
Tab bar chrome C 1 / U 6 · Font zoom does not resize the window C 1 / U 6 ·
OpenGL with capped frame rate C 1 / U 6 · F6 theme toggle C 3 / U 6.

## Boxes

- [x] **B1 — the font stack, with the reason for `font_dirs`.**
      `font_with_fallback{ CaskaydiaCove Nerd Font, CaskaydiaCove NF,
      JetBrainsMono Nerd Font, Cascadia Code, Menlo }`, `font_size` 14.0 on
      macOS / 9.0 elsewhere, `line_height = 1.0`, and `font_dirs` pointed at
      `~/Library/Fonts` (macOS) or `~/.local/share/fonts` **so a freshly
      installed font resolves before the system font cache refreshes** —
      that reason is the requirement, not decoration.
- [x] **B2 — the palette is read, never owned.** `dofile` of
      `~/.config/wezterm/colors.lua`, **not `require`**, because `require`
      caches by module name and a second `tinty apply` in the same GUI
      process would keep returning the first palette. Guarded by `pcall`
      plus an essential-key check so a half-written file from a concurrent
      hook is rejected rather than painted as a half-empty theme. Registered
      with `add_to_config_reload_watch_list` because WezTerm's auto-reload
      only watches files it loaded and `dofile` is invisible to it.
- [x] **B3 — no scheme name and no hex, anywhere.** The requirement is the
      mechanism; the scheme is user state that tinty rewrites. Evidence for
      why this is a box and not a style note: the inventory recorded the live
      scheme as `base16-everforest-dark-hard` on 2026-08-20 and `colors.lua`
      reads `base16-caroline` today. Both were true when written. A PRD that
      named either would be wrong within a day. The single permitted constant
      is the no-theme-picked fallback `config.color_scheme = "Gruvbox dark,
      hard (base16)"`, which is named as a fallback, not as the palette.
- [x] **B4 — the retro tab bar is derived from the same palette.**
      `use_fancy_tab_bar = false` (which is what makes `colors.tab_bar`
      apply), bar background = base00, active tab = base02 + base05 bold,
      inactive = base00 + base03 — **because the retro bar does not inherit
      the scheme** and stayed near-black under a light scheme. `window_frame`
      is set too, since it paints the resize border even with the fancy bar
      off. Also `tab_bar_at_bottom = false`,
      `show_new_tab_button_in_tab_bar = false`, and
      `hide_tab_bar_if_only_one_tab = true` recorded as vestigial while the
      floor holds.
- [x] **B5 — the tab title is the digit and nothing else.**
      `format-tab-title` returns the index + 1, so the tab bar **is** the F5
      keymap legend. This is load-bearing for spec04: it is the whole reason
      the digit half needs no overlay and no status hint.
- [x] **B6 — the per-pane OSC retint, with both reasons.** Broadcast OSC
      4/10/11/12/17/19 into every live pane on `window-config-reloaded`,
      because a pane that already received tinted-shell's per-pane escapes
      holds an override that outranks `config.colors` — the "only this pane
      changed" symptom. Deduped on the payload in `wezterm.GLOBAL` (which
      survives the reload that resets every local) because the event fires
      per window and a theme switch reloads all of them, so without it every
      font-size edit re-blasts every pane. OSC only, so it is safe over a
      full-screen TUI; wrapped in `pcall` because `inject_output` is absent
      on older builds and a pane can die mid-iteration.
- [x] **B7 — the Appearance baseline, including the carve-out fields.**
      `window_decorations = "RESIZE"`, `default_cursor_style =
      "BlinkingBlock"`, `window_background_opacity = 0.95` with the
      translucent tint set to the active scheme's base00 (never pure black,
      which would diverge from the scheme), `macos_window_background_blur =
      30`, `inactive_pane_hsb = { saturation 0.85, brightness 0.7 }`,
      `scrollback_lines = 10000`, `audible_bell = "Disabled"`. Per this
      node's Inbox these are the Appearance baseline (C 2 / U 7, take over
      as-is) and **no decision is owed on them** — `decisions/wallpaper-opacity`
      covers only the pipeline and the OSC toggle.
- [x] **B8 — `window_padding` is zeroed *because* centering owns it.** All
      four sides zero, with a cross-link to
      [`07-grid-centering`](../07-grid-centering/prd.md) naming it as the
      runtime owner. Written as a dependency, not a coincidence: this is
      finding **T-4**, and zeroed padding without the centering node is the
      one combination that leaves the terminal visibly wrong.
- [x] **B9 — the rest of the baseline, each with its reason.**
      `adjust_window_size_when_changing_font_size = false` (a fullscreen
      window cannot grow, so WezTerm instead leaves a large gap and appears
      to resize); `front_end = "OpenGL"`, not WebGpu (transparency plus OS
      backdrop blur have the same backend sensitivity the old layered
      background had), `max_fps` and `animation_fps` at 60 (255 kept the GPU
      churning for no visible benefit); `enable_kitty_keyboard = false` as a
      **matched pair** with nushell's `use_kitty_protocol = false`, because
      with it on reedline fires the support query at startup and the pty
      returns the reply too late to consume, leaking `^[[?...u` over the
      prompt — enabling only the WezTerm half reproduces the leak and buys
      nothing; `status_update_interval = 5000`, the one tick that drives the
      tab reconcile, the centering, and the clock.
- [x] **B10 — the top-right clock, and why nothing shares the corner.**
      `update-right-status` paints `HH:MM` unconditionally and last. Record
      that the OSC 7 cwd label that used to live there is **impossible on
      this build** — `pane:get_current_working_directory()` does not exist,
      and calling it raised on every status tick, which is why the corner sat
      empty. Independently re-checked for this re-spec: the string
      `get_current_working_directory` appears **0 times** in the
      `20240203` binary.
- [x] **B11 — F6 is placed here (R5).** The theme toggle flips the two slots
      `theme.nu` parks in the state dir. Both constraints are requirements:
      bound in **WezTerm** rather than the shell because a full-screen TUI
      would swallow a shell-level binding, and `background_child_process`
      rather than `run_child_process` because `tinty apply` runs the whole
      hook chain and blocking the GUI thread freezes every window for its
      duration. Its `sh -lc` repeats the PATH seeding inline for the reason
      [`06-launchd-path`](../06-launchd-path/prd.md) owns. The shell half is
      [`04-shell/09-theme-switcher`](../../04-shell/09-theme-switcher/prd.md);
      cross-link, do not restate.
- [x] **B12 — the escalation and the textual damage go.** The
      `## Escalation` section is answered by this rewrite and comes out; so
      do the stray `]` closing nothing and the mangled Notes line
      (`capabilities-terminal.md\"appearance"’dictated`). Its "Material W0.2
      should not have to rediscover" list is discharged by B2 and B6.

## Out of scope

- Grid centering itself (spec07) — only the cross-link is written here.
- `theme.nu` and the tv scheme picker, which are `04-shell/09`'s.
