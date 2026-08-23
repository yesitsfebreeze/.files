# spec01 — Record the answer, and close T-11 on the record

est: 0.5h

## Goal

This node's first acceptance box is "the answer is recorded, with a date, in
the file this node names as its spec". That file is
`.mi/prds/00-delivery/corrections/prd.md`: it holds the numbered
**open decisions** list where the human's answers land (item 4 is already
recorded there in exactly this shape), and it holds T-11, the finding this
decision exists to close.

T-11 is the whole point. The backlog's own first acceptance criterion —
"every S1 item is either fixed or converted into a task" — is **currently
violated by T-11 alone**: no T task builds the live wallpaper/opacity
features, no task drops them, and C-1 meanwhile hands `Ctrl+Shift+B` to
capsule, which would have deleted a live feature as a side effect of a
keybinding change. `.mi/gantt/plan.md:115` states this in as many words. The
answer converts T-11 into a decision and answers it, so this spec also closes
that criterion.

**Verified before speccing:** the four numbered items under `## S1 — open
decisions for the human` are burrito (settled), tinty (open), fzf (open) and
"deployed or source" (`Decided 2026-08-21 (user)`, recorded in place). No
item mentions wallpaper or opacity today, and the T-11 row carries no
resolution. `grep -c "^- \[x\]"` over the file's `## Acceptance` block is 0.

## Files touched

- `.mi/prds/00-delivery/corrections/prd.md` — three edits, listed below.
  **Do not edit the frontmatter block.**

Nothing else. spec02 owns every other file.

### Contention — read this before you type

**This file is shared with two sibling decision tickets that are being
specced right now.** `00-delivery/decisions/fzf` answers numbered item **3**
and `00-delivery/decisions/tinty` answers numbered item **2**, both in this
same list, and both will tick the *second* acceptance box ("The three open
decisions have a recorded answer, in this file, with a date"). `w0-6-live-bugs`
also writes here.

Therefore:

- Touch **only** the three regions named below. Do not reflow, re-wrap or
  re-order anything else in the file, however tempting — a whitespace-only
  hunk elsewhere turns a clean serialisation into a merge conflict.
- Do **not** touch numbered items 1, 2, 3 or 4.
- Do **not** touch the second acceptance box. It is the siblings'.
- If a sibling has already landed when you run, re-read the list and append
  your item after whatever is there; the item number may not be 5 any more,
  in which case use the next free number and update the T-11 row's pointer to
  match.

## What to write

### 1. Close the T-11 row

The row is a single table line beginning `| T-11 |`. Keep its existing text
verbatim — it is the finding, and the finding was correct — and append to the
same cell, before the closing `|`:

> **Closed 2026-08-21 — converted to a decision and answered: both features
> are dropped on the record.** See open decision 5 below and
> [`decisions/wallpaper-opacity`](../decisions/wallpaper-opacity/prd.md).

Do not delete the row and do not move it. Other documents cite findings by
number, and a finding that is gone reads as a finding that was never made.

### 2. Add the answer as numbered item 5

Append to the `## S1 — open decisions for the human` list, after item 4,
matching item 4's shape (bold question, bold dated answer, a "what the
decision settles" sub-list). Wrap at ~78 columns.

> 5. **Wallpaper cycling and the opacity toggle: ported or dropped, and who
>    gets `Ctrl+Shift+B`?**
>    **Decided 2026-08-21 (user): both are dropped, on the record, and
>    `Ctrl+Shift+B` goes to capsule.**
>    Raised by T-11, which found the terminal epic refusing the two *legacy*
>    features (`Ctrl+Shift+P` cycling, `Ctrl+Shift+O` toggle) while the live
>    config had rebuilt both in new form. Refusing an old implementation is
>    not a decision about its replacement, so C-1's "give `Ctrl+Shift+B` to
>    capsule" would have deleted a live feature as a side effect of a
>    keybinding change. Dropping it deliberately and dropping it by accident
>    leave the same config and a very different record.
>
>    What the decision settles:
>    - (a) The `Ctrl+Shift+B` **wallpaper pipeline is not ported**, confirming
>      the `DO NOT PORT` (C 8 / U 3) verdict in
>      [`capabilities-terminal.md`](../../../docs/capabilities-terminal.md).
>      The engineering is careful, but the capability is a GUI keypress that
>      rewrites the OS desktop *and* another tool's source tree, depends on
>      ImageMagick, and is the largest block in the file after the tab floor.
>      If desktop wallpaper matters later it is a shell command, not a
>      terminal binding. `background.png` (`DO NOT PORT`, C 2 / U 0) drops out
>      with it.
>    - (b) The **opacity toggle is not in the minimal base**: neither the
>      OSC-1337 `opacity` user-var nor the `opacity` tv picker. The picker
>      keeps its existing `DEFER` (C 3 / U 3) — deferred is not refused, and
>      it may come back with the theme switcher it shares a surface with.
>    - (c) **`Ctrl+Shift+B` goes to capsule** — `capsule --rebuild`,
>      [`01-capsule/01`](../../01-capsule/01-container-lifecycle/prd.md) R4.
>      C-1's collision is **dissolved, not resolved**: with the incumbent
>      dropped the key is free, so no rekey is needed and none should be
>      invented. `Ctrl+Shift+T` is a separate collision and is untouched by
>      this.
>    - (d) **Not settled here, because it is not a fork.** The *static*
>      `window_background_opacity = 0.95`, its base00 translucent tint and
>      `macos_window_background_blur = 30` belong to the **Appearance
>      baseline** entry (C 2 / U 7, take-over-as-is) — a different capability
>      from either feature dropped above, and one the inventory already
>      rates.
>      [`02-terminal/01-appearance`](../../02-terminal/01-appearance/prd.md)'s
>      escalation names this node as their decider; it is mistaken.
>      [`w0-2-terminal-respec`](w0-2-terminal-respec/prd.md) specs them from
>      the inventory like every other appearance field, and must not wait on
>      an answer that is not coming.
>
>    T-11 is thereby closed as *converted to a decision and answered* — gantt
>    task D.1d, board node
>    [`decisions/wallpaper-opacity`](../decisions/wallpaper-opacity/prd.md).

Check every relative link resolves from
`.mi/prds/00-delivery/corrections/prd.md` before you finish: `../../../docs/`
reaches `.mi/docs/`, `../../` reaches `.mi/prds/`, and
`w0-2-terminal-respec/prd.md` is a sibling directory.

### 3. Tick the first acceptance box

Change the first box under `## Acceptance` from `- [ ]` to `- [x]`, keeping
its text. It is provable now and was not before. The evidence, which you must
confirm by reading the file rather than trusting this spec:

- T-1 … T-10 → task **W0.2** (`w0-2-terminal-respec`).
- T-11 → task **D.1d**, this decision. *This is the one that was missing.*
- C-1 … C-5 → task **W0.5** (`w0-5-capsule-rebase`), with C-1's capsule half
  also carried by `w0-4-s2-corrections/capsule`.
- Open decisions → 1 answered (burrito, 2026-08-20), 4 answered
  (2026-08-21), 5 answered here; 2 and 3 are `decisions/tinty` and
  `decisions/fzf`, board nodes of their own.

If reading the file does **not** support that, leave the box open and say so
in your report. A `[x]` you did not prove is worse than the gap it hides.

**Known residual, do not fix it here:** the box's text points at
`01-work-breakdown`, whose `D.1` row still describes three human decisions
rather than the five `decisions/*` nodes that now exist. That file is
`00-delivery/work-breakdown`, outside this ticket's footprint and inside
`w0-4-s2-corrections/delivery`'s. The conversion is real — the board node and
the gantt task both exist — and the stale prose table is a separate
correction. Report it; do not open the file.

Do not flip any other box anywhere. Nothing in this decision is implemented;
it is recorded.

## Acceptance

- [x] The `| T-11 |` row still exists, still carries its original finding
      text, and now also carries `Closed 2026-08-21` and a link to
      `decisions/wallpaper-opacity`.
- [x] `## S1 — open decisions for the human` holds at least five numbered
      items, and the new one contains the literal
      `Decided 2026-08-21 (user)`.
- [x] That new item names `wallpaper`, `opacity`, `Ctrl+Shift+B`, `T-11`,
      `capsule --rebuild`, and `DO NOT PORT`.
- [x] It records the (d) carve-out: the static `window_background_opacity` /
      Appearance baseline is **not** decided here, and names
      `w0-2-terminal-respec` as its owner.
- [x] Items 1–4 are untouched: the burrito, tinty and fzf headwords are
      intact and item 4 still carries `Decided 2026-08-21 (user): the
      deployed`.
- [x] The first `## Acceptance` box reads `- [x]` — or is left `- [ ]` with
      the reason in the report.
- [x] The second `## Acceptance` box still carries its original text about
      the three open decisions. Its `[ ]`/`[x]` state is a sibling's business
      and is not asserted either way.
- [x] No file other than `.mi/prds/00-delivery/corrections/prd.md` is
      modified by this spec.
- [x] The frontmatter block is unchanged.

verify: `bash -c 'cd "$(git rev-parse --show-toplevel)"; f=prds/00-delivery/corrections/prd.md; rc=0; D() { awk "/open decisions for the human/{d=1;next} /^## /{d=0} d" "$f"; }; N() { D | awk "/^5\./{p=1} /^## /{p=0} p"; }; t=$(grep "^| T-11 |" "$f"); [ -n "$t" ] || { echo "FAIL: T-11 row is gone"; rc=1; }; case "$t" in *"exist live in new form"*) ;; *) echo "FAIL: T-11 lost its original finding text"; rc=1;; esac; case "$t" in *"Closed 2026-08-21"*) ;; *) echo "FAIL: T-11 not closed on the record"; rc=1;; esac; case "$t" in *"decisions/wallpaper-opacity"*) ;; *) echo "FAIL: T-11 does not point at the decision"; rc=1;; esac; [ "$(D | grep -c "^[0-9]\. \*\*")" -ge 5 ] || { echo "FAIL: no fifth open-decision item"; rc=1; }; D | grep -qF "Decided 2026-08-21 (user): both are dropped" || { echo "FAIL: the dated answer is not recorded"; rc=1; }; for s in "wallpaper" "opacity" "Ctrl+Shift+B" "T-11" "capsule --rebuild" "DO NOT PORT" "window_background_opacity" "w0-2-terminal-respec"; do N | grep -qF "$s" || { echo "FAIL: the new item lacks: $s"; rc=1; }; done; for s in "burrito vs the nine-tab floor" "Does tinty stay" "Decided 2026-08-21 (user): the deployed" ; do D | grep -qF "$s" || { echo "FAIL: a sibling decision item was disturbed: $s"; rc=1; }; done; D | grep -qF "**fzf.**" || { echo "FAIL: the fzf item was disturbed"; rc=1; }; A() { awk "/^## Acceptance/{a=1;next} /^## /{a=0} a" "$f"; }; A | grep -qF "The three open decisions have a recorded answer" || { echo "FAIL: the siblings acceptance box was disturbed"; rc=1; }; A | head -2 | grep -qF "Every S1 item is either fixed or converted into a task" || { echo "FAIL: the S1 acceptance box moved or changed text"; rc=1; }; head -9 "$f" | grep -q "^kind: epic" || { echo "FAIL: frontmatter changed"; rc=1; }; [ $rc -eq 0 ] && echo OK; exit $rc'`

Proven RED against the current tree before being written here: it reports
`T-11 not closed on the record`, `T-11 does not point at the decision`,
`no fifth open-decision item`, `the dated answer is not recorded`, and the
eight `the new item lacks:` lines, exiting 1. The five negative guards (the
four sibling items, the siblings' acceptance box, the frontmatter) pass now
and exist to fail if the implementer strays outside its three regions.

Note the verify deliberately does **not** assert the first acceptance box is
`[x]`: the spec permits leaving it open with a reason, and a gate that forces
a tick is a gate that manufactures false records. Check that box by reading
the diff.
