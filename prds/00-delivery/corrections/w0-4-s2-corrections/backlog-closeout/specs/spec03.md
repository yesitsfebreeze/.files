verify: ""

# spec03 — the S2 live-bug sweep: L-1..L-12 (R1, R2, R3, R6)

**Goal.** Mark each `L-` row against the sibling that actually landed its fix,
add L-8's missing third site, and leave the two rows whose owner has not
landed visibly unmarked.

**Files touched — one, body only.**
- `.mi/prds/00-delivery/corrections/prd.md` — the `## S2 — bugs in the live
  config` table. **Finding cells only.** Owner cells are byte-frozen.

**RED baseline, measured before writing this spec:** `bash check03.sh` →
**21 FAIL**, exit 1.

## The rule that governs this file

**R2 outranks R1.** A row marked fixed against work that did not happen is
worse than an unmarked row, because the next reader stops looking. `check03.sh`
asserts the two unmarked rows as hard as it asserts the nine marked ones.

**Owner cells do not change.** `tests/live-bugs.sh` resolves every Owner cell
to a board node path *and* an R-number — 50 `routing:` assertions — and
`w0-4-s2-corrections/shell`'s closing note records that it kept a deliberate
`R4` gap in `04-shell/02` precisely so this resolution keeps working.
`check03.sh` pins all twelve Owner cells to the byte-exact text captured
before the sweep (`owners-L.tsv`). Everything this spec adds goes at the **end
of the Finding cell**, where `tests/live-bugs.sh` reads it only as
"non-empty".

## The disposition, row by row — measured, not assumed

| row | landed? | what to append to the Finding cell |
|---|---|---|
| L-1 | yes | `**Fixed 2026-08-21** — \`w0-4-s2-corrections/shell\` R3; \`04-shell/06-listing\` R3 now specifies \`du -sk\`.` |
| L-2 | yes | `**Fixed 2026-08-21** — \`w0-4-s2-corrections/shell\` R7. The channel already extracts the hash (\`{strip_ansi\|split: :1}\`), so the decoder's second extraction was the duplication that rotted; \`subject\` is dropped and a silent empty decode is now forbidden.` |
| L-3 | yes | `**Fixed 2026-08-21** — \`w0-4-s2-corrections/shell\` R1.` |
| L-4 | yes | `**Fixed 2026-08-21** — \`w0-4-s2-corrections/shell\` R2.` |
| L-5 | n/a | `**Accepted 2026-08-21** — accepted-with-reason by \`w0-6-live-bugs\` R2; the inventory now reads "Dead code, not live behaviour (L-5)", which \`tests/live-bugs.sh\` greps. Decision 4(b) as rewritten keeps L-5 standing on its own evidence.` |
| L-6 | yes | `**Fixed 2026-08-21** — \`w0-4-s2-corrections/editor\` R3.` |
| L-7 | yes | `**Fixed 2026-08-21** — \`w0-4-s2-corrections/editor\` R6.` |
| L-8 | yes | see below (R6 adds the third site first) |
| L-9 | **half** | `**Half open.** \`03-editor/02-keymaps\` carries the decision (\`w0-4-s2-corrections/editor\` R7), but that lane's own closing note records R7's \`03-editor/14-shift-select\` half as **undischarged**, so this row is not marked fixed.` |
| L-10 | yes | `**Fixed 2026-08-21** — \`w0-4-s2-corrections/editor\` R2; the replacement glyph is prescribed by codepoint (U+F0DA), because L-10 is a codepoint lost to copy-paste and a spec that pasted it lost it again.` |
| L-11 | **no** | nothing. Byte-unchanged. |
| L-12 | yes | `**Fixed 2026-08-21** — \`w0-4-s2-corrections/platform\` R4 — and **corrected**: five of the six files were phantoms of the stale June clone the audit read; only \`background.png\` is in the live source, and decision 5(a) drops it with the wallpaper pipeline. Recorded in \`capabilities-provisioning.md\`.` |

**L-9 is the one to get right.** `w0-4-s2-corrections/editor` R7 is `[x]`, but
its closing note says in as many words that R7's `14-shift-select` half is
undischarged. A `[x]` on a lane is not a `[x]` on every row it touches. Do not
write a completion marker here; `check03.sh` fails if `**Fixed` appears in the
row, and fails again if the word "undischarged" does not.

**L-11 is out of scope by the ticket's own text.** Its owner is
`02-terminal/03-f5-jump-mode` via `w0-2-terminal-respec`, which is `open`.
`check03.sh` compares the whole row against `row-L-11.txt`, captured before
the sweep.

**L-6 and L-9 must keep the string `Decided 2026-08-21`.**
`tests/live-bugs.sh` greps each of those two rows for it.

## R6 — L-8's third site

The row lists two ungrouped autocmd sites; `w0-4-s2-corrections/editor`'s
independent sweep found **ten autocmds at eight sites, seven grouped**, and
the three ungrouped are `plugins/treesitter.lua:31`, `config/keymaps.lua:58`
and `plugins/editor.lua:80`. Rewrite the Finding cell to name all three and to
cite the eight-site sweep — the count matters because a file-level `augroup`
grep passes falsely (seven hits), which is why the epic gave it invariant I7.

## Boxes

- [x] All twelve Owner cells are byte-identical to `owners-L.tsv`, and there
      are still exactly twelve `L-` rows.
- [x] L-8 names `plugins/treesitter.lua:31`, `config/keymaps.lua:58` and
      `plugins/editor.lua:80`, says "three", and cites the eight-site sweep.
- [x] L-1, L-2, L-3, L-4, L-6, L-7, L-8, L-10 and L-12 each carry
      `**Fixed 2026-08-21**` naming both the node and the R-number.
- [x] L-5 carries `**Accepted 2026-08-21**`, names `w0-6-live-bugs`, and
      quotes the inventory phrase the gate greps.
- [x] L-12 records the correction: five phantoms, `background.png` real, the
      stale clone named.
- [x] L-9 carries **no** `**Fixed`, names `14-shift-select`, says
      "undischarged", and keeps `Decided 2026-08-21`.
- [x] The L-11 row is byte-identical to `row-L-11.txt`.
- [x] L-6 keeps `Decided 2026-08-21`.
- [x] `tests/live-bugs.sh` 159 PASS / 0 FAIL, 40 `table:` + 50 `routing:`;
      `gates/audit-findings.sh` exit 0; Tier A broken links 0.

## Spent proof

L-5's Owner cell in `prds/00-delivery/corrections/prd.md` was rewritten by a
later backlog node; this is a don't-disturb pin on a row this node did not
own, and every assertion on its own R3 edits still passes.

Retired from `verify:` by
[`mi-rooted-verify-commands`](../../../mi-rooted-verify-commands/prd.md)
spec02. The command below is byte-identical to what spec01 left in this
file's `verify:`; it is kept because it is the execution record of a check
that once ran green.

```text
verify: `bash prds/00-delivery/corrections/w0-4-s2-corrections/backlog-closeout/specs/check03.sh`
```
