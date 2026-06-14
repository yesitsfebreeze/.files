-- LSP: mason (server installer) + nvim-lspconfig.
return {
    {
        "neovim/nvim-lspconfig",
        event = { "BufReadPre", "BufNewFile" },
        dependencies = {
            { "williamboman/mason.nvim", config = true },
            "williamboman/mason-lspconfig.nvim",
            "hrsh7th/cmp-nvim-lsp",
        },
        config = function()
            local lspconfig = require("lspconfig")
            local capabilities = require("cmp_nvim_lsp").default_capabilities()

            vim.diagnostic.config({
                virtual_text = { prefix = "●" },
                severity_sort = true,
                float = { border = "rounded", source = true },
            })

            vim.api.nvim_create_autocmd("LspAttach", {
                group = vim.api.nvim_create_augroup("lsp_attach", { clear = true }),
                callback = function(event)
                    local function bmap(keys, fn, desc)
                        vim.keymap.set("n", keys, fn, { buffer = event.buf, desc = "LSP: " .. desc })
                    end
                    bmap("gd", vim.lsp.buf.definition, "Goto definition")
                    bmap("gr", vim.lsp.buf.references, "References")
                    bmap("gI", vim.lsp.buf.implementation, "Goto implementation")
                    bmap("K", vim.lsp.buf.hover, "Hover docs")
                    bmap("<leader>rn", vim.lsp.buf.rename, "Rename")
                    bmap("<leader>ca", vim.lsp.buf.code_action, "Code action")
                    bmap("[d", vim.diagnostic.goto_prev, "Prev diagnostic")
                    bmap("]d", vim.diagnostic.goto_next, "Next diagnostic")
                end,
            })

            local servers = {
                lua_ls = {
                    settings = {
                        Lua = {
                            diagnostics = { globals = { "vim" } },
                            workspace = { checkThirdParty = false },
                            telemetry = { enable = false },
                        },
                    },
                },
                bashls = {},
                pyright = {},
                rust_analyzer = {},
            }

            require("mason-lspconfig").setup({
                ensure_installed = vim.tbl_keys(servers),
                handlers = {
                    function(server_name)
                        local cfg = servers[server_name] or {}
                        cfg.capabilities = capabilities
                        lspconfig[server_name].setup(cfg)
                    end,
                },
            })
        end,
    },
}
