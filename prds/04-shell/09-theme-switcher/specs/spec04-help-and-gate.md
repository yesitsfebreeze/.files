# spec04 — manual entries and the node's gate

Covers **R6** and proves the node: the `help` entries for the commands
spec01 adds, their review rows, the gate `tests/theme-switcher.sh` that the
PRD's `verify:` will name, and its wave-4 registration.

**Est:** 1h

**Footprint:** `home/dot_config/nushell/help/shell.nuon`,
`home/dot_config/nushell/help/use-review.nuon`,
`home/dot_config/nushell/help/why-review.nuon`,
`tests/theme-switcher.sh` (create), `gates/waves.tsv` (wave-4 gates cell)

## Manual entries — `shell.nuon`

Three entries, topic `config`, mode `shell`,
`source: "prds/04-shell/09-theme-switcher/prd.md"` (the current tree — the
gate resolves `source` against the repo root, and `.mi/` is gone):

1. **`cmd: "theme"`** — the picker. `use`: run `theme`, the scheme catalog
   opens in television with the A/B pair at the top; browsing retints the
   window background live, `Enter` applies the pick into the active slot and
   `Esc` leaves the theme as it was. `why`: browsing never runs
   `tinty apply` — the preview is one OSC 11 escape, because an
   apply-per-focus fires tinty's whole hook chain on every keystroke; the
   one real apply happens after tv exits, in the live shell, so the hooks
   see the real environment. `also: ["theme toggle", "theme slots"]`.
   `verify: [{kind: "command", name: "theme"}]`.
2. **`cmd: "theme toggle"`** — flip to the other slot. `use`: names F6 as
   the terminal binding that runs it and what a flip does (apply the parked
   scheme, move the active pointer). `why`: the slots are deliberately A/B,
   not light/dark — a slot holds whatever was last picked while it was
   active, and picking in the picker retunes the active slot rather than
   choosing one. `also: ["theme", "theme slots"]`. Same verify target.
3. **`cmd: "theme slots"`** — the readout, covering `theme a`/`theme b` in
   its `use` as the direct-activation forms. No `why`. `also: ["theme
   toggle"]`. Same verify target.

Wrap at the file's prevailing style; place the three together under a
`config`-topic comment header, matching the file's grouping.

## Review rows

`tests/help-content-model.nu` refuses any entry without a `use-review.nuon`
row and any `why` without a `why-review.nuon` row, and refuses a row whose
`reviewer` equals its `author` — the record must not vouch for its own
writing. Follow the lane-precedent of D-1c: the implementer writes the
entries as author, and a **separate reader agent that did not write them**
reads each `use` against this PRD and the live route (each `why` against its
`use` for restatement) and records the rows — distinct `reviewer` and
`author` identities, digests computed with the gate's own helpers. Three
`use-review` rows, two `why-review` rows.

## `tests/theme-switcher.sh`

One script, stages `--module`, `--hook`, `--preview`, `--help`; no argument
runs all four. Follow `tests/nushell-core.sh`'s safety rules: scratch
`HOME`/`XDG_*` for everything, stub binaries on a controlled PATH,
`/usr/bin/grep` always, nothing installed, the live `~/.config` never
touched. Fixture scheme yamls (a base16 and a base24) live inside the
script or under `gates/fixtures/`.

- `--module` — spec01's boxes: standalone parse under `nu -n`; the stubbed
  `tinty` call log proving toggle round-trip, apply-before-pointer,
  drift-adoption, the no-op skip, and the tag strip; the dropped-surface
  grep; the `config.nu` anchor order.
- `--hook` — spec02's boxes: generation from fixtures, base24 brights,
  half-parse bail, unchanged-content guard, the dropped-integrations grep,
  `bash -n`.
- `--preview` — spec03's boxes: template render, `no_sort`/`frecency`, one
  OSC 11 with the fixture base00, `NO_COLOR`, missing-scheme exit 0, the
  `tinty apply` grep.
- `--help` — the three entries exist in `shell.nuon` with non-empty
  `use`/`source`, and `nu tests/help-content-model.nu` reports no error
  naming a `theme` entry. Scoped to this node's entries: the content gate
  has repo-wide checks (stale `.mi/` sources predate this node) that are
  not this gate's to answer for.

Counterfactuals that bite, per the S.1 gate's standard: a copy with the
pointer written before the apply must FAIL the ordering check; a fixture
with `base05` deleted must leave `colors.lua` untouched or the stage is red.

## Registration

Append ` | external bash tests/theme-switcher.sh` to the wave-4 `gates` cell
of `gates/waves.tsv` — S.9 is a wave-4 task and "each wave's own tasks add
their gate here" is that file's own rule. Report the gate command upward for
the PRD's `verify:` field; frontmatter is not this lane's to edit.

## Acceptance

- [x] `bash tests/theme-switcher.sh` — all stages green, three consecutive
      runs, output quoted. *(2026-08-22: runs 1–3 all `theme-switcher gate:
      ALL PASS`, rc=0, 73 PASS / 0 FAIL per run.)*
- [x] A scratch copy with the spec01 files deleted turns the gate red
      (proves it can fail). *(Scratch copy minus `theme.nu` and the anchor
      line: 12 FAIL lines, `theme-switcher gate: FAILURES`, rc=1.)*
- [x] `help theme` renders the entry from the deployed nuon (or, pre-S.5:
      `open home/dot_config/nushell/help/shell.nuon | where cmd == "theme"`
      returns one row). *(Pre-S.5 form: exactly one row; gate `--help`
      counts all three entries.)*
- [x] `use-review.nuon` and `why-review.nuon` carry the new rows with
      `reviewer` ≠ `author`. *(Three use rows + two why rows, reviewer
      `reader-S-9`, author `impl-S-9` — a dispatched reader that wrote none
      of the entries; `nu tests/help-content-model.nu` prints `ok`, exit 0.)*
- [x] `gates/waves.tsv` wave 4 names the gate; `just gate-status` still
      parses the registry. *(The registration was DELEGATED to the
      implementer holding `gates/waves.tsv` and has landed — this lane never
      edited that file. Checked 2026-08-22: `grep -c
      'tests/theme-switcher.sh' gates/waves.tsv` = 1 on the wave-4 row, and
      `just gate-status` renders wave 4 with 4 registered gates.)*

## Verify

```sh
bash tests/theme-switcher.sh \
  && /usr/bin/grep -c 'tests/theme-switcher.sh' gates/waves.tsv
```
