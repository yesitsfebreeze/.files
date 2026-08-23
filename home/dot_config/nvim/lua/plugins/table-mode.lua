-- Live table alignment while typing: the pipes realign on every `|` typed in
-- insert mode. Complements prettier's on-save alignment
-- (03-editor/07-formatting) — this one works *during* editing.
--
-- ONE filetype list, hoisted out of both consumers. `ft` and the FileType
-- autocmd's `pattern` must never drift apart, and hoisting makes scoping this
-- node a one-line change. `markdown.mdx` was dropped 2026-08-23: nothing
-- registers the extension (`vim.filetype.match({ filename = "a.mdx" })`
-- returns nil, and init.lua registers only `.jd`), so the filetype was
-- unreachable and this spec never loaded for it.
local fts = { "markdown" }

return {
  "dhruvasagar/vim-table-mode",
  ft = fts,
  cmd = { "TableModeToggle", "TableModeEnable", "TableModeRealign", "Tableize" },
  init = function()
    -- GitHub-flavored corners: `|` instead of vim-table-mode's default `+`.
    --
    -- SHADOWED IN MARKDOWN, and kept anyway. The plugin ships
    -- ftplugin/markdown_tablemode.vim setting b:table_mode_corner = '|', and
    -- tablemode#utils#get_buffer_or_global_option prefers the buffer
    -- variable — so in a markdown buffer this global is never read (measured
    -- 2026-08-23: deleting it leaves the border byte-identical, |----|----|).
    -- It bites only in a buffer with no table-mode ftplugin, reached through
    -- the `cmd` trigger: there the border is |----+----| without it.
    vim.g.table_mode_corner = "|"
    -- `init`, not `config`, is load-bearing: plugin/table-mode.vim:48-58
    -- derives g:table_mode_realign_map and eight siblings from the prefix at
    -- plugin LOAD time, so a prefix set in `config` would land after the maps
    -- were already built. The value itself buys no behaviour — the plugin
    -- already defaults to <Leader>t (plugin/table-mode.vim:31) — it is the
    -- written contract with which-key's `table` group
    -- (03-editor/12-small-plugins R2), whose one child is <leader>tt.
    vim.g.table_mode_map_prefix = "<leader>t"
  end,
  config = function()
    local function enable()
      vim.cmd("silent! TableModeEnable")
    end
    -- Grouped with clear = true — live bug L-8's third site. Measured: with
    -- the group, re-running this registration leaves the autocmd count
    -- unchanged; without it two registrations give two callbacks and the
    -- handler fires twice per event.
    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("table_mode_enable", { clear = true }),
      pattern = fts,
      callback = enable,
    })
    -- Belt and braces. lazy re-fires FileType UNGROUPED after loading an
    -- ft-lazy plugin (core/handler/event.lua:107 sets exclude=nil for
    -- FileType), so the autocmd above already covers the buffer that
    -- triggered the load — measured 2026-08-23 on lazy 306a055, with this
    -- line deleted the first markdown file still aligns. Kept against a lazy
    -- that re-fires with a group filter.
    enable()
  end,
}
