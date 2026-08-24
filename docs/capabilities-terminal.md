# Capabilities of the WezTerm config

Companion to [`capabilities.md`](capabilities.md),
[`capabilities-nushell.md`](capabilities-nushell.md),
[`capabilities-nvim.md`](capabilities-nvim.md) and
[`capabilities-provisioning.md`](capabilities-provisioning.md); same rules.
Ratings are 1–10 (complexity / usefulness), sorted best-first by value ratio
(usefulness minus complexity). Markers: nothing = take over, `SIMPLIFY` =
reduced version, `CONSOLIDATE` = merge, `DEFER` = not in the minimal base,
`DO NOT PORT` = drop.

**Source of truth for this inventory.** Read live on 2026-08-20 from
`~/.config/wezterm/`: `wezterm.lua` (1149 lines, the whole config),
`colors.lua` (18 lines, tinty-generated), `config.lua` (23 lines, dead — see
its entry), plus five orphaned scripts and one image. Cross-checked against
the running GUI with `wezterm --version` (`20240203-110809-5046fc22`),
`wezterm show-keys --lua` (the effective key set, 263 lines) and
`wezterm cli list`. Written because the `02-terminal` epic was specced from
[`capabilities.md`](capabilities.md) and audit finding T-10 showed it wrong in
almost every requirement; nothing here is carried over from those PRDs.

**Three answers to "what font and palette?", two of them wrong.** The
`02-terminal` PRD says `agave` and "Flakes". The dead `config.lua` says
`Departure Mono Nerd Font Mono` and `Gruvbox Material`. Neither is live. The
live answer is `CaskaydiaCove Nerd Font` at 14.0pt and the tinty scheme
`base16-everforest-dark-hard`, with builtin `Gruvbox dark, hard (base16)` as
the no-theme-picked fallback. Do not trust a font or hex from any other file.

**Drift found while reading.** Not capabilities and carrying no rating —
findings that belong in
[`corrections`](../prds/00-delivery/corrections/prd.md) if they are not there
already, recorded here because this is where they surfaced.

- **`colors.lua` is still tracked in the chezmoi source.** The generator's own
  header says "The generated file is NOT tracked by git; instead this script
  records the picked scheme in `.chezmoidata/theme.toml`", but
  `home/dot_config/wezterm/colors.lua` exists in the source tree and holds a
  stale `base16-framer` palette while the live file is
  `base16-everforest-dark-hard`. A `chezmoi apply` would overwrite the live
  palette with the stale one until the hook regenerates it. `wezterm.lua`'s
  own comment ("colors.lua is generated, not committed") repeats the same
  false claim.
- **Five deployed-but-dead files** in `home/dot_config/wezterm/`: the four
  `solo-window.*` scripts, whose `ctrl+shift+m` binding no longer exists.
- **Two unmanaged local files** in `~/.config/wezterm/` that chezmoi does not
  know about: `config.lua` (invalid, unloaded, and actively misleading about
  font and palette) and `wsl-clip-prime.sh` (orphaned binding, WSL-only).
- **burrito's residue is still on disk and still in the chezmoi source.**
  `~/.cargo/bin/burrito` (a binary), `~/.config/burrito/burrito.toml`, and
  `home/dot_config/burrito/burrito.toml` in the chezmoi source all exist.
  Nothing launches it: `config.nu` mentions burrito only in comments, and the
  live WezTerm holds nine tabs of its own. Out of scope for this inventory per
  the node, but it is the evidence D.1 needs for "does burrito or WezTerm own
  tabs/panes" — the answer on disk today is WezTerm, by default rather than
  by decision.
- **Comments describe a burrito that no longer exists**, including two that
  justify design decisions: "multiplexing lives in the shell via burrito, not
  here" and the tab-bar chrome height being "zero whenever the tab bar is
  hidden (the usual case here — burrito owns multiplexing, so there's a
  single tab)". The second is now always false: nine tabs means the bar is
  always shown.

**Hard-won constraints, carried here so they are not rediscovered.** These
are not capabilities and carry no rating; they are the expensive part of the
knowledge, and every entry below that depends on one names it.

- **`wezterm.GLOBAL` is the only store that survives a config reload.**
  WezTerm evaluates the config into more than one Lua context — measured, 2
  per evaluation — and **every evaluation makes fresh ones**, so a
  module-local starts `nil` in each. That, and not context count, is the
  reason for `GLOBAL`: a module-local `slots` table is wiped by every
  reload, and every `tinty apply` is a reload because `colors.lua` is on the
  watch list, leaving each reconcile pass to re-adopt the current tab order
  as gospel — exactly the state that has to survive. `GLOBAL` values must
  stay JSON-shaped (array of integer ids, string keys), and a value read
  back out of it is a **copy**: assigning into it does not write through, so
  it is rebuilt as a plain table and reassigned.
- **The every-other-callback story is refuted, and the rule above does not
  rest on it.** This entry used to say callbacks run "in whichever is free,
  so a module-local table reads back `nil` about as often as not". Measured
  2026-08-24 on `20240203`, against an **instrumented copy of
  `wezterm.lua` itself** in two isolated `wezterm-gui` processes — 16
  evaluations, 9 event kinds, **2770 handler fires** — a module-local read
  back `nil` **5 times**, and every one was the **first** fire of a freshly
  evaluated context: **0 of 2765 later fires**. Exactly one context served
  events at any moment and dispatch never returned to an older one. The
  config's stronger wording, a local `slots` table "read back as nil on
  every single event", is refuted by the same fixture. The probe writes its
  log **outside** the config directory: a write inside it re-triggers the
  reload, and that storm reads exactly like a context pool — which is the
  most likely origin of the wording being corrected here.
- **`pane:get_current_working_directory()` does not exist on 20240203.**
  Recorded in the config as verified nil on the status callback's pane, on
  `window:active_pane()` and on the mux pane alike, which raised "attempt to
  call a nil value" on *every* status tick and meant `set_right_status` was
  never reached — that is why the corner sat empty. Not re-verified here;
  note that `wezterm cli list` *does* print a CWD column, so the OSC 7 data
  reaches
  the mux even though the Lua accessor is missing. The re-spec should re-check
  before designing anything around it.
- **The pane-select modal cannot coexist with a key listener.** A key bound in
  `config.keys` or a key table is consumed in the raw-key pass before
  `act.PaneSelect`'s modal sees it; a key that is *not* bound reaches the
  modal, which answers only to a complete label, Escape and `ctrl+g` and
  silently eats the rest. Nothing in Lua closes it — `cancel_modal` is
  reachable from no `KeyAssignment` and `PaneSelector::perform_assignment`
  returns false unconditionally (checked in this build's source and in main).
  That is why F5 paints its own labels.
- **`pane-focus-changed` is inert on 20240203.** Verified in the config as
  never firing on a pane switch. It is still registered because it costs
  nothing and starts working by itself on a build that emits it; the 5 s tick
  is the guarantee until then.
- **There is no tab-close event.** Hence reconciliation rather than
  interception — see the nine-tab floor.
- **The kitty keyboard protocol is a matched pair with nushell.** With it on,
  reedline fires the support query at startup and the pty returns the reply
  too late to consume, so `^[[?...u` leaks and garbles the prompt before it is
  visible. Enabling only the WezTerm half reproduces the leak and buys
  nothing, since the shell never opts in.
- **`set_config_overrides` re-fires the event that called it.** Both
  `center_grid` and the `opacity` user-var only write when the computed value
  actually changed; without that guard it is a feedback loop.
- **`MoveTab` acts on whatever the GUI believes is the active tab**, which
  right after a `spawn_tab` can still be the *previous* tab. A "harmless"
  no-op move therefore shoved the old tab one slot along (startup came out
  `1,0,2,3…`). Activate explicitly before any real move, and skip the move
  entirely when the slot being filled is already the end of the list.
- **burrito is gone.** It was deleted 2026-08-20, so several comments in the
  live file ("multiplexing lives in the shell via burrito", "the usual case
  here — a single tab") describe a world that no longer exists. WezTerm now
  owns tabs and panes by default. This is one half of open decision D.1 and
  the re-spec must state it rather than inherit it.

----
## Launchd PATH seeding
- macOS only: prepends `/opt/homebrew/{bin,sbin}`, `~/.local/bin` and
  `~/.cargo/bin` to `set_environment_variables.PATH`. A GUI-launched WezTerm
  inherits launchd's minimal `PATH` (`/usr/bin:/bin:/usr/sbin:/sbin`), which
  has no Homebrew — so the bare `nu` in `default_prog` cannot be found.
  WezTerm spawns `default_prog` directly with no shell in between, so nothing
  runs `path_helper` and nothing recovers Homebrew on its own. `env.nu` owns
  `PATH` from inside the shell; this only has to get the binary spawned.
- **The pane survives — the window does not die.** Measured 2026-08-23 with
  `wezterm-mux-server` under `env -i PATH=/usr/bin:/bin:/usr/sbin:/sbin`: the
  pane is created and kept, showing `Unable to spawn nu because: / No viable
  candidates found in PATH "/usr/bin:/bin:/usr/sbin:/sbin"` and then
  `didn't exit cleanly`. Neither config sets `exit_behavior`, and the default
  `CloseOnCleanExit` retains a pane whose process exited *un*cleanly. A dead
  pane you have to read is worse to diagnose than a window that vanishes.
- **The two inline `sh -lc` repetitions are neither the same seeding nor for
  this reason.** `sh -lc` is a *login* shell, so `/etc/profile` runs
  `path_helper`, which reads `/etc/paths.d/homebrew` and puts
  `/opt/homebrew/bin` on `PATH` by itself. Measured 2026-08-23 under a
  scratch `HOME`: `env -i HOME=$S PATH=/usr/bin:/bin:/usr/sbin:/sbin sh -lc
  'command -v nu; command -v tinty'` answers `/opt/homebrew/bin/nu` and
  `tinty: NOT FOUND`. What the F6 prefix (`wezterm.lua:1038`) earns is
  `~/.local/bin` — where `tinty` is installed — plus `~/.cargo/bin`, which
  `path_helper` never adds, and `/opt/homebrew/sbin`, since
  `/etc/paths.d/homebrew` names only `bin`. It must not be "simplified" away
  on the grounds that `nu` resolves without it: the toggle would then fail on
  `tinty` one layer further in, where the cause is far harder to see. The
  wallpaper prefix (`wezterm.lua:757`) seeds only `/opt/homebrew/{bin,sbin}`
  and is redundant outright — its comment claims `sh -lc` cannot find brew's
  `magick`/`curl`, and under the same login shell `magick` and `convert`
  resolve under `/opt/homebrew/bin/` while `curl` is `/usr/bin/curl`.
- One live-machine trap, to guard against rather than rely on: `~/.profile`
  here is `. "$HOME/.cargo/env"`, which is what puts `~/.cargo/bin` into a
  login shell's `PATH` on this machine. This repo deploys no `dot_profile`,
  so any re-measurement runs under a scratch `HOME` or it passes for the
  wrong reason. `env.nu` lines 15-19 already record the same `path_helper`
  mechanism, and prepend the same two user dirs.
- 2
- 10
----
## Nushell as `default_prog`
- `nu --config ~/.config/nushell/config.nu
  --env-config ~/.config/nushell/env.nu` with `XDG_CONFIG_HOME` set
  explicitly, so the same nushell files are used
  regardless of how the GUI was launched. Depends on the PATH seeding above.
- 1
- 8
----
## Font stack
- `font_with_fallback{ "CaskaydiaCove Nerd Font", "CaskaydiaCove NF",
  "JetBrainsMono Nerd Font", "Cascadia Code", "Menlo" }`, `font_size` 14.0 on
  macOS / 9.0 elsewhere, `line_height = 1.0`, and `font_dirs` pointed at
  `~/Library/Fonts` (macOS) or `~/.local/share/fonts` so a freshly installed
  font resolves before the system font cache refreshes. Verified installed:
  `~/Library/Fonts/CaskaydiaCoveNerdFont-*.ttf`, and `fc-list` resolves the
  family name the config asks for.
- 2
- 9
----
## `Ctrl+V` native paste
- `act.PasteFrom("Clipboard")` — a bracketed paste, which is how text reaches
  both the shell and a running program (Claude, nvim). No subprocess, and it
  is what makes clipboard-based dictation (Wispr) land in the terminal.
- 1
- 8
----
## `Ctrl+C` copy-or-SIGINT
- Callback: if `window:get_selection_text_for_pane` returns a non-empty
  selection, copy to `ClipboardAndPrimarySelection` and clear it; otherwise
  `SendKey{ key="c", mods="CTRL" }` so the key keeps its terminal meaning.
  Gives the platform-native copy shortcut without ever costing an interrupt.
- 3
- 9
----
## Kitty keyboard protocol off
- `enable_kitty_keyboard = false`. One line, and it is WezTerm's default — it
  is kept explicit as a marker for the matched pair with nushell's
  `use_kitty_protocol = false`. See the constraint above for the escape leak.
- 1
- 7
----
## Tab title is the digit and nothing else
- `format-tab-title` returns `"  %d  "` for `tab.tab_index + 1`, so the tab
  bar *is* the F5 keymap legend. Nine process titles would not fit legibly and
  the opposite corner is reserved for the clock.
- 1
- 7
----
## `StartWindowDrag` on `Ctrl+Alt+Super`+left-drag
- With `window_decorations = "RESIZE"` there is no titlebar to grab, so this
  is the only handle for repositioning the OS window. The deliberately heavy
  modifier combo keeps it from stealing ordinary clicks or selection drags.
- 1
- 7
----
## `Ctrl`+left-click opens the link under the cursor
- `act.OpenLinkAtMouseCursor` with `mouse_reporting = true`, which is what
  keeps it working while an app is capturing the mouse (DECSET 1002/1006) —
  without that flag WezTerm forwards the click to the app and nobody opens the
  URL. Plain clicks still reach the app. The comment cites burrito as the
  mouse-capturing app; burrito is gone, but nvim and other TUIs capture the
  same way, so the flag still earns its place.
- 1
- 7
----
## Fullscreen at startup
- `gui-startup` spawns one window, hands the CLI's `cmd` to the **first tab
  only** (so `wezterm start -- nvim foo` does not open nine editors), clears
  the stale `GLOBAL` slot maps a config reload would leave behind, fills the
  tab floor, activates slot 1 and calls `toggle_fullscreen()`.
- 3
- 8
----
## Copy mode: `Ctrl+Shift+X` plus a single-key `c` cycle
- `ctrl+shift+x` clears a stale selection and the toggle flag, then
  `ActivateCopyMode`. The **default** `copy_mode` table is extended, not
  replaced: its **54 builtin motions** survive, plus `c`: it anchors a `Cell`
  selection, and a second press does `CopyTo("ClipboardAndPrimarySelection")`
  + `CopyMode("Close")`. The toggle is per pane id, not read from the
  selection, which reads empty over blank cells; the entry reset stops
  `q`/`Esc`/`y` leaving it stale. Verified in `wezterm show-keys --lua`: 55
  rows, 54 builtin plus this `c`. **Copy mode has no search**: no `/`, no
  `NextMatch`/`PriorMatch`/`ClearPattern`/`CycleMatchType`. Those are a
  separate 10-row `search_mode` table, reached from normal mode by default
  `Ctrl+Shift+F` / `Cmd+F`.
- 4
- 9
----
## Appearance baseline
- `window_decorations = "RESIZE"`, `window_padding` all zero (grid centering
  owns padding at runtime), `default_cursor_style = "BlinkingBlock"`,
  `window_background_opacity = 0.95` with the translucent tint set to the
  active scheme's base00 (never pure black, which would diverge from the
  scheme), `macos_window_background_blur = 30` so the OS frosts the desktop
  behind the window, `inactive_pane_hsb = { saturation 0.85, brightness 0.7 }`,
  `scrollback_lines = 10000`, `audible_bell = "Disabled"`. There is no WezTerm
  image layer any more — the blur is the OS compositing the (already blurred)
  desktop wallpaper through the translucent cell colour.
- 2
- 7
----
## Tab bar chrome
- `use_fancy_tab_bar = false` (the retro bar, which is what makes
  `colors.tab_bar` apply), `tab_bar_at_bottom = false`,
  `show_new_tab_button_in_tab_bar = false`, `hide_tab_bar_if_only_one_tab =
  true` — the last is vestigial while the nine-tab floor holds, kept for a
  window opened by other means.
- 1
- 6
----
## Font zoom does not resize the window
- `adjust_window_size_when_changing_font_size = false`. By default WezTerm
  resizes the OS window to land on a whole number of cells; a fullscreen
  window cannot grow, so it instead leaves a large gap and appears to change
  size. Off, the window stays put and the grid just reflows.
- 1
- 6
----
## OpenGL front end with capped frame rate
- `front_end = "OpenGL"` (not WebGpu: transparency plus OS backdrop blur have
  the same backend sensitivity the old layered background had), `max_fps = 60`
  and `animation_fps = 60`. Uncapping to 255 let WezTerm present every redraw
  at up to 255 Hz, which combined with the status repaint and cursor blink
  kept the GPU churning for no visible benefit.
- 1
- 6
----
## Live tinty theme, read WezTerm-side
- `dofile` (not `require`, which caches by module name and would keep
  returning the *first* palette on a second `tinty apply`) of
  `~/.config/wezterm/colors.lua`, guarded by `pcall` plus an essential-key
  check so a half-written file from a concurrent hook is rejected instead of
  painted as a half-empty theme. `add_to_config_reload_watch_list` is required
  because WezTerm's auto-reload only watches files it loaded and `dofile` is
  invisible to it. Reading it here rather than taking tinted-shell's per-pane
  OSC escapes is what makes a theme switch **global**: `config.colors` is
  WezTerm-wide, so every window, tab and pane retints at once. `colors.tab_bar`
  is derived from the same palette (bar bg = base00, active tab = base02 +
  base05 bold, inactive = base00 + base03) because the retro bar does not
  inherit the scheme and stayed near-black under a light scheme; `window_frame`
  is set too, since it paints the resize border even with the fancy bar off.
  `config.color_scheme = "Gruvbox dark, hard (base16)"` is the fallback for a
  checkout that has not picked a theme. The generator
  (`tinted-theming/tinty/wezterm-colors.sh`) is provisioning's, not this
  epic's — see
  [`capabilities-provisioning.md`](capabilities-provisioning.md).
- 5
- 9
----
## `Ctrl+Shift+Q` close-window escape hatch
- `mark_closing(window_id)` then `act.Multiple` of one
  `CloseCurrentTab{ confirm = false }` per live tab. Needed only because the
  tab floor applies to every window: closing tabs one at a time can never
  empty a window whose slots refill, and `window_decorations = "RESIZE"`
  leaves no titlebar close button. Marking first is what stops the reconciler
  racing the close. `confirm = false` because the prompt would appear once per
  tab. WezTerm exposes no "close window" action, hence the loop. **Conditional
  on the nine-tab floor** — drop the floor and this is dead weight.
- 3
- 7
----
## OSC 1337 `SetUserVar` triggers
- `user-var-changed` handles two names, both written by a nushell command
  printing the escape to stdout. `copymode` (value ignored) drops the GUI into
  copy mode, which is how a shell command reaches a GUI-only mode. `opacity`
  takes a percentage 0–100, clamps it and applies
  `window_background_opacity` as a per-window override — live, nothing
  persisted, and guarded against the `set_config_overrides` feedback loop.
- 3
- 7
----
## Status tick rate
- `status_update_interval = 5000`. One interval drives three things:
  `update-status` (→ tab reconcile and grid centering, the latter because
  interactive font zoom fires no resize or reload event), `update-right-status`
  (the clock), and the F5 label janitor. At 1 s it repainted the tab bar every
  second forever for a clock that needs minute resolution; 5 s costs at most a
  5 s lag on the minute rollover and still recenters a font zoom promptly, and
  the no-op guards keep idle ticks near-free.
- 1
- 5
----
## Top-right clock
- `update-right-status` paints `  HH:MM  ` in `AnsiColor = "Silver"`,
  unconditionally and last, so nothing can displace it; the tab bar is at the
  top, so the right status *is* the top-right corner. HH:MM only because the
  5 s tick is what repaints it. Deliberately the only thing in the corner: the
  OSC 7 cwd label that used to live here is impossible on this build (see the
  constraints), and F5's legend was removed as noise.
- 2
- 5
----
## F6 theme toggle
- Flips between the two theme slots `theme.nu` parks in the state dir, via
  `background_child_process` running
  `sh -lc '… exec nu -n -c "source theme.nu; _theme_toggle"'`. Bound in
  WezTerm rather than the shell so it works from any pane whatever is running
  in it — a full-screen TUI would swallow a shell-level binding.
  `background_child_process`, not `run_child_process`, because `tinty apply`
  runs the whole hook chain and blocking the GUI thread would freeze every
  window for its duration; nothing needs the exit status, since the visible
  effect arrives when tinty rewrites `colors.lua` and the reload watch fires.
  **D.1b answered 2026-08-21 (user): tinty stays as palette owner, so the
  switcher is minimal base alongside the reader.** The binding has no node
  yet — `w0-2-terminal-respec` R5 ("give the ~230 uncovered lines a home")
  owns placing it, and the `theme.nu` half it calls needs a new `04-shell`
  child. Keep the two constraints above with it: bound in WezTerm rather than
  the shell because a full-screen TUI swallows a shell-level binding, and
  `background_child_process` rather than `run_child_process` because
  `tinty apply` runs the whole hook chain and blocking the GUI thread freezes
  every window for its duration.
- 3
- 6
----
## Per-pane OSC retint
- `retint_all_panes` builds an OSC 4/10/11/12/17/19 string from the palette
  and `inject_output`s it into every live pane on `window-config-reloaded`.
  Needed because a pane that already received tinted-shell's per-pane OSC
  escapes holds an override that outranks `config.colors`, so a config reload
  alone leaves it on the old scheme — the "only this pane changed" symptom.
  Deduped on the payload in `GLOBAL` (which survives the reload that resets
  every local) because the event fires per window and a theme switch reloads
  all of them, so without it every font-size edit re-blasts every pane. OSC
  only: nothing is printed and the cursor never moves, so it is safe over a
  full-screen TUI; wrapped in `pcall` because `inject_output` is absent on
  older builds and a pane can die mid-iteration.
  **The contingency resolved in favour of keeping it (D.1b, 2026-08-21):**
  `config.nu` sources tinty's cached tinted-shell artifact at every
  interactive start, and that artifact writes the per-pane OSC escapes — so
  the override this broadcast exists to overrule is live, and without the
  broadcast a theme switch leaves already-open panes on the old scheme.
- 6
- 7
----
## `config.lua`  DO NOT PORT
- A 23-line file sitting next to `wezterm.lua`, **never loaded** — the only
  `require` in the config is `require("wezterm")`, and WezTerm reads
  `wezterm.lua` alone. It is also not valid Lua (`profile: { … }` uses
  JS/YAML-style colons) and contains a Cyrillic typo (`use_defaultы`). It is
  not in the chezmoi source, so it is an unmanaged local file. Its danger is
  entirely as a decoy: it asserts a font and colorscheme
  (`Departure Mono Nerd Font Mono`, `Gruvbox Material`) that a reader would
  plausibly believe. Delete rather than port, and record why.
- 1
- 1
----
## F5 jump-select  SIMPLIFY
- One mode that arms tab switching and pane switching at the same time, with
  one keypress resolving either: a digit `1`–`9` activates that tab, a letter
  activates the pane at that position, every key ends the mode. Implemented as
  a pushed key table (`one_shot`, `until_unknown`, 5000 ms timeout) plus an
  overlay painted by hand, because WezTerm's own `act.PaneSelect` modal can
  never coexist with a key listener (see the constraints). The labels are one
  letter per pane, centred, in reverse video, `inject_output`-ed into the
  pane's own terminal parser — which is why a label lands *on* the pane
  rather than in a window corner, and why the covered cells have to be read
  back with
  `get_lines_as_text` and restored by hand (attributes are not recoverable, so
  a label sits on plain text and the cells come back uncoloured until the app
  repaints). Nothing is painted on a single-pane tab. The saved cells live in
  `GLOBAL` keyed by pane id, since the callbacks run in a different Lua
  context from the painter and a pane id survives a tab switch. All 26 letters
  are bound, not just the ones a pane has, because `until_unknown` pops the
  table without eating the keystroke — an unbound letter would type itself
  into nvim or Claude; a miss rings BEL through the same parser instead. A
  janitor on `update-right-status` sweeps labels left by the two exits that
  run no callback (timeout, `until_unknown`), scoped to the painting window
  because `GLOBAL` is shared and the key-table stack is not.
- Verified live in `wezterm show-keys --lua`: `key_tables.jump_mode` has
  exactly 36 entries — `Escape`, digits `1`–`9`, and all 26 letters. The
  pane alphabet is **`asdfghjkl`**, indexed against `tab:panes()` order (the
  order
  the splits were made in) — nine letters, home row, not the letter set or
  the ordering the existing PRD describes.
- **Live bug L-11, do not reproduce:** the miss path's BEL is silent.
  `audible_bell = "Disabled"` and no `visual_bell` is configured, so a
  mistyped jump letter produces no feedback at all — the keystroke is eaten
  and nothing happens, which is indistinguishable from the key table having
  failed to open. The re-spec owes the miss path a feedback channel that
  exists (a `visual_bell` fade, or reusing the pane-label overlay), or an
  explicit decision that silence is acceptable.
- `SIMPLIFY`: the digit half is a handful of lines and carries most of the
  value; the self-painted pane overlay is the bulk of the complexity and is
  worth its own decision in the re-spec.
- 9
- 8
----
## Dynamic grid centering  DEFER
- `center_grid` measures the true cell size from the grid's own rendered area
  (`mux_tab:get_size()` → `pixel_width/cols`), recomputes how many whole
  cells fit the window, and pushes the sub-cell remainder into symmetric
  `window_padding` overrides. The grid is an integer number of cells and
  almost never divides the window exactly, so without this the leftover sits
  as an uneven gap on the right and bottom. Adapts to any font size, DPI or
  resolution, and fires on `window-resized`, `window-config-reloaded` and the
  5 s tick (interactive font zoom fires neither of the first two). Four
  non-obvious pieces, each paid for: the tab is reached via
  `mux_window():active_tab()` rather than `active_pane():tab()`, because an
  overlay (debug, char-select, launcher) makes the active pane a detached one
  whose `:tab()` is nil and crashed centering mid-flight; the cell size is
  measured directly instead of reconstructed from window-minus-padding, which
  read stale padding under fractional DPI and during the multi-frame settle
  after a zoom; the tab-bar chrome height is subtracted so the grid centres
  *below* the bar; and the total gap is `floor`ed before halving, because
  over-padding by even a sub-pixel shrinks the usable area and drops a column
  that the next tick adds back — a 1 Hz flicker. Plus the idempotency guard
  against `set_config_overrides` re-firing the event.
- `DEFER` is a recommendation, not a settled call: it is cosmetic by the
  README's exclusion test, and it is the second-most intricate thing in the
  file. It is recorded in full here precisely so that deferring it does not
  throw the four constraints away. Flag it with D.1 for the human.
- 8
- 6
----
## `background.png`  DO NOT PORT
- A 2.8 MB blurred image in the config dir, written by the `ctrl+shift+b`
  pipeline below. **Nothing in `wezterm.lua` reads it** — there is no
  `window_background_image` and no image layer; it is only ever a file the
  script copies out to the OS desktop wallpaper. It is an output artifact
  sitting in a config directory. Drops out with the pipeline.
- 2
- 0
----
## Self-healing nine-tab floor  SIMPLIFY
- Nine terminals, always ready, on **every** window — the startup window,
  `ctrl+shift+n`, and `wezterm cli spawn --new-window` alike. `TAB_COUNT = 9`
  is a floor, not a target: extra hand-opened tabs are adopted, never closed,
  and a dead slot past the floor is dropped rather than refilled. Because
  WezTerm emits no tab-close event, it **reconciles** rather than intercepts:
  compare the live tab list against a per-window slot map and rebuild the
  holes, which covers `CloseCurrentTab`, `exit` in a tab's last pane, a
  crashed shell and `wezterm cli kill-pane` with one mechanism. Position is
  restored, not just the count — a plain `spawn_tab` appends, so the
  replacement for a dead slot 3 would land at the end and silently renumber
  everything after the hole (F5+4 would then reach the old tab 5); so it
  spawns, then `MoveTab`s into the dead slot's index. Slots are tracked by
  `tab_id`, never by index, because indices are exactly what shift when a tab
  dies. Five things make it survive contact: per-window slot maps in `GLOBAL`
  (a single shared list had two windows reading each other's ids as dead slots
  and refilling forever; see the `GLOBAL` constraint for why not a local); a
  `set_slots` that rebuilds the map as a plain table and drops entries for
  dead windows, the only thing keeping it from growing for the session; a
  module-local re-entrancy guard, because `spawn_tab` and `perform_action`
  pump the event loop and a nested pass saw a half-built window and filled its
  own holes — startup produced 16 tabs instead of 9; `pcall` around the
  repair, so a spawn failure cannot leave the guard latched — measured, a
  latched guard stops healing in every window until this file is evaluated
  again (see the next bullet); and focus handling that re-asserts the tab
  you were
  on **by id** after the rebuild rather than snapping you onto a blank
  replacement. Repair triggers: `update-status` (the 5 s tick, which is what
  actually heals, focused tab or not), `window-config-reloaded` (fills a new
  window at birth instead of up to 5 s later), `window-focus-changed`, and
  `pane-focus-changed` (inert on this build — see the constraints). The
  no-hole path is a tab-list walk, so idle ticks stay cheap.
- Verified live with `wezterm cli list`: one window, exactly nine tabs, with
  tab ids `9, 10, 11, 12, 13` interleaved among `2, 5, 6, 7, 8` at the *slot*
  positions their predecessors held — that interleaving is the `MoveTab`
  repositioning working, not appending.
- **The guard's lifetime, measured 2026-08-23 on `20240203`.** One
  evaluation of `wezterm.lua` creates **2** Lua contexts (4 with three
  windows) and each runs the file body once, so each holds its own
  `repairing` — but **exactly one context serves every trigger of that
  generation**: 0 of 268 fires across 10 generations, 1-3 windows and 7
  event kinds reached a sibling, including with an 800 ms busy-wait held
  inside `update-status` against a 200 ms tick. So a latched guard is read
  as latched by every later fire, in every window, including windows opened
  after it latched — `latched=false` occurred 10 times in 268 fires, always
  the first fire after an evaluation. Only re-evaluating the file clears it:
  a successful reload does, and every `tinty apply` is one because
  `colors.lua` is on the reload watch list; a config that fails to parse
  does **not**, because the body never runs. The probe that measures this
  writes its log **outside** the config directory — a write inside it
  re-triggers the reload, and the storm reads exactly like a context pool
  (56 evaluations and 51 serving contexts per generation, against 2 and 1).
- `SIMPLIFY`: it is the most intricate code in the config and it exists to
  make one promise — "F5 + a digit always lands on the same slot, and there
  is no tab-7-doesn't-exist-yet case". Two cheaper shapes keep most of that:
  nine
  tabs spawned once at `gui-startup` with no reconciler (a closed tab stays
  closed, and F5's digits shift), or reconcile count-only without `MoveTab`.
  Both drop the guarantee. The re-spec must choose knowingly, and note that
  `ctrl+shift+q` exists **only** to serve this — dropping the floor deletes
  the need for the escape hatch too. Now that burrito is gone, WezTerm owns
  tabs by default, which makes this decision load-bearing rather than
  academic.
- 10
- 7
----
## `wsl-clip-prime.sh`  DO NOT PORT
- Bridges a Windows-clipboard image onto the Wayland clipboard as PNG via
  `powershell.exe`, so Claude Code's `wl-paste --type image/png` branch finds
  it (WSLg bridges only `image/bmp`, which Claude rejects). Its comment says
  "wezterm's Ctrl-Shift-V runs this" — **no such binding exists** any more
  (`wezterm show-keys --lua` resolves `ctrl+shift+v` to WezTerm's default
  `PasteFrom 'Clipboard'`). Orphaned, unmanaged by chezmoi, and WSL-only
  against a macOS-host-only scope decision.
- 4
- 0
----
## `solo-window.{sh,applescript,ps1,vbs}`  DO NOT PORT
- Four scripts, one per platform, that minimise or hide every window except
  the focused one. Each names the binding that invoked it — "the WezTerm
  CTRL+SHIFT+M binding via background_child_process" — and **that binding
  does not exist** in the live config; `ctrl+shift+m` is unbound. The scripts
  are
  still in the chezmoi source (`home/dot_config/wezterm/`), so they are
  deployed dead code on every machine. The Wayland variant documents that its
  own job is impossible under Wayland's security model. Drop all four; note
  the macOS one additionally required an Accessibility grant.
- 5
- 0
----
## `Ctrl+Shift+B` wallpaper pipeline  DO NOT PORT
- `PromptInputLine` takes an image URL or path; nil (Esc) does nothing, empty
  clears, anything else is validated in Lua (reject control chars and single
  quotes) and interpolated into one POSIX `sh -lc` script under `set -e`. The
  script seeds Homebrew on `PATH`, `mktemp`s with an `EXIT INT TERM` trap,
  `curl`s an http(s) URL or copies a local file (stripping `file://`,
  expanding a leading `~`), blurs it to 16 px gaussian with `magick` or
  `convert` **into a temp first** — which doubles as image validation, since
  a non-image input fails there and `set -e` aborts before any destination is
  written — then publishes to both `chezmoi source-path` and the live dir,
  and
  finally applies the blurred copy as the **OS desktop** wallpaper via
  `osascript` (macOS) or `gsettings` (GNOME). The clear path removes both
  copies and calls `reload_configuration`.
- The engineering is careful, and the capability is a terminal keybinding that
  reaches out and rewrites the OS wallpaper and a chezmoi source tree. It is
  cosmetic, cross-writes another tool's repository from a GUI keypress,
  depends on ImageMagick, and is the single largest block in the file after
  the tab floor. Drop it; if desktop wallpaper matters later it is a shell
  command, not a terminal binding.
- 8
- 3
----
