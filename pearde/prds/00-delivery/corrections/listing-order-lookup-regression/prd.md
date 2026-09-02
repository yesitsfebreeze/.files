---
state: done
claim: 
priority: 40
est: 1.75h
actual: 30m
mode: afk
footprint:
  - tests/shell-listing.sh
verify: ""
origin: derived
from: 00-delivery/corrections/config-nu-parse-claims
---

# `shell-listing.sh` is red: the correction that fixed one gate defused another

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: a **live landing regression**, confirmed by the orchestrator.

```
$ bash tests/shell-listing.sh
FAIL  tree: T1 counterfactual core-ls-after-def-ls FAILS the order check
EXIT=1   (1 FAIL)
```

[`config-nu-parse-claims`](../config-nu-parse-claims/prd.md) (`done`, landed
minutes earlier) rewrote `config.nu`'s LISTING comment and — correctly — put
the declaration it reasons about **into the prose**:
`config.nu:161` now reads ``#   * `alias core-ls = ls` below MUST precede
`def ls`. Alias first: the …``, while the real declaration is at **202**.

`tests/shell-listing.sh:79` looks it up with a first-match substring grep:

```sh
line_of() { $GREP -nF -- "$2" "$1" | head -1 | cut -d: -f1 …; }
```

So `core` resolves to **161** instead of 202, and the swapped-order
counterfactual reads as still holding. **The counterfactual is defused: T1 can
no longer go red for the thing it exists to catch.**

**The causing node found this hazard and fixed it in its own gate.** It
switched to a start-anchored `line_of_decl` precisely because its own
corrected prose quoted the declaration — and it could not fix the sibling,
because `tests/shell-listing.sh` belongs to
[`04-shell/06-listing`](../../../04-shell/06-listing/prd.md) and one writer per
file holds. It reported the cross-gate duplication in a comment. This node is
the other half.

Priority 40 because a `done` node's counterfactual currently passes on a
broken input, which is worse than a red: it is a check that has stopped
checking.

## Requirements
- [x] **R1** — `tests/shell-listing.sh` uses a **start-anchored** declaration
      lookup, so a comment can never answer for a declaration. Port
      `line_of_decl` from `tests/nushell-core.sh:401-410` — read what landed,
      including the "do not simplify this back" comment beside it — rather
      than writing a third variant.
- [x] **R2** — Every `line_of` call site in the file is audited, not just
      T1's. `order_ok` compares four positions (`alias core-ls`, `def ls`,
      `def la`, the second PWD append); any of them may already be quoted in
      prose, or may become so. Report the audit.
- [x] **R3** — **The counterfactual is proved red again**, which is the whole
      point: with the swap applied, T1 must fail. A fix that leaves the
      counterfactual green has restored nothing.
- [x] **R4** — No assertion changes what it concludes. This is a lookup
      repair.
- [x] **R5** — **Census every other gate for a substring positional
      lookup.** Two gates have now been bitten by the same shape in one
      session. Sweep `tests/` and `gates/` for `line_of`-style first-match
      greps used to compare positions, and report each with whether its
      target could be quoted in prose. That census is the durable half of
      this node.

## Acceptance
- [x] `bash tests/shell-listing.sh` reaches `EXIT=0` with 0 FAIL, run
      **alone**, tally quoted not asserted.
- [x] The T1 counterfactual quoted **red** under the swap, and the measured
      before/after positions quoted — `core=161` under substring matching
      versus the declaration line under anchoring.
- [x] The R2 audit and the R5 census in the report.

## Out of scope
- `config.nu`'s prose, which is correct and is
  [`config-nu-parse-claims`](../config-nu-parse-claims/prd.md)'s.
- `tests/nushell-core.sh`, already anchored.
- `tests/nvim-statusline.sh --headless`, the other new red from the same
  window, whose cause is the `oil.nvim` lockfile widening and not this one.

## Measured at spec time, 2026-08-23 — and the live exposure is exactly one site

**`tests/shell-listing.sh:108` is the whole of it.** Every other positional
lookup on the board agrees between substring and anchored matching on the real
files right now. So this is one live defusal plus a class census, not a fire.

`order_ok`'s four positions, both lookups:

| target | substring | anchored |
|---|---|---|
| `alias core-ls = ls` | **161** (the LISTING prose) | **202** (the declaration) |
| `def ls [` | 278 | 278 |
| `def la [` | 302 | 302 |
| 2nd PWD append | 490 | 490 |

The counterfactual, proved on a scratchpad mirror before the spec was written:

```
substring: core=161 defls=277  -> order HOLDS  (chk_fail loses)
anchored : core=793 defls=277  -> order BROKEN (chk_fail wins)
```

Baseline 35 PASS / 1 FAIL → patched **36 PASS / 0 FAIL**, check count 36 both
times, which is R4's proof that nothing was weakened.

**Three more `line_of` sites in the same file, none previously reported**, and
one of them changes the fix:

- `autolist_ok:141-142` searches `^stty sane` and ` la ` **inside** an
  extracted block, and both targets are **indented** — so line-start anchoring
  returns 0 and is the *wrong* fix. It needs comment-stripping instead. The
  hazard is already loaded: `config.nu:400` quotes `` try { la | print } `` in
  prose, and the only thing keeping it out of this lookup is that it sits
  above the block.
- `two_appends_ok:150-151` and `stage_tree:396` are not diverging, but
  `two_appends_ok` carries a `-eq 2` count guard beside the lookup — so a prose
  quote there goes **loudly red** rather than silently green.
- **The T1 diagnostic at `:369` was itself printing `161`** — the one line a
  reader would use to spot the defusal was reporting the comment.

## The census's most useful output is a taxonomy, not a list

Four mitigation shapes already exist on this board, and the right column is
which one fits: **line-start anchoring** (`nushell-core.sh:401-410`),
**comment-stripped input** (`nvim-statusline.sh:152`, `capsule-credentials.sh:143`),
**whole-line match** (`grep -nxF`, `shell-help.sh:161-163`), and **a count
assertion beside the lookup** (`capsule-lifecycle.sh:98`) — which converts a
silent defusal into a loud red, and is why that ten-def roster is safe despite
being a substring lookup.

The durable predicate, run twice with different inputs as the census rules
require — an awk detector for "a code line quoted verbatim in an earlier
comment": **`home/**` → 14 hits**, of which `config.nu:202 [alias core-ls = ls]`
is the one a gate reads positionally and `config.nu:496 [try { la | print }]`
is the one spec01's comment-stripping pre-empts. **`gates/fixtures/**` → zero.**

## Two follow-ups the census named, neither this node's

- **`tests/nushell-core.sh` is only half anchored.** `textual_order_ok` uses
  `line_of_decl`, but `funnel_binds:380-382`, S3.9 `:566-568` and S4.13
  `:594-596` still compare substring positions. That file is
  [`04-shell/01-core-config`](../../../04-shell/01-core-config/prd.md)'s. Filed
  as [`nushell-core-positional-lookups`](../nushell-core-positional-lookups/prd.md).
- **`wezterm.lua` is the highest-exposure input on the board** — **595 of 1237
  lines are comments, 48%** — and `wezterm-copy-mode.sh`,
  `wezterm-startup-layout.sh` and `wezterm-tab-content-state.sh` compare
  positions of `act.ClearSelection`, `return true`/`return false` and
  `get_foreground_process_name` with **no guard**, while their own comments
  assert "both strings occur only inside that callback" — an assumption one
  comment breaks. Filed as
  [`wezterm-gate-positional-lookups`](../wezterm-gate-positional-lookups/prd.md).
  Also named there: `tests/live-bugs.sh:174` and `gates/wave-status.sh:337`
  bound a `sed -n` window by a substring position over prose, so a quoting
  comment moves the window and changes what the assertion concludes.

## Landed 2026-08-23 — and the census corrected its own seed twice

`bash tests/shell-listing.sh` → **35 PASS / 1 FAIL → 36 PASS / 0 FAIL**,
re-run by the orchestrator, with **36 checks both times** — R4's proof that
nothing was weakened. The T1 diagnostic now prints **202**, not 161.

The in-block site was mitigated the right way and the wrong way was
*measured*: line-start anchoring on `^stty sane` / ` la ` returns **0** for
both, because the targets are indented. So `autolist_ok` got comment-stripped
input instead, proved on a fixture that inverts the real order and quotes
`^stty sane` inside the closure — **raw block: HOLDS (silently green); code
only: BROKEN (correctly red).**

**Zero verdict-A rows remain: there is no defused check on the board today.**
`shell-listing.sh:108` was the only one.

### Finding 1 — the count-guard rule I recorded is too generous

I wrote that "a count assertion beside the lookup converts a silent defusal
into a loud red". That holds **only for a substring count**. Measured on four
sites:

```
-cF  'def _capsule_name ['        real 1 -> fixture 2   guard FIRES (loud red)
-cF  'def --wrapped cc ['         real 1 -> fixture 2   guard FIRES (loud red)
-cxF 'source ~/…/pass.nu'         real 1 -> fixture 1   guard SILENT, line_of moves 545 -> 30
-cE  '^# ── MODULES ──$'          real 1 -> fixture 1   guard SILENT, line_of moves 537 -> 30
```

A whole-line (`-cxF`) or anchored (`-cE '^…$'`) count **does not increment**
when the quote is prefixed with `#` or indented — which is exactly what a
prose quote looks like. So the eight rows I would have called "partially
guarded" are **effectively unguarded on their anchor positions**, and the
exemplar generalises to substring counts only.

### Finding 2 — it distrusted its own second input

The twice-with-a-different-input rule was satisfied by `gates/fixtures/**`,
which is **4 files**: zero hits over four files is weak evidence, so it ran a
**third disjoint set** — the live `~/.config/{nushell,nvim,wezterm}`, 27 files,
10 hits. That is the census rule applied to the census's own evidence, one
turn after the rule landed.

Set 1 (`home/**`) reproduced the seeded 14 exactly, and turned up a **third**
live hit the seed named only in passing: `config.nu:563 [use std/help]` quoted
at `:555`, harmless today only because `shell-help.sh` reads it with `-nxF`.

### Scale, and the one fix worth more than nine nodes

**47 positional lookup groups across `tests/` and `gates/`; 25 are substring
form on prose-bearing input with no effective guard, covering 55 target
positions.** But **eight of the nine unfiled gates copy the same `line_of`
body and then look up `# ── MODULES ──` / `# ── PALETTE ──` by substring** —
so **one shared anchored helper in `gates/lib.sh` closes 22 of the 55 at
once.** Filed as
[`gates-lib-anchored-lookup`](../gates-lib-anchored-lookup/prd.md); the
per-gate work is named there rather than as nine nodes.

### Correction to a sibling node's recommended fix

[`wezterm-gate-positional-lookups`](../wezterm-gate-positional-lookups/prd.md)
R1 suggested line-start anchoring. **It will not work on any wezterm site** —
every target is indented Lua, and `index($0,s)==1` returns 0 for all ten. Those
gates need **comment-stripped input**, already proven by `nvim-statusline.sh`
on the same language. Corrected on that node.
[`nushell-core-positional-lookups`](../nushell-core-positional-lookups/prd.md)
is confirmed complete as filed.

### A new leakage mechanism, self-reported

It leaked 7 files into the repo root and removed them: running the `cp`-aside
baseline from the scratchpad left `gates/lib.sh` unsourced, so `gates_tmpdir`
was undefined, `SCRATCH=""`, and `cd "" && pwd -P` resolved to the repo root.
**Any gate run with an unresolvable `$REPO` writes its counterfactuals into
`$PWD`** — a one-line `[ -n "$SCRATCH" ] || exit` guard after `gates_tmpdir`
stops the whole class. Added to
[`gate-artifact-leakage`](../gate-artifact-leakage/prd.md). The real gate does
not leak, confirmed by a clean run.
