# Feature: Shift-to-select (SIMPLIFY)

Parent: [Neovim epic](00-epic.md) · C 7 · U 7 · source: "Shift-to-select" in
capabilities-nvim.md · verdict: port deliberately, with tests

## Summary

The signature customization: Shift+arrows select like a conventional editor —
including the part most vim configs get wrong, where a plain motion after a
shift-selection *collapses* the selection instead of extending it. A
`v`-started selection keeps full vim semantics.

This is the most intricate hand-rolled logic in the config (~60 lines of mode
feeding and flag tracking). It earns its place, but it is the one feature
worth either porting with tests or consciously downgrading to plain
Shift+arrow selection.

## Requirements

1. **Premise.** `clipboard=unnamedplus` from
   [01-options](01-options.md) — the system clipboard is shared, so copy and
   paste cross between Neovim and the terminal.
2. **State flag.** A `shift_select` boolean, set whenever a selection begins
   via Shift (from normal, visual, or insert mode), and reset by a
   `ModeChanged` autocmd whenever visual mode is left (old mode matching
   `^[vV\22]`). Without that reset, a later plain `v` selection would
   inherit collapse-on-motion behavior.
3. **Start from normal.** `<S-Up/Down/Left/Right>` → enter visual and apply
   the motion.
4. **Extend from visual.** `<S-arrows>` keep extending (flag stays set).
5. **Start from insert.** `<S-arrows>` leave insert and start the selection;
   `<S-Right>` needs an extra `l` first so the character under the insert
   cursor is included.
6. **Collapse on plain motion.** In visual mode, `h`/`j`/`k`/`l` and the
   unshifted arrows: if `shift_select` is set, clear it, leave visual, and
   apply the motion; otherwise apply the motion normally. Counts must be
   preserved in both branches (`vim.v.count`).
7. **Clipboard keys.** Visual `<C-c>` → `y` (to the shared clipboard, leaving
   visual); visual `<C-v>` → `"_dP` (paste over the selection without
   clobbering the register).
8. **Feeding helper.** All of the above go through one
   `nvim_feedkeys` + `nvim_replace_termcodes` helper — not scattered
   `<cmd>` strings.

## Acceptance criteria

- From normal: `<S-Right><S-Right>` selects two characters; pressing `l`
  then leaves visual and moves right one (selection gone).
- From `v`: pressing `l` extends the selection, as in stock vim.
- From insert: `<S-Left>` selects the character just typed.
- `3j` in a shift-started selection collapses and moves three lines.
- `<C-c>` in visual copies to the system clipboard (pasteable in the
  terminal); `<C-v>` over a selection replaces it and the clipboard still
  holds the original copy.

## Simplification option

If the tests prove burdensome: keep only Shift+arrow selection and the
clipboard keys, and drop the collapse-on-motion behavior (rating would fall
to roughly C 3 / U 5). Record the decision here if taken.
