# spec02 — Reconcile the gated nodes, and put the exclusion where a reader looks

est: 0.5h

## Goal

Two jobs that share a rule.

The rule is `.mi/SYSTEM.md`'s: a `DO NOT PORT` decision "belongs in the epic's
Non-goals and the README's exclusion list, not just in the inventory". Both
places already refuse *something* called background image cycling and an
opacity toggle — and that is precisely the trap T-11 caught. Those lines
refuse the **legacy** `Ctrl+Shift+P` / `Ctrl+Shift+O` implementations
(`capabilities.md:119`, C 4 / U 5). The live config rebuilt both ideas in a
different form, rated separately (`capabilities-terminal.md`: the
`Ctrl+Shift+B` wallpaper pipeline `DO NOT PORT` C 8 / U 3, `background.png`
`DO NOT PORT` C 2 / U 0, the OSC-1337 `opacity` user-var inside a C 3 / U 7
entry), and *neither* exclusion list mentions those. So the epic's Non-goals
and T-11 currently contradict each other in the tree, and this spec is what
makes them agree.

The second job is this node's own second acceptance box: "every node listed as
gated on this decision has had its requirements reconciled with the answer".
Exactly three nodes carry `00-delivery/decisions/wallpaper-opacity` in their
`deps` — verified with `grep -rln` over `.mi/prds/**/prd.md`:

| Gated node | Reconciliation |
|---|---|
| `01-capsule/01-container-lifecycle` (C.2) | **Here.** R4 keeps `Ctrl+Shift+B`; record *why* the key is free so nobody re-picks it. |
| `02-terminal/01-appearance` (T.1) | **Routed to W0.2, deliberately — see below.** |
| `06-help/04-drift-check` | **Nothing to do.** It checks that documented bindings resolve; `06-help/01-content-model` already records that `Ctrl+Shift+B`-as-wallpaper is left undocumented *because* of the `DO NOT PORT` verdict, which this answer confirms. Confirming a premise changes no requirement. |

## Why T.1 is not touched here

The brief asked whether T.1's reconciliation belongs in this ticket. It does
not, and the reason is not footprint politeness.

1. **There is nothing to drop.** T.1's R1–R4 and its acceptance lines name
   `/src/colors`, Flakes, `font-sub-pixel-rendering`, `scroll-margin`,
   `status-bar-height`, `agave` and `italic-weight`. Not one word about
   wallpaper or opacity. The instruction "T.1 drops the background-image
   cycling and opacity requirements" describes requirements that are not in
   the file.
2. **The file is already condemned.** A session escalated it on 2026-08-21:
   four of its five config fields are rejected by the installed WezTerm at
   config-load time, its palette source does not exist, its font is not
   installed. `.mi/gantt/plan.json:663` says the same — "real requirements
   come from W0.2's rewrite, not this file as it stands today". Editing a
   file the record already calls not-the-spec produces a better-looking wrong
   file.
3. **`w0-2-terminal-respec` (W0.2) rewrites every `02-terminal` PRD from the
   inventory** and lists T.1's material in its own scope. Any edit made here
   is deleted there.

What T.1 *does* need is a correction to something it asserts, and that
correction is a **note for W0.2**, not an edit: escalation item 5 claims
"`decisions/wallpaper-opacity` decides `window_background_opacity` and the
base00 tint". It does not. Those are the **Appearance baseline** entry
(C 2 / U 7, take-over-as-is), a different capability from the two dropped
here. If W0.2 believes an answer is still owed, it stalls forever. spec01
writes that carve-out into the corrections record as item 5(d), where W0.2
reads its inputs. **The orchestrator should also file it into
`w0-2-terminal-respec`'s `## Inbox`** — that file belongs to the orchestrator
(there is already a "Filed 2026-08-21 by the orchestrator" block in it) and
to another ticket, so this spec must not write there.

## Files touched

Body text only in all three. **Do not edit any frontmatter.**

- `.mi/prds/01-capsule/01-container-lifecycle/prd.md` — one new section at the
  end. R1–R7 and every acceptance line stay exactly as they are.
- `.mi/prds/02-terminal/prd.md` — the `## Out of scope` section only.
- `.mi/prds/README.md` — the `## Excluded` section only.

### Ownership hazards, read before writing

- **`.mi/prds/README.md` is claimed by `w0-4-s2-corrections/delivery`**
  (W0.4g), whose R4 rewrites the exclusions because they are currently stated
  twice. Put the new paragraph **only inside `## Excluded`**, never in the
  prose pointer higher up the file, so W0.4g's de-duplication has nothing of
  ours to delete. If W0.4g has already landed, re-read `## Excluded` and match
  the shape it left.
- **`.mi/prds/02-terminal/prd.md` is inside W0.2's blast radius.** W0.2 is
  still `open`, so nothing is being written there right now, but it will
  revisit this epic (its R2 removes burrito references from it, its R6 updates
  it). The paragraph you add is a *decision record with a date*, which W0.2
  must preserve rather than regenerate; the README entry below is the copy
  that survives regardless. Keep the edit to the `## Out of scope` section so
  a later rewrite can lift it whole.
- **`w0-5-capsule-rebase` (W0.5) R2 owns "resolve the `Ctrl+Shift+B` /
  `Ctrl+Shift+T` collisions"**, and `w0-4-s2-corrections/capsule` also
  references the key. Do not edit either node. The `## Decisions` section
  below is written so that a later reader of W0.5 R2 finds the `B` half
  already answered and the `T` half still open.
- **Do not touch any `.mi/docs/capabilities*.md`.** They are
  `w0-4-s2-corrections/docs-inventories`', whose R1 blocks edits to
  `capabilities.md` until the author confirms, and the verdicts this decision
  confirms are already correct there. The verify asserts they are unmodified.
- **Do not touch `.mi/SYSTEM.md`.** Its Known-gaps bullet names *three*
  human-blocked decisions — burrito/tabs, tinty, fzf — and this is not one of
  them. That bullet is the tinty and fzf tickets' business. The verify asserts
  `SYSTEM.md` gained no mention of wallpaper.

## What to write

### 1. `01-capsule/01-container-lifecycle/prd.md` — a `## Decisions` section

Append at the end of the file, after `## Out of scope`. Same convention as
`00-delivery/corrections/w0-6-live-bugs` and `01-capsule/02-dev-image`.

> ## Decisions
>
> **Decided 2026-08-21 (user): `Ctrl+Shift+B` is capsule's.** R4 keeps it and
> needs no rekey. Recorded from
> [`00-delivery/decisions/wallpaper-opacity`](../prd.md),
> where the fork was put to the human.
>
> Why this needs saying at all: the audit's finding C-1 found `Ctrl+Shift+B`
> already taken in the live config — by the WezTerm wallpaper pipeline — and
> instructed the capsule PRDs to "pick new bindings". That instruction is now
> void. The incumbent is dropped (`DO NOT PORT`, C 8 / U 3), so the collision
> is **dissolved rather than resolved** and the key comes free with the port.
> Anyone re-reading C-1, or
> [`w0-5-capsule-rebase`](../../../corrections/w0-5-capsule-rebase/prd.md)
> R2, should stop here rather than invent a replacement key — a rekey now
> would cost the muscle memory the port exists to keep.
>
> `Ctrl+Shift+T` is **not** settled by this. It is a separate and still-live
> collision with WezTerm's default `SpawnTab`, which the tab reconciler treats
> as the manual new-tab path; it is claimed by
> [`04-recent-workspaces`](../../../../01-capsule/04-recent-workspaces/prd.md) and belongs to
> W0.5 R2.

Do not renumber, reword or re-flow R1–R7 — other documents cite them by
number, and R4 already says exactly the right thing. Do not flip any box: this
node is unimplemented, and confirming a keybinding is not building one.

### 2. `02-terminal/prd.md` — date the Non-goals line

Keep the existing sentence verbatim; add a paragraph under it:

> The last two were re-checked and re-confirmed **2026-08-21**. T-11 found
> that this line refused only the *legacy* implementations
> (`Ctrl+Shift+P` cycling, `Ctrl+Shift+O` toggle) while the live config had
> rebuilt both ideas in new form — the `Ctrl+Shift+B` pipeline that blurs an
> image and applies it as the **OS desktop** wallpaper, and the OSC-1337
> `opacity` user-var. Both live forms are out too, and the reasons are in
> [`decisions/wallpaper-opacity`](../prd.md).
> This does **not** touch the static `window_background_opacity` of the
> Appearance baseline, which is a separate take-over-as-is capability and is
> W0.2's to spec.

### 3. `.mi/prds/README.md` — a dated `## Excluded` entry

Add after the Odin/pi paragraph and before the `**DEFER**` paragraph, in the
shape the burrito and Odin entries established:

> **`DO NOT PORT` — the live wallpaper and opacity surfaces**, decided
> 2026-08-21: the `Ctrl+Shift+B` WezTerm pipeline that blurs an image and
> applies it as the OS desktop wallpaper — together with the 2.8 MB
> `background.png` it writes into the config dir, which nothing reads — and
> the OSC-1337 `opacity` user-var toggle. The legacy `Ctrl+Shift+P` /
> `Ctrl+Shift+O` versions are already excluded above; this adds the live
> rebuilds of the same two ideas, which the audit (T-11) found still standing
> and unrefused. `Ctrl+Shift+B` is thereby free and goes to
> `capsule --rebuild`. Two things are **not** excluded by it: the interactive
> opacity picker keeps its `DEFER` below, and the static
> `window_background_opacity` of the appearance baseline is untouched.
> Recorded in
> [`00-delivery/decisions/wallpaper-opacity`](../prd.md).

Wrap all three at ~78 columns. Check each relative link resolves from the file
it is written in.

## Acceptance

- [x] `01-capsule/01-container-lifecycle/prd.md` has a `## Decisions` section
      containing `Decided 2026-08-21 (user)`, `Ctrl+Shift+B`, `dissolved`,
      and a link to `decisions/wallpaper-opacity`.
- [x] That section also records that `Ctrl+Shift+T` is *not* settled.
- [x] R1 through R7 still exist with their numbers, and R4 still names
      `Ctrl+Shift+B`. No box in the file is `[x]` or `[~]`.
- [x] `02-terminal/prd.md`'s `## Out of scope` still names both
      `background image cycling` and `opacity toggle`, and now also carries
      `2026-08-21`, `T-11` and a link to `decisions/wallpaper-opacity`.
- [x] It states that the static `window_background_opacity` is *not* covered.
- [x] `README.md`'s `## Excluded` carries a dated entry naming
      `Ctrl+Shift+B`, `wallpaper` and `capsule --rebuild`.
- [x] `Ctrl+Shift+B` appears in `README.md` only inside `## Excluded` — the
      entry was not also added to the prose exclusion pointer near the top.
- [x] The `**DEFER**` paragraph still lists the opacity picker; this decision
      does not promote it to `DO NOT PORT`.
- [x] No `.mi/docs/capabilities*.md` is modified.
- [x] `.mi/SYSTEM.md` is not modified by this spec, and in particular gains no
      mention of wallpaper — the three-blocked-decisions bullet is the tinty
      and fzf tickets'.
- [x] `02-terminal/01-appearance/prd.md` is **not** modified: its
      reconciliation is routed to W0.2, for the reasons above.
- [x] No frontmatter block is edited in any of the three files.

verify: ""

Proven RED against the current tree before being written here: it reports
`capsule C.2 has no ## Decisions section`, the five missing
`capsule ## Decisions lacks:` strings, the four missing terminal-epic strings
(`2026-08-21`, `T-11`, `decisions/wallpaper-opacity`,
`window_background_opacity`), and the four missing README strings — exiting 1.
Everything else passes today and is a guard: R1–R7 intact, R4 still binding
`Ctrl+Shift+B`, no closed box, the two Non-goals phrases still present, the
`DEFER` picker line intact, `Ctrl+Shift+B` confined to `## Excluded`, the
three inventories unmodified, `SYSTEM.md` clean of `wallpaper`, and T.1
untouched.

Two notes on the negative guards:

- The `git diff --quiet` guard on the three inventories compares against
  `HEAD`. All three are clean at `HEAD` today, checked. If another lane
  dirties one first, the guard reports a failure that is not yours — say so
  rather than reverting someone else's work.
- The T.1 guard is a **sha256 of the file's current bytes**, not a
  `git diff`. `git diff` cannot be used there: the board migration
  (`.mi/prd` → `.mi/prds`) is an uncommitted rename, so every file under
  `.mi/prds/` already shows as changed against `HEAD` and the guard would
  fire on work nobody did. The hash was taken 2026-08-21, before this spec
  was written. If W0.2 legitimately rewrites T.1 before this spec runs, the
  guard fires; that is the correct signal — stop and report, because W0.2
  landing first changes what, if anything, is still owed.

## Spent proof

All three assertions are close-time snapshots of files this node only read:
`prds/01-capsule/01-container-lifecycle/prd.md` has closed boxes now that
the capsule lanes implemented it, `git diff --quiet --
docs/capabilities-nushell.md` is non-zero because that inventory is dirty
under another lane, and the T.1 assertion is a sha256 pin on
`prds/02-terminal/01-appearance/prd.md`, which the 02-terminal lane has
since written.

Retired from `verify:` by
[`mi-rooted-verify-commands`](../../../corrections/mi-rooted-verify-commands/prd.md)
spec02. The command below is byte-identical to what spec01 left in this
file's `verify:`; it is kept because it is the execution record of a check
that once ran green.

```text
verify: `bash -c 'cd "$(git rev-parse --show-toplevel)"; rc=0; c=prds/01-capsule/01-container-lifecycle/prd.md; C() { awk "/^## Decisions/{d=1;next} /^## /{d=0} d" "$c"; }; grep -q "^## Decisions" "$c" || { echo "FAIL: capsule C.2 has no ## Decisions section"; rc=1; }; for s in "Decided 2026-08-21 (user)" "Ctrl+Shift+B" "dissolved" "decisions/wallpaper-opacity" "Ctrl+Shift+T"; do C | grep -qF "$s" || { echo "FAIL: capsule ## Decisions lacks: $s"; rc=1; }; done; for n in 1 2 3 4 5 6 7; do grep -qF "**R$n**" "$c" || { echo "FAIL: capsule R$n vanished"; rc=1; }; done; grep -qF "**R4**" "$c" && grep -A2 "\*\*R4\*\*" "$c" | grep -qF "Ctrl+Shift+B" || { echo "FAIL: R4 no longer binds Ctrl+Shift+B"; rc=1; }; grep -qE "^- \[[x~]\]" "$c" && { echo "FAIL: a box was closed in capsule C.2"; rc=1; }; e=prds/02-terminal/prd.md; E() { awk "/^## Out of scope/{o=1;next} /^## /{o=0} o" "$e"; }; for s in "background image cycling" "opacity toggle" "2026-08-21" "T-11" "decisions/wallpaper-opacity" "window_background_opacity"; do E | grep -qF "$s" || { echo "FAIL: terminal epic Out of scope lacks: $s"; rc=1; }; done; r=prds/README.md; R() { awk "/^## Excluded/{x=1;next} /^## /{x=0} x" "$r"; }; for s in "2026-08-21" "Ctrl+Shift+B" "wallpaper" "capsule --rebuild"; do R | grep -qF "$s" || { echo "FAIL: README Excluded lacks: $s"; rc=1; }; done; [ "$(grep -cF "Ctrl+Shift+B" "$r")" -eq "$(R | grep -cF "Ctrl+Shift+B")" ] || { echo "FAIL: README names Ctrl+Shift+B outside ## Excluded"; rc=1; }; R | grep -qF "opacity picker" || { echo "FAIL: the DEFER opacity picker line was lost"; rc=1; }; git diff --quiet -- docs/capabilities-nushell.md || { echo "FAIL: an inventory was modified"; rc=1; }; grep -qi "wallpaper" AGENTS.md && { echo "FAIL: SYSTEM.md was written to"; rc=1; }; [ "$(shasum -a 256 prds/02-terminal/01-appearance/prd.md | cut -d" " -f1)" = "3cec5fe87ea9dcb55fc90c57ae4a472e537fd23f512cfb4c645959dc2aacd5f0" ] || { echo "FAIL: T.1 changed; its reconciliation belongs to W0.2, not this ticket"; rc=1; }; [ $rc -eq 0 ] && echo OK; exit $rc'`
```
