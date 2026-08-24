# spec01 — Record the answer in the corrections backlog

est: 0.5h

## Goal

This node's first acceptance box names the record destination: "the file this
node names as its spec", which its own `## Notes` resolves to
`.mi/prds/00-delivery/corrections/prd.md`, "with a date". That file's
`## S1 — open decisions for the human` section still poses decision 3 as a
live fork — *"Either accept fzf as a documented exception or replace `zi`
with a tv-backed picker"* — which is the exact shape a decision node exists
to destroy. An open fork sitting in the corrections backlog is an invitation
for the next `afk` agent to pick a side on the human's behalf.

Replace the question with the answer, in the shape decision 4 already
established in the same list a few lines below (`**Decided 2026-08-21
(user):**` followed by a "what the decision settles" list).

**Footprint warning, read before starting.** This file is the shared record
destination for three decision nodes — `decisions/tinty` (D.1b, item 2),
`decisions/wallpaper-opacity` (D.1d), and this one (D.1c, item 3) — plus
`w0-6-live-bugs`, which owns item 4. **Your edit is confined to numbered item
3.** Do not renumber, do not reflow items 1, 2 or 4, do not touch any other
section of the file. The verify carries negative guards on items 1, 2 and 4
precisely so an overreach fails loudly.

## Files touched

- `.mi/prds/00-delivery/corrections/prd.md` — numbered item **3** of
  `## S1 — open decisions for the human`, and nothing else. **Do not edit the
  frontmatter block.**

Not this spec's: `.mi/SYSTEM.md` (spec04), the three board PRDs (spec02), the
`help` content files (spec03).

## What to write

Replace item 3 in full. Keep the opening statement of the problem — a reader
five months from now needs to know what the fork *was* — then answer it:

> 3. **fzf.** `zi`/`cdi` shell out to `zoxide query --interactive`, which
>    spawns **fzf**, against the shell epic's invariant that "tv owns every
>    picker screen".
>    **Decided 2026-08-21 (user): fzf is an accepted, documented exception.**
>    `zi`/`cdi` keep shelling out to `zoxide query --interactive`; `zi` is
>    **not** rewritten against a tv-backed picker.
>
>    What the decision settles:
>    - (a) `05-platform/02-package-provisioning/packages-installer` (P.2)
>      req 7 stands: **fzf stays in the required package set**, and the
>      parenthetical that called it "required whether or not it is wanted"
>      becomes a statement of this decision rather than a shrug.
>    - (b) `04-shell/03-zoxide` (S.4) req 2 keeps the interactive path
>      unchanged.
>    - (c) The exception is **written down, not merely tolerated**, in two
>      places: the shell epic's invariant I3 in
>      [`04-shell/prd.md`](../../../../04-shell/prd.md) names fzf as the one
>      exception *and why*, and `help` carries an entry saying so. Without
>      the second, the manual teaches a rule the environment breaks, which
>      is the failure mode [`06-help`](../../../../06-help/prd.md) exists to
>      prevent.
>    - (d) It is an exception, not a precedent. Nothing else may add a
>      picker outside tv; a second one is a new decision, not an appeal to
>      this one.

Adjust the relative link depth to what the file actually needs (the file
lives at `.mi/prds/00-delivery/corrections/prd.md`, so the shell epic is
`../../04-shell/prd.md`). Wrap at ~78 columns.

Do not flip any `- [ ]` box in the file. The corrections backlog's own
acceptance box "The three open decisions have a recorded answer, in this
file, with a date" stays open until all three are recorded — one of three is
not three.

## Also, in this node's own `prd.md`

Tick this node's first acceptance box only:

- `- [x] The answer is recorded, with a date, in the file this node names as
  its spec.` — with the check you ran (the verify below).

Leave the second box (`Every node listed as gated on this decision has had
its requirements reconciled`) open; spec02 closes it. **Do not edit this
node's frontmatter.**

## Acceptance

- [ ] Item 3 contains the literal `Decided 2026-08-21 (user)`.
- [ ] Item 3 no longer poses the fork (`Either accept fzf` is gone).
- [ ] Item 3 names `zoxide query --interactive`, points at
      `04-shell/prd.md`, names `packages-installer`, and says `help` carries
      an entry.
- [ ] Item 3 states that this is an exception and not a precedent.
- [ ] Items 1 (burrito) and 2 (tinty) are byte-untouched and still carry no
      answer — this spec does not settle a sibling's fork.
- [ ] Item 4's existing `Decided 2026-08-21 (user)` record is intact.
- [ ] No box anywhere in the file is flipped to `[x]` or `[~]`.
- [ ] The file still wraps at ~78 columns (tables exempt) and the
      `## S1 — open decisions for the human` heading is intact.
- [ ] This node's `prd.md` acceptance box 1 is `[x]` with the check named;
      box 2 is still `[ ]`.

verify: ""

**Proven RED against the current tree before being written here.** It reports
`decision 3 lacks: Decided 2026-08-21 (user)` / `accepted` /
`04-shell/prd.md` / `packages-installer` / `help`, plus `decision 3 still
poses the fork`, and exits 1. The five negative guards (items 1, 2 and 4
undisturbed, section heading present) pass now and exist to fail if the
implementer strays outside item 3. The two strings it does *not* report —
`exception` and `zoxide query --interactive` — are already in the current
item-3 text and must survive the rewrite; that is deliberate, not a hole.

## Spent proof

The guard asserts that decision 2 in `prds/00-delivery/corrections/prd.md`
is still unanswered, and `decisions/tinty` answered it on 2026-08-21, after
this node closed; every assertion on decision 3, which is this node's own,
still passes.

Retired from `verify:` by
[`mi-rooted-verify-commands`](../../../corrections/mi-rooted-verify-commands/prd.md)
spec02. The command below is byte-identical to what spec01 left in this
file's `verify:`; it is kept because it is the execution record of a check
that once ran green.

```text
verify: `bash -c 'cd "$(git rev-parse --show-toplevel)"; c=prds/00-delivery/corrections/prd.md; rc=0; I() { awk -v n="$1" -v m="$2" "BEGIN{p=0} \$0 ~ \"^\"n\"\\\\. \\\\*\\\\*\"{p=1} \$0 ~ \"^\"m\"\\\\. \\\\*\\\\*\"{p=0} p" "$c"; }; for s in "Decided 2026-08-21 (user)" "accepted" "exception" "zoxide query --interactive" "04-shell/prd.md" "packages-installer" "help"; do I 3 4 | grep -qF "$s" || { echo "FAIL: decision 3 lacks: $s"; rc=1; }; done; I 3 4 | grep -qF "Either accept fzf" && { echo "FAIL: decision 3 still poses the fork"; rc=1; }; I 1 2 | grep -qF "burrito vs the nine-tab floor" || { echo "FAIL: decision 1 disturbed"; rc=1; }; I 1 2 | grep -qF "Decided" && { echo "FAIL: decision 1 was answered by this spec"; rc=1; }; I 2 3 | grep -qF "Does tinty stay" || { echo "FAIL: decision 2 disturbed"; rc=1; }; I 2 3 | grep -qF "Decided" && { echo "FAIL: decision 2 was answered by this spec"; rc=1; }; awk "/^4\\. \\*\\*Deployed/{p=1} p" "$c" | grep -qF "Decided 2026-08-21 (user)" || { echo "FAIL: decision 4 record disturbed"; rc=1; }; grep -qE "^## S1 — open decisions for the human" "$c" || { echo "FAIL: section heading gone"; rc=1; }; [ $rc -eq 0 ] && echo OK; exit $rc'`
```
