-- lua/plugins/claude.lua
-- Why this file is shaped the way it is:
--   manual → internals/neovim

return {
  {
    "coder/claudecode.nvim",
    cmd = {
      "ClaudeCode", "ClaudeCodeFocus", "ClaudeCodeSelectModel", "ClaudeCodeAdd",
      "ClaudeCodeSend", "ClaudeCodeTreeAdd", "ClaudeCodeStatus", "ClaudeCodeStart",
      "ClaudeCodeStop", "ClaudeCodeOpen", "ClaudeCodeClose", "ClaudeCodeDiffAccept",
      "ClaudeCodeDiffDeny", "ClaudeCodeCloseAllDiffs",
    },
    keys = {
      -- <leader>x is the Claude group, deliberately not <leader>a: `a` sat on the
      -- generic leader namespace, and Claude gets a solo whichkey prefix instead.
      { "<leader>x", nil, desc = "Claude" },
      { "<leader>xc", "<cmd>ClaudeCode<cr>", desc = "Toggle Claude" },
      { "<leader>xf", "<cmd>ClaudeCodeFocus<cr>", desc = "Focus Claude" },
      { "<leader>xr", "<cmd>ClaudeCode --resume<cr>", desc = "Resume Claude" },
      { "<leader>xC", "<cmd>ClaudeCode --continue<cr>", desc = "Continue Claude" },
      { "<leader>xm", "<cmd>ClaudeCodeSelectModel<cr>", desc = "Select Claude model" },
      { "<leader>xb", "<cmd>ClaudeCodeAdd %<cr>", desc = "Add current buffer" },
      { "<leader>xs", "<cmd>ClaudeCodeSend<cr>", mode = "v", desc = "Send to Claude" },
      { "<leader>xs", "<cmd>ClaudeCodeTreeAdd<cr>", desc = "Add file", ft = { "oil", "snacks_picker_list" } },
      { "<leader>xa", "<cmd>ClaudeCodeDiffAccept<cr>", desc = "Accept diff" },
      { "<leader>xd", "<cmd>ClaudeCodeDiffDeny<cr>", desc = "Deny diff" },
    },
    opts = {
      -- Spawn through cll, not the plain claude binary: the model picker runs
      -- before Claude starts, so every fresh pane opens on a chosen model —
      -- native:* hops ride the Max plan via cc's login picker, everything else
      -- goes through the litellm proxy profile. Toggling an ALREADY-RUNNING
      -- pane never re-runs the picker; only a fresh spawn does.
      terminal_cmd = "cll",
      terminal = { split_width_percentage = 0.30 },
      diff_opts = { layout = "vertical" },
    },
    dependencies = { "folke/snacks.nvim", "mr55p-dev/claude-tmux.nvim" },
    config = function(_, opts)
      local ok_provider, claude_tmux = pcall(require, "claude-tmux")
      if ok_provider and claude_tmux.is_available() then
        opts.terminal = opts.terminal or {}
        -- No split_side here, deliberately: the pane opens on the RIGHT and
        -- that is not a choice this file gets to make. claudecode's
        -- terminal.setup() ends by calling the provider's own
        -- `provider.setup(defaults)`, which force-merges claudecode's
        -- defaults table into claude-tmux's state.config — and that table
        -- carries `split_side = "right"`. Whatever this call passed would be
        -- overwritten before the first split runs, so a `split_side` key here
        -- would claim a choice that does not exist. Measured twice with
        -- different inputs (2026-09-02, real tmux, `:ClaudeCode` fired
        -- headless): `split_side = "bottom"` and no key at all both end at
        -- `right`, pane h=49 w=60 of a 200x50 client. `toggle_key` and
        -- `split_size` DO survive the same merge — claudecode's defaults hold
        -- neither key, so nothing overwrites them; the counterfactual run
        -- with `<C-y>`/`55` read back `<C-y>`/`55` and a 110-wide pane. That
        -- is the whole difference: only keys claudecode also defines are lost.
        opts.terminal.provider = claude_tmux.setup({
          toggle_key = "<C-j>", -- nvim's window-down is untouched: lands in tmux, pane-local
          split_size = 30,
        })
      end

      -- Login profile is `cll`'s job (~/.local/bin/cll:212-221 resolves the
      -- same CLAUDE_CONFIG_DIR from .last-login/.claude.json) — terminal_cmd
      -- already spawns through it, so nothing here needs to duplicate it.
      require("claudecode").setup(opts)
    end,
  },
}
