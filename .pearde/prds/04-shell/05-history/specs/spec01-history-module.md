# spec01 — `history.nu`: cwd query, pickers, inline cycle, KEYBINDINGS block

Delivers R1–R5 as a new module, `home/dot_config/nushell/history.nu`, sourced
at config.nu's MODULES anchor, plus the six keybinding records at the
KEYBINDINGS anchor. The live implementation is the model: defs at
`~/.config/nushell/config.nu:318-359`, bindings at `:533-590`. What does NOT
survive the port: the hardcoded db path
`$"($env.HOME)/.config/nushell/history.sqlite3"` (D2) and the unguarded
`open` of a db that may not exist (D3).

**Est:** 1.5h

**Footprint:** `home/dot_config/nushell/history.nu` (create),
`home/dot_config/nushell/config.nu` (MODULES: one `source` line;
KEYBINDINGS: one append block),
`tests/nushell-core.sh`, `tests/nushell-aliases.sh`, `tests/shell-listing.sh`,
`tests/shell-claude.sh`, `tests/shell-zoxide.sh` (one `cp` line in each
`mk_machine`)

## Exact files touched

- **create** `home/dot_config/nushell/history.nu` → deploys to
  `~/.config/nushell/history.nu`. Defs only — no keybinding append, no hook
  append, no `$env.config` write (the records are config.nu's, D1; the file
  parses standalone under `nu -n`). Contents in parse order:
  1. A header comment carrying: the D2 measurement (why `$nu.history-path`
     and never a literal path); the D4 seam (`Alt-R`'s `tv_shell_history`
     def is the generated television init's, P.4's generator comment names
     this node; the `nu-history` cable channel behind it belongs to
     [04-shell/04-television](../../04-television/prd.md), which depends on
     this node and owns the sqlite override).
  2. `def _hist_cwd []` (R1) — if `$nu.history-path` does not exist, return
     `[]` (D3). Else
     `open $nu.history-path | query db "SELECT command_line FROM history
     WHERE cwd = :cwd GROUP BY command_line ORDER BY max(id) DESC LIMIT
     5000" --params { cwd: $env.PWD } | get command_line`. The SQL is the
     live query verbatim: distinct commands, newest use first, capped 5000.
  3. `def tv_history_local []` (R2) — live verbatim: prefix =
     `commandline | str substring 0..(commandline get-cursor)`; then
     `_hist_cwd | str join (char newline) | tv --no-status-bar --inline
     --input $cur | str trim`; a non-empty pick → `commandline edit
     --replace` + `commandline set-cursor --end`. Plain stdin mode, no
     channel argument — the candidates ARE the cwd filter.
  4. `def --env _hist_local [--down]` (R3) — live verbatim, including its
     two quirks, kept with their comments (D5): position in
     `$env._HIST_LOCAL_POS`, last-injected line in `$env._HIST_LOCAL_LAST`,
     a buffer that differs from the last injection resets to newest, the
     clamp floors at 0 and ceils at n−1.
- **edit** `config.nu`, MODULES anchor: `source ~/.config/nushell/history.nu`
  as the LAST module line (after `zoxide.nu` — present by dispatch order,
  04-shell/03 is a dep). The order among modules is not load-bearing for
  this file — its defs name only builtins and the external `tv` — so it is
  placed last to keep the anchor append-only.
- **edit** `config.nu`, KEYBINDINGS anchor: a second
  `$env.config = ( ... | upsert keybindings ( ... | append [ ... ]))` block
  AFTER S.1's `esc_clear` block, commented with this node's name and R5's
  reason (reedline resolves a duplicate (modifier, keycode) to the LATER
  entry; KEYBINDINGS sits after GENERATED, so these beat the Ctrl-R the
  television init binds). Six records, all with
  `mode: [vi_normal vi_insert emacs]`, names EXACTLY as `help/shell.nuon`'s
  `verify` fields already fix them:
  | name | modifier | keycode | event |
  |---|---|---|---|
  | `hist_picker_local` | control | char_r | `{ send: executehostcommand, cmd: "tv_history_local" }` |
  | `hist_picker_global` | alt | char_r | `{ send: executehostcommand, cmd: "tv_shell_history" }` |
  | `hist_up_local` | none | up | `{ until: [{ send: menuup } { send: executehostcommand, cmd: "_hist_local" }] }` |
  | `hist_down_local` | none | down | `{ until: [{ send: menudown } { send: executehostcommand, cmd: "_hist_local --down" }] }` |
  | `hist_up_global` | shift | up | `{ until: [{ send: menuup } { send: previoushistory }] }` |
  | `hist_down_global` | shift | down | `{ until: [{ send: menudown } { send: nexthistory }] }` |
  The `until` chains are R4: `menuup`/`menudown` no-op with no menu open, so
  completion menus keep the arrows. Alt (not Ctrl-Shift) for the global
  picker is R2's constraint; the CONFIG anchor's `use_kitty_protocol`
  comment already carries the reason — reference it, do not restate it.
- **edit** the five gates that run a hermetic nu against config.nu — the
  moment config.nu sources `history.nu`, every one of them dies with
  `nu::parser::sourced_file_not_found`. One `cp` of the repo's `history.nu`
  beside the `claude.nu` line in each `mk_machine`, commented with this
  node's name (fifth repetition of the pass.nu precedent):
  `tests/nushell-core.sh`, `tests/nushell-aliases.sh`,
  `tests/shell-listing.sh`, `tests/shell-claude.sh`, `tests/shell-zoxide.sh`.
  Nothing else in those files is touched.

## Decisions

**D1 — defs in a module at MODULES, records at KEYBINDINGS.** The anchor
map gives config.nu's anchors to their owning nodes and MODULES is where
later nodes source their own files (pass.nu, claude.nu, zoxide.nu are the
precedent). The keybinding records do NOT ride inside the module: S.1's
KEYBINDINGS anchor comment names this node as the reason the anchor is
last ("anything appended here wins"), and an append from MODULES would
leave that promise empty while working only by accident of anchor order.

**D2 — the helper opens `$nu.history-path`, never a literal path.**
Measured 2026-08-22 on the pinned 0.114.1: the constant honours
`XDG_CONFIG_HOME` from the LAUNCH environment (env.nu's own
`$env.XDG_CONFIG_HOME = ...` runs too late to move it) and reflects the
loaded config's `file_format` — with the repo config it names
`history.sqlite3`; under `env -i` with no XDG it is
`~/Library/Application Support/nushell/history.sqlite3`. The live literal
`~/.config/nushell/history.sqlite3` works only because the LIVE
wezterm.lua sets `XDG_CONFIG_HOME` in `set_environment_variables` — a line
the repo's wezterm.lua deliberately omits today. The constant is the file
reedline actually reads and writes wherever the terminal's env puts it; a
literal would silently query a db no keystroke ever updates. spec02 pins
the resolution with an executable check.

**D3 — missing-db guard, `[]` not an error.** Reedline creates the sqlite
on the first interactive Enter; a fresh machine (and any `--no-history`
run) has none. Unguarded, `open` throws — which turns EVERY Up keypress
and Ctrl-R into a red error at the prompt on a new machine.

**D4 — Alt-R's target is the generated init's def; the channel is S.5's.**
`tv_shell_history` comes from `tv init nu` at apply time
(home/run_after_generate-shell-init.sh, whose comment names this node).
The `nu-history` cable override (sqlite-aware, `nu -n`) is
04-television's: its PRD lists this node in `deps` and owns that file.
This node proves the binding and the route; until S.5 lands, Alt-R runs
tv's builtin nu-history channel — degraded content, correct wiring.

**D5 — live quirks carried verbatim, with comments.** Down before any Up
injects the newest entry (the clamp floors at 0); the prefill substring
`0..cursor` is inclusive (exact at end-of-line, the position the picker
is invoked from). Fixing either silently is drift from the audited live
behaviour; a real fix is a correction filed upward, not an edit here.

## Hands off the manual

`home/dot_config/nushell/help/shell.nuon` already carries the four entries
(`Ctrl-R`, `Alt-R`, `Up / Down`, `Shift+Up / Shift+Down`), each with
`source: prds/04-shell/05-history/prd.md` and `verify` fields naming the
six binding names above — the names are the manual's contract, not a
choice. Do not edit the entries: an edit invalidates their review digests
in `use-review.nuon`. If the implementation is forced to diverge, file a
correction instead.

## Acceptance

Hermetic = scratch HOME via `env -i` with `XDG_CONFIG_HOME` pinned into
it, the repo's managed nushell files at the literal paths config.nu
sources, a recording `tv` stub on PATH, the seeded fixture db of spec02.
spec02's gate holds every box; the runs below are the smoke check.

- [x] Hermetic: with commands seeded in dirs A and B, `cd A; _hist_cwd`
      returns A's commands deduplicated newest-first and none of B's.
- [x] Hermetic: on a machine with no history db, `_hist_cwd` returns `[]`
      and a pty `Up` press errors nothing — buffer and stderr clean.
- [x] Hermetic, pty: in A, `Up` injects A's newest command; six plain
      `Up` presses never surface B's canary; `Shift+Up` presses do (R3).
      *(Six, not four: reedline's native traversal does not dedup and B's
      canary sits five raw rows back, so both sides press six — measured,
      see the gate's header.)*
- [x] Hermetic, pty: `Ctrl-R` after typing `pri` spawns the tv stub with
      `--input pri` and only A's commands on stdin; the stub's reply
      replaces the commandline (R2).
- [x] Hermetic, pty: `Alt-R` runs `tv_shell_history` — the stub's argv
      shows the global route, no candidate stdin (R2).
- [x] Hermetic, pty: with a completion menu open, `Down` moves the menu
      selection and injects no history line (R4).
- [x] `nu -c`: for `(control, char_r)` the LAST keybinding entry is
      `hist_picker_local`; all six records present with the exact shapes
      above (R5).
- [x] `bash tests/nushell-core.sh`, `bash tests/nushell-aliases.sh`,
      `bash tests/shell-listing.sh`, `bash tests/shell-claude.sh`,
      `bash tests/shell-zoxide.sh` stay green after the staging edits.

*Checked 2026-08-22: `bash tests/shell-history.sh` 62 PASS EXIT=0;
siblings 147/39/36/49/72 PASS, all EXIT=0.*

## Verify

```sh
cd /Users/feb/dev/dotfiles
bash tests/shell-history.sh         # spec02's gate; covers every box above
bash tests/nushell-core.sh
bash tests/nushell-aliases.sh
bash tests/shell-listing.sh
bash tests/shell-claude.sh
bash tests/shell-zoxide.sh
/usr/bin/grep -n 'history.nu' home/dot_config/nushell/config.nu   # one MODULES line
```
