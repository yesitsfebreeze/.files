-- §head home/dot_config/nvim/lua/plugins/statusline.lua:32-52 lualine_theme
-- §sig local function lualine_theme()
local ok, tn = pcall(require, "tinted-nvim")
                if not ok then return fallback_theme end
                local got, p = pcall(tn.get_palette)
                if not got or not p then return fallback_theme end
                local function s(fg, bg) return { fg = fg, bg = bg } end
                local b = s(p.base05, p.base02)
                local c = s(p.base04, p.base01)
                return {
                    normal = { a = s(p.base00, p.base0D), b = b, c = c },
                    insert = { a = s(p.base00, p.base0B), b = b, c = c },
                    visual = { a = s(p.base00, p.base0E), b = b, c = c },
                    replace = { a = s(p.base00, p.base08), b = b, c = c },
                    command = { a = s(p.base00, p.base0A), b = b, c = c },
                    inactive = {
                        a = s(p.base03, p.base01),
                        b = s(p.base03, p.base01),
                        c = s(p.base03, p.base01),
                    },
                }
-- §foot home/dot_config/nvim/lua/plugins/statusline.lua lualine_theme