-- Colorscheme: tinted-nvim, static Gruvbox Dark Hard. The palette-derived
-- highlights below are re-derived on every colorscheme change.
--
-- PALETTE OWNERSHIP, and it points one way only: tinty owns the palette and
-- the terminal is its first READER. `tinty apply` writes WezTerm's colour
-- file, WezTerm dofiles it (never require -- that caches by module name and
-- would hand back the FIRST palette on a second apply) and re-tints every
-- window at once, because WezTerm's colour table is terminal-wide. This
-- config's whole participation is ui.transparent below: with Normal carrying
-- no background, the terminal's background IS the editor's, so a live retint
-- arrives here with no change to this file. That is why this file holds not
-- one colour literal, and why the inheritance is one-directional. The earlier
-- "the terminal owns the palette" wording had the direction backwards --
-- finding T-3, settled 2026-08-21.
return {
  "tinted-theming/tinted-nvim",
  priority = 1000,
  -- lazy = false: a colorscheme must load before anything paints. NOTE for a
  -- later reader -- lua/config/lazy.lua already sets defaults.lazy = false,
  -- so deleting this line changes no observable state (measured). It is a
  -- text assertion in tests/nvim-colorscheme.sh --tree and nothing more; do
  -- not "strengthen" it into a readback, which would be vacuous.
  lazy = false,
  config = function()
    require("tinted-nvim").setup({
      default_scheme = "base16-gruvbox-dark-hard",
      apply_scheme_on_startup = true,
      ui = { transparent = true },
      -- Naming two integrations does not disable the rest: setup() merges
      -- with vim.tbl_deep_extend("force", defaults, opts), so telescope,
      -- notify, cmp, dapui and snacks stay true. Both keys below are already
      -- true by default; they are written out because they are the two the
      -- rest of this config depends on -- blink.cmp's menu highlights, and
      -- the Lualine* highlight groups the statusline node reads.
      highlights = {
        integrations = {
          blink = true,
          lualine = true,
        },
      },
      -- WHERE THE INHERITANCE STOPS, and it is specified rather than broken.
      -- The syntax palette is deliberately static: this plugin paints
      -- default_scheme above, and its `selector` -- the feature that would
      -- follow tinty live -- is left absent, so it keeps the plugin's own
      -- default of disabled. A `tinty apply` therefore moves the terminal
      -- background and NOT the editor's syntax colours. Two reasons to leave
      -- it off, both read out of the plugin source: its env mode reads
      -- TINTED_THEME while tinty's tinted-shell artifact exports
      -- BASE16_THEME, so wiring it that way silently resolves nothing; and
      -- its file mode expands a LITERAL tilde path, ignoring XDG_DATA_HOME,
      -- while the theme-switcher hook writes under
      -- ${XDG_DATA_HOME:-$HOME/.local/share}. Turning it on is a change with
      -- a PRD behind it, not a config tweak.
    })

    -- Palette-derived highlights, re-derived on every colorscheme change.
    -- Mode-aware cursor: shape per mode, colors pulled from the active base16
    -- palette. Whitespace/NonText use base02 to keep listchars as dim as VS
    -- Code's editorWhitespace.
    --
    -- The nil check is not defensive. get_palette() returns nil until a
    -- scheme has been applied, and with the check deleted a startup that has
    -- not applied one yet dies with "attempt to index local 'p' (a nil
    -- value)" at the first highlight call (measured).
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
    -- Both halves below are load-bearing, not belt-and-braces.
    --   * The eager call: setup()'s startup load() fires ColorScheme from
    --     INSIDE this config function, before the augroup below exists.
    --     Delete the eager call and CursorNormal is nil on a fresh launch
    --     (measured).
    --   * The augroup: delete it instead and a later :colorscheme leaves all
    --     six groups nil, because load() runs `highlight clear` before it
    --     re-applies (measured).
    -- The re-derive reads THIS plugin's palette, not the active scheme's: a
    -- non-tinted :colorscheme fires ColorScheme and the six groups keep the
    -- last tinted palette (measured). A base16 switch is in scope; a
    -- non-tinted scheme is not.
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
