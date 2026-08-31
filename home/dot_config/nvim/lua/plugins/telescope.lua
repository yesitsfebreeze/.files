-- lua/plugins/telescope.lua
-- Why this file is shaped the way it is:
--   docs-site → Internals → Neovim

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

    local function multi_or_select(prompt_bufnr)
      local picker = action_state.get_current_picker(prompt_bufnr)
      if #picker:get_multi_selection() > 0 then
        actions.send_selected_to_qflist(prompt_bufnr)
        actions.open_qflist(prompt_bufnr)
      else
        actions.select_default(prompt_bufnr)
      end
    end

    local maps = {
      ["<CR>"] = multi_or_select,
      ["<Tab>"] = actions.toggle_selection + actions.move_selection_worse,
      ["<S-Tab>"] = actions.toggle_selection + actions.move_selection_better,
    }

    telescope.setup({
      defaults = {
        mappings = { i = maps, n = maps },
      },
    })

    pcall(telescope.load_extension, "fzf")
  end,
}
