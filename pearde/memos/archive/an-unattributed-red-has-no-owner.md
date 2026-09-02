---
memo: an-unattributed-red-has-no-owner
kind: decision
status: decided
subject: A red outside every claimed footprint belongs to nobody by default — the orchestrator routes it at collect time, and "not mine" is no longer a complete report
date: 2026-08-24
updated: 2026-08-24
prds:
  - 00-delivery/corrections/statusline-devicon-red
  - 03-editor/13-statusline
  - 04-shell/07-quicklist
---

# an-unattributed-red-has-no-owner — recording a red is not routing it

## Decision

**"Not mine" is no longer a complete report.** A worker that finds a red
outside its own footprint still may not fix it and still may not file it — that
rule stands, and it exists because a worker cannot see the board's ratio. What
changes is the other end: **the orchestrator must route every reported red on
the collect that receives it**, to exactly one of three places, and say which:

1. a **node** that owns it, when fixing it changes what ships;
2. a **memo** carrying the full measurement, when it changes only how loudly
   the board would have noticed — and the memo names the gate, the failing
   check text, and the runs;
3. an existing node's **body**, when that node already owns the file.

A red that leaves a collect with none of the three is an orphan, and an orphan
is the one outcome this memo forbids.

## Why

Measured on this board: `tests/nvim-statusline.sh`'s PROBE C diff pair has been
red for at least three sessions. Two workers reported it correctly and neither
report went anywhere. `lsp-gate-parser-seed`'s analyst said "not mine" and
stopped — a complete report under the rules as written.
`done-nodes-without-proof` counts nodes with **no** proof, and this node had a
proof that ran, so its selector never saw it. The third session finally
measured the cause: lualine spawns
`git -C sub --no-pager diff --no-color --no-ext-diff -U0 -- note.txt`
asynchronously from the `BufEnter` the probe fires, while the probe reads the
render after a fixed `vim.wait(500)` — red in **4/5** runs at load 6.26 and
**2/6** at load 2.94, so it is process-spawn latency rather than load average.

Three correct reports, no owner, still red. The gap is not diligence; it is
that the board's vocabulary has *record* and lacks *route*. The worker that
found it put it better than this memo can: a red belonging to no claimed node
has no owner by default.

Its recommendation was that the implementer file the node in the same breath.
That is rejected, but only in the last mile: the **attribution** genuinely
needs the session that just measured it — which is why the report must carry
the gate, the check text, and the runs — while the **filing** needs the ratio
only the orchestrator can see. Tonight is the case in point: the
**Derived work** tripwire is live at 28 derived in flight against 16 requested,
so this finding becomes a memo rather than a 29th derived PRD, and it would
have been wrong for a worker to decide that.

## The open red, so it can be picked up cold

- **Gate**: `tests/nvim-statusline.sh`, PROBE C.
- **Checks**: `render: a lualine_b_diff_added_ group carries +1`, and the
  companion asserting the count it shows.
- **Cause**: async `git diff` spawn versus a fixed `vim.wait(500)`.
- **Not the cause**: load average, and `gitsigns` — which never loads, because
  `noautocmd edit` skips `BufReadPre`.
- **Shape of the fix**: `07-formatting`'s, not a widened settle window — a
  bounded retry on one declared signal, the load printed when it fires, and one
  probe with retry disabled so the assertion can still go red.
- **Owner when the tripwire clears**: `03-editor/13-statusline` owns that gate.

## Queue entry 2 — Ctrl-T poisons the quicklist log

Routed here 2026-08-24 from `06-help/03-browser`'s analyst, under the same rule
and the same live tripwire.

`tv_finder` calls `finder` with **no `--start`**, so it cannot know which
channel the user picked. A channel whose rows are TAB-delimited therefore has
its raw row shell-quoted into the prompt, and `finder`'s `_recents_add` stores
that tab-bearing row as a quicklist `value` — after which `_recents_entry`'s
four-field split reads the wrong columns.

**This is reachable today**, not hypothetically: `04-shell/07-quicklist`
shipped the `quicklist` channel tonight, and Ctrl-T can pick it. The `manual`
channel would be a second instance of the same class.

It is filed here rather than as a PRD only because the tripwire is live — 28
derived in flight against 16 requested. Unlike queue entry 1, **this one
changes what ships**: a poisoned recents row is user-visible, so when the
tripwire clears it should be filed as a node against `04-shell/07-quicklist`
and not left as a memo. The fix needs a channel seam in `tv_finder` — the
missing `--start` is the whole defect.

Two smaller things from the same report, worth having written down where the
next reader of `finder.nu` will find them:

- **`_finder_parse` silently misreads any `--expect` key outside its six.**
  The else-branch returns `{key: "enter", entries: $lines}` with the
  pressed-key line as the first *row*. `06-help/03-browser` adds `ctrl-o`; the
  trap remains for the seventh key, and no gate pins the list.
- **`tests/shell-help.sh:275`'s `no_spawn_ok` is spelling-based**
  (`\^(nvim|wezterm|git|tv)`), so a bare `tv` or a `^chezmoi` slips it. Its
  label claims "help.nu spawns nothing" and could go false without going red.
  `06-help/03-browser`'s spec01 re-scopes it rather than exploiting it.

## Queue entry 3 — the gates/lib.sh scratch leak, now measured

Routed here 2026-08-24 from `gates-lib-anchored-lookup`'s analyst. Two earlier
lanes reported this as "known, out of scope"; it now has a mechanism and a
count, which is what it needed to become filable.

**The count:** `${TMPDIR}` holds **32 orphaned `gates.XXXXXX` directories**,
oldest 2026-08-21 — including `gates.oVw7Gl`, the one named in
[`a-counterfactual-proves-its-own-mutation`](a-counterfactual-proves-its-own-mutation.md).
Sixteen are selftest-shaped (a lone `keep/` subtree); four are nvim-gate
scratches at 39k–50k entries each.

**Why it is silent:** every leftover is an **empty directory skeleton** with
normal `drwxr-xr-x` modes — the files were removed and `rmdir` refused — so
permissions are not the cause; a concurrent writer or an interrupted `rm` is.
The silence itself is `gates/lib.sh:359`, `trap 'rm -rf "$GATES_TMP"' EXIT`,
whose status is discarded: measured directly, a bash script whose EXIT trap
runs a failing `rmdir` prints to stderr and **still exits 0**. That is the
entire "fails silently at rc 0" shape.

**It did not reproduce in either of two clean runs** (`selftest --selftest`, rc
0, 23 PASS / 0 FAIL, empty stderr, 6m24s, load 3.3), which is consistent with a
race and is why it survived three sessions of reporting.

The analyst deliberately did **not** fold it into its own spec, and was right:
it is a second contract on the same file, and the honest order is *make the
cleanup loud first, then attribute the ENOTEMPTY from the loud output* — not
explain the race first. It belongs to a node against `gates/lib.sh`, sequenced
after `gates-lib-anchored-lookup` because the footprints collide. Filed here
only because the tripwire is live.

## Alternatives considered

**Let workers file their own findings** — the recommendation this memo is
answering. Rejected because one PRD becomes three: a worker cannot see that
derived work already outnumbers requested work, and tonight it does, 28 to 16.

**An automatic rule keyed on gate output** — parse the reds, open a node per
red. Rejected on the worker's own argument, which is better than the idea: the
attribution *is* the work. A node saying "PROBE C is red" without the async
spawn measurement is a ticket for re-doing the measurement.

**Leave it as it was** — three sessions of evidence that this loses real
defects. The flake above is cheap; the next orphan may not be.

## Consequences

- Collect gets longer. Every reported red now costs a routing decision and one
  line of the round saying where it went.
- Memos become a queue as well as a record. This one is a **queue entry**: when
  the tripwire clears, the red above becomes a node against
  `03-editor/13-statusline`, and this memo is where its measurement is waiting.
- The worker rule is unchanged and should stay that way: report, do not fix, do
  not file. What changed is that the orchestrator can no longer let a report
  end at "reported".
