---
state: done
priority: 13
est:
mode: afk
claim: 
needs:
verify: ""
origin: derived
from: 03-editor
complexity: 12
blast-radius: low
commit: c53d294
---

# Epic invariant I8 says "named for the plugin"; every landed file is named
# for the concern

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: [`03-editor`](../../../03-editor/prd.md)'s **I8** reads "One file per
plugin under `lua/plugins/`. Each plugin spec lives in a file named **for the
plugin**". Practice disagrees, consistently and deliberately:

| landed file | plugin it holds |
|---|---|
| `lua/plugins/completion.lua` | blink.cmp |
| `lua/plugins/colorscheme.lua` | tinted-nvim |
| `lua/plugins/lsp.lua` | mason + nvim-lspconfig |
| `lua/plugins/telescope.lua` | telescope (both readings agree) |

Three of four are named for the **concern**, not the plugin — which is the
better convention, because it survives replacing the plugin. `AGENTS.md`
records that pattern elsewhere too: "Prefer built-ins over plugins", and the
inventories name capabilities rather than packages.

Why it is worth a node rather than a shrug: I8 is an **epic invariant**, and
[`AGENTS.md`(../../../../../AGENTS.md) says epics own the invariants and
children reference them rather than restating them. So every future editor
node reads this sentence to decide a filename. E.11's analyst hit exactly that
— `07-formatting` never named its file, and resolving it required weighing
I8's letter against the landed practice. The next node will do the same work
again unless the sentence matches reality.

Found by E.11's analyst, 2026-08-23, which called it "decidable, not a
question — but somebody should reconcile I8's wording".

## Requirements
- [x] **R1** — I8 states the convention actually in force, with the reason:
      one file per plugin, **named for the concern it delivers**, because a
      concern name survives replacing the plugin behind it. The
      no-catch-all clause and the `lua/plugins/editor.lua` history it records
      are correct and stay.
      *(a) — commit `c53d294`: "I8 restated for the concern, not the plugin
      … I8 now says what the config actually does."*
- [x] **R2** — Every landed filename is checked against the restated
      invariant, and any genuine mismatch is **reported, not renamed**.
      Renaming a deployed file changes the plugin census in
      `tests/nvim-options.sh` and every gate that greps it — far beyond a
      wording fix, and it would collide with whichever editor node holds
      that census at the time.
      *(a) — commit `c53d294` spec01: "census of all twelve
      lua/plugins/*.lua files against the restated wording (zero genuine
      mismatches; conform.lua reported as the one already-litigated
      ambiguous case)."*
- [x] **R3** — The unbuilt editor nodes that will create files —
      [`12-small-plugins`](../../../03-editor/12-small-plugins/prd.md),
      [`13-statusline`](../../../03-editor/13-statusline/prd.md),
      [`15-markdown-tables`](../../../03-editor/15-markdown-tables/prd.md) —
      are checked for a name that the restated I8 would reject, and any
      conflict is reported. `12-small-plugins` R4 already names three files;
      if the restatement disagrees with them, **that node's names win** —
      they were settled by a correction — and I8 accommodates them.
      *(a) — commit `c53d294` spec01: "the three nodes R3 worried about,
      found already done with names that agree."*

## Acceptance
- [x] I8's new text is quoted, alongside the four-row table of landed files
      that motivated it.
      *(a) — commit `c53d294` restated I8 in `prds/03-editor/prd.md`; the
      four-row table is this PRD's body.*
- [x] The R2 and R3 checks are in the report as lists, with a verdict per
      file: agrees, mismatched-and-reported, or not yet created.
      *(a) — commit `c53d294` spec01 carries the census with verdicts.*
- [x] `bash gates/tree-links.sh` Tier A stays at 0 broken.
      *(a) — commit `c53d294`: "Verified: bash gates/tree-links.sh — 0
      broken before and after."*

## Out of scope
- Renaming any file, deployed or specced. R2 makes a mismatch a reported
  finding.
- The `lua/plugins/editor.lua` catch-all decision, which I8 already records
  and which three nodes already act on.
