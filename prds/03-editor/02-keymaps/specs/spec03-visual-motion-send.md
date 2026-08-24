---
est: 45m
footprint:
  - tests/nvim-keymaps.sh
---

# spec03 — repair the R4 v-mode send: one key per `nvim_feedkeys` call

`tests/nvim-keymaps.sh:370` sends `3GVj<A-k>` as one `nvim_feedkeys` batch.
Since [`14-shift-select`](../../14-shift-select/prd.md) landed, visual `j` is a
callback map whose own `nvim_feedkeys(…, "n", false)` **appends** to the
typeahead, so the batch's still-pending `<A-k>` runs ahead of the fed `j` and
the check measures `one,three,two,four` instead of `one,three,four,two`. This
spec repairs the send in that one probe, adds the counterfactuals that keep the
repair honest, and rewrites the gate's measured mechanic #2 — which now holds
only under a condition it does not state.

**Nothing outside `tests/nvim-keymaps.sh` is touched.** `keymaps.lua` is
correct and committed; `shift-select.lua` is another node's file. spec01 and
spec02 are landed and their boxes stay `[x]` — spec02's "`nvim_feedkeys` …
executes synchronously" line and its prescribed `feed 3GVj<A-k>` are
superseded here, not reopened.

## The fork, settled by measurement (2026-08-24, load avg 2.6–3.6)

The question was whether this check must move to the `--remote-send` RPC input
path the way `tests/nvim-shift-select.sh` did, or whether one key per
`nvim_feedkeys` call is enough. **Measured on the staged config, all four
cells, not reasoned about:**

| transport | how the keys are sent | measured |
|---|---|---|
| `nvim_feedkeys(…, "mx", false)` | one batch `3GVj<A-k>` | `one,three,two,four` — 5/5 runs (today's red) |
| `nvim_feedkeys(…, "mx", false)` | one key per call | `one,three,four,two` `mode=V` `sel=2-3` — 10/10 runs |
| `--remote-send` + queued `<Cmd>` marker | one key per send | `one,three,four,two` `mode=V` `sel=2-3` — 6/6 runs |
| `--remote-send` | one batch `3GVj<A-k>` | `one,three,two,four` |

**The transport is not the variable; the batching is.** Both transports agree
on the right value when the keys go one at a time and on the same wrong value
when batched. `nvim_feedkeys` therefore stays, for two reasons beyond cost:

- **It is not load-sensitive.** `"x"` drains the typeahead inside the process —
  no socket, no poll, no timeout. The RPC harness needs a settle marker with a
  30-tick poll and a TIMEOUT path (`tests/nvim-shift-select.sh` mechanics 4
  and 5, plus a 104-byte socket-path assertion), which is machinery whose
  failure mode is load. This machine is contended; re-verified 5/5 stable at
  load 4.9 with ten synthetic busy loops running.
- **It is not the case `tests/nvim-shift-select.sh` mechanic #1 describes.**
  There, `nvim_feedkeys` genuinely *mis-measured* the insert-mode shift maps
  (anchor column 2 vs 3) — a transport difference no batching change fixes.
  Here one-key `nvim_feedkeys` and the RPC path agree on all three observables
  (buffer, `mode()`, `line("v")`–`line(".")`), so this gate does not inherit
  that gate's harness.

Also measured, so the rule below is this gate's own rather than borrowed:
splitting the count from its motion (`feed("3")`, then `feed("G")`) measures
`one,two,four,three` with the cursor on line **4** — the count is lost across
two `feedkeys` calls, the same hazard as shift-select's mechanic #3 by a
different mechanism (no marker involved; each `"x"` drain ends the pending
command). So **a count and its motion stay in one call, and every other key
gets its own.**

## What to change

1. **`$W/movesel.lua`** (gate line ~370): replace `feed("3GVj<A-k>")` with
   `feed("3G")`, `feed("V")`, `feed("j")`, `feed("<A-k>")` — four calls, the
   count riding with its motion. Add a `start=` emission read after `3G` and
   before `V`, so a lost count is its own datum instead of an inference from
   the final buffer.
2. **Two new counterfactuals**, both probe-body mutations rather than config
   mutations, each asserting its **exact** measured value (an inequality
   against the expected value is what let today's red hide — see box 7):
   a batch-form probe measuring `one,three,two,four`, and a split-count probe
   measuring `one,two,four,three` with `start=4`.
3. **Strengthen the existing `cf-movesel` counterfactual** from
   `after != one,three,four,two` to `after == one,two,three,four`.
4. **Rewrite measured mechanic #2** in the gate header (lines 48–52) so it
   states its condition, its mechanism, and its date.

## Acceptance

- [x] **Red before.** With the gate as committed and before any edit,
      `bash tests/nvim-keymaps.sh` exits 1 at **106 PASS / 1 FAIL**, the FAIL
      is `R4: <A-k> on the lines 3-4 block moves it up`, and the line above it
      prints `after=one,three,two,four mode=V sel=2-3`. Quoted in the report.
  - Run 2026-08-24 before any edit, `rc=1`, 106 PASS / 1 FAIL (107 checks):

        move selection (rc 0): after=one,three,two,four mode=V sel=2-3
        FAIL  R4: <A-k> on the lines 3-4 block moves it up — one,two,three,four becomes one,three,four,two

- [x] **Green after.** After the repair `bash tests/nvim-keymaps.sh` exits 0
      with **0 FAIL** and the probe prints
      `after=one,three,four,two mode=V sel=2-3`.
  - `rc=0`, **111 PASS / 0 FAIL**:
    `move selection (rc 0): start=3 after=one,three,four,two mode=V sel=2-3`.
    Both stage splits green too: `--tree` 42 PASS / 0 FAIL rc 0,
    `--headless` 95 PASS / 0 FAIL rc 0.
- [x] **The check count went up, not sideways.** The green run reports
      strictly more checks than the red run's 107 (106 PASS + 1 FAIL) — the
      memo's floor rule: a repaired counterfactual raises the count so a
      strengthened gate cannot be mistaken for a quietly deleted check.
  - 107 → **111**, +4: the `start=3` precondition, the batch-form
    counterfactual, and the split-count pair (`start=4` and the buffer).
    Counted as `grep -cE '^(PASS|FAIL)  '`, which excludes the trailing
    summary line — the red run's summary reads `FAIL —` and the green run's
    `PASS —`, so a naive `^PASS` count would have compared 106 against 112.
    Diffed label-by-label: exactly four labels added, one reworded
    (`cf-movesel`), none removed.
- [x] **One key per call, count with its motion.** In the repaired
      `movesel.lua` the sequence travels as four separate `nvim_feedkeys`
      calls; no two of `3G` / `V` / `j` / `<A-k>` share a call, and `3G` is
      not split.
  - `feed("3G")`, `feed("V")`, `feed("j")`, `feed("<A-k>")` — four calls in
    `tests/nvim-keymaps.sh`'s `$W/movesel.lua` heredoc.
- [x] **The count is asserted, not inferred.** The probe emits `start=3` after
      `3G` and the gate `chk`s it, so a dropped count is red on its own line.
  - `PASS  R4 precondition: the count survived its motion — 3G landed the
    cursor on line 3, so a dropped count is red HERE and not inferred from
    the buffer`. Its own counterfactual below measures `start=4`, so the
    line can go red.
- [x] **Counterfactual — the batch form.** A probe sending all four keys in
      ONE `nvim_feedkeys` call measures **exactly** `one,three,two,four`, and
      the gate asserts that equality. This is the box that proves the one-key
      discipline is what carries the pass.
  - Against the **correct** staged config, so the send is the only variable:
    `batched send, correct config (rc 0): after=one,three,two,four mode=V
    sel=2-3` → `PASS  counterfactual: ONE nvim_feedkeys batch `3GVj<A-k>`
    measures EXACTLY one,three,two,four`.
- [x] **Counterfactual — the split count.** A probe sending `3` and `G` as two
      calls measures **exactly** `one,two,four,three` with `start=4`, and the
      gate asserts both.
  - `split count, correct config (rc 0): start=4 after=one,two,four,three
    mode=V sel=3-3` → two PASS lines, one per observable.
- [x] **The existing `cf-movesel` counterfactual now discriminates.** It
      asserts the exact value `one,two,three,four` rather than "not the
      expected value". Reason, on the record: under today's red the *correct*
      config also compared unequal to the expected value, so the inequality
      form went on passing while the check it exists to guard was FAIL — the
      "stopped discriminating" half of
      [`a-counterfactual-proves-its-own-mutation`](../../../memos/a-counterfactual-proves-its-own-mutation.md).
  - `if [ "$after2" = "one,two,three,four" ]` replaces
    `if [ "$after2" != "one,three,four,two" ]`, and the check's label now
    prints the value it demands. Measured: `no visual move maps (rc 0):
    after=one,two,three,four sel=3-3`.
  - **Distinctness verified rather than assumed**, since four exact-value
    assertions now share one probe shape: correct `one,three,four,two`,
    batched `one,three,two,four`, maps-deleted `one,two,three,four`,
    split-count `one,two,four,three` — four distinct permutations of
    `two,three,four` after `one`, so no counterfactual can satisfy its own
    negation. All four were measured in the green run, not reasoned about.
- [x] **Mechanic #2 no longer states an unconditional truth.** The rewritten
      comment says all of: that `"mx"` drains only what that one call was
      given; that a `vim.keymap.set` callback calling
      `nvim_feedkeys(…, "n", false)` **appends to the end** of the typeahead,
      so a batch's remaining keys execute first; that
      [`14-shift-select`](../../14-shift-select/prd.md)'s visual
      `h j k l <Up> <Down> <Left> <Right>` callbacks are the maps that make it
      conditional; the two measured values (`one,three,four,two` one-at-a-time
      vs `one,three,two,four` batched) with the date; and that a count and its
      motion must share a call, with the `one,two,four,three` measurement
      behind it.
  - Rewritten in place at the mechanics block, titled "feedkeys IS
    SYNCHRONOUS PER CALL, AND ONE KEY PER CALL IS THE RULE WHEN THE BATCH
    CROSSES AN E.14 MAP". It names `visual_motion` at
    `lua/config/shift-select.lua:92-102` as the mechanism's site. The two
    still-true sentences from the old text ("None of these maps does async
    work", the plain `-c` chain) are kept as the closing paragraph, where
    they no longer read as a licence to batch.
- [x] **The comment records that the transport was measured.** It states that
      the same batch over `--remote-send` measures the same wrong value — so
      the variable is batching, not transport — and that this is why the gate
      keeps `nvim_feedkeys` instead of adopting
      `tests/nvim-shift-select.sh`'s RPC harness. A future reader must not have
      to re-run the 2×2 to know why.
  - The paragraph headed "THE VARIABLE IS BATCHING, NOT TRANSPORT" carries
    both `--remote-send` cells, the three observables the two transports
    agree on, the settle-marker/30-tick-poll cost it declines, and the note
    that this is *not* `tests/nvim-shift-select.sh` mechanic #1's
    mis-measurement case.
- [x] **The other batched `feed()` calls are justified in one line, not left
      unexamined.** The comment records that no remaining batched send in this
      gate contains a key E.14 maps in the mode it is sent in, and names the
      set it checked against: v-mode `h j k l <Up> <Down> <Left> <Right>`,
      n/v/i `<S-Up>/<S-Down>/<S-Left>/<S-Right>`, v-mode `<C-c>`/`<C-v>` —
      22 maps. (Verified while speccing: the surviving batched sends are
      `gg`, `<A-j>`, `2GV<A-k>`, `2GV>>`, `2GV`, `3GV`, `<S-l>`, `<S-h>`,
      `<leader>w`, `<leader>p`, and none crosses one.)
  - The "SWEPT" paragraph lists all ten surviving sends and all 22 maps.
    Re-checked against the module rather than taken on trust: 4 n-mode
    `<S-arrow>` + 4 v-mode `<S-arrow>` + 8 v-mode motions + 4 i-mode
    `<S-arrow>` + v-mode `<C-c>`/`<C-v>` = 22, at
    `lua/config/shift-select.lua:104-138`.
- [x] **The three guard lines `14-shift-select` depends on still PASS** in
      `--tree`: `keymaps.lua` holds no shift-select machinery
      (`f_noshift`), no `nvim_create_autocmd` (`f_noau`), and no `map(` on
      `<C-q>`/`<C-c>`/`<C-v>` (`f_nokeys`), plus the epic-wide `<C-q>` sweep.
      Quoted from the green run.
  - From the `--tree` run (rc 0):

        PASS  tree: no shift-select machinery — no shift_select flag, no <S-arrow> map (E.14's)
        PASS  tree: zero autocmds — the live ungrouped ModeChanged is L-8 and E.14's
        PASS  tree: no map call on <C-q>, <C-c> or <C-v> (R9 and E.14's keys)
        PASS  tree: R9 epic-wide — no map call under lua/ takes <C-q>, including unloaded plugin keys

- [x] **Nothing outside the gate moved.** `git diff --stat` names
      `tests/nvim-keymaps.sh` and nothing else — in particular neither
      `home/dot_config/nvim/lua/config/keymaps.lua` nor `shift-select.lua`,
      and not `gates/waves.tsv` (the gate is already registered in wave 3).
  - `tests/nvim-keymaps.sh | 142 +++…`, 135 insertions / 7 deletions, five
    hunks, all in this lane's regions. `keymaps.lua` does not appear in
    `git status` at all (committed, unmodified); `shift-select.lua` is
    E.14's own untracked file and was read, never written; `gates/waves.tsv`
    carries another lane's pre-existing edit and none of mine. The rest of
    the worktree's modifications predate this lane.

## Out of scope

- Any change to `shift-select.lua`. Passing `insert = true` to the callback's
  `nvim_feedkeys` would put the fed key at the *front* of the typeahead and
  make the batch work — it is the wrong fix here: it is another node's file and
  it would change E.14's runtime behaviour to suit a test harness.
- Migrating this gate's other probes to RPC, or to one-key-per-call, when they
  cross no E.14 map. The measurement above says the batching only matters
  across a feeding callback.
- Reopening spec01 or spec02, or their `[x]` boxes.

## Verify and Proof

```sh
# 1. red before — run BEFORE editing, quote the FAIL and the after= line
bash tests/nvim-keymaps.sh; echo "rc=$?"

# 2. green after — same command, plus the two stage splits waves.tsv's
#    neighbours use, so a stage-specific break cannot hide in the no-arg run
bash tests/nvim-keymaps.sh; echo "rc=$?"
bash tests/nvim-keymaps.sh --tree; echo "rc=$?"
bash tests/nvim-keymaps.sh --headless; echo "rc=$?"

# 3. the footprint really is one file
git diff --stat
```

Measured while speccing, as the implementer's expected wall clock: a full
`bash tests/nvim-keymaps.sh` is ~26s at load 3.5.

**`est` calibration, stated because the board's aggregate would be wrong
here.** Calibrated off [`14-shift-select`](../../14-shift-select/prd.md) —
`est: 2h`, `actual: 35m` — which is editor-gate work measured tonight on this
machine, and which delivered a 138-line module *and* a 906-line RPC gate from
scratch. This spec is strictly smaller: four lines of probe body, one comment
block, two new probe files and ~6 `chk` lines in an existing 800-line gate,
plus three gate runs at ~26s. It is not a 15-minute edit either, because the
red-before/green-after pair and the two exact-value counterfactuals each have
to be run and quoted. **45m.**
