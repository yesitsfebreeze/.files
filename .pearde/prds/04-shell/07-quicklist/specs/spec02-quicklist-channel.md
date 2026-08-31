---
est: 0.75h
footprint:
  - home/dot_config/nushell/quicklist.nu
  - home/dot_config/television/cable/quicklist.toml
  - home/dot_config/nushell/config.nu
  - tests/shell-quicklist.sh
  - tests/shell-television.sh
  - tests/nushell-core.sh
  - tests/nushell-aliases.sh
  - tests/shell-claude.sh
  - tests/shell-help.sh
  - tests/shell-history.sh
  - tests/shell-listing.sh
  - tests/shell-zoxide.sh
  - gates/manual/wave5.md
---

# spec02 — the quicklist channel, its runner, `Ctrl-Q` and the remote arm

Land R3 and R4 on top of spec01's log: the `quicklist` cable channel, the
runner that dispatches `enter` (open) and `ctrl-r` (replay), the `Ctrl-Q`
keybinding, and the `tv_remote` arm that makes the channel reachable from the
channels remote. Depends on spec01 having landed the log; do not start before
it.

## `home/dot_config/television/cable/quicklist.toml` (new)

```toml
[metadata]
name = "quicklist"
description = "Recent picks across every channel — enter opens by type, ctrl-r replays in its cwd"
requirements = ["nu"]

[source]
command = "nu -n -c 'source ~/.config/nushell/dirstack.nu; source ~/.config/nushell/recents.nu; _recents_lines'"
no_sort = true
frecency = false
display = "{split:\\t:1}    ({split:\\t:3})  {split:\\t:2}"
output = "{}"
```

Four things carry their reason in a comment above them:

* **Two `source`s, not one.** `recents.nu` reuses `dirstack.nu`'s `_state_dir`
  so the state directory has exactly one definition (spec01), so the `nu -n`
  needs both files. `recent-dirs.toml` already uses this idiom for
  `_dirstack_list`. `nu -n` loads no config, which is the latency reason
  `nu-history.toml` records.
* **`no_sort = true` / `frecency = false` are load-bearing, and the live cable
  file has neither.** The log is already newest-first and the cap makes any
  re-ranking wrong; without these two keys tv reorders the rows and R1's
  "newest first" is false at the only place a user sees it. `zoxide.toml` and
  `nu-history.toml` are the precedent for both keys.
* **The `\\t` escaping trap.** `\\t` in TOML reaches tv as the literal escape
  `\t`, which its template engine treats as the tab delimiter. A single `\t`
  in the TOML is a real tab character and the template stops splitting.
* **`output = "{}"` emits the whole row**, because the runner needs the kind
  (to open) and the cwd and channel (to replay), not just the display column.
* No `[preview]`: a row's value may be a path, a grep row or a bare hash, and
  one preview command cannot be right for all three. Out of scope.

Field indexes are `0` kind, `1` value, `2` cwd, `3` channel — spec01's
four-field row.

## `home/dot_config/nushell/quicklist.nu` (new)

Sourced **after** `finder.nu` at MODULES, because its bodies call
`_finder_decode`, `_finder_open`, `_finder_parse` and `finder`, and nushell
binds a def body's calls at parse time. Put the line directly below
`source ~/.config/nushell/finder.nu`.

| def | contract |
|---|---|
| `_recents_entry [line]` | split one TAB row back into `{kind, value, cwd, channel}`, each field defaulted (`kind` → `"Any"`, `cwd` → `$env.PWD`) |
| `_recents_open [entry]` (`--env`) | `_finder_decode { produces: $entry.kind, results: [$entry.value] }` then `_finder_open` |
| `_recents_replay [entry]` (`--env`) | `cd` the entry's cwd when it still exists, then `_finder_open (finder --start $entry.channel)` |
| `quicklist` (`export def --env`) | the runner: guard, empty-state, one `tv` call, dispatch |

`quicklist`, in order:

1. `if not $nu.is-interactive { return }`. **Not** the live spelling: measured
   on the pinned 0.114.1, a parenthesised `is-terminal` as an `if` condition
   captures stdout and is false unconditionally, on a terminal or off one
   (config.nu's PALETTE anchor carries the measurement). Keep the banned
   spelling out of the file entirely, so a grep hit is proof of a regression —
   `zoxide.nu`'s convention.
2. **R4:** `if (_recents_load | is-empty) { print "…"; return }` — one line of
   hint, and tv is never spawned. The shipped manual entry
   (`help/shell.nuon`, `Ctrl-Q`) already promises "an empty log prints a hint
   rather than an empty picker", so this is what makes that entry true.
3. One `tv quicklist` call with `--input-header`, the un-hijack
   (`enter="confirm_selection"`) and `--expect 'ctrl-r'`. The un-hijack rides
   this invocation like every other (finder.nu's header): our own cable file
   binds no `enter`, but the flag costs nothing and survives someone adding
   one.
4. `_finder_parse` the raw output — reused verbatim, which is what finder.nu's
   comment at `_finder_parse` reserves it for. `ctrl-r` → replay, anything
   else → open.

**`ctrl-r` here means replay and does not collide with anything**: this is its
own `tv` invocation, and the reedline `Ctrl-R` history binding is a different
surface entirely.

One case R3 leaves undefined, resolved here at minimum size: an entry whose
`kind` is `Any` (the untyped channels — `zoxide`, `git-branch`, `alias`,
`env`, `nu-history`, `cht`) decodes to a bare string, and `_finder_open`'s
else-branch would `cd` a directory, otherwise open `$EDITOR` on it. For a
branch name or an env var that means the editor on a file that does not
exist. So `_recents_open` opens an `Any` entry only when its value resolves to
an existing path, and otherwise prints one line naming `ctrl-r` as the way to
act on it. The alternative — not logging untyped channels at all — was
declined: it would empty "cross-channel recents" of most of its channels.

## `home/dot_config/nushell/config.nu`

Three edits, all inside the sections that already reserve them:

1. `source ~/.config/nushell/quicklist.nu`, directly below `finder.nu` at
   MODULES.
2. The `tv_remote` arm, beside the `theme` arm and for the same reason: a
   quicklist row is a TAB-delimited record, and the generic chain would hand
   it to `_finder_open` as a path. Add
   `if ($channel == "quicklist") { quicklist; return }` and delete the
   "when 04-shell/07 lands" future tense from the two comments that carry it
   (lines ~630 and ~656-658).
3. The keybinding record at KEYBINDINGS, appended as its own block after
   television's three — never interleaved, because that node's gate asserts
   its three sit together:

```
{
    name: quicklist
    modifier: control
    keycode: char_q
    mode: [vi_normal vi_insert emacs]
    event: { send: executehostcommand, cmd: "quicklist" }
}
```

`name: quicklist` is **not** free choice: `help/shell.nuon`'s `Ctrl-Q` entry
carries `verify: [{kind: "keybinding", name: "quicklist"}]`, and 06-help/04's
`--check` will resolve that name against this record. Renaming it breaks a
shipped manual entry.

Two collision claims, measured rather than carried:

* Reedline's default table has **no** `Ctrl-Q` binding at all — measured on
  the pinned 0.114.1, `keybindings default | where ($it.code | str contains
  "q")` returns an empty list. The live config's comment says this record
  "overrides reedline's default ctrl+q (reverse history search)"; do not carry
  that sentence, it does not reproduce.
* `tv init nu` binds only `char_t` and `char_r`, and WezTerm's only `q` key is
  `CTRL|SHIFT`+`q` (window close, wezterm.lua:1145). So nothing competes, and
  the record needs no "wins over" reason — it sits at KEYBINDINGS because that
  anchor is where records go.

No `help/*.nuon` edit in this spec, and that is deliberate: `help/shell.nuon`
already ships the `Ctrl-Q` entry with the `use` text this spec makes true
(newest-first, enter opens by type, ctrl-r replays in the recorded cwd, empty
log prints a hint). Editing an entry would stale its review digest and drag
`help/why-review.nuon` and `help/use-review.nuon` into the footprint for no
gain. **If** the implementer finds the shipped entry contradicted by what it
built, that is a finding for the report, not an edit here.

## `tests/shell-television.sh` — the census flip

`census_ok` (:130-147) currently lists `quicklist` in `DROPPED`, i.e. it
asserts `cable/quicklist.toml` does **not** exist — correct while the channel
had no logger, and red the moment this spec ships the file. Move `quicklist`
from `DROPPED` into `CURATED`, and update the three places that say "15
curated channels" (:3, :130, :373) to 16. That flip is the whole reason
04-shell/04's why-review note flagged quicklist as "named but has no cable
file in this tree"; the note needs no edit, the condition it flagged is gone.

Also add `quicklist` and `recents` to the `for m in …` staging list (:471) if
spec01 has not already added `recents`.

## Staging, again

`gates/nushell-module-staging.sh` requires every nushell-staging gate to stage
every module `config.nu` sources, so `quicklist.nu` goes into the same eight
files spec01 touched: one `cp` line each in `nushell-core.sh`,
`nushell-aliases.sh`, `shell-claude.sh`, `shell-history.sh`,
`shell-listing.sh`, `shell-zoxide.sh`; the `MODULES=` string in
`shell-help.sh` (:101); the `for m in …` list in `shell-television.sh` (:471).

## `gates/manual/wave5.md`

Add one S.7 entry for what a stub cannot prove: with **real** tv, that the
rendered quicklist rows are in the log's order (the `no_sort`/`frecency` keys
doing their job), that the display columns read as value / channel / cwd, and
that `Ctrl-Q` reaches the runner from a live prompt. Unticked, like every box
in that file.

## `tests/shell-quicklist.sh` — the second half

Extend spec01's gate. `--tree` gains the cable-file and config-wiring claims;
`--hermetic` gains the dispatch scenarios. The tv stub records argv **and its
own PWD** per invocation — the replay boxes are assertions about the directory
tv was spawned in, and there is no other way to see it. Most boxes need no
pty: `nu -i -c` sets `$nu.is-interactive` true without one (measured, 0.114.1;
shell-television.sh's header carries it), so only the `Ctrl-Q` keystroke box
uses the pty runner, with `@SEND=\x11`.

Every mutated-copy counterfactual prints the copy's sha before and after on
one line, asserts RED before the repair with the FAIL naming the subject, and
asserts the repair moves the sha back — per
[`a-counterfactual-proves-its-own-mutation`(../../../../../prds/memos/a-counterfactual-proves-its-own-mutation.md).

## Acceptance

- [x] `cable/quicklist.toml` exists, carries `no_sort = true`,
      `frecency = false`, `output = "{}"`, the two-`source` `nu -n` command and
      the `\\t` display template; the cable dir holds no hex color
- [x] `bash tests/shell-television.sh --tree` is green with `quicklist` in
      `CURATED`; a copy of the gate with `quicklist` left in `DROPPED` FAILS
      `census_ok` against the real tree (sha pair on one line)
- [x] `config.nu` sources `quicklist.nu` exactly once, under MODULES, strictly
      after `finder.nu`; a copy with the two lines swapped FAILS the check
- [x] `config.nu` holds exactly one keybinding record named `quicklist`, with
      `modifier: control`, `keycode: char_q` and
      `cmd: "quicklist"`, appended after television's three records
- [x] the record's name matches the `verify` target in `help/shell.nuon`'s
      `Ctrl-Q` entry — grep both, assert equal, so a rename cannot pass
- [x] `quicklist.nu` contains the banned `is-terminal` guard spelling zero
      times and `if not $nu.is-interactive { return }` once
- [x] hermetic, R4: `nu -i -c 'quicklist'` with no log file prints one line of
      hint, exits 0, and spawns the tv stub **zero** times (the stub's argv
      log is absent or empty)
- [x] hermetic, R3 enter → dir: a seeded log whose head is a `DirList`/`zoxide`
      entry for an existing scratch dir; the stub replies that row with an
      empty `--expect` first line; `quicklist` leaves PWD at that dir
- [x] hermetic, R3 enter → file: a `FileList`/`files` entry replays through
      `_finder_decode` and the recording `nvim` stub is invoked with that path
- [x] hermetic, R3 enter → grep: a `GrepList`/`text` entry whose value is
      `<file>:12:hit` invokes the editor stub with `+12` and the file
- [x] hermetic, R3 enter → commit: a `Commits`/`git-log` entry whose value is
      a bare hash from a real scratch commit reaches `git show` — the L-2
      decode path, on a single stored value
- [x] hermetic, R3 `ctrl-r` replay: a `GrepList`/`text` entry recorded in
      scratch dir A, `quicklist` run from scratch dir B, stub first line
      `ctrl-r`: the tv stub's second invocation is `tv text …` and its
      recorded PWD is **A**, and the shell is left in A. This is the box the
      PRD says no live demo can close, because no live entry has ever carried
      a channel other than `zoxide`
- [x] hermetic, `ctrl-r` on an entry whose recorded cwd no longer exists: no
      `cd`, no error, and the channel still opens in the current dir
- [x] hermetic, the `Any` arm: an entry with kind `Any` and a value that is
      not an existing path prints one line naming `ctrl-r` and does **not**
      invoke the editor stub
- [x] hermetic, the remote: `nu -i -c 'tv_remote'` with the channels-picker
      stub replying `quicklist` reaches the runner (the second stub invocation
      is `tv quicklist …`, not `tv quicklist` through the generic chain
      followed by an editor call)
- [x] hermetic, `Ctrl-Q` under the pty: `@SEND=\x11` at a live prompt spawns
      `tv quicklist`; a copy of `config.nu` with the record deleted spawns
      nothing (sha pair on one line)
- [x] `bash gates/nushell-module-staging.sh` reports zero MISS for
      `quicklist.nu` across all eight in-scope gates
- [x] `gates/manual/wave5.md` carries an S.7 entry, unticked, and
      `bash gates/manual-coverage.sh` is green

## Verify and Proof

```sh
bash tests/shell-quicklist.sh
bash tests/shell-television.sh --tree
bash gates/nushell-module-staging.sh
bash gates/manual-coverage.sh
```

Quote each run's PASS/FAIL tail plus the one-line sha pair for every
counterfactual. `bash tests/shell-television.sh --hermetic` is worth a run
after the census flip, but it asserts 04-shell/04's requirements and is not
this spec's proof.

## Proof (implementer, 2026-08-24)

```
bash tests/shell-quicklist.sh          EXIT=0   (111 PASS, 0 FAIL)
bash tests/shell-television.sh --tree  EXIT=0   (quicklist in CURATED, census green)
bash gates/nushell-module-staging.sh   rc=0     (grid: quicklist column all `.`, misses: 0)
bash gates/manual-coverage.sh          rc=0     (S.7 entry present, unticked)
```

The census-flip counterfactual, run against the real tree with a mutated copy
of the gate (`quicklist` put back in `DROPPED`, taken out of `CURATED`):

```
CF census-left-in-DROPPED: sha 9e31e36c04e9 -> 056bb72f481b
mutated-copy rc=1
FAIL  tree: cable census — the 16 curated channels + theme.toml.tmpl, nothing else, no drop-set name
```

In-gate counterfactuals, each with its sha pair on one line, red before the
repair and green after: `cable-lets-tv-resort`,
`cable-display-uses-a-real-tab`, `quicklist-sourced-above-finder`,
`remote-arm-deleted`, `record-renamed`,
`record-interleaved-into-04s-three`, `ctrl-q-record-deleted`.

Three corrections to the spec, measured here:

* **The remote's invocation index.** The spec calls the replay's channel spawn
  "the second stub invocation". It is the second when `quicklist` is started
  directly, and the **third** through `tv_remote`, because
  `_finder_pick_channel` spends two invocations (`tv list-channels`, then the
  channels picker) before dispatching. The gate asserts the argv sequence
  `list-channels, channels, quicklist` rather than a fixed index.
* **The Ctrl-Q reedline claim reproduces.** On the pinned 0.114.1,
  `keybindings default | where ($it.code | str contains "q")` returns `[]`, so
  there is no default `Ctrl-Q` to override. The live sentence is not carried;
  the measurement is recorded beside the record instead. (The column is
  `code`, not `keycode` — `$it.keycode` in that `where` returns all 145 rows
  rather than raising, which is its own trap.)
* **The banned guard spelling had to leave the comments too**, not just the
  code. Naming it in the header that explains why it is absent makes the
  gate's own zero-hit assertion fail. zoxide.nu's header already phrases it as
  "the live spelling" for this reason; quicklist.nu now does the same.

Both pty sessions are additionally asserted timeout-free. A runner timeout
SIGKILLs nu and hands back whatever the buffer held, so an assertion over that
buffer can be true of a session that never finished.
