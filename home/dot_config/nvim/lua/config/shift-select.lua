-- Editor-style "shift to select" (task E.14). A port of the live block at
-- ~/.config/nvim/lua/config/keymaps.lua, verbatim in behaviour except for the
-- augroup noted below.
--
-- WHY THIS IS ITS OWN MODULE and not lua/config/keymaps.lua, where the rest
-- of the general maps live: tests/nvim-keymaps.sh — 02-keymaps' committed
-- gate — asserts PER CALL SITE that keymaps.lua contains no shift_select
-- machinery, no <S-arrow> map, zero autocmds (epic invariant I7, live bug
-- L-8) and no map on the clipboard keys, each with a selftest that plants
-- exactly this code. Appending this block there would turn a landed node's
-- gate red by construction. 02-keymaps leaves the clipboard keys and the
-- blockwise-visual escape hatch unbound on purpose so this file can take
-- them; its own file comment says why.
--
-- The system clipboard is shared (clipboard=unnamedplus, from 01-options), so
-- copy and paste cross between nvim and the terminal.
--
-- Entering visual mode via Shift+<arrow> (or starting a selection from
-- insert) sets a flag. While that flag is set, a plain motion (h/j/k/l or an
-- unshifted arrow) collapses the selection and returns to normal mode, just
-- like a conventional editor. Holding Shift keeps extending the selection. A
-- selection started the vim way (plain `v`) is unaffected and extends on
-- motion as usual.
--
-- COUNTS, settled 2026-08-24 (finding M-2 resolved: the acceptance criteria
-- were the thing that was off by one, not these mappings). The selection is
-- charwise-INCLUSIVE, so one <S-Right> selects two characters -- `kl` with
-- the cursor on `k` -- and two presses select three. From insert, <S-Left>
-- catches the last two characters rather than one: the insert caret sits
-- BETWEEN characters and leaving insert drops the cursor onto the one behind,
-- which every shift map out of insert has to correct for, in opposite
-- directions. <S-Right> therefore feeds an extra `l` before entering visual,
-- or the character under the cursor is left out; leftward there is nothing to
-- correct, and the extra character is the price. <S-Up>/<S-Down> stay
-- charwise-inclusive either way, which is why no mapping change reaches this.
local map = vim.keymap.set

local shift_select = false

-- The ONE feeding helper (R8): every map below goes through it, so there are
-- no scattered <cmd> strings and one place where termcodes are resolved.
local function feed(keys)
  vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(keys, true, false, true), "n", false)
end

-- Reset the flag whenever we leave visual mode, so a later `v` selection
-- keeps normal extend-on-motion behaviour.
--
-- GROUPED, which is the one deliberate deviation from the live block: the
-- live site is ungrouped (live bug L-8, named by epic invariant I7), so every
-- re-source of the module stacks another identical callback on ModeChanged --
-- an event that fires on every mode transition. `clear = true` makes a reload
-- idempotent instead of cumulative.
vim.api.nvim_create_autocmd("ModeChanged", {
  group = vim.api.nvim_create_augroup("shift_select", { clear = true }),
  pattern = "*:*",
  callback = function()
    if vim.v.event.old_mode:find("^[vV\22]") then
      shift_select = false
    end
  end,
})

-- Start a selection from normal mode.
local function select_start(motion)
  return function()
    shift_select = true
    feed("v" .. motion)
  end
end

-- Extend a selection (Shift held) from visual mode.
local function select_extend(motion)
  return function()
    shift_select = true
    feed(motion)
  end
end

-- Start a selection from insert mode.
local function select_start_insert(keys)
  return function()
    shift_select = true
    feed("<Esc>" .. keys)
  end
end

-- Plain motion in visual mode: collapse + leave when we got here via Shift,
-- otherwise behave like a normal visual-mode motion. The count is preserved
-- in BOTH branches -- `3j` collapses and goes down three lines, and in a
-- `v`-started selection it extends by three, exactly as stock vim does.
local function visual_motion(motion)
  return function()
    local count = vim.v.count > 0 and tostring(vim.v.count) or ""
    if shift_select then
      shift_select = false
      feed("<Esc>" .. count .. motion)
    else
      feed(count .. motion)
    end
  end
end

map("n", "<S-Up>", select_start("<Up>"), { desc = "Select up" })
map("n", "<S-Down>", select_start("<Down>"), { desc = "Select down" })
map("n", "<S-Left>", select_start("<Left>"), { desc = "Select left" })
map("n", "<S-Right>", select_start("<Right>"), { desc = "Select right" })

map("v", "<S-Up>", select_extend("<Up>"), { desc = "Extend selection up" })
map("v", "<S-Down>", select_extend("<Down>"), { desc = "Extend selection down" })
map("v", "<S-Left>", select_extend("<Left>"), { desc = "Extend selection left" })
map("v", "<S-Right>", select_extend("<Right>"), { desc = "Extend selection right" })

-- The eight collapse-on-motion maps are written out one per line rather than
-- generated in a loop, as the live block does: the gate asserts the exact
-- number of map call sites and reads each mode/lhs/desc triple out of this
-- file, and a loop hides both from a text check.
map("v", "h", visual_motion("h"), { desc = "Move (collapse selection)" })
map("v", "j", visual_motion("j"), { desc = "Move (collapse selection)" })
map("v", "k", visual_motion("k"), { desc = "Move (collapse selection)" })
map("v", "l", visual_motion("l"), { desc = "Move (collapse selection)" })
map("v", "<Up>", visual_motion("<Up>"), { desc = "Move (collapse selection)" })
map("v", "<Down>", visual_motion("<Down>"), { desc = "Move (collapse selection)" })
map("v", "<Left>", visual_motion("<Left>"), { desc = "Move (collapse selection)" })
map("v", "<Right>", visual_motion("<Right>"), { desc = "Move (collapse selection)" })

map("i", "<S-Up>", select_start_insert("v<Up>"), { desc = "Select up" })
map("i", "<S-Down>", select_start_insert("v<Down>"), { desc = "Select down" })
map("i", "<S-Left>", select_start_insert("v<Left>"), { desc = "Select left" })
-- The extra `l` (R5) is the insert-caret correction described in the header:
-- without it the character under the insert cursor is left out.
map("i", "<S-Right>", select_start_insert("lv<Right>"), { desc = "Select right" })

-- Ctrl+C copies the selection to the shared clipboard and leaves visual mode;
-- Ctrl+V pastes over the selection without clobbering the register -- the
-- black-hole delete is what keeps the copied text pasteable a second time.
map("v", "<C-c>", "y", { desc = "Copy to clipboard" })
map("v", "<C-v>", [["_dP]], { desc = "Paste over selection" })
