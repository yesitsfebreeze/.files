# The help command

> How `help` and `?` are built, and the four constraints that shape them.

`help` addresses the manual's **entries** — one key, one command, by name —
reading the four `.nuon` surfaces under `~/.config/nushell/help`. `?` addresses
the manual's **prose** — every line of `guide/`, `reference/` and `internals/`,
which `just manual` generates from those same surfaces — and opens the hit in
the editor. Two searches over one corpus, deliberately separate.

The file is 198 lines and defines two names a person types, `help` and `docs`,
with `?` aliased to the second.

## `help.nu`

### Layout only, never content

Every renderer reads the corpus and holds nothing but shape. No description of
a binding, a command or an idiom is written in `help.nu`; a phrase that reads
like manual prose in that file is a bug, because it would be a second source
for something the corpus already says once. The one place a hand-written line
is tempting is the overview's curated first-keys block, and it resolves each id
against the corpus rather than restating its title.

### Defs only

No write to the shell's config record, no keybinding append, no hook — the
`history.nu` precedent, so the file parses standalone under `nu -n`.

### Constraint 1 — the `std/help` capture is in `config.nu`, and cannot move here

Measured on the pinned 0.114.1: `use std/help` and `def help` in ONE file fail
at PARSE with `nu::parser::unknown_flag` pointing into `std/help/mod.nu:795` —
in either order. Nushell predeclares a block's `def`s before parsing its
statements, so the `use` resolves std's `@example {help --find char}` attribute
against OUR predeclared signature, which has no `--find`. A `source`d file is
its own block, so `config.nu` holds

```
use std/help
alias core-help = help
source ~/.config/nushell/help.nu
```

and `help.nu` holds only the `def`. `core-help` is an ALIAS on purpose: alias
targets bind at parse time (the `core-ls` precedent), so it stays bound to
std's `help` after our `def` shadows the name, and the wrapper cannot recurse.
It must also PRECEDE the shadow. The delegation target is std's implementation,
not the builtin — the builtin's `--find` returns an empty list where std's
finds hits.

### Constraint 2 — the corpus is addressed one way and no other

```
def _help_dir [] { $nu.home-dir | path join ".config" "nushell" "help" }
```

`config.nu` holds `source ~/.config/nushell/help.nu`, so the renderer is always
read from that directory; addressing the corpus by the same `~`-literal means
one hardcoded path on both sides that cannot diverge.

The two rejected candidates are kept out of `help.nu` entirely, comment
included, so a grep for either spelling is proof of a regression — the
`history.nu` discipline. They are the launch-time config-dir constant
(`default-config-dir`) and the loaded config file's dirname (`config-path |
path dirname`). Measured on the pinned 0.114.1, 2026-08-23, every run under
`env -i` with HOME and PATH only; D is the constant, P is the dirname, H is the
home-dir expression above, and `~/.config` in the last three columns is short
for `~/.config/nushell`:

```
launch shape                          D          P          H
plain nu, no XDG_CONFIG_HOME          ~/Library  ~/Library  ~/.config
plain nu, XDG_CONFIG_HOME exported    ~/.config  ~/.config  ~/.config
nu --config ~/.config/…, no export    ~/Library  ~/.config  ~/.config
nu --config <other tree>/…, export    the export <other>    ~/.config
```

Three facts settle the choice.

1. **Row three is the defect, and it is the deployed shape.** With `--config`
   naming our tree and no export, D resolved to `~/Library/Application
   Support/nushell` and `help` died with nushell's raw `file_not_found`, rc 1.
   Not an empty manual — a stack trace.
2. **P is not correct by construction.** `config.nu` sources every module by a
   `~`-literal, so `--config` pointed at another tree still loads
   `$HOME/.config/nushell/help.nu` — measured with a marker `def` in each of
   two trees, and the marker that ran was the home one. So P can name a
   directory that did NOT supply the running `help.nu` (row four), and then the
   renderer and its corpus come from different trees: a manual that renders,
   exits 0, and describes a different machine.
3. **H agrees with that literal in every shape**, and it is exactly the
   directory the file was itself read from.

`$env.XDG_CONFIG_HOME` is rejected for a second reason: `env.nu` assigns it
unconditionally, so it is a copy of `$nu.home-dir/.config` wherever `env.nu`
ran and nothing at all where it did not.

**No fallback chain.** One resolution, never "if it is not there, try
elsewhere". A fallback is precisely what turns "not found" into "found
somewhere wrong", and row four is what that costs.

**Out of this file's reach, on purpose.** Row one — plain `nu` with no export,
which is a GUI-launched WezTerm, since `wezterm.lua` deliberately carries no
`default_prog` — loads `~/Library/Application Support/nushell/config.nu`. That
file does not exist, so NONE of this repo's nushell configuration loads and
`help` is nushell's builtin welcome text. No line here can change that, because
`help.nu` is never sourced in that shape. That half belongs to the launchd PATH
seeding described in [WezTerm](./wezterm.md).

**The other constant, which genuinely cannot move:** `$nu.history-path`. Same
launch-time lesson, recorded in `history.nu`'s header — reedline reads and
writes wherever the launch environment puts it, so there the constant IS the
right answer and a literal would be the wrong one. Cross-referenced, not
re-fixed.

### Constraint 3 — every failure is loud

```
def _help_missing [what: string] {
```

A corpus that is absent or degenerate RAISES; it never renders an empty manual.
Measured: a zero-byte `topics.nuon` opens as `nothing`, and `help` then printed
`Topics:` with nothing under it, `First keys:` with nothing under it, and
exited 0 with an empty stderr. An empty manual reads as "this environment has
no custom bindings", which is the most expensive wrong answer `help` can give,
so every length check is explicit — `finder.nu`'s empty-decode rule, applied to
a read instead of a decode.

There is ONE message, not five. The five near-identical variants it replaced
each named a different missing file and all ended in the same instruction:
the file is data a reader cannot act on, and `chezmoi apply` is the whole of
the action.

```
def _help_topics [] {
```

The spine: the nine topics in reading order. Every render that groups or sorts
by topic uses THIS order, never alphabetical. A `.nuon` list of records opens
as a `table`, a bare `[]` as a `list` and a zero-byte file as `nothing`;
`length` on the last is 0, so the shape test and the length test together cover
all three.

```
def _help_corpus [] {
```

The four surface files flattened into one entry list, each entry given an `id`
— its `key` or its `cmd`, whichever it carries. A missing surface file and an
empty flattened list both raise, for the spine's reason: an overview whose
topics all count zero is the empty manual. A file that opens to something other
than a list contributes nothing, so the length check catches a zero-byte one
too.

**The trade, recorded rather than softened.** The entry and search clauses read
the corpus, so with the corpus gone `ls --help` raises instead of delegating
(measured: rc 1). That is intended — a missing corpus is a broken deploy, and a
`--help` that quietly fell through to std's would hide it. The escape hatch is
`core-help <name>`, which is bound in `config.nu` and touches no corpus at all.
*Restated 2026-09-02: this used to name a `--delegate` flag on `help`, which is
deleted. The alias was always the real hatch; the flag was a second spelling
of it.*

### Constraint 4 — `ls --help` and `help ls` are indistinguishable

Nushell sanctions a custom `help` and routes `<cmd> --help` to it, so
`ls --help` arrives here as `help` with rest `["ls"]` — indistinguishable from
a typed `help ls`. Both must therefore resolve identically, and anything we do
not document is forwarded to `core-help` untouched.

Externals are exempt by construction: nushell passes an external's flags
through, so `git --help` never reaches this file. Longest-match parsing also
keeps std's own subcommands (`help commands`, `help aliases`, `help modules`,
`help externs`, `help operators`, `help escapes`) out of this `def` entirely —
none of the nine topic ids collides with one, and defining subcommands would
shadow that free behaviour and re-fight the parser.

### No ANSI, ever, from this file

Every render is a plain string or a plain table value: no colour codes, no
pager, no TUI. A TTY branch is not writable anyway — as `config.nu`'s PALETTE
comment records, `(is-terminal --stdout)` inside a subexpression captures
stdout and is false unconditionally. Interactive styling comes free, because
nu's own table theme renders a returned table.

### Reads the corpus and spawns nothing

No process, no editor, no terminal query, no git: `help` is typed to find
something out, so it has to be instant. *Nothing checks the manual against the
live configuration any more. A 497-line drift check used to, spawning a
headless Neovim, a second tmux server and a terminal probe to keep 191
recorded verify commands true; it and those records were deleted on
2026-09-02. The manual is now kept honest by being generated from the same
surfaces `help` renders, and by being read.* The one def that spawns anything
is `docs`, and it is a separate command for exactly that reason.

## The renders

```
def _help_overview [] {
```

The spine with per-topic counts, the handful of keys worth knowing first, and
the ways to go deeper. Counts are computed, so the manual growing never leaves
a number behind.

**An id absent from the corpus drops silently** from the first-keys block:
renaming an entry shrinks the list without a word of complaint. That is
deliberate and the `where` in the block is what keeps it silent — a curated
list that raised would make every rename a breakage. Nothing checks it, which
is written in the file beside it so the next reader does not assume otherwise.

**Why the overview is a curated block and not a flag.** Measured before the
curated block landed: bare `help` printed the topics with counts and the
go-deeper line, and NEVER NAMED `idioms` — the entry that says search with `rg`
and find with `fd` rather than `grep`/`find`, and pick with television.
AGENTS.md tells an agent to run `help`, so a data render alone does nothing for
the reader that matters: the rule was satisfied in the corpus and invisible in
the render.

```
def _help_topic_table [id: string] {
```

One topic as a table. `key` carries the entry's id, so
`help find | where key =~ 'ctrl'` composes like any other nu pipeline.

```
def _help_search_table [q: string] {
```

A query across the manual: case-insensitive substring over `id`, `title` and
`use`, in spine order, so the result reads grouped by topic while staying one
composable value.

```
def _help_json [] {
```

The whole manual as ONE JSON document. `to json` returns TEXT, so a caller gets
one document whether it pipes to `jq` or back through `from json`. Shape:
`{topics: <topics.nuon verbatim>, entries: [...]}`.

**Column names are an interface.** Renaming one is a breaking change, not a
tidy-up, and it binds the JSON keys hardest because `help --json` is consumed
by programs. **Every optional corpus field is materialised with an empty
default, never omitted**: `jq '.entries[].why'` must not hit a missing key, and
a consumer that has to tell absent from empty is reading a dump, not an
interface. `key` and `cmd` are BOTH emitted because which one an entry carries
is itself information — a non-empty `key` means the entry is a keystroke, a
non-empty `cmd` means it is an invocation.

**No per-topic count and no `version` key.** Both are derivable from `entries`,
and a stored count is exactly the stale-number shape this board keeps
correcting.

**No corpus row index is published.** An index shifts whenever an entry is
added, and an unstable handle inside a stable interface is worse than no
handle. *A deleted picker lane needed one, because television substitutes a
template field textually and one live id carries an apostrophe; that lane and
its index are gone, and `?` searches prose by line, so the constraint no longer
has a mechanism to defend.*

```
def _help_entry_detail [id: string] {
```

One entry in full: the gesture, the reason, the neighbours, the surface. A
`terminal`-mode entry is MARKED rather than hidden, so a reader inside a
capsule learns the key exists and does not work there.

## `docs`, and `?`

```
def --env docs [] {
```

The prose search. It guards on television's presence and on an interactive
shell — television REQUIRES a TTY (`finder.nu`'s limitation (a)) and panics
without one — then hands the `docs` channel to the shared finder and opens the
hit at its line. `help --json` is what renders the entries without a TTY, and
the error says so.

`?` is the alias, because this is the thing you want with one keystroke. It is
the ONE search over the manual: there is no second picker over the entries.

## The command

```
def help [
```

Four shapes and no flag ladder: `help` (the topics), `help <topic>`,
`help <thing>` and `help --json`.

**Resolution order, first hit wins.** `--json` is checked before anything reads
the corpus-dependent path, and it refuses a query rather than silently dropping
one — its subject is the WHOLE manual, so there is nothing for a query to
filter to, and an interface that silently drops an argument is how an agent
comes to trust a wrong answer.

Then, in order: an empty query renders the overview; one of our nine topics
renders that topic's table; one of our entries, matched exactly against
`key`/`cmd`, renders in full — this is where `help ls`, `help ctrl-r` and a
typed `ls --help` all land; a name the shell knows but we do not is **forwarded
to `core-help` unchanged**; a name that matches nothing exactly falls to a
search across the manual; and a search with no hits falls to `core-help
--find`, so `help <nu-word>` still lands somewhere.

The forwarding clause is the load-bearing one. A regression there breaks
`--help` for every nu-resolvable name in the shell, which is the whole cost of
being allowed to own this name.
