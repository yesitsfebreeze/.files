---
est: 0.5h
footprint:
  - tests/nushell-core.sh
verify: "bash tests/nushell-core.sh"
---

# spec02 — gate the corrected wording, and relay the census and R5

Two deliverables, one sitting.

1. Add the `PB.1` – `PB.7` block below to `tests/nushell-core.sh`, so the
   retired session-latch reading cannot come back by accident. This mirrors
   what `ST.5` did for the guard's own comment.
2. Relay the **R4 census** and the **R5 recommendation** — both already
   resolved by the analyst below — in the implementer report. Change no file
   named in either. Each census finding is its own node.

Depends on spec01: `PB.2` – `PB.6` assert phrases spec01 writes. Run spec01
first.

## 1 — the gate block

Insert verbatim in `stage_tree`, immediately after the `ST.6` check at
`tests/nushell-core.sh:609` and before the blank line at 610. That puts it
next to the `ST.5`/`ST.6` block it extends.

```bash
  # PB.1 – PB.7 — 00-delivery/corrections/pwd-closure-blast-radius R1/R2.
  # ST.5 above gates the `which` guard's own comment. These gate the `try`
  # paragraph that comment refines, so the retired session-latch reading
  # cannot come back in either place.
  chk_fail "why: PB.1 config.nu no longer claims one closure stops EVERY PWD closure" \
           $GREP -qF 'stops EVERY PWD closure firing' "$CONFIG_NU"
  chk_fail "why: PB.1 …nor that the damage lasts the rest of the session" \
           $GREP -qF 'for the rest of the session' "$CONFIG_NU"
  chk_ok "why: PB.2 the try paragraph states the reach is narrower than a latch" \
         has . "$CFG_TXT" 'NARROWER THAN A SESSION-WIDE LATCH'
  chk_ok "why: PB.3 …and the scope that reproduces: own closure onward, every fire" \
         test -n "$(printf '%s' "$CFG_TXT" | $GREP -oF 'REMAINDER OF ITS OWN CLOSURE')" \
              -a -n "$(printf '%s' "$CFG_TXT" | $GREP -oF 'every closure appended AFTER it, on EVERY fire')"
  chk_ok "why: PB.4 …with BOTH driven measurements named, and the per-fire count" \
         test -n "$(printf '%s' "$CFG_TXT" | $GREP -oF 'once with `error make`, once with A MISSING EXTERNAL')" \
              -a -n "$(printf '%s' "$CFG_TXT" | $GREP -oF 'FOUR FIRES, FOUR BOXES')"
  chk_ok "why: PB.5 …and R2's order dependence, with what enforces it (nothing)" \
         test -n "$(printf '%s' "$CFG_TXT" | $GREP -oF 'LOAD-BEARING FOR AN ORDER, NOT FOR A SESSION')" \
              -a -n "$(printf '%s' "$CFG_TXT" | $GREP -oF 'AND NOTHING ENFORCES THAT ORDER')"
  chk_ok "why: PB.6 …and the measured consequence of appending ahead of the dirstack" \
         has . "$CFG_TXT" 'DIRS.TXT IS NEVER CREATED AT ALL'
  chk_ok "tree: PB.7 R3 — the try, its width guard and the stty guard are unchanged" \
         test "$($GREP -cF '                try { la | print }' "$CONFIG_NU")" -eq 1 \
              -a "$($GREP -cF 'if ($env._NAV? | default "" | is-empty) and (term size).columns > 0 {' "$CONFIG_NU")" -eq 1 \
              -a "$($GREP -cF 'if (which stty | is-not-empty) { ^stty sane e> /dev/null }' "$CONFIG_NU")" -eq 1
```

Three mechanics the block depends on, all verified by the analyst against the
current file — do not "simplify" them away:

- **`$CFG_TXT`, not `$CONFIG_NU`, for every prose check.** `prose()`
  (`tests/nushell-core.sh:490`) strips the leading `#` and collapses every
  whitespace run to one space, so a phrase that straddles a wrapped comment
  line still matches. `REMAINDER OF ITS OWN CLOSURE` straddles two lines in
  spec01's block and matches **only** through `$CFG_TXT`. All eight prose
  anchors were checked against the normalised text and each hits exactly
  once.
- **`PB.7` matches indented code lines.** `try { la | print }` occurs twice
  in `config.nu` — line 376 is the comment introducing it, line 430 is the
  code. A bare `-eq 1` on the phrase is red today and proves nothing about
  the mechanism. The 16-space prefix is what makes it a code check.
- **`PB.1`'s second check is only clean after spec01.** `for the rest of the
  session` occurs exactly once in the file right now — at line 388, the line
  spec01 replaces. Run spec01 first or `PB.1` is red for the right reason.

## 2 — the R4 census, already run

Six confirmed findings. Each has its own node; **fix none of them here.**
For each: the claim, what reproduces, and how the analyst measured it.

### C1 — the same retired claim, two more carriers

| Where | Line |
|---|---|
| `prds/04-shell/06-listing/prd.md` | 116-117 |
| `prds/04-shell/06-listing/specs/spec02-autolist-hook.md` | 79 |

**Claims** — "an error thrown in one PWD closure stops every PWD closure —
**dirstack included** — for the rest of the session", presented as one of
"three pty measurements on 0.114.1".

**Reproduces** — nothing of it. The session latch does not exist (M1, M2 in
[spec01](spec01.md)), and "dirstack included" is the inverted half: the
dirstack is the one thing that *survives*, because its append is first (M3,
M5). This carrier is worse than the comment `config.nu` carried, because it
launders the generalisation as a measured constraint and states the
consequence backwards.

**Measured** — `/usr/bin/grep -rn 'every PWD closure' prds/ docs/ home/`,
then spec01's M1-M5 against the phrases found. `04-shell/06-listing` is
`state: done`, so this is a live record.

**This is the highest-value finding in the census.** Fixing `config.nu` and
leaving these two is the exact failure the PRD's own Purpose warns about.

### C2 — "the GUI launch dies", four live carriers

| Where | Line |
|---|---|
| `prds/02-terminal/06-launchd-path/prd.md` | 30 (Purpose) |
| `prds/00-delivery/corrections/prd.md` | 52 (row T-10, **open**) |
| `prds/00-delivery/corrections/w0-1-terminal-inventory/prd.md` | 32 |
| `prds/00-delivery/corrections/w0-2-terminal-respec/specs/spec06.md` | 82 |

**Claims** — that without the launchd `PATH` seeding "the window dies on the
spot" / "a GUI launch dies" / "the window dies immediately".

**Reproduces** — no. `exit_behavior` defaults to `CloseOnCleanExit` and the
spawn fails *un*cleanly, so the pane is created and kept, showing
`No viable candidates found in PATH`. A dead pane you have to read, not a
window that vanishes.

**Measured** — by
[`terminal-inventory-path-claim`](../../terminal-inventory-path-claim/prd.md)
with `wezterm-mux-server` under `env -i`; that node's R4 asserted the
inventory was "the last carrier", and a
`/usr/bin/grep -rn 'window dies\|launch dies\|dies on the spot\|dies
immediately' prds/ docs/ home/` shows four survived it. `06-launchd-path`
contradicts itself inside one file: its R3 at `:55-62` records the
correction, its Purpose at `:30` still carries the retired wording. T-10 is
the row a future analyst specs the whole `02-terminal` re-spec from, which
makes it the one that matters.

**One node covers all four.**

### C3 — `config.nu:146-148`, the reason the LISTING anchor precedes HOOKS

**Claims** — "the auto-list closure that `04-shell/06` appends at HOOKS names
`la`, and nushell resolves a closure's command calls at PARSE time — so `la`
has to be defined above it".

**Reproduces** — no. Nushell predeclares a block's `def`s before parsing its
statements, so a closure defined *above* the `def` still binds it.

**Measured** — a scratch config whose *first* statement appends a PWD closure
calling `la`, with `def la` written below it, run under a real pty
(0.114.1): the closure ran, `la.txt` reads `LA-RAN`, and
`grep -c nu::parser` on the transcript is `0`. Control:
`nu -n -c 'let c = {|| later }; def later [] { "LATER-RAN" }; do $c'` →
`LATER-RAN`.

**The anchor order is still load-bearing — for a different reason the same
file already states.** `alias core-ls = ls` at `:175-178` must precede
`def ls`, and `source` boundaries bind in textual order. Aliases and sourced
files bind textually; `def`s in one file do not. So this is a right
conclusion resting on a wrong mechanism — precisely the shape that invites a
reader to reorder the anchors after finding the stated reason false.

### C4 — `wezterm.lua:292-296` and `docs/capabilities-terminal.md:503-506`

**Claims** — the `pcall` exists because a latched guard "would silently
disable healing **for the rest of the session**".

**Reproduces** — no, and the same file refutes it twice. `repairing` is a
module-local, and its own comment at `:200-203` says so: "deliberately a
module-local, not GLOBAL: it only has to hold across a synchronous
re-entry, which by definition happens in the same Lua context." `:972-975`
then says a config reload "resets every local in this file". So a latch is
per-Lua-context and reload-scoped, not session-wide.

**Measured** — textual, no WezTerm run needed: the claim contradicts two
comments in its own file. Stated as such so nobody records it as a runtime
measurement. The `pcall` stays load-bearing; only the radius is wrong.
`prds/02-terminal/02-startup-layout/prd.md:86-88` carries the same wording
and belongs in the same node.

### C5 — `config.nu:18-23`, restated at `:448-452`

**Claims** — a `source` of a missing file raises
`nu::parser::sourced_file_not_found`, "a PARSE error, which takes the whole
shell down rather than degrading".

**Reproduces** — the error class does; "takes the whole shell down" does not.
The shell comes up.

**Measured** — a scratch config whose first line is
`source /definitely/not/here.nu`, followed by `alias zz = echo "zz"`, run
under a real pty: nushell printed `nu::parser::sourced_file_not_found` **and
reached an interactive prompt** — `print $"ALIVE=(2 + 2)"` answered
`ALIVE=4`. The alias below the failing source is gone: `zz` answered
``Command `zz` not found``.

**The true radius is a better argument than the stated one.** You get a
working but naked REPL: no aliases, no keybindings, no funnel, no modules,
and no error after the first one. A shell that starts and silently lacks
everything is harder to notice than a shell that will not start.

### C6 — `capsule.nu:453`, a safety claim naming the wrong guard

**Claims** — "There is no code path that reaches `docker rm` outside the
`_capsule_owned` set."

**Reproduces** — no. `capsule.nu:405` runs `^docker rm -f $name` on the
`--rebuild` path, where `$name` comes from `_capsule_name` (`:373`), not from
`_capsule_owned`.

**Measured** — `/usr/bin/grep -n 'docker rm'
home/dot_config/nushell/capsule.nu` gives three call sites: `:405`,
`:459`, `:461`. Only the last two iterate
`_capsule_owned`.

**The safety property holds; the stated mechanism is the wrong one.** `:405`
is protected by the `dir_label` ownership check at `:399-401`, a different
guard. Highest stakes of the six after C1, because a reader auditing the
destructive path is pointed at a guard that does not cover it. The accurate
wording is "no `docker rm` runs without the `capsule.dir` ownership check".

### Collected, not confirmed — each needs its own measurement

Reported so they are on the record rather than looking like an oversight. The
analyst did not measure these; do not repeat them as findings.

| Where | The suspect absolute |
|---|---|
| `config.nu:44-47` | `sync_on_enter` "is what makes a command typed in ANOTHER pane arrive in this one". It is `true` by default (measured: `nu -n -c '$env.config.history'`), and `file_format: sqlite` + `isolation: false` two lines below are the plausible cause |
| `config.nu:60-61` | "without it nushell completes its own builtins only". `completions.external.enable` is already `true` by default (measured) |
| `config.nu:336-338` | "…and startdir.txt **and the dirstack** simply never updated for zoxide jumps". `zoxide.nu:199-203` pushes the dirstack at jump time *because* the hook "may not trip" — a different code path from the generated init the measurement used |
| `config.nu:49-53` | `isolation: false` and "the global history picker would only ever see itself". `history.nu:37-42` reads the sqlite file directly, bypassing reedline's traversal |
| `theme.nu:71-72` | "a corrupt or empty state file can **never** wedge the toggle". The fallback covers unrecognised content, not an unreadable file |
| `wezterm.lua:123-131` | "read back as nil on **every single** event", where the stated mechanism predicts intermittent nil and `docs/capabilities-terminal.md:67-71` says "about as often as not" |
| `wezterm.lua:1044-1048` | attributes the kitty escape leak to enabling the WezTerm half alone, while naming *reedline* as what sends the query |
| `wezterm.lua:116-121`, `:1121-1125` | a refilling window "can **never** be closed" by closing its last tab, against a 5 s polled reconciler |
| `wezterm.lua:39-48` | "**everything** nushell derives from it drifts out of the managed tree", where the measurement bounds exactly two paths |
| `docs/capabilities-provisioning.md:47-52`, `:141-146` | "a re-apply is a no-op" / "**every** step is `command -v`-guarded", against `:37-43`'s generator that "runs last on every apply" and regenerates three files |
| `docs/capabilities-provisioning.md:110-114` | "re-emits the prompt-start mark on **every reedline repaint**", where the symptom reported is a single phantom line |
| `docs/capabilities-nushell.md:30-33` | `mkcd` as the funnel "**every** move flows through", against `finder.nu:260`'s bare `cd $first` |
| `prds/06-help/prd.md:111` | "breaks `--help` **everywhere**", where `06-help/02:131` says externals never route through it |
| `prds/03-editor/12-small-plugins/prd.md:92-94` | `which-key`'s `show()` "**never returns** under `--headless`", which is a property of a harness with no input feeder |
| `prds/02-terminal/07-grid-centering/prd.md:91-93` | the bar height claim is "**always** false: the nine-tab floor means the bar is always shown", which holds only after the first heal tick |

**Scale.** 108 `prd.md` files, twelve `home/dot_config/nushell/*.nu`,
`wezterm.lua` and five `docs/capabilities-*.md` swept for absolute
quantifiers attached to a mechanism, then read in context.

**The good pattern is common, and worth naming.** Most absolutes in this tree
bound themselves in place, and those are not findings:
`config.nu:392-398`'s "one cd one box, two cds two, three cds three";
`env.nu:168-177`'s "ABORTED THE REST OF THIS FILE", which then narrows itself
to "today's damage is only the message because the block happens to be
last"; `wezterm.lua:400-412`'s "Measured, not assumed" plus
"RE-MEASURE IT IF THE WEZTERM BUILD MOVES";
`docs/capabilities-terminal.md:76-82`'s "Not re-verified here". A claim that
names its method and its scope cannot become this node.

## 3 — the R5 answer, to relay

**Yes. The ordering dependence deserves a gate, not only a comment, and it
belongs to
[`04-shell/01-core-config`](../../../../04-shell/01-core-config/prd.md).**

The argument is the tree's own, made once already for the same class of
hazard. `config.nu:339-340` says of the funnel-before-zoxide line order: "The
gate asserts the two line numbers, which is why this is a checked artefact
and not a convention." The PWD append order is the same shape — silent when
broken, invisible in the diff that breaks it, and load-bearing. M4 produced
no warning about the dirstack at all: just the external's own error box,
which a reader attributes to the external. Comments are read by whoever opens
that block; the node that appends a third closure need not open it.

What the check would assert, in four parts:

1. **Order.** The line of `_dirstack_push $after` is lower than the line of
   the auto-list closure body. `line_of()` and the existing `S3.9` check at
   `tests/nushell-core.sh:417-418` already compute exactly this kind of
   comparison; the new check is two `line_of` calls and a `-lt`.
2. **Count.** Exactly two `$env.config.hooks.env_change.PWD = (`
   assignments in `config.nu`. The failure mode is a closure *added* ahead of
   the dirstack, so a check that only compares the two known appends stays
   green while the hazard lands.
3. **Counterfactual.** A derived copy with the two appends swapped must FAIL
   part 1. The gate's established idiom — `S3.10` and `ST.4` both ship one,
   and a guard with no failing counterfactual is decoration.
4. **The consequence, hermetically.** A machine whose config carries a
   throwing closure ahead of the dirstack push produces **no** `dirs.txt`
   (M4); the same closure appended last produces one (M5). This is what
   turns "order matters" from a convention into a measured artefact, and both
   halves are already measured in [spec01](spec01.md) — `04-shell/01` can
   lift them.

Do not build any of it here. `tests/nushell-core.sh` is `04-shell/01`'s
`spec04` artefact; this spec adds a prose-and-tree block to it and asserts
nothing about runtime order.

## Acceptance

- [x] The `PB.1` – `PB.7` block is present in `stage_tree`, immediately after
      the `ST.6` check, and all eight of its `chk_` lines PASS.
- [x] `PB.1`'s two counterfactual checks are `chk_fail`, not `chk_ok` —
      grep the inserted block and quote the two lines.
- [x] `bash tests/nushell-core.sh` reaches `EXIT=0`, **run alone**. Quote the
      `PASS`/`FAIL` totals before and after the insertion; the delta is
      exactly `+8 PASS`, `+0 FAIL`.
- [x] The gate's own check count moved and nothing else did: no `ST.*` or
      `S3.*` or `S4.*` label changed, and `git diff` on
      `tests/nushell-core.sh` shows one contiguous inserted hunk.
- [x] The C1 – C6 census is in the report, each with claim / what reproduces
      / how it was measured, and a one-line verdict. No file named in C1 – C6
      is modified by this node — `git status` shows only
      `home/dot_config/nushell/config.nu` (spec01),
      `tests/nushell-core.sh` and this board folder among this node's
      changes.
- [x] The R5 recommendation is in the report with its four assertions, and
      **no** ordering check is added to any gate.
- [x] `gates/waves.tsv:24` still lists `external bash tests/nushell-core.sh`
      in wave 3, unedited — confirmed by reading it, not assumed. Nothing in
      `gates/waves.tsv` or `gates/manual/wave*.md` is written; they are the
      orchestrator's.

## Out of scope

- Fixing any C1 – C6 finding. Each is its own node. C1 and C6 are the two
  worth filing first: C1 is this node's own retired claim living in a `done`
  PRD, and C6 misnames the guard on a destructive `docker` path.
- Building the R5 ordering check. `04-shell/01-core-config`'s.
- Every entry in the *Collected, not confirmed* table. Unmeasured; do not
  report them as findings.

## Verify and Proof

```sh
cd /Users/feb/dev/dotfiles

# baseline BEFORE the insertion
bash tests/nushell-core.sh | tee /tmp/pb-before.txt | tail -3
/usr/bin/grep -c '^PASS' /tmp/pb-before.txt
/usr/bin/grep -c '^FAIL' /tmp/pb-before.txt

# … insert the block after tests/nushell-core.sh:609 …

# the eight new checks, and the totals
bash tests/nushell-core.sh | tee /tmp/pb-after.txt | tail -3
/usr/bin/grep -E '^(PASS|FAIL) +(why|tree): PB\.' /tmp/pb-after.txt
/usr/bin/grep -c '^PASS' /tmp/pb-after.txt
/usr/bin/grep -c '^FAIL' /tmp/pb-after.txt

# the counterfactuals really are chk_fail
/usr/bin/grep -n 'PB\.1' tests/nushell-core.sh

# wave 3 already carries this gate — read, do not edit
/usr/bin/grep -n 'tests/nushell-core.sh' gates/waves.tsv

# nothing in the census tree was touched
git status --short prds/04-shell/06-listing prds/02-terminal \
  home/dot_config/wezterm docs/ home/dot_config/nushell/capsule.nu
```
