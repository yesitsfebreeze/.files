-- Treesitter: syntax-tree highlighting and indentation on nvim-treesitter's
-- `main` branch — the new API (setup + install), no `ensure_installed`
-- module config. Neovim 0.12 already compiles seven parsers into the binary
-- (c, lua, markdown, markdown_inline, query, vim, vimdoc) and starts
-- treesitter itself from its own ftplugins for lua, markdown, help and
-- query, so this file's real subject is the OTHER nine languages plus the
-- indentexpr everywhere.
--
-- COLD-INSTALL CONTRACT, and it is the load-bearing constraint here.
-- `install()` compiles each missing parser from source: it needs `curl`
-- (a tarball per language from GitHub) AND the `tree-sitter` CLI, which
-- upstream shells out to for `tree-sitter build`. With either missing the
-- run STILL EXITS 0 — every failure is one `:messages` line, nothing marks
-- the config broken, and the nine non-builtin languages simply have no
-- highlighting. Measured 2026-08-23: with PATH stripped to /usr/bin:/bin,
-- `Error during "tree-sitter build": ENOENT ... 'tree-sitter'` per language
-- and an empty parser dir. `tree-sitter` is NOT in the required package set
-- (05-platform/02 R7), so a freshly provisioned machine lands in exactly
-- that state.
--
-- `install()` is idempotent and offline-safe once warm: it short-circuits on
-- `get_installed()` and makes zero network calls (measured). It is safe to
-- call on every launch, which is why it lives here rather than behind a
-- command.
--
-- HALF-INSTALLED IS A WEDGE. `get_installed()` unions the parser directory
-- with the QUERIES directory under `stdpath("data")/site`, so a language
-- whose queries symlink survived but whose `.so` is gone reads as installed,
-- `install()` skips it forever, and no relaunch heals it (measured: all 16
-- reported installed, 0 downloads, nothing highlighted). Diagnose with
-- `:checkhealth nvim-treesitter`; fix by deleting the stale
-- `site/queries/<lang>` link as well as the parser.
--
-- `build = ":TSUpdate"` keeps ALREADY-INSTALLED parsers in step with the
-- plugin's revision table; it is not what installs them. `:TSUpdate`
-- resolves its language list through `norm_languages("all", { missing =
-- true })`, which is `get_installed()` — empty on a cold machine, so the
-- build step is a no-op there (measured warm: all 16 in subject; the
-- installer is `install()` below).
return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  build = ":TSUpdate",
  event = { "BufReadPost", "BufNewFile" },
  config = function()
    require("nvim-treesitter").setup({})
    require("nvim-treesitter").install({
      "odin",
      "bash",
      "c",
      "lua",
      "luadoc",
      "markdown",
      "markdown_inline",
      "nu",
      "python",
      "query",
      "rust",
      "toml",
      "vim",
      "vimdoc",
      "yaml",
      "json",
    })
    -- pcall is live, not defensive decoration: `vim.treesitter.start` calls
    -- assert() and a filetype with no parser throws `Parser could not be
    -- created for buffer N and language "go"` out of the FileType autocmd.
    -- Measured both ways 2026-08-23 — without the pcall, opening a .go file
    -- prints a Lua traceback.
    local function attach(buf)
      if pcall(vim.treesitter.start, buf) then
        vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end
    end
    -- I7: cleared augroup, or a second run of this config registers a second
    -- copy of the callback (measured: FileType count 4 -> 5 ungrouped, 4 -> 4
    -- grouped). Live bug L-8.
    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("treesitter_attach", { clear = true }),
      callback = function(ev)
        attach(ev.buf)
      end,
    })
    -- Buffers that were ALREADY filetyped before this plugin loaded get no
    -- further FileType event, so the autocmd alone never reaches them. Note
    -- what this loop is NOT for: on `nvim x.nu` the triggering buffer's
    -- filetype is still EMPTY when this config runs — FileType fires after
    -- BufReadPost, and the autocmd above is what attaches it (measured
    -- 2026-08-23: `loop:1:ft=` then `au:1:ft=nu`). Deleting the loop leaves
    -- `nvim x.nu` fully highlighted and costs a pre-typed sibling buffer its
    -- indentexpr (measured: ours vs `GetLuaIndent()`).
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(buf) then
        attach(buf)
      end
    end
  end,
}
