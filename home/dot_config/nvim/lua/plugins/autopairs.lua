-- Automatic bracket and quote pairing while typing. Default config, per R3 —
-- no `opts` table, and nothing this file has an opinion about.
--
-- Three measured facts.
--
-- 1. `config = true` IS LOAD-BEARING, and "loaded" is not "set up". Replace
--    it with an empty function and lazy still reports the plugin loaded,
--    while typing `(` inserts a bare `(` (measured). Any readback that only
--    checks `_.loaded` passes that mutation, which is why the gate types into
--    a buffer instead.
-- 2. THE DEFAULT `map_cr` INSTALLS A GLOBAL INSERT `<CR>` MAP, AND IT DOES
--    NOT SURVIVE — and that is the good outcome. blink.cmp
--    (03-editor/05-completion R3) sets its own `<CR>` from an async callback
--    that runs after this setup, so the live map is `blink.cmp: Accept`,
--    measured in BOTH spec orders (this filename sorting before
--    completion.lua, and a copy named to sort after it), so the outcome does
--    not depend on filename order. It matters because autopairs' own `<CR>`
--    handler branches on `pumvisible()`, and blink draws its menu in a
--    floating window where `pumvisible()` is 0 — so if autopairs' map ever
--    did win, Enter would insert a newline instead of accepting the
--    completion.
-- 3. `<BS>` IS AUTOPAIRS' AND STAYS. `map_bs` is on by default and nothing
--    overrides it: the live insert map is `autopairs delete` (measured). It
--    is the only global map this plugin contributes to the final config.
--
-- No dependency to add and nothing to exclude by hand: `check_ts` is false by
-- default, so autopairs has no treesitter dependency even though
-- nvim-treesitter is in the lockfile, and `disable_filetype` already defaults
-- to TelescopePrompt, spectre_panel and snacks_picker_input, so telescope's
-- prompt is excluded without this file saying anything.
return {
  "windwp/nvim-autopairs",
  event = "InsertEnter",
  config = true,
}
