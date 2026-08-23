-- Git hunk signs in the sign column, lazy on the two file-opening events.
--
-- THE GLYPHS ARE THE WHOLE SUBJECT OF THIS FILE, and they carry their
-- codepoints in this comment on purpose. Live bug L-10 is a codepoint lost to
-- copy-paste: the live spec writes `delete` and `topdelete` as literally
-- `text = ""`, so a deleted hunk gets a blank sign cell. A `U+` number beside
-- the character is what lets a reader tell an empty string from a glyph their
-- editor cannot draw.
--
--   add, change, changedelete   U+258E  LEFT ONE QUARTER BLOCK
--   delete, topdelete           U+F0DA  nf-fa-caret_right
--
-- Four measured facts, each because rediscovering it costs a debugging round.
--
-- 1. L-10 FAILS SILENTLY, NOT LOUDLY. Measured 2026-08-23 against a scratch
--    git repo with a deleted line: with `delete`'s value emptied, gitsigns
--    still places the extmark — `sign_hl_group = GitSignsDelete`,
--    `sign_text = nil` — so the cell renders blank and nothing errors. A
--    deleted hunk is the one hunk kind with no line of its own to colour, so
--    blank means invisible. A readback of the config value catches an empty
--    string and nothing else; tests/nvim-small-plugins.sh reads the
--    `gitsigns_signs_` extmarks, which is the half that catches a value that
--    reads back fine and paints nothing.
-- 2. THE TWO GLYPH FAMILIES MUST NOT COLLAPSE. U+258E is drawn by WezTerm
--    itself (`custom_block_glyphs = true`, measured via `wezterm ls-fonts`);
--    U+F0DA comes from CaskaydiaCove Nerd Font. If the delete glyph ever
--    equalled the add/change glyph, a deleted hunk would be
--    indistinguishable from a changed one — the readable half of L-10's bug,
--    and a check asserting only "non-empty" would pass it.
-- 3. GITSIGNS SHELLS OUT TO `git`. Measured with a `git` stub exiting 127:
--    gitsigns does not attach, places no sign, prints nothing, and the
--    session still exits 0. `git=git` is in install.sh's PKGS, and that is
--    what keeps the silent failure off a fresh machine. Do not assume the
--    attach is unconditional.
-- 4. `BufNewFile` IS NOT DECORATION. Opening a path that does not exist yet
--    inside a git worktree loads gitsigns (measured), which is why both
--    events are named and not just `BufReadPre`.
--
-- The fallback the PRD sanctions — `_` (U+005F) for delete and `‾` (U+203E)
-- for topdelete, which additionally keep a below/above distinction — is NOT
-- taken here, and its condition was measured false rather than assumed:
-- `wezterm ls-fonts --text` resolves U+F0DA to `glyph=fa-caret_right` out of
-- CaskaydiaCoveNerdFont-Regular.ttf at `cells=1`, and WezTerm additionally
-- ships a built-in Symbols Nerd Font Mono that covers it even with the cask
-- absent. The gate accepts either set, so taking the fallback stays a
-- two-character change here with no gate edit.
return {
  "lewis6991/gitsigns.nvim",
  event = { "BufReadPre", "BufNewFile" },
  opts = {
    signs = {
      add = { text = "▎" },
      change = { text = "▎" },
      delete = { text = "" },
      topdelete = { text = "" },
      changedelete = { text = "▎" },
    },
  },
}
