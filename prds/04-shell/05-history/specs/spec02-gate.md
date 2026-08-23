# spec02 — the history gate: tests/shell-history.sh, registered

Delivers this node's standing proof: a gate script holding spec01's
acceptance to executable checks, plus its registration in the wave
registry. New file — the five gates spec01 adds staging lines to belong to
other nodes; their harness patterns are followed, not forked.

**Est:** 2.5h

**Footprint:** `tests/shell-history.sh` (create), `gates/waves.tsv`
(wave 5 gates cell)

## Shape

`bash tests/shell-history.sh [--tree|--hermetic]`, no argument runs both.
Source `gates/lib.sh`. Follow `tests/nushell-core.sh`'s safety rules:
`/usr/bin/grep` always; every nu run under `env -i HOME="$S"` with a
scratch HOME, never the live one; never snapshot `~/.config/nushell`
wholesale — the live shell rewrites `history.sqlite3-wal` at any moment,
so per-file shas only, and the live db is never read, copied or sha'd;
`~/.cache/nushell` must not exist when the gate finishes; nothing
installed, live tree untouched. Copy the pty runner from
`tests/shell-listing.sh` (the winsize-setting variant — the arrow and
menu checks assert repainted buffers, and a 0-column pty fails them for
the wrong reason). Its `unesc` already turns `\x1b` escapes into real
bytes, so keys are sent as `@SEND=\x1b[A` (Up), `\x1b[B` (Down),
`\x1b[1;2A`/`\x1b[1;2B` (Shift+Up/Down), `\x12` (Ctrl-R), `\x1br`
(Alt-R).

Two deviations from the house runners, stated in the header with their
reasons:

- **No `--no-history`.** Shift+Up/Down are reedline's NATIVE traversal
  and the seeded fixture is read through reedline itself; `--no-history`
  disables both. Isolation comes from the scratch HOME, not the flag.
- **`XDG_CONFIG_HOME="$M/home/.config"` in every runner's env.** Pins
  `$nu.history-path` (D2) inside scratch and mirrors the live terminal's
  launch environment. The first hermetic check asserts the resolution.

No `--apply` stage, and say so in the header: S.1's gate proves the
managed tree deploys byte-identical, and `history.nu` rides the same path
as `pass.nu`, `claude.nu` and `zoxide.nu`.

**The seeded fixture db.** Never hand-written SQL: the `history` table is
`strict` with nushell's own indexes, and its schema is nushell's to
define. A seeding pty session against the managed config in the scratch
HOME types, with ABSOLUTE `cd` targets (env.nu's startdir restore means a
session does not start where it was spawned):
`cd $S/home/dirA` → `print HIST-A-ONE` → `print HIST-A-TWO` →
`print HIST-A-ONE` (again — the dedup row) → `cd $S/home/dirB` →
`print HIST-B-ONE` → `exit`. That leaves a real
`$S/home/.config/nushell/history.sqlite3` with a `cwd` per row
(`exit` and the `cd` lines are recorded too — assertions count canaries,
never total rows).

**The tv stub and the television fixture.** The `tv` BINARY is a
recording stub: it appends its argv to one log, its full stdin to a
per-invocation log, and prints the contents of `$S/tv-reply` (empty file
→ prints nothing). The fixture at `~/.cache/nushell/init/television.nu`
is NOT the one-line comment stub the other gates use: it carries the
generated init's real shape — `tv_smart_autocomplete`, `tv_shell_history`
(spawning `tv nu-history --no-status-bar --inline --input ...`) and tv's
own `tv_completion` (Ctrl-T) and `tv_history` (Ctrl-R) bindings — so
last-entry-wins (R5) is executable, not asserted. Header comment names
`tv init nu` as the source of the shape.

## --tree: the managed files as text

Each ordering or absence claim carries a counterfactual — a deliberately
broken copy in scratch that must FAIL the same check.

- `source ~/.config/nushell/history.nu` sits under `# ── MODULES ──`,
  before `# ── PALETTE ──`; the ten S.1 anchors are present once each, in
  order (own grep — never call into another gate).
- `history.nu` defines, in this parse order: `_hist_cwd`,
  `tv_history_local`, `_hist_local`. It contains NO keybinding append, no
  hook append, no `$env.config` write (spec01 D1: defs only).
  Counterfactual: a copy with an `upsert keybindings` block fails.
- The R1 SQL literal, all four load-bearing pieces:
  `GROUP BY command_line`, `ORDER BY max(id) DESC`, `LIMIT 5000`, and the
  `cwd` parameter.
- `$nu.history-path` is the only db path in `history.nu`; the literal
  spelling `.config/nushell/history.sqlite3` has 0 hits there (D2).
  Counterfactual: a copy carrying the live literal fails.
- The missing-db guard precedes the `open` (D3).
- The six records sit AFTER the `# ── KEYBINDINGS ──` anchor line, after
  S.1's `esc_clear` block; the six names are exactly the `verify` names
  in `help/shell.nuon`'s four history entries — read, never rewritten:
  assert each entry's `source:` names this PRD and that the gate's own
  sha over `shell.nuon` is unchanged at exit.
- `hist_up_local`/`hist_down_local` try `menuup`/`menudown` FIRST in an
  `until` chain; `hist_up_global`/`hist_down_global` send
  `previoushistory`/`nexthistory` (R3/R4). Counterfactual: a copy with
  the `until` members swapped fails.
- The CONFIG anchor still carries `isolation: false` — S.1's line,
  asserted read-only, because it is this node's premise (one merged
  sqlite; `true` would give the picker only its own session).

## --hermetic: a real nushell in a scratch HOME

- `$nu.history-path` under the gate env prints
  `$S/home/.config/nushell/history.sqlite3` — D2 pinned. Then the seeding
  session runs and the file exists; `/usr/bin/sqlite3` sees a `cwd`
  column (sanity, scratch db only).
- R1 direct, `nu -c`: `cd $S/home/dirA; _hist_cwd | to json -r` — first
  element `print HIST-A-ONE` (most recent use wins the dedup), exactly
  one occurrence of it, `print HIST-A-TWO` present, no `HIST-B` row.
- Fresh machine (no db staged): `_hist_cwd | to json -r` is `[]`; a pty
  `Up` press leaves the buffer clean, nothing on stderr (D3).
- pty, in dirA: `Up` injects `print HIST-A-ONE` (newest first); `Up Up`
  reaches `print HIST-A-TWO`; typing a character and pressing `Up` again
  returns to `print HIST-A-ONE` (reset-on-typing); four plain `Up`
  presses never surface `HIST-B-ONE`.
- pty, in dirA: repeated `Shift+Up` (≤4) surfaces `HIST-B-ONE` — the
  global traversal reaches B's command where the local cycle cannot.
- pty, in dirA: type `pri`, `Ctrl-R` with `$S/tv-reply` =
  `print PICKED-LOCAL`: the stub's argv log shows
  `--no-status-bar --inline --input pri`; its stdin log holds
  `HIST-A-ONE` and `HIST-A-TWO` and no `HIST-B` line (the cwd filter,
  proven at the pipe); the buffer shows `print PICKED-LOCAL`; Enter
  executes it (`PICKED-LOCAL` in output).
- pty: `Alt-R` — the stub's argv log gains a `nu-history` invocation
  (the fixture `tv_shell_history` ran) with no candidate stdin.
- **R5 counterfactual, executed:** against a scratch config copy with
  this node's six-record block deleted, `Ctrl-R` reaches the fixture's
  `tv_history` binding instead — the stub argv shows `nu-history` where
  the correct config's run showed the stdin-piped local picker. Reedline
  gave the key to the later entry; deleting ours hands it back to tv's.
- `nu -c`: `$env.config.keybindings | where modifier == control and
  keycode == char_r | last | get name` is `hist_picker_local`; each of
  the six records matches its exact shape (name, modifier, keycode,
  event, `mode: [emacs vi_insert vi_normal]` order as nushell reports
  it) via the S4.23 json pattern.
- pty, menu-safe (R4): a fixture dir with exactly `aaa.txt` and
  `abb.txt`; type `ls a`, `Tab` (completion menu opens), `Down`,
  `Enter`: the executed line completes to the SECOND candidate and no
  history canary was injected while the menu was open.
- Shas of every managed nushell file and `shell.nuon` unchanged by the
  run; `~/.cache/nushell` does not exist at exit.

## Registration

Append ` | external bash tests/shell-history.sh` to wave 5's `gates` cell
in `gates/waves.tsv` — S.6 is a wave 5 task; the cell currently carries
only `tests/shell-claude.sh`. `external` because the script lives in
`tests/`; `gates/selftest.sh` reports it unverified-by-contract, and the
counterfactuals above are this script's own falsification.

## Acceptance

- [x] `bash tests/shell-history.sh` exits 0 on the finished spec01 work,
      printing one `chk` line per check above (62 PASS, EXIT=0,
      2026-08-22).
- [x] Every counterfactual copy fails its check — shown in the gate's own
      output, not asserted in prose.
- [x] `gates/waves.tsv` names the gate — in WAVE 4's gates cell, not this
      spec's wave 5: the registry's rule is that each task registers in
      its own row, and the orchestrator placed
      `external bash tests/shell-history.sh` on the row carrying this
      node's task (registration delegated to the waves.tsv holder; landed
      and validated 2026-08-22). `bash gates/selftest.sh` still exits 0.
- [x] `~/.cache/nushell` does not exist after a full run; the shas of the
      managed nushell files and `shell.nuon` are unchanged; the LIVE
      `~/.config/nushell/history.sqlite3` was never opened, copied or
      sha'd by the gate.
- [x] `bash tests/nushell-core.sh`, `bash tests/nushell-aliases.sh`,
      `bash tests/shell-listing.sh`, `bash tests/shell-claude.sh`,
      `bash tests/shell-zoxide.sh` and `nu tests/help-content-model.nu`
      still exit 0 (147/39/36/49/72 PASS and `ok`, 2026-08-22).

## Verify

```sh
cd /Users/feb/dev/dotfiles
bash tests/shell-history.sh
bash tests/nushell-core.sh
bash tests/nushell-aliases.sh
bash tests/shell-listing.sh
bash tests/shell-claude.sh
bash tests/shell-zoxide.sh
nu tests/help-content-model.nu
bash gates/selftest.sh
/usr/bin/grep -n 'shell-history' gates/waves.tsv   # wave 5 row
```
