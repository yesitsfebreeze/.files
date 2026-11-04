-- lua/config/insert.lua
-- Why this file is shaped the way it is:
--   manual → internals/neovim
--
-- One rule for every path that puts the editor in Insert (opening a buffer,
-- Esc, closing the leader): only a plain editable file gets Insert. Every
-- other screen stays in Normal: oil, :Lazy, :Mason, help, quickfix, man,
-- checkhealth, terminal, pickers, plugin floats, fugitive, diffview.
local M = {}

function M.editable(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  if not vim.api.nvim_buf_is_valid(buf) then
    return false
  end
  if vim.bo[buf].buftype ~= "" or not vim.bo[buf].modifiable or vim.bo[buf].readonly then
    return false
  end
  -- Plugin buffers are named like oil:// or fugitive://; real files are not.
  return not vim.api.nvim_buf_get_name(buf):match("^%a[%w+.-]*://")
end

-- Insert in a plain file; anywhere else leave the current mode for Normal.
function M.start()
  if M.editable() then
    vim.cmd("startinsert")
  elseif vim.api.nvim_get_mode().mode ~= "n" then
    vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "n", false)
  end
end

return M
