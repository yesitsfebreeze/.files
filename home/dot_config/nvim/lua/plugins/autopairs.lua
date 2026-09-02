-- lua/plugins/autopairs.lua
-- Why this file is shaped the way it is:
--   manual → internals/neovim

return {
  "windwp/nvim-autopairs",
  event = "InsertEnter",
  config = true,
}
