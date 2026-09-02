---
state: done
priority: 50
est: 1h
task: W0.3
mode: afk
needs:
verify: ""
origin: derived
from: 00-delivery/corrections
---

# Finish the 05-platform provisioning rewrite

Purpose: The epic and its three children were rewritten, but the rewrite left
residues that the repo's own conventions require. This closes them.

## Requirements
- [x] **R1** — `.mi/SYSTEM.md`'s epic table still reads `05-platform | macOS
      dependency bootstrap | 1`. The epic now has three children and a
      different subject; update the row.
      - Met by the tree as it stands; nothing was rewritten to meet it.
        `grep -n "05-platform" .mi/SYSTEM.md` returns exactly one hit, line 66:
        a row whose first cell links `05-platform` to
        `.mi/prds/05-platform/prd.md`, whose subject cell reads "chezmoi
        provisioning: deploy, packages, shell-init" and whose count cell reads
        "3 (+4)". `grep -c "macOS dependency
        bootstrap" .mi/SYSTEM.md` returns 0. The count cell is corroborated
        rather than read off itself: `find .mi/prds/05-platform -name prd.md`
        returns 8 — the epic, 3 direct children (`01-deploy-mechanism`,
        `02-package-provisioning`, `03-shell-init-generation`) and 4
        grandchildren (`01/managed-config`, `01/repo-skeleton`,
        `02/homebrew-bootstrap`, `02/packages-installer`) — which is `3 (+4)`
        exactly. `CLAUDE.md` and `AGENTS.md` at the repo root are symlinks to
        `.mi/SYSTEM.md`, so there is one copy, not three. Counterfactual, run
        rather than asserted: with the stale row restored in a scratchpad copy
        the grep prints the old text verbatim and the link check goes red as
        well (`BROKEN SYSTEM.md:66 -> .mi/prds/05-platform/00-epic.md`), because
        the stale row points at a file the node conversion deleted.
      - Correction, recorded because the premise is false and would otherwise
        be re-checked forever: R1's premise was already false when it was
        authored. `git log --diff-filter=A` shows commit `8ecbbe4` ("board:
        land the flat-prose -> node conversion") both created this node file
        and rewrote line 66 to its current text, in the same commit. R1 was
        stillborn, not fixed by anyone.
## Acceptance
- [x] The `SYSTEM.md` epic table is correct.
      - Narrowed on 2026-08-21, when R2 and R3 were re-homed (see `## Re-homed
        requirements`). It read "the `SYSTEM.md` epic table, the README
        exclusion list and the inventory sort are all correct"; the two
        re-homed conjuncts left with their requirements, and their new owners
        carry them as boxes. The surviving conjunct is R1's, and holds on R1's
        evidence: `grep -n "05-platform" .mi/SYSTEM.md` returns one hit,
        line 66, subject "chezmoi provisioning: deploy, packages, shell-init",
        count `3 (+4)`; `grep -c "macOS dependency bootstrap"` returns 0; and
        `find .mi/prds/05-platform -name prd.md` returns 8, corroborating the
        count cell independently rather than reading it off itself.
- [~] The Wave 0 tree link check passes.
      - STUB: **the Wave 0 tree link check does not exist**.
        `.mi/prds/00-delivery/verification-gates/prd.md` is `state: open` with
        every box `[ ]`, and the repo has no runner (no `justfile`, `Makefile`
        or `package.json`; `tests/` holds only `help-content-model.nu` and
        `live-bugs.sh`). Standing in for it: an uncommitted scratchpad link
        walker. It reports `checked 244 relative links in 78 files, 0 broken`
        over `.mi/prds` (exit 0) and `18 links, 0 broken` for `.mi/SYSTEM.md`
        resolved from the repo root (exit 0) — but the underlying fact being
        green is not the gate passing. See `## Findings` for why this box is
        `[~]` and not `[x]`.

## Out of scope
- Re-deriving the epic and its children. That work landed; only the residues
      are open.

## Re-homed requirements

R2 and R3 left this node on 2026-08-21 by user decision. Their numbers are
retired here and must not be reused; their full text and evidence moved with
them, under fresh numbers, to the nodes that already own the files:

| was | now | file it needed |
|---|---|---|
| R2 (README half) | `w0-4-s2-corrections/delivery` R7 | `.mi/prds/README.md` |
| R3 | `w0-4-s2-corrections/docs-inventories` R6 | `.mi/docs/capabilities-provisioning.md` |

R2's other half — "the 05-platform epic's Non-goals name the three
provisioning verdicts" — was **already met** and did not move:
`05-platform/prd.md`'s `## Out of scope` carries both the Windows entry and
the `wp-stat-overlay` / docs-site entry. Only the README half was open, and
only it was re-homed.

## Findings

### The escalation of 2026-08-21, and its resolution

Resolved by the user on 2026-08-21: re-home the two requirements downward, as
recorded above. The dependency direction is unchanged — `w0-4-s2-corrections`
and its children still `deps` on this node — and this node's footprint was not
widened. The escalation text is kept below as the record of what was found.


W0.3 cannot be closed inside the footprint it was dispatched with, and the fix
is a scheduling decision that is not a worker's to make.

**What was hit.** Of this node's three requirements, R1 is already met by the
tree as it stands (verified, see its box). The other two write files that are
NOT in W0.3's footprint and ARE in the declared footprint of two other tasks:

- R2's open half needs `.mi/prds/README.md`. `plan.json` assigns that file to
  **W0.4g** (`00-delivery/corrections/w0-4-s2-corrections/delivery`,
  `deps: [W0.3]`) and to W0.2.
- R3 needs `.mi/docs/capabilities-provisioning.md`. `plan.json` assigns that
  file to **W0.4a**
  (`00-delivery/corrections/w0-4-s2-corrections/docs-inventories`,
  `deps: [W0.3]`).

W0.3's own `files` list is exactly the four `.mi/prds/05-platform/**/prd.md`
files — none of which R2's open half or R3 touch. Both files are also on the
shared-file interdiction list (`.mi/prds/README.md`, `.mi/docs/`), which no lane
may edit. So every lane dispatched at this node hits the same block: R2 and R3
are unreachable, the node reopens with the same two boxes open, and it
re-dispatches forever. Narrowing W0.3's scope to dodge them is move 3, not
move 2.

Note the direction of the edge: W0.4a and W0.4g both `deps: [W0.3]`, i.e. they
are scheduled to run AFTER this node. So W0.3 is currently required to finish
work that its own downstream tasks own.

**What change is needed** — a conductor/user call between two options:

**(A) RECOMMENDED — move the two requirements downstream**, into the nodes
that already own the files, and close W0.3 on R1 plus the link-check
acceptance. Concretely: delete R2's README half and R3 from W0.3; add to
`00-delivery/corrections/w0-4-s2-corrections/docs-inventories` a box
"`capabilities-provisioning.md` is sorted best-ratio first" (that node already
exists to fix inventory hygiene, and the backlog's S3 section already tasks it
with the same violation in `capabilities-nvim.md` and `capabilities-nushell.md`
— the same class of defect, in a file it already owns); add to
`00-delivery/corrections/w0-4-s2-corrections/delivery` a box "the README
exclusion list carries the three provisioning verdicts". Replacement text for
both is below, so neither node has to re-derive it. This is the smaller change
and it needs no footprint edits in `plan.json`.

**(B) Widen W0.3's footprint** to include `.mi/prds/README.md` and
`.mi/docs/capabilities-provisioning.md`, and remove those two files from
W0.4g's and W0.4a's footprints so the one-writer-per-file rule still holds.
This inverts the current dependency direction and makes W0.3 a shared-file
writer, so it must then be serialised against W0.2 as well.

Neither file was edited and nothing was worked around.

**No split proposed.** R2b and R3 are not a coherent sub-area with its own
contract — they are two one-line fixes that two existing nodes already own the
files for. A new child would add a third writer to files that already have two.

### Replacement text, so the downstream node does not re-derive it

For the README's `## Excluded` section, in the file's existing house style,
each reason taken from the inventory entry rather than invented. Append to the
`DO NOT PORT` set a **`DO NOT PORT` — provisioning:** paragraph reading
"Windows config mirroring (`run_after_mirror-config-to-windows.sh`) — 42 lines
mirroring `~/.config` into a Windows-side location; the rebuild is macOS-only,
so it goes with the rest of the Windows surface." And extend the existing
`DEFER` paragraph with "wp-stat-overlay installer (project-specific, not
daily-driver base) · the published docs site (`docs/build.py`, orthogonal to
the daily driver and overlapping `06-help`, which should be built first and
then reconsidered as the source for any published page)."

The corrected inventory order for R3 is recorded with the requirement,
now `w0-4-s2-corrections/docs-inventories` R6.

### Recorded, not acted on

Each names a file this node may not write.

**Why the second acceptance box is `[~]` and not `[x]`.** The underlying fact
is true — the board's links resolve — but the check that proved it is a
load-bearing stub, and refutation found a class it is blind to. The stand-in
walker matched links with a per-line regex; this repo wraps markdown at ~78
columns, which manufactures links split across lines. Induced failure: in a
faithful copy of `.mi`, breaking the wrapped link at `.mi/prds/06-help/prd.md`
line 39 — the one whose text "tv needs a TTY" wraps mid-link across two lines
and whose target is the `04-shell/04-television` node — left the
per-line walker reporting `0 broken` and exiting 0, while a multi-line-aware
walker caught it and exited 1. It does bite for single-line breaks (breaking
`05-platform/prd.md:16` produced `BROKEN ... capabilities-provisioning-GONE.md`,
exit 1), so it is not a check that passes no matter what — but it has a
demonstrated silent-pass class on exactly the link shape this repo's wrap
convention produces. The multi-line-aware walker run at landing time reports
244 links across 78 files, 0 broken. The counts also drift between runs (241 →
243 → 244) as concurrent sessions add links, which is precisely what a
committed gate is for. Neither walker is committed; building one as `tests/…`
would be inventing part of `00-delivery/verification-gates`' own deliverable.

**`.mi/prds/05-platform/prd.md` has an `## Acceptance` heading with zero boxes
under it** — the heading is followed immediately by `## Out of scope`. Per §1
of `worker.md` a node owes `unchecked + stubbed`, so an epic with an empty
Acceptance owes nothing from it and can close vacuously on its children alone;
`SYSTEM.md`'s own rule is that prose acceptance "is invisible to the scheduler
and closes unmet", and an empty Acceptance is the limiting case. This is
squarely "a residue the rewrite left that the repo's own conventions require",
which is this node's stated purpose, so it belongs here as a new requirement
rather than in a new node — but adding a requirement to one's own node is not
move 2, so it is recorded for the fold-in instead. It needs one box; the
epic's invariants I1–I4 already say what it would assert (one `chezmoi apply`
from clone yields a working machine, and a second apply is a no-op).

**The Wave 0 gate's link clause is scope-sensitive and nobody has decided its
scope.** The check is green over `.mi/prds` (244 links, 0 broken) and over
`.mi/SYSTEM.md` (18, 0). It is NOT green over `.mi/` as a whole:
`.mi/workflows/refs/worker.md` and `.mi/workflows/refs/memo.md` carry 11 broken
relative links — `../../../src/plugins/board/plugin.lua`,
`../../docs/memos/{prd,discipline,memo-format,README}.md`,
`../../docs/{RUST-CORE,SURFACES,LUA-PLUGINS}.md` — none of which exist in this
repo. These are not rot in this tree; they are the mi framework's own reference
docs pointing back at the Rust/Lua repo they were written for, and
`worker.md`'s shelf table sends a worker to several of them before any
non-trivial change, so a worker following the protocol as written is sent to
files that are not there. `.mi/workflows/` is shared and belongs to no lane, so
this is a report, not an edit — but whoever builds the Wave 0 gate in
`00-delivery/verification-gates` has to decide deliberately whether "tree link
check" means the board or the whole `.mi/` directory, because the answer flips
the gate red on day one.

## Notes

 This node was almost recorded as done on the strength of the `[x] fixed` mark
      on the Provisioning bullet in the backlog's coverage-gaps section. That
      mark is defined at the top of that file as "already fixed in this pass"
      — the author's own note, not an executed check — and
      `03-verification-gates` req 1 says reading criteria is not executing
      them. The three requirements above are what an actual check found still
      open.

 The reconciliation pass vindicated that note twice over: the note was right
      to distrust the `[x] fixed` mark, and the note itself was only two-thirds
      right — R1, which it lists as open, is in fact already met, and R2 is
      half met. Both errors are the same error in opposite directions, reading
      a document instead of running a check, which is `03-verification-gates`
      R1 landing on the reconciler as well as on the author.

## Closing note

*Closed 2026-08-21 by the orchestrator.* Both spec verify commands were run by
the implementer and re-run independently by the orchestrator: `OK`, exit 0 for
each. Restored attributions carry per-source C/U numbers and the inventory
link resolves.

One box in each spec is left `- [ ]` and was **not** ticked: the
`git status --porcelain` check asserting the out-of-footprint epics are clean.
It cannot pass right now for a reason outside this ticket — the whole
`.mi/prds` tree is mid-migration (renamed from `.mi/prd`, tree-wide frontmatter
normalisation) and uncommitted. Footprint containment was instead proved by a
stronger check: the implementer reverse-applied its exact edit strings to
reconstruct the pre-edit files and compared frontmatter blocks byte-for-byte,
all four identical. Re-run those two boxes once the migration is committed.

The second acceptance box above stays `[~]`: it stands in for the Wave 0 tree
link check, a gate owned by [`verification-gates`](../../verification-gates/prd.md)
(G.1). Building it here would invert the G.1 → P.1 → W0.3 edge.
