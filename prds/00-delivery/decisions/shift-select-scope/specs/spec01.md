verify: `bash -c 'cd "$(git rev-parse --show-toplevel)"; rc=0; P=prds/03-editor/14-shift-select/prd.md; D=prds/00-delivery/decisions/shift-select-scope/prd.md; I=docs/capabilities-nvim.md; S=$(awk "/^## Simplification option/{s=1} s&&/^## /&&!/^## Simplification option/{s=0} s" "$P" | tr "\n" " " | tr -s " "); [ -n "$S" ] || { echo "FAIL: no ## Simplification option section"; exit 1; }; for pat in "2026-08-21" "eclined" "collapse-on-motion" "orrection" "shift-select-scope/prd.md" "capabilities-nvim.md" "C 7" "does not apply"; do printf "%s" "$S" | grep -q "$pat" || { echo "FAIL: decision record missing: $pat"; rc=1; }; done; grep -q "^## Answers" "$D" || { echo "FAIL: $D holds no ## Answers"; rc=1; }; HDR=$(grep -A2 "^Parent:" "$P" | tr "\n" " "); echo "$HDR" | grep -q "C 7 . U 7" || { echo "FAIL: header is not C 7 / U 7"; rc=1; }; echo "$HDR" | grep -q "capabilities-nvim.md" || { echo "FAIL: header names no inventory file"; rc=1; }; echo "$HDR" | grep -q "Shift-to-select" || { echo "FAIL: header does not name the inventory entry"; rc=1; }; N=$(awk "/^## Shift-to-select \(editor-style selection\)/{s=1;next} s&&/^## /{exit} s&&/^- [0-9]+\$/{print \$2}" "$I" | tr "\n" " "); [ "$N" = "7 7 " ] || { echo "FAIL: inventory no longer rates C 7 / U 7 (got: $N)"; rc=1; }; for n in 1 2 3 4 5 6 7 8; do grep -q "\*\*R$n\*\*" "$P" || { echo "FAIL: R$n missing"; rc=1; }; done; awk "/\*\*R6\*\*/{s=1} s&&/^- \[.\] \*\*R[75]\*\*/{s=0} s" "$P" | tr "\n" " " | tr -s " " | grep -qi "not[* ]*optional" || { echo "FAIL: R6 does not say collapse-on-motion is not optional"; rc=1; }; for f in $(grep -rl "deps:.*00-delivery/decisions/shift-select-scope" prds --include=prd.md); do grep -q "decisions/shift-select-scope/prd.md" "$f" || { echo "FAIL: gated node $f never reaches the recorded answer"; rc=1; }; done; d=$(dirname "$P"); for l in $(grep -oE "\]\([^)#][^)]*\)" "$P" | sed "s/^](//;s/)\$//" | grep -v "^http"); do [ -e "$d/${l%%#*}" ] || { echo "FAIL: broken link -> $l"; rc=1; }; done; [ $rc -eq 0 ] && echo OK; exit $rc'`

# spec01 — record the declined simplification in `03-editor/14-shift-select`

Closes both acceptance boxes of this node. Est **1h**.

The answer is already written into this node's `## Answers` (decided
2026-08-21, user): **full port with tests**. This spec does not re-open it. It
propagates it into the one file the schedule names as this task's footprint,
in the form that stops it being silently undone.

## Goal

`03-editor/14-shift-select/prd.md` carries a `## Simplification option`
section that ends "Record the decision here if taken." Today it reads as a
live, unclaimed fork — an afk worker who finds the tests burdensome may take
it without asking anyone. After this spec it reads as a closed one: dated,
attributed, reasoned, with the re-take routed to a correction instead.

Three things get written, all in that one file:

1. the dated decision, in the section that asks for it;
2. the *why*, so the next agent does not re-derive the trade from scratch
   (AGENTS.md: "Preserve the hard-won why" — the expensive part is the reason,
   not the verdict);
3. the pin on the rating — the header stays `C 7 · U 7`, matching
   `.mi/docs/capabilities-nvim.md`, because the decision turns on that not
   moving.

## Files touched

- `.mi/prds/03-editor/14-shift-select/prd.md` — and nothing else.
  `.mi/gantt/plan.json` lists exactly this one file for task `D.3`.

Three edits inside it: the `Parent:` line, the `R6` bullet, and the
`## Simplification option` section. Frontmatter is **not** touched (the
orchestrator owns it); `## Requirements`, `## Acceptance` and `## Out of
scope` keep every existing line.

### Not touched, and why

- `.mi/docs/capabilities-nvim.md` — unchanged by the answer. Its entry rates
  C 7 / U 7 with the `SIMPLIFY` verdict "port it deliberately, with tests, or
  accept plain Shift+arrow selection". The decision takes the **first**
  branch, so the entry stays exactly as it is. The verify asserts this
  (`7 7`), so a later edit to it fails this node's gate.
- `06-help/01-content-model/coverage/prd.md` — the other node whose `deps`
  name this decision. Its `R2` ("Coverage — Neovim … shift-select semantics")
  is what it is under either branch; only its parenthetical calls the fork
  "open", and it already carries a relative link to this node, which now holds
  the settled answer. Reconciliation there is by reference, which is how the
  `deps` edge was designed to work. Its parent
  `06-help/01-content-model/prd.md` (whose `R5` sits `[~]` on this fork) is
  `state: claimed` by `impl-H-1` right now — writing there would be a live
  footprint collision, and its stub clears when this node reaches `done`.
- `03-editor/14-shift-select`'s own implementation (`keymaps.lua`, the tests).
  That is task `E.14`, gated on this one.

## What to write

### 1. `Parent:` line — name the inventory the rating is pinned to

It currently truncates mid-sentence:

```
Parent: [Neovim epic](../prd.md) · C 7 · U 7 · source: "Shift-to-select" in
```

The source is dangling — there is no file named. Since the whole decision
rests on this header still matching the inventory, the link has to exist.
Replace with:

```
Parent: [Neovim epic](../prd.md) · C 7 · U 7 · source: "Shift-to-select
(editor-style selection)" in
[`capabilities-nvim.md`](../../../docs/capabilities-nvim.md)
```

`C 7 · U 7` is unchanged — it already matches the inventory entry. Verified
2026-08-21: `.mi/docs/capabilities-nvim.md` line 176, entry
`## Shift-to-select (editor-style selection)  SIMPLIFY`, trailing bullets
`- 7` / `- 7`.

### 2. `R6` — mark collapse-on-motion non-optional at the point of use

R6 is the requirement the declined path would have dropped, and a worker
reads the requirement, not the appendix. Append to the existing bullet (keep
its number and its text; add the last sentence):

```
- [ ] **R6** — **Collapse on plain motion.** In visual mode, `h`/`j`/`k`/`l`
      and the unshifted arrows: if `shift_select` is set, clear it, leave
      visual, and apply the motion; otherwise apply the motion normally.
      Counts must be preserved in both branches (`vim.v.count`). **Not
      optional** — see the declined simplification below.
```

### 3. `## Simplification option` — replace the section entire

The section is currently three lines offering the fork. Replace all of it,
heading included, with the text below verbatim (it is wrapped at 78 columns
and every relative link in it was resolved against the tree on 2026-08-21):

```markdown
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
```

The heading keeps the words `## Simplification option` so existing references
to it still read true; `— DECLINED 2026-08-21` is a suffix, not a rename.

## Acceptance

- [x] `## Simplification option` in
      `.mi/prds/03-editor/14-shift-select/prd.md` records the decision with
      the date `2026-08-21`, the word "declined", and a link to
      `00-delivery/decisions/shift-select-scope/prd.md` as its source.
      (Closes this node's acceptance box 1: "The answer is recorded, with a
      date, in the file this node names as its spec.")
- [x] The section states the *reason* — it names `collapse-on-motion` as what
      makes the capability worth its complexity, and says the test burden was
      weighed and accepted — not merely that a choice was made.
- [x] The section routes a later objection to a **correction**, naming
      `00-delivery/corrections/prd.md`, and says a worker does not re-take the
      fork. A future agent that finds the tests burdensome cannot read this
      section as permission.
- [x] The section says the `C 3 / U 5` downgrade **does not apply** and that
      the inventory entry is unchanged; the numbers appear only as a rejected
      rating, never as this node's.
- [x] The `Parent:` header reads `C 7 · U 7` and names
      `capabilities-nvim.md`; the `source:` clause no longer dangles.
- [x] The two numeric bullets of `## Shift-to-select (editor-style selection)`
      in `.mi/docs/capabilities-nvim.md` are still `7` and `7`, and the file
      is unmodified by this spec.
- [x] `R1` … `R8` are all still present in the PRD; none was dropped as "the
      simplification". `R6` carries a "not optional" marker in its own bullet.
- [x] Every node whose `deps` name `00-delivery/decisions/shift-select-scope`
      reaches the recorded answer — each such `prd.md` contains a path to
      `decisions/shift-select-scope/prd.md`, and that file holds an
      `## Answers` section. (Closes this node's acceptance box 2.)
- [x] Every relative link in `14-shift-select/prd.md` resolves to a file that
      exists.
- [x] No file other than `.mi/prds/03-editor/14-shift-select/prd.md` is
      modified.
- [x] The `verify:` command above exits 0.

## Verify provenance

Run against the tree on 2026-08-21 **before** any edit: exits 1 with 10
distinct `FAIL:` lines (missing date, missing "declined", no correction
route, no link to the deciding node, no inventory named in the section, no
`C 7` assertion, no "does not apply", header names no inventory file, `R6`
not marked non-optional, and the gated-node loop failing on
`14-shift-select` itself). Run against the edit described above: `OK`,
exit 0. The tree was restored afterwards — `14-shift-select/prd.md` is
byte-identical to its pre-check state.
