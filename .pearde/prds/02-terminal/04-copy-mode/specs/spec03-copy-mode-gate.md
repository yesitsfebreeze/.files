# spec03 — `tests/wezterm-copy-mode.sh`, the wave-4 registration, and the manual rows

The gate that proves spec01 and spec02 statically and by probe, its
registration in the wave-4 gates cell, and the T.4 rows in
`gates/manual/wave4.md` — the GUI-only half of the acceptance. Land after
spec01 and spec02: the gate greps what they wrote.

**Est:** 0.75h

**Footprint:** `tests/wezterm-copy-mode.sh` (create), `gates/waves.tsv`
(append one command to the **wave-4** gates cell — shared file; land only
when no other lane holds it), `gates/manual/wave4.md` (append eight T.4
rows)

## The gate script

House pattern, inherited from `tests/wezterm-startup-layout.sh` and not
re-derived: `set -u`, source `gates/lib.sh`, `GREP=/usr/bin/grep` (`grep`
in this environment is a shell function over ugrep), scratch `HOME` from
`gates_tmpdir`, `snapshot_paths`/`assert_unchanged` over the live
`~/.config/wezterm` files, stage flags `--static`/`--probe` with no-arg
running both, every check messaged with what failed and its R number.

`SRC=$REPO/home/dot_config/wezterm/wezterm.lua`,
`CMD=$REPO/home/dot_config/nushell/copymode.nu`.

No GUI is launched: copy mode, paste, the mouse bindings and the user-var
route act only on a live session; the behavioral half is the manual rows
below.

### `--static` — greps over the source files

Over `$SRC`:

- R1: `enter_copy_mode` defined; `copy_selecting[pane:pane_id()] = nil`,
  `act.ClearSelection` and `act.ActivateCopyMode` all present, and the
  `ClearSelection` line number precedes the `ActivateCopyMode` line number
  (each appears once — first-occurrence comparison, the
  `mark_closing`-before-close shape from `tests/wezterm-startup-layout.sh`).
- R2: `wezterm.gui.default_key_tables().copy_mode` present;
  `table.insert(copy_mode,` present; exactly one `config.key_tables`
  assignment, carrying both `copy_mode = copy_mode` and
  `jump_mode = jump_mode_keys`.
- R2's reason survives as a comment: `Extension, never replacement`
  present, and the 54-vs-62 measurement note (`62 copy_mode rows`)
  present — the count trap costs a re-measurement every time it is lost.
- R4: `copy_selecting` present; `SetSelectionMode = "Cell"` present;
  `CopyTo("ClipboardAndPrimarySelection")` present; `CopyMode("Close")`
  present.
- R5: exactly one `wezterm.on("user-var-changed"` registration;
  `copymode` present; `opacity` never appears outside a comment (the
  `grep -v '^ *--'` shape from `tests/live-bugs.sh`) — the refusal
  comment naming the wallpaper-opacity decision is the only permitted
  mention.
- R6: the `v`/`CTRL` entry with `act.PasteFrom("Clipboard")` present, no
  callback on that line.
- R7: `get_selection_text_for_pane` present; `act.SendKey` with
  `key = "c"` present; in the Ctrl+C callback the `CopyTo` line precedes
  the `ClearSelection`-after-copy — check the callback contains both.
- R8: exactly one `config.mouse_bindings` assignment; `StartWindowDrag`
  present with `CTRL|ALT|SUPER`; `OpenLinkAtMouseCursor` present;
  `mouse_reporting = true` present.
- Refused names, 0 hits each: `set_background`, `clear_background`,
  `run_bg_script`, `PromptInputLine` (the wallpaper pipeline),
  `PaneSelect` (epic I3), `burrito`, `#[0-9a-fA-F]{6}` (epic
  acceptance). `search_mode` appears at most in comments — the config
  never assigns that table (R3).
- Census: `git ls-files home/dot_config/wezterm/` is exactly
  `wezterm.lua`.

Over `$CMD` (spec02):

- `def copymode` present; `SetUserVar=copymode=` present; `opacity`
  0 hits; `print -n` present (a trailing newline would print a blank line
  into the prompt).
- `source ~/.config/nushell/copymode.nu` appears exactly once in
  `home/dot_config/nushell/config.nu`.

### `--probe` — the real binaries load the real files

Precondition `chk`: `wezterm` on PATH; record the version (the epic pins
`20240203-110809-5046fc22`). With `HOME` at the scratch dir:

1. `ls-fonts --list-system` exits 0, stderr free of
   `not a valid Config field` and of `Configuration Error` — this also
   proves `wezterm.gui.default_key_tables()` is callable at config-eval
   time.
2. `show-keys --lua` into a file, then:
   - the `copy_mode` block (extracted between `    copy_mode = {` and the
     next `    },` at that indent) holds exactly **55** rows — 54 builtin
     plus the added `c`; exactly one row matches
     `key = 'c', mods = 'NONE', action = act.EmitEvent` (callbacks print
     as `EmitEvent 'user-defined-N'` with an unstable N — match the
     pieces, never the number); the block contains 0 hits for
     `Search|NextMatch|PriorMatch|ClearPattern|CycleMatchType` (R3).
   - the `search_mode` block holds exactly **10** rows, and
     `'F', mods = 'CTRL', action = act.Search` prints among the top-level
     rows — the default search entry, present and unshadowed (R3),
     checked mechanically rather than trusted.
   - exactly one `'X'` row in the whole dump:
     `key = 'X', mods = 'CTRL', action = act.EmitEvent`; and
     `act.ActivateCopyMode` appears **0** times — binding `x`/`CTRL|SHIFT`
     replaces all three default `ActivateCopyMode` rows (measured, and the
     shift-fold note in `tests/wezterm-startup-layout.sh` applies: the
     row prints `'X'` with `'CTRL'`, never `SHIFT|CTRL`).
   - exactly one
     `key = 'v', mods = 'CTRL', action = act.PasteFrom 'Clipboard'` row
     (R6; the copy-mode-internal `'v', mods = 'CTRL'` row maps to
     `SetSelectionMode Block`, so the full-row match cannot collide).
   - exactly one `key = 'c', mods = 'CTRL', action = act.EmitEvent` row
     (R7).
   - no regression on T.3/T.2/T.1: `jump_mode` still 36 rows, `act.Nop`
     still exactly 27, the `'F5'`, `'F6'` and `'Q'`/`'CTRL'` rows still
     present.
3. Precondition `chk`: `nu` on PATH. The command's output is
   byte-compared: `nu -n -c "source $CMD; copymode"` against
   `printf '\033]1337;SetUserVar=copymode=MQ==\007'` via `cmp` (R5).

## `gates/waves.tsv`

Append ` | external bash tests/wezterm-copy-mode.sh` to the **wave-4**
gates cell (the row whose tasks include `T.4`). One cell, one row, nothing
else in the file.

## `gates/manual/wave4.md`

Append eight rows in the file's PASS/FAIL style, one per PRD acceptance
box, task id **T.4**. All boxes `[ ]` — a pre-ticked box is the failure
`gates/manual-coverage.sh` exists to catch, and T.4 must appear in no
other wave file.

- **T.4** — copy mode enters clean. Select some text with the mouse, then
  press `Ctrl+Shift+X`. PASS: copy mode opens with no selection carried
  in, and `h`/`j`/`k`/`l`, `w`/`b`, `g`/`G` all move the cursor. FAIL: a
  stale selection visible on entry, or any builtin motion dead.
- **T.4** — the `c` cycle, including the blank-cell start. Press `c` on a
  blank region, move onto text, press `c` again; paste elsewhere. Then
  re-enter and run one `c`-`c` cycle starting on text. PASS: both cycles
  copy the swept range to the clipboard and close copy mode; the second
  press never re-anchors. FAIL: a desynced toggle (the second `c` starts
  a new selection), or nothing on the clipboard.
- **T.4** — copy mode has no search, and normal mode does. In copy mode
  press `/`. Leave, press `Ctrl+Shift+F`. PASS: `/` does nothing at all;
  `Ctrl+Shift+F` opens the search prompt over the pane. FAIL: `/` opens
  anything, or the search prompt fails to appear (something shadowed the
  default).
- **T.4** — the shell entry. Run `copymode` at a host prompt. PASS: that
  pane drops into copy mode exactly as `Ctrl+Shift+X` does. FAIL:
  escape bytes printed as text, or nothing happens.
- **T.4** — `Ctrl+V` is a bracketed paste. Copy a two-line snippet; paste
  at a shell prompt, then into nvim insert mode. PASS: both receive it in
  one piece, nvim without auto-reindenting it. FAIL: the second line
  executes at the prompt, or nvim staircases the indent.
- **T.4** — `Ctrl+C` copies or interrupts, never both. With text
  selected, press `Ctrl+C`, paste elsewhere; then run `sleep 100` and
  press `Ctrl+C` with nothing selected. PASS: the selection lands on the
  clipboard and clears; the sleep dies to SIGINT. FAIL: an interrupt
  fired while a selection existed, or a copy eaten with nothing selected.
- **T.4** — the window drag handle. Hold `Ctrl+Alt+Cmd` and drag with
  the left button; then do an ordinary left-drag. PASS: the OS window
  moves; the plain drag still selects text. FAIL: the window stays put,
  or plain drags stop selecting.
- **T.4** — the link opener under a mouse-capturing TUI. Open nvim with
  its mouse enabled, display a URL, `Ctrl`+left-click it; then plain-click
  elsewhere. PASS: the browser opens the URL, and the plain click still
  reaches nvim. FAIL: the click is swallowed by nvim (the
  `mouse_reporting` flag missing), or plain clicks stop reaching the app.

## Acceptance

- [x] `bash tests/wezterm-copy-mode.sh` runs both stages green on this
      machine; each stage also runs alone via its flag.
- [x] The wave-4 row of `gates/waves.tsv` names the script;
      `bash gates/wave-status.sh` still parses the registry.
- [x] `bash gates/manual-coverage.sh` stays green: the eight `T.4` rows
      all `[ ]`, no duplicate task id across wave files.
- [x] `bash tests/wezterm-appearance.sh`,
      `bash tests/wezterm-startup-layout.sh` and
      `bash tests/wezterm-f5-tab-select.sh` stay ALL PASS.

## Verify

```sh
bash tests/wezterm-copy-mode.sh
bash tests/wezterm-copy-mode.sh --static
bash tests/wezterm-copy-mode.sh --probe
bash gates/wave-status.sh >/dev/null && echo registry-ok
bash gates/manual-coverage.sh
bash tests/wezterm-appearance.sh
bash tests/wezterm-startup-layout.sh
bash tests/wezterm-f5-tab-select.sh
```
