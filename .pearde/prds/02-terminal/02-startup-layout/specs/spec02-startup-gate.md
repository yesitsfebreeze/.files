# spec02 — `tests/wezterm-startup-layout.sh`, the wave-3 registration, and the manual rows

The gate that proves spec01's machinery statically and by probe, its
registration in the wave-3 gates cell, and the interactive checks only a
human at the GUI can run. The behavioral half (tabs actually refilling,
focus actually preserved) needs a live GUI session, so it lives in
`gates/manual/wave3.md` per the house split — the same split T.1 used for
retint and F6.

**Est:** 1.75h

**Footprint:** `tests/wezterm-startup-layout.sh` (create),
`gates/waves.tsv` (append one command to the **wave-3** gates cell —
shared file; land only when no other lane holds it),
`gates/manual/wave3.md` (add the T.2 rows)

## The gate script

House pattern, inherited from `tests/wezterm-appearance.sh` and not
re-derived: `set -u`, source `gates/lib.sh`, `GREP=/usr/bin/grep`
(`grep` in this environment is a shell function over ugrep), scratch
`HOME` from `gates_tmpdir`, the live `~/.config` never written.
Registered as `external`; give every check a message naming what failed.

`SRC=$REPO/home/dot_config/wezterm/wezterm.lua`. Stage flags with no-arg
running all.

### `--static` — greps over the source file

- `TAB_COUNT = 9` present (R1).
- Floor semantics: `#want < TAB_COUNT` present (the dead-slot-past-the-
  floor drop and the pad loop, R1).
- `wezterm.GLOBAL.tab_slots` and `wezterm.GLOBAL.tab_closing` present;
  `tostring(` applied to window ids (string keys, R5).
- `local repairing = false` present, and no `GLOBAL` on that line (the
  guard is module-local by design, R7).
- `pcall` present inside the repair path, and the failure log message
  `tab reconcile failed` present (R8).
- `MoveTab(` present, and the skip-guard `~= pos` present (R3, R9).
- Exactly 4 hits for `, reconcile_tabs)`, and one each of
  `"pane-focus-changed"`, `"window-focus-changed"`, `"update-status"`,
  `"window-config-reloaded"` on those registration lines (R11, R13).
- `gui-startup` handler: `spawn_window(cmd or {})`,
  `wezterm.GLOBAL.tab_slots = nil`, `toggle_fullscreen` all present (R12).
- `mark_closing` appears **before** `CloseCurrentTab` within the file
  (compare line numbers of first occurrence in the key callback);
  `confirm = false` present (R14).
- 0 hits for `PaneSelect` (epic I3), `center_grid` (T.8's), `burrito`
  (refused), `#[0-9a-fA-F]{6}` (epic acceptance).
- Census: `git ls-files home/dot_config/wezterm/` is exactly
  `wezterm.lua`.

### `--probe` — the real binary loads the real file

Precondition `chk`: `wezterm` on PATH; record the version the probe ran
against (the epic pins `20240203-110809-5046fc22`).

With `HOME` pointed at the scratch dir:

1. `wezterm --config-file "$SRC" ls-fonts --list-system` exits 0, stderr
   free of `not a valid Config field` and of `Configuration Error` — the
   floor block must not break T.1's standalone-load guarantee.
2. `wezterm --config-file "$SRC" show-keys --lua` contains a row with
   `'Q'` and `'CTRL'` — shift folds into the uppercase letter in
   show-keys output, so `q`/`CTRL|SHIFT` in the source prints as
   `Q`/`CTRL`; grepping for `SHIFT|CTRL` would match nothing while
   looking reasonable. The same output still contains `'F6'` (no
   regression on T.1's table).

No GUI is launched: `gui-startup`, the reconciler and the close key act
only on a live session, and running a fullscreen nine-tab window out of a
gate script is the disruption the manual rows exist to avoid.

## `gates/waves.tsv`

Append ` | external bash tests/wezterm-startup-layout.sh` to the
**wave-3** gates cell (the row whose tasks include `T.2`; its cell
currently holds `external bash tests/nushell-core.sh`). One cell, one
row, nothing else in the file.

## `gates/manual/wave3.md`

Add six `**T.2**` rows in the file's PASS/FAIL style, one per PRD
acceptance box:

- **Fresh launch shape** — quit WezTerm, launch it clean. PASS: one
  fullscreen window, tabs titled `1`–`9`, focus on tab 1. FAIL: 16 tabs
  (the re-entrancy failure), any order other than `1..9` (the `1,0,2,3…`
  no-op-move failure), a non-fullscreen window, or focus elsewhere.
- **A dead slot heals in place** — focus tab 5, close tab 3
  (`exit` in it), wait one `status_update_interval` (5 s). PASS: nine
  tabs, the replacement at position 3, focus still on the tab that was
  focused. FAIL: eight tabs, the replacement at the end, renumbered tabs
  after the hole, or focus snapped onto the blank replacement.
- **New windows come up at the floor** — run
  `wezterm cli spawn --new-window` with no key pressed. PASS: the new
  window holds nine tabs at birth (not up to 5 s later). FAIL: a lone
  tab, or nine only after a visible delay.
- **Extra tabs are adopted** — open a tenth tab by hand, wait two ticks
  (≥10 s). PASS: ten tabs still standing. FAIL: the tenth culled — the
  floor became a target.
- **`Ctrl+Shift+Q` closes for real** — press it in a nine-tab window.
  PASS: the whole window closes, no confirmation prompt, no tab refilled
  behind the close. FAIL: a prompt per tab, or the window refilling and
  never dying (the reconciler racing the close).
- **Two windows stay independent** — hold two windows open across
  several ticks, close a tab in each. PASS: each window heals to its own
  nine; neither spawns into the other. FAIL: cross-window refill (the
  shared-slot-map failure R5 exists to prevent).

## Acceptance

Ran 2026-08-22: the gate ALL PASS no-arg and per stage (`--static`,
`--probe`); `gates/wave-status.sh` parses the registry; manual-coverage 0
FAIL with the six rows all `[ ]`; `wezterm-appearance.sh --static` (and the
full run) ALL PASS.

- [x] `bash tests/wezterm-startup-layout.sh` runs all stages green on
      this machine; each stage also runs alone via its flag.
- [x] The wave-3 row of `gates/waves.tsv` names the script;
      `bash gates/wave-status.sh` still parses the registry.
- [x] `bash gates/manual-coverage.sh` stays green with the six new
      `T.2` rows in `gates/manual/wave3.md`, all boxes `[ ]`.
- [x] `bash tests/wezterm-appearance.sh --static` stays green — the
      floor block must not disturb any T.1 invariant it greps for.

## Verify

```sh
bash tests/wezterm-startup-layout.sh
bash gates/wave-status.sh >/dev/null && echo registry-ok
bash gates/manual-coverage.sh
bash tests/wezterm-appearance.sh --static
```
