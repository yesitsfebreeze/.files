# spec02 — finder.nu: the typed channel runner and decoder

Create `home/dot_config/nushell/finder.nu`: `finder`, the channel picker,
the typed decoder (with the L-2 and L-3 fixes), the open-by-type dispatcher,
the `--expect` parser, the shell quoter, and the cht → cht-query pipe. Defs
only — no keybinding record, no config write, no hook (the entry points and
records are spec03's, in config.nu). The file parses standalone under
`nu -n`.

**Est:** 2.5h

**Footprint:** `home/dot_config/nushell/finder.nu`

## Header contract (R7 — carry each reason)

The file header states, because each one cost real time to learn:

- tv panics without a TTY ("Failed to create TUI instance") — every entry
  point is interactive-only. Guards use `$nu.is-interactive`, **not
  `is-terminal --stdout`**: measured on 0.114.1 (config.nu's PALETTE anchor
  comment), a parenthesised `is-terminal --stdout` as an `if` condition is
  false unconditionally.
- The CLI `--keybindings` grammar is `key="action"` — the INVERSE of the
  config-file `action = "key"` form; the config form is rejected.
- With `--expect`, stdout line 1 is the pressed key; a plain enter emits an
  empty first line.

## Defs

**`finder [--start: string]`** (`--env`, R1) —

1. Error with a named message if `tv` is missing; error cleanly (no panic)
   if not `$nu.is-interactive`.
2. Channel = `--start`, else `_finder_pick_channel`; empty pick returns `[]`.
3. Run `tv $channel --keybindings 'enter="confirm_selection";tab="toggle_selection"'`
   — the un-hijack (R1). It is passed on EVERY invocation, so it covers the
   three channels M-9 names (`text`, `recent-files` → edit; `zoxide` → cd in
   a nested `$SHELL`) **and** `git-branch`, whose live cable also binds
   enter (`actions:checkout`) — a fourth M-9 undercounted; note it in the
   comment and report it for the backlog. Tab multi-selects.
4. The cht pipe (R5): when the channel is `cht`, run it with
   `--expect 'ctrl-p'` and parse via `_finder_parse`. On `ctrl-p` with a
   picked language `$lang`, run `cht-query` with `--source-command` set to a
   bash one-liner fetching `cht.sh/$lang/:list` and prefixing every topic
   with `$lang/`, so the confirmed line is a complete sheet id
   (`python/lambda`). This is a **build, not a port**: the deployed
   finder.nu never implemented it (the comments in the live
   `cht-query.toml` reference a def from the abandoned chezmoi-source
   design, which Decision 4 retired). Plain enter on `cht` falls through as
   a raw pick.
5. Decode: `_finder_decode { produces: (_finder_type $channel), results: $entries }`.
6. **Empty decode over a non-empty selection is an error, not `[]`**
   (R2b): if `$entries` is non-empty and the decode is empty, `error make`
   naming the channel and the row count. This check lives HERE, not in
   `_finder_decode` — 04-shell/07 reuses the decoder on single stored
   values, where a dead path is that entry's problem, not a failure.

**`_finder_type [channel]`** (R2, L-3) — `files` | `dirs` | `recent-dirs` |
`recent-files` → `FileList`; `text` → `GrepList`; `git-log` → `Commits`;
`cht-query` → `ChtSheet`; anything else → `Any`. The word `rcwd` appears
nowhere in this file: it is bug L-3's id, not a channel name.

**`_finder_decode [stage]`** (R2) —
- `FileList` → each row `path expand`, keep only `path exists`.
- `GrepList` → `{file, line, text}` per the live split-on-`:` decode.
- `Commits` (L-2) → consume the emitted value **whole**: the channel's
  `output` template has already reduced the row to a bare hash, so the
  decoder trims and keeps rows matching `^[0-9a-f]{7,}$` — the guard stays,
  as a validity filter that passes. Produced shape is `{hash}`; `subject`
  is dropped (nothing consumes it; a label would come from the channel's
  display template, never reconstructed here). No second split — that
  duplication is what rotted.
- `ChtSheet` → `{sheet}`.
- `Any` → raw strings.

**`_finder_open [sel]`** (`--env`, R3) — `{file, line}` → `^$env.EDITOR
+$line $file`; `{hash}` → `^git show $hash`; `{sheet}` → `cht.sh/$sheet`
through `less -R`; else path → `cd` if dir (reaches the shell via `--env`),
edit if file.

**`_finder_pick_channel`** — candidate list from `tv list-channels`, minus
`channels` itself, handed back to the `channels` channel via
`--source-command` (R5: the remote's own channel, overridden per call).
Returns `""` on esc/empty. No non-tty fallback to "first channel" — the
live one has that and it is wrong; callers guard before calling.

**`_finder_parse [raw]`** — the `--expect` decoder: `{ key, entries }`,
empty first line = plain enter. Kept from live verbatim; 04-shell/07's
quicklist runner reuses it.

**`_finder_shquote` / `_finder_shquote_list`** — POSIX single-quoting, from
live verbatim. spec03's `tv_finder` uses them.

## Seams for 04-shell/07 (comment-marked, not built)

Two marked comment seams, both inside this file because nushell binds a def
body's calls at parse time and a later-sourced module cannot inject them:

- in `finder`, after a non-empty selection: `04-shell/07 R2 logs the pick
  here — the channel name is in hand at this line and nowhere else (L-4)`.
- no `_recents_*` defs here. 04-shell/07 owns the log, the `quicklist`
  cable, its runner, and the `quicklist` dispatch arm in spec03's
  `tv_remote`.

## Acceptance

- [x] `nu -n -c 'source home/dot_config/nushell/finder.nu'` exits 0; the
      file contains no `$env.config` write and no keybinding record.
      Run directly: `rc=0`. Gate:
      `PASS  tree: finder.nu parses standalone under nu -n` and
      `PASS  tree: finder.nu is defs only — no $env.config write, no
      keybinding record`.
- [x] With a recording tv stub returning one existing and one nonexistent
      path, `finder --start files` returns only the existing path,
      expanded; the stub's argv log shows
      `enter="confirm_selection";tab="toggle_selection"`.
      `PASS  hermetic: finder --start files keeps only the existing path,
      expanded (got ["…/m-tv/home/ok-file.txt"])` and
      `PASS  hermetic: …and the argv log carries the un-hijack (R1:
      enter=confirm, tab=toggle; got: tv files --keybindings
      enter="confirm_selection";tab="toggle_selection")`.
- [x] With the stub returning bare hashes for `git-log`, the decode is
      `[{hash: …}]` — no `subject` column — and `_finder_open` on it runs
      `git show <hash>` (L-2: this check has never passed against the live
      config).
      `PASS  hermetic: finder --start git-log decodes bare hashes to {hash}
      rows (got [{"hash":"01729f5"}])`,
      `PASS  hermetic: …with no subject column (R2b: nothing consumes it and a
      bare hash cannot fill it)`, and
      `PASS  hermetic: _finder_open on the decode runs git show — the scratch
      commit's message is in the output (L-2: never passed against the live
      config)` — observed via `git show`'s own output against a scratch repo,
      not asserted. **L-2 now passes.**
- [x] With the stub returning rows that all fail the FileList existence
      check, `finder --start files` raises a named error instead of
      returning `[]`.
      `PASS  hermetic: all-invalid FileList reply exits non-zero and never
      prints [] (rc=1, out=)` and
      `PASS  hermetic: …and the error names the channel and the row count
      (Error: nu::shell::error x finder: the files decode dropped all 2
      selected rows —)`, with the executed counterfactual
      `PASS  hermetic: counterfactual check-removed finder returns [] silently,
      rc 0 (rc=0, out=[]) — what the gate would then FAIL`.
- [x] `finder --start recent-dirs` decodes as FileList (expanded, existing);
      `/usr/bin/grep -c rcwd` on finder.nu is 0.
      `PASS  hermetic: finder --start recent-dirs decodes as FileList —
      expanded, existing (got ["…/m-tv/home/rd-target"]; L-3)`;
      `/usr/bin/grep -c rcwd home/dot_config/nushell/finder.nu` → `0` (rc 1).
      The gate also runs the executed counterfactual
      `PASS  tree: counterfactual rcwd-match-arm FAILS the type check`.
- [x] `nu -c 'source …/finder.nu; finder'` in a non-tty context errors
      cleanly with the interactive-only message — no panic, exit non-zero.
      `PASS  hermetic: finder under nu -c (no pty, no -i) exits non-zero with
      the interactive-only message (rc=1)` and
      `PASS  hermetic: …and no tv panic string in stderr (tv was never reached:
      argv log has 0 lines)`.
- [x] With the stub emitting `ctrl-p` + a language for `cht`, the next stub
      invocation's argv carries `cht-query` and a `--source-command`
      containing `cht.sh/<lang>/:list`.
      `PASS  hermetic: a ctrl-p pick on cht pipes into cht-query and decodes
      {sheet} (got [{"sheet":"python/lambda"}])`,
      `PASS  hermetic: …first invocation ran cht with --expect ctrl-p`, and
      `PASS  hermetic: …second invocation ran cht-query with a
      --source-command carrying cht.sh/python/:list and the python/ prefix`.

## Verify

```sh
nu -n -c 'source home/dot_config/nushell/finder.nu'
bash tests/shell-television.sh   # spec04's gate runs every box above
```
