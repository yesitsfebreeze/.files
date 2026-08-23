-- gates/fixtures/nvim/init.lua — the self-test fixture for `nvim_probe`.
--
-- One normal-mode map carrying `desc = "gate probe"`. Keymap assertions go
-- through nvim_get_keymap, never by grepping Lua source: the source says what
-- was written, introspection says what the editor actually has.
vim.keymap.set('n', '<Plug>GateProbe', '<Nop>', { desc = 'gate probe' })
