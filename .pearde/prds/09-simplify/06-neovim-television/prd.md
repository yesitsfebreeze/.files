---
state: claimed        # open|analyzing|refine|question|specced|claimed|blocked|done|failed
origin: requested  # requested = the user asked | derived = the board found it
priority: 30        # higher first
complexity: 25      # analyst, at spec time — 1-100. THE WEIGHT the board schedules by
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
workflow: land-an-answered-fork
claim: implementer-neovim-tv 2026-09-02 14:23
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

- [ ] `tv list-channels | wc -l` prints at most 16 and `ls
      home/dot_config/television/cable | wc -l` prints at most 15.
      **Corrected 2026-09-02, before dispatch**: `tv` 0.15.9 bakes in ten
      channel names regardless of the cable directory's contents (measured
      on an empty `XDG_CONFIG_HOME` fixture), and R1+R2's ten kept files
      add six names those builtins don't cover — 16 is the floor, not 15;
      there is no in-scope file left to drop that would reach 15. The
      `ls cable` half (the repo-owned count) still holds at 15.
      **Measured 2026-09-02 by `implementer-neovim-tv`; left red on
      purpose.** `ls home/dot_config/television/cable | wc -l` is `10`, and
      against an isolated `XDG_CONFIG_HOME` holding only this repo's
      television configuration `tv list-channels | wc -l` is exactly `16`
      (an empty fixture gives `10` — the baked-in names). Run in this
      machine's own shell it prints `30`, because `chezmoi apply` never
      removes a file it has stopped managing:
      `$HOME/.config/television/cable` still holds all five channels R1
      deleted plus thirteen older ones. The repair is the mechanism
      `04-nushell` already used — five lines appended to
      `home/.chezmoiremove` — and that file is outside this PRD's footprint,
      so it is reported, not done.
- [x] `nvim --headless "+Lazy! sync" +qa` exits 0; `nvim --headless +qa` prints no error
      — re-run 2026-09-02 by `implementer-neovim-tv`; both exit 0, no stderr.
- [ ] in nvim: Shift-Down three times then Down collapses the selection; the same from insert mode; `grn` renames in a Lua buffer; the statusline follows two `tinty apply` calls without a restart; `<leader>xc` opens Claude through `cll`
      **Four of five clauses measured live in a real pty (tmux); one cannot
      pass on this tree.** Shift-Down x3 from line 1 → `mode=v cursor=4
      anchor=1`; a bare Down after it → `mode=n cursor=5 anchor=5` (the
      collapse); from insert mode, `i` then Shift-Down x2 → `mode=v cursor=3
      anchor=1`; `<leader>xc` is mapped and `claudecode`'s own merged state
      reads `terminal_cmd=cll`. **The `tinty apply` clause fails, and did
      before this PRD too**: nothing on this machine propagates a `tinty
      apply` into an already-running nvim (no nvim hook in `tmux-colors.sh`,
      no watcher in `tinted-nvim`'s setup), so the statusline cannot follow
      it. The autocmd R3 deleted listened to `ColorScheme` — an in-nvim
      event — so it never followed `tinty apply` either. What R3 replaced it
      with IS proven: three consecutive `:colorscheme` changes in one live
      nvim moved `lualine_a_normal` `#665c54/#1d2021` → `#bdae93/#f9f5d7` →
      `#4c566a/#2e3440`, no restart and no autocmd. `grn` is mapped in normal
      mode; the rename itself was not driven against a live `lua_ls`.
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
