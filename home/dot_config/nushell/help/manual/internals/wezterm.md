# WezTerm

> The local chrome \u2014 font, grid centering, opacity, launchd PATH.

WezTerm keeps only what is true of this machine; tmux owns multiplexing.

## `wezterm.lua`

```
local wezterm = require("wezterm")
```

WezTerm appearance: font, palette reader, derived tab bar, baseline, clock, F6 theme toggle — prds/02-terminal/01-appearance owns that scope. The self-healing nine-tab floor below is prds/02-terminal/02-startup-layout's; later terminal nodes (F5, copy mode, grid centering) extend this file.

The launch environment — default_prog, set_environment_variables and the macOS PATH prefix — is prds/02-terminal/06-launchd-path's, and it sits immediately below: a GUI-launched WezTerm inherits launchd's environment, so nushell has to be named and its PATH seeded before the spawn.

```
local is_mac = triple:find("darwin") ~= nil
```

The only platform surface WezTerm offers.

```
local nu_config = home .. "/.config/nushell/config.nu"
```

── 06-launchd-path: the launch environment ───────────────────────────────── Nushell, with both config files named absolutely (R6). A GUI-launched WezTerm gets no default_prog for free and WezTerm then falls back to the passwd login shell. Measured 2026-08-23 on this machine: `dscl . -read /Users/feb UserShell` is /bin/zsh, launchd's GUI environment exports no SHELL (only SSH_AUTH_SOCK -- see the foreground-process comment further down), and a wezterm-mux-server started under `env -i` with no default_prog spawns `-zsh`. So without this line the terminal never starts nushell at all: no aliases, no keybindings, no `help`.

Both files are named rather than left to discovery, because the config directory nushell would discover is not the managed one -- see the XDG_CONFIG_HOME comment below, which is the other half of the same fact. 07-multiplexer/08-wezterm-reduction, Q8: the terminal opens INTO tmux. The spelling of the attach is not repeated here — ~/.local/bin/tmux-main holds it, so WezTerm, an ssh login and anything else that wants the session all say the same thing and cannot drift apart. That script is also what still starts nushell directly on a machine with no tmux, with the same three obligations this line used to carry (resolve nu on PATH, export XDG_CONFIG_HOME before the exec, fall back to a shell that exists). Still named, still not left to discovery: the capsule Ctrl+Shift+O binding below spawns nushell directly, outside tmux, and needs the same two paths the old default_prog did. The XDG_CONFIG_HOME comment below is the other half of the same fact.

```
config.set_environment_variables = {
```

XDG_CONFIG_HOME is exported at LAUNCH, and that is the whole point (R7). $nu.default-config-dir is a launch-time CONSTANT, so env.nu's own assignment runs too late to move it and everything nushell derives from it drifts out of the managed tree. Measured 2026-08-23 on nushell 0.114.1: with --config/--env-config but no export, $nu.default-config-dir is ~/Library/Application Support/nushell and $nu.history-path is the history.sqlite3 under it -- and reedline really does create it there, so the shell history silently leaves ~/.config. history.nu's header records the same lesson for that path; this line is what makes it come out right. Not inside the is_mac branch: it is correct on every platform.

```
if is_mac then
```

PATH seeding, macOS only (R2, R3). default_prog above is spawned by WezTerm itself -- execvp against the process PATH, never through a login shell -- and a GUI launch inherits launchd's PATH. Measured 2026-08-23: `launchctl getenv PATH` is unset, so that is the hardcoded /usr/bin:/bin:/usr/sbin:/sbin, with no Homebrew in it. Without this prefix the spawn fails with `No viable candidates found in PATH` and the pane STAYS OPEN carrying that message plus "didn't exit cleanly" -- WezTerm's default exit_behavior is CloseOnCleanExit, so the failure is a terminal you cannot type into rather than a window that disappears.

Four DIRECTORIES, fixed, not a list computed from the installed package set: it seeds directories, so adding a package to the provisioning set needs no change here. Not seeded on Linux -- this is a macOS-host-only configuration and nu is on PATH there already.

Getting the binary spawned is all this does; env.nu owns PATH inside the shell, and it wins by construction (R5). env.nu `prepend`s ~/.cargo/bin and ~/.local/bin, `append`s the Homebrew and system dirs and `uniq`s, so the duplicates this prefix creates collapse and the shell's resolution order is env.nu's under either launch shape. Measured both ways on 0.114.1: the repaired PATH is .cargo/bin:.local/bin:/opt/homebrew/bin:... whether the launch PATH was this prefix or a terminal's inherited one.

```
local TAB_BAR_RESERVE = 0
```

── 07-grid-centering: the runtime owner of window_padding ────────────────── Keep the grid centered. The grid is an integer number of cells, so it almost never divides the window exactly, and the sub-cell remainder would sit as an uneven gap on the right and bottom. center_grid measures the true cell size, recomputes how many whole cells fit, and pushes the leftover into padding -- so it adapts to any font size, DPI or resolution by itself (resize, interactive zoom, monitor swap). The left/right split is exactly symmetric; the top/bottom split is symmetric to within the tab-bar over-reserve explained below, which measured 0-2 px across the font sizes checked.

This pair is the RUNTIME OWNER of window_padding. That is why config.window_padding further down the file is declared as four zeroes (prds/02-terminal/01-appearance R8): the declaration is only the neutral starting point, and every value after the first tick comes from here. The tab bar's pixel reserve, read by grid_padding below through an upvalue. ZERO because `config.enable_tab_bar = false` since the tmux cutover (07-multiplexer/08-wezterm-reduction) — there is no bar to reserve for, and reserving one pushed the grid up by cell_h + 1 with that much dead space at the bottom. Declared OUT HERE, above the sentinel, on purpose: see the long note inside grid_padding for the two shapes that did not survive the gate.

```
local function grid_padding(win_w, win_h, cell_w, cell_h)
```

>>> grid-padding (pure): no wezterm calls in this block -- tests/wezterm-grid-centering.sh --math slices it out between these two sentinels and runs it against measured geometries. The failure this node exists to fix -- an axis that computes zero for every input -- is invisible to a grep and needs no GUI to catch, so the arithmetic is kept pure and the gate proves it produces padding at all.

```
local bar_h = TAB_BAR_RESERVE or (math.ceil(cell_h) + 1)
```

RESERVE the tab bar, do not measure it. mux_tab:get_size() reports the PTY size, which is exactly rows * cell_h and therefore carries no information about the vertical remainder: deriving the chrome as height - grid_height - pad_top - pad_bottom measures the bar PLUS the remainder, the available height collapses back to rows * cell_h, and the vertical gap comes out zero by construction at every font size. Measured, not assumed: that is why this reserves the bar instead.

The constant is EMPIRICAL. Measured against wezterm 20240203-110809-5046fc22 (dpi 144, CaskaydiaCove, line_height = 1.0, retro tab bar shown), the bar is cell_h or cell_h + 1 pixels tall at font sizes 9, 12, 14, 17 and 21. RE-MEASURE IT IF THE WEZTERM BUILD MOVES.

It over-reserves on purpose, because the error is safe in one direction only. Over-reserving by d px costs d px of top/bottom asymmetry, plus one row in the boundary case where (win_h - bar) mod cell_h < d -- stable, reached in one tick, never flickering. UNDER-reserving over-pads, drops a row and parks a whole extra cell at the bottom, which is the flicker failure described further down in its stable form.

THE RESERVE IS ZERO SINCE 2026-08-30, AND THAT IS THE WHOLE OF WHAT THE tmux CUTOVER DID TO THIS FUNCTION. Everything above still describes the arithmetic correctly and is kept, because the day a tab bar comes back this is the reasoning that has to come back with it.

What changed: `config.enable_tab_bar = false` (07-multiplexer/08-wezterm-reduction). There is no bar, so reserving a row of pixels for one pushes the grid up by cell_h + 1 and leaves that much dead space at the bottom — an off-centre grid, which is the exact defect this node exists to prevent, arrived at from the other side.

The old text said the reserve "assumes the tab bar is SHOWN, and the nine-tab floor above is what guarantees it: hide_tab_bar_if_only_one_tab hides the bar at one tab only, and the floor keeps nine". Both halves of that guarantee are gone — the floor and the option — which is why this had to move rather than being left as a harmless constant. Found by `bash tests/wezterm-grid-centering.sh` on the quiet sweep, not by reading: its static check asserts the option the reserve depends on.

It is written as a branch on the config rather than as a bare `0`, so the constant and its measurement survive and a future tab bar needs one line, not an archaeology dig. The constant is EMPIRICAL: measured against wezterm 20240203-110809-5046fc22 (dpi 144, CaskaydiaCove, line_height = 1.0, retro tab bar shown), the bar is cell_h or cell_h + 1 pixels tall at font sizes 9, 12, 14, 17 and 21. RE-MEASURE IT IF THE WEZTERM BUILD MOVES. THE RESERVE IS AN ARGUMENT SINCE 2026-08-30, AND ZERO AT THE ONE CALL SITE. Everything above still describes the arithmetic correctly and is kept, because the day a tab bar comes back this is the reasoning that has to come back with it — and the default below is that reasoning, still executable.

What changed: `config.enable_tab_bar = false` (07-multiplexer/08-wezterm-reduction). There is no bar, so reserving a row of pixels for one pushes the grid up by cell_h + 1 and leaves that much dead space at the bottom — an off-centre grid, which is the exact defect this node exists to prevent, arrived at from the other side.

The old text said the reserve "assumes the tab bar is SHOWN, and the nine-tab floor above is what guarantees it: hide_tab_bar_if_only_one_tab hides the bar at one tab only, and the floor keeps nine". BOTH halves of that guarantee are gone — the floor and the option — which is why this had to move rather than being left as a harmless constant. Found by `bash tests/wezterm-grid-centering.sh` on the 2026-08-30 quiet sweep, whose static check asserts the very option the reserve depended on.

AN UPVALUE, not a parameter, not a hardcoded 0, and not a read of `config`. Three shapes were tried and the gate rejected two of them, which is the gate doing its job:

```
* `config.enable_tab_bar and … or 0` — CRASHES the harness. This
  block is PURE by contract; the sentinels exist so the gate can
  slice it out and run it with no wezterm and no `config` in scope,
  and that slice is the only thing that tests the arithmetic at all.
* a fifth PARAMETER — silently steals a slot the gate uses. R8's
  pad-independence check calls `grid_padding(w, h, cw, ch, 37, 41)`
  with deliberate junk to prove extra arguments are ignored; a real
  fifth parameter turns that 37 into a 37-pixel reserve. Measured:
  it reddened all nine cases.
* THIS: an upvalue declared ABOVE the opening sentinel. In
  wezterm.lua it is 0. In the sliced harness the name is undefined,
  so it is nil and the measured formula below applies — which is
  what keeps the gate's nine cases meaningful instead of forcing
  nine expected values to be re-derived from the very function they
  are supposed to be checking, the tautology that gate's own header
  warns against.
```

`or`, not a nil-check, and 0 survives it: 0 is TRUTHY in Lua.

```
local avail_w = win_w
```

ABSOLUTE, never incremental. Both axes are derived from the constant window and the cell only; the padding in force is not an input to this function on either axis, so a given font always yields the same padding regardless of zoom history and the grid cannot ratchet smaller over time.

```
local cols = math.floor(avail_w / cell_w)
```

Fit as many whole cells as the available space allows; the gap is whatever those cells leave over, which is in [0, cell).

```
local tot_x = math.floor(avail_w - cols * cell_w)
```

floor() the TOTAL gap before halving it, so the padding applied is never larger than the true gap. Over-padding by even a sub-pixel (possible whenever the cell is not a whole pixel, i.e. fractional DPI) shrinks the usable area below cols * cell and drops a column that the next tick adds back -- a flicker at the tick rate. Under-padding by less than a pixel is invisible and stable.

```
local function center_grid(window)
```

<<< grid-padding

```
local mux_win = window:mux_window()
```

Reach the tab through the MUX WINDOW, not through the active pane and its own tab accessor: an overlay (debug overlay, char select, launcher) makes the active pane a detached one whose tab is nil, which crashed centering mid-flight and left the stale padding in place. mux_window():active_tab() always resolves the real underlying tab, so update-status keeps centering even while an overlay is up.

```
local win = window:get_dimensions()
```

MEASURE, do not reconstruct. get_size() reports {cols, rows, pixel_width, pixel_height} for the grid's own rendered area, so cell = pixels / count is exact and independent of the padding in force -- which is what matters under fractional DPI (the cell is not a whole pixel) and during the multi-frame settle after a font zoom, where reconstructing the cell from window-minus-padding read stale padding and produced a wrong cell size.

```
local overrides = window:get_config_overrides() or {}
```

The padding in force is read for the change comparison at the bottom and for nothing else. It must never reach the arithmetic.

```
if new_pad.left ~= pad.left or new_pad.right ~= pad.right
```

Idempotency guard. Writing the config overrides RE-FIRES the event that called this handler, so writing unconditionally is a feedback loop; writing only on a real change makes idle ticks nearly free.

```
wezterm.on("window-resized", center_grid)
```

Recenter on anything that can change the grid geometry: window or screen size (window-resized, which also covers dragging between differently sized monitors), and config or font-size edits (window-config-reloaded). Registering window-config-reloaded is fine to do more than once -- wezterm.on accumulates handlers.

```
wezterm.on("update-status", center_grid)
```

Interactive font zoom fires NEITHER of the two above. That is the whole reason the periodic tick is a trigger here as well as in prds/02-terminal/02-startup-layout: it catches a zoom within one status_update_interval, which is 5 s (set further down). The guard above keeps these ticks nearly free.

```
config.color_scheme = "Gruvbox dark, hard (base16)"
```

── the palette: read over the wire, not out of a file ─────────────────────

07-multiplexer/04-palette-delivery moved this. WezTerm used to `dofile` ~/.config/wezterm/colors.lua, keep it on the config-reload watch list and rebuild config.colors from it, because OSC emitted inside a pane reached only that pane. Under tmux the palette arrives as OSC 4/10/11 written straight to the client's tty by tinty's tmux-colors.sh hook, which retints the terminal itself — every pane at once, on any emulator that honours it, including one at the far end of an ssh where no colors.lua exists.

So the file, the watch registration and the whole derived tab-bar palette are gone. What is left is the one permitted scheme constant: the no-theme-picked fallback for a checkout that has never applied a theme. It is never the palette — the palette is whatever tinty last pushed — and naming a scheme here as the palette would be wrong within a day.

The `dofile`-never-`require` trap that governed the old reader is not deleted knowledge: it is recorded in prds/memos/tmux-owns-multiplexing-wezterm-keeps-the-chrome.md as history, because the next person to reach for `require` in a WezTerm config needs it and this file no longer has anywhere to say it.

```
config.enable_tab_bar = false
```

── no tab bar at all ───────────────────────────────────────────────────────

07-multiplexer/08-wezterm-reduction, Q8. tmux draws the status bar and owns window addressing; a second bar would be a second answer to "which window am I in". This is the line that makes the old I1 true again with the roles reversed — WezTerm binds nothing that addresses a tab or a pane, because it no longer has either.

```
config.font = wezterm.font_with_fallback({
```

── R1: font ────────────────────────────────────────────────────────────────

```
if is_mac then
```

Search the per-user font dir so a freshly installed font resolves before the system font cache refreshes.

```
config.window_decorations = "RESIZE"
```

── R7, R8, R9: the appearance baseline ─────────────────────────────────────

```
config.window_background_opacity = 0.95
```

The translucent tint is the active scheme's base00 by construction: config.colors.background (with a theme) or the fallback scheme's own base00 (without) — never pure black, never a constant.

```
config.macos_window_background_blur = 30
```

macOS frosts the desktop directly behind the translucent cell colour; there is no WezTerm image layer.

```
config.window_padding = { left = 0, right = 0, top = 0, bottom = 0 }
```

Zeroed BECAUSE prds/02-terminal/07-grid-centering owns padding at runtime (finding T-4): the grid is an integer number of cells and the sub-cell remainder is pushed into symmetric padding there. Until that node lands the remainder sits as a gap on the right and bottom — expected, not a bug here.

```
config.adjust_window_size_when_changing_font_size = false
```

By default WezTerm resizes the OS window to land on a whole number of cells; a fullscreen window cannot grow, so it leaves a large gap instead and appears to change size. Off = the window stays put and the grid reflows.

```
config.front_end = "OpenGL"
```

OpenGL, not WebGpu: transparency plus the OS backdrop blur have the same backend sensitivity the old layered background had. fps capped at 60: uncapping to 255 let WezTerm present every redraw at up to 255 Hz, which with the status repaint and cursor blink kept the GPU churning for no visible benefit.

```
config.enable_kitty_keyboard = false
```

Matched pair with nushell's `use_kitty_protocol = false` (prds/04-shell/01-core-config): with it on, reedline fires the kitty support query at startup and the pty returns the reply too late to consume, leaking `^[[?...u` over the prompt. Enabling only the WezTerm half reproduces the leak and buys nothing.

```
config.status_update_interval = 5000
```

The one tick that drives the tab reconcile, the grid centering and the clock. At 1 s it repainted the bar every second for a minute-resolution clock.

```
config.disable_default_key_bindings = true
```

── the keys that are still WezTerm's ───────────────────────────────────────

07-multiplexer/08-wezterm-reduction emptied this table of everything that addressed a tab, a pane or the palette. F5 (window/pane jump), F6 (theme toggle) and Ctrl+Shift+X (copy mode) are tmux bindings now — WezTerm must pass those keys THROUGH, which is exactly what binding nothing achieves — and Ctrl+Shift+Q went with the nine-tab floor it existed to defeat.

What is left is local chrome and nothing else: the capsule wrappers, paste, and the copy-or-interrupt Ctrl+C. Mouse selection is deliberately still WezTerm's (tmux's `mouse` option stays off), which is what keeps that last binding meaningful. WezTerm's DEFAULT bindings are switched off, and that is the load-bearing half of this section. `show-keys` on a stock config lists ActivateTab, ActivateTabRelative and SplitVertical/Horizontal — a full second set of window and pane keys, shipped, that no line of this file ever wrote. Left on, the epic's invariant ("WezTerm binds nothing that addresses a tab or a pane") would be false out of the box and untestable, because the bindings that break it are not in the file you would read to check.

Everything genuinely local is re-added below by hand: fullscreen, font size, the macOS clipboard keys and quit. Deleting a default is cheap; discovering one silently shadowing a tmux key is not.

```
{ key = "Enter", mods = "ALT", action = act.ToggleFullScreen },
```

── the defaults worth keeping, re-added by hand ──────────────────────── Fullscreen, font size and the macOS clipboard keys: all four are about this window on this desk, and none of them addresses a tab or a pane.

```
{ key = "q", mods = "SUPER", action = act.QuitApplication },
```

window_decorations = "RESIZE" leaves no titlebar close button, so the only way out of the application is a key. This replaces the Ctrl+Shift+Q that existed to defeat the nine-tab floor.

```
{ key = "d", mods = "CTRL|SHIFT", action = act.SendString("capsule\r") },
```

prds/01-capsule/01-container-lifecycle R8: thin wrappers over the one capsule CLI. SendString, not a spawn, because the pane's cwd is unreadable from Lua on this build (pane:get_current_working_directory() is absent from wezterm 20240203 — see the R10 comment above): the command is delivered to the pane's shell, whose cwd IS the pane's directory. One code path by construction — the binding types exactly the invocation a hand would. \r, not \n: reedline submits on carriage return. Known and accepted: the string lands wherever the pane's input goes, so a non-empty prompt line or a running TUI receives it as keystrokes — that is the wrapper being thin, not a bug to guard.

```
{ key = "s", mods = "CTRL|SHIFT", action = act.SendString("capsule recent\r") },
```

prds/01-capsule/04-recent-workspaces R2: the recents picker, in this pane and in a new tab. Both keys are thin wrappers over the one CLI (the epic's one-entry-path acceptance); `capsule recent` owns the store, the picker screen and the mount.

Ctrl+Shift+S is the Ctrl+Shift+D shape: SendString into this pane, whose shell has the TTY tv needs.

Ctrl+Shift+O is SpawnCommandInNewTab, and deliberately NOT "spawn a tab, then send text into it": a pane that was created this instant has no shell reading its pty yet, so typed input would race the shell's startup. Making the picker the tab's PROGRAM removes the race. nushell --execute runs the command and then stays interactive, so an aborted pick leaves exactly the plain tab Ctrl+Shift+T would have given, and $nu.is-interactive is TRUE while --execute runs (measured on nushell 0.114.1, 2026-08-23; it is false under -c) so the picker's own TTY guard passes.

nu_config and nu_env are 06-launchd-path's locals, reused and not respelled: SpawnCommandInNewTab replaces default_prog, so both config paths have to be named a second time, and taking them from the one source is the difference between a reuse and two spellings that drift. The spawn resolves `nu` through config.set_environment_variables.PATH, the same seeding default_prog depends on under a GUI launch -- if that ever stops applying to a pane spawn, the symptom is the launchd-path one: "No viable candidates found in PATH" in a tab that stays open.

Ctrl+Shift+T keeps WezTerm's SpawnTab and the tab reconciler's manual new-tab path (finding C-1). Either key's extra tab is adopted by the nine-tab floor, never closed by it.

```
action = act.SpawnCommandInNewWindow({
```

A new WINDOW, not a new tab: there is no tab bar any more and WezTerm addresses no tabs (08-wezterm-reduction). The picker runs nushell directly rather than through tmux-main, because it is a one-shot `--execute` that should exit with the picker, not a second attach to the session you are already in.

```
{ key = "v", mods = "CTRL", action = act.PasteFrom("Clipboard") },
```

CTRL-V: native paste. Sends the clipboard as a bracketed paste, which is how text reaches both the shell and a running program (Claude, nvim). No subprocess — and it is what makes clipboard-based dictation land in the terminal.

```
{
```

CTRL-C copies when a selection exists, otherwise falls through to the pty as a normal interrupt (SIGINT) so the key keeps its terminal meaning. The fallthrough is the point: the platform-native copy shortcut without ever costing an interrupt.

```
config.mouse_bindings = {
```

── 04-copy-mode: the two mouse bindings ──────────────────────────────────── CTRL-ALT-SUPER + left-drag moves the whole OS window. window_decorations is "RESIZE" (01-appearance), so StartWindowDrag is the ONLY handle for repositioning; the deliberately heavy modifier combo keeps it from stealing ordinary clicks and selection drags. SUPER is the Cmd key.

```
{
```

CTRL + left-click opens the hyperlink under the cursor. mouse_reporting = true keeps it working while an application is capturing the mouse (DECSET 1002/1006) — nvim and other full-screen TUIs do — because without the flag WezTerm forwards the click to the application and nobody opens the URL. Plain clicks still reach the application.
