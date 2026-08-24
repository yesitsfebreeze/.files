---
state: done
claim:
priority: 12
est: 2h
actual: 35m
task: E.14
mode: afk
needs:
  - 00-delivery/decisions/shift-select-scope
  - 03-editor/02-keymaps
  - 06-help/01-content-model
footprint:
  - home/dot_config/nvim/lua/config/shift-select.lua
  - home/dot_config/nvim/init.lua
  - tests/nvim-shift-select.sh
  - tests/nvim-options.sh
verify: "bash tests/nvim-shift-select.sh"
---

# Shift-to-select (SIMPLIFY)

Parent: [Neovim epic](../prd.md) · C 7 · U 7 · source: "Shift-to-select
(editor-style selection)" in
[`capabilities-nvim.md`](../../../docs/capabilities-nvim.md)

Purpose: The signature customization: Shift+arrows select like a conventional
editor — including the part most vim configs get wrong, where a plain motion
after a shift-selection *collapses* the selection instead of extending it. A
`v`-started selection keeps full vim semantics. This is the most intricate
hand-rolled logic in the config (~60 lines of mode feeding and flag tracking).
It earns its place, but it is the one feature worth either porting with tests
or consciously downgrading to plain Shift+arrow selection.

## Requirements
- [x] **R1** — **Premise.** `clipboard=unnamedplus` from
      [01-options](../01-options/prd.md) — the system clipboard is shared, so copy
      and paste cross between Neovim and the terminal.
      *Proven:* `bash tests/nvim-shift-select.sh --headless` reads
      `[unnamed|plus|provider-copies|clipboard]=[kl|kl|1|unnamedplus]` after a
      visual `<C-c>`, so the yank reached `+` — through a scratch provider,
      never the real pasteboard.
- [x] **R2** — **State flag.** A `shift_select` boolean, set whenever a
      selection begins via Shift (from normal, visual, or insert mode), and
      reset by a `ModeChanged` autocmd whenever visual mode is left (old mode
      matching `^[vV\22]`). Without that reset, a later plain `v` selection
      would inherit collapse-on-motion behavior.
      *Proven:* the tree stage asserts one `nvim_create_autocmd`, its
      `augroup shift_select` with `clear = true`, `pattern = "*:*"` and the
      `^[vV\22]` guard; the headless stage measures the escape path
      `<S-Right> <Esc> v l` as `v|2|5|2|4|lm`, and the `noau` counterfactual —
      the autocmd deleted from a copy — collapses it to `n|2|5|2|5|`.
- [x] **R3** — **Start from normal.** `<S-Up/Down/Left/Right>` → enter visual
      and apply the motion. *Proven:* `<S-Right>` measures `v|2|4|2|3|kl`,
      `<S-Left>` `jk`, `<S-Up>` `cdefgh/ijk`, `<S-Down>` `klmnop/qrs`, each
      read back over the RPC input path.
- [x] **R4** — **Extend from visual.** `<S-arrows>` keep extending (flag stays
      set). *Proven:* `<S-Right><S-Right>` measures `v|2|5|2|3|klm`, one press
      per `--remote-send` because two in one batch land in normal mode.
- [x] **R5** — **Start from insert.** `<S-arrows>` leave insert and start the
      selection; `<S-Right>` needs an extra `l` first so the character under
      the insert cursor is included. *Proven:* insert `<S-Left>` after typing
      `x` measures `v|2|2|2|3|jx`; insert `<S-Right>` measures `v|2|4|2|3|kl`;
      and the `nol` counterfactual (`lv<Right>` → `v<Right>`) moves the anchor
      3 → 2 and the selection to `jk`.
- [x] **R6** — **Collapse on plain motion.** In visual mode, `h`/`j`/`k`/`l`
      and the unshifted arrows: if `shift_select` is set, clear it, leave
      visual, and apply the motion; otherwise apply the motion normally.
      Counts must be preserved in both branches (`vim.v.count`). **Not
      optional** — see the declined simplification below.
      *Proven:* `<S-Right> l` measures `n|2|5|2|5|`; `<S-Down> 3j` measures
      `n|6|3|6|3|`; the other branch measures `v|2|4|2|3|kl` for `v l` and
      `v|5|3|2|3|…` for `v 3j`, so the count survives there too; and the
      `nocount` counterfactual lands on line 4 instead of 6.
- [x] **R7** — **Clipboard keys.** Visual `<C-c>` → `y` (to the shared
      clipboard, leaving visual); visual `<C-v>` → `"_dP` (paste over the
      selection without clobbering the register).
      *Proven:* `<C-c>` leaves visual with `kl` in `"` and in `+`; `<C-v>`
      turns `qrstuvwx` into `qrkluvwx` with the register intact, and a second
      `<C-v>` pastes the same `kl` again. The `plainp` counterfactual
      (`"_dP` → `p`) clobbers the register to `st` and pastes `yz0st345`.
- [x] **R8** — **Feeding helper.** All of the above go through one
      `nvim_feedkeys` + `nvim_replace_termcodes` helper — not scattered
      `<cmd>` strings. *Proven:* the tree stage asserts exactly one call site
      of each and zero `<cmd>` strings, with a selftest that plants a second
      `nvim_feedkeys` in a copy and shows the check red.

## Acceptance

**The counts below were corrected 2026-08-24 by the user's answer, and the
old ones are recorded under the warning so nobody re-derives them.** The live
behaviour stands: charwise-inclusive selection, two characters per press.

- [x] From normal: **one `<S-Right>` selects two characters** (`kl` with the
      cursor on `k`), and `<S-Right><S-Right>` selects three (`klm`);
      pressing `l` then leaves visual and moves right one (selection gone).
      Measured `v|2|4|2|3|kl`, `v|2|5|2|3|klm`, `n|2|5|2|5|` — mode, cursor,
      anchor and selected text, read back after every press.
- [x] From `v`: pressing `l` extends the selection, as in stock vim.

      **This box proves nothing on its own** — measured 2026-08-24 and
      recorded by the orchestrator. With R2's autocmd stripped, plain `v`
      then `l` still extends (`mode=v`, anchor 3 → cursor 4), identical to the
      correct module, because stock vim already does this. The discriminator
      is the **escape path**: `<S-Right>`, `<Esc>`, `v`, `l` gives `mode=v`
      with anchor 4 → cursor 5 when the autocmd is present, and collapses to
      `mode=n` with anchor = cursor = column 5 when it is gone. Both are
      asserted; only the second can fail. Both reproduced: `v|2|5|2|4|lm` with
      the module as written, `n|2|5|2|5|` in the `noau` counterfactual — and
      the plain `v l` case measures the same `v|2|4|2|3|kl` in the vacuity
      staging, printed there so nobody mistakes it for proof.
- [x] From insert: **`<S-Left>` selects two characters — the one just typed
      and the one before it** (type `x` over `k`, get `jx`). Measured
      `v|2|2|2|3|jx` over the RPC input path.
- [x] From insert: `<S-Right>` selects two characters (`kl`) — the mapping's
      `l` correction does apply here, and it is measured, not assumed.
      Measured `v|2|4|2|3|kl`; without the extra `l` the same probe measures
      `v|2|3|2|2|jk`.
- [x] `3j` in a shift-started selection collapses and moves three lines. The
      fixture needs **at least six lines**: a four-line buffer clamps, and the
      check then cannot tell three lines from the end of the file. Measured
      `n|6|3|6|3|` in an **eight**-line fixture. A fifth mechanic was found
      here and is recorded below: the count and its motion have to be **one**
      `--remote-send`, or the settle marker between them eats the pending
      count and the probe lands on line 4 while reporting a pass.
- [x] `<C-c>` in visual copies to the system clipboard (pasteable in the
      terminal); `<C-v>` over a selection replaces it and the clipboard still
      holds the original copy. Measured against a **scratch** clipboard
      provider, never the real pasteboard: `kl` in `"` and `+` with one
      provider copy, `qrkluvwx` after the paste, and `yz0kl345` from a second
      paste of the same register.

Off-by-one warning, carried from the 2026-08-21 plan review (finding M-2) and
**resolved 2026-08-24: the acceptance criteria were the thing that was off by
one, not the mappings.** M-2 offered three readings and nobody had picked one.

The old boxes demanded that one `<S-Right>` select **one** character and that
insert `<S-Left>` select **the character just typed** — one — and the warning
made those counts binding: "implement to them, not to the first mapping that
appears to work". Measured 2026-08-24 on Neovim 0.12.4, live block staged into
a scratch config and driven through the real input path
(`nvim --headless --listen` plus `nvim --server --remote-send`), fixture
`ijklmnop`, cursor on `k` at column 3: `<S-Right>` gives anchor 3 → cursor 4,
selecting `kl`; `<S-Right><S-Right>` gives `klm`; insert-then-`<S-Left>` gives
`jx`. The one-character variants (`v` bare, `<Esc>v`, `<Esc>lv`) were also
measured and do work — so this was a genuine fork between two working mapping
sets, not a defect.

The user kept the live behaviour, for two reasons on the record: it is the
daily muscle memory being ported, and the shipped manual entry in
`help/nvim.nuon` — landed by the `done`
[`06-help/01-content-model`](../../06-help/01-content-model/prd.md) — already
documents it *with its reason*: "from insert, `<S-Left>` catches the last two
characters rather than one … the extra character is the price". Choosing
editor-exactness would have falsified a reviewed manual entry and forced a
fresh review digest, and it would have fixed only the horizontal half:
`<S-Up>`/`<S-Down>` stay charwise-inclusive regardless of which set is used.

## How the gate must drive the keys

Four mechanics measured 2026-08-24 by the analyst, each of which silently
falsifies this node's headline checks if ignored. They are here rather than in
a spec because they outlive the spec.

- **`nvim_feedkeys` mis-measures the insert-mode shift maps.** Under
  `nvim_feedkeys(keys, "mx")` the mapping's fed `l` is lost: insert
  `<S-Right>` measures anchor column 2 and `jk`, where the real input path
  measures anchor 3 and `kl`. `tests/nvim-keymaps.sh`'s documented mechanic
  #2 — "feedkeys IS SYNCHRONOUS HERE" — is true of E.3's maps and **not** of
  these. This gate needs the RPC input path.
- **One press per call.** Two `<S-Right>` in a single `nvim_feedkeys` batch
  land in *normal* mode, because the second callback's queued `v` toggles
  visual off. Batched, the headline acceptance measures an artifact.
- **`nvim_input` never drains** inside a `-c luafile` headless script — every
  probe left the mode unchanged and the buffer untouched at rc 0. A gate built
  on it would be silently vacuous, which is exactly the shape
  [`the counterfactual memo`](../../memos/a-counterfactual-proves-its-own-mutation.md)
  forbids.
- **No collision with E.3**: `<C-c>`, `<C-v>` and `<C-q>` are free, and that
  node's file comment says why. Nothing here touches `<C-l>`, so the
  built-in-replacement class E.3 found does not recur.

## Out of scope
- Anything this node's Requirements do not name. The epic ([`../prd.md`](../prd.md)) owns the shared invariants.

## Simplification option — DECLINED 2026-08-21

The option was: keep only Shift+arrow selection and the clipboard keys, drop
collapse-on-motion, and re-rate the node down to roughly C 3 / U 5.

**Declined on 2026-08-21 by the human, in
[`shift-select-scope`](../../00-delivery/decisions/shift-select-scope/prd.md)
(task D.3). The full port is the path: R1–R8 in full, with the tests.**

Why it was declined, so nobody has to re-derive it: collapse-on-motion is the
part that makes shift-select feel native instead of half-implemented. Without
it this is a plain Shift+arrow map — what every half-configured vim already
does — so dropping R6 does not make the capability smaller, it removes the
reason it rates U 7 at all. And the tests are not a bolt-on. The ~60 lines of
mode feeding and flag tracking have exactly one failure mode, and it is
silent: a later change to [`02-keymaps`](../02-keymaps/prd.md) or
[`03-autocmds`](../03-autocmds/prd.md) breaks the collapse semantics, every
keymap still exists, and nothing complains. That is the thing the tests pin.
The tests being burdensome *is* the cost that was weighed, and accepted.

What follows, binding on any later agent:

- Every requirement R1–R8 stands. R6 is not a stretch goal.
- The header stays **C 7 · U 7**, matching the `Shift-to-select (editor-style
  selection)` entry in
  [`capabilities-nvim.md`](../../../docs/capabilities-nvim.md). The C 3 / U 5
  downgrade **does not apply**, and the inventory entry is unchanged.
- The `SIMPLIFY` marker in the title stays. The inventory verdict offered
  "port it deliberately, with tests, or accept plain Shift+arrow selection",
  and the first branch is the one taken — `SIMPLIFY` here does not license
  dropping requirements.
- **This fork is closed; a worker does not re-take it.** An agent that finds
  the tests burdensome files a correction in
  [`04-corrections-backlog`](../../00-delivery/corrections/prd.md) and stops.
  It does not drop R6, re-rate the node, or edit the inventory entry.
  Re-deciding needs the person who decided.

## Questions

*Raised 2026-08-24 by `analyst-shift-select`, round 1. One question; the
2026-08-21 decision does not reach it.*

Question *Q1*: **How many characters does one Shift+arrow press select — the
live two, or the editor-exact one?**

This node cannot be specced until this is settled, because the two records
that bind it disagree, and each one names a *different* set of mappings.

**What was measured**, on this machine, 2026-08-24, Neovim 0.12.4, against the
live block at `~/.config/nvim/lua/config/keymaps.lua:42-127` staged into a
scratch config, driven through the **real input path** (`nvim --headless
--listen` plus `--remote-send`, so mappings run as if typed). Fixture line 2 is
`ijklmnop`, cursor on `k` (1-based column 3):

| Keys | Anchor → cursor | Selected |
|---|---|---|
| normal `<S-Right>` | col 3 → col 4 | `kl` — **2 chars** |
| normal `<S-Right><S-Right>` | col 3 → col 5 | `klm` — **3 chars** |
| normal `<S-Left>` | col 3 → col 2 | `jk` — 2 chars |
| insert, type `x`, `<S-Left>` | col 3 → col 2 | `jx` — **2 chars** |
| insert `<S-Right>` | col 3 → col 4 | `kl` — 2 chars, the `l` correction works |
| shift-selection then `l` | — | collapses, moves one right (R6 holds) |
| `v` then `l` | col 3 → col 4 | extends, stock vim (R6's other branch holds) |
| `<S-Down>` then `3j` | — | collapses, moves three lines |

So the machinery (R2, R6, R7, R8) reproduces exactly as specified. Only the
**counts** are in dispute, and only for the horizontal maps:

- This PRD's Acceptance says `<S-Right><S-Right>` selects **two** characters
  and that from insert `<S-Left>` selects **the character just typed** — one.
  The off-by-one warning under it makes that binding: "the acceptance counts
  above are the contract; implement to them".
- The shipped manual says the opposite, deliberately. `help/nvim.nuon`
  (landed by [`06-help/01-content-model`](../../06-help/01-content-model/prd.md),
  `done`) documents "from insert, `<S-Left>` catches the last two characters
  rather than one" and gives the reason: the insert caret sits *between*
  characters, leaving insert drops the cursor onto the one behind, "`<S-Right>`
  moves right once before entering visual, or the character under the cursor is
  left out; leftward there is nothing to correct, and the extra character is
  the price".
- Finding M-2 in the [corrections backlog](../../00-delivery/corrections/prd.md)
  is still **open** and reads the disagreement the third way — that the
  *acceptance criteria* are the thing that is off by one. Nobody has picked a
  direction.

**Option A — keep the live behavior.** Port the block as it stands: `v` plus
the motion from normal, `<Esc>v<motion>` from insert with the extra `l` on
`<S-Right>`. One press selects two characters, N presses select N+1. Cost:
Acceptance boxes 1 and 3 of this PRD are wrong and get corrected to the
measured counts, and M-2 closes as "criteria fixed, code unchanged".

**Option B — editor-exact horizontal counts.** One press selects exactly one
character: normal `<S-Right>` becomes a bare `v`, insert `<S-Left>` becomes
`<Esc>v`, insert `<S-Right>` becomes `<Esc>lv` (all three measured at 1
character). Cost: it deviates from the daily driver, the manual's entry and its
`why` become wrong and need a correction against a `done` `06-help` node, and
the fix is only half a fix — `<S-Up>`/`<S-Down>` stay charwise-inclusive and
still cover one character more than a non-modal editor would, which no mapping
change reaches. It also opens a follow-up for a later round: whether normal
`<S-Left>` should anchor on the character under the cursor (`v`) or the one to
its left (`<Left>v`).

Recommendation **Option A — keep the live behavior, and correct this PRD's two
acceptance counts.** Three reasons: it is what you type every day, so the
"off-by-one" is muscle memory rather than a defect; the manual already
documents it *with* the reason, and that reason is correct about why the insert
maps cannot be symmetric; and Option B fixes only the horizontal half, so the
inconsistency it removes from `<S-Right>` reappears on `<S-Down>`. The board
rule that "the live config wins" points the same way.

## Answers

Answered 2026-08-24 by the user, in the round the analyst asked.

**Q1 — keep the live behaviour; this PRD's counts were what was wrong.** Two
characters per `<S-Right>`, two for insert `<S-Left>`. Acceptance boxes 1 and 3
are corrected above, the fourth reading of the fork is closed, and **M-2 is
resolved as describing the acceptance criteria rather than the code** — its
third reading was the right one.

Two reasons on the record. It is the daily muscle memory this port exists to
carry over; and the shipped manual entry already documents it *with its
reason*, so editor-exactness would have falsified a reviewed entry, cost a
fresh review digest against a `done` node, and fixed only the horizontal half
— `<S-Up>`/`<S-Down>` are charwise-inclusive either way.

The settled 2026-08-21 scope is untouched by this: full port, R6
collapse-on-motion included, tests included, `C 7 · U 7`. This round settled
*counts*, which that decision never adjudicated.

## Implementation — 2026-08-24

Landed by `implementer-shift-select`. Four paths, the footprint exactly:

| Path | What changed |
|---|---|
| `home/dot_config/nvim/lua/config/shift-select.lua` | new: the R1–R8 port, 22 `map(` call sites, one `feed` helper, one **grouped** autocmd |
| `home/dot_config/nvim/init.lua` | one require, between the general maps and the plugin manager |
| `tests/nvim-shift-select.sh` | new: the node's gate, `--tree` and `--headless` |
| `tests/nvim-options.sh` | the E.1 file census gains `./lua/config/shift-select.lua` and the `post-E.14` label |

`bash tests/nvim-shift-select.sh` — **157 PASS, 0 FAIL, rc 0, 33 s** at load
average 4.45. Split: `--tree` 63 PASS in 12 s, `--headless` 90 PASS in 24 s.
No timing assertion in this gate has a budget to widen; the two deadlines
(server readiness, settle marker) print the load average and FAIL as TIMEOUT
rather than skipping.

**The census, red before and green after**, per
[`a-counterfactual-proves-its-own-mutation`](../../memos/a-counterfactual-proves-its-own-mutation.md).
Measured by hand while landing, and then folded into the gate so it repeats:

- with the file present and the entry missing, `bash tests/nvim-options.sh
  --tree` exited **1**, red on `tree: home/dot_config/nvim/ holds exactly the
  post-E.12 census`, whose `got:` string named `./lua/config/shift-select.lua`;
  `tests/nvim-options.sh` was sha `8406befd5204`.
- after the entry and the label went in, sha `b74dc7f0b187`, the same command
  exited **0**. So: `sha 8406befd5204 -> b74dc7f0b187`, rc `1 -> 0`.
- the gate now re-runs both halves against a **copy** of the repo, mutating
  the copy's census string and reading only the census line out of that run —
  `copy sha b74dc7f0b187 -> e24e7f1b652f` red, `-> b74dc7f0b187` green. The
  real tree is never mutated, and this node asserts none of E.1's other
  checks.

**Two deliberate deviations from the live block**, both recorded in the
module's own header:

- the `ModeChanged` autocmd is **grouped** (`augroup shift_select`,
  `clear = true`), which epic I7 requires and the live ungrouped site (live
  bug L-8) does not do.
- the eight collapse-on-motion maps are written out one per line instead of
  generated in a `for` loop. Behaviour is identical; the spec's acceptance
  counts `map(` call sites and reads each mode/lhs/`desc` triple out of the
  file, and a loop hides both from a text check.

### Two mechanics found while building the gate

Neither is in the spec, and each one produces a **green that measures
nothing**, so both are in the gate's header where the next reader will hit
them:

- **A count and its motion must be ONE `--remote-send`.** The spec's "one
  press per call" is right for the shift keys and wrong for a count: with the
  settle marker between `3` and `j`, the marker's command consumes the pending
  count and `<S-Down> 3j` lands on line **4** — which is also what the
  count-dropped counterfactual measures, so a split send makes R6's count
  check indistinguishable from its own counterfactual. Sent as one `3j` it
  lands on line 6.
- **macOS truncates a unix socket path at 104 bytes, silently.** A server
  asked to listen on `…/scratchpad/proto/dbg.sock` created a socket named
  `…/proto/db`; the next server on a different long path then failed with
  `address already in use`, and every probe read back **empty at rc 0** for
  three minutes of a run that looked like it was working. The gate keeps its
  socket in a short `mktemp -d` directory and asserts the length as a
  precondition.

Two smaller ones, also in the header: the settle marker (`<Cmd>lua
SS_bump()<CR>` queued behind the key, then polled) replaces both a fixed sleep
and the "two identical consecutive reads" poll — the latter passes vacuously
when both reads land before the key is processed; and the client runs
`-u NONE`, which is 13 ms against a full config load, while the **server** is
the full staged config.

### Owed to the orchestrator

`gates/waves.tsv` is not this node's file. The row it needs:
`external bash tests/nvim-shift-select.sh` alongside the other E-task gates
(E.14 in the task column). The gate takes 33 s and runs both stages by
default.

### One finding outside this node, reported and NOT fixed

`tests/nvim-keymaps.sh` (E.3, `done`) goes red on exactly one check once this
node lands: `R4: <A-k> on the lines 3-4 block moves it up`, at `:370`, which
feeds `3GVj<A-k>` as a **single** `nvim_feedkeys` batch. `j` is now a visual
mode map, and its callback's `nvim_feedkeys(…, "n", false)` appends the fed
`j` to the **end** of the typeahead, so the trailing `<A-k>` runs first.

Measured both ways on the staged config with this module present:

| How the keys arrive | Result |
|---|---|
| one at a time, over `--remote-send` (what a person types) | `one,three,four,two`, mode `V`, selection 2-3 — E.3's expected value |
| `3GVj<A-k>` as one `nvim_feedkeys` batch (E.3's probe) | `one,three,two,four` |

So the behaviour is **not** regressed — E.3's mechanic #2 ("feedkeys IS
SYNCHRONOUS HERE") stops holding for a batch that crosses one of this node's
maps, which is E.3's probe to split, not this node's mapping to change. The
live config has always had both sets in one file. E.3's `--tree` stage, which
this node's spec names, is green: 106 of 107 checks pass, and the one red is
the batch above. `tests/nvim-autocmds.sh --tree`, `tests/nvim-plugin-manager.sh
--tree` and `tests/nvim-options.sh` (full) are green beside it.

One unrelated observation, not filed: a `vicky/` directory sits in the repo
root, dated 2026-08-22, holding `Dashboard.md`, `WORKFLOW.md`, `sources/` and
`conclusions/`. Nothing in this node created or touched it.

## Closed 2026-08-24 by the orchestrator

`done`. **The editor epic is complete.** `bash tests/nvim-shift-select.sh` →
**157 PASS / 0 FAIL, rc 0**, run twice (33.2s and 35.5s at load 4.4);
`--tree` 63 PASS, `--headless` 90 PASS. R1–R8 and all six acceptance boxes
`[x]`, each against the value that proved it, plus spec01's fifteen.
`keymaps.lua` is byte-identical to HEAD and the gate asserts it.

**Every count came out as the 2026-08-24 answer settled them**: `<S-Right>` →
`kl`, twice → `klm`, insert `<S-Left>` → `jx`, insert `<S-Right>` → `kl`,
`<S-Down>` then `3j` → line 6 of 8, and the escape path → anchor 4 → cursor 5.
The vacuity control asserts the built-ins **by value** (`<S-Left>` word-left
col 3 → 1, `<S-Down>` page-down line 2 → 8), so it cannot pass by measuring
nothing — the same discipline E.3's `<C-l>` finding forced.

**`actual: 35m` against `est: 2h`.** The analyst calibrated off E.3 rather than
the board average and said why; it came in under, but by 3.4x rather than the
6-8x the document nodes showed. Five pairs now, and the pattern that predicts
best is still whether the analyst measured before estimating.

**Two mechanics found here, and both are in the gate's header rather than only
in a report:**

- **A count and its motion must travel in one `--remote-send`.** With a settle
  marker between `3` and `j`, the marker's command eats the pending count and
  `<S-Down> 3j` lands on line 4 — *the same value the count-dropped
  counterfactual measures*. A split send would have made R6's check
  indistinguishable from its own counterfactual: a check that agrees with its
  negation.
- **macOS truncates a unix socket path at 104 bytes, silently.** A server asked
  to listen on `…/proto/dbg.sock` created `…/proto/db`; the next server then
  failed `address already in use`, and every probe read back empty **at rc 0**
  for three minutes of a run that looked healthy. The gate keeps its socket in
  a short `mktemp -d` and asserts the length. Settling is a queued
  `<Cmd>lua SS_bump()<CR>` marker rather than a sleep or a
  two-identical-reads poll — the latter passes vacuously when both reads land
  before the key is processed.

**The census red/green pair was proved against a copy**: `nvim-options.sh
--tree` exited 1 with its `got:` naming the new file at sha `8406befd5204`, and
0 after the entry at `b74dc7f0b187`. The gate reads only the census line out of
that run, so it asserts none of E.1's other checks — which is how a node proves
a shared file's line without inheriting the whole gate.

**The registry row is written**: `gates/waves.tsv` wave 4 now carries
`external bash tests/nvim-shift-select.sh`, and `wave-status.sh --validate`
exits 0.

**One red this node causes, routed to its owner rather than absorbed here:**
`tests/nvim-keymaps.sh:370` (`R4: <A-k>` on the lines 3-4 block moves it up)
goes red now that a visual-mode `j` map exists. Behaviour is **not** regressed
— sent one key at a time the result is E.3's expected `one,three,four,two`; it
is the gate's batch that breaks, because a fed `j` is appended to the end of
the typeahead so the trailing `<A-k>` runs first. E.3's mechanic #2 ("feedkeys
IS SYNCHRONOUS HERE") stops holding for a batch that crosses an E.14 map. That
belongs to [`02-keymaps`](../02-keymaps/prd.md), which owns that file, and it
has been reopened with the measurement.
