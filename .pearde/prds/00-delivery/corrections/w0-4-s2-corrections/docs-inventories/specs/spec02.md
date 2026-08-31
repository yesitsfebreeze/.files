verify: `bash -c 'cd "$(git rev-parse --show-toplevel)"; f=docs/capabilities-nvim.md; rc=0; RAT() { awk "/^## /{h=\$0; sub(/^## /,\"\",h); n=0} /^- [0-9]+\$/{v[n++]=\$2} /^----/{if(n>=2) printf \"%d\t%s\n\", v[n-1]-v[n-2], h}" "$f"; }; SEC() { awk -v H="$1" "index(\$0,\"## \"H)==1{s=1;next} s&&/^## /{exit} s" "$f" | tr "\n" " " | tr -s " "; }; NUM() { awk -v H="$1" "index(\$0,\"## \"H)==1{s=1;next} s&&/^## /{exit} s&&/^- [0-9]+\$/{print \$2}" "$f" | tr "\n" " "; }; RAT | awk -F"\t" "NR>1 && \$1>p {printf \"FAIL: ratio rise — %s (%d) sits below (%d)\n\", \$2, \$1, p; r=1} {p=\$1} END{exit r+0}" || rc=1; [ "$(RAT | wc -l | tr -d " ")" = "23" ] || { echo "FAIL: entry count is not 23 (got $(RAT | wc -l | tr -d " ")) — the reorder dropped or merged an entry"; rc=1; }; HL="Options baseline|Whitespace rendering (VS Code parity)|LSP log kill-switch|Core keymaps|Load order + filetype registration|Editor autocmds|lazy.nvim bootstrap and plugin loading|Colorscheme + mode-aware cursor|Treesitter|Completion (blink.cmp)|LSP (mason + native 0.11)|Fuzzy finder (telescope)|File explorer (oil.nvim)|Statusline (lualine)|Format on save (conform.nvim)|Git signs|which-key|Autopairs|Shift-to-select (editor-style selection)  SIMPLIFY|Markdown table mode|Smear cursor  DEFER|mini.nvim plugin set (from capabilities.md)  DO NOT PORT|Insert-mode-first modal inversion  DO NOT PORT"; OIFS=$IFS; IFS="|"; for h in $HL; do IFS=$OIFS; grep -qF "## $h" "$f" || { echo "FAIL: entry vanished in the reorder: $h"; rc=1; }; IFS="|"; done; IFS=$OIFS; [ "$(NUM "Shift-to-select (editor-style selection)")" = "7 7 " ] || { echo "FAIL: shift-select is no longer C 7 / U 7 — that reddens decisions/shift-select-scope and 03-editor/14"; rc=1; }; M=$(SEC "mini.nvim plugin set (from capabilities.md)"); for s in "Neovim: self-bootstrapping config" "C 5" "U 8" "supersed" "docs-inventories"; do echo "$M" | grep -qF "$s" || { echo "FAIL: mini.nvim entry does not reconcile capabilities.md — missing: $s"; rc=1; }; done; [ "$(NUM "mini.nvim plugin set (from capabilities.md)")" = "5 2 " ] || { echo "FAIL: mini.nvim entry re-rated; reconciling is cross-linking, not re-scoring"; rc=1; }; I=$(SEC "Insert-mode-first modal inversion"); for s in "Neovim: insert-mode-first modal inversion" "U 6"; do echo "$I" | grep -qF "$s" || { echo "FAIL: insert-mode entry does not name its capabilities.md twin — missing: $s"; rc=1; }; done; [ "$(NUM "Insert-mode-first modal inversion")" = "8 2 " ] || { echo "FAIL: insert-mode entry re-rated"; rc=1; }; H=$(awk "/^## /{exit} {print}" "$f" | tr "\n" " " | tr -s " "); for s in "different, newer config" "capabilities.md" "lazy.nvim"; do echo "$H" | grep -qF "$s" || { echo "FAIL: the IMPORTANT header note lost: $s"; rc=1; }; done; SEC "Core keymaps" | grep -qF "L-6" || { echo "FAIL: the L-6 record was lost in the reorder"; rc=1; }; SEC "File explorer (oil.nvim)" | grep -qF "L-7" || { echo "FAIL: the L-7 record was lost in the reorder"; rc=1; }; SEC "Shift-to-select (editor-style selection)" | grep -qF "L-9" || { echo "FAIL: the L-9 record was lost in the reorder"; rc=1; }; [ $rc -eq 0 ] && echo OK; exit $rc'`

est: 25m

# spec02 — `capabilities-nvim.md`: sort, and reconcile the two double-rated entries

Goal: land R3's nvim half and R4's in-footprint half. R4's other half — the
missing marker in `capabilities.md` — is blocked by R1 and is a Question, not
a box here.

Files: `.mi/docs/capabilities-nvim.md` — and nothing else.

**The verify was proven RED on 2026-08-21** against the current file: seven
ratio rises, five missing mini.nvim reconciliation assertions and two missing
insert-mode assertions. The guards — 23 entries, all 23 headings present,
shift-select still 7 / 7, mini.nvim still 5 / 2, insert-mode still 8 / 2, the
IMPORTANT header note, the L-6 / L-7 / L-9 records — pass now and must still
pass after.

## What is wrong now

**R3 undercounts.** The backlog and R3 both say "four rises". Measured, there
are **seven**: LSP log kill-switch (6 below 5) · Core keymaps (7 below 6) ·
Completion (5 below 3) · Fuzzy finder (4 below 3) · File explorer (6 below 4)
· Format on save (5 below 1) · Markdown table mode (2 below 0). The fix is a
full descending sort, so the stale count changes nothing about the work — but
say so in the commit rather than leaving a reader to wonder which four.

Current ratios in file order:
`7 5 6 7 5 5 5 3 3 5 3 4 6 1 5 5 5 5 0 2 1 -3 -6`.

## Boxes

- [ ] **B1 — the file is sorted descending by (usefulness − complexity), ties
      broken by existing file order.** That is exactly this sequence, and no
      other:

      7  Options baseline
      7  Core keymaps
      6  LSP log kill-switch
      6  File explorer (oil.nvim)
      5  Whitespace rendering (VS Code parity)
      5  Load order + filetype registration
      5  Editor autocmds
      5  lazy.nvim bootstrap and plugin loading
      5  Completion (blink.cmp)
      5  Format on save (conform.nvim)
      5  Git signs
      5  which-key
      5  Autopairs
      4  Fuzzy finder (telescope)
      3  Colorscheme + mode-aware cursor
      3  Treesitter
      3  LSP (mason + native 0.11)
      2  Markdown table mode
      1  Statusline (lualine)
      1  Smear cursor  DEFER
      0  Shift-to-select (editor-style selection)  SIMPLIFY
      -3 mini.nvim plugin set (from capabilities.md)  DO NOT PORT
      -6 Insert-mode-first modal inversion  DO NOT PORT

      Move each entry whole — heading, every bullet, both rating lines, its
      `----`. Nothing is re-worded and nothing is re-rated.
- [ ] **B2 — the marked tail is not force-grouped.** `Smear cursor` (`DEFER`,
      ratio 1) legitimately lands **above** `Shift-to-select` (`SIMPLIFY`,
      ratio 0). The sort key is the ratio; the marker is not a sort key.
      Provisioning's tail happens to group by marker, which is a coincidence
      of its numbers, not a rule to import here.
- [ ] **B3 — nothing is lost in the move.** 23 entries before, 23 after; every
      heading string unchanged; every C/U pair byte-identical; the L-6, L-7
      and L-9 resolution records still inside their own entries.
- [ ] **B4 — shift-select is untouched.** `## Shift-to-select (editor-style
      selection)  SIMPLIFY` keeps its heading, its marker and 7 / 7.
      `decisions/shift-select-scope` closed on "full port with tests" and its
      verify asserts these numbers by name; `03-editor/14`'s header cites
      them too. Its prose still says "port it deliberately, with tests, or
      accept plain Shift+arrow selection" — that fork **is** now settled, but
      the decision node re-checked the inventory and recorded it as
      deliberately unchanged, so rewording it is not this node's move.
- [ ] **B5 — the mini.nvim entry reconciles its `capabilities.md` twin
      (R4).** Add bullets to `## mini.nvim plugin set (from capabilities.md)
      DO NOT PORT` that make the double rating legible instead of
      contradictory. They must carry: that it rates the same capability as
      `capabilities.md`'s `"Neovim: self-bootstrapping config"`, quoted by
      name, with that entry's **C 5 / U 8** and the fact that it carries **no
      marker**; that this entry is the verdict of record — `DO NOT PORT`,
      superseded by the live lazy.nvim config, with oil + lualine + devicons
      the only parts kept and the live config already having them; and why
      the two U numbers differ and which binds — U 8 rates the capability in
      its own era against no alternative, U 2 rates it against the live
      baseline that replaces it, so a PRD sourcing it takes **C 5 / U 2**.
      Finally, name what is still open: the missing marker on the
      `capabilities.md` side needs the author's confirmation, so point at the
      `## Questions` on
      `00-delivery/corrections/w0-4-s2-corrections/docs-inventories`.
- [ ] **B6 — the same treatment for the second double-rated entry.**
      `## Insert-mode-first modal inversion  DO NOT PORT` (8 / 2) is a second
      rating of `capabilities.md`'s `"Neovim: insert-mode-first modal
      inversion"` (**C 8 / U 6**), and the file already half-admits it
      ("Already marked DO NOT PORT in `capabilities.md`"). Name that entry
      with its numbers and say which binds, in one added clause. This one
      needs no confirmation — both sides already carry `DO NOT PORT`, so only
      the U divergence is unexplained.
- [ ] **B7 — no new rating is invented and no existing one moved.** R4 says
      *reconcile*, which is cross-linking and explanation. Collapsing the two
      entries into one, or averaging their U, would break `03-editor/prd.md`'s
      non-goals list and the README's Neovim exclusion, both of which cite
      them separately.

## Out of scope

- `capabilities.md`'s missing `DO NOT PORT` marker — R1; Question 5.
- `03-editor/*` PRDs — W0.4c owns them.
- Rewording the shift-select prose (B4) or any live-bug record.
