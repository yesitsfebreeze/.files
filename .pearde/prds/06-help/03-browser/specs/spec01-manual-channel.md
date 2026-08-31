---
est: 1h
footprint:
  - home/dot_config/television/cable/manual.toml
  - home/dot_config/nushell/help.nu
  - home/dot_config/nushell/finder.nu
  - home/dot_config/nushell/config.nu
  - home/dot_config/nushell/help/shell.nuon
  - home/dot_config/nushell/help/why-review.nuon
  - home/dot_config/nushell/help/use-review.nuon
  - tests/shell-television.sh
  - tests/shell-help.sh
---

# spec01 — the `manual` cable channel, its two renderers, and the wiring

Ship the fuzzy browser as a television channel plus a small runner, the shape
[`04-shell/07-quicklist`](../../../04-shell/07-quicklist/prd.md) just landed
(111 PASS): one cable file, three `def`s in the existing `help.nu`, one
dispatch arm in `tv_remote`, one token in `finder.nu`. No new nushell module —
`help.nu` is already sourced below `finder.nu` at config.nu's MODULES anchor,
which is exactly the parse position the runner needs, and 02-help-command's
own `--fuzzy` branch comment hands this branch over by name.

Everything below was measured on this machine on 2026-08-24 (tv 0.15.9,
nushell 0.114.1, 15-min load 6.36) unless it says otherwise.

## The channel is named `manual`, not `help` — measured

`help` is a **clap subcommand of `tv`**, so a channel of that name is
unreachable by the tool's own CLI. Measured with a scratch
`XDG_CONFIG_HOME` holding one cable file named `help`:

| invocation | result |
|---|---|
| `tv list-channels` | lists `help` (so it *looks* installed) |
| `tv help` | prints tv's own usage, rc 0 — the channel never opens |
| `tv -- help` | reaches the channel (crashes on the missing TTY, like `tv files`) |
| `tv manual …` | reaches the channel; `manual` is neither a subcommand nor a builtin channel |

`tv -- help` works but puts every flag before a `--`, and it does not save the
two generic paths: `finder --start help` and `Ctrl-T` both run `tv <channel>`
with flags, so a channel named `help` would hand **tv's usage text** to
`_finder_decode` as rows and then to `_finder_open` as a path. The name
`manual` costs one thing — typing "help" in the `Ctrl-Space` remote does not
match it, because `_finder_pick_channel` matches on channel *names* only
(`finder.nu:150`) — and that is the trade this spec takes. PRD R1 says "a
`help` cable channel"; implement `manual` and let the report carry the finding.

## 1 — `home/dot_config/television/cable/manual.toml` (new)

Copy `cable/quicklist.toml`'s discipline, including its header comments' habit
of stating the reason beside the key.

- `[metadata]` — `name = "manual"`, a one-line `description` naming what
  `enter` and `ctrl-o` do, `requirements = ["nu"]`.
- `[source] command` — one `nu -n`, single-quoted, exactly the idiom
  `quicklist.toml` and `nu-history.toml` use and for the reason
  `nu-history.toml` records (television hands the line to `$SHELL`, and a
  bourne fallback would expand `$vars` inside double quotes to nothing;
  `nu -n` also skips the full config load, which is the latency reason):

      command = "nu -n -c 'source ~/.config/nushell/help.nu; _help_rows'"

- `display` — a **basic** TOML string carrying `\\t`, never a real tab. `\\t`
  in the TOML reaches tv as the two-character escape `\t`, which is what its
  template engine splits on; a real tab, or a single backslash, stops the
  split. Show topic, id and title, e.g.
  `display = "{split:\\t:0}  {split:\\t:1} — {split:\\t:2}"`.
- `output = "{}"` — the whole row, because the runner needs the id column
  `display` shows and the caller cannot recover a field tv did not emit.
- `[preview] command` — the fourth field, the **row index**, unquoted:

      command = "nu -n -c 'source ~/.config/nushell/help.nu; _help_preview {split:\\t:3}'"

  **Why an index and not the id, measured:** tv substitutes template fields
  textually into a line it hands to `$SHELL`, and one live entry id is
  `Neovim's own LSP keys` — an apostrophe that closes the shell quote around
  it. An integer has no shell-hostile character at all. This is the only
  reason the fourth field exists; the runner identifies entries by id.
- `[ui] preview_panel = { size = 55 }` — the `use` paragraph is long
  (`cht.toml` sets 50 for the same reason).
- **No `[keybindings]` and no `[actions.*]`.** `enter` is un-hijacked on the
  CLI by the runner, exactly as `quicklist.toml` does it, and `ctrl-o` must
  reach the runner rather than fork a shell command out of the picker.
- **No `no_sort` / `frecency` keys.** The opposite of `quicklist.toml`, and
  deliberately: this channel *is* a search, so tv's match ranking is the
  point. Say so in the header, next to a pointer at `quicklist.toml`'s
  contrary keys, so the next reader does not "fix" one into the other. Row
  order is irrelevant to correctness because the index rides in the row.
- No hex colour anywhere (`tests/shell-television.sh:hexfree_ok` is a
  gate over the whole cable dir).

## 2 — three `def`s in `home/dot_config/nushell/help.nu`

The file's own rules bind: layout only and never content, no ANSI, and every
failure loud. The three defs go below the existing renders.

**`_help_rows [--mode: string]`** — one TAB row per entry, joined with
`str join (char nl)` (no trailing newline: `_recents_lines` does the same and
the deployed quicklist channel proves tv is fine with it). Fields, in order:
`topic`, `id`, `title`, **index**.

> **The index is the entry's position in the FULL corpus, computed *before*
> any `--mode` filter.** `enumerate` first, `_help_by_mode` second. The cable
> file's preview command is fixed while the source command can be overridden
> per call, so an index counted over a filtered subset would make the preview
> name a different entry than the row it is previewing. This is the one
> invariant in this spec that a reader will get wrong.

**`_help_preview [i: int]`** — the focused entry in full: `title`, blank,
`use`, then `why:` and `also:` when present, then `source:`. R2's four fields.
It must **not** reuse `_help_entry_detail`: that def ends a `command`-kind
entry with `(core-help $name)`, and `core-help` is an alias defined in
`config.nu`, so under the cable's `nu -n` it binds as an *external* at parse
and dies at runtime inside the preview pane. An out-of-range index returns one
`help: no entry at row <i>` line rather than raising, because a preview pane
is not a place to read a stack trace.

**`_help_browse [q: string, m: string]`** — the runner. Guard, one tv call,
dispatch:

1. `if not $nu.is-interactive { }` is *not* here — clause order lives in the
   `--fuzzy` branch below, so this def is only ever called interactively.
2. `if (which tv | is-empty) { error make … }` naming tv as the required
   dependency, `finder`'s wording.
3. One invocation, un-hijacked like every other (`finder.nu`'s header rule):

       tv manual --input-header "manual    [enter] print   [ctrl-o] open its PRD   [esc] back" --keybindings 'enter="confirm_selection"' --expect ctrl-o

   plus `--input $q` when `$q` is non-empty (tv's `-i/--input` prefills the
   prompt — so `help --fuzzy select` prefills interactively and filters
   non-interactively, one meaning for the argument), plus
   `--source-command "nu -n -c 'source ~/.config/nushell/help.nu; _help_rows --mode <m>'"`
   when `--mode` was given. Overriding a channel's source per call is
   `_finder_pick_channel`'s own idiom (`finder.nu:155`). All four flags parse
   together in one argv — verified: the run reaches the TUI (and crashes on
   the absent TTY), while a bogus flag gives a clap error instead.
4. Wrap in `try { } catch { "" }`, then `_finder_parse` it, then take the
   first non-blank row. Empty → return nothing.
5. Split the row on `(char tab)`, take field 1 as the id.
   - `enter` → return `(_help_entry_detail $id)`. Returning the string is
     what leaves the detail in the scrollback after tv exits, and it reuses
     02's renderer so a `command` entry still ends with its `std/help` tail.
   - `ctrl-o` → resolve and open the entry's `source` (below).

**`ctrl-o`'s repo resolution — one resolution, no fallback chain.** Entry
`source` values are repo-root relative (`prds/04-shell/03-zoxide/prd.md`), and
the deployed corpus does not know where the repo is. Resolve it as
`^chezmoi source-path | path dirname`: `.chezmoiroot` is `home`, so
`source-path` reports `<repo>/home` and its dirname is the repo root, and
`just cutover` (`chezmoi init --source "<repo>"`) is what makes that this
repo. `chezmoi` is in install.sh's required set, so its absence is a broken
machine — say so and stop.

Then **require the resolved file to exist before spawning the editor.** It
does not today: measured, `chezmoi source-path` reports
`/Users/feb/dev/.files/home` on this machine because the cutover has not run,
and `/Users/feb/dev/.files` holds no `prds/`. On that path print one line
naming the resolved path and `just cutover`, and return — `help.nu`'s
"every failure is loud" rule, and the reason a fallback chain is refused
there applies here word for word: a fallback turns "not found" into "found
somewhere wrong". Otherwise `^$env.EDITOR <resolved path>`.

## 3 — the `--fuzzy` branch, same file

Replace the branch body 02-help-command reserved (its comment says so by
name). Clause order is load-bearing:

```
if $fuzzy {
    if $nu.is-interactive { return (_help_browse $name $m) }
    if ($query | is-empty) { return (_help_all_table $m) }
    return (_help_search_table $name $m)
}
```

The two non-interactive lines are today's behaviour, unchanged: R5's degrade
to `help <query>`, and it is what keeps the shipped `help --fuzzy` entry's
last sentence true. Delete the "until then" half of the comment above the
branch and leave the sentence that says why the flag parses.

## 4 — `home/dot_config/nushell/finder.nu`: one token

`_finder_parse`'s `known` list is `["ctrl-p" "ctrl-b" "ctrl-n" "ctrl-r"
"enter" "esc"]`. `ctrl-o` is absent, so the def's else-branch returns
`{key: "enter", entries: $lines}` **with the literal `ctrl-o` line as the
first entry** — the browser's `ctrl-o` would silently print the detail for a
nonexistent entry. Add `"ctrl-o"` to the list with a one-line comment naming
this node. No gate pins that list today (checked), and no existing caller
regresses: a channel row equal to `ctrl-o` is the same negligible risk the
six existing keys already carry.

## 5 — `config.nu`: the third `tv_remote` arm

`tv_remote`'s comment says "TWO channels are dispatched to their own runner
rather than through the generic chain … what the channel emits is not a
path." `manual` is the third instance of exactly that: its row is
TAB-delimited and the generic chain would hand the whole row to
`_finder_open`. Add

```
if ($channel == "manual") { _help_browse "" ""; return }
```

beside the `theme` and `quicklist` arms, and rewrite the comment's count and
its list in the same edit — a stale "TWO" is the kind of line this board
strikes. Parse order is already satisfied: `tv_remote` is defined after
`source ~/.config/nushell/help.nu`. Content between anchors; do not add an
anchor.

## 6 — the manual entry that goes stale, and its review row

`shell.nuon`'s `tv channel` entry carries the curated channel list in its
`why`, and that list becomes false the moment a channel ships. Its review row
(`why-review.nuon:92`) was itself re-recorded for precisely this defect —
"its curated channel list omitted six of the sixteen channels". Add `manual`
to the list, in the same change as the behaviour (the house rule for manual
entries).

The `help --fuzzy` entry itself needs **no edit**: its `use` already promises
the picker, the four preview fields, `enter` into the scrollback, `ctrl-o`
into `$EDITOR`, and the non-TTY degrade — this spec's job is to make that text
true, and leaving it byte-identical keeps its `use`-review row valid.

`why-digest` keys on `use` **and** `why` together, so the `tv channel` row
stales. Re-record it:

- run `nu tests/help-content-model.nu`; its error names the digest to set;
- `author` is the session that wrote the revision, `reviewer` is a **second
  reading pass under a different id** (`impl-H-3` / `impl-H-3-r1`, the
  `implementer-television` / `implementer-television-r1` shape). The gate
  refuses a row whose `reviewer` equals its `author`; a self-vouched row is
  what sent another node to `blocked` this session.
- the note records what was read, in both directions: the new list names
  every channel that ships and names nothing that does not.

`use-review.nuon` is in the footprint because it is the other half of this
file pair, but no `use` or `source` changes here, so expect it to need no
edit. If the content-model gate asks for a row there, something else was
edited by mistake.

## 7 — two sibling gates whose assertions this change flips

Both are `done` nodes' gates, and both must flip **in this change** rather
than be loosened — `tests/shell-television.sh`'s own comment sets that
precedent for the quicklist file ("the assertion had to flip in the same
change rather than be loosened").

- **`tests/shell-television.sh`** — `census_ok` is an exact-set census over
  the cable dir (`CURATED=` plus a reject loop over everything else), so a
  new cable file is red until `manual` joins `CURATED`. Update the count in
  the census comment and in the `chk_ok` label ("the 16 curated channels" →
  17) the same way the quicklist flip did.
- **`tests/shell-help.sh:275`** — `no_spawn_ok` asserts `help.nu` has **zero**
  caret-prefixed `nvim|wezterm|git|tv` spawns, labelled "help.nu spawns
  nothing … (R8)". The browser spawns `tv`, `chezmoi` and `$env.EDITOR`.
  Do **not** let it pass by spelling (`tv` bare and `^chezmoi` both slip the
  current regex — that is worse than a red, because the label keeps claiming
  something the file no longer honours). Re-scope the check to what R8
  actually protects: the **render** path spawns nothing. Assert it over
  `help.nu` with the `_help_browse` body excised, and add a second check that
  `_help_browse` is the only def naming `tv`, `chezmoi` or `$env.EDITOR`, with
  the label saying so. The hermetic "poison tv never invoked" checks stay
  true as they are — every probe there runs `nu -c`, which is
  non-interactive, so `--fuzzy` degrades and never reaches tv; leave them
  alone and say in the comment why they still hold.

## Acceptance

- [x] `tv list-channels` under a scratch `XDG_CONFIG_HOME` staging this
      cable dir lists `manual`, and lists no channel named `help`.
- [x] `nu -n -c 'source <staged>/help.nu; _help_rows'` exits 0 and emits one
      TAB row per corpus entry (92 today), every row has exactly 4
      tab-separated fields, field 3 is an integer, and no field contains a
      tab or a newline.
- [x] Field 3 of row *n* equals *n* for every row, and
      `_help_preview <n>` names the entry whose id is that row's field 1 —
      checked on at least three rows including the last.
- [x] `_help_rows --mode nvim` emits a strict subset whose **indices are the
      unfiltered ones** (they are not `0..<count>`), and `_help_preview` on
      the first of them still names that same entry.
- [x] `_help_preview` on an entry that carries a `why` renders `title`, `use`,
      `why:`, `also:` and `source:`; on `help --fuzzy` (a `command`-kind
      entry) it renders **no** `std/help` block and exits 0 — the
      `core-help`-under-`nu -n` trap.
- [x] `_help_preview 99999` prints one `help: no entry at row` line, rc 0.
- [x] `home/dot_config/nushell/help.nu` still parses standalone under
      `nu -n` with no config loaded — the cable's source and preview both
      depend on it.
- [x] The cable file contains the two-character sequence `\\t` and **no**
      literal tab character; `output = "{}"`; no `[keybindings]`, no
      `[actions.`, no hex colour.
- [x] In a real nushell in a scratch HOME with a recording `tv` stub,
      interactive: `help --fuzzy` invokes tv exactly once, with argv
      containing `manual`, `enter="confirm_selection"`, `--expect ctrl-o` and
      an `--input-header`; `help --fuzzy select` adds `--input select`;
      `help --fuzzy --mode nvim` adds a `--source-command` carrying
      `_help_rows --mode nvim`.
- [x] Same machine, tv replying with an empty first line then a row: the
      command's output is that entry's `_help_entry_detail` render, and the
      recording editor stub was **not** invoked.
- [x] Same machine, tv replying `ctrl-o` then a row, with a `chezmoi` stub
      reporting a scratch `<root>/home` that really holds the entry's PRD:
      the editor stub is invoked exactly once, with that resolved absolute
      path.
- [x] Same, with the stub reporting a root that has no `prds/`: the editor
      stub is **not** invoked, and the printed line carries the resolved path
      and `just cutover`.
- [x] `nu -c 'help --fuzzy'` (non-interactive) with a **poison** tv on PATH
      returns the whole-manual table and never invokes tv;
      `nu -c 'help --fuzzy select'` returns the search table with the
      shift-select entries in it.
- [x] Interactive with **no** `tv` on PATH at all: `help --fuzzy` exits
      non-zero and the message names `tv`.
- [x] `_finder_parse` returns `{key: "ctrl-o", entries: [<row>]}` for
      `"ctrl-o\n<row>"`, and the six pre-existing keys still parse as before.
- [x] `shell.nuon`'s `tv channel` `why` names `manual`; the `help --fuzzy`
      entry is byte-identical to before this change.
- [ ] `nu tests/help-content-model.nu` passes, with the `tv channel`
      `why-review` row re-digested and its `reviewer` different from its
      `author`.
- [x] `bash tests/shell-television.sh` passes with `manual` in the census.
- [x] `bash tests/shell-help.sh` passes with the re-scoped spawn check, and
      the re-scoped check goes **red** on a mutated copy that puts a `tv`
      call inside a render def.
- [x] `bash gates/nushell-module-staging.sh` passes — no module was added, so
      its derived grid must be unchanged.

## Verify and Proof

```sh
bash tests/help-browser.sh          # spec02's gate — the primary proof
bash tests/shell-television.sh      # the flipped cable census
bash tests/shell-help.sh            # the re-scoped spawn check
nu tests/help-content-model.nu      # the re-digested why-review row
bash gates/nushell-module-staging.sh
```

## Proof (implementer, 2026-08-24)

`bash tests/help-browser.sh` — **96 PASS / 0 FAIL, rc 0** (`--tree` 44,
`--hermetic` 54, each green alone). `tests/shell-television.sh` 61/0,
`tests/shell-help.sh` 93/0, `gates/nushell-module-staging.sh` 44/0.
`nu tests/help-content-model.nu` reports **1 violation** — the review row
below, which this session may not write.

Every box above is closed by a named check in `tests/help-browser.sh` except
the last four, which are closed by the sibling gates named in Verify and are
not re-run inside this node's gate.

Measured numbers, as readings of this day and not as pins: **92** corpus
entries, all ids unique, no tab or newline in any field; `--mode nvim` returns
**27** of them carrying indices **43, 44, 45 …** — not `0..27`, which is the
whole point; the cable's source command **37 ms** and its preview command
**33 ms** at 15-minute load 3.70. The gate counts the corpus live and asserts
no timing budget.

Three deviations and corrections, all measured:

1. **spec01 §5's `tv_remote` arm swallows the return value.**
   `{ _help_browse "" ""; return }` discards the detail string, so `enter`
   through Ctrl-Space printed nothing. Shipped as
   `{ return (_help_browse "" "") }`. The theme and quicklist arms are
   correctly value-less; this one renders.
2. **ctrl-o's resolution lives INSIDE `_help_browse`, not in a fourth def** —
   which is what §2's "three `def`s" asks for, and what lets
   `tests/shell-help.sh` assert the re-scoped R8 claim as *help.nu with
   `_help_browse`'s body excised*.
3. **"no `tv` on PATH" is not reachable by the launch environment's PATH.**
   env.nu's PATH repair (R1) APPENDS `/opt/homebrew/bin` unconditionally —
   deliberately, since a GUI-launched WezTerm otherwise loses Homebrew — so
   with only the stub removed `help --fuzzy` reached the REAL tv and crashed
   on the absent TTY. The check sets `$env.PATH` inside the shell instead, and
   the guard then raises with `help: \`tv\` (television) is not installed`.

Two substitutions worth naming rather than hiding:

* The non-interactive degrade is proven against the **recording** tv stub, not
  a poison one, and "never invoked" is read off an EMPTY argv log. That is
  strictly stronger evidence than a poison's non-zero exit, which would only
  show up as a failure downstream.
* `gates/nushell-module-staging.sh`'s derived grid gained a ROW (this node's
  new gate, all `.`) and no COLUMN: no module was added, so the module list it
  derives from config.nu is unchanged, which is what that box contracts.

Also recorded, because the cable file's own comments had to move for it: the
TOML spellings `[keybindings]` and `[actions.` are kept OUT of
`cable/manual.toml` entirely — the comment says it in words — because
`cable_ok` greps for both as absences and a sentence explaining an absence is
otherwise indistinguishable from the thing itself. Same reason a literal
developer home path is kept out of `help.nu`: `tests/shell-help.sh`'s
`corpus_path_ok` greps for `/Users/`, and the first draft of the ctrl-o
comment quoted the measured legacy source path and went red on it.

**The one open box.** Adding `manual` to `shell.nuon`'s `tv channel` `why`
staled that entry's `why-review` digest. `nu tests/help-content-model.nu`
names the digest to set: **`edf405bf05241f37`**. This session wrote the
revision, so it may not also review it — the gate refuses a row whose
`reviewer` equals its `author`. `use-review.nuon` needs no edit, exactly as
§6 predicted: no `use` and no `source` changed anywhere.
