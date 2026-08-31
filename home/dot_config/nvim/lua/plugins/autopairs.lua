-- lua/plugins/autopairs.lua
-- Why this file is shaped the way it is:
--   docs-site → Internals → Neovim

return {
  "windwp/nvim-autopairs",
  event = "InsertEnter",
  config = true,
}
