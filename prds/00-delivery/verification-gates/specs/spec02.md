# spec02 — Wave 0: the tree link check

Goal: build the check that
[`w0-3-platform-rewrite`](../../corrections/w0-3-platform-rewrite/prd.md)'s
second acceptance box has been standing in for since it landed. That box is
`[~]` with the note "the Wave 0 tree link check does not exist"; building it
here rather than there was deliberate, because building it there would invert
the G.1 → P.1 → W0.3 edge. This spec closes the stub's *cause*. (The box
itself is W0.3's to re-tick; this node must not edit that file.)

## Files touched
- `gates/tree-links.sh` — new.

## The scoping question, answered

This node's PRD says the scope of "tree link check" is a question this node
must settle deliberately, because the answer flips the gate red on day one.
Answering it, with the measurements taken during analysis:

**The premise moved.** W0.3 recorded 11 broken links in
`.mi/workflows/refs/worker.md` and `memo.md` pointing back into the mi
framework's own Rust/Lua repo. **`.mi/workflows/` no longer exists** — it is
staged as deleted in the working tree, alongside a new `.mi/skills/mi/`. So
the specific reason to keep the scope narrow has dissolved. Three of its
casualties remain, as inbound links: `06-help/01-content-model/prd.md` still
points at `.mi/workflows/refs/{laws,worker}.md` three times.

**Two tiers, one exit code.**

*Tier A — gating.* Every `prd.md` and `README.md` under `.mi/prds/`, plus
`.mi/docs/capabilities*.md`, plus `.mi/SYSTEM.md`. Measured now: **474 links
across 87 files, 6 broken.**

*Tier B — reported, never gating.* `specs/**` under any node, `.mi/gantt/*.md`,
`.mi/gantt/repair-*/**`, `.mi/docs/delivery-gantt.md`. Printed under a
`TIER B (not gating)` heading with a one-line count so nothing is invisible.
Measured now: **~123 more broken**, dominated by analyst spec notes that copied
a relative path from a `prd.md` one directory up, and by generated files
(`delivery-gantt.md` 6, `plan.md` 2) still carrying pre-rename `../prd/`
paths. Rationale, and write it into the script header: a generated file's
broken link is the generator's bug and no lane may hand-edit it; `specs/**` are
working notes with a lifetime of one ticket. Neither is the tree's link health.

*Excluded outright.* `.mi/gantt/scratch/` — planning runs write into it and it
is git-ignored (`.gitignore` line: `.mi/gantt/scratch/`).

**`.mi/SYSTEM.md` resolves from the repo root, not from `.mi/`.** It is
symlinked as `./CLAUDE.md` and `./AGENTS.md`, and its relative links are
written for that vantage point. Resolved from `.mi/` it shows 19 false
breakages; resolved from the repo root, 0. Getting this wrong is the
difference between a green gate and a gate nobody trusts.

## The walker

- Strip fenced code blocks (``` and ~~~) before matching, replacing each with
  its own newline count so reported line numbers stay true.
- Match links over the **whole file text, not per line**. The regex must
  tolerate a newline inside the `[...]` text part. This is the silent-pass
  class W0.3 demonstrated: `.mi/prds/06-help/prd.md` line 39 wraps "tv needs a
  TTY" mid-link, and a per-line walker reported `0 broken` while the target
  was gone.
- Skip absolute URLs (`scheme:`), protocol-relative (`//`) and pure anchors
  (`#…`). Split `#anchor` off a path before resolving; do not validate
  anchors (out of scope, say so in the header).
- Resolve with `normpath` against the file's own directory — except
  `.mi/SYSTEM.md`, which resolves against the repo root.
- Report `BROKEN <file>:<line> -> <target> (<resolved>)`, then a summary line
  `checked N links in M files, K broken`.

Implementation language: `python3` (installed), invoked from a thin bash
wrapper so the interface matches the rest of the suite. `bash` alone cannot do
multi-line-aware matching without pain, and pain is how the first walker got
it wrong.

## Landing red is the correct outcome

Tier A is red by 6 today. Each is owned by another node and **must not be
fixed here**:

| broken link | owner |
|---|---|
| `.mi/docs/capabilities-terminal.md:31 -> ../prd/…` | W0.1 / `w0-4-s2-corrections/docs-inventories` |
| `…/provisioning-rerate/prd.md:55,56 -> ../../decisions/…` | `w0-4-s2-corrections/provisioning-rerate` (W0.4i, being analysed now) |
| `06-help/01-content-model/prd.md:155,709,785 -> ../../../workflows/refs/…` | `06-help/01-content-model` (state `done`; needs reopening or a correction row) |

Record all six in `## Findings` of this node's `prd.md` with their owners, so
the red is a routed defect rather than an unexplained failure. The count is a
moving target — `provisioning-rerate` is mid-analysis and the `.mi/prd` →
`.mi/prds` rename is uncommitted — so assert *the mechanism*, never the number.

## Acceptance
- [x] `bash gates/tree-links.sh` prints a Tier A summary and a Tier B
      summary, and exits non-zero iff Tier A has a broken link. Today:
      Tier A `checked 505 links in 88 files, 4 broken`, exit 1; Tier B
      `checked 191 links in 76 files, 95 broken`, never gating.
- [x] `.mi/SYSTEM.md` contributes 0 broken links, and the script says in its
      output that it resolved it from the repo root. Counterfactual run: from
      `.mi/` the Tier A count goes 6 -> 26 in the scratch copy (the SYSTEM.md
      half of that is 20, not the 19 measured during analysis — the file
      gained a link since). Counterfactual, run:
      resolve it from `.mi/` in a scratch copy and watch 19 appear.
- [x] `.mi/gantt/scratch/` is never walked, proved by planting a file with a
      broken link there and seeing both tiers ignore it (A 6 = 6, B 97 = 97).
- [x] **Multi-line link detection**, proved on the exact historical case: in a
      `scratch_tree` copy, repoint the wrapped link at
      `.mi/prds/06-help/prd.md:39` to a non-existent target and watch the
      walker report it. A per-line walker on the same copy reports 0 — include
      that comparison in the output of `--selftest`.
- [x] Fenced code blocks are skipped, proved by planting a broken link inside
      a ``` block in a scratch copy and seeing it ignored, while the same
      link outside the fence is caught.
- [x] **The green counterfactual**: in a `scratch_tree` copy with the six
      known-broken Tier A links repaired, the script exits 0. Implemented
      generically — the selftest creates every missing Tier A target in the
      copy, so it does not rot as the list moves (8 created on the run
      recorded here) — and paired with the opposite: deleting
      `06-help/04-drift-check` from the repaired copy turns it red again. This is what
      proves the gate is not permanently red and not blind.
- [x] Reported line numbers are correct after fence stripping, checked
      against one known hit (a planted link at `.mi/prds/README.md:230`,
      after a fenced block, is reported at exactly 230).
- [x] The current Tier A breakages are listed in `## Findings` of
      `../prd.md` with the owning node for each. **Four, not six**, and the
      spec said to assert the mechanism rather than the number: while this
      node was being built, `provisioning-rerate` repaired its own two spec
      links and the orchestrator fixed `capabilities-terminal.md:31`, and
      `backlog-closeout/prd.md:56` appeared. Three of the four are
      `06-help/01-content-model`'s links into the deleted
      `.mi/workflows/refs/`, now owned by
      `00-delivery/corrections/stale-framework-links`.

verify: `bash gates/tree-links.sh --selftest && bash gates/tree-links.sh`

Proved RED before writing this spec: `bash gates/tree-links.sh` → `No such
file or directory`, exit 127.

Est: 1.5h
