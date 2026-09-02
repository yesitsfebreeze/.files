-- lua/plugins/claude.lua
-- Why this file is shaped the way it is:
--   manual → internals/neovim

return {
  {
    "coder/claudecode.nvim",
    cmd = {
      "ClaudeCode",
      "ClaudeCodeFocus",
      "ClaudeCodeSelectModel",
      "ClaudeCodeAdd",
      "ClaudeCodeSend",
      "ClaudeCodeTreeAdd",
      "ClaudeCodeStatus",
      "ClaudeCodeStart",
      "ClaudeCodeStop",
      "ClaudeCodeOpen",
      "ClaudeCodeClose",
      "ClaudeCodeDiffAccept",
      "ClaudeCodeDiffDeny",
      "ClaudeCodeCloseAllDiffs",
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
      {
        "<leader>xs",
        "<cmd>ClaudeCodeTreeAdd<cr>",
        desc = "Add file",
        ft = { "NvimTree", "neo-tree", "oil", "minifiles", "netrw", "snacks_picker_list" },
      },
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
      terminal = {
        provider = "auto",
        split_width_percentage = 0.30,
      },
      diff_opts = {
        layout = "vertical",
      },
    },
    dependencies = {
      "folke/snacks.nvim",
      "mr55p-dev/claude-tmux.nvim",
    },
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
          toggle_key = "<C-j>", -- nvim's window-down is untouched: the binding lands in tmux, pane-local
          split_size = 30,
        })
      end

      -- Login profile. claudecode spawns the plain `claude` binary, which
      -- without CLAUDE_CONFIG_DIR lands on the default ~ profile — and the
      -- logins live in the profile dirs the `cc` picker chooses from. Resolve
      -- the same way ~/.local/bin/cll does: leave an inherited, logged-in
      -- CLAUDE_CONFIG_DIR alone; else the profile ~/.claude/.last-login names,
      -- when it is actually logged in; else nil, and default wins. Checked for
      -- '"oauthAccount"' in the profile's .claude.json — settings.json can
      -- exist in a logged-out profile (claude.nu seeds it on first pick), so
      -- the marker, not file existence, decides. Computed at first load, not
      -- per spawn: a fresh nvim after running `cc` picks up the new login.
      if opts.env == nil and vim.env.CLAUDE_CONFIG_DIR == nil then
        local root = vim.fn.expand("~/.claude")
        local function logged_in(dir)
          local f = io.open(dir .. "/.claude.json", "r")
          if not f then return false end
          local content = f:read("*a")
          f:close()
          return content ~= nil and content:find('"oauthAccount"', 1, true) ~= nil
        end
        local last_ok = false
        local lf = io.open(root .. "/.last-login", "r")
        if lf then
          local last = (lf:read("*l") or ""):gsub("^%s+", ""):gsub("%s+$", "")
          lf:close()
          if #last > 0 and last ~= "default" then
            local dir = root .. "/" .. last
            if logged_in(dir) then
              opts.env = { CLAUDE_CONFIG_DIR = dir }
              last_ok = true
            end
          end
        end
        if not last_ok and not logged_in(root) then
          -- nothing logged in anywhere the plugin can find: open default and
          -- let Claude's own login flow run, rather than point at a dead dir
          opts.env = nil
        end
      end

      require("claudecode").setup(opts)
    end,
  },
}
