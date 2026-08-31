# spec03 — Wave 0: every audit finding is disposed of

Goal: the other half of R4's Wave 0 gate — "Every audit finding is either
fixed or recorded as accepted, with a reason." `tests/live-bugs.sh` already
covers one of the four finding classes exhaustively (`L-1`…`L-12`: table
shape, both cells non-empty, no smuggled ids, and every Owner cell resolving
to a real node path *and* R-number, plus the bug re-measured against the live
config). The other three classes have nobody checking them.

**`tests/live-bugs.sh` is owned by `w0-6-live-bugs` and must not be edited.**
This gate lives in `gates/` and covers what that script does not; the runner
invokes both for wave 0.

## Files touched
- `gates/audit-findings.sh` — new.

## What it checks

[`../../corrections/prd.md`](../../corrections/prd.md) carries **48 findings**
in four classes, measured during analysis: `T-` 11, `C-` 5, `L-` 12, `M-` 20.
The `L-` table has three columns (`# | Owner | Finding`); the `T-`, `C-` and
`M-` tables have two (`# | Finding`) and therefore carry no routing at all.

1. **Shape.** Each class's ids are contiguous from 1 to the class maximum,
   each occurs exactly once as a row id, and every row's Finding cell is
   non-empty. No id outside the four classes appears as a row id.
2. **Disposition.** Every finding is *disposed of*: it carries an inline
   verdict marker on its own row (`**Closed`, `**Resolved`, `**Answered`,
   `**Dropped`, `**Accepted`, `**Fixed` — case-insensitive), **or** it is
   named in some board `prd.md` other than the backlog, **or** it is named in
   `.mi/gantt/plan.json`. Anything else is an orphan finding: recorded once,
   owned by nobody, and gone by the next audit.
3. **Id matching is exact.** `T-1` must not match inside `T-10`, and `M-2`
   must not match `M-20`. Use a lookaround-guarded matcher, not `grep -w` and
   not bash `\b` — BSD grep's word boundaries do not behave here, and getting
   this wrong changed the measured orphan count from 1 to 19 during analysis.
4. **The backlog's own Acceptance boxes are reachable.** Its four `##
   Acceptance` boxes are prose-checkable and one (`Every S1 item is either
   fixed or converted into a task`) is `[x]` on the author's own say-so. The
   gate asserts the mechanical half: every `S1` section's findings satisfy
   check 2.

## Where it lands today

Measured during analysis, with the exact matcher above:

- **Loose rule** (mentioned anywhere under `.mi/` outside its own row): **1
  undisposed** — `M-19`.
- **Strict rule** (the disposition rule above): **7 undisposed** — `T-2`,
  `T-4`, `T-6`, `T-9`, `M-10`, `M-11`, `M-19`.

Build the strict rule. Four of the seven (`T-2/4/6/9`) are terminal findings
that W0.2 will dispose of when it re-specs `02-terminal`; that task is held
behind D.1. The fix belongs to
[`w0-4-s2-corrections/backlog-closeout`](../../corrections/w0-4-s2-corrections/backlog-closeout/prd.md),
whose `verify:` is already `bash tests/live-bugs.sh` — this gate is what will
tell it when it is finished. Record the seven in `## Findings` of
`../prd.md`; do not fix them here.

## Acceptance
- [x] `bash gates/audit-findings.sh` prints one line per undisposed finding
      and a summary `N findings, K undisposed`, exiting non-zero iff K > 0.
      Today: `48 findings, 0 undisposed`, exit 0.
- [x] It counts 48 findings today across `T`/`C`/`L`/`M` (T 11 · C 5 · L 12 ·
      M 20). Counterfactual, run: deleting the `M-10` row in a `scratch_tree`
      copy produces `shape: M-10 occurs exactly once as a row id (got 0)` and
      turns the gate red.
- [x] Exact id matching proved both ways in a scratch copy: disposing of
      `M-2` does **not** dispose of `M-20`, and disposing of `T-1` does not
      dispose of `T-10`. The matcher is `(^|[^A-Za-z0-9])<id>([^0-9]|$)` —
      not `grep -w`, not `\\b`.
- [x] The green counterfactual: in a scratch copy where every undisposed
      finding is given an inline `**Accepted` marker, the script exits 0. The
      copy is first made red on purpose (all three routes stripped from
      `M-11`), because the real tree now measures 0 undisposed and a green
      counterfactual from a green baseline proves nothing.
- [x] Each of the three disposition routes is proved to work on its own —
      inline marker, named in another `prd.md`, named in `plan.json` — by
      removing all three in a scratch copy and restoring exactly one.
- [x] It never edits the backlog. `assert_unchanged` covers
      `.mi/prds/00-delivery/corrections/prd.md` across the run (not `git
      diff` — the tree is mid-rename and dirty for unrelated reasons: 166
      porcelain lines throughout), and the selftest re-asserts it over the
      real backlog and `plan.json` after a full run.
- [x] The seven are listed in `## Findings` of `../prd.md` with the node that
      disposes of them — and the measurement moved to **0 undisposed** while
      this node was being built: R7 of
      `w0-4-s2-corrections/backlog-closeout` now names all seven (`T-2`,
      `T-4`, `T-6`, `T-9`, `M-10`, `M-11`, `M-19`) and routes the four
      terminal ones to `w0-2-terminal-respec`. That is the 'named in another
      board prd.md' route firing, which is the rule as specced; the Findings
      section records that rewording that one line sends all seven orphan
      again.

verify: `bash gates/audit-findings.sh --selftest`

Proved RED before writing this spec: `bash gates/audit-findings.sh` → `No such
file or directory`, exit 127.

Est: 1h
