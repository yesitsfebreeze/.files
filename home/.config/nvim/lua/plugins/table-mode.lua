-- lua/plugins/table-mode.lua
-- Why this file is shaped the way it is:
--   manual → internals/neovim

local fts = { "markdown" }

return {
  "dhruvasagar/vim-table-mode",
  ft = fts,
  cmd = { "TableModeToggle", "TableModeEnable", "TableModeRealign", "Tableize" },
  init = function()
    vim.g.table_mode_corner = "|"
    vim.g.table_mode_map_prefix = "<leader>t"
  end,
  config = function()
    local function enable()
      vim.cmd("silent! TableModeEnable")
    end
    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("table_mode_enable", { clear = true }),
      pattern = fts,
      callback = enable,
    })
    enable()
  end,
}
