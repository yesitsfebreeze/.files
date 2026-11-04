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
      vim.api.nvim_set_hl(0, "Whitespace", { fg = p.base02 })
      vim.api.nvim_set_hl(0, "NonText", { fg = p.base02 })
    end

    -- Cursor color follows the mode color lualine already shows, so the
    -- block and the statusline never disagree. Every value is read from a
    -- theme highlight group; the statusline groups ARE the mode colors.
    local theme_insert = nil

    local function mode_cursor_hl()
      local normal = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
      -- Capture Insert's statusline colors before restyling them: the
      -- theme's insert color is the blue that Normal keeps.
      if not theme_insert then
        local li = vim.api.nvim_get_hl(0, { name = "lualine_a_insert", link = false })
        if li.bg then
          theme_insert = { bg = li.bg, fg = li.fg }
        end
      end
      local blue, blue_fg = nil, nil
      if theme_insert then
        blue, blue_fg = theme_insert.bg, theme_insert.fg
      end
      if blue then
        vim.api.nvim_set_hl(0, "CursorNormal", { bg = blue })
        vim.api.nvim_set_hl(0, "lualine_a_normal", { bg = blue, fg = blue_fg, bold = true })
      end
      -- Insert takes the theme foreground on the theme background.
      local fg = normal.fg
      local bg = normal.bg or blue_fg
      if fg then
        vim.api.nvim_set_hl(0, "CursorInsert", { bg = fg, fg = bg })
        vim.api.nvim_set_hl(0, "lualine_a_insert", { bg = fg, fg = bg, bold = true })
      end
      local groups = {
        CursorVisual = "lualine_a_visual",
        CursorReplace = "lualine_a_replace",
        CursorCommand = "lualine_a_command",
      }
      for cursor, source in pairs(groups) do
        local hl = vim.api.nvim_get_hl(0, { name = source, link = false })
        if hl.bg then
          vim.api.nvim_set_hl(0, cursor, { bg = hl.bg })
        end
      end
    end
    set_palette_hl()
    mode_cursor_hl()
    vim.api.nvim_create_autocmd({ "ColorScheme", "User" }, {
      group = vim.api.nvim_create_augroup("palette_hl", { clear = true }),
      pattern = "*",
      callback = function(event)
        set_palette_hl()
        if event.event == "ColorScheme" then
          -- Let lualine re-apply its theme first, then read the new colors.
          theme_insert = nil
          vim.schedule(mode_cursor_hl)
        elseif event.match == "VeryLazy" then
          mode_cursor_hl()
        end
      end,
    })
    -- lualine sets its theme after this config runs; refresh once loaded.
    vim.defer_fn(mode_cursor_hl, 500)

    vim.opt.guicursor = table.concat({
      "a:block-blinkwait700-blinkon400-blinkoff250",
      "n:block-CursorNormal",
      "v:block-CursorVisual",
      "i-ci-ve:block-CursorInsert",
      "r-cr:block-CursorReplace",
      "o:block-CursorNormal",
      "c:block-CursorCommand",
      "t:block",
      "sm:block",
    }, ",")
  end,
}
