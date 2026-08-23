# spec03 — L-10: restore the gitsigns delete glyph instead of porting the hole

est: 0.3h

Closes ticket **R2**.

## Goal

Live bug L-10. `~/.config/nvim/lua/plugins/editor.lua:12–13` are literally:

```lua
delete    = { text = "" },
topdelete = { text = "" },
```

against `▎` (U+258E, LEFT ONE EIGHTH BLOCK) on `add`, `change` and
`changedelete`. A nerd-font codepoint was lost in transit at some point, and
the result is that a deleted hunk gets a blank sign cell — the one hunk kind
you cannot see any other way, since a deletion leaves no line to colour.

The ticket says "both documents describe them as glyphs". For
`capabilities-nvim.md` that is exactly right, and it is
`w0-4-s2-corrections/docs-inventories` (W0.4a)'s to fix — its "Git signs"
entry reads "custom `▎` add/change/delete glyphs".

**For this node's PRD it is worse than the ticket says.** `12-small-plugins`
R1 does not *describe* a glyph; it *reproduces the empty string*. Hexdumped
2026-08-21, R1's bytes are:

```
… custom glyphs: `<e2 96 8e>` for add/change/changedelete, `` for
delete/topdelete.
```

Two backticks with nothing between them. The spec inherited the bug verbatim,
so an implementer following it faithfully would rebuild the blank sign and
every acceptance check would pass. That is the precise failure mode this whole
sweep exists to stop.

## Why the requirement names a codepoint number

The bug is *a character that did not survive being copied*. Writing the
replacement glyph as a pasted character and nothing else re-arms exactly the
same trap for the next transcription. So R1 states the codepoint by `U+`
number as well as pasting it, and the binding property is stated
independently of any particular character: **non-empty, a single codepoint,
and visually distinct from the `▎` used for add/change.** Any implementer who
finds the recommended glyph does not render can satisfy the requirement with
the fallback without re-opening the spec.

Recommended value and its provenance, stated as a recommendation because it
rests on lineage rather than measurement: this config's sign block (`▎` on
add/change/changedelete, the `map` helper, `last_loc`, `close_with_q`) is
LazyVim-derived, and LazyVim's gitsigns block uses a nerd-font caret,
`` (U+F0DA, `nf-fa-caret_right`), for both `delete` and `topdelete`.
**Confirm it renders in the terminal font before committing** — the host font
is CaskaydiaCove Nerd Font per the terminal inventory's T-1, which carries
the Font Awesome range, but that is an inference and not a check that has
been run.

Font-free fallback, and it is a real option rather than a formality:
gitsigns' own upstream defaults, `_` for `delete` and `‾` (U+203E, OVERLINE)
for `topdelete`. They need no nerd font, they are distinct from `▎`, and they
carry the deletion-above / deletion-below distinction that a single caret on
both signs throws away.

## Files touched

- `.mi/prds/03-editor/12-small-plugins/prd.md` — R1 and one acceptance line.

**Do not edit the frontmatter.** Not touched: `.mi/docs/capabilities-nvim.md`
(W0.4a's, concurrent), `.mi/prds/00-delivery/corrections/prd.md` (W0.6's, and
`tests/live-bugs.sh` pins the L-10 row's contents — the live config still has
the empty strings and the row stays true).

Note for the reader of the gate: `tests/live-bugs.sh` asserts that
`delete`'s sign text in `~/.config/nvim` is zero bytes. That is a statement
about the **live** config, which this spec does not change. It stays green.

## What to write

Replace R1, keeping the number:

> - [ ] **R1** — **gitsigns.** `lewis6991/gitsigns.nvim`, lazy on
>       `BufReadPre`/`BufNewFile`. Signs: `▎` (U+258E) for add, change and
>       changedelete; for delete and topdelete, a **non-empty single-codepoint
>       glyph distinct from `▎`** — recommended `` (U+F0DA,
>       `nf-fa-caret_right`), the character LazyVim's gitsigns block uses and
>       the lineage this sign set came from; fallback, if that does not render
>       in the terminal font, gitsigns' own defaults `_` (delete) and `‾`
>       (U+203E, topdelete), which additionally keep the below/above
>       distinction. **Live bug L-10, do not reproduce:** both are literally
>       `text = ""` live (`lua/plugins/editor.lua:12–13`), so a deleted hunk
>       gets a blank sign cell — the one hunk kind with no line of its own to
>       colour, hence invisible. The codepoint is written as a `U+` number
>       and not only as a pasted character because a character lost in
>       copy-paste is how the bug happened.

Add one acceptance line:

> - [ ] Delete a line in a tracked file and write: the sign cell for the
>       deleted hunk is not blank, and the glyph is not the `▎` used for
>       add/change. Read it back from the config rather than by eye —
>       `:lua =require("gitsigns.config").config.signs.delete.text` must
>       return a non-empty string.

The existing acceptance line "Edit a tracked file: change signs appear in the
sign column" stays: it covers add/change, which were never broken.

## Acceptance

- [ ] R1 contains no empty backtick pair (` `` `) anywhere.
- [ ] R1 names L-10 and says the empty strings are not to be reproduced.
- [ ] R1 states the binding property — non-empty, distinct from `▎`.
- [ ] R1 names at least one glyph by `U+` codepoint for delete/topdelete.
- [ ] R1 names a fallback that needs no nerd font.
- [ ] R1 still names the plugin and its `BufReadPre`/`BufNewFile` lazy event.
- [ ] There is an acceptance line asserting the delete sign is non-blank, and
      it names a way to read the value back rather than "looks right".
- [ ] R2 and R3 keep their numbers and text.
- [ ] Every box in the file is still open — no `[x]`, no `[~]`.
- [ ] `bash tests/live-bugs.sh` still exits 0 (this spec changes no live
      config, so the L-10 assertions must not move).

verify: `bash -c 'cd "$(git rev-parse --show-toplevel)"; rc=0; F=prds/03-editor/12-small-plugins/prd.md; r1=$(awk "/\*\*R1\*\*/{r=1} r&&/^- \[.\] \*\*R[0-9]/&&!/R1/{r=0} r&&/^## /{r=0} r" "$F" | tr "\n" " " | tr -s " "); [ -n "$r1" ] || { echo "FAIL: no R1 found"; rc=1; }; bt=$(printf "\140\140"); printf "%s" "$r1" | grep -qF "$bt" && { echo "FAIL: R1 still carries an empty backtick pair - the bug is still copied into the spec"; rc=1; }; printf "%s" "$r1" | grep -qF "L-10" || { echo "FAIL: R1 does not name L-10"; rc=1; }; printf "%s" "$r1" | grep -qE "not.{0,20}reproduce|do not reproduce" || { echo "FAIL: R1 does not say the loss is not reproduced"; rc=1; }; printf "%s" "$r1" | grep -qE "non-empty" || { echo "FAIL: R1 does not state the non-empty property"; rc=1; }; printf "%s" "$r1" | grep -qE "distinct" || { echo "FAIL: R1 does not require the delete glyph to differ from the add/change glyph"; rc=1; }; [ "$(printf "%s" "$r1" | grep -oE "U\+[0-9A-Fa-f]{4}" | sort -u | wc -l | tr -d " ")" -ge 2 ] || { echo "FAIL: R1 names fewer than two glyphs by U+ codepoint"; rc=1; }; printf "%s" "$r1" | grep -qE "fallback" || { echo "FAIL: R1 offers no font-free fallback"; rc=1; }; printf "%s" "$r1" | grep -qF "lewis6991/gitsigns.nvim" || { echo "FAIL: R1 lost the plugin name"; rc=1; }; printf "%s" "$r1" | grep -qF "BufReadPre" || { echo "FAIL: R1 lost the lazy event"; rc=1; }; acc=$(awk "/^## Acceptance/{r=1;next} r&&/^## /{r=0} r" "$F" | tr "\n" " " | tr -s " "); printf "%s" "$acc" | grep -qE "not blank|non-empty|not be blank" || { echo "FAIL: no acceptance line asserts the delete sign is non-blank"; rc=1; }; printf "%s" "$acc" | grep -qE "gitsigns.config|:lua|read it back|Read it back" || { echo "FAIL: the delete-sign acceptance is by eye, with no way to read the value back"; rc=1; }; for i in 2 3; do printf "%s" "$(tr "\n" " " < "$F")" | grep -qF "**R$i**" || { echo "FAIL: lost R$i"; rc=1; }; done; grep -qE "^- \[[x~]\]" "$F" && { echo "FAIL: a box was closed"; rc=1; }; bash tests/live-bugs.sh >/dev/null 2>&1 || { echo "FAIL: tests/live-bugs.sh no longer exits 0"; rc=1; }; [ $rc -eq 0 ] && echo OK; exit $rc'`

**Proven RED against the current tree before this spec was written**, run
verbatim as the string above. It reports, in order: R1 still carries an empty
backtick pair; R1 does not name L-10; does not say the loss is not reproduced;
does not state the non-empty property; does not require distinctness; names
fewer than two `U+` codepoints; offers no fallback; no acceptance line asserts
the delete sign is non-blank; and the delete-sign acceptance is by eye.
Exit 1.

The clauses that pass today — plugin name, `BufReadPre`, R2/R3 present, boxes
open, `tests/live-bugs.sh` green — are regression guards. The last one matters
most: it is the check that catches an implementer who "fixes" L-10 by editing
`~/.config/nvim` instead of the PRD. This node corrects a specification; the
live config is not this repo's to edit.

The empty-backtick clause builds its pattern with `bt=$(printf "\140\140")`
rather than writing two literal backticks, because a backtick inside a
`bash -c` script is command substitution and not a literal — a sibling spec
lost three clauses to exactly that this session. `\x60` does **not** work
either: `grep -F` takes it as the four characters `\x60`, so the clause
silently never fires. That was the first draft here, and it passed on a file
that plainly contains the pair; octal-through-`printf` is what actually
matches.
