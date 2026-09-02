---
state: done
priority: 46
est: 1.75h
task: W0.6
mode: afk
needs:
verify: ""
origin: derived
from: 00-delivery/corrections
---

# Record the live-config bugs so the rebuild fixes them

Purpose: Twelve bugs found in the live configuration. Recording them is half
the job; the other half is making sure each one reaches the node that must not
reproduce it.

## Requirements
- [x] **R1** — The `L-1`..`L-12` table exists in the backlog and is populated.
      Checked via `grep -cE '^\| *L-[0-9]+' .mi/prds/00-delivery/corrections/prd.md`,
      which returns 12 (all rows L-1 through L-12 present with non-empty
      Finding text); had the table been incomplete this would have returned
      fewer than 12. Also pinned as the first assertion in
      `tests/live-bugs.sh`. **Caveat on the check**, recorded because the box
      stands on a reading and not on the grep: the count is hard-coded at 12
      and matches row *shape*, not row identity or cell contents — emptying a
      Finding cell or renumbering a row still returns 12, and promoting L-13
      into the table would make the assertion report STALE for a correct
      change. Strengthen it to a per-id grep with a non-empty-cell assertion
      when the table is next touched.
- [ ] **R2** — Each bug is either fixed in the PRD that owns it, or recorded
      as accepted-with-reason. L-3 (`rcwd` is really `recent-dirs`, wrong in
      three PRDs and an inventory), L-4 (finder picks are never logged, so
      `04-shell/07`'s premise is wrong) and L-5 (`leadermode.nu` is dead code)
      are still unfixed in the tree. Advanced, not met: L-5 is now recorded
      accepted-with-reason in `.mi/docs/capabilities-nushell.md` (dead code,
      `DO NOT PORT`, on the stronger ground that there is nothing to port).
      L-3 and L-4 still stand unfixed in `04-shell/04-television`,
      `04-shell/01-core-config` and `04-shell/07-quicklist`; those fixes are
      owned by `w0-4-s2-corrections/shell` R1/R2, which this node may not
      edit.
      *(b) — the routing arm closed and the fixes landed, but one row is
      still genuinely unmet: L-9's `03-editor/14-shift-select` half is
      undischarged. L-3/L-4 are "**Fixed 2026-08-21**" in the backlog
      (`w0-4-s2-corrections/shell` R1/R2), L-5 recorded accepted-with-reason,
      and L-11's bell fix is specced in `w0-2-terminal-respec` R5 — but the
      L-9 row itself reads "**Half open.** `03-editor/02-keymaps` carries the
      decision (`w0-4-s2-corrections/editor` R7), but that lane's own closing
      note records R7's `03-editor/14-shift-select` half as **undischarged**,
      so this row is not marked fixed." The decision is recorded in one of the
      two nodes it names; the other never got its one-bullet follow-up.*
- [~] **R3** — L-6 and L-9 are questions, not records: L-6 asks which of two
      inert settings to port, L-9 asks whether shadowing blockwise-visual
      `<C-v>` is intentional. Both say "record it either way"; neither has
      been recorded. **Stub: the inventory entry stands in for the backlog
      row and for the owning editor PRDs.** Both decisions are now recorded
      in `.mi/docs/capabilities-nvim.md` with reason and rejected
      alternative (see `## Decisions`), but backlog rows L-6 and L-9 are
      byte-unchanged and still read as questions, and neither
      `03-editor/02-keymaps` nor `03-editor/14-shift-select` — the nodes that
      must implement them, and the one CLAUDE.md names for the shift-select
      fork — has been touched. Refutation in full under `## Findings`.
- [x] **R4** — Each bug names the node that must not reproduce it, so the fix
      is reachable from the implementing task. L-1 belongs to
      `04-shell/06-listing`, L-11 to `02-terminal/03-f5-jump-mode`. Not met:
      the backlog table has columns `# | Finding` and no owner column, and
      adding one is a write to another node's file. The full owner mapping
      for all 13 rows is under `## Findings`.
      *(a) — the routing arm is closed and machine-checked. The "Placed
      elsewhere" section (2026-08-21) names an owner for every row, the
      backlog's second column now carries the owner, and the Closing note
      records "every S2 row names an owner, and the gate resolves every owner
      node path and requirement reference".)*
- [x] **R5** — The six bugs that no board node names — L-2, L-5, L-7, L-9,
      L-11, L-12 — each carry a do-not-reproduce record in the inventory
      entry for the capability they belong to, so they are reachable from the
      document an implementer reads even before the board names an owner.
      Checked by `bash tests/live-bugs.sh` (exit 0, 46 assertions, run on
      main at merge); the set of six is checked by
      `grep -rhoE 'L-[0-9]+' .mi/prds/00-delivery/corrections/w0-4-s2-corrections/*/prd.md`,
      which returns only L-1, L-3, L-4, L-6, L-8, L-10. Had a record been
      absent or the live config drifted under it, the matching line prints
      FAIL and the script exits 1 — demonstrated by breaking the L-6 record.
      This is reachability through the docs, not through the board; R4
      remains open.

## Acceptance
- [x] No `L-*` row is left as an open question. Answered but not transcribed:
      L-6 and L-9 have decisions (`## Decisions`), the rows still say
      "Intentional?" and "Port one or the other, not both."
      *(a) — both rows are transcribed. L-6 reads "**Decided 2026-08-21
      (afk):** keep `opt.hlsearch = false` … **Fixed 2026-08-21**"; L-9 reads
      "**Decided 2026-08-21 (afk): intentional — port as-is and leave
      `<C-q>` unbound.**" Neither row still reads as a question. The L-9
      decision's *second half* is undischarged — that is Acceptance 2's
      finding, not this box's.*
- [ ] Every `L-*` row names the node that owns its fix, and that node's PRD
      reflects it. Neither half holds: no row names a node, and none of
      `04-shell/04-television`, `04-shell/07-quicklist`,
      `03-editor/02-keymaps`, `03-editor/01-options`,
      `03-editor/06-explorer`, `02-terminal/03-f5-jump-mode` or
      `05-platform/01-deploy-mechanism/managed-config` has been corrected.
      *(b) — the first half now holds (every row names an owner, and the
      owning nodes carry the fixes), but the second half fails on exactly one
      row: L-9's `03-editor/14-shift-select` half is undischarged — that
      node's PRD does not reflect the "leave `<C-q>` unbound" decision, and
      the backlog row itself says so ("**Half open.**"). The one-bullet
      follow-up `w0-4-s2-corrections/editor` R7 declared residual never
      landed.*

## Out of scope
- Implementing the fixes. This node routes them; the S, E and T nodes apply
      them.

## Assumptions
- L-6 and L-9 were answered in the principal's absence (worker.md Appendix C
  — `mode: afk`, no user in the loop). Both are taste calls on a live
  editor's feel; a reversal on either is the human's to make, and reversing
  costs only the two inventory records plus the port requirement each names.

## Decisions
- **L-6 — keep `hlsearch = false`, drop the inert `<Esc>` → `nohlsearch`
  map.** Measured: `map("n", "<Esc>", "<cmd>nohlsearch<CR>")` coexists with
  `opt.hlsearch = false`, so the map can never have anything to clear.
  Rejected: the LazyVim pairing (turn `hlsearch` on and keep the map),
  because it changes the feel of every search to give one dead line a job,
  and 06-help's drift check would then have to document a binding that never
  fires. Recorded with its reasoning in `.mi/docs/capabilities-nvim.md`.
- **L-9 — the visual-mode `<C-v>` shadow is intentional; port as-is, and
  leave `<C-q>` unbound.** It is half of the `<C-c>`/`<C-v>` pair that is the
  entire point of shift-select. The map is `v`-mode only, so normal-mode
  `<C-v>` still enters blockwise, `virtualedit=block` still applies, and the
  unbound built-in `<C-q>` still covers the one case lost (promoting an
  existing selection to blockwise). Rejected: moving paste to another key,
  which breaks the pair for a mode that keeps a working alternative.
  Verified against the real dependency at land time — headless nvim 0.12.4
  reports `hlsearch=false`, `incsearch=true`, `virtualedit=block`, `<C-v>`
  bound in `v`/`x` only, `<C-c>` → `y` in `v`/`x`, and `<C-q>` unbound in
  `n`/`v`/`x`. Port requirement: leave `<C-q>` unbound and document it.

## Findings

### Two audit findings were wrong and are corrected in the inventories
- **L-12 is half stale.** `solo-window.{applescript,sh,ps1,vbs}` are shipped,
  but "zero references in the live config" holds only for the *deployed*
  `wezterm.lua`; the chezmoi *source* `wezterm.lua` defines `solo_window()`
  and calls it from two places. `wsl-clip-prime.sh` and the wezterm
  `background.png` are not in the source tree at all.
- **L-5's reasoning is wrong although its verdict is right.** "calls
  `finder --resume`/`--fresh`, flags that do not exist" is true only of the
  deployed 221-line `finder.nu`. Those flags exist in the 345-line
  chezmoi-source `finder.nu`, a different stack-and-resume design.
  `leadermode.nu` is a leftover from that design and never entered the
  source. `DO NOT PORT` stands, on the stronger ground.
- Both corrections share one root, escalated below and recorded as **L-13**
  in `.mi/docs/capabilities-provisioning.md`.

### The routing table (R4's content, for the writer who owns the backlog)
`✓routed` = a node already carries it; **PLACE** = no node does.

| # | Owner node | Status |
|---|---|---|
| L-1 | `04-shell/06-listing` | ✓routed (w0-4/shell R3) |
| L-2 | `04-shell/04-television` | **PLACE** — new R on `w0-4-s2-corrections/shell` |
| L-3 | `04-shell/04-television`, `04-shell/01-core-config` | ✓routed (w0-4/shell R1); inventory face fixed |
| L-4 | `04-shell/07-quicklist` | ✓routed (w0-4/shell R2); inventory face fixed |
| L-5 | no feature node — `DO NOT PORT` | accepted-with-reason, in the inventory |
| L-6 | `03-editor/01-options` + `03-editor/02-keymaps` | ✓routed (w0-4/editor R3); answer in `## Decisions` |
| L-7 | `03-editor/06-explorer` | **PLACE** — new R on `w0-4-s2-corrections/editor` |
| L-8 | `03-editor/03-autocmds`, `10-treesitter`, `14-shift-select` | ✓routed (w0-4/editor R1) |
| L-9 | `03-editor/02-keymaps` + `03-editor/14-shift-select` | **PLACE** — new R on `w0-4-s2-corrections/editor`; answer in `## Decisions` |
| L-10 | `03-editor/12-small-plugins` | ✓routed (w0-4/editor R2) |
| L-11 | `02-terminal/03-f5-jump-mode` | **PLACE** on `w0-2-terminal-respec`; inventory face fixed |
| L-12 | `05-platform/01-deploy-mechanism/managed-config` | **PLACE** — new R on `w0-4-s2-corrections/platform`, with the correction above |
| L-13 | new — open decision 4 | see `## Escalation` |

Four requirement lines other nodes' owners must place (escalations, not
edits — this node did not write them):
- `w0-4-s2-corrections/shell` — **L-2**: the `Commits` decoder reads field
  index 1 of a line the channel has already reduced to a bare hash, and the
  `^[0-9a-f]{7,}$` guard then drops every row, so commit→`git show` has never
  run. Read the field the channel emits.
- `w0-4-s2-corrections/editor` — **L-7**: oil is lazy on `keys`, so
  `default_file_explorer` is not installed until `<leader>e`; with netrw
  disabled, `:e some/dir` opens neither. `03-editor/06-explorer`'s third
  acceptance line asserts the behavior the bug prevents.
- `w0-4-s2-corrections/editor` — **L-9**: record the decision above in
  `03-editor/02-keymaps` and `03-editor/14-shift-select`, including "leave
  `<C-q>` unbound".
- `w0-4-s2-corrections/platform` — **L-12**: as corrected above.

### Why R3 is `[~]` and not `[x]`
The adversary refuted the closing claim and the demotion is the record. The
decisions are real and were verified against a headless nvim, but the landed
commit touches no file under `.mi/prds`: backlog rows L-6 and L-9 are
byte-unchanged and still read "Port one or the other, not both." and
"Intentional? Record it either way." — the exact text R3 names as the
defect — and neither owning editor PRD was touched, so the decision is not
reachable from the node that must implement it, which is what R4 exists to
prevent. The two gate lines are near-circular: `grep -q 'Live bug L-6,
resolved'` matches a phrase the author wrote and would pass on a record
reading "resolved — TBD". `~` records that a genuine decision exists with the
inventory standing in for the board row.

### A new file outside this node's granted footprint
`tests/live-bugs.sh` is new. It sits in `tests/` beside
`help-content-model.nu` because CLAUDE.md's tests law puts a check in a
`tests/` folder named for what it covers, and a checker beside its subject in
`.mi/docs` would have been a second dialect. New file, no existing file
touched. The records it guards stand without it.

Note for whoever lands `w0-4-s2-corrections/docs-inventories`: it owns
`.mi/docs/capabilities-*.md` for its R3 sort-order and R5 burrito-strip work.
Three of those files were edited here, on different lines, with no overlap
with its requirements — it will rebase onto this.

## Placed elsewhere

The four requirement lines this node identified but may not write were placed
by the conductor on 2026-08-21, so each bug is now reachable from the node
that must not reproduce it:

| bug | now owned by |
|---|---|
| L-2 — the `git-log` → `Commits` decoder reads the wrong field | `w0-4-s2-corrections/shell` R7 |
| L-7 — oil is lazy on `keys`, so `:e some/dir` opens neither | `w0-4-s2-corrections/editor` R6 |
| L-9 — visual `<C-v>` shadows blockwise-visual | `w0-4-s2-corrections/editor` R7 |
| L-12 — dead files in the abandoned chezmoi source | `w0-4-s2-corrections/platform` R4 |

L-3 and L-4 needed no placement: `w0-4-s2-corrections/shell` R1 and R2 already
carry them. L-6 is carried by `w0-4-s2-corrections/editor` R3.

## Resolved escalation (2026-08-20)

Answered by the user on 2026-08-21 — the deployed `~/.config` tree is
canonical. Recorded as decision 4 in the parent backlog, and again under
`### Resolved 2026-08-21` at the end of this section. The text below is kept
as the record of what was found and why it was raised.

**The phrase every inventory in this repo is founded on does not name one
artifact, and choosing which it names is not an agent's call.**

Checking L-12's claim that `solo-window.*` has "zero references in the live
config" surfaced that the chezmoi source's `wezterm.lua` defines
`solo_window()` and calls it twice, while the deployed
`~/.config/wezterm/wezterm.lua` never mentions it. The two files are
different programs. Measured 2026-08-20, source
(`~/.local/share/chezmoi/home/dot_config/`) vs deployed (`~/.config/`), in
lines:

| file | source | deployed | |
|---|---|---|---|
| `wezterm/wezterm.lua` | 339 | 1149 | deployed is ~810 lines ahead |
| `nushell/config.nu` | 380 | 715 | deployed is ahead |
| `nushell/finder.nu` | 345 | 221 | **source** is ahead, and is a different (stack-and-resume) design, not an older copy |
| `television/config.toml` | 16 | 15 | |
| `nvim/lua/config/keymaps.lua` | — | — | identical |
| `dirstack.nu`, `quicklist.nu`, `overlay.nu`, `opacity.nu`, `leadermode.nu` | absent | present | never entered the source at all |

The drift runs in both directions, so `chezmoi apply` from the current source
would destroy the configuration that `capabilities-nushell.md`,
`capabilities-nvim.md` and `capabilities-terminal.md` were all written from.

Every one of those inventories opens with "Source of truth: the live config
in `~/.config/...` (chezmoi-managed)". That is two claims and the second is
false. CLAUDE.md's standing instruction — "Verify against the live config,
always", the instruction the four-agent audit was run to enforce — silently
assumes the two are one thing. They are not, so "the live config" currently
resolves to whichever tree the reading agent happened to open. Same class of
failure as the one that invalidated `02-terminal`: a spec written from the
wrong artifact, correct-looking the whole time it was wrong.

**The change needed** is a fourth entry in the backlog's "S1 — open decisions
for the human", and it is a scope fork an agent must not resolve alone:

> **4. Deployed or source — which artifact do the inventories rate, and what
> happens to the delta?**
> (a) Is the deployed `~/.config` canonical, making the chezmoi source
> abandoned and `05-platform` a from-scratch deploy mechanism rather than a
> port of a working one?
> (b) The 345-line source `finder.nu` — a newer unfinished pipeline design
> worth porting, or an abandoned branch? `04-shell/04` is specced from the
> 221-line deployed one and does not know the other exists. `leadermode.nu`
> (L-5) is a leftover from the source design, which is why its
> `--resume`/`--fresh` calls look like calls to flags that never existed.
> (c) Does the ~810-line wezterm delta get pushed back into a source tree, or
> does the rebuild take the deployed file as its input? `w0-2-terminal-respec`
> depends on this node and would otherwise re-spec from a file whose
> relationship to the deploy layer is undefined.

Not decided here because it is scope (the human's), and because it is not
expressible as an amendment to this node — it changes the parent backlog's
contract and the header of four inventories, which is an escalation and not
an edit. The measurement is recorded as L-13 in
`.mi/docs/capabilities-provisioning.md` and pinned in `tests/live-bugs.sh`,
so the finding survives regardless. This node's scope was **not** narrowed
around it.

Sequencing: `w0-2-terminal-respec` lists this node in its `deps`, so this
escalation blocks the terminal re-spec. That is the correct outcome, not a
side effect — (c) is an input the re-spec needs.

### Resolved 2026-08-21 — decision 4 answered by the user

**The deployed `~/.config` tree is canonical.** The chezmoi source is
abandoned; the inventories rate the deployed artifact; `w0-2-terminal-respec`
specs from the deployed 1149-line `wezterm.lua`; the 345-line source
`finder.nu` is not ported. Recorded in full as entry 4 of the parent
backlog's "S1 — open decisions for the human", which is where the escalation
asked for it.

This clears the blocking question. It does **not** close R2 or R3 — those
remain open on their own merits, and their fixes are owned by
`w0-4-s2-corrections/*`, which this node may not edit. The escalation text
above is kept as the record of what was found and why it was escalated.

## Notes

R1 is the one box in this conversion that opened `[x]`: the check is
`grep -cE '^\| *L-[0-9]+'` on the backlog, which returns 12, and it would
have returned a smaller number had the table been incomplete. Everything else
opened `[ ]`, because the backlog's own acceptance requires each bug be fixed
or accepted-with-reason and no rebuild exists yet.

## Closing note

*Closed 2026-08-21 by the orchestrator.* `bash tests/live-bugs.sh` re-run
independently: `PASS=146 FAIL=0 SKIP=0`, exit 0 — up from 46 assertions. The
numbered open-decisions region of the backlog was confirmed untouched (zero
`+`/`-` diff lines in it). All 24 spec boxes ticked.

**R2 stays open, by design, and this is not an oversight.** Its routing arm is
now closed and machine-checked — every S2 row names an owner, and the gate
resolves every owner node path and requirement reference. But R2's literal
wording ("fixed in the PRD that owns it") depends on the `w0-4-s2-corrections/*`
children and `w0-2-terminal-respec` landing, and this node may not edit them.
R2 closes when they do.

One recorded deviation: spec02's box 5 named a pattern (`|Decide`) that its own
mandated row text (`Decided 2026-08-21`) matches, so the check could never pass
as written. spec03 §4 supersedes it; the reasoning is written into the box.

L-11 has no requirement anywhere on the tree — its owner is
[`02-terminal/03-f5-jump-mode`](../../../02-terminal/03-f5-jump-mode/prd.md)
via [`w0-2-terminal-respec`](../w0-2-terminal-respec/prd.md), which is still
open. The Owner column is the routing mechanism that keeps it from being lost.

## Superseded guard

*Recorded 2026-08-21 by the orchestrator, after this ticket closed.*

Two classes of assertion in `tests/live-bugs.sh` were written against
`~/.local/share/chezmoi` — since identified as a **two-months-stale June
clone** whose HEAD `a2544e4` is a git *ancestor* of the live chezmoi source at
`/Users/feb/dev/.files` (`chezmoi source-path`). Not a divergent tree: the same
repo, behind.

- The **doc greps** (`Live bug L-12, corrected`, `New finding (L-13)`) went
  stale when [`provisioning-rerate`](../w0-4-s2-corrections/provisioning-rerate/prd.md)
  corrected the record on the user's decision.
- Worse, **seven of the eleven L-12/L-13 live assertions were green and
  wrong** — they asserted the opposite of what the record says and passed only
  because they read the clone. Measured: `solo-window.sh` is absent from the
  real source (present in the clone), the source `wezterm.lua` has **0**
  references to it (the clone has 3), source vs deployed `wezterm.lua` is
  `1149 vs 1149` and `finder.nu` `221 vs 221` — byte-identical, not "far
  shorter"/"longer" — and `dirstack.nu`, `quicklist.nu`, `overlay.nu`,
  `opacity.nu` **are** in the real source.

Both halves are **repointed, not abandoned**, by
[`gate-reconciliation`](../gate-reconciliation/prd.md) (W0.8): greps at the
corrected wording, live checks at the real source, each proved red against the
pre-correction record, and `SRC` now guarded against `chezmoi source-path` so it
cannot drift back. The backlog-table and Owner-cell machinery — 40 `table:` and
50 `routing:` assertions — is byte-unchanged and asserted so. The file went from
146 assertions to 159.

This is the same wrong-baseline class as `docs-inventories` R7 and
`backlog-closeout` R9. It is worth stating plainly: **the stale-clone error had
colonised one of the gates built to catch that class of error**, and it passed
green all session while lanes took that green as evidence.
