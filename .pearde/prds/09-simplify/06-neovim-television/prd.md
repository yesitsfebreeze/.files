---
state: open        # open|analyzing|refine|question|specced|claimed|blocked|done|failed
origin: requested  # requested = the user asked | derived = the board found it
priority: 30        # higher first
complexity: 0      # analyst, at spec time — 1-100. THE WEIGHT the board schedules by
blast-radius: mid
repo:
time:
  est:
  actual:
needs:
  - 09-simplify/03-help-system
footprint:
  - home/dot_config/nvim
  - home/dot_config/television/config.toml
  - home/dot_config/television/cable
  - home/dot_config/television/executable_theme-preview.sh
  - home/run_after_seed-mason-registry.sh
  - home/dot_config/nushell/help/nvim.nuon
  - .pearde/prds/00-delivery/decisions/shift-select-scope/prd.md
---

# 06-neovim-television — built-ins over wrappers, five channels not twenty-one

Parent: [`09-simplify`](../prd.md) · meta, no C/U

Purpose: only five television channels are reachable from a key; sixteen
exist for `tv <name>` typed by hand, and six of those duplicate another
channel or a built-in. `shift-select.lua` is 81 lines for what
`vim.o.keymodel` does in one; `statusline.lua` hand-builds a six-mode theme
that tinted-nvim ships; `claude.lua` re-implements `cll`'s profile resolver
in Lua although it already spawns through `cll`. The mason hook is 104
lines, 53 of them comments citing deleted tests. Measured 2026-09-02 on
Neovim 0.12.5; re-read before cutting.

## Requirements

- [ ] **R1** — `cable/git-files.toml`, `git-branch.toml`, `zoxide.toml`,
      `alias.toml`, `env.toml` and `nvim/lua/plugins/init.lua` (`return {}`)
      are deleted. `channels.toml` is deleted by `04-nushell`.
- [ ] **R2** — The edit action in `files.toml`, `text.toml`,
      `recent-files.toml`, `git-log.toml` and `docs.toml` is one string with
      `nvim` as the fallback. `recent-files.toml` uses
      `fd -t f --changed-within 7d` instead of `find` over the last ten
      commits. `theme.toml.tmpl` becomes `theme.toml` — `~` expands in the
      command already, as `manual.toml:32` proved. `config.toml` loses the
      three `border_type = "rounded"` lines that restate the default.
- [ ] **R3** — `statusline.lua` becomes `theme = "tinted"` with the
      `filename path = 1` section kept; the hand-built theme and the
      ColorScheme re-setup (:28-57) go.
- [ ] **R4** — `claude.lua` loses the profile resolver (:74-111 — `cll`
      does it, and `terminal_cmd = "cll"` at :50 already spawns through it),
      `provider = "auto"` (:53, overwritten at :67), and the four explorers
      that are not installed (:39).
- [ ] **R5** — `shift-select.lua` becomes `vim.o.keymodel =
      "startsel,stopsel"` plus the `<C-c>`/`<C-v>` maps (:80-81). This
      re-takes the 2026-08-21 fork: `decisions/shift-select-scope` gains a
      dated paragraph saying the built-in replaced the port and what it does
      not do (collapse on `hjkl`, the `lv<Right>` insert quirk), and the
      rating note in `03-editor/14` is updated. The `nvim.nuon` entries for
      `<S-…>` and `h j k l (visual)` say what the built-in does.
- [ ] **R6** — `lsp.lua:27-30` (`gd`, `gI`, `<leader>rn`, `<leader>ca`) go;
      `grn`, `gra`, `gri`, `grr`, `gO` are the built-ins and `nvim.nuon`
      already documents them. `options.lua` loses `incsearch`, `backup`,
      `cmdheight`, `termguicolors`, `completeopt` and `mouse = "a"` — each
      is the default or ignored by blink.
- [ ] **R7** — The mason hook is decided one way: (a) delete
      `run_after_seed-mason-registry.sh` and `ensure_installed`, install the
      five servers once with `:MasonInstall`; or (b) keep the hook at its
      ~30 mechanism lines with the memo path corrected to
      `.pearde/memos/mason-refresh-off-trades-auto-bootstrap.md`. The
      analyst puts the choice as the one question; (a) is recommended for
      one machine.
- [ ] **R8** — `theme-preview.sh` keeps the header line, the OSC 11 retint
      (:73) and the swatch grid (:139-160); the banner box, the fake code
      card (:95-137) and the bash-3.2 indirection (:48-54) go.
- [ ] **R9** — `just manual` is run after `nvim.nuon` changes.

## Acceptance

- [ ] `tv list-channels | wc -l` prints at most 15 and `ls home/dot_config/television/cable | wc -l` prints at most 15
- [ ] `nvim --headless "+Lazy! sync" +qa` exits 0; `nvim --headless +qa` prints no error
- [ ] in nvim: Shift-Down three times then Down collapses the selection; the same from insert mode; `grn` renames in a Lua buffer; the statusline follows two `tinty apply` calls without a restart; `<leader>xc` opens Claude through `cll`
- [ ] `theme` in the shell retints while scrolling and restores on Esc
- [ ] `wc -l home/dot_config/nvim/lua/config/shift-select.lua home/dot_config/nvim/lua/plugins/statusline.lua home/dot_config/nvim/lua/plugins/claude.lua` prints at most 12, 20 and 75
- [ ] `rg -l 'tests/' home/dot_config/nvim home/dot_config/television home/run_after_seed-mason-registry.sh` prints nothing (or the file is gone)

## Out of scope

- `docs.toml`, `nu-history.toml`, `quicklist.toml`, `git-log.toml`'s
  hash-by-regex — kept as they are.
- `cht.toml`, `cht-query.toml`, `channels.toml` — `04-nushell`.
