---
est: 0.75h
footprint:
  - home/dot_config/nushell/recents.nu
  - home/dot_config/nushell/finder.nu
  - home/dot_config/nushell/zoxide.nu
  - home/dot_config/nushell/config.nu
  - tests/shell-quicklist.sh
  - tests/shell-zoxide.sh
  - tests/shell-television.sh
  - tests/nushell-core.sh
  - tests/nushell-aliases.sh
  - tests/shell-claude.sh
  - tests/shell-help.sh
  - tests/shell-history.sh
  - tests/shell-listing.sh
---

# spec01 — the recents log and its five producers

Land R1 and R2: one nuon recency log in XDG state, and the five sites that
write it — the three zoxide wrappers, the bare-word fallback, and `finder`
itself (the **L-4** fix). No picker, no keybinding, no cable file: that is
spec02. When this spec is done the log fills correctly and nothing reads it
yet.

## The parse-order constraint that decides the file layout

Nushell binds a def body's calls at parse time, and this node has a genuine
cycle:

* `zoxide.nu` (MODULES, before `finder.nu`) and `finder.nu` itself both
  **call** `_recents_add`, so the log must be parsed before both;
* the quicklist runner (spec02) **calls** `_finder_decode`, `_finder_open`,
  `_finder_parse` and `finder`, so it must be parsed after `finder.nu`.

One file cannot sit on both sides, so the node ships **two** modules:
`recents.nu` (this spec — the log, no dependencies) and `quicklist.nu`
(spec02 — the runner). `config.nu`'s MODULES comment currently anticipates a
single `quicklist.nu`; update that comment in this spec so the next reader
finds the reason rather than the guess.

Insert the source line **between `claude.nu` and `zoxide.nu`**:

```
source ~/.config/nushell/pass.nu
source ~/.config/nushell/claude.nu
source ~/.config/nushell/recents.nu      # NEW
source ~/.config/nushell/zoxide.nu
...
source ~/.config/nushell/finder.nu
```

That position keeps every ordering claim the sibling gates already assert
(`claude.nu` after `pass.nu`, `zoxide.nu` after `claude.nu`, `history.nu`
after `zoxide.nu`, `finder.nu` after `capsule.nu`, all before PALETTE) — an
inserted line between two of them does not break an "after" comparison.

## `home/dot_config/nushell/recents.nu` (new)

Defs only, no config-record write, no keybinding, no hook. It must parse
standalone under `nu -n`, because spec02's cable file source-commands it.

| def | contract |
|---|---|
| `_recents_file` | `(_state_dir) \| path join "recents.nuon"` |
| `_recents_key` | `$"($e.channel)(char us)($e.value)"` — the dedup key, one definition |
| `_recents_load` | the parsed log, or `[]` for a missing/empty/corrupt file (`try`/`catch`) |
| `_recents_add [kind, value, channel]` | prepend, dedup by `_recents_key`, `first 200`, `to nuon \| save -f` |
| `_recents_lines` | the cable's source rows: one TAB-joined `kind value cwd channel` line per entry, newest first |

Four load-bearing decisions, each with its reason in the file header:

1. **The state directory is `dirstack.nu`'s `_state_dir`, not a second
   computation.** `dirstack.nu` is sourced at the FUNNEL anchor (config.nu:309),
   well before MODULES, and it exports `_state_dir` precisely so "there is
   exactly one definition of the directory". So the log is
   `<XDG_STATE_HOME|~/.local/state>/nushell/recents.nuon`. This deliberately
   **differs from the live config**, which computed its own `$env.HOME`-rooted
   `.../state/finder/` path: `$nu.home-dir` and `$env.HOME` differ on this
   host under a symlinked TMPDIR (dirstack.nu:37-40), and a second path
   computation is the divergence env.nu already has to be gate-pinned against.
   The cost is that `recents.nu` does not parse standalone on its own — the
   cable command sources `dirstack.nu` first, exactly as `recent-dirs.toml`
   already does.
2. **The row has four fields, not five.** Live carries a `query` column that
   is written `""` at every call site and read by nothing. R1 names kind,
   value, channel, cwd and timestamp and does not name a query, so the field
   is dropped. The display template indexes (`0` kind, `1` value, `2` cwd,
   `3` channel) are unchanged by the drop, so spec02's template is the live
   one.
3. **`ts: (date now)` is stored and not read.** R1 requires it; ordering is
   positional (newest-first on write), so nothing sorts by it. Say so, so the
   next reader does not add a sort that the cap already makes wrong.
4. **No `--env` on any def here**, and the reason is dirstack.nu's: these
   helpers only write a file. The `cd` that prompted the write already
   happened in the caller.

## `home/dot_config/nushell/zoxide.nu` — delete the shim

Delete `def _recents_add [kind: string, value: string, channel: string] {}`
(zoxide.nu:35) and rewrite the RECENTS SEAM paragraph in the header to
describe what now exists: the real logger lives in `recents.nu`, sourced
above this file at MODULES, and the four call sites in this file bind to it at
parse. **The four call sites do not change** — they are already correctly
placed and correctly tagged.

## `home/dot_config/nushell/finder.nu` — the L-4 fix

At the comment-marked line inside `finder` (finder.nu:89-90), log the pick.
Three points the implementer must not improvise:

* **Log after the empty-decode check, not before it.** The marked comment sits
  above the decode; move the call below the `error make`, so a pick whose
  channel and decoder disagree never enters a log whose whole purpose is to
  be replayable. Update the comment in place.
* **Store the RAW pick line plus the channel's `produces` name** —
  `_recents_add (_finder_type $channel) $line $channel`, once per selected
  entry (tab multi-selects). `_recents_open` re-decodes with that same
  `produces`, so the stored pair reproduces exactly what `finder` returned.
  This is the reuse finder.nu's own comment reserves: the empty-decode check
  lives in `finder` and not in `_finder_decode` because "04-shell/07 reuses
  the decoder on single stored values".
* **The `cht` branch logs too**, before its two returns (kind `Any` for the
  raw `cht` pick, `ChtSheet` for a `cht-query` sheet). A sheet pick is a
  finder pick; R2 says finder picks log.

## `home/dot_config/nushell/config.nu`

Only the MODULES source line above, plus the comment repairs: the MODULES
paragraph (line 538) and the finder-seam note it pairs with. Do not touch
KEYBINDINGS or the entry points — those are spec02's.

## The gates this change breaks, and the repairs

`gates/nushell-module-staging.sh` derives the module set from `config.nu`'s
own `source` lines and requires **every** gate that stages a nushell machine
to stage **every** module — a `source` of a missing file is a parse error
that discards the whole of config.nu and leaves a working but naked REPL, so a
gate that misses the new module dies before its first assertion. Add
`recents.nu` to all eight stagers:

| file | edit |
|---|---|
| `tests/nushell-core.sh` | one `cp` line beside the others (~:311-320) |
| `tests/nushell-aliases.sh` | one `cp` line (~:118-127) |
| `tests/shell-claude.sh` | one `cp` line (~:326-335) |
| `tests/shell-history.sh` | one `cp` line (~:532-541) |
| `tests/shell-listing.sh` | one `cp` line (~:357-366) |
| `tests/shell-zoxide.sh` | one `cp` line (~:517-526) |
| `tests/shell-help.sh` | add `recents.nu` to `MODULES=` (:101) |
| `tests/shell-television.sh` | add `recents` to the `for m in …` list (:471) |

`tests/shell-zoxide.sh` additionally pins the shim this spec deletes, in two
predicates, and both must be **repaired rather than loosened**:

* `defs_ok` (:146-161) lists `def _recents_add [` first in zoxide.nu's parse
  order. Drop that element; the remaining twelve keep their strict order.
* `recents_ok` (:203-211) keeps its four-call-sites-all-`"zoxide"` count
  (those are unchanged and still the point), and its three shim greps
  (`04-shell/07`, `ABOVE this file`, `delete the shim`) are **replaced**, not
  deleted, by greps for the rewritten seam paragraph — a check that stops
  asserting anything is the failure mode
  [`a-counterfactual-proves-its-own-mutation`(../../../../../prds/memos/a-counterfactual-proves-its-own-mutation.md)
  names as equal in size to a vacuous green. The existing counterfactual at
  :441-443 (a copy with the fallback call site dropped must FAIL
  `recents_ok`) must still fail; add one for the header half the same way.

## `tests/shell-quicklist.sh` (new)

Create the gate with two stages, `--tree` and `--hermetic`, and no argument
running both — modelled on `tests/shell-television.sh`, whose harness
(`mk_machine`, `reset_stub`, `nu_i`, `nu_c`, the sha epilogue) is the one to
copy. No `--selftest`: this file is registered `external`, which
`gates/selftest.sh` reports as unverified-by-contract rather than failing, and
`shell-television.sh` sets the precedent of carrying inline counterfactuals
instead.

Rules carried from the sibling gates, not optional: `/usr/bin/grep` always
(plain `grep` is ugrep here); every `nu` run under `env -i` with a scratch
`HOME` and `XDG_CONFIG_HOME` pinned; the live history db never read; the
banned guard spelling assembled from fragments so this script's own text is
never a hit; a sha epilogue proving the managed files are byte-identical
afterwards.

**Every mutated-copy counterfactual in this file follows the memo**: print the
copy's sha before and after the mutation on **one line**, assert the copy is
RED with the FAIL naming the gate and the subject, and assert the repair moves
the sha back. An end-state grep for what the mutation was supposed to produce
is not proof — it passes identically when the `sed` matched nothing.

## Acceptance

- [x] `home/dot_config/nushell/recents.nu` exists, holds the five defs above
      and nothing else, and contains no `$env.config` write, no
      `upsert keybindings`, no hook append and no `--env`
- [x] `config.nu` sources `recents.nu` exactly once, under MODULES, strictly
      after `claude.nu` and strictly before both `zoxide.nu` and `finder.nu`;
      a copy with the line moved below `zoxide.nu` FAILS the same check
- [x] `zoxide.nu` contains no `def _recents_add [`, still contains exactly
      four `_recents_add "` call sites, all tagged `"zoxide"`, and its header
      names `recents.nu` as the logger sourced above it
- [x] `finder.nu` calls `_recents_add` at least once, and every call site sits
      **below** the `error make` of the empty-decode check in its branch
- [x] hermetic: on a scratch machine with no log file, `_recents_add` creates
      `<HOME>/.local/state/nushell/recents.nuon`, and `open` on it returns one
      record carrying kind, value, channel, cwd and a non-null `ts`
- [x] hermetic: adding the same channel+value twice leaves **one** entry, at
      the head; adding the same value under a different channel leaves two
- [x] hermetic: 205 adds leave exactly 200 entries and the oldest five are
      gone
- [x] hermetic: `nu -i -c 'z <existing dir>'` against the scratch machine
      appends a `DirList`/`zoxide` entry whose `value` is the moved-to dir;
      `z <no such token>` (zoxide stub reporting no match) leaves the log
      byte-identical
- [x] hermetic: `nu -i -c 'finder --start files'` with the tv stub replying
      one existing path appends **one** entry with kind `FileList`, channel
      `files`, and `value` equal to the raw stub reply line
- [x] hermetic: `finder --start text` with a stub reply of `<file>:12:hit`
      appends kind `GrepList` and the raw row as `value` — the L-4 behaviour
      that has never run in the live config
- [x] hermetic: a `finder --start files` pick that fails the empty-decode
      check (stub replies two nonexistent paths) raises and leaves the log
      byte-identical — nothing unreplayable is logged
- [x] hermetic: `_recents_lines` emits one TAB-joined four-field row per
      entry, newest first, and `nu -n -c 'source …/dirstack.nu; source
      …/recents.nu; _recents_lines'` produces the same rows with no config
      loaded
- [x] `bash gates/nushell-module-staging.sh` reports zero MISS for
      `recents.nu` across all eight in-scope gates
- [x] `bash tests/shell-zoxide.sh` is green, `defs_ok` no longer names the
      shim, `recents_ok` asserts the rewritten seam paragraph, and both its
      counterfactuals still FAIL as intended (sha pair printed on one line)

## Verify and Proof

```sh
bash tests/shell-quicklist.sh --tree
bash tests/shell-quicklist.sh --hermetic
bash tests/shell-zoxide.sh
bash gates/nushell-module-staging.sh
```

Quote the PASS/FAIL tail of each, and for every counterfactual quote the
one-line sha pair that shows the mutation landed. `bash tests/shell-help.sh`
and `bash tests/nushell-core.sh` are worth a run to confirm the staging edits
took, but they are not this spec's proof: they assert other nodes'
requirements and inherit those nodes' flakes.

## Proof (implementer, 2026-08-24)

Every box above was ticked against a run, not a reading:

```
bash tests/shell-quicklist.sh --tree      EXIT=0
bash tests/shell-quicklist.sh --hermetic  EXIT=0
bash tests/shell-zoxide.sh                EXIT=0   (117 PASS, 0 FAIL)
bash gates/nushell-module-staging.sh      rc=0     (grid: recents column all `.`, misses: 0)
```

`tests/shell-zoxide.sh`'s repaired counterfactuals, sha pairs on one line, all
three RED before the repair and green after it:

```
CF-A fallback-call-site-dropped: sha c962b7ee55a3 -> 42e3ccc218be
CF-B seam-names-the-wrong-module: sha c962b7ee55a3 -> d7f0589bfad8
CF-C shim-reintroduced:          sha c962b7ee55a3 -> fe101f275b5c
```

CF-C is one the spec did not ask for and the deletion made necessary:
`recents_ok` now asserts the shim's ABSENCE, and nothing else in the suite
would notice a shadowing no-op re-appearing above the call sites.

Side runs confirming the staging edits took (not this spec's proof — they
assert other nodes' requirements): `bash tests/shell-help.sh` rc=0,
`bash tests/nushell-core.sh` rc=0.

Two things measured differently from the spec, both re-derived rather than
trusted:

* `_recents_load` needs TWO guards, not one. On the pinned 0.114.1
  `"" | from nuon` returns **null** rather than raising, and a list of records
  describes as `table<...>`, not `list<...>` — so a `try`/`catch` plus a
  `list` prefix test rejects every log the file writes. Both are in the def's
  comment.
* the purity and state-path greps read **code only**. recents.nu's header
  explains why it has no hook, no `--env` and no second path computation,
  naming each, so a whole-file grep matches the paragraph promising their
  absence. `tests/capsule-recents.sh` already draws this line.
