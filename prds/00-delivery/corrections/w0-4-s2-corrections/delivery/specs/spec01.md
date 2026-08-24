# spec01 — Wave 0 no longer waits on a human: five decisions, all answered

est: 0.75h

## Goal

`01-work-breakdown`'s Wave 0 section is the last place in the tree that still
presents the D.1 scope forks as open. Checked against the board, not assumed:

- The table's last row reads
  `| D.1 | **Human decisions**: burrito vs nine-tab floor · does tinty stay ·
  fzf exception or replace | — | backlog | *blocked on the human* |`. All
  three clauses are dead.
- Five `00-delivery/decisions/*` nodes exist, and every fork is answered:
  `tinty` (D.1b), `fzf` (D.1c), `wallpaper-opacity` (D.1d), `odin-toolchain`
  (D.2), `shift-select-scope` (D.3). Four are `state: done`; `fzf`'s answer is
  recorded in its PRD and the corrections backlog with one spec still to land.
  The answers are dated 2026-08-21 in
  [the corrections backlog](../../../prd.md) (open decisions
  2–5) and in each node.
- The **burrito** question — what was open decision 1, "which layer owns
  panes/tabs" — was settled separately on 2026-08-20 by deleting burrito.
  `.mi/gantt/plan.json` records the consequence in the W0.1, W0.2, W0.5 and
  T.2 notes: *"D.1a and T.5 are removed rather than resolved"*, with WezTerm's
  self-healing nine-tab floor owning panes and tabs and no competing
  multiplexer. `.mi/prds/README.md`'s `## Excluded` already carries the same
  decision.
- The prose above the table still says "three scope forks need a human
  answer", and the paragraph below it still calls **D.1 the real Wave 0
  gate**. `plan.json` disagrees on both counts: W0.2's deps are
  `W0.1, W0.4, W0.6` and W0.5's are `W0.4, W0.6` — neither waits on a
  decision any more. The corrections sweep (W0.4) is the gate.
- The W0.1 row still says "Inventory live `~/.config/wezterm` + burrito" at
  size **L**. `plan.json` has it at **M** with the note "Scope is WezTerm only
  now, so the burrito half of the inventory drops (L -> M)".

A plan that names a person as the blocker on work nobody is blocked on is how
a build stalls on a question already answered.

## Files touched

- `.mi/prds/00-delivery/work-breakdown/prd.md` — the `## Wave 0` section
  only: its two prose paragraphs, the table's `W0.1`, `W0.2`, `W0.5` and
  `D.1` rows.

### Ownership hazards, read before writing

- This node (W0.4g) owns `.mi/prds/00-delivery/work-breakdown/prd.md` and
  `.mi/prds/README.md`. **Touch nothing else** — the other six W0.4 children
  are writing their own epics concurrently.
- Do **not** edit `.mi/gantt/plan.json`. It is the schedule of record here and
  this spec reads from it; the gantt is the conductor's.
- Do **not** edit frontmatter, and do not tick any `- [ ]` box in
  `work-breakdown/prd.md` (its four acceptance boxes belong to that node, not
  to this correction).
- Leave the `## Track` tables alone — spec02 rewrites those.

## What to write

Relative links shown under **What to write** are written *into the target
file*, so they resolve from that file's directory, not from this spec's.

<!-- tree-links: target-file-vantage — the relative links in this section are
     markup written into prds/00-delivery/work-breakdown/prd.md and
     prds/README.md, and resolve from those files' directories, not from this
     spec's. Repairing them here would falsify the instruction. -->

1. **Rewrite the second Wave 0 paragraph.** Drop "three scope forks need a
   human answer". State instead that the audit's forks are now all answered,
   with the date, and that the wave's remaining size comes from the terminal
   rebuild and the corrections sweep. Keep the link to
   [`04-corrections-backlog`](../corrections/prd.md).
2. **Replace the `D.1` row with one row per decision**, first cell `D.1b`,
   `D.1c`, `D.1d`, `D.2`, `D.3`. Each row names the board node by path
   (`decisions/tinty`, `decisions/fzf`, `decisions/wallpaper-opacity`,
   `decisions/odin-toolchain`, `decisions/shift-select-scope`), states the
   answer in one clause, and carries the date `2026-08-21`.
   **Do not copy board state into the row** — no `state:` values, no
   "claimed"/"open". Frontmatter moves; a table that mirrors it goes stale,
   which is the defect being repaired. The answer and its date do not move.
3. **Record the burrito question as removed, not resolved.** One sentence
   under the table: D.1a and T.5 were *removed rather than resolved* when
   burrito was deleted on 2026-08-20; WezTerm's self-healing nine-tab floor
   owns panes and tabs, with no competing multiplexer. Cross-link
   [`README.md`'s exclusion entry](../../README.md) rather than restating the
   full rationale.
4. **Replace the "D.1 is the real Wave 0 gate" paragraph.** W0.2 and W0.5 no
   longer wait on a decision; per `plan.json` they wait on **W0.4** (and
   W0.6). Say that, and keep the closing observation that Tracks P, S, E and H
   proceed regardless.
5. **Fix the W0.1 row**: drop "+ burrito" from the task text and set the size
   to `M`, matching `plan.json`. Fix the `W0.2` and `W0.5` rows' `Depends on`
   cells, which name the deleted `D.1`.

## Acceptance

- [ ] No table row in the file has `D.1` or `D.1a` as its first cell.
- [ ] Rows exist with first cell `D.1b`, `D.1c`, `D.1d`, `D.2` and `D.3`.
- [ ] Each of those five rows names its node path under `decisions/` and
      carries `2026-08-21`.
- [ ] None of those five rows contains a board `state:` value.
- [ ] The string `blocked on the human` does not appear in the file.
- [ ] The stale row text `burrito vs nine-tab floor` does not appear.
- [ ] The file no longer says `three scope forks`, and no longer calls D.1
      the Wave 0 gate.
- [ ] Read with line breaks collapsed, the file states that `D.1a and T.5`
      were `removed rather than resolved`, names the `self-healing nine-tab
      floor` as the owner of panes and tabs, and dates the burrito deletion
      `2026-08-20`.
- [ ] The `W0.1` row no longer says `burrito` and its Size cell is `M`.
- [ ] No row in the Wave 0 table names the deleted task `D.1`
      anywhere in the row (`D.1b`/`D.1c`/`D.1d` are fine — the check
      is deliberately position-free, because spec02 deletes the
      `Depends on` column out from under a positional one).
- [ ] No `- [ ]` box in the file was flipped to `[x]` or `[~]`, and
      `## Acceptance` still holds its four open boxes.

verify: `bash -c 'cd "$(git rev-parse --show-toplevel)"; f=prds/00-delivery/work-breakdown/prd.md; rc=0; ROW() { grep -E "^\| *$1 *\|" "$f"; }; for i in D.1 D.1a; do ROW "$i" >/dev/null && { echo "FAIL: a table row is still keyed $i"; rc=1; }; done; for i in D.1b D.1c D.1d D.2 D.3; do r=$(ROW "$i"); [ -n "$r" ] || { echo "FAIL: no table row for $i"; rc=1; continue; }; printf "%s" "$r" | grep -qF "decisions/" || { echo "FAIL: $i row does not name its board node path"; rc=1; }; printf "%s" "$r" | grep -qF "2026-08-21" || { echo "FAIL: $i row is undated"; rc=1; }; printf "%s" "$r" | grep -qF "state:" && { echo "FAIL: $i row copies board state, which goes stale"; rc=1; }; done; for s in "blocked on the human" "burrito vs nine-tab floor" "three scope forks" "D.1 is the real Wave 0 gate"; do grep -qF "$s" "$f" && { echo "FAIL: stale text survives: $s"; rc=1; }; done; N=$(tr "\n" " " < "$f" | tr -s " "); for s in "D.1a and T.5" "removed rather than resolved" "self-healing nine-tab floor" "2026-08-20"; do printf "%s" "$N" | grep -qF "$s" || { echo "FAIL: the burrito removal is not recorded: $s"; rc=1; }; done; w=$(ROW W0.1); printf "%s" "$w" | grep -qF burrito && { echo "FAIL: W0.1 still inventories burrito"; rc=1; }; printf "%s" "$w" | awk -F"|" "{gsub(/ /,\"\",\$4); exit !(\$4==\"M\")}" || { echo "FAIL: W0.1 size is not M"; rc=1; }; awk "/^## Wave 0/{w=1} /^## Track/{w=0} w" "$f" | grep -E "^\|" | grep -qE "D\.1([^a-z0-9]|$)" && { echo "FAIL: a Wave 0 row still names the deleted task D.1"; rc=1; }; grep -qE "^ *- \[[x~]\]" "$f" && { echo "FAIL: a box in work-breakdown was closed"; rc=1; }; [ "$(awk "/^## Acceptance/{a=1;next} /^## /{a=0} a" "$f" | grep -c "^- \[ \]")" -eq 4 ] || { echo "FAIL: the four acceptance boxes were disturbed"; rc=1; }; [ $rc -eq 0 ] && echo OK; exit $rc'`

Proven RED before being written here — see `checks/red-spec01.txt` for the
captured run.
