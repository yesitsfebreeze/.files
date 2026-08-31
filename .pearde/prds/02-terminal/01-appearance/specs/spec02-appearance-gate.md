# spec02 — `tests/wezterm-appearance.sh`, the wave-2 registration, and the manual rows

The gate that proves spec01's file box by box, its row in the wave registry,
and the three live checks a script cannot see. T.1 is wave 2; the wave-2
gates cell in `gates/waves.tsv` currently ends at `tests/dev-image.sh
--static`, and the registry's own header says each wave's tasks add their
gate.

**Est:** 0.75h

**Footprint:** `tests/wezterm-appearance.sh` (create), `gates/waves.tsv`
(append one command to the wave-2 gates cell — **shared with the gates-port
lane**, land only when that lane is not holding the file),
`gates/manual/wave2.md` (extend the T.1 rows)

## The gate script

House pattern, inherited from `tests/theme-switcher.sh` and not re-derived:
`set -u`, source `gates/lib.sh`, `GREP=/usr/bin/grep` always (`grep` here is
a shell function over ugrep), scratch `HOME` from `gates_tmpdir`, the live
`~/.config` never written, stage flags with no-arg running all. Registered
as `external`, so the `--selftest` contract does not apply; still give every
check a message that names what failed.

`SRC=$REPO/home/dot_config/wezterm/wezterm.lua`.

### `--static` — greps over the source file

- 0 hits for `#[0-9a-fA-F]{6}` (R3).
- Exactly one `color_scheme` assignment, value
  `Gruvbox dark, hard (base16)` (R3).
- `dofile` present; the only `require(` is `require("wezterm")`;
  `add_to_config_reload_watch_list` present (R2).
- The essential-key check reads `t.background`, `t.foreground`, `t.ansi`
  (R2 — and the seam floor: the hook refuses to write a file missing
  base00/base05, so reader-need ⊆ writer-guarantee).
- `background_child_process` present; `run_child_process` absent; the F6
  block carries `_theme_toggle` and `theme.nu` (R11).
- `enable_kitty_keyboard = false` (R9).
- Each baseline pair present with its value (R7–R9):
  `window_decorations = "RESIZE"`, `default_cursor_style =
  "BlinkingBlock"`, `window_background_opacity = 0.95`,
  `macos_window_background_blur = 30`, `saturation = 0.85`,
  `brightness = 0.7`, `scrollback_lines = 10000`,
  `audible_bell = "Disabled"`, zeroed `window_padding`,
  `adjust_window_size_when_changing_font_size = false`,
  `front_end = "OpenGL"`, `max_fps = 60`, `animation_fps = 60`,
  `status_update_interval = 5000`, `use_fancy_tab_bar = false`,
  `tab_bar_at_bottom = false`, `show_new_tab_button_in_tab_bar = false`,
  `hide_tab_bar_if_only_one_tab = true`, `line_height = 1.0`.
- Font: `CaskaydiaCove Nerd Font` first in `font_with_fallback`, and both
  `font_dirs` branches (`Library/Fonts`, `.local/share/fonts`) present
  (R1).
- `format-tab-title` returns the literal `"  %d  "` format (R5).
- Clock: `AnsiColor = "Silver"` and `%H:%M` in the right-status handler
  (R10).
- Retint: `tinty_osc` deduped in `wezterm.GLOBAL`, `inject_output` present,
  and the payload builder names OSC codes `4`, `10`, `11`, `12`, `17`, `19`
  (R6).
- Census: `git ls-files home/dot_config/wezterm/` is exactly
  `wezterm.lua`; 0 hits under `home/dot_config/wezterm/` for `config.lua`,
  `wsl-clip-prime`, `background.png`, `solo-window`.

### `--probe` — the real binary loads the real file

Precondition `chk`: `wezterm` on PATH (the epic pins build
`20240203-110809-5046fc22`; record the version the probe ran against in the
output). `fc-list` resolving `CaskaydiaCove Nerd Font` is its own `chk`
(PRD acceptance box 1).

With `HOME` pointed at the scratch dir (which is what makes
`$HOME/.config/wezterm/colors.lua` resolve inside the scratch), run
`wezterm --config-file "$SRC" ls-fonts --list-system` three times:

1. no `colors.lua` — exit 0, stderr free of `not a valid Config field` and
   of `Configuration Error`;
2. a hook-generated `colors.lua` (see `--seam`) — same;
3. a truncated `colors.lua` (head -3 of the generated one) — same: the
   `pcall` + essential-key guard swallows it (PRD acceptance box 3's static
   half).

Then `wezterm --config-file "$SRC" show-keys --lua` contains the `F6` row.

### `--seam` — the writer's shape feeds the reader

Run the repo's own generator read-only:
`bash home/dot_config/tinted-theming/tinty/executable_wezterm-colors.sh`
against a scratch `HOME`/`XDG_DATA_HOME` holding an inline base16 fixture
yaml and a `current_scheme` naming it (the fixture recipe is
`tests/theme-switcher.sh --hook`'s; write this gate's own copy, do not
source that script). Assert:

- the generated file carries every key `load_theme` requires:
  `background`, `foreground`, `ansi` — plus `brights` (the tab bar's base03
  alias) and `selection_bg` (its base02 alias);
- probe load 2 above, with exactly this file in place, is clean.

This is the seam pinned mechanically: S.9 owns the generator, T.1 owns the
reader, and this stage goes red if either side moves its shape.

## `gates/waves.tsv`

Append ` | external bash tests/wezterm-appearance.sh` to the wave-2 gates
cell. One cell, one row, nothing else in the file.

## `gates/manual/wave2.md`

The wave-2 T.1 row (cursor smear) exists; add three more, in its PASS/FAIL
style:

- **Retint reaches every pane** — with two windows open and a pane that was
  open before the switch, run `tinty apply` with a different scheme. PASS:
  every window, tab and pane recolours, no restart, no file in this epic
  edited. FAIL: any pane keeps the old scheme (the per-pane override
  outranking `config.colors` is exactly what R6 exists to beat).
- **F6 does not freeze the GUI** — press F6. PASS: the theme flips and
  typing in another window never stalls while the hook chain runs. FAIL:
  any visible freeze (that is `run_child_process` behaviour).
- **Half-written palette is rejected** — truncate the live `colors.lua`
  mid-write (e.g. `head -c 100` of it back onto itself), wait for the
  reload watch. PASS: the previous palette stays, WezTerm keeps running;
  restoring the file retints. FAIL: a half-empty theme is painted or
  WezTerm errors.

Note beside the nine-tab acceptance box: with only T.1 landed,
`hide_tab_bar_if_only_one_tab = true` hides the bar on a fresh window —
open a second tab to see the digit-only titles; "nine tabs titled 1–9"
completes when T.2 lands in wave 3.

## Acceptance

- [x] `bash tests/wezterm-appearance.sh` runs all stages green on this
      machine; each stage also runs alone via its flag.
- [x] The wave-2 row of `gates/waves.tsv` names the script; `bash
      gates/wave-status.sh` still parses the registry.
- [ ] `bash tests/managed-config.sh` stays green: `wezterm` is already in
      its declared surface, and the census finds no forbidden artifact in
      the new directory. *(2026-08-22: the two wezterm clauses both PASS —
      "holds only declared tools: undeclared <none>" and no forbidden
      artifact. The script itself was already red before this lane's first
      write: its template census ("exactly one deployed template,
      dot_gitconfig.tmpl" / "no template under home/dot_config/") refuses
      S.9's landed `television/cable/theme.toml.tmpl`. Not this node's file
      on either side — reported to the orchestrator for a correction against
      the census or the template.)*
- [x] `gates/manual/wave2.md` carries the three new T.1 rows.

## Verify

```sh
bash tests/wezterm-appearance.sh
bash gates/wave-status.sh >/dev/null && echo registry-ok
bash tests/managed-config.sh
```
