-- The leader-key overlay: press `<leader>` and pause, and which-key lists the
-- groups, then the maps inside whichever one you press. `opts`, not `config`
-- — there is nothing imperative here.
--
-- R2's "group names must stay in sync with the keymaps that live under them"
-- IS MECHANICAL, not a discipline anyone has to keep. which-key builds a
-- per-buffer tree and then runs `tree:fix()`, which DELETES any group node
-- with no child keymap. So declaring a group before its keys exist is
-- harmless: the overlay prunes rather than lying, and a group whose name is
-- wrong is the only way this can go bad.
--
-- MEASURED, so nobody reads a short leader menu as a bug. A group renders
-- only where one of its children has a LIVE keymap in the current buffer, and
-- lazy's `keys =` stubs count — they are real keymaps from startup. Measured
-- 2026-08-24 against the repo tree: `f` (telescope's `<leader>ff`/`fg`/`fb`/
-- `fh` stubs), `b` (`<leader>bd` in lua/config/keymaps.lua) and `c`
-- (conform's `<leader>cf` stub) render; `r` does not, because `<leader>rn` is
-- BUFFER-LOCAL and set on `LspAttach`, so it exists only inside a buffer with
-- a language server attached; and `t` does not, because vim-table-mode builds
-- its `<leader>t` maps at plugin load time and that plugin is `ft`-lazy on
-- markdown. Proved by construction rather than inferred: seeding a global
-- `<leader>bd`, a global `<leader>tt` and buffer-local `<leader>ca` /
-- `<leader>rn`, then calling `require("which-key.buf").clear()`, makes all
-- five appear with their names. That is why all five are safe to declare
-- here, and why the gate asserts the DECLARATIONS unconditionally and the
-- RENDERED tree only against a probe-seeded buffer.
--
-- `VeryLazy` NEVER FIRES WITHOUT A UI. lazy hooks `User VeryLazy` to
-- `UIEnter`, so under `--headless` (`#nvim_list_uis() == 0`) which-key is
-- never loaded and every probe has to fire the event itself. And which-key's
-- `Config.setup` wraps its own `load` in `vim.schedule_wrap` AND defers to
-- `VimEnter` when `vim.v.vim_did_enter == 0` — which is the case for anything
-- in a `-c` chain — so a probe must then wait for
-- `require("which-key.config").loaded`. Reading `Config.triggers.modes`
-- before that flag flips throws `attempt to index field 'modes' (a nil
-- value)`. All measured; tests/nvim-small-plugins.sh carries the shape.
--
-- NO ICON PLUGIN IS NEEDED, so there is nothing to provision: `icons.mappings`
-- defaults to true and uses which-key's own built-in set. Measured with
-- neither mini.icons nor nvim-web-devicons loaded — `Config.issues` is empty
-- and `:messages` is empty at startup. No health warning either.
return {
  "folke/which-key.nvim",
  event = "VeryLazy",
  opts = {
    spec = {
      { "<leader>f", group = "find" },
      { "<leader>b", group = "buffer" },
      { "<leader>c", group = "code" },
      { "<leader>r", group = "rename/refactor" },
      { "<leader>t", group = "table" },
      -- Added by 07-multiplexer/06-nvim-session. It goes AFTER table, not in
      -- alphabetical order: tests/nvim-small-plugins.sh asserts R2's five
      -- groups as five ASCENDING line numbers, so inserting anywhere among
      -- them would go red on the order check while the set check still
      -- passed. Appending leaves f, b, c, r, t in the order R2 states.
      { "<leader>s", group = "session" },
    },
  },
}
