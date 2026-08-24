---
state: done
claim:
priority: 43
est: 0.35h
actual: 20m
mode: afk
footprint:
  - tests/nvim-statusline.sh
verify: "bash tests/nvim-statusline.sh"
origin: derived
---

# `03-editor/13-statusline` is `done` with a verify that exits 1, and nobody owns it

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: `bash tests/nvim-statusline.sh` — the node's **own, non-empty**
`verify:` — exits 1 with **188 PASS / 1 FAIL**, on its DevIcon counterfactual.

This is the worst ownership shape on the board:
[`lsp-gate-parser-seed`](../lsp-gate-parser-seed/prd.md) recorded it as "not
this node's", which was correct, and **no node picked it up**. So a `done`
node's own proof has been failing while every report about it said, truthfully,
that it belonged to somebody else.

Priority 43 because a `done` node with a red proof is the exact condition
[`done-nodes-without-proof`](../done-nodes-without-proof/prd.md) exists to
count — and this one is *worse* than the eighteen it found, because those had
no runnable proof at all while this one runs and says no.

**Likely cause, and the reason this needs measurement rather than a patch.**
`06-explorer` landed `oil.nvim` and its `nvim-web-devicons` dependency, and
that node measured something directly relevant: **deleting oil's `dependencies`
line alone changes nothing, because `statusline.lua:74` already declares
devicons — only deleting both empties the icon column.** Two nodes now declare
the same plugin, so a counterfactual that mutates one file may no longer
discriminate.

## Requirements
- [x] **R1** — **Measure first.** Establish whether the FAIL is (a) a
      counterfactual that no longer discriminates because a second node
      declares devicons, (b) a real regression in the statusline's icon
      rendering, or (c) an environmental artifact. Those are three different
      nodes' problems and only the first is this one's.
- [x] **R2** — If (a): the counterfactual mutates **both** declarations, with
      the reason in a comment — the shape `06-explorer` landed for the same
      dependency. If (b): **stop and report.** A rendering regression is
      `03-editor/13-statusline`'s or `06-explorer`'s, and this node must not
      quietly repair a feature under cover of a gate fix.
- [x] **R3** — No assertion becomes weaker, and the check count does not fall.
      188 PASS is the floor.
- [x] **R4** — **Say why nobody owned it.** Two nodes reported this red and
      both were right that it was not theirs. Recommend what should have
      happened — a filed node at report time, or a board rule that an
      unattributed red gets one automatically. That recommendation is worth
      more than the fix.
- [x] **R5** — Re-measure after any live nvim lane lands. `12-small-plugins`
      is in flight on the same census and lockfile.

## Acceptance
- [x] `bash tests/nvim-statusline.sh` reaches exit 0 with 0 FAIL, run
      **alone**, tally quoted not asserted.
- [x] R1's verdict with its measurement, and the counterfactual quoted red
      under the mutation it should catch.
- [x] R4's recommendation in the report.

## Out of scope
- The statusline config itself, unless R1 finds (b) — in which case report,
  do not fix.
- `06-explorer`'s files.

## Findings

**R1 verdict: (a).** Reproduced from this implementer's own runs, not taken
from the spec. Pre-change, the one red was

```
FAIL  counterfactual: the dependency deleted -> NO lualine_x_filetype_DevIcon group in the render, the filetype section loses its icon
```

while PROBE C's unmutated baseline stayed green
(`PASS render: a lualine_x_filetype_DevIcon group — nvim-web-devicons is on
lualine s side of the render (R1)`). So the feature renders and the *proof*
had gone inert: `lua/plugins/explorer.lua:37` declares the same plugin as
`lua/plugins/statusline.lua:74`, so deleting one line leaves devicons in the
lazy spec. With both deleted the same check is green. Not (b), not (c).

**The fix.** Counterfactual 2 now deletes both declarations in the staged copy
and carries one staging check that goes red if either deletion is a no-op or if
any non-comment line under the staged `lua/` tree still names the plugin —
`PASS counterfactual staging: explorer.lua's devicons line ALSO deleted, and
NOT ONE non-comment line under the staged lua/ tree still names
nvim-web-devicons (residue: none)`. A future third declaration is a red staging
check, not a second silently inert counterfactual. `f_dep` gained the selftest
pair it lacked, because after this mutation it is the only check defending
`statusline.lua`'s own clause.

**A recursive `grep -q` over `lua/` would go red on the correct tree.** The
spec measured that grep clean; it is not. `lua/plugins/which-key.lua:40` names
`nvim-web-devicons` in prose (its mini.icons note), so the guard strips Lua
line comments first — the same measured necessity `nocomm()` exists for.

**Check count: 189 -> 192, none weakened.** `grep -c '^PASS'` reads 193 on the
passing run; one of those lines is the trailing summary, so 192 checks.

**R4 — why nobody owned it.** Both prior reports were correct and both were
dead ends, because the board has a place to record a red and no place to
*route* one. `lsp-gate-parser-seed` correctly said "not mine" and stopped;
`done-nodes-without-proof` counts nodes with no proof and this node had one
that ran. The gap is structural: a red belonging to no claimed node has no
owner by default, and "not mine" is a complete report under today's rules.
Recommendation: **an implementer that reports a red outside its footprint files
the node in the same breath, and the orchestrator treats an unattributed red as
undispatchable until it has a node.** A one-line stub with the gate name, the
failing check text and the two runs is cheap; the expensive thing is the two
sessions that each measured this correctly and left it running red. Prefer this
over an automatic rule keyed on gate output — the attribution is the work, and
it needs the session that just measured it.

**Out-of-scope defect, reported not fixed.** `tests/nvim-statusline.sh` PROBE
C's diff pair (`render: a lualine_b_diff_added_ group carries +1` and `…and
the count it shows is +1`) is **flaky**, and it was already red before this
node's change — the spec's "exactly one red" precondition did not hold. lualine
spawns `git -C sub --no-pager diff --no-color --no-ext-diff -U0 -- note.txt`
asynchronously from the `BufEnter` the probe fires, and the probe reads the
render after a fixed `vim.wait(500)`. Measured in an isolated harness with a
byte-identical config: the group is present in **4/5** runs at load 6.26, then
**2/6** at load 2.94 — so it is process-spawn latency, not load average, and
`gitsigns` never loads (`noautocmd edit` skips `BufReadPre`). Across four
post-change gate runs it was red twice and green twice; the fourth run is
clean. Per
[`a-headless-gate-red-may-be-load-not-code`](../../../memos/a-headless-gate-red-may-be-load-not-code.md)
the settle window was **not** widened. This wants the `07-formatting` shape —
a bounded retry on a declared signal with the load printed — which is a
different node's design decision, not this one's staging fix.

## Closed 2026-08-24 by the orchestrator

`done`, R1–R5 and all three acceptance boxes ticked. `bash
tests/nvim-statusline.sh` → **exit 0, 192 checks, 0 FAIL**, run twice with the
load recorded both times (4.83 → 7.69, then 8.15 → 6.24). The floor rose from
189 to 192; nothing was weakened.

**`actual: 20m` against `est: 0.35h` (21m) — the first estimate on this board
to land dead on.** Worth noting against the other three pairs measured today:
a gate repair came in 25% over, and two document nodes came in 6x and 8x under.
The pattern that is emerging is not a board-wide ratio at all — it is that an
analyst who *prototypes the change before estimating it* produces an estimate
that holds, and this analyst ran the whole measurement itself.

**R1's verdict was (a), reproduced from the implementer's own runs:** the
counterfactual had stopped discriminating because `06-explorer` landed a second
`nvim-web-devicons` declaration. The baseline still renders the icon, so this
was a broken *proof*, never a broken feature, and nothing was repaired under
cover of a gate fix.

**One spec correction, measured:** the spec's recursive
`grep -rq 'nvim-web-devicons'` guard was described as clean and is not —
`lua/plugins/which-key.lua:40` names the plugin **in prose**, so a bare grep
goes red on a correct tree. The guard now strips Lua line comments first and
prints the residue in the check message, so a future red is diagnosable rather
than mysterious.

**A flaky check in a sibling's gate, measured properly and left red.** The
baseline was 186 PASS / 3 FAIL, not the 188/1 this PRD recorded: two extra reds
are PROBE C's diff pair (`render: a lualine_b_diff_added_ group carries +1` and
the count it shows). Isolated with a byte-identical config, lualine spawns
`git -C sub --no-pager diff …` **asynchronously** from the `BufEnter` the probe
fires, while the probe reads the render after a fixed `vim.wait(500)`. Present
in **4/5** runs at load 6.26 and **2/6** at load 2.94 — so it is
process-spawn latency, *not* load average, and `gitsigns` never loads because
`noautocmd edit` skips `BufReadPre`. The implementer did not widen the settle
window; the fix wants `07-formatting`'s shape — a bounded retry on a declared
signal, load printed, one probe with retry off — which is a design decision for
whoever owns that gate. Recorded in
[`an-unattributed-red-has-no-owner`](../../../memos/an-unattributed-red-has-no-owner.md)
with everything needed to pick it up.

**R4 is a report obligation and this is its report**, and the implementer
turned it into the sharpest process finding of the session: both prior attempts
to route this red were correct and both were dead ends, because the board has a
place to *record* a red and no place to *route* one. That argument is now a
memo and a change to how the orchestrator collects.
