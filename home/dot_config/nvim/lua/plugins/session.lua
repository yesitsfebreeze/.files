-- Session persistence: Neovim writes the open buffer set on exit and
-- restores it on demand, so tmux-resurrect has something to bring back
-- after a reboot rather than an empty editor in the right directory.
-- Owned by 07-multiplexer/06-nvim-session (epic Q12, Q13).
--
-- WHY persistence.nvim AND NOT auto-session — the choice was delegated to
-- the analyst and the PRD's framing of it does not survive reading either
-- plugin (both measured 2026-08-29, at the commits below):
--
--   * The PRD calls auto-session "branch-aware" and the one that "brings a
--     picker", as if persistence.nvim were neither. persistence.nvim is
--     branch-aware by default (config.lua `branch = true`, appended to the
--     session name as `%%<branch>`) and ships `require("persistence").select()`,
--     a picker over `vim.ui.select`. Neither is a distinguishing property.
--   * What actually separates them is size and WHEN THEY RESTORE.
--     persistence.nvim is 180 lines in two files; auto-session is 4213
--     lines across a package. persistence.nvim restores only when asked;
--     auto-session's `auto_restore` fires on every bare `nvim` started in a
--     directory it has a session for. That second behaviour reaches past
--     this node's contract into ordinary editing — opening `nvim` by hand
--     in a project would silently reopen an old buffer set — and this node
--     is not licensed to change that.
--   * I2 ("lean on built-ins, add only what is missing") and I3 ("one
--     plugin per concern") both point the same way: `:mksession` is the
--     built-in, and the only thing missing from it is a place to put the
--     file and a hook to write it. That is the whole of persistence.nvim.
--
-- WHY NOT A BARE `Session.vim` AUTOCMD (the Q13 answer that was not taken).
-- tmux-resurrect's `@resurrect-strategy-nvim 'session'` restores with
-- `nvim -S` only when a literal `Session.vim` exists in the pane's cwd
-- (strategies/nvim_session.sh, read 2026-08-29), which would mean writing
-- an untracked file into every working tree the editor was ever opened in.
-- resurrect's *inline strategy* takes a custom restore command instead —
-- `@resurrect-processes '"~nvim->nvim -c \"lua require(\\\"persistence\\\").load()\""'`,
-- split on the `->` token in scripts/process_restore_helpers.sh — so the
-- session file stays in the state directory where it belongs. That option
-- string is this node's published interface; 07-persistence owns the file
-- it goes in and must not invent a different one.
--
-- WHY `need = 1` IS KEPT AT ITS DEFAULT, not lowered to 0: a pane where
-- nvim was opened and closed without a file must not overwrite a real
-- session for that directory with an empty one. The default counts named,
-- ordinary-buftype buffers and declines to save below the threshold.
--
-- WHY THE KEYS ARE UNDER `<leader>s` AND NOT `<leader>q` (the prefix every
-- persistence.nvim README uses). `<leader>q` is already a LEAF map in this
-- config — `lua/config/keymaps.lua`, desc "Quit" — so binding `<leader>qs`
-- would turn it into a prefix and make every quit wait `timeoutlen` for a
-- second key that usually never comes. `<leader>s` is unbound (swept
-- 2026-08-29: the config binds -, |, b, bd, c, ca, cf, e, f, fb, ff, fg,
-- fh, p, q, r, rn, t, tt, w and nothing on s), so session takes it and
-- which-key gains a `session` group beside find/buffer/code/
-- rename-refactor/table.
--
-- `lazy = false` for the same reason 06-explorer gives: the save autocmd
-- has to be registered before the user's first action, and a spec carrying
-- `keys` would otherwise override `defaults = { lazy = false }` in
-- lua/config/lazy.lua and load only on the keypress — by which time an
-- exit could already have happened unsaved.
return {
  "folke/persistence.nvim",
  lazy = false,
  opts = {},
  keys = {
    { "<leader>ss", function() require("persistence").load() end, desc = "Restore session for this directory" },
    { "<leader>sl", function() require("persistence").load({ last = true }) end, desc = "Restore last session" },
    { "<leader>sd", function() require("persistence").stop() end, desc = "Stop session save on exit" },
  },
}
