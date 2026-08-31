---
state: done
priority: 37
est: 3.7h
task: W0.4c
mode: afk
needs:
  - 00-delivery/corrections/w0-3-platform-rewrite
verify: ""
origin: derived
from: 00-delivery/corrections/w0-4-s2-corrections
---

# 03-editor corrections

Purpose: One epic's share of the S2/S3 corrections sweep. Child of W0.4; one
writer per file, so the seven corrections run in parallel instead of one agent
serialising ~22 files.

## Requirements
- [x] **R1** — L-8: the treesitter `FileType` autocmd and shift-select's
      `ModeChanged` are ungrouped, so a reload stacks duplicates — a violation
      of `03-autocmds`' own invariant. Record grouping as a requirement in
      both places. **Done** — as the epic's new **I7**, per `AGENTS.md`
      "epics own the invariants": neither offending node is in this
      footprint, and an epic invariant binds all three. **The sweep found a
      third ungrouped site** the backlog's L-8 row does not list —
      `plugins/editor.lua:80` (vim-table-mode's `FileType`) — recorded in
      I7. `03-autocmds` gains **R5** promoting its prose claim into a box.
      Check: `specs/verify-all.sh` → `PASS spec02`.
- [x] **R2** — L-10: gitsigns delete/topdelete glyphs are empty strings live;
      both documents describe them as glyphs. Record that the nerd-font glyphs
      are restored, not that the loss is ported. **Done** — and the defect
      was worse than stated: `12-small-plugins` R1 did not *describe* the
      empty string, it *reproduced* it (a literal empty backtick pair), so
      an implementer following it faithfully would have rebuilt the blank
      sign. R1 now states the binding property (non-empty, single
      codepoint, distinct from `▎`) and names glyphs by `U+` codepoint —
      U+F0DA recommended, U+203E/`_` as the font-free fallback — because a
      codepoint lost to copy-paste is how the bug happened. (Confirmed: the
      spec that prescribed U+F0DA had itself lost the character; it was
      emitted from the codepoint, not pasted.)
      Check: `specs/verify-all.sh` → `PASS spec03`.
- [x] **R3** — L-6: `<Esc>` → `nohlsearch` is inert because `hlsearch=false`.
      Port one or the other and say which. **Done** — `hlsearch=false` is
      ported (`01-options` R6) and the map is **not** (`02-keymaps` R1,
      which keeps its number and prescribes no keymap). Both halves now
      carry the decision and the rejected LazyVim pairing. Requires the
      `02-keymaps` footprint extension. Check: `PASS spec06`.
- [x] **R4** — M-1: the scrolloff overclaim in `01-options`. M-17: the epic
      says 13 files; there are 14. M-3: the baseline says native 0.11 while
      the live binary is 0.12.4. **Done, with one correction to the ticket
      itself: M-17 was already discharged** — the epic said "14 files" and
      that is right (`find ~/.config/nvim -name '*.lua' | wc -l` → 14,
      re-measured). No edit was invented to close it; the `~680` estimate
      was tightened to the measured **683**. M-1: R3 no longer claims
      unconditional centering and the acceptance line now exempts the top
      of the buffer. M-3: the version *floor* (≥0.11) was fine — the real
      bite was `03-autocmds` R1 prescribing the deprecated
      `vim.highlight.on_yank`; the epic's I6 now distinguishes **floor**
      from **target** (0.12.4) and R1 prescribes `vim.hl.on_yank`.
      Check: `PASS spec04`.
- [x] **R5** — Record that `plugins/editor.lua` is split into one file per
      plugin, and that the filename appears nowhere in the tree though three
      PRDs write it. **Done** — epic invariant **I8**, plus
      `12-small-plugins` **R4** naming its three target files. The
      `cmdheight` half of the same backlog bullet is recorded in
      `01-options` R2 (it equals Neovim's default; recorded as bookkeeping,
      not a behaviour change). `grep -rn 'editor\.lua' .mi/prds/03-editor/`
      is no longer empty. Check: `PASS spec05`.
- [x] **R6** — L-7: oil is lazy on `keys`, so `default_file_explorer` is not
      installed until `<leader>e` is pressed; with netrw disabled, `:e
      some/dir` opens neither. `03-editor/06-explorer`'s third acceptance line
      asserts exactly the behaviour this bug prevents. Correct the load
      condition, or correct the acceptance line — and say which. **Done —
      the load condition was corrected: oil becomes `lazy = false`, and the
      `:e some/dir` acceptance line stands unchanged.** Decided afk under
      this node's delegation. Keeping the lazy load would have made the PRD
      self-consistent by abandoning the capability its Purpose names, and
      left `:e dir` a dead end stock Neovim does not have. `06-explorer`
      R1 carries the mechanism (the hijack installs in `setup()`) and new
      **R4** records the fork so it is not "optimised" back. Requires the
      `06-explorer` footprint extension. Check: `PASS spec07`.
- [x] **R7** — L-9: visual-mode `<C-v>` shadows blockwise-visual mode. Record
      the decision in both `03-editor/02-keymaps` and
      `03-editor/14-shift-select`, including the "leave `<C-q>` unbound" half,
      so the decision is reachable from the nodes that implement it. R6 and R7
      placed here by the conductor on 2026-08-21 because `w0-6-live-bugs`
      identified them and named this node as their owner, but may not write
      this file. **Done on the `02-keymaps` side** — new **R9** records the
      shadow, the afk decision to port it as-is, the rejected alternative,
      the visual-mode-only scope, and the "leave `<C-q>` unbound" half as a
      *negative* requirement (an unbound key is invisible to search, so
      writing it down is the only thing stopping a later agent from taking
      it). The gate sweeps all of `03-editor` for any `<C-q>` binding.
      **Residual, declared not absorbed:** the `14-shift-select` half is
      NOT discharged — that file is `decisions/shift-select-scope`'s and
      this ticket was told to leave it alone. It needs a one-bullet
      follow-up pointing its R7 at this decision. Check: `PASS spec08`.

## Acceptance
- [x] Every requirement box above is `[x]`, and the backlog item it corrects
      is marked fixed. **R1–R7 are all `[x]`; this box stays OPEN on its
      second clause only.** Marking the backlog items fixed means editing
      `.mi/prds/00-delivery/corrections/prd.md`, which is
      `backlog-closeout`'s (W0.4h) file and is pinned by
      `tests/live-bugs.sh` — one writer per file, so this ticket must not
      touch it. W0.4h closes this box.
      *(a) — the backlog items are marked fixed: L-8, L-10, L-6, M-1 all
      "**Fixed 2026-08-21**", and M-17 recorded as "Needs no fix". The
      annotation's condition ("W0.4h closes this box") is met — backlog-
      closeout ran and marked them.*

## Verification

`bash .mi/prds/00-delivery/corrections/w0-4-s2-corrections/editor/specs/verify-all.sh`
→ 8× PASS, exit 0 (RED baseline before the work: 8× FAIL, exit 1).
`bash tests/live-bugs.sh` still exits 0 — this ticket corrects
specifications, and the live config it describes is not this repo's to edit.

## Footprint extensions used

Approved by the orchestrator, and owned by no other task in `plan.json`:
`03-editor/02-keymaps/prd.md` (R3, R7) and `03-editor/06-explorer/prd.md`
(R6). Neither R3 nor R6 nor R7 is dischargeable without them.
`03-editor/14-shift-select/prd.md` was **not** touched; spec08's gate asserts
it still carries `C 7 · U 7`, its DECLINED simplification section and R1–R8.

## Reported upward

- **Backlog addendum for L-8:** a third ungrouped autocmd site,
  `plugins/editor.lua:80`. The L-8 row was not edited here (W0.4h's file).
- **M-17 needs no fix** and its backlog row should say so — the count was
  already right. Guard against a later agent "correcting" 14 back to 13.
- **M-1's third statement** (`capabilities-nvim.md:17`, "cursor line
  permanently centered") belongs to W0.4a and was left alone.
- **R7's `14-shift-select` half** is undischarged — see R7 above.
- **No local pointer at I7/I8** from `10-treesitter`, `15-markdown-tables`
  or `07-formatting`; the epic invariant binds them, but a reader of one
  node alone must follow the epic link. One-clause follow-up.

## Out of scope
- Any file another W0.4 child owns. One writer per file is why this sweep is
      split.

## Closing note

*Closed 2026-08-21 by the orchestrator.* `specs/verify-all.sh` → 8/8 PASS,
exit 0, re-run independently from a RED baseline of 8× FAIL.
`tests/live-bugs.sh` still exits 0 — this ticket corrects specifications; the
live config they describe was not edited. R1–R7 ticked.

**The finding of the session, and it validates the rule that caught it.**
spec03 prescribed the gitsigns delete glyph **by `U+` codepoint** rather than
by pasting it, because L-10 is a codepoint lost to copy-paste
(`12-small-plugins` R1 did not *describe* the blank-sign bug — it contained an
empty backtick pair and would have made an implementer rebuild it). The
implementer then found that **U+F0DA was itself missing from spec03** — the
recommended replacement had already been lost to the same failure it was
written to fix. It emitted the character from `\uf0da` instead of pasting.
Verified independently: U+F0DA is present in `12-small-plugins/prd.md` and
**absent from `specs/spec03.md`**. A spec that had prescribed the glyph by
example would have propagated the bug a third time.

**Two of its own drafts were caught by its own verifies**, both wrap/quoting
artifacts rather than errors of understanding: a first draft of `01-options` R3
quoted the literal phrase the verify greps for while explaining that the phrase
was wrong, and `02-keymaps` R9's `<C-q>` landed on a wrapped line without
"unbound" on it. The whitespace-normalised assertions and allow-listed sweeps
caught exactly what they were designed to.

**L-8's third site confirmed by independent sweep:** ten autocmds at eight
sites, seven grouped; the three ungrouped are `treesitter.lua:31`,
`keymaps.lua:58` and `editor.lua:80`. Epic invariant I7 records *why* a
file-level `augroup` grep passes falsely — seven hits. The backlog's L-8 row
was correctly left untouched and routed upward.

**M-17 confirmed already discharged** — `find ~/.config/nvim -name '*.lua' |
wc -l` is 14 and the epic already said 14. No edit was invented; only `~680`
was tightened to the measured 683, with a negative guard so nobody "fixes" the
correct count back to 13.

`14-shift-select` untouched — still `C 7 · U 7` with its DECLINED simplification
section intact, so `decisions/shift-select-scope`'s gate stays green.

**Reported upward, not absorbed:** the L-8 backlog addendum (third site); M-17's
row should be marked needs-no-fix rather than fixed; M-1's third statement
belongs to W0.4a; **R7's `14-shift-select` half is undischarged** and needs a
one-bullet follow-up aiming that node's R7 at the L-9 decision; and
`10-treesitter`, `15-markdown-tables` and `07-formatting` carry no local
pointer at invariants I7/I8, so a reader of one node alone must follow the epic
link.

**Acceptance box deliberately open** — its second clause needs the corrections
backlog, which is [`backlog-closeout`](../backlog-closeout/prd.md)'s (W0.4h).
