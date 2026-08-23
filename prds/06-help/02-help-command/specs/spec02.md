# spec02 — retire the manual's "not settled" caveat on the `help` entry

The corpus's own `help` entry (`shell.nuon`, topic `config`, source: this
PRD) carries a `why` whose second half is now false: "Where a name is BOTH a
nushell command and an entry here — `ls` is the live example — which one
wins is not settled; the delegation PRD and this file currently disagree."
W0.4d settled it 2026-08-21 (M-13, "ours wins"), the PRD carries the
settled contract, and spec01 implements it — shipping the caveat past that
point is a stale line read as current. W0.4d corrected only the PRD; the
data file was deliberately out of its footprint, so the fix lands here, in
the same change set as the behavior (the house rule for manual entries).

**Est:** 0.5h

**Footprint:** `home/dot_config/nushell/help/shell.nuon` (one `why` field),
`home/dot_config/nushell/help/why-review.nuon` (that entry's row)

## Exact edit

- `shell.nuon`, the `cmd: "help"` entry, `why` field only. Keep the first
  sentence (the sanctioned-override constraint — it is the hard-won why).
  Replace the unsettled-collision sentence with the settled rule, stated
  for a manual reader: for a name that is both a nushell command and an
  entry here (`ls`), the manual wins — and loses the reader nothing,
  because a command entry's detail ends with that command's own `std/help`
  output, and `help --entry` / `help --topic` / `help --delegate` address
  either side explicitly. Single-line string, like every string in the
  corpus. Do NOT touch the entry's `use`: it already describes the
  implemented resolution, and editing it would stale its `use-review.nuon`
  row (digest keys on `use`+`source`).
- `why-review.nuon`: editing the `why` stales that entry's row by
  construction. Follow the ritual in the file's own header: refresh the
  row's digest (the gate prints the expected value on failure), set
  `author:` to the session that wrote the new text, and `reviewer:` to a
  reader that did NOT write it — the gate fails a row where the two match,
  and signing your own writing is the false record the field exists to
  block. The implementer arranges the independent read (a spawned reader
  given only the entry and the PRD, per the header's ritual) or reports
  the row as needing one; it never self-signs.

## Acceptance

- [x] `/usr/bin/grep -c 'not settled' home/dot_config/nushell/help/shell.nuon`
      is 0. Ran it: `0`.
- [x] The new `why` names the settled rule and the three disambiguator
      flags; the entry's `use` is byte-unchanged. The edit was one string
      replacement over one `why` field, asserted unique before writing, and
      `git diff -U0 shell.nuon` shows the `why` line as the only changed line
      this node touched. `git diff --stat` on that file is not the measure
      here: the file arrived with uncommitted edits from another lane, so its
      diff against the index carries lines this node never wrote.
- [x] `nu tests/help-content-model.nu` exits 0 — digest current, and the
      `help` row's `reviewer` ≠ `author`. Ran it: `help content model: 91
      entries across 4 files, 9 topics, 12 prose-only` then `ok`. 91, not the
      87 written here — H.1 grew the corpus after this spec was written. The
      row now reads `digest: 29ed1a89c9b22b7c, reviewer: reader-H-2, author:
      impl-H-2`; the reader was spawned with the entry and the PRD and wrote
      none of the text, and returned STANDS.

## Verify

```sh
cd /Users/feb/dev/dotfiles
nu tests/help-content-model.nu
/usr/bin/grep -c 'not settled' home/dot_config/nushell/help/shell.nuon
git diff --stat home/dot_config/nushell/help/
```
