-- Statusline: lualine, with its theme built by hand out of the live base16
-- palette. The complexity here is entirely a workaround, and each piece of
-- it is written down because the obvious shorter version is silently wrong.
--
-- WHY NOT theme = "auto" — and the reason is NOT that it errors. lualine's
-- auto.lua collapses any colors_name beginning `base16` to its bundled
-- base16 theme, and that theme resolves in three steps of which the third
-- is the trap:
--   1. setup_base16_vim() wants vim.g.base16_gui00..base16_gui0F, or since
--      lualine PR #1352 vim.g.tinted_gui00..tinted_gui0F. All of them are
--      nil under tinted-nvim (measured: zero vim.g keys matching `tinted`
--      or `base16` exist after a scheme is applied), so it returns nil.
--   2. setup_base16_nvim() wants the nvim-base16 module, which is absent
--      from lazy-lock.json. Returns nil, and records one notice.
--   3. setup_default() — a hardcoded Tomorrow-Night palette.
-- So `auto` exits 0, and it paints the Tomorrow-Night values #81a2be,
-- #b5bd68, #b294bb and #de935f: colours from no scheme this config has
-- ever applied, with the command mode collapsed onto normal because
-- base16.lua assigns theme.command = theme.normal. The only user-facing
-- signal is a deferred WARN two seconds in — "lualine: There are some
-- issues with your config. Run :LualineNotices for details" — plus the
-- :LualineNotices command appearing. Silently wrong beats broken as a
-- failure mode, which is exactly why the theme table below is built slot by
-- slot instead.
--
-- The fallback is lualine's builtin gruvbox_dark: a real theme file with no
-- nvim-base16 dependency, so taking it costs nothing and the broken base16
-- path is never requested.
--
-- globalstatus = true is NOT redundant with lua/config/options.lua's
-- laststatus = 3. lualine sets the option itself — 3 with globalstatus, 2
-- without (measured) — and it overrides options.lua, so the line has an
-- observable effect of its own.
--
-- The separators default to Powerline private-use glyphs rather than to
-- nothing: component_separators defaults to U+E0B1/U+E0B3 and
-- section_separators to U+E0B0/U+E0B2. Emptying both is what removes the
-- lualine_transitional_* groups from the rendered line (measured: 4 of them
-- with the two lines deleted, 0 with them present).
--
-- The ColorScheme rebuild is load-bearing, and its failure mode is a STALE
-- value, not nil: lualine registers its own ColorScheme handler, and that
-- handler re-applies the SAME theme table. Delete the block below and a
-- base16 switch leaves the statusline on the old palette while the cursor
-- moves to the new one — measured across gruvbox-dark-hard to
-- tokyo-night-dark: lualine_a_normal stayed #83a598, CursorNormal #2ac3de.
-- Statusline and cursor then visibly disagree.
--
-- clear = true is epic I7, and what it guards is a re-run of this config
-- function, not a :colorscheme. Measured: with clear = false the augroup
-- still holds exactly one entry across two scheme switches, because lazy
-- runs config once. Run config twice by hand and the count goes 1 -> 2 -> 3
-- with clear = false and stays 1 -> 1 -> 1 with clear = true. That second
-- copy firing per event is live bug L-8.
--
-- get_palette() needs no eager-vs-augroup ordering worry here, unlike
-- lua/plugins/colorscheme.lua: that node runs at priority 1000 with
-- lazy = false, so by the time this file loads on VeryLazy the palette is
-- committed. The eager setup call is still required — it is the first build
-- — but the startup ColorScheme has already fired by then, which is why the
-- handler only matters for later switches.
--
-- The diff component shells out to git: `git -C <dir> --no-pager diff
-- --no-color --no-ext-diff -U0 -- <file>`. With no git on PATH there is no
-- error and no crash — branch still resolves by reading .git/HEAD, and the
-- diff section silently renders nothing. install.sh's PKGS carries git=git,
-- and font-caskaydia-cove-nerd-font too, which is what makes the branch,
-- file and fileformat glyphs render as icons rather than tofu.
local fallback_theme = "gruvbox_dark"

return {
  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    event = "VeryLazy",
    opts = {
      options = {
        globalstatus = true,
        component_separators = "",
        section_separators = { left = "", right = "" },
      },
      sections = {
        lualine_a = { "mode" },
        lualine_b = { "branch", "diff", "diagnostics" },
        lualine_c = { { "filename", path = 1 } },
        lualine_x = { "encoding", "fileformat", "filetype" },
        lualine_y = { "progress" },
        lualine_z = { "location" },
      },
    },
    config = function(_, opts)
      local function lualine_theme()
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
      end
      opts.options.theme = lualine_theme()
      require("lualine").setup(opts)
      vim.api.nvim_create_autocmd("ColorScheme", {
        group = vim.api.nvim_create_augroup("lualine_theme", { clear = true }),
        callback = function()
          opts.options.theme = lualine_theme()
          require("lualine").setup(opts)
        end,
      })
    end,
  },
}
