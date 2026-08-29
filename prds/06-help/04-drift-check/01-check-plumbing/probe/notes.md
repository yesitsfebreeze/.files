# 01-check-plumbing — probe notes (child of 04-drift-check)

Continuing pass one. Parent probe: ../../probe/notes.md (266 lines, read).

## State on disk at start (uncommitted, from the parent's build)
- `home/dot_config/nushell/help-check.nu` — new, untracked
- `config.nu` +1: `source ~/.config/nushell/help-check.nu` at 609, ABOVE `help.nu` at 610
- `help.nu` +9: `--check` flag on `def help` (line 670) and
  `if $check { return (_help_check) }` before the delegate branch
Verified by `git diff`. So pass one of the plumbing already stands.

## The eleven gates do NOT all carry a `MODULES=` constant
Measured: only TWO gates have a literal `MODULES=` line —
`tests/help-agent.sh:147` and `tests/shell-help.sh:101`. Four use a
`for m in <names>; do` list instead: shell-television:565, help-browser:517,
shell-quicklist:671. The brief's "eleven `MODULES=` constants" is the shape
of the fix, not the literal spelling: each gate names its modules its own way.
Enumerating all eleven next.

## The eleven gates and their three staging idioms (measured)
Derived list (the gate's own predicate: stages a `.nu` into a scratch
`.config/nushell` AND passes `--config`) returns TEN:
  help-browser nushell-aliases nushell-core shell-claude shell-help
  shell-history shell-listing shell-quicklist shell-television shell-zoxide
`tests/help-agent.sh` stages modules (line 443) but is NOT selected — its cp
is `cp "$NUSHELL_SRC/$m" "$M/home/.config/nushell/$m"`, a templated dest that
the predicate's explicit-cp regex `cp +"[^"]+" +"[^"]*/\.config/nushell/[^"]*\.nu"`
misses because `$m` already carries the `.nu`. Eleven gates must be edited;
only ten are in the gate's grid. Recorded, not widened.

Idioms:
  A. explicit per-module `cp` lines (6): nushell-aliases, nushell-core,
     shell-claude, shell-history, shell-listing, shell-zoxide
  B. `for m in <stems>; do cp "$NUSHELL_SRC/$m.nu"` (3): help-browser:517,
     shell-quicklist:671, shell-television:565
  C. a `MODULES=` constant (2): help-agent:147, shell-help:101

`tests/shell-init.sh` is NOT in either list — no collision with the
concurrent g1-verify session's footprint. Confirmed by the derivation above.

Extra coupling found: `tests/help-agent.sh:147-153` asserts its `MODULES=`
string EQUALS the list derived from config.nu, so that gate has a second
edit beyond staging. `tests/shell-help.sh:101` has no such mirror assert but
:382 checks the config.nu/help.nu mirror.

## Step 1 DONE — the regex fix, both copies
Only TWO copies of the module-derivation regex exist in the repo:
  gates/nushell-module-staging.sh:83  (modules())
  tests/help-agent.sh:151             (modules_fresh(), a second, private copy)
Both widened `[a-z]+` -> `[a-z-]+`. A third `[a-z]+\.nu` at
tests/nushell-core.sh:907 is the GENERATED-init name list (starship, zoxide,
television) — unrelated surface, no hyphen possible, left alone.
help-agent's copy is load-bearing: modules_fresh asserts its own MODULES=
string EQUALS config.nu's derived list, so regex and MODULES must move together
or that gate goes red either way.

## Step 2 DONE — the two MODULES= constants and the three for-lists
  tests/help-agent.sh:147   MODULES= ... copymode.nu help-check.nu help.nu theme.nu
  tests/shell-help.sh:101   MODULES= ... copymode.nu help-check.nu help.nu
  tests/help-browser.sh:517 | shell-quicklist.sh:671 | shell-television.sh:565
    `for m in ... copymode help-check help; do`

## Step 3 DONE — a SECOND discrimination hole in the gate, found by building
A hyphen in a module name defeats the gate a second way, independent of the
derivation regex. `names_it`'s list-driven branch matched the stem with
  (^|[^a-zA-Z0-9_])$stem(\.nu)?([^a-zA-Z0-9_.]|$)
`-` is in NEITHER boundary class, so once `help-check` is in a for-list the
stem `help` matches the `help` inside `help-check` — a gate that dropped
`help` entirely would still read as staging it. That is the gate's OWN
selftest GREEN half (it deletes `help` from shell-television's list and
requires red before repair), so the hole is not hypothetical: it would have
turned the selftest vacuous the moment this node landed. Both boundary classes
now exclude `-`:
  (^|[^a-zA-Z0-9_-])$stem(\.nu)?([^a-zA-Z0-9_.-]|$)
Still to fix: the selftest's own two seds use `[a-z ]*` and cannot match a
list containing `help-check`.

## Step 4 DONE — six explicit-cp gates stage help-check.nu
nushell-aliases:131 nushell-core:399 shell-claude:340 shell-history:546
shell-listing:445 shell-zoxide:600 — one `cp "$NUSHELL_SRC/help-check.nu"`
line each, immediately after that gate's help.nu line. These six are exactly
`tests/shell-help.sh:105` SIBLINGS.
Not touched, and recorded rather than fixed: `shell-help.sh:294 staging_ok`
asserts each sibling carries exactly ONE help.nu staging line and says nothing
about help-check.nu — a hand-maintained list, which the module-staging gate's
own header calls the failure mode. Its count stays 1 because the fixed-string
needle ends `help.nu"` and the new line ends `help-check.nu"`. Verified by
the gate runs below.

## Step 5 MEASURED — the gate now sees help-check.nu, and can fail on it
`bash gates/nushell-module-staging.sh` -> **rc=0**, 14 modules derived
(help-check between copymode and help), 10x14 grid all `.`, misses: 0.
Part A proved the new module is a real parse-time requirement:
  drop help-check.nu  rc=1 at=config.nu:609  nu::parser::sourced_file_not_found
`--selftest` -> **rc=0**, both halves, including the GREEN half's
red-before-repair — which is the behavioural proof that the `-` boundary
tightening works: with `help-check` still in the list, dropping `help` is
still seen as a MISS.
COUNTERFACTUAL (scratch copy under the scratchpad, --repo, repo untouched):
removed `help-check` from shell-television's for-list ->
  FAIL MISS tests/shell-television.sh does not stage help-check.nu — config.nu
       sources it at line 609 ...
  FAIL grid: ... (misses: 1)
So the gate discriminates on this module in both directions. The fix

## Step 5 MEASURED - the gate now sees help-check.nu, and can fail on it
`bash gates/nushell-module-staging.sh` -> **rc=0**, 14 modules derived
(help-check between copymode and help), 10x14 grid all `.`, misses: 0.
Part A proved the new module is a real parse-time requirement:
    drop help-check.nu  rc=1 at=config.nu:609  nu::parser::sourced_file_not_found
`--selftest` -> **rc=0**, both halves, including the GREEN half's
red-before-repair - which is the behavioural proof that the `-` boundary
tightening works: with `help-check` still in the list, dropping `help` is
still seen as a MISS.
COUNTERFACTUAL (scratch copy under the scratchpad, --repo, repo untouched):
removed `help-check` from shell-television's for-list ->
    FAIL MISS tests/shell-television.sh does not stage help-check.nu - config.nu
         sources it at line 609 ...
    FAIL grid: ... (misses: 1)
So the gate discriminates on this module in both directions. The "fix that
still cannot fail" risk named in the brief is closed by measurement.

## Step 6 MEASURED - all eleven gates green with help-check.nu in config.nu
Run 2026-08-29, this tree, after the edits above:

    help-agent        rc=0  PASS=100  FAIL=0
    help-browser      rc=0  PASS=97   FAIL=0
    nushell-aliases   rc=0  PASS=39   FAIL=0
    nushell-core      rc=0  PASS=256  FAIL=0
    shell-claude      rc=0  PASS=51   FAIL=0
    shell-help        rc=0  PASS=93   FAIL=0
    shell-history     rc=0  PASS=68   FAIL=0
    shell-listing     rc=0  PASS=40   FAIL=0
    shell-quicklist   rc=0  PASS=111  FAIL=0
    shell-television  rc=0  PASS=71   FAIL=0
    shell-zoxide      rc=0  PASS=117  FAIL=0

1043 assertions, zero failures. That is the whole blast radius of the
config.nu `source` line, closed. `help-agent`'s modules_fresh passes, so its
MODULES= string and config.nu's derived list agree under the widened regex -
the two edits are consistent with each other, not merely each self-consistent.
`shell-help`'s staging_ok still counts exactly one help.nu line per sibling,
unaffected by the added help-check.nu line, as predicted.

## Step 7 MEASURED - the flag dispatches, and the source order is load-bearing
Hermetic machine (parent probe's mk-machine.sh + nu-c.sh; the machine's nvim
is the repo config with an offline-seeded lazy store):

  as shipped   `help --check` -> ZERO `nu::parser::unknown_flag` matches; the
               run enters help-check.nu (it fails later, at help-check.nu:166,
               inside `_hc_nvim_live`). The AGENTS.md parse error is gone.
  swapped      config.nu sourcing help.nu ABOVE help-check.nu ->
               nu::shell::external_command, "Command `_help_check` not found"
               at help.nu:713.
The order is not a convention, it is a run-time requirement, and it is now
proven by counterfactual rather than asserted.

The remaining failure is NOT plumbing and NOT mine. `_hc_nvim_live` at
help-check.nu:166 does `$out.stdout | from json` and lazy.nvim's clone chatter
is on stdout: persistence.nvim is in lazy-lock.json but in no local store
(the concurrent 07-multiplexer/06-nvim-session work added the lock entry), so
a headless start CLONES FROM THE NETWORK mid-check and the JSON parse dies.
The parent probe recorded the same trap. It is sibling 03-nvim-resolver's
contract. Reading of the tree as of now: home/dot_config/nvim/lazy-lock.json,
which/help nuon corpora and which-key.lua are being edited concurrently by
that session, so any count taken from them here is a snapshot, not a constant.

## Step 8 MEASURED - collateral outside the eleven
    shell-init      rc=0  PASS=100 FAIL=0     <- the concurrent session's footprint,
    shell-litellm   rc=0  PASS=44  FAIL=0        run only, NOT edited. No edit was
    deploy-skeleton rc=0  PASS=63  FAIL=0        needed: neither gate is in the
    managed-config  rc=1  PASS=65  FAIL=2        derived staging list.
managed-config's two FAILs are NOT this node's:
    FAIL  surface: home/dot_config/ holds only declared tools (undeclared: tmux)
`home/dot_config/tmux/` is the concurrent 07-multiplexer work, untracked.
help-check.nu does not trip that surface check - it lands inside an already
declared tool directory. Reported, not fixed.
No gate anywhere enumerates the nushell source directory (`ls`/`find` over
home/dot_config/nushell: zero hits across tests/ and gates/), so a new module
file is invisible to everything except the `source`-derived list.

## Step 9 - both spec02 counterfactuals executed as written
    A (drop help-check from shell-television) -> MISS ... does not stage
      help-check.nu - config.nu sources it at line 609 ... misses: 1
    B (drop help while help-check stays)      -> MISS ... does not stage
      help.nu - config.nu sources it at line 610 ... misses: 1
    `grep -rn 'nushell/\[a-z\]+' gates tests` -> rc=1, no narrow copy left
B is the one that matters: before the boundary tightening it would have been
GREEN, because the stem `help` matched inside `help-check`.

## Verdict: SPECCED. specs/spec01.md + specs/spec02.md written.
Everything in the contract is built and green; what the specs leave open is
the ordering gate in capture_ok (spec01) and the two comment records in the
gate and help-agent (spec02).

## IMPLEMENTER pass — step I1 DONE: spec01's ordering gate exists
`tests/shell-help.sh capture_ok` extended: `source ~/.config/nushell/help-check.nu`
counted exactly once (`grep -cxF`, so help.nu's own line cannot satisfy it)
and required strictly between `alias core-help = help` and
`source ~/.config/nushell/help.nu`. The chain is now
  MODULES < history.nu < use std/help < alias core-help < help-check.nu
  < help.nu < PALETTE.
A second in-gate counterfactual was added beside the D1/D2 one, built by awk
moving the help-check source line BELOW help.nu — the exact swap that dies at
run time — so the new clause is gated by something that can fail rather than
by inspection.
Measured this tree:
  bash tests/shell-help.sh -> rc=0, 94 run / 94 passed / 0 failed
  PASS tree: history.nu < 'use std/help' < 'alias core-help = help'
       < help-check.nu < help.nu < PALETTE, each once
       (use at line 607, help-check.nu at line 609)
  PASS tree: counterfactual help-check.nu-sourced-below-help.nu FAILS the
       order check
EXTERNAL COUNTERFACTUAL (scratch copy, the two source lines swapped, repo
untouched): rc=1, 93/94, the single FAIL being the order clause by name.
Grep proofs: help.nu:670 `--check`, help.nu:713 `if $check { return
(_help_check) }` as clause 0 above the `--delegate` branch; config.nu 608 /
609 / 610 alias / help-check.nu / help.nu, help-check count exactly 1.
Spec01 boxes 1-4 and 6 ticked. Remaining: the hermetic-machine unknown_flag box.

## Step I2 DONE — spec01 box 5, re-measured on a fresh hermetic machine
`bash probe/mk-machine.sh` -> a new $M; `nu-c.sh "$M" 'help --check'`:
  rc=1, `grep -c unknown_flag` = **0**
  the only error is `nu::shell::error` "Error while parsing JSON text" located
  at `help-check.nu:166:19` (`$out.stdout | from json`), i.e. INSIDE
  help-check.nu, not in the parser.
The JSON that fails to parse is lazy.nvim's clone chatter for
persistence.nvim (`Cloning into .../lazy/persistence.nvim`) — the concurrent
07-multiplexer/06-nvim-session session's lock entry with no local store to
seed from, so the headless start goes to the network. NOT this node's: it is
sibling 03-nvim-resolver's contract. Reproduced twice now (analyst pass and
this one), same line, same cause.
**spec01 COMPLETE — 6/6 boxes [x].**

## Step I3 DONE — spec02's two comment records, and a trap they set
`gates/nushell-module-staging.sh` header: "Known state" moved to 2026-08-29 /
10 x 14 / help-check.nu at config.nu:609, and BOTH hyphen defects recorded
with the counterfactual that catches each, plus the general rule (a character
class written for the names that exist is a guess about the ones that will).
A second, shorter note sits AT `names_it` telling the next reader not to drop
`-` back out of either boundary class. `tests/help-agent.sh`'s `modules_fresh`
comment now says its regex is a SECOND COPY of the gate's and that the two
must move together — including which way each fails alone (the gate under-
reports; help-agent goes red on a correct list).

TRAP, found by running the check rather than by writing it: the first draft of
the header quoted the OLD regex verbatim, and spec02's acceptance box 1 is
`! grep -rn 'nushell/\[a-z\]+' gates tests`. The comment therefore MATCHED and
turned the "no narrow copy survives" proof green-by-prose. Rewritten to name
the class without reproducing the path-prefixed literal; grep now rc=1, no
output. Recording it because it is the same species as the defect being
documented: a check that a comment can satisfy is not a check.

Measured after the edits: `bash gates/nushell-module-staging.sh` rc=0,
14 modules with help-check.nu between copymode and help,
`PASS parse: dropping help-check.nu is fatal at config.nu:609 with
nu::parser::sourced_file_not_found (rc=1 at=config.nu:609)`,
`PASS grid: ... (misses: 0)`. `--selftest` rc=0, both halves, zero FAILs.

## Step I4 DONE — spec02's Verify and Proof block, executed whole
  grep -rn 'nushell/\[a-z\]+' gates tests   -> rc=1, NO OUTPUT (after the
      comment rephrase in I3; before it, the comment itself matched)
  gate                                       -> rc=0, misses: 0, 14 modules
  PASS parse: dropping help-check.nu is fatal at config.nu:609 with
       nu::parser::sourced_file_not_found (rc=1 at=config.nu:609)
  --selftest                                 -> rc=0, both halves, 0 FAILs

COUNTERFACTUAL A (scratch copy, help-check dropped from shell-television's
`for m in` list; mutation proved landed by `cmp -s` before running):
  rc=1
  FAIL MISS tests/shell-television.sh does not stage help-check.nu — config.nu
       sources it at line 609, so this gate dies at parse before its own first
       assertion
  FAIL grid: ... (misses: 1)

COUNTERFACTUAL B (help dropped while help-check STAYS — the boundary fix):
  rc=1
  FAIL MISS tests/shell-television.sh does not stage help.nu — config.nu
       sources it at line 610, ...
  FAIL grid: ... (misses: 1)
B is the one that would have been GREEN before the `-` boundary tightening,
because the stem `help` matched inside `help-check`. Proven, not read.

THE ELEVEN, this tree, after every edit above:
  help-agent 100/0 · help-browser 97/0 · nushell-aliases 39/0 ·
  nushell-core 256/0 · shell-claude 51/0 · shell-help 94/0 ·
  shell-history 68/0 · shell-listing 40/0 · shell-quicklist 111/0 ·
  shell-television 71/0 · shell-zoxide 117/0     (PASS/FAIL, all rc=0)
1044 assertions, zero failures — one more than the analyst's 1043, which is
exactly shell-help's new help-check ordering counterfactual.
**spec02 COMPLETE — 9/9 boxes [x]. spec01 COMPLETE — 6/6 boxes [x].**

## Step I5 — the repo's own gate (`just gates`), and one red that is not mine
Meta-gate contract on my edited gate: PASS on all five clauses, including
`nushell-module-staging.sh wrote nothing outside its scratch` and
`--selftest exits 0 (rc 0)` with 3 MUTATION lines.

FOUND, NOT MINE, NOT FIXED: `gates/tree-links.sh` is rc=1 in the sweep and
standalone —
  FAIL green: the real tree exits 0 over the merged set (specs/** included)
  checked 1716 links in 529 files, 5 broken
All five broken links are in OTHER nodes' documents, none in this node's:
  prds/00-delivery/quiet-board-sweep/prd.md:42,59,60,64
  prds/00-delivery/corrections/tree-links-selftest-stale-pin/specs/spec03.md:182
Two shapes: `../memos/<slug>.md` resolving under `00-delivery/memos/` (which
does not exist — the memos live at `prds/memos/`), and `corrections/...`
written relative to `quiet-board-sweep/` instead of `00-delivery/`. Reported
to the orchestrator for the owning node; untouched here.

## Step I5 (cont) — `just gates` sweep verdict through wave 3
The full sweep is slow (waves 4-6 are the nvim gates); observed through
wave 3, 3118 PASS. FIVE armed gates red, and **none of them names a file this
node touched** (`grep '^FAIL' | grep -E 'shell-help|module-staging|help-agent|
help-check'` -> NONE):
  wave 0  gates/tree-links.sh        5 broken links, all in 00-delivery/ docs
  wave 0  gates/manual-coverage.sh   selftest rc=1 + wrote outside its scratch
  wave 0  gates/retired-phrases.sh   5 carriers of `the terminal owns the
          palette` — 07-multiplexer probe/spec/memo and two 00-delivery
          corrections nodes
  wave 1  tests/managed-config.sh    undeclared: tmux (known, another node)
  wave 3  tests/nvim-treesitter.sh   parser/ leftovers false-pass (nvim work)
Plus `registry: every script under tests/ is named by a row (unreferenced:
box-audit.py capsule-recents-gui.sh nvim-session.sh tmux-session-and-windows.sh)`
— the last two are the concurrent 07-multiplexer session's new gates.
All reported, none fixed: outside this node's footprint.
