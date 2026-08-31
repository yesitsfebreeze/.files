---
state: done
priority: 12
est:
mode: afk
needs:
  - 06-help/04-drift-check
verify: "nu tests/help-content-model.nu"
origin: derived
from: 00-delivery/corrections/done-nodes-with-unticked-boxes/drain-the-backlog
complexity: 2
blast-radius: low
actual: 0.02h
---

# `shell.nuon [y]` has no review row, so the content-model gate is red

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: `nu tests/help-content-model.nu` exits 1 with one violation:

```
shell.nuon [y]: has no row in use-review.nuon — read the `use` against
prds/04-shell/02-aliases-utilities/prd.md and the live route, then record
the reading with digest b88bef74e7a115cc
```

The `y` entry (`home/dot_config/nushell/help/shell.nuon:147-152`, the yazi
alias) is an **uncommitted working-tree change by a concurrent lane** — the
same lane adding `y`→yazi to `prds/04-shell/02-aliases-utilities/prd.md` R1,
`config.nu` and `tests/nushell-aliases.sh` (all uncommitted, 2026-08-31). It
has no matching row in `use-review.nuon`. The corpus ritual requires every
entry's `use` to be reviewed; the gate enforces it.

**Corrected 2026-08-31:** the first filing attributed the entry to commit
`43a1604` (`06-help/04-drift-check` + `07-multiplexer/09-manual-entries`).
Measured: neither `43a1604`'s tree nor `HEAD` contains `cmd: "y"` in
`shell.nuon` (zero `yazi` matches in both), and `git log --all -S 'cmd: "y"'`
finds no commit that ever added it — the entry is purely working-tree. The
gate red is real (verified 2026-08-31: `nu tests/help-content-model.nu` →
`1 violation(s): shell.nuon [y]: has no row in use-review.nuon`), but the
cause is a concurrent lane mid-work, not a landed commit. If that lane
commits the entry with its review row, this finding is moot; if it commits
without one, R1 below is the fix.

**Why this is a finding and not a shrug:** the content-model gate is a wave-4
gate, so wave 4 is red. It also blocks the (a) classification of several
`done` nodes whose acceptance says "`nu tests/help-content-model.nu`
passes" — `esc-entry-verify-kind`, `help-nvim-lsp-descs`,
`capsule-creds-doc-accuracy`, `zi-cdi-picker-exception` — because the
drain-the-backlog discipline is that (a) is only available where the proof
passes today. The fix is one review row; the gate then goes green and those
boxes become tickable.

## Requirements
- [x] **R1** — The `y` entry's `use` is read against
      `prds/04-shell/02-aliases-utilities/prd.md` and the live route
      (`alias y = yazi` in `config.nu`), and the reading is recorded in
      `use-review.nuon` with the digest the gate names
      (`b88bef74e7a115cc`), per the corpus ritual.
      > [analyst-shell-y-row, 2026-08-31] Row written (end of the file):
      > `{id: "y", file: "shell.nuon", digest: "b88bef74e7a115cc",
      > reviewer: "analyst-shell-y-row", date: "2026-08-31", note: …}`.
      > Digest independently re-derived with the gate's `use-digest`
      > formula (sha256 of use + newline + `--` + newline + source, first
      > 16 hex), reproducing `b88bef74e7a115cc` — not copied off the gate's
      > message. The reading: 02-aliases-utilities R1 lists `y`→yazi among
      > the tool aliases (prd.md:23-27) and has no gesture text of its own;
      > live route `alias y = yazi` at config.nu:114 (uncommitted, the
      > lane's), proven resolving in a fresh shell by
      > tests/nushell-aliases.sh's hermetic `scope aliases` check; yazi
      > 26.8.15 installed, no ~/.config/yazi so no keymap override; driven
      > in a tmux scratch session — `l` descends into a directory and `q`
      > quits (the pane process ends), the stock arrow/hjkl and Enter-open
      > defaults not separately driven and named as such in the row's note.
      > The row's note also records: bare alias, so no quit-cd — the funnel
      > and the recents log see nothing, which is what the `use` honestly
      > says; yazi is a file manager, not a picker screen.
- [x] **R2** — The reviewer is distinct from the entry's author, per the
      ritual `cdi-manual-source` R2 established.
      > [analyst-shell-y-row, 2026-08-31] The reviewer wrote none of the
      > entry text: the entry is a concurrent lane's uncommitted
      > working-tree work and that lane's session id is recorded nowhere
      > this reader could find, so the `author` field is omitted rather
      > than invented — the ritual's own rule — and the row's `note`
      > carries the record. The gate's reviewer-equals-author check
      > reports nothing.

## Acceptance
- [x] `nu tests/help-content-model.nu` exits 0, output quoted.
      > Before the row: `1 violation(s): shell.nuon [y]: has no row in
      > use-review.nuon …`, exit 1. After: `help content model: 102
      > entries across 4 files, 9 topics, 15 prose-only` … `ok`, exit 0.
- [x] The `y` row in `use-review.nuon` names the digest
      `b88bef74e7a115cc` and a reviewer distinct from the author.
      > `open home/dot_config/nushell/help/use-review.nuon | where id ==
      > "y"` reads back digest `b88bef74e7a115cc`, reviewer
      > `analyst-shell-y-row`; no `author` (see R1 and R2 above).

## Out of scope
- Any other entry missing a review row. If the same shape exists elsewhere,
  that is a census this node does not run — report it as its own correction.

## Report

spec01: exit 0
help content model: 102 entries across 4 files, 9 topics, 15 prose-only
╭───┬────────────┬─────────╮
│ # │   topic    │ entries │
├───┼────────────┼─────────┤
│ 0 │ navigate   │      13 │
│ 1 │ find       │      12 │
│ 2 │ history    │       4 │
│ 3 │ edit       │      30 │
│ 4 │ git        │       2 │
│ 5 │ terminal   │      13 │
│ 6 │ agents     │      10 │
│ 7 │ config     │       8 │
│ 8 │ containers │      10 │
╰───┴────────────┴─────────╯
ok
[[id, file, digest, reviewer, date, note]; [y, "shell.nuon", "b88bef74e7a115cc", analyst-shell-y-row, "2026-08-31", "new entry (shell.nuon:146-154), read by a session that wrote none of it and is not its author: the entry and its live route are a concurrent lane's uncommitted working-tree work on this same date, and that lane's session id is recorded nowhere this reader could find, so no `author` is written rather than an invented one. Against the source: 04-shell/02-aliases-utilities R1 lists `y`->yazi among the tool aliases (prd.md:23-27) and says nothing more about the gesture, so the yazi-stock sentences are checked against the route, not the PRD. Live route: `alias y = yazi` (config.nu:114, also uncommitted 2026-08-31), proven resolving in a fresh shell by tests/nushell-aliases.sh's hermetic `scope aliases` check (all twelve names, y among them); yazi 26.8.15 at /opt/homebrew/bin/yazi and no ~/.config/yazi, so no keymap override. Driven in a tmux scratch session on a throwaway dir: `l` descends into a directory and `q` exits (the pane process ends) — arrows/hjkl movement and Enter-opening are yazi's stock defaults and were not separately driven. Three standing observations, none a defect: the alias is bare, so quitting yazi does NOT cd the shell to yazi's last directory — no quit-cd wrapper, so the mkcd funnel, startdir and the recents log see nothing, which is exactly what `q quits back to the shell` honestly says; yazi is a full-screen file manager rather than a picker screen, so it does not touch the tv-owns-every-picker invariant; and the row is keyed to the concurrent lane's current `use`/`source` text — if that lane rewords either before committing, the digest goes stale by design and the reading is re-run, not patched through."]]
