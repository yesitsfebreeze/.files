-- §head home/dot_config/nvim/lua/plugins/treesitter.lua:26-30 attach
-- §sig local function attach(buf)
if pcall(vim.treesitter.start, buf) then
                vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
            end
-- §foot home/dot_config/nvim/lua/plugins/treesitter.lua attach