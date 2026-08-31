# spec02 — `tests/wezterm-f5-tab-select.sh`, the wave-3 registration, and the manual rows

The gate that proves spec01's key table statically and by probe, its
registration in the wave-3 gates cell, and the rewrite of the **stale T.3
row** in `gates/manual/wave3.md` — the row there today describes the
dropped pane-letter overlay and instructs the human to confirm an L-11 fix
that must not exist (R5: unreachable, not fixed).

**Est:** 1h

**Footprint:** `tests/wezterm-f5-tab-select.sh` (create),
`gates/waves.tsv` (append one command to the **wave-3** gates cell —
shared file, held by the E.1 lane this round; land only when no other lane
holds it), `gates/manual/wave3.md` (replace the one T.3 row with six)

## The gate script

House pattern, inherited from `tests/wezterm-startup-layout.sh` and not
re-derived: `set -u`, source `gates/lib.sh`, `GREP=/usr/bin/grep` (`grep`
in this environment is a shell function over ugrep), scratch `HOME` from
`gates_tmpdir`, `snapshot_paths`/`assert_unchanged` over the live
`~/.config/wezterm` files, stage flags `--static`/`--probe` with no-arg
running both, every check messaged with what failed and its R number.

`SRC=$REPO/home/dot_config/wezterm/wezterm.lua`.

No GUI is launched: the mode itself acts only on a live session, and the
behavioral half is the manual rows below.

### `--static` — greps over the source file

- `local JUMP_TIMEOUT_MS = 5000` present (R1).
- The F5 entry: `key = "F5"` present; `act.ActivateKeyTable(` present;
  `name = "jump_mode"`, `one_shot = true`, `until_unknown = true`,
  `timeout_milliseconds = JUMP_TIMEOUT_MS` all present (R1).
- The digit loop runs over the floor: `for i = 1, TAB_COUNT` appears
  exactly once (the reconciler has no such loop, so one hit is the table
  builder), and `act.ActivateTab(i - 1)` present (R1, epic I1).
- The letter loop: `for i = 1, 26` and `string.char(96 + i)` present, and
  `act.Nop` present (R2).
- R2's reason survives as a comment: `without eating the keystroke`
  present.
- R5's record survives as written: `L-11` present AND `unreachable`
  present on the same comment block; `audible_bell = "Disabled"` appears
  exactly once; `visual_bell` never appears outside a comment (reuse
  `tests/live-bugs.sh`'s `grep -vc '^ *--'` shape).
- R3: exactly one `set_right_status` call in the file — the clock stays
  the only status writer, no legend came back.
- 0 hits for each of `PaneSelect` (epic I3, R6), `paint_labels`,
  `unpaint_labels`, `PANE_ALPHABET`, `pane_labels`, `get_lines_as_text`,
  `"\a"` (the dropped half), `#[0-9a-fA-F]{6}` (epic acceptance).
- Census: `git ls-files home/dot_config/wezterm/` is exactly
  `wezterm.lua`.

### `--probe` — the real binary loads the real file

Precondition `chk`: `wezterm` on PATH; record the version (the epic pins
`20240203-110809-5046fc22`). With `HOME` at the scratch dir:

1. `ls-fonts --list-system` exits 0, stderr free of
   `not a valid Config field` and of `Configuration Error`.
2. `show-keys --lua` into a file, then:
   - the F5 row: `one_shot = true`, `until_unknown = true`,
     `timeout_milliseconds = (5000)` each appear exactly once (only F5
     pushes a table, so once is the F5 row). The printer writes
     `name =  'jump_mode'` with two spaces — match `'jump_mode'` alone,
     never the whole row.
   - all nine digit rows, exact-match per row:
     `{ key = '1', mods = 'NONE', action = act.ActivateTab(0) }` through
     `ActivateTab(8)`. `mods = 'NONE'` is what keeps these distinct from
     WezTerm's own `SUPER`/`CTRL|SHIFT` digit defaults (R1). Digits do not
     shift-fold; the fold note in `tests/wezterm-startup-layout.sh`
     applies only to letters with CTRL|SHIFT, of which this table has
     none.
   - `act.Nop` appears exactly 27 times in the dump — Escape plus 26
     letters; no default binding uses `Nop` on this build (measured at
     spec time), so the count is the whole R2 surface.
   - `action = act.ActivatePaneDirection` appears exactly 4 times, on
     `SHIFT|CTRL` arrow rows — R4's "present and unshadowed", checked
     mechanically rather than trusted.
   - `'F6'` and the `'Q'`/`'CTRL'` row still present — no regression on
     T.1's or T.2's keys.

## `gates/waves.tsv`

Append ` | external bash tests/wezterm-f5-tab-select.sh` to the **wave-3**
gates cell (the row whose tasks include `T.3`). One cell, one row, nothing
else in the file.

## `gates/manual/wave3.md`

**Replace** the existing `**T.3**` row (it says "press the letter painted
in the second pane" and carries the L-11 parenthetical — both describe the
design Q2 dropped) with six rows in the file's PASS/FAIL style, one per
PRD acceptance box. All boxes `[ ]` — a pre-ticked box is the failure
`gates/manual-coverage.sh` exists to catch.

The first row's opening phrase is **pinned verbatim**:
`gates/manual-coverage.sh` hand-carries `"the F5 jump landing on the right
pane"` in `R3_CHECKS` and goes red without it. That file belongs to
another node; keep the phrase, which is still true — the digit lands focus
in that tab's pane.

- **T.3** — the F5 jump landing on the right pane. Press `F5`, then `3`.
  PASS: focus is on tab 3 and the next keystroke types into that tab's
  pane — the mode has popped. FAIL: the wrong tab, the next keystroke
  swallowed (the mode still armed), or anything painted on screen.
- **T.3** — a mistyped letter cancels clean. At a shell prompt press `F5`
  then `x`; repeat in nvim insert mode. PASS: no character inserted in
  either, no bell, next keystroke types normally. FAIL: a character leaks
  (the `until_unknown` fall-through R2 exists to stop), or any bell.
  (Silence here is the design: the letter's only job is to cancel — L-11
  is unreachable, not fixed.)
- **T.3** — `Escape` cancels. Press `F5`, then `Escape`. PASS: nothing
  activates, the next keystroke types normally. FAIL: a tab switch, or a
  swallowed next keystroke.
- **T.3** — the misfire timeout. Press `F5`, wait 6 s, then type. PASS:
  the keystroke types normally — the table expired on its own. FAIL: the
  keystroke swallowed or a tab switch.
- **T.3** — pane movement is WezTerm's own. Split a tab, press
  `Ctrl+Shift+`arrow in each direction. PASS: focus moves between panes.
  FAIL: nothing happens — something this epic binds is shadowing the
  default (R4).
- **T.3** — no modal, ever. In a split tab and in a single-pane tab, run
  `F5`+digit, `F5`+letter, `F5`+`Escape`. PASS: at no point is a modal or
  overlay on screen. FAIL: any overlay, or anything that must be
  dismissed (epic I3).

## Acceptance

- [x] `bash tests/wezterm-f5-tab-select.sh` runs both stages green on this
      machine; each stage also runs alone via its flag.
- [x] The wave-3 row of `gates/waves.tsv` names the script;
      `bash gates/wave-status.sh` still parses the registry.
- [x] `bash gates/manual-coverage.sh` stays green: the six `T.3` rows all
      `[ ]`, the `R3_CHECKS` phrase matched, no duplicate task id.
- [x] `/usr/bin/grep -c 'letter painted' gates/manual/wave3.md` returns 0
      — the stale row is gone, not appended-around.
- [x] `bash tests/wezterm-appearance.sh` and
      `bash tests/wezterm-startup-layout.sh` stay ALL PASS.

## Verify

```sh
bash tests/wezterm-f5-tab-select.sh
bash gates/wave-status.sh >/dev/null && echo registry-ok
bash gates/manual-coverage.sh
/usr/bin/grep -c 'letter painted' gates/manual/wave3.md || true   # want 0
bash tests/wezterm-appearance.sh
bash tests/wezterm-startup-layout.sh
```
