---
state: done        # open|analyzing|refine|question|specced|claimed|blocked|done|failed
origin: requested  # requested = the user asked | derived = the board found it
priority: 30        # higher first
complexity: 25      # analyst, at spec time — 1-100. THE WEIGHT the board schedules by
blast-radius: mid
repo:
time:
  est:
  actual: 0.94h
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
workflow: land-an-answered-fork
commit: 67784bb
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

- [x] **R1** — `cable/git-files.toml`, `git-branch.toml`, `zoxide.toml`,
      `alias.toml`, `env.toml` and `nvim/lua/plugins/init.lua` (`return {}`)
      are deleted. `channels.toml` is deleted by `04-nushell`.
- [x] **R2** — The edit action in `files.toml`, `text.toml`,
      `recent-files.toml` and `docs.toml` is one string with `nvim` as the
      fallback. **Corrected 2026-09-02, before dispatch**: `git-log.toml`
      was dropped from this list — it has no `[actions.edit]` at all (only
      cherry-pick/revert/checkout), so there is no edit action to unify;
      the analyst's pass-1 build confirmed this by direct read and left it
      untouched rather than inventing one. `recent-files.toml` uses
      `fd -t f --changed-within 7d` instead of `find` over the last ten
      commits. `theme.toml.tmpl` becomes `theme.toml` — `~` expands in the
      command already, as `manual.toml:32` proved. `config.toml` loses the
      three `border_type = "rounded"` lines that restate the default.
- [x] **R3** — `statusline.lua` becomes `theme = "tinted"` with the
      `filename path = 1` section kept; the hand-built theme and the
      ColorScheme re-setup (:28-57) go.
- [x] **R4** — `claude.lua` loses the profile resolver (:74-111 — `cll`
      does it, and `terminal_cmd = "cll"` at :50 already spawns through it),
      `provider = "auto"` (:53, overwritten at :67), and the four explorers
      that are not installed (:39).
- [x] **R5** — `shift-select.lua` becomes `vim.o.keymodel =
      "startsel,stopsel"` plus the `<C-c>`/`<C-v>` maps (:80-81). This
      re-takes the 2026-08-21 fork: `decisions/shift-select-scope` gains a
      dated paragraph saying the built-in replaced the port and what it does
      not do (collapse on `hjkl`, the `lv<Right>` insert quirk), and the
      rating note in `03-editor/14` is updated. The `nvim.nuon` entries for
      `<S-…>` and `h j k l (visual)` say what the built-in does.
- [x] **R6** — `lsp.lua:27-30` (`gd`, `gI`, `<leader>rn`, `<leader>ca`) go;
      `grn`, `gra`, `gri`, `grr`, `gO` are the built-ins and `nvim.nuon`
      already documents them. `options.lua` loses `incsearch`, `backup`,
      `cmdheight`, `termguicolors`, `completeopt` and `mouse = "a"` — each
      is the default or ignored by blink.
- [x] **R7** — The mason hook is decided one way: (a) delete
      `run_after_seed-mason-registry.sh` and `ensure_installed`, install the
      five servers once with `:MasonInstall`; or (b) keep the hook at its
      ~30 mechanism lines with the memo path corrected to
      `.pearde/memos/mason-refresh-off-trades-auto-bootstrap.md`. The
      analyst puts the choice as the one question; (a) is recommended for
      one machine.
- [x] **R8** — `theme-preview.sh` keeps the header line, the OSC 11 retint
      (:73) and the swatch grid (:139-160); the banner box, the fake code
      card (:95-137) and the bash-3.2 indirection (:48-54) go.
- [x] **R9** — `just manual` is run after `nvim.nuon` changes.

## Acceptance

- [x] The television surface this repo owns is at most 16 channels and at
      most 15 cable files in the tree: `tv list-channels | wc -l` is at most
      16 against an `XDG_CONFIG_HOME` holding only this repo's television
      configuration, and `ls home/dot_config/television/cable | wc -l` is at
      most 15.
      **Rewritten 2026-09-02 by `implementer-neovim-tv`** — the box as
      dispatched read `tv list-channels | wc -l` with no `XDG_CONFIG_HOME`
      named, which measures the machine's whole cable directory, not this
      repo's surface, so it could be red for work no PRD here owns. The
      **Corrected 2026-09-02, before dispatch** note it replaces still holds
      and is why the ceiling is 16 rather than 15: `tv` 0.15.9 bakes in ten
      channel names before the cable directory is read (an empty fixture
      measures exactly `10`), and R1+R2's ten kept files add six names those
      builtins do not cover. There is no in-scope file left to drop that
      would reach 15.
      **Measured after the `home/.chezmoiremove` apply: both clauses hold.**
      Isolated fixture: `16` channels over `10` cable files. Repo: `ls
      home/dot_config/television/cable | wc -l` → `10`. `chezmoi apply` never
      removes a file it has stopped managing, so R1's five deletions needed
      the retirement mechanism `03-help-system` built and `04-nushell`
      reused: five lines appended to `home/.chezmoiremove`, then a `chezmoi
      apply` naming the five target paths. All five are now gone from
      `$HOME`.
      **A third clause — `ls ~/.config/television/cable | wc -l` at most 15 —
      was struck 2026-09-02 and transferred whole, with its measurements, to
      `09-simplify/retire-the-unmanaged-television-channels`, where it is now
      that node's acceptance box.** It was not tuned away and it was not
      dropped. It stayed in this box until `9b80a71` had landed and been
      measured: before that commit the number was movable by work inside this
      PRD's footprint and this PRD had not moved it, which is exactly why the
      skeptic ruled on 2026-09-02 that it stayed. After it, the machine reads
      `23` and `13` of those files — `bg`, `burrito-sessions`,
      `git-deletions`, `git-diff`, `git-reflog`, `git-remotes`, `git-repos`,
      `git-stash`, `git-submodules`, `git-tags`, `git-worktrees`, `opacity`,
      `opencode-sessions` — were never managed by this repo at all, so
      nothing this node's footprint reaches can move `23` toward `15`. The
      second reason it moves: once those thirteen are gone the machine clause
      and the fixture clause measure the same ten files and the same `16`, so
      a clause that becomes a verbatim duplicate of its neighbour the moment
      its blocker clears was never a check on this node. Same shape, and same
      ruling, as the struck `tinty apply` clause below.
      **The rule this sets, for the next box that looks like this:** a clause
      may leave a PRD only after the in-footprint work that could have moved
      it has landed and been measured, with the commit named. `9b80a71` is
      that receipt here.
- [x] `nvim --headless "+Lazy! sync" +qa` exits 0; `nvim --headless +qa` prints no error
      — re-run 2026-09-02 by `implementer-neovim-tv`; both exit 0, no stderr.
- [x] in nvim: Shift-Down three times then Down collapses the selection; the same from insert mode; `grn` renames in a Lua buffer; ~~the statusline follows two `tinty apply` calls without a restart~~; `<leader>xc` opens Claude through `cll`
      **The `tinty apply` clause is struck 2026-09-02 and handed off — it
      was never this node's to pass.** There is no nvim leg in the palette
      path to regress: tinty's only hook is `tinty/config.toml` running
      `tmux-colors.sh`, and that script names `nvim` nowhere, at HEAD or in
      the working tree. The autocmd R3 deleted
      (`7f98da4^:.../statusline.lua:51-57`) fires on `ColorScheme`, an
      in-process event, so it followed `:colorscheme` and never a `tinty
      apply` from outside. Measured anyway: two real `tinty apply` calls
      against a live nvim left `colors_name` and `lualine_a_normal` unmoved,
      and the machine's scheme was restored afterwards.
      **The four remaining clauses are green, measured live in a real pty
      (tmux).** Shift-Down x3 from line 1 → `mode=v cursor=4 anchor=1`; a
      bare Down after it → `mode=n cursor=5 anchor=5` (the collapse); from
      insert mode, `i` then Shift-Down x2 → `mode=v cursor=3 anchor=1`;
      `<leader>xc` is mapped and `claudecode`'s own merged state reads
      `terminal_cmd=cll`. `grn` and `gra` are both mapped in normal mode as
      Neovim 0.11 built-ins, which is what R6 deleted `lsp.lua:27-30` in
      favour of. What R3 replaced the autocmd with is proven independently:
      three consecutive `:colorscheme` changes in one live nvim moved
      `lualine_a_normal` `#665c54/#1d2021` → `#bdae93/#f9f5d7` →
      `#4c566a/#2e3440`, no restart and no autocmd, while
      `theme.normal.a` stayed `nil/nil` throughout — the `tinted` lualine
      theme is group-name based.
- [x] `theme` in the shell retints while scrolling and restores on Esc
      — driven in a real pty: three focused rows emitted three distinct OSC 11
      backgrounds (`#1d2021`, `#090300`, `#262427`), and Esc emitted a fourth
      OSC 11 restoring `#1d2021`, with `current_scheme` unchanged
      (`theme.nu:70-72` restores by re-setting the saved background, not by
      OSC 111). This box was red for a reason no one had measured: the
      channel's source command listed nothing at all — see `## Findings` in
      the report; fixed inside `theme.toml`.
- [x] `wc -l home/dot_config/nvim/lua/config/shift-select.lua home/dot_config/nvim/lua/plugins/statusline.lua home/dot_config/nvim/lua/plugins/claude.lua` prints at most 12, 20 and 75
      — `8 20 71`.
- [x] `rg -l 'tests/' home/dot_config/nvim home/dot_config/television home/run_after_seed-mason-registry.sh` prints nothing (or the file is gone)
      — no output; `rg` exit 1.

## Out of scope

- `docs.toml`, `nu-history.toml`, `quicklist.toml`, `git-log.toml`'s
  hash-by-regex — kept as they are.
- `cht.toml`, `cht-query.toml`, `channels.toml` — `04-nushell`.

## Questions

### Q1: What a brand new machine does about its editor's language tools

You are choosing what happens the first time this editor configuration
lands on a brand new machine: whether it quietly fetches its language-server
tools for you, or leaves that as something you do yourself once?

1. **Automatic** — the editor quietly installs its language-server tools the first time it runs on a new machine, with no extra step from you. (recommended)
2. **One-time step** — you run one command yourself the first time, and the editor never touches this on its own again.
3. **Only when you ask** — nothing installs on its own, ever; you fetch a language-server tool the moment a project actually needs it.

<!-- for the board: 09-simplify/06-neovim-television R7 — option 1 keeps
home/run_after_seed-mason-registry.sh (~30 mechanism lines, MASON_SEED
gate) with its memo path corrected to
.pearde/memos/mason-refresh-off-trades-auto-bootstrap.md; option 2 deletes
that run_after and ensure_installed in lua/plugins/lsp.lua, installing the
five servers once with :MasonInstall; option 3 also drops
`ensure_installed` from mason-lspconfig's setup entirely, leaving server
installation to interactive :Mason use, never scripted. Whichever is
chosen also resolves the R7-tied acceptance box `rg -l 'tests/' ...`
(currently red — the hook still cites two deleted test files). -->

## Answers

**Q1** *(answered 2026-09-02 14:14)* — Automatic.

## Report

spec01-channels-and-lua: exit 0
[35m[blink.cmp] [0m[36m      fetch[0m[90m | [0m[34mRunning task fetch[0m
[35m[claude-tmux.nvim] [0m[36mfetch[0m[90m | [0m[34mRunning task fetch[0m
[35m[claudecode.nvim] [0m[36mfetch[0m[90m | [0m[34mRunning task fetch[0m
[35m[conform.nvim] [0m[36m   fetch[0m[90m | [0m[34mRunning task fetch[0m
[35m[friendly-snippets] [0m[36mfetch[0m[90m | [0m[34mRunning task fetch[0m
[35m[gitsigns.nvim] [0m[36m  fetch[0m[90m | [0m[34mRunning task fetch[0m
[35m[lazy.nvim] [0m[36m      fetch[0m[90m | [0m[34mRunning task fetch[0m
[35m[lualine.nvim] [0m[36m   fetch[0m[90m | [0m[34mRunning task fetch[0m
[35m[mason-lspconfig.nvim] [0m[36mfetch[0m[90m | [0m[34mRunning task fetch[0m
[35m[mason.nvim] [0m[36m     fetch[0m[90m | [0m[34mRunning task fetch[0m
[35m[nvim-autopairs] [0m[36m fetch[0m[90m | [0m[34mRunning task fetch[0m
[35m[nvim-lspconfig] [0m[36m fetch[0m[90m | [0m[34mRunning task fetch[0m
[35m[nvim-treesitter] [0m[36mfetch[0m[90m | [0m[34mRunning task fetch[0m
[35m[nvim-web-devicons] [0m[36mfetch[0m[90m | [0m[34mRunning task fetch[0m
[35m[oil.nvim] [0m[36m       fetch[0m[90m | [0m[34mRunning task fetch[0m
[35m[persistence.nvim] [0m[36mfetch[0m[90m | [0m[34mRunning task fetch[0m
[35m[plenary.nvim] [0m[36m   fetch[0m[90m | [0m[34mRunning task fetch[0m
[35m[smear-cursor.nvim] [0m[36mfetch[0m[90m | [0m[34mRunning task fetch[0m
[35m[snacks.nvim] [0m[36m    fetch[0m[90m | [0m[34mRunning task fetch[0m
[35m[telescope-fzf-native.nvim] [0m[36mfetch[0m[90m | [0m[34mRunning task fetch[0m
[35m[telescope.nvim] [0m[36m fetch[0m[90m | [0m[34mRunning task fetch[0m
[35m[tinted-nvim] [0m[36m    fetch[0m[90m | [0m[34mRunning task fetch[0m
[35m[vim-table-mode] [0m[36m fetch[0m[90m | [0m[34mRunning task fetch[0m
[35m[which-key.nvim] [0m[36m fetch[0m[90m | [0m[34mRunning task fetch[0m
[35m[claudecode.nvim] [0m[36mfetch[0m[90m | [0m[34mFinished task fetch in 676ms[0m
[35m[claudecode.nvim] [0m[36mstatus[0m[90m | [0m[34mRunning task status[0m
[35m[smear-cursor.nvim] [0m[36mfetch[0m[90m | [0m[34mFinished task fetch in 734ms[0m
[35m[smear-cursor.nvim] [0m[36mstatus[0m[90m | [0m[34mRunning task status[0m
[35m[nvim-lspconfig] [0m[36m fetch[0m[90m | [0m[34mFinished task fetch in 738ms[0m
[35m[nvim-lspconfig] [0m[36mstatus[0m[90m | [0m[34mRunning task status[0m
[35m[claudecode.nvim] [0m[36mstatus[0m[90m | [0m[34mFinished task status in 57ms[0m
[35m[claudecode.nvim] [0m[36mcheckout[0m[90m | [0m[34mRunning task checkout[0m
[35m[claudecode.nvim] [0m[36mcheckout[0m[90m | [0m[34mFinished task checkout in 0ms[0m
[35m[smear-cursor.nvim] [0m[36mstatus[0m[90m | [0m[34mFinished task status in 16ms[0m
[35m[smear-cursor.nvim] [0m[36mcheckout[0m[90m | [0m[34mRunning task checkout[0m
[35m[smear-cursor.nvim] [0m[36mcheckout[0m[90m | [0m[34mFinished task checkout in 0ms[0m
[35m[nvim-lspconfig] [0m[36mstatus[0m[90m | [0m[34mFinished task status in 23ms[0m
[35m[nvim-lspconfig] [0m[36mcheckout[0m[90m | [0m[34mRunning task checkout[0m
[35m[persistence.nvim] [0m[36mfetch[0m[90m | [0m[34mFinished task fetch in 785ms[0m
[35m[nvim-lspconfig] [0m[36mcheckout[0m[90m | [0mHEAD is now at ee1e3691 fix(util): undefined variable #4520
[35m[persistence.nvim] [0m[36mstatus[0m[90m | [0m[34mRunning task status[0m
[35m[nvim-lspconfig] [0m[36mcheckout[0m[90m | [0m[34mFinished task checkout in 21ms[0m
[35m[persistence.nvim] [0m[36mstatus[0m[90m | [0m[34mFinished task status in 11ms[0m
[35m[persistence.nvim] [0m[36mcheckout[0m[90m | [0m[34mRunning task checkout[0m
[35m[persistence.nvim] [0m[36mcheckout[0m[90m | [0m[34mFinished task checkout in 0ms[0m
[35m[oil.nvim] [0m[36m       fetch[0m[90m | [0m[34mFinished task fetch in 821ms[0m
[35m[oil.nvim] [0m[36m      status[0m[90m | [0m[34mRunning task status[0m
[35m[gitsigns.nvim] [0m[36m  fetch[0m[90m | [0m[34mFinished task fetch in 857ms[0m
[35m[gitsigns.nvim] [0m[36m status[0m[90m | [0m[34mRunning task status[0m
[35m[friendly-snippets] [0m[36mfetch[0m[90m | [0m[34mFinished task fetch in 866ms[0m
[35m[friendly-snippets] [0m[36mstatus[0m[90m | [0m[34mRunning task status[0m
[35m[oil.nvim] [0m[36m      status[0m[90m | [0m[34mFinished task status in 36ms[0m
[35m[oil.nvim] [0m[36m    checkout[0m[90m | [0m[34mRunning task checkout[0m
[35m[oil.nvim] [0m[36m    checkout[0m[90m | [0m[34mFinished task checkout in 0ms[0m
[35m[gitsigns.nvim] [0m[36m status[0m[90m | [0m[34mFinished task status in 23ms[0m
[35m[gitsigns.nvim] [0m[36mcheckout[0m[90m | [0m[34mRunning task checkout[0m
[35m[gitsigns.nvim] [0m[36mcheckout[0m[90m | [0mHEAD is now at 5be654f fix(change_base): handle files missing from revision
[35m[friendly-snippets] [0m[36mstatus[0m[90m | [0m[34mFinished task status in 34ms[0m
[35m[friendly-snippets] [0m[36mcheckout[0m[90m | [0m[34mRunning task checkout[0m
[35m[friendly-snippets] [0m[36mcheckout[0m[90m | [0m[34mFinished task checkout in 4ms[0m
[35m[gitsigns.nvim] [0m[36mcheckout[0m[90m | [0m[34mFinished task checkout in 14ms[0m
[35m[which-key.nvim] [0m[36m fetch[0m[90m | [0m[34mFinished task fetch in 911ms[0m
[35m[which-key.nvim] [0m[36mstatus[0m[90m | [0m[34mRunning task status[0m
[35m[vim-table-mode] [0m[36m fetch[0m[90m | [0m[34mFinished task fetch in 916ms[0m
[35m[vim-table-mode] [0m[36mstatus[0m[90m | [0m[34mRunning task status[0m
[35m[which-key.nvim] [0m[36mstatus[0m[90m | [0m[34mFinished task status in 29ms[0m
[35m[which-key.nvim] [0m[36mcheckout[0m[90m | [0m[34mRunning task checkout[0m
[35m[which-key.nvim] [0m[36mcheckout[0m[90m | [0m[34mFinished task checkout in 0ms[0m
[35m[lazy.nvim] [0m[36m      fetch[0m[90m | [0m[34mFinished task fetch in 953ms[0m
[35m[lazy.nvim] [0m[36m     status[0m[90m | [0m[34mRunning task status[0m
[35m[vim-table-mode] [0m[36mstatus[0m[90m | [0m[34mFinished task status in 33ms[0m
[35m[vim-table-mode] [0m[36mcheckout[0m[90m | [0m[34mRunning task checkout[0m
[35m[vim-table-mode] [0m[36mcheckout[0m[90m | [0m[34mFinished task checkout in 0ms[0m
[35m[plenary.nvim] [0m[36m   fetch[0m[90m | [0m[34mFinished task fetch in 963ms[0m
[35m[plenary.nvim] [0m[36m  status[0m[90m | [0m[34mRunning task status[0m
[35m[lazy.nvim] [0m[36m     status[0m[90m | [0m[34mFinished task status in 16ms[0m
[35m[tinted-nvim] [0m[36m    fetch[0m[90m | [0m[34mFinished task fetch in 979ms[0m
[35m[lazy.nvim] [0m[36m   checkout[0m[90m | [0m[34mRunning task checkout[0m
[35m[tinted-nvim] [0m[36m   status[0m[90m | [0m[34mRunning task status[0m
[35m[plenary.nvim] [0m[36m  status[0m[90m | [0m[34mFinished task status in 21ms[0m
[35m[lazy.nvim] [0m[36m   checkout[0m[90m | [0mHEAD is now at 306a055 chore(build): auto-generate rockspec mappings
[35m[plenary.nvim] [0m[36mcheckout[0m[90m | [0m[34mRunning task checkout[0m
[35m[lazy.nvim] [0m[36m   checkout[0m[90m | [0m[34mFinished task checkout in 19ms[0m
[35m[lualine.nvim] [0m[36m   fetch[0m[90m | [0m[34mFinished task fetch in 1001ms[0m
[35m[lualine.nvim] [0m[36m  status[0m[90m | [0m[34mRunning task status[0m
[35m[plenary.nvim] [0m[36mcheckout[0m[90m | [0mHEAD is now at 74b06c6 docs: provide info in readme that plenary will be archived in Q2 2026 (#677)
[35m[tinted-nvim] [0m[36m   status[0m[90m | [0m[34mFinished task status in 22ms[0m
[35m[tinted-nvim] [0m[36m checkout[0m[90m | [0m[34mRunning task checkout[0m
[35m[plenary.nvim] [0m[36mcheckout[0m[90m | [0m[34mFinished task checkout in 15ms[0m
[35m[lualine.nvim] [0m[36m  status[0m[90m | [0m[34mFinished task status in 13ms[0m
[35m[tinted-nvim] [0m[36m checkout[0m[90m | [0mHEAD is now at a1f4cd3 Update with the latest tinted-theming colorschemes [skip ci]
[35m[lualine.nvim] [0m[36mcheckout[0m[90m | [0m[34mRunning task checkout[0m
[35m[lualine.nvim] [0m[36mcheckout[0m[90m | [0mHEAD is now at 221ce6b fix: re-deepcopy extension sections to avoid shared-ref mutation (#1507) (#1509)
[35m[tinted-nvim] [0m[36m checkout[0m[90m | [0m[34mFinished task checkout in 22ms[0m
[35m[lualine.nvim] [0m[36mcheckout[0m[90m | [0m[34mFinished task checkout in 9ms[0m
[35m[mason-lspconfig.nvim] [0m[36mfetch[0m[90m | [0m[34mFinished task fetch in 1048ms[0m
[35m[mason-lspconfig.nvim] [0m[36mstatus[0m[90m | [0m[34mRunning task status[0m
[35m[nvim-web-devicons] [0m[36mfetch[0m[90m | [0m[34mFinished task fetch in 1074ms[0m
[35m[nvim-web-devicons] [0m[36mstatus[0m[90m | [0m[34mRunning task status[0m
[35m[mason-lspconfig.nvim] [0m[36mstatus[0m[90m | [0m[34mFinished task status in 22ms[0m
[35m[mason-lspconfig.nvim] [0m[36mcheckout[0m[90m | [0m[34mRunning task checkout[0m
[35m[mason-lspconfig.nvim] [0m[36mcheckout[0m[90m | [0mHEAD is now at 40276c4 chore: update generated code (#693)
[35m[nvim-web-devicons] [0m[36mstatus[0m[90m | [0m[34mFinished task status in 23ms[0m
[35m[nvim-web-devicons] [0m[36mcheckout[0m[90m | [0m[34mRunning task checkout[0m
[35m[mason-lspconfig.nvim] [0m[36mcheckout[0m[90m | [0m[34mFinished task checkout in 13ms[0m
[35m[nvim-web-devicons] [0m[36mcheckout[0m[90m | [0mHEAD is now at 5f032a8 feat: change clang icons to llvm dragon logo (#654)
[35m[nvim-web-devicons] [0m[36mcheckout[0m[90m | [0m[34mFinished task checkout in 14ms[0m
[35m[claude-tmux.nvim] [0m[36mfetch[0m[90m | [0m[34mFinished task fetch in 1318ms[0m
[35m[claude-tmux.nvim] [0m[36mstatus[0m[90m | [0m[34mRunning task status[0m
[35m[snacks.nvim] [0m[36m    fetch[0m[90m | [0m[34mFinished task fetch in 1331ms[0m
[35m[snacks.nvim] [0m[36m   status[0m[90m | [0m[34mRunning task status[0m
[35m[claude-tmux.nvim] [0m[36mstatus[0m[90m | [0m[34mFinished task status in 23ms[0m
[35m[claude-tmux.nvim] [0m[36mcheckout[0m[90m | [0m[34mRunning task checkout[0m
[35m[claude-tmux.nvim] [0m[36mcheckout[0m[90m | [0m[34mFinished task checkout in 0ms[0m
[35m[snacks.nvim] [0m[36m   status[0m[90m | [0m[34mFinished task status in 111ms[0m
[35m[snacks.nvim] [0m[36m checkout[0m[90m | [0m[34mRunning task checkout[0m
[35m[snacks.nvim] [0m[36m checkout[0m[90m | [0m[34mFinished task checkout in 0ms[0m
[35m[blink.cmp] [0m[36m      fetch[0m[90m | [0m[34mFinished task fetch in 1475ms[0m
[35m[blink.cmp] [0m[36m     status[0m[90m | [0m[34mRunning task status[0m
[35m[blink.cmp] [0m[36m     status[0m[90m | [0m[34mFinished task status in 23ms[0m
[35m[blink.cmp] [0m[36m   checkout[0m[90m | [0m[34mRunning task checkout[0m
[35m[blink.cmp] [0m[36m   checkout[0m[90m | [0mHEAD is now at 78336bc chore: bump version to 1.10.2
[35m[blink.cmp] [0m[36m   checkout[0m[90m | [0m[34mFinished task checkout in 47ms[0m
[35m[mason.nvim] [0m[36m     fetch[0m[90m | [0m[34mFinished task fetch in 1674ms[0m
[35m[mason.nvim] [0m[36m    status[0m[90m | [0m[34mRunning task status[0m
[35m[mason.nvim] [0m[36m    status[0m[90m | [0m[34mFinished task status in 56ms[0m
[35m[mason.nvim] [0m[36m  checkout[0m[90m | [0m[34mRunning task checkout[0m
[35m[mason.nvim] [0m[36m  checkout[0m[90m | [0m[34mFinished task checkout in 0ms[0m
[35m[nvim-autopairs] [0m[36m fetch[0m[90m | [0m[34mFinished task fetch in 1799ms[0m
[35m[nvim-autopairs] [0m[36mstatus[0m[90m | [0m[34mRunning task status[0m
[35m[nvim-treesitter] [0m[36mfetch[0m[90m | [0m[34mFinished task fetch in 1808ms[0m
[35m[nvim-treesitter] [0m[36mstatus[0m[90m | [0m[34mRunning task status[0m
[35m[nvim-autopairs] [0m[36mstatus[0m[90m | [0m[34mFinished task status in 23ms[0m
[35m[nvim-autopairs] [0m[36mcheckout[0m[90m | [0m[34mRunning task checkout[0m
[35m[nvim-treesitter] [0m[36mstatus[0m[90m | [0m[34mFinished task status in 33ms[0m
[35m[nvim-autopairs] [0m[36mcheckout[0m[90m | [0mHEAD is now at 430522f fix: pairing after entering insert mode by action with count (#543) (#550)
[35m[nvim-treesitter] [0m[36mcheckout[0m[90m | [0m[34mRunning task checkout[0m
[35m[nvim-autopairs] [0m[36mcheckout[0m[90m | [0m[34mFinished task checkout in 23ms[0m
[35m[nvim-treesitter] [0m[36mcheckout[0m[90m | [0mHEAD is now at 427e9222 feat(proto)!: update parser and queries
[35m[nvim-treesitter] [0m[36mcheckout[0m[90m | [0m[34mFinished task checkout in 22ms[0m
[35m[telescope-fzf-native.nvim] [0m[36mfetch[0m[90m | [0m[34mFinished task fetch in 1920ms[0m
[35m[telescope-fzf-native.nvim] [0m[36mstatus[0m[90m | [0m[34mRunning task status[0m
[35m[telescope-fzf-native.nvim] [0m[36mstatus[0m[90m | [0m[34mFinished task status in 23ms[0m
[35m[telescope-fzf-native.nvim] [0m[36mcheckout[0m[90m | [0m[34mRunning task checkout[0m
[35m[telescope-fzf-native.nvim] [0m[36mcheckout[0m[90m | [0m[34mFinished task checkout in 0ms[0m
[35m[conform.nvim] [0m[36m   fetch[0m[90m | [0m[34mFinished task fetch in 2482ms[0m
[35m[conform.nvim] [0m[36m  status[0m[90m | [0m[34mRunning task status[0m
[35m[conform.nvim] [0m[36m  status[0m[90m | [0m[34mFinished task status in 22ms[0m
[35m[conform.nvim] [0m[36mcheckout[0m[90m | [0m[34mRunning task checkout[0m
[35m[conform.nvim] [0m[36mcheckout[0m[90m | [0mHEAD is now at 016802d fix(rumdl): specify filename to formatter (#893)
[35m[conform.nvim] [0m[36mcheckout[0m[90m | [0m[34mFinished task checkout in 23ms[0m
[35m[telescope.nvim] [0m[36m fetch[0m[90m | [0m[34mFinished task fetch in 2569ms[0m
[35m[telescope.nvim] [0m[36mstatus[0m[90m | [0m[34mRunning task status[0m
[35m[telescope.nvim] [0m[36mstatus[0m[90m | [0m[34mFinished task status in 23ms[0m
[35m[telescope.nvim] [0m[36mcheckout[0m[90m | [0m[34mRunning task checkout[0m
[35m[telescope.nvim] [0m[36mcheckout[0m[90m | [0mHEAD is now at 40aedd8 fix(finders): yield once per await_count entries in oneshot replay loop
[35m[telescope.nvim] [0m[36mcheckout[0m[90m | [0m[34mFinished task checkout in 23ms[0m
spec01-channels-and-lua OK

spec02-mason-hook: exit 0
ok   warm registry: silent no-op
ok   no nvim on PATH: warns, exits 0
ok   cold + working nvim: seeds automatically, no switch needed
ok   cold + offline: warns, exits 0, tells you how to retry
PASS
spec02-mason-hook OK
