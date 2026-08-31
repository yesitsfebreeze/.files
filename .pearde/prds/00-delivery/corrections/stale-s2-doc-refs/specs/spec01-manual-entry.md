# spec01 — remove the `bb / ba` manual entry and everything that pins it

Delete the `bb / ba` entry from the shell manual and the three records that
require it to exist: its two review rows and its line in the test's coverage
list. `bb`/`ba` are `DO NOT PORT`
([`04-shell/02`](../../../../04-shell/02-aliases-utilities/prd.md), Out of
scope), so the manual documents aliases that will never ship. All four edits
land in one change: `tests/help-content-model.nu` fails on a review row whose
entry is gone ("reviews a `use` that no entry carries any more") and on a
coverage id no entry documents — partial removal turns the gate red.

The landed `stale-mi-paths` sweep already repointed the entry's `source:` to
`prds/...`; the entry itself is what remains.

**Est:** 1h

**Footprint:** `home/dot_config/nushell/help/shell.nuon`,
`home/dot_config/nushell/help/use-review.nuon`,
`home/dot_config/nushell/help/why-review.nuon`,
`tests/help-content-model.nu`

## Changes

1. **`home/dot_config/nushell/help/shell.nuon`** — delete the whole
   `cmd: "bb / ba"` record (lines 348–357, from its `{` through its `}`).
   Delete nothing else; change no digest and no other entry.
2. **`home/dot_config/nushell/help/use-review.nuon`** — delete the one row
   `{id: "bb / ba", file: "shell.nuon", ...}` (line 152). The `note:` about
   `brr` keying by git root dies with the row; the shipping record of the
   brr facts is `docs/capabilities-nushell.md` and `prds/README.md`'s
   exclusion list, both already written.
3. **`home/dot_config/nushell/help/why-review.nuon`** — delete the one row
   `{id: "bb / ba", file: "shell.nuon", ...}` (line 98).
4. **`tests/help-content-model.nu`** — in `const COVERAGE`, `"shell.nuon"`
   list (line 186), delete `"bb / ba"`; `"cf <file>"` and `"pass <tab>"`
   stay. This is transcription rot, not a requirement change: the coverage
   node ([`06-help/01/coverage`](../../../../06-help/01-content-model/coverage/prd.md))
   R1 says "aliases and utilities" and never names `bb`/`ba`.

Deletions only. No digest recompute, no renumbering, no rewording of
surviving entries. Baseline before the change: the gate is green with 87
entries; after, it is green with 86.

Off limits: `gates/**` (gates-port lane), `home/dot_config/nushell/config.nu`
and `claude.nu` (claude-launchers lane), `home/dot_config/capsule/` and
`tests/dev-image.sh` (dev-image lane). None of them is needed here; already
today `config.nu` defines no `bb`/`ba` and no gate under `gates/` names the
entry.

## Acceptance

- [x] `nu tests/help-content-model.nu` prints `ok`, exits 0, and reports 86
      entries. Ran 2026-08-22: `help content model: 86 entries across 4
      files, 9 topics, 10 prose-only` … `ok`, exit 0.
- [x] `bb / ba` appears nowhere under `home/dot_config/nushell/help/` and
      nowhere in `tests/help-content-model.nu`. Ran 2026-08-22:
      `rg -n 'bb / ba' home/dot_config/nushell/help
      tests/help-content-model.nu` exits 1 with no matches.
- [x] The only files under `home/` or `tests/` mentioning `bb` or `ba` at
      all are absence assertions (`tests/nushell-aliases.sh`), satisfying the
      PRD's "no shipped file references `bb`/`ba` as a live alias". Ran
      2026-08-22: `rg -ln '\bbb\b|\bba\b' home tests` prints
      `tests/nushell-aliases.sh` only.

## Verify

```sh
cd "$(git rev-parse --show-toplevel)"
nu tests/help-content-model.nu
rg -n 'bb / ba' home/dot_config/nushell/help tests/help-content-model.nu && exit 1
rg -ln '\bbb\b|\bba\b' home tests   # expected: tests/nushell-aliases.sh only
```
