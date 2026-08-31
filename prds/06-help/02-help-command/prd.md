---
state: done
claim: 
priority: 14
est: 5h
task: H.2
mode: afk
needs:
  - 06-help/01-content-model
  - 00-delivery/corrections/w0-4-s2-corrections
verify: ""
---

# The `help` command

Parent: [Help epic](../prd.md) · C 5 · U 9 · net-new

Purpose: `help` renders the manual. It is a nushell custom command that
deliberately overrides the builtin — a documented extension point — and
therefore must carry the builtin's duties as well as its own.

## Requirements
- [x] **R1** — **`help`** — the overview: the topic list from
      [01-content-model](../01-content-model/prd.md), each with a one-line summary
      and entry count, the handful of keys worth knowing first (`Ctrl-Space`,
      `F5`, `Ctrl-R`, `<leader>ff`), and the ways to go deeper (`help
      <topic>`, `help <query>`, `help --all`, the fuzzy browser). It also
      states that `help <command>` still reaches nushell's own help for
      anything we do not document.
- [x] **R2** — **`help <topic>`** — a nushell table of that topic's entries:
      key/cmd, title, use. Structured output, so `help find | where key =~
      'ctrl'` composes like any other nu pipeline.
- [x] **R3** — **`help <query>`** — case-insensitive substring/fuzzy match
      across `key`, `cmd`, `title`, and `use`, grouped by topic.
      **`help selection` must find the shift-select entries. A query that
      collides with a nushell command name delegates instead — `help select`
      reaches `std/help`, because `select --help` is the same call.**

      *Amended 2026-08-23 by the orchestrator.* The original example was
      `help select`, and it was unreachable by construction rather than by
      oversight: `select` is a nushell built-in (verified — `which select`
      reports `type: "built-in"`), so clause 3 of this PRD's own delegation
      contract forwards it to `std/help`. It has to. `help select` and
      `select --help` are indistinguishable at the call site, so making that
      one query search the manual would have broken `select --help`. Three
      artefacts already stated delegate-before-search — the delegation
      contract, spec01's resolution clause 8, and the review-locked `use` on
      the corpus's own `help` entry — so the example was the odd one out, not
      the rule.

      Met against the real thing: the gate's probe 5 asserts `help selection`
      returns both shift-select entries (`<S-Up> <S-Down> <S-Left> <S-Right>`
      and `h j k l (visual)`) with the `topic` column present, and asserts the
      delegation half as well. `bash tests/shell-help.sh` → 60 run, 60
      passed, 0 failed, re-run by the orchestrator on the transition.
- [x] **R4** — **`help <entry>`** — full detail for one entry: title, use,
      why, related (`also`), and its `source` — the PRD the entry is specified
      by, defined by [01-content-model](../01-content-model/prd.md) R2. For a
      `command`-kind entry the detail view ends with that command's own
      `std/help` output, so winning a collision never costs the reader the
      flags they came for.
- [x] **R5** — **`help --all`** — the entire manual, all topics, in reading
      order.
- [x] **R6** — **`--mode <m>`** — filter to `shell` / `nvim` / `terminal` /
      `container` (e.g. `help edit --mode nvim`).
- [x] **R7** — **Non-TTY behavior.** Plain text, no colors, no pager, no TUI
      when stdout isn't a terminal (epic invariant 4). Same content, plainer
      shape.
- [x] **R8** — **Speed.** Rendering reads the content files and nothing else —
      no spawning nvim, no wezterm calls, no git. Must feel instant; that
      machinery belongs to [04-drift-check](../04-drift-check/prd.md), which runs on
      demand.
- [x] **R9** — **Container parity.** `help` marks host-only entries rather
      than hiding them, and finds its corpus under any config root — not
      only the one the launching environment happens to name.

      The marking half: `help "F5 <digit>"` renders
      `mode: terminal (host-only — the terminal is outside a capsule)`, and
      no render filters an entry out by mode unless `--mode` asks.

      The corpus half: the corpus is addressed as
      `$nu.home-dir | path join ".config" "nushell" "help"` — the same
      `~/.config/nushell` literal `config.nu` uses to source `help.nu` — so
      the render is byte-identical with and without `XDG_CONFIG_HOME`
      exported at launch. `bash tests/shell-help.sh --noxdg` proves it.

      **`help` does not run inside a capsule, and cannot.** Rewritten
      2026-08-23 by the orchestrator: the original wording asked the corpus
      to "ship or mount with" the container, and the premise is false, not
      merely unproven. The dev image installs zsh + oh-my-zsh and **no
      nushell** ([`01-capsule/02-dev-image`](../../01-capsule/02-dev-image/prd.md)
      R1, `[x]` and done — `useradd -s "$(command -v zsh)"`,
      `docker exec -it $name zsh`), and `capsule` mounts the workspace,
      `~/.ssh`, `~/.gitconfig`, the credential export and the setup script —
      never `~/.config/nushell`. Both capsule nodes are `done`, so that is
      the settled shape rather than a gap someone will close. R9 was asking
      a container with no interpreter to carry the manual. Corrected by
      [`help-corpus-path-resolution`](../../00-delivery/corrections/help-corpus-path-resolution/prd.md),
      which owns the corpus half and its gate.
- [x] **R10** — **Disambiguators.** Because ours wins on collision, both
      sides stay addressable by name: `help --entry ls` and `help --topic
      find` address the manual explicitly, and `help --delegate <name>`
      reaches `std/help` for a name we document. `help --entry ls` and `ls
      --help` must produce identical output — they are indistinguishable at
      the call site, so they cannot diverge.

## Acceptance
- [x] No `--help` invocation loses information: `git --help` is byte-for-byte
      what it was before this command existed (externals never route here),
      and `ls --help` still ends with `std/help`'s output for `ls`. Measured
      in the hermetic machine: `git --help` under the configured shell and
      under `nu -n` are both 2290 bytes and `cmp` reports no difference;
      `ls --help`'s tail carries `Usage:` and `> ls`.
- [x] `help` with no args prints the overview in under ~100 ms.
      `timeit { help }` inside the configured shell: `6ms 378µs 750ns`.
- [x] `help navigate` lists the zoxide suite including the bare-word fallback;
      `help ctrl-r` explains the directory-scoped picker and mentions `Alt-R`.
      Both gate probes PASS; `help ctrl-r` carries `in this directory` and
      `Alt-R`.
- [x] `help ls` shows the manual's `ls` entry, and its output ends with the
      `std/help` signature for `ls`. 43-line render: the entry, then
      `nushell's own help for \`ls\`:` and std's block.
- [x] `help --entry ls` and `ls --help` produce identical output. `cmp` on
      the two captures: identical. They call one helper, so they cannot
      diverge.
- [x] `help navigate` lists all three listing entries — `ls`, `ls -D` and
      `l / ll / la`. (There is no `listing` topic; the listing entries live
      under `navigate`.) All three present in the 12-row table.
- [x] `help find`, `help history` and `help config` reach our topics, not the
      nushell builtins of the same name, and `help --delegate find` reaches
      the builtin. Four gate checks, all PASS: 12 / 4 / 8 rows, and
      `--delegate find` prints `Search for terms in the input data`.
- [x] `git --help` is untouched, because externals never route here. Same
      measurement as the first box.
- [x] `help find | to json` produces valid JSON (it's a real nu table).
      `python3 json.load` parses it: 12 rows, `key` column present.
- [x] `nu -c 'help' | complete` returns plain unstyled text.
      `bytes index-of 0x[1b]` on the captured stdout returns `-1`.

## Out of scope
- Anything this node's Requirements do not name. The epic ([`../prd.md`](../prd.md)) owns the shared invariants.

## The delegation contract (read first)

Nushell's builtin help states: *"If you want your own help implementation,
create a custom command named `help` and it will also be used for `--help`
invocations."* Two consequences, both mandatory:

1. **`<cmd> --help` routes here — but only for nu-resolvable names.**
   Measured 2026-08-21: with a custom `help` defined, `ls --help` arrives as
   `help` with `rest = ["ls"]` — **indistinguishable from a typed
   `help ls`**, so both paths must resolve identically. That holds for
   builtins, aliases and `def`s. It does not hold for externals: nushell
   passes an external's flags through untouched, so external commands never
   route here and `git --help` prints git's own usage. `git --help` is
   therefore unaffected by construction and is not the test that matters —
   `ls --help` is, and it gets one, because a regression there breaks
   `--help` for every nu-resolvable name in the shell. Anything that isn't
   one of our topics or entry keys MUST be forwarded unchanged.
   Verified: the delegation target is `use std/help` (the standard library
   implementation, 492 commands) — defining our own `help` shadows the
   builtin, so `std/help` is what we forward to.
2. **Resolution order.** Given an argument:
   1. no argument → our overview;
   2. matches one of our topics or entry keys → our manual;
   3. resolves via `which` / `scope commands` (builtin, alias, def, extern)
      → hand off to `std/help`;
   4. otherwise → treat as a search query across the manual, and if that
      finds nothing, fall back to `std/help`'s own search so
      `help <nu-word>` still works.

**Collisions are the normal case, not the edge case.** Measured 2026-08-21,
two classes of them exist. First, three of the manual's nine topic names are
nushell builtins: `find`, `history` and `config` all resolve `built-in`, and
all three route here as `help <name>`. (`git` is a topic name too, but it is
an external, so it does not collide.) Second, nearly every shell command the
manual documents is one of our own `def`s or aliases — `ls`, `l`/`ll`/`la`,
`grep`, `z`, `zi`, `mkcd`, `capsule` and the rest — which is the manual's own
subject matter; delegating those would leave the manual unreachable by name
almost everywhere.

Ours wins on collision, but only for names we actually document — and the
overview must state that `help <command>` still reaches nushell's own help
for anything we do not. Winning costs the reader nothing: a `command`-kind
entry's detail render ends with that command's own `std/help` output (R4), so
no `--help` invocation loses information, and R10's `--entry` / `--topic` /
`--delegate` flags address either side explicitly when the name is ambiguous.
