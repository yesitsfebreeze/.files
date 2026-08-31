---
est: 1h
footprint:
  - home/dot_config/nushell/config.nu
  - tests/nushell-core.sh
verify: "bash tests/nushell-core.sh"
---

# spec01 — four passages state the mechanism that reproduces

Replace four comment blocks in `home/dot_config/nushell/config.nu` with the
blocks in **The replacement blocks**, verbatim, and retarget one existing
assertion in `tests/nushell-core.sh` so the gate stays green. No code line
changes. No anchor moves. No `source` line is reordered. R3 binds this spec.

The analyst re-measured every claim the replacement text makes, on
nushell 0.114.1, 2026-08-23. The runs are in **The measurements**. Do not
re-derive them.

Two facts in the PRD are corrected here, both found by re-measuring:

- **The PRD's `:18-23` does not carry the defect.** That bullet says a
  missing `source` is a parse error "so this file can only ever source files
  that already exist", which is true and claims no radius. The "takes the
  whole shell down" wording lives at **`:470-471`** (GENERATED) and
  **`:479-480`** (MODULES) — two sites, not one, and the PRD's `:448-452`
  is the stale spelling of the first.
- **R2's "everything below the failing `source` is silently absent" is too
  narrow.** The parse error discards **the whole file**: four probes, two
  written above the failing line and two below, all four answered
  ``Command `qq…` not found``. Nothing in config.nu survives, in either
  direction.

## What is wrong

**Defect 1 — `:146-148`, the LISTING lead-in.**

```
# This anchor is BEFORE the funnel and the hooks deliberately: the auto-list
# closure that 04-shell/06 appends at HOOKS names `la`, and nushell resolves a
# closure's command calls at PARSE time — so `la` has to be defined above it.
```

The mechanism is false and the consequence with it. Nushell **predeclares**
every `def` in a block before it parses any body, so a closure or a def body
may call a def written lower in the same file. `la` is a def. Def order buys
nothing here. What binds textually is an **alias** and a **`source`**, and
that is the reason the same file already gets right one anchor further down
(`alias core-ls = ls` must precede `def ls`).

The comment is dangerous rather than merely wrong: a reader who tests the
stated mechanism finds it false and concludes the layout is arbitrary.

**Defect 2 — `:470-471` (GENERATED) and `:479-480` (MODULES).**

```
# is load-bearing here and not a nicety: a `source` of a missing file is
# `Error: nu::parser::sourced_file_not_found`, a PARSE error, which takes the
# whole shell down rather than degrading.
```

```
# file, because a `source` of a missing file is a parse error that takes the
# whole shell down. chezmoi deploys the module and this line in one apply,
```

"Takes the whole shell down" is the wrong radius, and the true one is a
stronger argument for the constraint, not a weaker one: interactively the
shell **starts**, prints the error, and silently has nothing this file
defines. A shell that refuses to start is noticed in one second; a naked REPL
is noticed a week later.

## The measurements

Every command was run in a scratch directory. The live `~/.config` was not
touched. `PTY` is the pty runner lifted out of `tests/nushell-core.sh`
(`write_pty_runner`), because a PWD hook does not fire from `nu -c`.

**M1 — a closure calls a def written below it, one block.**

```
$ nu -n -c 'let c = {|| later }; def later [] { print "LATER-RAN" }; do $c'
LATER-RAN
```

Same through a file: `LATER-RAN-FILE`. Defs predeclare.

**M2 — the same shape as the live file: a PWD closure naming `la`, with
`def la` written below the append.** Two configs, byte-identical but for the
order, each driven with one `cd /tmp` typed into a real REPL:

| config | parser errors | `la.txt` |
|---|---|---|
| closure above `def la` | 0 | `LA-RAN` |
| closure below `def la` | 0 | `LA-RAN` |

**M3 — an alias is not predeclared.** `alias core-ls = ls` /
`def ls [...p] { print "SHADOW-RAN"; core-ls ...$p … }`:

```
# alias first (the live order)
SHADOW-RAN
# def first (swapped)
SHADOW-RAN
Error: nu::shell::external_command
 1 | def ls [...p: string] { print "SHADOW-RAN"; core-ls ...$p | …
   :                                             ^^^|^^^
   :                                                `-- Command `core-ls` not found
```

The swapped order fails **loudly, on the first `ls`, and it is not
recursion** — the alias points at our own `ls` while the body's `core-ls`
was never in scope. The shell still starts clean if `ls` is never called
(`nu -c 'print SHELL-STARTED'` → `SHELL-STARTED`).

**M4 — a closure calling an alias declared below it fails.**

```
$ cat c.nu
let cl = {|| aliased }
alias aliased = print "ALIAS-VIA-CLOSURE"
do $cl
Error: nu::shell::external_command  …  Command `aliased` not found
```

So the anchor order *would* be load-bearing if the auto-list closure ever
named an alias. That is the fact worth carrying.

**M5 — an alias target cannot name a def declared below it either.**
`def --env mkcd …` then `alias cd = mkcd` printed `MKCD-SAW /tmp` and moved.
Swapped, `alias cd = mkcd` first: ``Command `mkcd` not found``. Nothing in
the tree asserts this pair; spec02 adds it.

**M6 — a `source` binds textually.** `def caller [] { helper }` above
`source ~/helper.nu` → ``Command `helper` not found``. Below it →
`HELPER-RAN`.

**M7 — the parse-error radius, interactively.** Config: two declarations
above `source /definitely/not/here.nu` and two below. Driven under the pty,
one probe per run, `exit` after:

| probe | position | with the bad `source` | with the line removed |
|---|---|---|---|
| `qqa` (alias) | above | `Command `qqa` not found` | `ABOVE-ALIAS-RAN` |
| `qqb` (def) | above | `Command `qqb` not found` | `ABOVE-DEF-RAN` |
| `qqc` (alias) | below | `Command `qqc` not found` | `BELOW-ALIAS-RAN` |
| `qqd` (def) | below | `Command `qqd` not found` | `BELOW-DEF-RAN` |

The shell reached a prompt in every bad run and `print ALIVE=4` ran. The
whole file is discarded, above the failing line as well as below.

**M8 — the same config, non-interactively.**

```
$ nu --config bad.nu -c 'print ALIVE=1; zz'
Error: nu::parser::sourced_file_not_found  …
$ echo $?   # 1 ;  "ALIVE" appears 0 times in the output
```

`nu -c` prints the error, **never runs the command**, and exits 1. That is
why "takes the whole shell down" felt true to whoever wrote it: it is true
for the non-interactive path and false for the one a human sits in front of.

## The replacement blocks

Apply them **in descending line order** — C, B, A, then D — so no edit
moves the lines of an edit not yet made. Every line is at or under 78
columns. Net delta: **+40 lines**, so `# ── MODULES ──` moves from 476 to
516 and the KEYBINDINGS anchor moves by the same amount. No gate holds a
config.nu line number; `tests/nushell-core.sh` uses `line_of`.

### Block C — lines 479-480 (MODULES), 2 lines → 4

```
# file, because a `source` of a missing file is a parse error that DISCARDS
# THE WHOLE OF THIS FILE and leaves a working but naked REPL (measured; the
# GENERATED anchor above carries the numbers). chezmoi deploys the module and
# this line in one apply,
```

### Block B — lines 469-471 (GENERATED), 3 lines → 17

```
# is load-bearing here and not a nicety. A `source` of a missing file is
# `Error: nu::parser::sourced_file_not_found`, a PARSE error, and the radius
# is NOT "the shell refuses to start". It is worse than that, and it was
# measured 2026-08-23 on 0.114.1.
#
# INTERACTIVELY THE SHELL STARTS AND THE WHOLE FILE IS DISCARDED. With one
# bad `source` at the top, nu printed the error, reached a prompt (`print
# ALIVE=4` ran), and every command this file defines was gone — the ones
# ABOVE the failing line as well as the ones below. Four probes, two above
# and two below: all four answered `Command not found`; with the `source`
# line removed all four ran. NON-INTERACTIVELY it fails the other way round:
# `nu -c` prints the same error, NEVER RUNS THE COMMAND, and exits 1.
#
# So the failure mode to fear is A WORKING BUT NAKED REPL, which is harder to
# notice than a shell that refuses to start: nothing looks broken, everything
# is merely absent. That is what the copymode staging outage looked like from
# the inside.
```

### Block A — lines 146-148 (LISTING lead-in), 3 lines → 26

The block must not recite the retired sentence: spec02's CP.1 proves it is
gone by grepping `has to be defined above it`, and a quotation would keep
that grep green forever. State the truth instead.

```
# This anchor sits before FUNNEL and HOOKS, and DEF ORDER IS NOT WHAT THAT
# BUYS. Nushell PREDECLARES every def in a block before it parses any body,
# so a closure or a def body may call a def written LOWER in the same file,
# and `la` is a def. Measured 2026-08-23 on 0.114.1: a PWD closure calling
# `la` with `def la` written BELOW it wrote `la.txt: LA-RAN` on the first
# `cd`, zero `nu::parser` errors; the control
# `nu -n -c 'let c = {|| later }; def later [] {...}; do $c'` printed
# `LATER-RAN`.
#
# WHAT BINDS TEXTUALLY IS AN ALIAS AND A `source`, and neither is
# predeclared: an alias target resolves where the parser meets the `alias`
# line, and a `source`d name enters scope only from its own line downwards.
# Two measurements, same session:
#
#   * `alias core-ls = ls` below MUST precede `def ls`. Alias first: the
#     shadow ran. Alias after the def: `Command core-ls not found` on the
#     FIRST `ls` — loud, not silent, and NOT recursion, because the alias
#     then points at OUR `ls` while the body's `core-ls` was never in scope.
#   * had the auto-list closure named an ALIAS instead of the `la` def, this
#     anchor order WOULD be load-bearing: a closure calling an alias
#     declared below it gives `Command not found`.
#
# tests/nushell-core.sh asserts both textual-binding pairs with swapped-order
# counterfactuals, which is what makes them checked artefacts and not
# conventions. The ten-anchor order is its own contract (S4.10); nothing here
# licenses moving an anchor.
```

### Block D — lines 18-23 (the header's closed-layouts bullet), 6 → 7

The first six lines are carried verbatim, the 79-column third line included.
Do not rewrap it: this spec changes reasons, not layout.

```
#   * pre-declared `source` lines for files a sibling node will create later.
#     A `source` of a missing file is a PARSE error
#     (`nu::parser::sourced_file_not_found`), so this file can only ever source
#     files that already exist when it is deployed. That is why the MODULES
#     anchor below sources only modules that ship in this tree and holds no
#     line for quicklist.nu. The radius is a WORKING BUT NAKED REPL, not a
#     shell that refuses to start — measured at the GENERATED anchor below.
```

### Block E — `tests/nushell-core.sh:563-564`

The existing S3.16 check greps for the wording Block B retires, so it goes
red unless it is retargeted in the same change. Replace the phrase only; the
label is unchanged.

```
  chk_ok "why: S3.16 …and that the generator's always-exists guarantee is load-bearing" \
         has . "$CFG_TXT" 'a PARSE error, and the radius'
```

This is the only assertion in `tests/` that reads the retired phrase from
`config.nu`. `tests/shell-help.sh:99` repeats it in a comment of its own,
which belongs to `06-help/02` and is not touched here — report it.

## Acceptance

- [x] `home/dot_config/nushell/config.nu` line 148's old sentence is gone:
      `/usr/bin/grep -c 'so `la` has to be defined above it'` prints `0`.
- [x] `/usr/bin/grep -c 'takes the whole shell down'` over `config.nu`
      prints `0`.
- [x] The LISTING lead-in states that defs are predeclared, names both
      controls (`la.txt: LA-RAN` and `LATER-RAN`), and states that an alias
      and a `source` bind textually.
- [x] The GENERATED paragraph states all four measured facts: the shell
      starts, `ALIVE=4` ran, the whole file is discarded above the failing
      line as well as below, and `nu -c` exits 1 without running the command.
- [x] The MODULES paragraph and the header bullet say the same thing as
      GENERATED and do not restate its numbers.
- [x] No code line changed and no anchor moved: `git diff` is empty (both
      files are untracked), so the proof is a diff against a `cp` aside taken
      before the edit, showing **comment lines only** in `config.nu` and one
      changed phrase in `tests/nushell-core.sh`.
- [x] `bash tests/nushell-core.sh` reaches `EXIT=0`, run **alone**. The
      pre-change baseline is 187 PASS / 0 FAIL; quote the tally, do not
      assert a fresh absolute.

## Verify and Proof

```sh
cd /Users/feb/dev/dotfiles

# 1 — the retired wordings are gone.
/usr/bin/grep -c 'so `la` has to be defined above it' home/dot_config/nushell/config.nu
/usr/bin/grep -c 'takes the whole shell down'          home/dot_config/nushell/config.nu

# 2 — the corrected reasons are present, over normed prose (the file wraps
#     at ~78 columns, so a per-line grep gives false negatives).
sed -e 's/^[[:space:]]*#[[:space:]]\{0,1\}//' home/dot_config/nushell/config.nu \
  | tr '\n\r\t' '   ' | tr -s ' ' \
  | /usr/bin/grep -o -e 'PREDECLARES every def in a block' \
                     -e 'la.txt: LA-RAN' -e 'LATER-RAN' \
                     -e 'WHAT BINDS TEXTUALLY IS AN ALIAS AND A `source`' \
                     -e 'had the auto-list closure named an ALIAS' \
                     -e 'A WORKING BUT NAKED REPL' -e 'ALIVE=4' \
                     -e 'ABOVE the failing line as well as the ones below' \
                     -e 'NEVER RUNS THE COMMAND, and exits 1' \
                     -e 'DISCARDS THE WHOLE OF THIS FILE'

# 3 — comment lines only. BASE is the copy taken before editing.
diff "$BASE/config.nu" home/dot_config/nushell/config.nu \
  | /usr/bin/grep -E '^[<>]' | /usr/bin/grep -vE '^[<>] *#' ; echo "non-comment diff lines above: none expected"

# 4 — the gate, alone.
bash tests/nushell-core.sh; echo "EXIT=$?"
bash tests/nushell-core.sh 2>&1 | /usr/bin/grep -c '^PASS'
bash tests/nushell-core.sh 2>&1 | /usr/bin/grep -c '^FAIL'
```
