-- telescope.nvim — fuzzy finder. Replaces finder.nvim.
-- Multiselect: <Tab>/<S-Tab> toggle marks. <CR> opens a single entry, but when
-- entries are marked it sends them all to the quickfix list and opens it.
--
-- This is the EDITOR's finder, and it is the only one here. The shell has its
-- own, and AGENTS.md settles that the two are deliberately separate tools
-- (prds/04-shell/04-television) — nothing in this file reaches for the shell's.
return {
  "nvim-telescope/telescope.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim",
    { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
  },
  cmd = "Telescope",
  keys = {
    { "<leader>ff", "<cmd>Telescope find_files<CR>", desc = "Find files" },
    { "<leader><space>", "<cmd>Telescope find_files<CR>", desc = "Find files" },
    { "<leader>fg", "<cmd>Telescope live_grep<CR>", desc = "Live grep" },
    { "<leader>fb", "<cmd>Telescope buffers<CR>", desc = "Buffers" },
    { "<leader>fh", "<cmd>Telescope help_tags<CR>", desc = "Help tags" },
  },
  config = function()
    local telescope = require("telescope")
    local actions = require("telescope.actions")
    local action_state = require("telescope.actions.state")

    -- <CR>: when entries are marked, send them all to the quickfix list and
    -- open it; otherwise behave like a normal single-entry open.
    local function multi_or_select(prompt_bufnr)
      local picker = action_state.get_current_picker(prompt_bufnr)
      if #picker:get_multi_selection() > 0 then
        actions.send_selected_to_qflist(prompt_bufnr)
        actions.open_qflist(prompt_bufnr)
      else
        actions.select_default(prompt_bufnr)
      end
    end

    -- Same marks/move bindings in insert and normal mode (read-only config,
    -- so both modes can share one table).
    local maps = {
      ["<CR>"] = multi_or_select,
      -- The two rows below RESTATE telescope's own defaults: its
      -- mappings.lua:167 (insert) and :201 (normal) bind the identical
      -- toggle_selection + move_selection_* pair. Measured 2026-08-23 —
      -- deleting both leaves the mark-to-quickfix flow byte-for-byte
      -- identical, so no behavioural check can ever defend them and no
      -- counterfactual on them can go red. They are kept explicit on
      -- purpose: an upstream default change must not be able to move this
      -- environment's marks silently, and the manual documents them as our
      -- flow. Only <CR> above is ours.
      ["<Tab>"] = actions.toggle_selection + actions.move_selection_worse,
      ["<S-Tab>"] = actions.toggle_selection + actions.move_selection_better,
    }

    telescope.setup({
      defaults = {
        mappings = { i = maps, n = maps },
      },
    })

    -- The pcall buys a CLEAN STARTUP, not a working finder — say it that way
    -- or the next reader deletes it after watching the finder survive.
    -- Measured 2026-08-23: with build/libfzf.so absent,
    -- load_extension("fzf") raises (dlopen ... no such file), and unwrapped
    -- it aborts this whole config function, so lazy reports "Failed to run
    -- `config` for telescope.nvim". The finder works either way, because
    -- telescope.setup() above has already installed the mappings by this
    -- line; what the pcall prevents is the error on startup.
    pcall(telescope.load_extension, "fzf")
  end,
}
