# spec01 — `help.nu`: the renderer, the shadow, and the delegation capture

Delivers R1–R10 as a new module, `home/dot_config/nushell/help.nu`, sourced
at config.nu's MODULES anchor, plus the `std/help` capture that makes
delegation possible. Net-new: the live `~/.config/nushell/` has no help
machinery to port (checked 2026-08-22 — `grep help ~/.config/nushell/*.nu`
finds only pass-store and prose hits). The corpus it renders is H.1's, done
and gated: 87 entries across 4 surface files plus `topics.nuon`, all under
`home/dot_config/nushell/help/`.

**Est:** 2.5h

**Footprint:** `home/dot_config/nushell/help.nu` (create),
`home/dot_config/nushell/config.nu` (MODULES anchor: three lines —
**serial-after-S.5**, that lane holds config.nu),
`tests/nushell-core.sh`, `tests/nushell-aliases.sh`,
`tests/shell-listing.sh`, `tests/shell-zoxide.sh`,
`tests/shell-history.sh` (**serial-after-S.5**), `tests/shell-claude.sh`
(one `cp` staging line each)

## Exact files touched

- **create** `home/dot_config/nushell/help.nu` → deploys to
  `~/.config/nushell/help.nu`. Defs only — no `$env.config` write, no
  keybinding append, no hook (the history.nu purity precedent; spec03 gates
  it). Contents in parse order:
  1. A header comment: what the file is, the D1 trap (below), and that every
     renderer reads the corpus and holds layout only (epic I1).
  2. `_help_corpus []` — read `($nu.default-config-dir | path join help)`:
     `topics.nuon` as the spine, then `shell.nuon`, `nvim.nuon`,
     `terminal.nuon`, `capsule.nuon` flattened into one entry list, each
     entry tagged with an `id` (its `key` or `cmd`). Never the review files
     (`why-review.nuon`, `use-review.nuon` are records, not content).
     Measured: the full load plus a per-topic count is ~3 ms, so R8's 100 ms
     budget holds with two orders of headroom.
  3. Render helpers — overview, topic table, search, entry detail, all
     (shapes under "Renders" below).
  4. `def help [...query: string, --all, --mode: string, --entry: string,
     --topic: string, --delegate: string, --fuzzy]` — resolution order under
     "Resolution" below.
- **edit** `config.nu`, three lines under `# ── MODULES ──`, after the
  `history.nu` source line and before `# ── PALETTE ──`, in this order and
  with a comment carrying D1 and D2:

  ```nu
  use std/help
  alias core-help = help
  source ~/.config/nushell/help.nu
  ```

- **edit** the six gates that stage config.nu's sourced modules into a
  hermetic HOME — the moment config.nu sources `help.nu`, every hermetic
  check in them dies with `nu::parser::sourced_file_not_found` (the
  claude.nu/history.nu precedent): one `cp` of the repo's `help.nu` beside
  the `history.nu` line in `tests/nushell-core.sh` (`mk_machine`),
  `tests/nushell-aliases.sh`, `tests/shell-listing.sh`,
  `tests/shell-zoxide.sh`, `tests/shell-history.sh`, `tests/shell-claude.sh`.
  Each line carries a comment naming this node; nothing else in those files
  is touched. The corpus dir is NOT staged there: `help.nu` reads it at run
  time, none of those gates calls `help`, and only the `source` is
  parse-time.

## Decisions

**D1 — `use std/help` and `def help` cannot share a file, so the capture
lives in config.nu.** Measured on nushell 0.114.1: putting both in one file
— in either order — fails at parse with `nu::parser::unknown_flag` pointing
INTO `std/help/mod.nu:795`. Nushell predeclares a block's `def`s before
parsing its statements, so when the `use` parses std's module, the
`@example {help --find char}` attribute resolves `help` against our
predeclared signature, which has no `--find`. With the `use` and the alias
in config.nu and only the `def` in help.nu (a `source`d file is its own
block), everything parses; measured working end to end.

**D2 — `alias core-help = help`, the core-ls precedent.** Alias targets bind
at parse time, so `core-help` stays bound to std's `help` after the shadow
and the wrapper cannot recurse. The delegation target is `std/help`, not the
builtin: the PRD verified it (492 commands), and the builtin's `--find`
returns an empty list where std's finds hits (re-measured 2026-08-22).

**D3 — std's subcommands survive the shadow, and must keep doing so.**
Longest-match parsing sends `help commands` (492 rows measured), `help
aliases`, `help modules`, `help externs`, `help operators`, `help escapes`
to std's own subcommands, bypassing our `def` entirely. None of the nine
topic ids collides with a std subcommand name, so nothing is lost. Do not
define `help <topic>` subcommands — that would shadow this for free
behavior and re-fight the parser.

**D4 — no ANSI, ever, from this module.** R7 (epic I4) is met by
construction: every render is a plain string or a plain table value, no
color codes, no pager, no TUI. A TTY branch is not writable anyway: as
config.nu's PALETTE comment records, `(is-terminal --stdout)` inside a
subexpression captures stdout and is false unconditionally. Interactive
styling comes free — nu's own table theme renders returned tables.

**D5 — `--fuzzy` parses and degrades to search; 03 owns the tv branch.**
R1's overview names the fuzzy browser, and a flag the command rejects would
make that line false. So `--fuzzy` runs the search render (over the query,
or the full `--all` table with no query). That is exactly
[03-browser](../../03-browser/prd.md) R5's non-TTY fallback, shipped early;
03 (which deps this node) replaces the branch body with the tv spawn.
`shell.nuon [help --fuzzy]`'s entry (source: 03) already describes the
degrade.

**D6 — corpus path is `$nu.default-config-dir | path join help`.** It
follows `XDG_CONFIG_HOME`, so the hermetic gates and a capsule that mounts
the config both resolve it (R9) and no path is hardcoded twice.

**D7 — `--all` returns one spine-ordered table.** Columns `topic`, `key`,
`title`, `use`, `mode`, topics in `topics.nuon` order, entries in corpus
order within each. A table composes (`| where`, `| to json`) and is what
[05-agent-interface](../../05-agent-interface/prd.md)'s acceptance reads;
document form is 05's `--md`, not this node's.

## Resolution

In order; first hit wins. `$name` = the rest args joined with one space.

1. `--delegate <name>` → `core-help <name>`, untouched.
2. `--entry <name>` → entry detail; no entry → `error make` naming the miss.
3. `--topic <name>` → topic table; no topic → `error make` naming the miss.
4. `--all` → the D7 table.
5. no rest args → the overview.
6. `$name` matches a topic id (case-insensitive) → topic table. This is what
   sends `help find`, `help history`, `help config` to OUR topics over the
   builtins of the same name.
7. `$name` matches an entry id (case-insensitive, exact against `key`/`cmd`)
   → entry detail. `help ls`, `help ctrl-r` land here — and so does a typed
   `ls --help`, which arrives as `help` with rest `["ls"]`,
   indistinguishable by construction (measured, PRD delegation contract).
8. `$name` resolves in `scope commands` or `which` (builtin, alias, def,
   extern) → `core-help ...$query`. Anything not ours MUST be forwarded
   unchanged — a regression here breaks `--help` for every nu-resolvable
   name in the shell.
9. otherwise search the manual: case-insensitive substring of `$name`
   across `key`, `cmd`, `title`, `use`; hits → the search table.
10. no hits → `core-help --find $name`, so `help <nu-word>` still lands
    somewhere.

`--mode <m>` composes with the table renders (topic, search, `--all`):
`m` must be one of `shell` `nvim` `terminal` `container` (else `error
make`); keep entries whose `mode` equals `m` or starts with `$"($m):"`.

## Renders

All column names are an interface ([05](../../05-agent-interface/prd.md)
R1); renaming one later is a breaking change.

- **Overview** (plain string): the nine topics in spine order, each as
  `<id> — <summary> (<n> entries)` with counts computed from the corpus;
  a "first keys" block pulling these four entries by exact id — `Ctrl-Space
  / F1`, `F5 <digit>`, `Ctrl-R`, `<leader>ff and <leader><space>` — with
  their titles; the go-deeper line (`help <topic>` · `help <query>` ·
  `help --all` · `help --fuzzy`); and the delegation sentence: `help
  <command>` still reaches nushell's own help for anything not documented
  here.
- **Topic** (table): columns `key`, `title`, `use`, `mode` — `key` carries
  the entry's `key` or `cmd`, so `help find | where key =~ 'ctrl'` composes
  (R2's own example).
- **Search** (table): columns `topic`, `key`, `title`, `mode`, sorted by
  spine order — grouped by topic, still one composable value.
- **Entry detail** (plain string): id, title, use, why (when present), also
  (when present), mode — a `terminal`-mode entry is marked host-only (R9:
  marked, never hidden) — and `source`, the PRD path. When the entry's
  `verify` list holds a `command`-kind target, the detail ENDS with
  `core-help <name>` output for that name (R4), so winning a collision
  costs the reader nothing. `help --entry ls` and `ls --help` are the same
  render by construction — clause 7 and flag 2 call the same helper —
  which is what R10's byte-identity demands.

## Hands off the manual

`home/dot_config/nushell/help/shell.nuon` already carries the `help`,
`help --fuzzy`, `help --json`, `help --md` and `help --check` entries. The
`help` entry's `use` describes exactly the resolution above and is
review-locked; implement to it, and if forced to diverge, file a correction
— never edit the `use`. The one sanctioned edit is spec02's `why` fix.
`--json`/`--md` are [05](../../05-agent-interface/prd.md)'s flags and
`--check` is [04](../../04-drift-check/prd.md)'s; do not define them here —
their entries document the epic's end state, which is this corpus's normal
state (the capsule CLI precedent).

## Acceptance

Hermetic = scratch HOME via `env -i` with `XDG_CONFIG_HOME` pinned, the
managed nushell tree plus the `help/` corpus dir copied in, one-line
generated-init stubs (the sibling-gate pattern). spec03's gate holds every
box; the inline runs below are the smoke check.

- [x] Hermetic `nu -c 'help'`: contains all nine topic ids with per-topic
      counts summing to the corpus count, the four first keys, and the
      delegation sentence; `nu -c 'help' | complete` output has no `\x1b`
      byte. Ran `bash tests/shell-help.sh --hermetic`: `the per-topic counts
      sum to the corpus entry count (91 = 91)` and `carries no ESC byte
      (R7 — got index -1)`. The count is 91, not the 87 written here: H.1
      grew the corpus after this spec was written, so the gate computes it
      from the staged files rather than holding a constant.
- [x] Hermetic `help navigate`: rows include the zoxide suite and all three
      listing entries — `ls`, `ls -D`, `l / ll / la`. Gate: `'help navigate'
      lists the zoxide suite with the bare-word fallback and all three
      listing entries`.
- [x] Hermetic `help find | to json`: valid JSON (parsed back, not eyeballed).
      Gate parses it with `python3 -c json.load` and asserts the `key`
      column.
- [x] Hermetic `help selection`: the shift-select entries come back, `topic`
      column present — **and `help select` delegates to `std/help`.**
      *Reworded by the orchestrator on the transition; the original box said
      `help select` and was unachievable by construction, not by oversight.*
      `select` is a nushell built-in (verified: `which select` reports
      `type: "built-in"`), so resolution clause 8 forwards it — and it must,
      because `help select` and `select --help` are the same call site, so
      searching the manual there would break `select --help`. The capability
      is proven with a query that is not a nushell command: the gate's probe
      5 asserts `<S-Up> <S-Down> <S-Left> <S-Right>` and `h j k l (visual)`
      are both returned with a `topic` column, and asserts the delegation
      half too. R3 was amended to match. `bash tests/shell-help.sh` → 60 run,
      60 passed, 0 failed.
- [x] Hermetic `help ls`: ends with std/help's `ls` output (`Usage:` and
      `> ls` present near the tail); `help --entry ls` and `ls --help`
      byte-identical. Gate: `…ends with std/help's own output for ls (Usage:
      and '> ls' in the tail, 43 lines total)` and `'help --entry ls' and
      'ls --help' are byte-identical`. The tail is matched after stripping
      CSI sequences: std prints `Usage` inside a colour pair, so the literal
      `Usage:` matches nothing on the raw bytes.
- [x] Hermetic `help find`, `help history`, `help config`: our topic tables,
      not std's output; `help --delegate find` is std's `find` help. Four
      gate checks, all PASS.
- [x] Hermetic `help commands`: still std's subcommand, > 400 rows (D3).
      Gate: `got 576`.
- [x] Hermetic: an external stub on PATH, `fakecmd --help`, prints the
      stub's own usage — externals never route here. Gate: `got:
      FAKECMD-OWN-USAGE: fakecmd [--flag]`.
- [x] Hermetic `help --all --mode nvim`: every row's `mode` starts with
      `nvim`; `--mode tmux` errors. Gate: `got:
      nvim:normal,nvim:visual,nvim:insert` and `--mode tmux` exits 1.
- [x] Hermetic `timeit { help }` < 100 ms (R8), and
      `/usr/bin/grep -cE '\^(nvim|wezterm|git|tv)' help.nu` is 0. Gate:
      `single sample: 6ms 378µs 750ns`; the grep is 0.
- [x] Hermetic `help qqqxyzzy`: exits 0 (falls through to `core-help
      --find`). Gate: `rc=0`.
- [x] config.nu line order: `history.nu` source < `use std/help` <
      `alias core-help` < `source ~/.config/nushell/help.nu` < PALETTE.
      Gate's `--tree` check 1, with the counterfactual (the `use` moved
      below the shadow) failing the same check.
- [x] This node's staging line breaks no sibling gate, and
      `tests/nushell-core.sh` — the one sibling that was green before this
      change — is still green. *Narrowed by the orchestrator on the
      transition: the original box said "the six staged sibling gates stay
      green", which this node cannot deliver, because five of the six were
      already red when it started.*

      The pre-existing defect: `config.nu:436` has sourced `copymode.nu`
      since T.7, and of the six only `tests/nushell-core.sh` stages it, so
      the other five die at `nu::parser::sourced_file_not_found`. Confirmed
      independently by the orchestrator before accepting this transition —
      `bash tests/nushell-aliases.sh` → `CHECKS: 39 run, 27 passed, 12
      failed / EXIT=1`, and `grep -c copymode.nu` returns 0 for
      `nushell-aliases`, `shell-listing`, `shell-zoxide`, `shell-history` and
      `shell-claude`, 1 for `nushell-core`. Filed as
      `prds/00-delivery/corrections/sibling-gates-copymode-staging/`.

      Proof this node's line is innocent: scratch copies of all five with
      only the one missing `cp "$NUSHELL_SRC/copymode.nu" …` line added run 0
      FAIL with the `help.nu` staging line in place — `nushell-aliases`
      39/39, `shell-claude` 49/49, and `shell-listing`, `shell-zoxide`,
      `shell-history` all `EXIT=0`. `bash tests/nushell-core.sh` is green on
      the real tree.

## Verify

```sh
cd /Users/feb/dev/dotfiles
bash tests/shell-help.sh            # spec03's gate; covers every box above
/usr/bin/grep -n 'std/help\|core-help\|help.nu' home/dot_config/nushell/config.nu
bash tests/nushell-aliases.sh       # cheapest full sibling; then the other four
bash tests/shell-zoxide.sh
nu tests/help-content-model.nu      # corpus untouched by this spec
```
