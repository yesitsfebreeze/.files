---
est: 0.75h
footprint:
  - tests/wezterm-tab-content-state.sh
  - gates/waves.tsv
  - gates/manual/wave4.md
---

# spec02 — the T.6 gate, its wave-4 registration, and the manual rows

The gate that proves spec01 statically and by probe, its registration in the
wave-4 gates cell, and the T.6 rows in `gates/manual/wave4.md` — the GUI-only
half of the PRD's acceptance. Land after spec01: the gate greps what it wrote.

## The gate script

House pattern, inherited from `tests/wezterm-copy-mode.sh` and not
re-derived: `set -u`, source `gates/lib.sh`, `GREP=/usr/bin/grep` (`grep`
here is a shell function over ugrep), scratch `HOME` from `gates_tmpdir`,
`snapshot_paths`/`assert_unchanged` over the live `~/.config/wezterm` files,
stage flags `--static`/`--probe` with no-arg running both, every check
messaged with what failed and its R number.

`SRC=$REPO/home/dot_config/wezterm/wezterm.lua`.

No GUI is launched: occupancy is a live-session property, so the behavioural
half is the manual rows below.

### `--static` — greps over `$SRC`

Extract the block once with
`sed -n '/── 05-tab-content-state/,/── R5: the tab title/p'` and run the
block-scoped checks on that, the file-scoped ones on `$SRC`.

- R1: `pane_programs` and `tab_is_occupied` both defined; `tab.panes`
  read in `tab_is_occupied`; the function returns `true` from inside the
  loop and `false` after it — the OR, not an AND.
- R2: `learn_pane_programs` registered on exactly four events —
  `update-status`, `window-config-reloaded`, `pane-focus-changed`,
  `window-focus-changed` — one registration each.
- R3: exactly one `wezterm.on("format-tab-title"` in the whole file; the
  handler contains `AnsiColor = "Silver"`; it returns the bare label for
  `tab.is_active`. `colors.tab_bar` still carries exactly the six keys
  `01-appearance` R4 wrote and no seventh.
- R4, and this is the check the requirement turns on: **no shell name in
  the block.** 0 hits for `"(nu|zsh|bash|fish|sh)"` *within the extracted
  block*. File-wide is not assertable — the F6 binding's `"sh", "-lc"`
  (`01-appearance` R11) is a landed line — and asserting it anyway is the
  unsatisfiable-clause defect T.4's `opacity` box already recorded.
  Also 0 hits in the block for `os.getenv("SHELL")`, `/etc/shells`,
  `dscl`, `getent`, `OSC 133`, `633` and `SetUserVar`.
- R4's reason survives as a comment: the block still names OSC 133/633 as
  deliberately off and points at `04-shell/01-core-config`, and still
  records that `os.getenv("SHELL")` is nil under launchd. Both are
  measurements that cost a session to make; losing the comment costs the
  next reader the same session.
- R5: `get_foreground_process_name` appears exactly once in the file, inside
  `learn_pane_programs`, and `pcall` appears on a line at or before it
  within that function.
- R6: `wezterm.GLOBAL.tab_pane_program` assigned exactly once; the
  rebuild-and-write shape present (`local out = {}` inside
  `learn_pane_programs`) and no `known[` assignment — a write through a
  GLOBAL copy is the bug the `set_slots` comment above already paid for.
  No `local` table in the block holds baselines.
- Refused names: 0 hits for `mux.all_panes`, `mux.get_pane`, `PaneSelect`,
  `burrito` and `#[0-9a-fA-F]{6}` over the whole file. Grep
  `mux.all_panes`, never the bare substring — `retint_all_panes` matches it
  three times. `get_current_working_directory` is checked on non-comment
  lines only (`grep -v '^ *--'`), where it must be 0; R10's comment carries
  it twice on purpose.
- Census: `git ls-files home/dot_config/wezterm/` is exactly `wezterm.lua`.

### `--probe` — the real binaries load the real file

Precondition `chk`: `wezterm` on PATH; record the version (the epic pins
`20240203-110809-5046fc22`). With `HOME` at the scratch dir:

1. `ls-fonts --list-system` exits 0, stderr free of
   `not a valid Config field` and of `Configuration Error`.
2. **R5, as a gate rather than as a sentence.** Resolve the GUI binary
   beside the `wezterm` on PATH (`readlink -f`, then `wezterm-gui` in the
   same directory) and run `strings` over it:
   `get_foreground_process_name` must appear **more than 0** times and
   `get_current_working_directory` exactly **0** times. The negative control
   is what makes the positive result mean anything — a `strings` invocation
   that matched everything would pass the first assertion on any binary.
   Precondition `chk` on both `strings` and the sibling binary; skip with a
   message rather than failing when either is absent, because the check is
   about the installed build and not about the repo.
3. No regression on T.1–T.4 from the same file: `show-keys --lua` still
   prints `jump_mode` at 36 rows, `act.Nop` exactly 27 times, `copy_mode`
   at 55 rows, and the `F5`, `F6`, `'X'`/`'CTRL'`, `'Q'`/`'CTRL'`,
   `v`/`CTRL` rows.

## `gates/waves.tsv`

Append ` | external bash tests/wezterm-tab-content-state.sh` to the
**wave-4** gates cell (the row whose tasks include `T.6`). One cell, one
row, nothing else in the file.

## `gates/manual/wave4.md`

Append six rows in the file's PASS/FAIL style, task id **T.6**. All boxes
`[ ]` — a pre-ticked box is the failure `gates/manual-coverage.sh` exists to
catch — and T.6 must appear in no other wave file.

- **T.6** — every tab starts dim. Launch WezTerm from the Dock and look at
  the bar without touching anything. PASS: all nine digits render in the
  inactive-tab colour, and tab 1 differs from the rest only by having
  focus. FAIL: any background tab lit at startup, which means a baseline was
  learned against something other than the spawned shell.
- **T.6** — a command lights its tab, and exiting dims it again. In tab 3
  run `htop` (or `sleep 120`), switch to tab 1, wait. Then quit the command
  and wait again. PASS: tab 3's digit brightens within one
  `status_update_interval` (5 s) and returns to the dim colour within one
  interval of the command exiting. FAIL: no change, a change that needs a
  keystroke in tab 3, or a tab that stays lit after the command is gone.
- **T.6** — the OR over panes. In tab 4, split the pane with WezTerm's own
  default `Ctrl+Alt+Shift+"` (measured from `show-keys --lua`; this config
  binds no split key of its own), run `sleep 120` in the new pane, leave the
  sibling at its prompt, and switch away. PASS: tab
  4 is lit while one of its two panes is idle. FAIL: the tab stays dim, which
  means the classification read only the active pane.
- **T.6** — occupancy does not repaint the focused tab. With a long command
  running in the focused tab, compare it against the same tab focused and
  idle. PASS: the focused tab looks identical either way — background says
  focus, foreground says busy, and the two never fight. FAIL: the focused
  tab changes appearance, which is R3's separate-signal clause broken.
- **T.6** — an outside kill decays to dim. In tab 5 run `sleep 300`, find
  the process from another tab and `kill -9` it; wait one interval. Then
  repeat against the pane's *shell* PID. PASS: both end dim within one
  interval — the killed command hands the foreground back to the shell, and
  the killed shell closes its pane, whereupon the nine-tab floor refills the
  slot with a fresh one. FAIL: either case leaves a lit tab.
- **T.6** — a theme switch recolours both states. With one tab lit and the
  rest dim, press `F6`, then press it back. PASS: both the dim and the lit
  digits change with the scheme, in every open window, with no edit to any
  file. FAIL: either state keeps its old colour, or only one window
  retints. Judgement row: also say whether the lit digit is legible against
  the bar and does not out-shout the focused tab (R3). If it does not read
  well, the fix is the ANSI slot in `format-tab-title`, not a hex value.

## Acceptance

- [x] `bash tests/wezterm-tab-content-state.sh` runs both stages green on
      this machine; each stage also runs alone via its flag. Ran all three:
      `wezterm-tab-content-state gate: ALL PASS` for no-arg, `--static` and
      `--probe`.
- [x] The `--probe` stage's R5 assertion fails when pointed at a binary
      without the accessor — demonstrate the negative control fires by
      running the same `strings` pattern against
      `get_current_working_directory` and quoting the 0. Ran, against
      `/Applications/WezTerm.app/Contents/MacOS/wezterm-gui` (resolved as
      the sibling of `readlink -f $(command -v wezterm)`):
      `get_foreground_process_name` → **4** hits,
      `get_current_working_directory` → **0** hits. Both are asserted in
      the gate, and the gate prints them:
      `PASS  probe: get_foreground_process_name is present … (got 4 hits,
      want >0) (R5)` and `PASS  probe: negative control —
      get_current_working_directory is absent from the same binary (got 0
      hits, want 0) (R5)`. The 0 is what proves the pattern discriminates:
      an invocation that matched everything would have passed the first
      assertion on any binary and failed this one.
- [x] The wave-4 row of `gates/waves.tsv` names the script;
      **Closed by the orchestrator on the transition.** Appended `| external bash tests/wezterm-tab-content-state.sh` to the wave-4 gates cell, then verified: `bash gates/wave-status.sh` → `4  PENDING  7/18  8 registered` (seven before), exit 0, and `bash tests/wezterm-tab-content-state.sh` → `ALL PASS`.
      `bash gates/wave-status.sh` still parses the registry.
      **Left open: `gates/waves.tsv` is the orchestrator's file** — the
      verbatim segment to append is reported with this lane's result. What
      was proved here instead: `bash gates/wave-status.sh` exits 0 against
      the registry as it stands (`registry-ok`), and
      `bash tests/wezterm-tab-content-state.sh` is ALL PASS, so the
      registration is the only thing outstanding.
- [x] `bash gates/manual-coverage.sh` stays green: the six `T.6` rows all
      `[ ]`, no duplicate task id across wave files.
      **Closed by the orchestrator on the transition**, which appended the
      six rows verbatim and re-ran the check: `bash gates/manual-coverage.sh`
      → exit 0, 19 PASS / 0 FAIL, with
      `entries: every checklist box names a task id carried by a board node
      (unknown: none)` and
      `boxes: no checklist box is ticked in the repo (ticked: none)`;
      `grep -c 'T\.6' gates/manual/wave4.md` → 6.
      The append is not yet safe from being clobbered: `03-editor/09-lsp` is
      still `claimed` and writes the same file directly, having been briefed
      before this carve-out existed. The orchestrator re-checks both id sets
      on that node's transition and re-appends if either is missing.

      Original note, kept as the record:
      **Left open: `gates/manual/wave4.md` is the orchestrator's file** —
      `03-editor/09-lsp` is appending to it in this same session, so it is
      serialised there. The six rows to append are reported with this lane's
      result, all boxes `[ ]`. What was proved here instead:
      `bash gates/manual-coverage.sh` exits 0 as the file stands, and `T.6`
      appears in **no** wave file today
      (`grep -rc 'T\.6' gates/manual/` → 0 everywhere), so no duplicate can
      arise from the append.
- [x] `bash tests/wezterm-appearance.sh`,
      `bash tests/wezterm-startup-layout.sh`,
      `bash tests/wezterm-f5-tab-select.sh` and
      `bash tests/wezterm-copy-mode.sh` stay ALL PASS. Ran: all four ALL
      PASS, plus `bash tests/wezterm-grid-centering.sh` (T.7) ALL PASS.

## Verify and Proof

```sh
bash tests/wezterm-tab-content-state.sh
bash tests/wezterm-tab-content-state.sh --static
bash tests/wezterm-tab-content-state.sh --probe
bash gates/wave-status.sh >/dev/null && echo registry-ok
bash gates/manual-coverage.sh
bash tests/wezterm-appearance.sh
bash tests/wezterm-startup-layout.sh
bash tests/wezterm-f5-tab-select.sh
bash tests/wezterm-copy-mode.sh
```
