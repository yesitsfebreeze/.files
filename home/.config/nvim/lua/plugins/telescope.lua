-- lua/plugins/telescope.lua
-- Why this file is shaped the way it is:
--   manual → internals/neovim

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
    local builtin = require("telescope.builtin")

    local function multi_or_select(prompt_bufnr)
      local picker = action_state.get_current_picker(prompt_bufnr)
      if #picker:get_multi_selection() > 0 then
        actions.send_selected_to_qflist(prompt_bufnr)
        actions.open_qflist(prompt_bufnr)
      else
        actions.select_default(prompt_bufnr)
      end
    end

    -- ctrl-. cycles normal -> hidden files -> gitignored files, the same
    -- three modes the television pickers cycle (terminal.txt). One mode index
    -- is shared, so the editor keeps one visibility state across both
    -- pickers; the prompt title names it, television shows it in the border.
    local modes = { "normal", "hidden files", "gitignored files" }
    local mode = 1

    local function find_files(line)
      local m = mode
      builtin.find_files({
        default_text = line,
        prompt_title = "Find Files " .. modes[m],
        hidden = m == 2 or nil,
        no_ignore = m == 3 or nil,
      })
    end

    local function live_grep(line)
      local m = mode
      builtin.live_grep({
        default_text = line,
        prompt_title = "Live Grep " .. modes[m],
        additional_args = m == 2 and { "--hidden" }
          or m == 3 and { "--no-ignore" }
          or nil,
      })
    end

    local function cycle(prompt_bufnr)
      local picker = action_state.get_current_picker(prompt_bufnr)
      local title = picker.prompt_title or ""
      local reopen = title:find("^Find Files") and find_files
        or title:find("^Live Grep") and live_grep
      if not reopen then
        return
      end
      local line = action_state.get_current_line()
      mode = mode % #modes + 1
      actions.close(prompt_bufnr)
      reopen(line)
    end

    local maps = {
      ["<CR>"] = multi_or_select,
      ["<Tab>"] = actions.toggle_selection + actions.move_selection_worse,
      ["<S-Tab>"] = actions.toggle_selection + actions.move_selection_better,
      ["<C-.>"] = cycle,
    }

    telescope.setup({
      defaults = {
        mappings = { i = maps, n = maps },
      },
    })

    pcall(telescope.load_extension, "fzf")
  end,
}
