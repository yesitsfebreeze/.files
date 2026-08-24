# Capabilities of the Neovim config

Companion to [`capabilities.md`](capabilities.md) and
[`capabilities-nushell.md`](capabilities-nushell.md); same rules. Ratings are
1–10 (complexity / usefulness), sorted best-first by value ratio. Markers:
nothing = take over, `SIMPLIFY` = reduced version, `DEFER` = not in the
minimal base, `DO NOT PORT` = drop.

IMPORTANT: the live config (`~/.config/nvim`, ~680 lines, lazy.nvim +
telescope + blink.cmp + native LSP) is a **different, newer config** than the
mini.nvim one described in `capabilities.md`. This inventory rates the LIVE
one; the mini.nvim entries in `capabilities.md` are superseded and should not
be ported.

## Options baseline
- `options.lua`: leader = space, relative+absolute numbers, cursorline,
  termguicolors, `scrolloff=999` (cursor line permanently centered), 2-space
  expandtab, smartindent/breakindent, smartcase search with `hlsearch` off,
  no swap/backup but `undofile` on, `updatetime=250`,
  `clipboard=unnamedplus`, mouse on, `virtualedit=block`, `laststatus=3`
  (global statusline), `fillchars.eob=" "`.
- 2
- 9
----
## Core keymaps
- `keymaps.lua` general set: `<C-hjkl>` window nav,
  `<C-arrows>` resize, `<leader>|`/`-` splits, `S-h`/`S-l` buffer cycle,
  `<leader>bd` delete buffer, `A-j`/`A-k` move line/selection, centered jumps
  (`<C-d>zz`, `n`→`nzzzv`), visual indent keeps selection, `<leader>w`/`q`,
  `<leader>p` paste-keep-register.
- **Live bug L-6, resolved — port `hlsearch = false`, drop the map.** The
  live set also binds `<Esc>` to `<cmd>nohlsearch<CR>`, which is inert:
  `options.lua` sets `hlsearch = false`, so there is never a highlight to
  clear. Two settings, one behaviour, and the backlog says port one or the
  other. `hlsearch = false` with `incsearch = true` is the behaviour actually
  in use — the match shows while you type and nothing persists after — and
  the repo's rule is that the live config wins, so the option stays and the
  map goes. *Alternative rejected:* turn `hlsearch` on and keep the `<Esc>`
  map, the LazyVim/kickstart pairing the dead map was copied from. It loses
  because it changes what every search looks like in order to give a vestigial
  map something to do, and because a map that does nothing would still have to
  be documented — `06-help`'s drift check reads the map table, so an inert
  binding becomes a manual entry describing a behaviour that never happens.
  *Recorded by W0.6 in the principal's absence; a taste reversal is the
  human's to make.*
- 2
- 9
----
## LSP log kill-switch
- `vim.lsp.log.set_level(OFF)`: nvim mirrors every LSP stderr line into
  `~/.local/state/nvim/lsp.log` with no rotation — rust-analyzer once grew it
  to 17 GB. One line, prevents a disk-filling failure.
- 1
- 7
----
## File explorer (oil.nvim)
- Directory-as-buffer editing, hidden files shown, devicons, `<leader>e`.
- **Live bug L-7, do not reproduce:** oil does *not* replace netrw for
  `:e some/dir`. The spec is lazy on `keys`, so oil's
  `default_file_explorer` hijack is not installed until `<leader>e` is
  pressed — and netrw is disabled in the plugin-manager config, so before
  that first press `:e some/dir` opens neither explorer. The port must load
  oil early enough for the hijack to be in place at the first `:e` on a
  directory (its own docs' `lazy = false`), or stop claiming the hijack.
- 2
- 8
----
## Whitespace rendering (VS Code parity)
- `list` on with `listchars` = `eol ↵`, `tab → `, `multispace ·`, `trail ·`,
  `nbsp ␣` — dots only on runs of 2+ spaces, mirroring VS Code's
  `renderWhitespace=boundary`. Dimmed via base02 Whitespace/NonText
  highlights (see Colorscheme).
- 2
- 7
----
## Load order + filetype registration
- `init.lua`: options → keymaps → autocmds → lazy (leader must exist before
  plugins load). Registers the `.jd` extension as markdown.
- 1
- 6
----
## Editor autocmds
- Highlight on yank (150ms); restore last edit position on BufReadPost
  (excluding gitcommit); trim trailing whitespace on save (preserving the
  view); `q` closes help/qf/man/lspinfo/checkhealth/startuptime buffers and
  unlists them.
- 3
- 8
----
## lazy.nvim bootstrap and plugin loading
- `config/lazy.lua` clones lazy.nvim (stable branch) on first run with a real
  error path, imports `plugins/`, `lazy = false` + no version pinning by
  default, `lazy-lock.json` committed, update checker on but silent,
  netrw/gzip/zip/tarPlugin/tohtml/tutor disabled for startup time.
- 4
- 9
----
## Completion (blink.cmp)
- One batteries-included engine (LSP, snippets, path, buffer, signature help,
  rust fuzzy matcher) replacing the nvim-cmp + LuaSnip + cmp-* stack.
  `super-tab` preset with `<CR>` accept and `<Esc>` cancel fallbacks,
  friendly-snippets, auto-shown docs after 200ms, tagged `1.*` so the
  prebuilt rust lib is fetched.
- 4
- 9
----
## Format on save (conform.nvim)
- stylua / rustfmt / black / prettier (markdown, with table-pipe alignment and
  `proseWrap=preserve`), LSP fallback, 500ms timeout, `<leader>cf` manual.
- 3
- 8
----
## Git signs
- gitsigns.nvim with custom `▎` add/change/delete glyphs, on BufReadPre.
- 2
- 7
----
## which-key
- Leader discovery overlay with named groups (find / buffer / code /
  rename / table).
- 2
- 7
----
## Autopairs
- nvim-autopairs on InsertEnter, default config.
- 1
- 6
----
## Fuzzy finder (telescope)
- telescope + fzf-native, lazy on `cmd`/`keys`. `<leader>ff` /
  `<leader><space>` files, `fg` live grep, `fb` buffers, `fh` help. Custom
  `<CR>`: with marked entries, send all to the quickfix list and open it,
  else normal open; `<Tab>`/`<S-Tab>` toggle marks and move, shared between
  insert and normal mode.
- 5
- 9
----
## Colorscheme + mode-aware cursor
- tinted-nvim on `base16-gruvbox-dark-hard`, transparent UI, blink+lualine
  integrations. Palette-derived highlights re-derived on every ColorScheme
  event: per-mode cursor colors (normal blue / insert green / visual magenta
  / replace red) wired into `guicursor` shapes, plus dimmed
  Whitespace/NonText.
- 5
- 8
----
## Treesitter
- `main` branch nvim-treesitter, `:TSUpdate` build, explicit install list
  (odin, bash, c, lua, markdown(+inline), nu, python, rust, toml, vim,
  yaml, json, query, luadoc), FileType autocmd starts highlighting and sets
  the treesitter indentexpr — including for buffers already loaded when the
  plugin lazy-loads.
- 5
- 8
----
## LSP (mason + native 0.11)
- mason v2 + mason-lspconfig auto-install/auto-enable; per-server config via
  the native `vim.lsp.config()` API; blink capabilities applied to `*`;
  lua_ls tuned (vim global, no third-party scan, no telemetry); servers:
  lua_ls, bashls, pyright, rust_analyzer, tailwindcss. Relies on nvim 0.11's
  default LSP maps and only adds `gd`/`gI`/`<leader>rn`/`<leader>ca`.
  Diagnostics: `●` virtual text, severity-sorted, rounded float with source.
- 6
- 9
----
## Markdown table mode
- vim-table-mode on markdown filetypes, GitHub-style `|` corners,
  `<leader>t` prefix, auto-enabled on FileType (including the buffer that
  triggered the lazy-load).
- 3
- 5
----
## Statusline (lualine)
- Global statusline, no separators; mode / branch+diff+diagnostics /
  filename(path=1) / encoding+fileformat+filetype / progress / location.
  Theme is BUILT from tinted-nvim's live palette and rebuilt on ColorScheme —
  never lualine's `auto`. `auto` resolves cleanly, exits 0, and silently
  paints a hardcoded Tomorrow-Night palette: `auto.lua` collapses any
  `base16-*` colorscheme to lualine's bundled `base16` theme, which
  falls through three steps — `setup_base16_vim()` wants `vim.g.base16_gui00`
  or `vim.g.tinted_gui00` (and **tinted-nvim sets zero `vim.g` keys matching
  either prefix**), `setup_base16_nvim()` wants the absent `nvim-base16`,
  then `setup_default()` paints `#81a2be` / `#b5bd68` / `#b294bb` / `#de935f`
  on `#282a2e`, with `command` collapsed onto `normal`. The only signal is a
  deferred WARN at ~2 s plus `:LualineNotices` appearing. So `auto` does not
  error — it silently paints a scheme nothing else in the environment uses,
  and `tinty apply` would not move it; `gruvbox_dark` is the pre-palette
  fallback.
- 6
- 7
----
## Smear cursor  DEFER
- smear-cursor.nvim: Neovide-style trailing cursor animation in the terminal,
  with Unicode legacy-computing glyphs for sharper smears. Pure eye candy.
- 2
- 3
----
## Shift-to-select (editor-style selection)  SIMPLIFY
- The signature customization: `Shift+arrows` start/extend a selection from
  normal, visual, or insert mode; a plain motion while in a shift-started
  selection collapses it and returns to normal mode (like a conventional
  editor), while a `v`-started selection keeps vim semantics. Tracked via a
  `shift_select` flag reset by a ModeChanged autocmd. `<C-c>` copies the
  selection, `<C-v>` pastes over it without clobbering the register.
  Genuinely useful but the most intricate hand-rolled logic in the config —
  port it deliberately, with tests, or accept plain Shift+arrow selection.
- **L-9, resolved — the `<C-v>` shadow is intentional; port it as it is.**
  `<C-v>` in visual mode is half of the CUA pair `<C-c>` copy / `<C-v>` paste
  that makes shift-select feel like a conventional editor, and porting only
  one half would be worse than porting neither. The shadow it casts is
  narrower than it looks: the map is visual-mode only, so `<C-v>` from normal
  mode still enters blockwise-visual and `virtualedit = "block"` is still
  set. What is lost is only promoting an existing charwise/linewise selection
  to blockwise — and the built-in `<C-q>`, the documented synonym for
  `<C-v>`, is unbound in this config and still does exactly that. Requirement
  for the port: leave `<C-q>` unbound, and say in the manual that it is the
  blockwise key inside a selection. *Alternative rejected:* move paste to
  another key to keep `<C-v>` blockwise everywhere — it breaks the pair that
  is the whole point of the capability, for a mode that keeps a working key.
  *Recorded by W0.6 in the principal's absence.*
- 7
- 7
----
## mini.nvim plugin set (from capabilities.md)  DO NOT PORT
- The older config's `mini.deps` bootstrap with vague theme, startify,
  noice/notify/nui, go-up. Superseded by the live lazy.nvim config; keep only
  oil + lualine + devicons, which the live config already has.
- **Reconciled with its `capabilities.md` twin (R4).** The same capability is
  rated a second time there, as `"Neovim: self-bootstrapping config"`, at
  **C 5 / U 8** and carrying **no marker** — which, read alone, says take it
  over as-is. This entry is the verdict of record: `DO NOT PORT`, superseded
  by the live lazy.nvim config.
- **Why the two U numbers differ, and which binds.** U 8 rates the capability
  in its own era, against no alternative; U 2 rates it against the live
  lazy.nvim baseline that replaces it. Both are honest measurements of
  different questions. A PRD sourcing this capability takes **C 5 / U 2** —
  the rebuild is the context that matters. Still open: adding the missing
  marker on the `capabilities.md` side needs the author's confirmation, since
  that file is user-authored; see the `## Questions` on
  `00-delivery/corrections/w0-4-s2-corrections/docs-inventories`.
- 5
- 2
----
## Insert-mode-first modal inversion  DO NOT PORT
- Already marked DO NOT PORT in `capabilities.md`, and absent from the live
  config: autocmds forcing insert mode, `<Esc>` disabled, `<F24>` hardware
  remap for normal mode. Requires Karabiner (also dropped).
- **The twin, named (R4).** That second rating is
  `"Neovim: insert-mode-first modal inversion"` in `capabilities.md`, at
  C 8 / U 6. Only the U diverges, and for the same reason as the mini.nvim
  pair: **U 6** rates it in its own era, **U 2** rates it against the live
  config that does not have it. Both sides already carry `DO NOT PORT`, so
  the verdict needs no confirmation; **C 8 / U 2** binds for the rebuild.
- 8
- 2
----
