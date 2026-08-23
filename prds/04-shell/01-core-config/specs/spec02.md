# spec02 — `home/dot_config/nushell/dirstack.nu`

Covers the state layer of **R8**, and the persistence half of **R6**/**R7**,
of [`../prd.md`](../prd.md).

## Goal

Two files under XDG state, and the four helpers that read and write them:
`startdir.txt` (a single line: where a new shell opens) and `dirs.txt` (a
recency stack of every directory visited, capped and deduped) — the second of
which is the source the `recent-dirs` television channel draws from.

## Exact files touched

- **create** `home/dot_config/nushell/dirstack.nu` → deploys to
  `~/.config/nushell/dirstack.nu`

## Decisions this spec makes, with the evidence

**D1 — the module is `source`d, not `use`d, and its four defs are
`export def`.** `config.nu` must have `_startdir_save` in scope at *parse*
time for `mkcd`'s body and `_dirstack_push` in scope for the PWD hook closure,
which is why spec03 orders the `source` before both. Keeping the live shape
(`source` + `export def`) means the names land unprefixed, which is what the
callers already assume.

**D2 — `_dirstack_list` filters on read, `_dirstack_push` does not.** A path
deleted after it was pushed must never reach the picker, and the push side has
no way to know. Filtering on read costs one `path exists` per entry over a
list capped at 100; filtering on write would leave stale entries behind
forever whenever the deletion happened after the last push.

**D3 — no `--env` on any of the four.** They write files; the `cd` that
prompted the write has already happened in the caller. The live file carries
this note twice and it is worth keeping: adding `--env` here would look
harmless and would silently change `mkcd`'s and the hook's env semantics.

**D4 — the channel this feeds is `recent-dirs`, and the decode is not this
node's.** Live bug **L-3** is that `finder.nu`'s `_finder_type` types `rcwd`,
a name no cable file has ever carried, so recent-dir picks were never decoded
as paths. `rcwd` is the *bug id*. The fix lives in
[`04-television`](../../04-television/prd.md) R2. This spec's only obligation
is that the file it writes is the one `~/.config/television/cable/recent-dirs.toml`
reads, and that no comment in this file ever writes `rcwd` as if it were a
channel name — a grep for `rcwd` outside an explicit "live bug L-3" sentence
is a failure.

## Requirements — boxes a real check can fail

- [x] **S2.1** — The file exists at `home/dot_config/nushell/dirstack.nu` and
      opens with a comment that names both files, what each is for, and which
      one `env.nu` mirrors (spec01 S1.11).
- [x] **S2.2** — **`_state_dir`** resolves `$env.XDG_STATE_HOME?` defaulted to
      `<HOME>/.local/state`, joins `nushell`, `mkdir`s it, returns it. A check
      with `XDG_STATE_HOME` set to a scratch dir proves the override is
      honoured; a check with it unset proves the default.
- [x] **S2.3** — **`_dirstack_file`** → `<state>/nushell/dirs.txt`;
      **`_startdir_file`** → `<state>/nushell/startdir.txt`. Both derived from
      `_state_dir`, so there is one definition of the directory.
- [x] **S2.4** — **`_startdir_save <dir>`** overwrites the file with that one
      path. Called twice with different values, the file holds only the second.
- [x] **S2.5** — **`_dirstack_push <dir>`** puts `<dir>` at the head, removes
      any earlier occurrence of the same path (dedup), truncates to
      `DIRSTACK_CAP` = **100**, and persists newest-first, one path per line.
      Checkable: push `/a`, `/b`, `/a` → the file is exactly `/a`, `/b`;
      push 150 distinct paths → the file has 100 lines and the head is the
      last one pushed.
- [x] **S2.6** — **`_dirstack_list`** returns `[]` when the file is absent,
      and otherwise the stored paths newest-first with blank lines and
      no-longer-existing paths dropped. Checkable: seed the file with a real
      dir, a blank line and a deleted dir → only the real dir comes back, and
      the file itself is left unmodified (this is a read, not a compaction).
- [x] **S2.7** — **The cap is a named constant** (`const DIRSTACK_CAP = 100`),
      not a literal inside `take`.
- [x] **S2.8** — **No `--env` on any def** (D3), and the comment says why.
- [x] **S2.9** — **No `rcwd` as a channel name** (D4). The only permitted
      occurrence of the string is inside a sentence that identifies it as
      live bug L-3.
- [x] **S2.10** — **Nothing outside the state dir is written.** Under an
      isolated `HOME` with `XDG_STATE_HOME` unset, sourcing this file and
      calling all four helpers creates only `<HOME>/.local/state/nushell/` and
      the two files inside it.

## Out of scope

- The `recent-dirs` cable file and its decode — `04-television` R2.
- Any UI over this data. This module is state, not a picker.
