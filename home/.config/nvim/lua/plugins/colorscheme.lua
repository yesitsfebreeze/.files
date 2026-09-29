-- lua/plugins/colorscheme.lua
-- Why this file is shaped the way it is:
--   manual → internals/neovim

return {
  "tinted-theming/tinted-nvim",
  priority = 1000,
  lazy = false,
  config = function()
    -- tinty is the palette owner: the scheme is whatever tinty's current_scheme
    -- names (theme.sh writes it). Schemes that tinted-nvim does not bundle
    -- (tinty's custom schemes, gogh-*) come from `theme.sh --palette ID`: theme.sh
    -- is the one scheme parser.
    local tinty = (vim.env.XDG_DATA_HOME or (vim.env.HOME .. "/.local/share")) .. "/tinted-theming/tinty"
    local current = tinty .. "/current_scheme"
    local theme = (vim.env.XDG_CONFIG_HOME or (vim.env.HOME .. "/.config")) .. "/tinted-theming/tinty/theme.sh"

    local function custom_scheme(name)
      local ok, out = pcall(vim.fn.system, { theme, "--palette", name })
      local spec = {}
      for k, v in (ok and out or ""):gmatch("(%w+)=(%S+)") do spec[k:sub(1, 4) .. k:sub(5):upper()] = v end -- base0a → base0A
      return spec.base00 and spec or nil
    end

    local tn = require("tinted-nvim")
    tn.setup({
      default_scheme = "base16-gruvbox-material-dark-medium",
      apply_scheme_on_startup = false,
      selector = { enabled = true, mode = "file", path = current, watch = false },
      ui = { transparent = true },
      highlights = {
        integrations = {
          blink = true,
          lualine = true,
        },
      },
    })

    setmetatable(require("tinted-nvim.config").options.schemes, {
      __index = function(_, name) return custom_scheme(name) end,
    })
    local function load()
      if not pcall(tn.load) then pcall(tn.load, "base16-gruvbox-material-dark-medium") end
    end
    load()

    -- Reload on every write; re-arm after a rename (a writer may replace the file).
    local function watch()
      local handle = vim.uv.new_fs_event()
      if not handle then return end
      handle:start(current, {}, function(_, _, events)
        vim.schedule(function()
          load()
          if events.rename then
            handle:stop()
            watch()
          end
        end)
      end)
    end
    watch()

    local function set_palette_hl()
      local ok, tn = pcall(require, "tinted-nvim")
      if not ok then return end
      local p = tn.get_palette()
      if not p then return end
      vim.api.nvim_set_hl(0, "CursorNormal", { bg = p.base0D }) -- blue
      vim.api.nvim_set_hl(0, "CursorInsert", { bg = p.base0B }) -- green
      vim.api.nvim_set_hl(0, "CursorVisual", { bg = p.base0E }) -- magenta
      vim.api.nvim_set_hl(0, "CursorReplace", { bg = p.base08 }) -- red
      vim.api.nvim_set_hl(0, "Whitespace", { fg = p.base02 })
      vim.api.nvim_set_hl(0, "NonText", { fg = p.base02 })
    end
    set_palette_hl()
    vim.api.nvim_create_autocmd("ColorScheme", {
      group = vim.api.nvim_create_augroup("palette_hl", { clear = true }),
      callback = set_palette_hl,
    })

    vim.opt.guicursor = table.concat({
      "a:blinkwait700-blinkon400-blinkoff250",
      "n-c-sm:block-CursorNormal",
      "i-ci-ve:ver25-CursorInsert",
      "v:block-CursorVisual",
      "r-cr-o:hor20-CursorReplace",
    }, ",")
  end,
}
