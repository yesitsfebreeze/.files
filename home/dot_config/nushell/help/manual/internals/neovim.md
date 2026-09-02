# Neovim

> The lazy.nvim stack — plugin choices, the constraints behind them, and the built-ins preferred over plugins.

Notes harvested from the Neovim sources. Each block is anchored to the line it
was written about.


## `init.lua`

```lua
require("config.options")
```

Load order (epic I1): options -> keymaps -> autocmds -> lazy. The leader is set in config.options, before any plugin spec is evaluated.

SEAM: a require of a missing module aborts startup — this file requires exactly what is built. 02-keymaps (E.3) INSERTS its require ABOVE the require("config.autocmds") line, in I1's order; require("config.lazy") stays last.

```lua
require("config.shift-select")
```

14-shift-select gets its own module rather than riding in the general keymap file, which is kept free of shift-select machinery and of autocmds. It loads after the general maps and before the plugin manager, keeping I1's order.


## `lua/plugins/init.lua`

```lua
return {}
```

The import anchor for `{ import = "plugins" }` — permanent and load-bearing: lazy errors `No specs found for module "plugins"` at every startup when lua/plugins/ is missing OR empty (measured 2026-08-22), and git cannot track an empty directory. This file holds zero specs, forever. Plugin nodes (E.5+) add sibling plugins/*.lua files, imported alongside it; nobody writes specs into this file. It is the anchor, not the catch-all spec file epic I8 forbids.


## `lua/config/autocmds.lua`

```lua
local augroup = vim.api.nvim_create_augroup
```

Four small behaviors, each in its own cleared augroup: clear = true is what makes re-registration idempotent, so re-running this module replaces its callbacks instead of stacking a second copy (epic I7, live bug L-8).

```lua
autocmd("TextYankPost", {
```

Highlight on yank. vim.hl, NOT vim.highlight: the latter was renamed in 0.11 (deprecated.txt) and is on a removal clock. The rename is the one thing no runtime check can catch — the deprecated call still flashes and warns nobody (measured: notify count 0) — so only reading the source finds it. timeout = 150 is also vim.hl.on_yank's own default; it is written out because R1 specifies the duration, not because it changes behavior.

```lua
autocmd("BufReadPost", {
```

Return to the last edit position when opening a file.

The filetype has to be COMPUTED here, not read. This module is required from init.lua, so its BufReadPost callback registers before the one $VIMRUNTIME/filetype.lua installs on the same event, and same-event autocmds fire in registration order: vim.bo.filetype is still "" at this point and a filetype-based exclusion silently never matches. Measured on 0.12.4: the live config's gitcommit exclusion is dead for exactly this reason, and a commit message opens on the previous commit's cursor line. vim.filetype.match resolves it now; deferring with vim.schedule would also work but moves the cursor after the first redraw, which is the visible jump this autocmd exists to prevent.

```lua
if vim.tbl_contains({ "gitcommit" }, ft) then
```

A fresh commit message opens at the top, never where the last one was left.

```lua
pcall(vim.api.nvim_win_set_cursor, 0, mark)
```

pcall: the mark can be invalid for a window that is not laid out yet, and a hard error here would abort the read.

```lua
autocmd("BufWritePre", {
```

Trim trailing whitespace on save. The substitute leaves the cursor on the last line it changed, so the view is saved and restored around it — without the bracket, saving a 400-line file with trailing space on line 370 drags the cursor there from line 200 (measured).

```lua
autocmd("FileType", {
```

Close utility buffers with `q`, and keep them out of buffer cycling: an unlisted help buffer never turns up under :bnext.


## `lua/config/keymaps.lua`

```lua
local map = vim.keymap.set
```

General keymaps. Plugin-specific maps live in their plugin specs (keys = ...).

```lua
map("n", "<C-d>", "<C-d>zz")
```

Keep cursor centered on jumps / search (these maps carry no desc).

NO DESC ON PURPOSE, and the manual agrees: which-key should not list a key whose behavior is the vim default plus a re-centre, so help/nvim.nuon records these four — and the visual </> pair below — as desc: null. Adding a desc to one of them contradicts the manual.

Do NOT "simplify" the zz away as redundant under scrolloff = 999 (01-options): scrolloff is a minimum distance from the window edge and never scrolls PAST THE END of the buffer, while zz does — so the appended zz is exactly what keeps the last half-screen centered. The zv in nzzzv is the other half: it opens the fold a search match lands in.

R9: <C-q> IS LEFT UNBOUND ON PURPOSE. No node in this epic may map it.

14-shift-select binds Ctrl+V in VISUAL mode to a register-safe paste, which shadows vim's entry into blockwise-visual from a selection (live bug L-9, ported as decided 2026-08-21). <C-q> is vim's built-in synonym for blockwise-visual and therefore the escape hatch that makes that shadow acceptable: bind it to anything and the hatch closes. Stated here as a comment because an unbound key is invisible to search — nothing else in the tree would stop a later agent from taking it.


## `lua/config/lazy.lua`

Bootstrap lazy.nvim (clones it on first run) and load plugin specs.

Lockfile policy: lazy-lock.json lives beside init.lua and is committed. lazy rewrites the deployed copy on sync/update; carry that change back to the repo in the same commit as the spec change that caused it. Every plugin node (E.5+) commits its lockfile delta with its spec.

REMOVED 2026-09-02: a `HELP_CHECK=1` guard that disabled `install.missing` and `checker` when the manual's drift check started this config headless to read `nvim_get_keymap`. The check is deleted, so the guard defends nothing and its two options are back at their normal values. The measurement that motivated it is worth keeping if anything ever spawns this config to observe it: 2026-08-29, a plugin in lazy-lock.json with no local store was git-cloned from the network mid-run, and lazy's clone chatter landed on stdout where the reader expected JSON. **A startup that installs is a startup that changes its own answer** — anything spawning this config to observe it has to stop it provisioning first, and two more installers sit behind buffer events (`lua/plugins/lsp.lua`'s `mason-lspconfig`, `lua/plugins/treesitter.lua`'s `install()`) where a headless start that opens no buffer runs neither, but one that opens a buffer does.

```lua
if #vim.api.nvim_list_uis() > 0 then vim.fn.getchar() end
```

The guard is load-bearing, not dead code: a bare getchar() blocks forever in --headless, even with stdin at /dev/null (measured 2026-08-22, nvim 0.12.4) — an offline scripted launch would hang instead of failing. Interactive launch still waits for the keypress; headless gets the error on stderr and exit 1.

```lua
install = { colorscheme = { "base16-gruvbox-dark-hard" } },
checker = { enabled = true, notify = false },
```

`install.missing` is left at its default of true — it is the clone-on-start that makes a fresh machine work — and `checker` polls GitHub for plugin updates, silently. Both were switched off under the deleted drift-check guard; deleting the guard restores them, which is the point. Writing `false` for either here would turn off plugin installation and update checks as a side effect of removing a check, which is the one way this edit could have gone wrong.


## `lua/config/options.lua`

```lua
vim.g.mapleader = " "
```

Leader must be set before lazy/plugins load.

```lua
opt.scrolloff = 999
```

scrolloff is a minimum distance from the window edge, not a centering command: 999 keeps the cursor line centered everywhere except the first and last half-screen of the buffer, where there is nothing left to scroll and the cursor walks to the edge (correction M-1).

```lua
opt.list = true
```

Mirror VS Code's renderWhitespace=boundary: multispace (not space) puts dots only on runs of 2+ spaces (single spaces stay clean), tab as right arrow, enter sign at eol.

```lua
vim.lsp.log.set_level(vim.log.levels.OFF)
```

Servers like rust-analyzer can spam stderr in a tight loop; nvim mirrors every line into ~/.local/state/nvim/lsp.log with no rotation (once grew to 17GB).


## `lua/config/shift-select.lua`

```lua
local map = vim.keymap.set
```

Editor-style "shift to select" (task E.14). A port of the live block at ~/.config/nvim/lua/config/keymaps.lua, verbatim in behaviour except for the augroup noted below.

WHY THIS IS ITS OWN MODULE and not lua/config/keymaps.lua, where the rest of the general maps live: keymaps.lua is deliberately free of shift_select machinery, of any <S-arrow> map, of autocmds (epic invariant I7, live bug L-8) and of any map on the clipboard keys. 02-keymaps leaves the clipboard keys and the blockwise-visual escape hatch unbound on purpose so this file can take them; its own file comment says why. Appending this block there would collapse that separation, and nothing checks it any more — the split is held by this paragraph and the file comment, so read both before moving a map between them.

The system clipboard is shared (clipboard=unnamedplus, from 01-options), so copy and paste cross between nvim and the terminal.

Entering visual mode via Shift+<arrow> (or starting a selection from insert) sets a flag. While that flag is set, a plain motion (h/j/k/l or an unshifted arrow) collapses the selection and returns to normal mode, just like a conventional editor. Holding Shift keeps extending the selection. A selection started the vim way (plain `v`) is unaffected and extends on motion as usual.

COUNTS, settled 2026-08-24 (finding M-2 resolved: the acceptance criteria were the thing that was off by one, not these mappings). The selection is charwise-INCLUSIVE, so one <S-Right> selects two characters -- `kl` with the cursor on `k` -- and two presses select three. From insert, <S-Left> catches the last two characters rather than one: the insert caret sits BETWEEN characters and leaving insert drops the cursor onto the one behind, which every shift map out of insert has to correct for, in opposite directions. <S-Right> therefore feeds an extra `l` before entering visual, or the character under the cursor is left out; leftward there is nothing to correct, and the extra character is the price. <S-Up>/<S-Down> stay charwise-inclusive either way, which is why no mapping change reaches this.

```lua
local function feed(keys)
```

The ONE feeding helper (R8): every map below goes through it, so there are no scattered <cmd> strings and one place where termcodes are resolved.

```lua
vim.api.nvim_create_autocmd("ModeChanged", {
```

Reset the flag whenever we leave visual mode, so a later `v` selection keeps normal extend-on-motion behaviour.

GROUPED, which is the one deliberate deviation from the live block: the live site is ungrouped (live bug L-8, named by epic invariant I7), so every re-source of the module stacks another identical callback on ModeChanged -- an event that fires on every mode transition. `clear = true` makes a reload idempotent instead of cumulative.

```lua
local function select_start(motion)
```

Start a selection from normal mode.

```lua
local function select_extend(motion)
```

Extend a selection (Shift held) from visual mode.

```lua
local function select_start_insert(keys)
```

Start a selection from insert mode.

```lua
local function visual_motion(motion)
```

Plain motion in visual mode: collapse + leave when we got here via Shift, otherwise behave like a normal visual-mode motion. The count is preserved in BOTH branches -- `3j` collapses and goes down three lines, and in a `v`-started selection it extends by three, exactly as stock vim does.

```lua
map("v", "h", visual_motion("h"), { desc = "Move (collapse selection)" })
```

The eight collapse-on-motion maps are written out one per line rather than generated in a loop, as the live block does: one line per map keeps the mode/lhs/desc triple of each readable in the source, and a loop hides all eight behind a table.

```lua
map("i", "<S-Right>", select_start_insert("lv<Right>"), { desc = "Select right" })
```

The extra `l` (R5) is the insert-caret correction described in the header: without it the character under the insert cursor is left out.

```lua
map("v", "<C-c>", "y", { desc = "Copy to clipboard" })
```

Ctrl+C copies the selection to the shared clipboard and leaves visual mode; Ctrl+V pastes over the selection without clobbering the register -- the black-hole delete is what keeps the copied text pasteable a second time.


## `lua/plugins/autopairs.lua`

```lua
return {
```

Automatic bracket and quote pairing while typing. Default config, per R3 — no `opts` table, and nothing this file has an opinion about.

Three measured facts.

1. `config = true` IS LOAD-BEARING, and "loaded" is not "set up". Replace it with an empty function and lazy still reports the plugin loaded, while typing `(` inserts a bare `(` (measured). Any readback that only checks `_.loaded` passes that mutation, so check this by typing into a buffer, never by reading the flag. 2. THE DEFAULT `map_cr` INSTALLS A GLOBAL INSERT `<CR>` MAP, AND IT DOES NOT SURVIVE — and that is the good outcome. blink.cmp (03-editor/05-completion R3) sets its own `<CR>` from an async callback that runs after this setup, so the live map is `blink.cmp: Accept`, measured in BOTH spec orders (this filename sorting before completion.lua, and a copy named to sort after it), so the outcome does not depend on filename order. It matters because autopairs' own `<CR>` handler branches on `pumvisible()`, and blink draws its menu in a floating window where `pumvisible()` is 0 — so if autopairs' map ever did win, Enter would insert a newline instead of accepting the completion. 3. `<BS>` IS AUTOPAIRS' AND STAYS. `map_bs` is on by default and nothing overrides it: the live insert map is `autopairs delete` (measured). It is the only global map this plugin contributes to the final config.

No dependency to add and nothing to exclude by hand: `check_ts` is false by default, so autopairs has no treesitter dependency even though nvim-treesitter is in the lockfile, and `disable_filetype` already defaults to TelescopePrompt, spectre_panel and snacks_picker_input, so telescope's prompt is excluded without this file saying anything.


## `lua/plugins/claude.lua`

```lua
return {
```

Claude Code inside nvim: coder/claudecode.nvim (the IDE integration — WebSocket MCP server, inline diff accept/deny, send-selection, buffer management) with mr55p-dev/claude-tmux.nvim as its terminal provider, so the Claude terminal is a REAL tmux pane and not nvim's built-in terminal. Owned by 08-claude-agent/02-nvim-plugin.

WHY THE PROVIDER IS WIRED CONDITIONALLY. tmux is the multiplexer here (07-multiplexer invariant: tmux owns the panes), so inside tmux the claude-tmux provider wins — `:ClaudeCode` opens a split BELOW nvim in the `main` session, and <C-j> returns to the editor from that pane only (claude-tmux binds it pane-locally; nvim's own <C-j> window-down in lua/config/keymaps.lua is untouched, and so is every other pane). Outside a tmux session the provider is claudecode's default "auto" (snacks), which is also what runs under --headless: claude-tmux checks $TMUX and answers false. Measured both branches.

WHY ONE SPEC ENTRY, not two. claude-tmux has no user-facing surface of its own — no commands, no keymaps, nothing to lazy-load on; its README's own lazy spec relies on claudecode loading first. Naming it a dependency of claudecode means lazy installs both into the store, records both in lazy-lock.json, and loads claude-tmux before claudecode's `config` runs — which is the order the provider wiring needs. A second entry would add a load trigger where there is nothing to trigger.

WHY snacks.nvim IS A DEPENDENCY EVEN THOUGH THE TMUX PROVIDER BYPASSES IT: claudecode's `auto` provider (the non-tmux fallback above) and its diff sizing go through snacks. Dropping it breaks the fallback path this file itself keeps live.

THE SET MOVED FROM `<leader>a*` TO `<leader>x*` ON 2026-08-31, on the user's call: Claude gets a solo whichkey prefix that sits nowhere else, and `a` — a crowded, obvious letter — was the wrong place for it. The original sweep is still the method: this config binds -, |, a, b, bd, c, ca, cf, e, f, fb, ff, fg, fh, p, q, r, rn, t, tt, w (lua/config/keymaps.lua and the plugin `keys` stubs) and nothing on `x`, which is what makes `x` free. `x` is also why the map list shows `<leader>x` with desc `Claude`, the group's whole name. which-key needs no group entry: the bare `{ "<leader>x", desc = ... }` map is a prefix with live lazy stubs under it, and which-key renders it the same way it renders `f` (measured shape, see lua/plugins/which-key.lua).

EPI Constraint, superseded 2026-08-31: claudecode launches the `claude` CLI directly, so it originally bypassed the `cc` profile picker and ran the default profile — which after the multi-login work meant an editor-side Claude that was not logged in. Superseded again the same day: the pane now spawns through **`cll`** (`terminal_cmd = "cll"` in claude.lua), so the model is picked at spawn and cll owns the routing — a `native:*` pick execs through `cc`'s login picker, a proxied pick sets `CLAUDE_CONFIG_DIR` to the litellm profile and exports the proxy pair, overriding whatever resolution exported. The Lua resolution below still earns its keep: it seeds the `CLAUDE_CONFIG_DIR` that cll's *native* branch inherits when it does not run its own picker, and it decides nothing else. The login-resolution rule stands: an inherited, logged-in `CLAUDE_CONFIG_DIR` is left alone; else the profile `~/.claude/.last-login` names **when it is actually logged in**, the test being `"oauthAccount"` in the profile's `.claude.json` (`settings.json` alone exists in logged-out profiles, seeded by `claude.nu`'s `_claude_share` on first pick, so file existence decides nothing); else nothing is exported and Claude's own login flow runs. The env rides claudecode's `env` option; the tmux and snacks providers both receive it (tmux prefixes the command, termopen layers it). Resolution happens when the plugin first loads, not per spawn — a fresh nvim after running `cc` picks up the new login, a long-running instance does not. Claudecode's IDE env (`CLAUDE_CODE_SSE_PORT`, `ENABLE_IDE_INTEGRATION`) is injected independently of `terminal_cmd`, so the WebSocket integration survives the detour through cll — measured on the cll side: neither branch unsets those two, and the SSE port survives `exec`.

```lua
cmd = {
```

`cmd` is load-bearing, cosmetic nothing: lazy creates stub commands so `:ClaudeCode` and friends exist on a fresh start and LOAD the plugin on first use. With keys alone the commands would not exist until a <leader>x* key was pressed.

```lua
{
```

Tree-send variant, same key, file-explorer buffers only (this stack's explorer is oil.nvim, which the ft list covers).

```lua
provider = "auto",
```

Inside tmux this is replaced by the claude-tmux provider table in config() below; "auto" is only ever live outside tmux.

```lua
split_width_percentage = 0.30,
```

30% of the pane's height, matching claude-tmux's own default.

```lua
layout = "vertical",
```

Vertical is the plugin default and matches the split layouts already used across the editor config.

```lua
opts.terminal = opts.terminal or {}
```

claude-tmux.setup() RETURNS the provider table claudecode stores under terminal.provider (README "API" section) — the call is not a side effect to fire and forget.


## `lua/plugins/colorscheme.lua`

```lua
return {
```

Colorscheme: tinted-nvim, static Gruvbox Dark Hard. The palette-derived highlights below are re-derived on every colorscheme change.

PALETTE OWNERSHIP, and it points one way only: tinty owns the palette and the terminal is its first READER. `tinty apply` writes WezTerm's colour file, WezTerm dofiles it (never require -- that caches by module name and would hand back the FIRST palette on a second apply) and re-tints every window at once, because WezTerm's colour table is terminal-wide. This config's whole participation is ui.transparent below: with Normal carrying no background, the terminal's background IS the editor's, so a live retint arrives here with no change to this file. That is why this file holds not one colour literal, and why the inheritance is one-directional. The earlier "the terminal owns the palette" wording had the direction backwards -- finding T-3, settled 2026-08-21.

```lua
lazy = false,
```

lazy = false: a colorscheme must load before anything paints. NOTE for a later reader -- lua/config/lazy.lua already sets defaults.lazy = false, so deleting this line changes no observable state (measured). It is a redundant statement of intent and nothing more; do not "strengthen" it into a readback, which would be vacuous, and do not delete it either — it is what tells the next reader that a colorscheme's eagerness is deliberate rather than an oversight.

```lua
highlights = {
```

Naming two integrations does not disable the rest: setup() merges with vim.tbl_deep_extend("force", defaults, opts), so telescope, notify, cmp, dapui and snacks stay true. Both keys below are already true by default; they are written out because they are the two the rest of this config depends on -- blink.cmp's menu highlights, and the Lualine* highlight groups the statusline node reads.

```lua
})
```

WHERE THE INHERITANCE STOPS, and it is specified rather than broken. The syntax palette is deliberately static: this plugin paints default_scheme above, and its `selector` -- the feature that would follow tinty live -- is left absent, so it keeps the plugin's own default of disabled. A `tinty apply` therefore moves the terminal background and NOT the editor's syntax colours. Two reasons to leave it off, both read out of the plugin source: its env mode reads TINTED_THEME while tinty's tinted-shell artifact exports BASE16_THEME, so wiring it that way silently resolves nothing; and its file mode expands a LITERAL tilde path, ignoring XDG_DATA_HOME, while the theme-switcher hook writes under ${XDG_DATA_HOME:-$HOME/.local/share}. Turning it on is a change with a PRD behind it, not a config tweak.

```lua
local function set_palette_hl()
```

Palette-derived highlights, re-derived on every colorscheme change. Mode-aware cursor: shape per mode, colors pulled from the active base16 palette. Whitespace/NonText use base02 to keep listchars as dim as VS Code's editorWhitespace.

The nil check is not defensive. get_palette() returns nil until a scheme has been applied, and with the check deleted a startup that has not applied one yet dies with "attempt to index local 'p' (a nil value)" at the first highlight call (measured).

```lua
set_palette_hl()
```

Both halves below are load-bearing, not belt-and-braces.
  * The eager call: setup()'s startup load() fires ColorScheme from
    INSIDE this config function, before the augroup below exists.
    Delete the eager call and CursorNormal is nil on a fresh launch
    (measured).
  * The augroup: delete it instead and a later :colorscheme leaves all
    six groups nil, because load() runs `highlight clear` before it
    re-applies (measured).
The re-derive reads THIS plugin's palette, not the active scheme's: a
non-tinted :colorscheme fires ColorScheme and the six groups keep the
last tinted palette (measured). A base16 switch is in scope; a
non-tinted scheme is not.


## `lua/plugins/completion.lua`

```lua
return {
```

Completion: blink.cmp — one batteries-included engine (LSP, snippets, path, buffer, signature help, fuzzy matching) replacing the nvim-cmp + LuaSnip + cmp-* stack. Faster per-keystroke and far fewer plugins.

```lua
keymap = {
```

super-tab: <Tab> selects/accepts and jumps snippets, <S-Tab> reverses, <C-n>/<C-p> cycle, <C-Space> toggles, <C-e> hides. Closest to the old nvim-cmp Tab-driven flow.


## `lua/plugins/conform.lua`

```lua
return {
```

Formatting: conform.nvim — one owner for "make this buffer well-formed". Real formatters where they exist, the language server as the fallback, on save and on demand.

```lua
markdown = { "prettier" },
```

R3. prettier is here to align markdown table pipes and normalize lists; prose must stay AS WRITTEN, because the documents in this repo are hand-wrapped at ~78 columns and reflowing them churns every diff. What makes that safe is prettier's own default: proseWrap is "preserve" unless something overrides it. Nothing does — measured 2026-08-23, this repo carries no .prettierrc, .prettierrc.json, prettier.config.js or package.json at its root, so prettier's defaults are exactly what runs here. List and table normalization is therefore NOT opt-in; it is the price of the pipe alignment.

And this key owns more buffers than its name suggests: init.lua registers `extension = { jd = "markdown" }`, so every .jd file is a markdown buffer and prettier reformats it on save. Measured with a logging shim: saving t.jd invokes `prettier --stdin-filepath <abs path to t.jd>`. There are 27 .jd files under ~/dev, so this is the common case, not a corner.

```lua
},
```

No ["markdown.mdx"] key. Nothing in this config registers the .mdx extension, so no buffer can ever hold that filetype and the entry would be dead configuration.

```lua
format_on_save = { timeout_ms = 500, lsp_format = "fallback" },
```

R4. `lsp_format = "fallback"` covers TWO cases, and the second one is silent. The obvious one is a filetype with no formatter listed above. The other, measured with an in-process fake language server and an empty PATH: a filetype whose formatter IS listed but whose binary is missing also falls through to the server, which formats the buffer while vim.notify is never called — nothing at all indicates that stylua did not run. That is why install.sh provisions the four binaries rather than assuming them.

The write ALWAYS succeeds. Every failure mode was measured to exit 0 with the file written: a timeout (WARN `Formatter 'stylua' timeout`, unformatted write, ~570 ms wall for a 2 s formatter), a formatter that fails (ERROR `Formatter failed. See :ConformInfo for details`), an absent formatter with no server (WARN `Formatters unavailable for lua file`, once per filetype per session), and no configured formatter with no server (silent). Formatting never blocks a save.


## `lua/plugins/explorer.lua`

```lua
return {
```

Directories as editable buffers: rename, create and delete files with ordinary editing commands instead of a bespoke tree UI. Replaces netrw, which lua/config/lazy.lua disables via disabled_plugins.

WHY `lazy = false` — do not "optimise" this back to a keys-only spec. The live config had no `lazy = false`, and that absence is live bug L-7. lua/config/lazy.lua sets `defaults = { lazy = false }`, but a spec that carries `keys` overrides that default: measured, the live shape reports plugins["oil.nvim"].lazy == true at startup. Three facts make eager loading non-negotiable (all measured 2026-08-23, nvim 0.12.4):

```
1. Oil installs its `default_file_explorer` hijack inside setup()
   (oil.nvim/lua/oil/config.lua:4, the option defaults to true), so
   while the plugin is unloaded it hijacks nothing.
2. With netrw disabled and oil lazy, `:e some/dir` opens an ordinary
   empty buffer named for the directory — filetype empty, one blank
   line, oil still unloaded. Neither explorer answers.
3. That is worse than stock Neovim: with "netrwPlugin" removed from
   disabled_plugins the same `:e some/dir` gives filetype = netrw and
   a real listing (netrw v184). So the dead end is this config's
   doing, not Neovim's, and this config has to undo it.
```

The cost is bounded and small: lazy reports oil's load at 3.0-3.6 ms at startup (`_.loaded.time`, three runs). Same trade 11-colorscheme R1 already makes for tinted-nvim — a thing that must be in place before the user's first action cannot be lazy on that action.

`<leader>e` stays in `keys` and is a BINDING, not a loader. lazy's Handler.setup() runs before Loader.startup(), so it registers a loader stub for the key while oil is unloaded; loading oil eagerly then calls Handler.disable -> keys:_del -> keys:_set, which deletes the stub and sets the real mapping. Read back at startup: rhs = <cmd>Oil<CR>, expr = 0. The lazy shape reads rhs = nil, expr = 1 — same desc, so a desc-only check cannot tell the two apart.


## `lua/plugins/gitsigns.lua`

```lua
return {
```

Git hunk signs in the sign column, lazy on the two file-opening events.

THE GLYPHS ARE THE WHOLE SUBJECT OF THIS FILE, and they carry their codepoints in this comment on purpose. Live bug L-10 is a codepoint lost to copy-paste: the live spec writes `delete` and `topdelete` as literally `text = ""`, so a deleted hunk gets a blank sign cell. A `U+` number beside the character is what lets a reader tell an empty string from a glyph their editor cannot draw.

```
add, change, changedelete   U+258E  LEFT ONE QUARTER BLOCK
delete, topdelete           U+F0DA  nf-fa-caret_right
```

Four measured facts, each because rediscovering it costs a debugging round.

1. L-10 FAILS SILENTLY, NOT LOUDLY. Measured 2026-08-23 against a scratch git repo with a deleted line: with `delete`'s value emptied, gitsigns still places the extmark — `sign_hl_group = GitSignsDelete`, `sign_text = nil` — so the cell renders blank and nothing errors. A deleted hunk is the one hunk kind with no line of its own to colour, so blank means invisible. A readback of the config value catches an empty string and nothing else, so checking this means reading the `gitsigns_signs_` extmarks in a scratch repo: that is the half that catches a value which reads back fine and paints nothing. 2. THE TWO GLYPH FAMILIES MUST NOT COLLAPSE. U+258E is drawn by WezTerm itself (`custom_block_glyphs = true`, measured via `wezterm ls-fonts`); U+F0DA comes from CaskaydiaCove Nerd Font. If the delete glyph ever equalled the add/change glyph, a deleted hunk would be indistinguishable from a changed one — the readable half of L-10's bug, and a check asserting only "non-empty" would pass it. 3. GITSIGNS SHELLS OUT TO `git`. Measured with a `git` stub exiting 127: gitsigns does not attach, places no sign, prints nothing, and the session still exits 0. `git` is in the `Brewfile`, and that is what keeps the silent failure off a fresh machine. Do not assume the attach is unconditional. 4. `BufNewFile` IS NOT DECORATION. Opening a path that does not exist yet inside a git worktree loads gitsigns (measured), which is why both events are named and not just `BufReadPre`.

The fallback the PRD sanctions — `_` (U+005F) for delete and `‾` (U+203E) for topdelete, which additionally keep a below/above distinction — is NOT taken here, and its condition was measured false rather than assumed: `wezterm ls-fonts --text` resolves U+F0DA to `glyph=fa-caret_right` out of CaskaydiaCoveNerdFont-Regular.ttf at `cells=1`, and WezTerm additionally ships a built-in Symbols Nerd Font Mono that covers it even with the cask absent. Taking the fallback is therefore a two-character change here and nothing else.


## `lua/plugins/lsp.lua`

```lua
return {
```

CONSTRAINT: the LSP log kill-switch is NOT here. lua/config/options.lua turns the LSP log level OFF (01-options R11) and this file must never raise it: Neovim mirrors every LSP stderr line into ~/.local/state/nvim/lsp.log with NO rotation, and a chatty rust-analyzer once grew it to 17 GB. rust_analyzer is in ensure_installed below, so this is exactly the file where turning logging up to debug a server is tempting. Raise it in a scratch probe, never here.

LSP: mason (server installer, mason-org v2) + Neovim 0.11 native LSP. nvim-lspconfig ships the per-server lsp/*.lua defaults; mason-lspconfig auto-installs and auto-enables them via vim.lsp.enable(). Per-server tweaks and capabilities go through the native vim.lsp.config() API.

```lua
{ "mason-org/mason.nvim", opts = { registry_cache = { refresh = false } } },
```

CONSTRAINT: mason must NEVER refresh its registry on its own. `registry_cache.refresh` is mason's own setting (lua/mason/settings.lua, @since 2.3.0; the pinned mason is v2.3.1 / 2a6940a, so the key is live). With it false, mason-registry's refresh() returns callback(true, {}) without touching mason-registry.installer and NO curl is spawned at all — measured 2026-08-24: zero network attempts on a launch that loads this file, against four on the default (curl and wget against both endpoints).

THE REASON IS A DISCARDED WRITE, not politeness. mason-lspconfig.setup() calls mason-registry.refresh() on every launch. When the fetch's on_spawn handler (mason-core/fetch.lua:134, wrapped in a.scope) shuts down the stdin pipe of a curl that has ALREADY EXITED, uv.shutdown fails with ENOTCONN and a.scope re-raises it with error(err, 0) from inside a libuv callback — which propagates out of WHATEVER BLOCKING CALL IS PUMPING THE LOOP at that instant. A BufWritePre consumer that pumps the loop (conform's format_lines_sync is one) therefore loses its write: the buffer is not written and the file stays byte-identical, which is data loss on a laptop that woke up on a train. Not fetching a catalogue at launch removes the promise, so there is nothing left to reject into anyone's save. See 00-delivery/corrections/offline-launch-eats-first-save.

TWO OTHER CANDIDATES WERE TRIED FIRST AND BOTH FAILED, which is why this is a setting and not a pcall: seeding <data>/mason/registries still aborted 5/5, 4/4 and 6/6, and draining the pending work under pcall before the write aborted 1/6 and then 3/6. A pcall at one call site fixes one victim at a time and was excluded on the same grounds — any BufWritePre consumer that pumps the loop inherits this.

WHAT IT COSTS, measured 2026-08-24 and real. A machine with an empty <data>/mason never bootstraps its catalogue on its own: online with the default, registries/github/mason-org/mason-registry/registry.json appears (536 KB); with this, nothing under <data>/mason is created, and ensure_installed below cannot resolve a server it cannot look up. And the catalogue then goes stale until it is refreshed by hand. Both are recoverable with ONE command; a discarded save is not.

:MasonUpdate IS THE DELIBERATE REFRESH, and mason's networking is not broken. Measured offline on a cold root, :MasonUpdate raised the network-attempt count from 0 to 2; measured online on a cold root it installed the registry and has_package("pyright") came back true afterwards. Check that PAIR if you check it at all: a zero-attempt count on its own passes just as well on a mason that is entirely broken.

```lua
vim.api.nvim_create_autocmd("LspAttach", {
```

Neovim 0.11 ships default LSP maps (grn rename, gra code action, grr references, gri implementation, gO symbols, K hover) and diagnostic maps (]d, [d). Add only the extra aliases we want.

```lua
vim.lsp.config("*", {
```

Capabilities from the completion engine, applied to every server.

```lua
vim.lsp.config("lua_ls", {
```

Per-server settings (merged over nvim-lspconfig's bundled config).

```lua
require("mason-lspconfig").setup({
```

Install + auto-enable. bashls/pyright/rust_analyzer use defaults. This call stays LAST in the body: setup() enables the installed servers synchronously, so a vim.lsp.config call placed after it would not be merged into the config the first attach reads.


## `lua/plugins/session.lua`

```lua
return {
```

Session persistence: Neovim writes the open buffer set on exit and restores it on demand, so tmux-resurrect has something to bring back after a reboot rather than an empty editor in the right directory. Owned by 07-multiplexer/06-nvim-session (epic Q12, Q13).

WHY persistence.nvim AND NOT auto-session — the choice was delegated to the analyst and the PRD's framing of it does not survive reading either plugin (both measured 2026-08-29, at the commits below):

```
* The PRD calls auto-session "branch-aware" and the one that "brings a
  picker", as if persistence.nvim were neither. persistence.nvim is
  branch-aware by default (config.lua `branch = true`, appended to the
  session name as `%%<branch>`) and ships `require("persistence").select()`,
  a picker over `vim.ui.select`. Neither is a distinguishing property.
* What actually separates them is size and WHEN THEY RESTORE.
  persistence.nvim is 180 lines in two files; auto-session is 4213
  lines across a package. persistence.nvim restores only when asked;
  auto-session's `auto_restore` fires on every bare `nvim` started in a
  directory it has a session for. That second behaviour reaches past
  this node's contract into ordinary editing — opening `nvim` by hand
  in a project would silently reopen an old buffer set — and this node
  is not licensed to change that.
* I2 ("lean on built-ins, add only what is missing") and I3 ("one
  plugin per concern") both point the same way: `:mksession` is the
  built-in, and the only thing missing from it is a place to put the
  file and a hook to write it. That is the whole of persistence.nvim.
```

WHY NOT A BARE `Session.vim` AUTOCMD (the Q13 answer that was not taken). tmux-resurrect's `@resurrect-strategy-nvim 'session'` restores with `nvim -S` only when a literal `Session.vim` exists in the pane's cwd (strategies/nvim_session.sh, read 2026-08-29), which would mean writing an untracked file into every working tree the editor was ever opened in. resurrect's *inline strategy* takes a custom restore command instead — `@resurrect-processes '"~nvim->nvim -c \"lua require(\\\"persistence\\\").load()\""'`, split on the `->` token in scripts/process_restore_helpers.sh — so the session file stays in the state directory where it belongs. That option string is this node's published interface; 07-persistence owns the file it goes in and must not invent a different one.

WHY `need = 1` IS KEPT AT ITS DEFAULT, not lowered to 0: a pane where nvim was opened and closed without a file must not overwrite a real session for that directory with an empty one. The default counts named, ordinary-buftype buffers and declines to save below the threshold.

WHY THE KEYS ARE UNDER `<leader>s` AND NOT `<leader>q` (the prefix every persistence.nvim README uses). `<leader>q` is already a LEAF map in this config — `lua/config/keymaps.lua`, desc "Quit" — so binding `<leader>qs` would turn it into a prefix and make every quit wait `timeoutlen` for a second key that usually never comes. `<leader>s` is unbound (swept 2026-08-29: the config binds -, |, b, bd, c, ca, cf, e, f, fb, ff, fg, fh, p, q, r, rn, t, tt, w and nothing on s), so session takes it and which-key gains a `session` group beside find/buffer/code/ rename-refactor/table.

`lazy = false` for the same reason 06-explorer gives: the save autocmd has to be registered before the user's first action, and a spec carrying `keys` would otherwise override `defaults = { lazy = false }` in lua/config/lazy.lua and load only on the keypress — by which time an exit could already have happened unsaved.


## `lua/plugins/statusline.lua`

```lua
local fallback_theme = "gruvbox_dark"
```

Statusline: lualine, with its theme built by hand out of the live base16 palette. The complexity here is entirely a workaround, and each piece of it is written down because the obvious shorter version is silently wrong.

WHY NOT theme = "auto" — and the reason is NOT that it errors. lualine's auto.lua collapses any colors_name beginning `base16` to its bundled base16 theme, and that theme resolves in three steps of which the third is the trap: 1. setup_base16_vim() wants vim.g.base16_gui00..base16_gui0F, or since lualine PR #1352 vim.g.tinted_gui00..tinted_gui0F. All of them are nil under tinted-nvim (measured: zero vim.g keys matching `tinted` or `base16` exist after a scheme is applied), so it returns nil. 2. setup_base16_nvim() wants the nvim-base16 module, which is absent from lazy-lock.json. Returns nil, and records one notice. 3. setup_default() — a hardcoded Tomorrow-Night palette. So `auto` exits 0, and it paints the Tomorrow-Night values #81a2be, #b5bd68, #b294bb and #de935f: colours from no scheme this config has ever applied, with the command mode collapsed onto normal because base16.lua assigns theme.command = theme.normal. The only user-facing signal is a deferred WARN two seconds in — "lualine: There are some issues with your config. Run :LualineNotices for details" — plus the :LualineNotices command appearing. Silently wrong beats broken as a failure mode, which is exactly why the theme table below is built slot by slot instead.

The fallback is lualine's builtin gruvbox_dark: a real theme file with no nvim-base16 dependency, so taking it costs nothing and the broken base16 path is never requested.

globalstatus = true is NOT redundant with lua/config/options.lua's laststatus = 3. lualine sets the option itself — 3 with globalstatus, 2 without (measured) — and it overrides options.lua, so the line has an observable effect of its own.

The separators default to Powerline private-use glyphs rather than to nothing: component_separators defaults to U+E0B1/U+E0B3 and section_separators to U+E0B0/U+E0B2. Emptying both is what removes the lualine_transitional_* groups from the rendered line (measured: 4 of them with the two lines deleted, 0 with them present).

The ColorScheme rebuild is load-bearing, and its failure mode is a STALE value, not nil: lualine registers its own ColorScheme handler, and that handler re-applies the SAME theme table. Delete the block below and a base16 switch leaves the statusline on the old palette while the cursor moves to the new one — measured across gruvbox-dark-hard to tokyo-night-dark: lualine_a_normal stayed #83a598, CursorNormal #2ac3de. Statusline and cursor then visibly disagree.

clear = true is epic I7, and what it guards is a re-run of this config function, not a :colorscheme. Measured: with clear = false the augroup still holds exactly one entry across two scheme switches, because lazy runs config once. Run config twice by hand and the count goes 1 -> 2 -> 3 with clear = false and stays 1 -> 1 -> 1 with clear = true. That second copy firing per event is live bug L-8.

get_palette() needs no eager-vs-augroup ordering worry here, unlike lua/plugins/colorscheme.lua: that node runs at priority 1000 with lazy = false, so by the time this file loads on VeryLazy the palette is committed. The eager setup call is still required — it is the first build — but the startup ColorScheme has already fired by then, which is why the handler only matters for later switches.

The diff component shells out to git: `git -C <dir> --no-pager diff --no-color --no-ext-diff -U0 -- <file>`. With no git on PATH there is no error and no crash — branch still resolves by reading .git/HEAD, and the diff section silently renders nothing. install.sh's PKGS carries git=git, and font-caskaydia-cove-nerd-font too, which is what makes the branch, file and fileformat glyphs render as icons rather than tofu.


## `lua/plugins/table-mode.lua`

```lua
local fts = { "markdown" }
```

Live table alignment while typing: the pipes realign on every `|` typed in insert mode. Complements prettier's on-save alignment (03-editor/07-formatting) — this one works *during* editing.

ONE filetype list, hoisted out of both consumers. `ft` and the FileType autocmd's `pattern` must never drift apart, and hoisting makes scoping this node a one-line change. `markdown.mdx` was dropped 2026-08-23: nothing registers the extension (`vim.filetype.match({ filename = "a.mdx" })` returns nil, and init.lua registers only `.jd`), so the filetype was unreachable and this spec never loaded for it.

```lua
vim.g.table_mode_corner = "|"
```

GitHub-flavored corners: `|` instead of vim-table-mode's default `+`.

SHADOWED IN MARKDOWN, and kept anyway. The plugin ships ftplugin/markdown_tablemode.vim setting b:table_mode_corner = '|', and tablemode#utils#get_buffer_or_global_option prefers the buffer variable — so in a markdown buffer this global is never read (measured 2026-08-23: deleting it leaves the border byte-identical, |----|----|). It bites only in a buffer with no table-mode ftplugin, reached through the `cmd` trigger: there the border is |----+----| without it.

```lua
vim.g.table_mode_map_prefix = "<leader>t"
```

`init`, not `config`, is load-bearing: plugin/table-mode.vim:48-58 derives g:table_mode_realign_map and eight siblings from the prefix at plugin LOAD time, so a prefix set in `config` would land after the maps were already built. The value itself buys no behaviour — the plugin already defaults to <Leader>t (plugin/table-mode.vim:31) — it is the written contract with which-key's `table` group (03-editor/12-small-plugins R2), whose one child is <leader>tt.

```lua
vim.api.nvim_create_autocmd("FileType", {
```

Grouped with clear = true — live bug L-8's third site. Measured: with the group, re-running this registration leaves the autocmd count unchanged; without it two registrations give two callbacks and the handler fires twice per event.

```lua
enable()
```

Belt and braces. lazy re-fires FileType UNGROUPED after loading an ft-lazy plugin (core/handler/event.lua:107 sets exclude=nil for FileType), so the autocmd above already covers the buffer that triggered the load — measured 2026-08-23 on lazy 306a055, with this line deleted the first markdown file still aligns. Kept against a lazy that re-fires with a group filter.


## `lua/plugins/telescope.lua`

```lua
return {
```

telescope.nvim — fuzzy finder. Replaces finder.nvim. Multiselect: <Tab>/<S-Tab> toggle marks. <CR> opens a single entry, but when entries are marked it sends them all to the quickfix list and opens it.

This is the EDITOR's finder, and it is the only one here. The shell has its own, and AGENTS.md settles that the two are deliberately separate tools (prds/04-shell/04-television) — nothing in this file reaches for the shell's.

```lua
local function multi_or_select(prompt_bufnr)
```

<CR>: when entries are marked, send them all to the quickfix list and open it; otherwise behave like a normal single-entry open.

```lua
local maps = {
```

Same marks/move bindings in insert and normal mode (read-only config, so both modes can share one table).

```lua
["<Tab>"] = actions.toggle_selection + actions.move_selection_worse,
```

The two rows below RESTATE telescope's own defaults: its mappings.lua:167 (insert) and :201 (normal) bind the identical toggle_selection + move_selection_* pair. Measured 2026-08-23 — deleting both leaves the mark-to-quickfix flow byte-for-byte identical, so no behavioural check can ever defend them and no counterfactual on them can go red. They are kept explicit on purpose: an upstream default change must not be able to move this environment's marks silently, and the manual documents them as our flow. Only <CR> above is ours.

```lua
pcall(telescope.load_extension, "fzf")
```

The pcall buys a CLEAN STARTUP, not a working finder — say it that way or the next reader deletes it after watching the finder survive. Measured 2026-08-23: with build/libfzf.so absent, load_extension("fzf") raises (dlopen ... no such file), and unwrapped it aborts this whole config function, so lazy reports "Failed to run `config` for telescope.nvim". The finder works either way, because telescope.setup() above has already installed the mappings by this line; what the pcall prevents is the error on startup.


## `lua/plugins/treesitter.lua`

```lua
return {
```

Treesitter: syntax-tree highlighting and indentation on nvim-treesitter's `main` branch — the new API (setup + install), no `ensure_installed` module config. Neovim 0.12 already compiles seven parsers into the binary (c, lua, markdown, markdown_inline, query, vim, vimdoc) and starts treesitter itself from its own ftplugins for lua, markdown, help and query, so this file's real subject is the OTHER nine languages plus the indentexpr everywhere.

COLD-INSTALL CONTRACT, and it is the load-bearing constraint here. `install()` compiles each missing parser from source: it needs `curl` (a tarball per language from GitHub) AND the `tree-sitter` CLI, which upstream shells out to for `tree-sitter build`. With either missing the run STILL EXITS 0 — every failure is one `:messages` line, nothing marks the config broken, and the nine non-builtin languages simply have no highlighting. Measured 2026-08-23: with PATH stripped to /usr/bin:/bin, `Error during "tree-sitter build": ENOENT ... 'tree-sitter'` per language and an empty parser dir. `tree-sitter` is NOT in the required package set (05-platform/02 R7), so a freshly provisioned machine lands in exactly that state.

`install()` is idempotent and offline-safe once warm: it short-circuits on `get_installed()` and makes zero network calls (measured). It is safe to call on every launch, which is why it lives here rather than behind a command.

HALF-INSTALLED IS A WEDGE. `get_installed()` unions the parser directory with the QUERIES directory under `stdpath("data")/site`, so a language whose queries symlink survived but whose `.so` is gone reads as installed, `install()` skips it forever, and no relaunch heals it (measured: all 16 reported installed, 0 downloads, nothing highlighted). Diagnose with `:checkhealth nvim-treesitter`; fix by deleting the stale `site/queries/<lang>` link as well as the parser.

`build = ":TSUpdate"` keeps ALREADY-INSTALLED parsers in step with the plugin's revision table; it is not what installs them. `:TSUpdate` resolves its language list through `norm_languages("all", { missing = true })`, which is `get_installed()` — empty on a cold machine, so the build step is a no-op there (measured warm: all 16 in subject; the installer is `install()` below).

```lua
local function attach(buf)
```

pcall is live, not defensive decoration: `vim.treesitter.start` calls assert() and a filetype with no parser throws `Parser could not be created for buffer N and language "go"` out of the FileType autocmd. Measured both ways 2026-08-23 — without the pcall, opening a .go file prints a Lua traceback.

```lua
vim.api.nvim_create_autocmd("FileType", {
```

I7: cleared augroup, or a second run of this config registers a second copy of the callback (measured: FileType count 4 -> 5 ungrouped, 4 -> 4 grouped). Live bug L-8.

```lua
for _, buf in ipairs(vim.api.nvim_list_bufs()) do
```

Buffers that were ALREADY filetyped before this plugin loaded get no further FileType event, so the autocmd alone never reaches them. Note what this loop is NOT for: on `nvim x.nu` the triggering buffer's filetype is still EMPTY when this config runs — FileType fires after BufReadPost, and the autocmd above is what attaches it (measured 2026-08-23: `loop:1:ft=` then `au:1:ft=nu`). Deleting the loop leaves `nvim x.nu` fully highlighted and costs a pre-typed sibling buffer its indentexpr (measured: ours vs `GetLuaIndent()`).


## `lua/plugins/which-key.lua`

```lua
return {
```

The leader-key overlay: press `<leader>` and pause, and which-key lists the groups, then the maps inside whichever one you press. `opts`, not `config` — there is nothing imperative here.

R2's "group names must stay in sync with the keymaps that live under them" IS MECHANICAL, not a discipline anyone has to keep. which-key builds a per-buffer tree and then runs `tree:fix()`, which DELETES any group node with no child keymap. So declaring a group before its keys exist is harmless: the overlay prunes rather than lying, and a group whose name is wrong is the only way this can go bad.

MEASURED, so nobody reads a short leader menu as a bug. A group renders only where one of its children has a LIVE keymap in the current buffer, and lazy's `keys =` stubs count — they are real keymaps from startup. Measured 2026-08-24 against the repo tree: `f` (telescope's `<leader>ff`/`fg`/`fb`/ `fh` stubs), `b` (`<leader>bd` in lua/config/keymaps.lua) and `c` (conform's `<leader>cf` stub) render; `r` does not, because `<leader>rn` is BUFFER-LOCAL and set on `LspAttach`, so it exists only inside a buffer with a language server attached; and `t` does not, because vim-table-mode builds its `<leader>t` maps at plugin load time and that plugin is `ft`-lazy on markdown. Proved by construction rather than inferred: seeding a global `<leader>bd`, a global `<leader>tt` and buffer-local `<leader>ca` / `<leader>rn`, then calling `require("which-key.buf").clear()`, makes all five appear with their names. That is why all five are safe to declare here — and why anything checking the RENDERED tree has to seed a buffer first, while the DECLARATIONS can be read straight out of this file.

`VeryLazy` NEVER FIRES WITHOUT A UI. lazy hooks `User VeryLazy` to `UIEnter`, so under `--headless` (`#nvim_list_uis() == 0`) which-key is never loaded and every probe has to fire the event itself. And which-key's `Config.setup` wraps its own `load` in `vim.schedule_wrap` AND defers to `VimEnter` when `vim.v.vim_did_enter == 0` — which is the case for anything in a `-c` chain — so a probe must then wait for `require("which-key.config").loaded`. Reading `Config.triggers.modes` before that flag flips throws `attempt to index field 'modes' (a nil value)`. All measured.

NO ICON PLUGIN IS NEEDED, so there is nothing to provision: `icons.mappings` defaults to true and uses which-key's own built-in set. Measured with neither mini.icons nor nvim-web-devicons loaded — `Config.issues` is empty and `:messages` is empty at startup. No health warning either.

```lua
{ "<leader>s", group = "session" },
```

Added by 07-multiplexer/06-nvim-session. It goes AFTER table, not in alphabetical order, so the five groups read f, b, c, r, t — the order 07-multiplexer/06-nvim-session's R2 states. Nothing enforces that now; append a sixth rather than sorting the list.
