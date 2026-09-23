# WezTerm

> The local chrome \u2014 font, opacity, launchd PATH.

WezTerm keeps only what is true of this machine; tmux owns multiplexing.

## `wezterm.lua`

```
local wezterm = require("wezterm")
```

WezTerm appearance: font, palette reader, derived tab bar, baseline, clock, F6 theme toggle — prds/02-terminal/01-appearance owns that scope. The self-healing nine-tab floor below is prds/02-terminal/02-startup-layout's; later terminal nodes (F5, copy mode) extend this file.

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

Getting the binary spawned is all this does; env.nu owns PATH inside the shell, and it wins by construction (R5). env.nu `prepend`s ~/.cargo/bin, ~/.opencode/bin and ~/.local/bin, `append`s the Homebrew and system dirs and `uniq`s, so the duplicates this prefix creates collapse and the shell's resolution order is env.nu's under either launch shape. Measured both ways on 0.114.1: the repaired PATH is .cargo/bin:.local/bin:/opt/homebrew/bin:... whether the launch PATH was this prefix or a terminal's inherited one.

```
config.color_scheme = "Gruvbox dark, hard (base16)"
```

── the palette: read over the wire, not out of a file ─────────────────────

07-multiplexer/04-palette-delivery moved this. WezTerm used to `dofile` ~/.config/wezterm/colors.lua, keep it on the config-reload watch list and rebuild config.colors from it, because OSC emitted inside a pane reached only that pane. Under tmux the palette arrives as OSC 4/10/11 written straight to the client's tty by tinty's theme.sh hook, which retints the terminal itself — every pane at once, on any emulator that honours it, including one at the far end of an ssh where no colors.lua exists.

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

Zero, and nothing rewrites it at runtime: the grid is anchored top-left and the sub-cell remainder sits at the right and bottom edges. Centering it (the old `center_grid`) made the whole grid shift whenever fullscreen or a resize changed the remainder.

```
config.adjust_window_size_when_changing_font_size = false
```

By default WezTerm resizes the OS window to land on a whole number of cells; a fullscreen window cannot grow, so it leaves a large gap instead and appears to change size. Off = the window stays put and the grid reflows.

```
config.native_macos_fullscreen_mode = false  -- plus a window-config-reloaded handler
```

Every window goes fullscreen once, when it is created (the handler remembers window ids in `wezterm.GLOBAL`, so a config reload, such as a font pick, never toggles it back). Non-native because macOS's native fullscreen gives each window its own Space: switching windows or monitors then animates a Space change and re-lays the grid mid-slide. Non-native just fills whichever screen the window is on. Moving between the Retina panel (144 dpi) and the QHD monitor (72 dpi) still re-rasterizes the font; that is the dpi change, not the window, and pinning `dpi` would render text at the wrong size on one of them. `Alt+Enter` still toggles fullscreen.

```
config.front_end = "OpenGL"
```

OpenGL, not WebGpu: transparency plus the OS backdrop blur have the same backend sensitivity the old layered background had. fps capped at 60: uncapping to 255 let WezTerm present every redraw at up to 255 Hz, which with the status repaint and cursor blink kept the GPU churning for no visible benefit.

```
config.enable_kitty_keyboard = false
```

Matched pair with nushell's `use_kitty_protocol = false` (prds/04-shell/01-core-config): with it on, reedline fires the kitty support query at startup and the pty returns the reply too late to consume, leaking `^[[?...u` over the prompt. Enabling only the WezTerm half reproduces the leak and buys nothing.

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

SHIFT + left-click opens the hyperlink under the cursor. Three measured facts hold this up. mouse_reporting = true on the duplicate binding keeps it working while an application captures the mouse (DECSET 1002/1006) — tmux (`set -g mouse on`) and nvim do — because a binding without it is never considered there. SHIFT is the `bypass_mouse_reporting_modifiers` default, which strips the modifier before bindings match (wezterm#4536), so the bypass lives on ALT instead. And the click's DOWN stroke is Nopped: binding only Up still ships the press to the program (the mouse docs' "Gotcha on binding an 'Up' event only"), and tmux turns that press into copy-mode selection — the click is eaten. Both halves of the click are consumed in both reporting states.

## Font

The font comes from `~/.local/state/wezterm/font.txt` when that file exists, with the built-in fallback list behind it. The F8 `font` channel (`~/.config/wezterm/font.sh`) writes the file on Enter, and the config's reload watch applies it to every window. Its live preview is OSC 1337 `SetUserVar=font=…` written straight to each tmux client tty, past tmux, which would swallow it; the `user-var-changed` handler turns it into a per-window override, and an empty value, sent on Esc and after Enter, drops the override.
