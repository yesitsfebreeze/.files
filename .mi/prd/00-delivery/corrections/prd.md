---
state: open
mode: afk
deps: []
verify: ""
---

# Corrections backlog

Parent: [Delivery epic](../prd.md) · net-new

Purpose: Findings from the four-agent audit of 2026-08-20, which checked every
PRD and inventory against the live configs. These are Wave 0: they change what
later tasks build, so they land before implementation starts. Severity: **S1**
invalidates a PRD or a scope decision · **S2** a factual error to correct ·
**S3** cosmetic. `[x]` = already fixed in this pass.

## Acceptance
- [ ] Every S1 item is either fixed or converted into a task in
      [`01-work-breakdown`](../work-breakdown/prd.md) before Wave 1 starts.
- [ ] The three open decisions have a recorded answer, in this file, with a
      date.
- [ ] No S2 "live bug" is reproduced in the rebuild; each is either fixed or
      documented as accepted-with-reason.
- [ ] `capabilities.md` corrections are confirmed with the author before
      editing.

## Out of scope
- Anything this node's Requirements do not name. The epic ([`../prd.md`](../prd.md)) owns the shared invariants.

## S1 — the terminal epic is specced from the wrong config

`02-terminal/*` was written from `capabilities.md` and never checked against
the live `~/.config/wezterm/`. Nearly every requirement is wrong, and the live
config is a substantially more sophisticated thing. **Treat all of
`02-terminal` as invalid until re-specced (task W0.2).**

| # | Finding |
|---|---|
| T-1 | Font is **CaskaydiaCove Nerd Font** (installed, with `font_dirs` → `~/Library/Fonts`), not in-repo Departure Mono — that is legacy-only. |
| T-2 | Palette is **not** Gruvbox Material. `wezterm.lua` `dofile`s a tinty-generated `colors.lua` (currently `base16-everforest-dark-hard`); the base16 gruvbox scheme is only a fallback. No green cursor override; style is `BlinkingBlock`. |
| T-3 | **Palette ownership is inverted.** WezTerm *reads* what `tinty apply` writes, and F6 delegates the switch to nushell's `theme.nu`. Tinty is the source of truth — yet the theme switcher is `DEFER`red, so the palette source is currently out of the minimal base. Resolve deliberately. |
| T-4 | Padding is zeroed and recomputed every tick by `center_grid` to center the cell grid. There is no platform-aware padding. |
| T-5 | `gui-attached` does not exist; startup calls `toggle_fullscreen()`, not `maximize()`. |
| T-6 | Quit passes `confirm = false` explicitly, and must `mark_closing()` first to defeat the tab-refill floor. |
| T-7 | **No `Cmd+N` binding exists.** New windows get nine tabs from a reconciler on `window-config-reloaded`. |
| T-8 | F5 pane letters are `asdfghjkl` indexing `tab:panes()` in **split-creation order, not geometry**. `b` is bound but maps to nothing and rings the bell. Both the letter set and the ordering in the PRD are wrong. |
| T-9 | The "JUMP" status hint was **deliberately removed** as noise; discoverability is a reverse-video letter painted into each pane. Right status is clock-only. |
| T-10 | Uncovered live features, ~230 lines of the most intricate code in the config: the **self-healing nine-tab floor** (per-window slot maps, `MoveTab` re-positioning, re-entrancy guard, 5 s heal tick), **dynamic grid centering**, **copy mode** (`Ctrl+Shift+X` + single-key toggle + OSC user-var), `Ctrl+V` bracketed paste / `Ctrl+C` copy-or-SIGINT, mouse bindings (`StartWindowDrag` is the only window handle under `RESIZE`), and the launchd-PATH seeding without which a GUI launch dies. |
| T-11 | The epic's Non-goals list "background image cycling" and "opacity toggle" as never-port, but both exist live in new form (`Ctrl+Shift+B` sets a blurred desktop wallpaper; opacity via OSC-1337 user var over `window_background_opacity = 0.95`). |


## S1 — capsule collides with live bindings and rests on broken code

| # | Finding |
|---|---|
| C-1 | **`Ctrl+Shift+B` is already the wallpaper prompt** and `Ctrl+Shift+T` is WezTerm's default SpawnTab (which the tab reconciler treats as the manual new-tab path). The capsule PRDs claim both. Pick new bindings. |
| C-2 | **No live capsule implementation exists** — no `~/docker`, no Dockerfile or capsule script in `~/.config`. The five "existing pieces" the epic consolidates live only in the undeployed legacy repo. The epic's framing ("consolidate what exists") should become "build once, informed by the legacy attempt". |
| C-3 | **Legacy `mount` never worked.** It `cd`s to a non-existent `~/docker`, calls `just run "$PWD"` where the recipe takes zero parameters, and that recipe mounts `./workspace` rather than the current directory. Do not preserve its semantics — design them. |
| C-4 | **`devzsh` has no zsh** (image installs none; `CMD ["bash"]`), so zsh/oh-my-zsh comes only from the capsule image. `01-capsule/02` mis-attributes it. Claude Code is likewise only in the capsule image, not the standalone one. |
| C-5 | The "Recent:" status indicator required by `01-capsule/04` has no host: the live status bar is clock-only and `set_left_status` is never called. |


## S1 — open decisions for the human

These are scope forks an agent must not resolve alone:

1. **burrito vs the nine-tab floor.** The live WezTerm config states "burrito
   owns multiplexing, so there's a single tab", yet also implements a
   self-healing nine-tab floor. These are two competing models of the same
   surface, and the terminal epic is built on the tab one. burrito
   (`~/.cargo/bin/burrito`, config at `~/.config/burrito/`) appears in the PRD
   tree only as the `bb`/`ba` aliases. **Which layer owns panes/tabs?**
2. **Does tinty stay?** It owns the palette that WezTerm, Neovim, and tv all
   inherit (T-3), but it is `DEFER`red as cosmetic. If it goes, something else
   must own the palette; if it stays, it is not cosmetic.
3. **fzf.** `zi`/`cdi` shell out to `zoxide query --interactive`, which spawns
   **fzf** — violating the shell epic's own invariant that "tv owns every
   picker screen". Either accept fzf as a documented exception or replace `zi`
   with a tv-backed picker.
4. **Deployed or source — which artifact do the inventories rate?**
   **Decided 2026-08-21 (user): the deployed `~/.config` tree is canonical.**
   Raised by `w0-6-live-bugs`: checking L-12 surfaced that the chezmoi source
   and the deployed tree are different programs, not copies. Measured
   2026-08-20, `~/.local/share/chezmoi/home/dot_config/` vs `~/.config/`, in
   lines: `wezterm/wezterm.lua` 339 vs 1149 (deployed ~810 ahead),
   `nushell/config.nu` 380 vs 715 (deployed ahead), `nushell/finder.nu` 345 vs
   221 (**source** ahead, and a different stack-and-resume design rather than
   an older copy). CLAUDE.md's "verify against the live config, always"
   assumed the two were one thing, so "the live config" resolved to whichever
   tree the reading agent opened — the same failure class that invalidated
   `02-terminal`.

   What the decision settles:
   - (a) The chezmoi source is **abandoned**, not a port target. `05-platform`
     is a from-scratch deploy mechanism, not a port of a working one.
   - (b) The 345-line source `finder.nu` is **not ported**. `04-shell/04` is
     correctly specced from the 221-line deployed file. This also explains
     L-5: `leadermode.nu` is a leftover of the source design, which is why it
     calls `finder --resume`/`--fresh`, flags the deployed finder never had.
   - (c) `w0-2-terminal-respec` takes the **deployed** 1149-line
     `wezterm.lua` as its input. The ~810-line delta is not pushed back.
   - L-12 stands as written: the deployed config has zero references to
     `solo-window.*`. The source's `solo_window()` definition and its two
     call sites are part of the abandoned tree.

   Every inventory in `.mi/docs/` rates the deployed artifact. Where one was
   written against the source, that is a correction, not a difference of
   opinion.


## S2 — bugs in the live config (do not reproduce these)

The PRDs documented these as working behavior. They are not.

| # | Finding |
|---|---|
| L-1 | **`ls -D` cannot work on macOS.** It runs `du -sb`; macOS `du` has no `-b`, stderr is discarded, so dir sizes silently stay inode sizes. Fix in the rebuild (`-sk`, or `gdu`). |
| L-2 | **`git-log` → commit decode is dead.** The channel emits a bare hash, the decoder reads field index 1, so the result is always empty and `git show` never runs. |
| L-3 | **`rcwd` is not a channel** — the real name is `recent-dirs`, and the decoder only types `rcwd`, so recent-dir picks are never decoded as paths. Named wrongly in three PRDs and the inventory. |
| L-4 | **Finder picks are never logged to the quicklist** — only zoxide jumps and the bare-word fallback log. `04-shell/07`'s premise and acceptance criterion are wrong. |
| L-5 | **`leadermode.nu` is dead code** (never sourced) and calls `finder --resume` / `--fresh`, flags that do not exist. Its `DO NOT PORT` verdict stands; the inventory should say "dead code", not describe it as live. |
| L-6 | Neovim `<Esc>` → `nohlsearch` is **inert** because `hlsearch=false`. Port one or the other, not both. |
| L-7 | **oil does not replace netrw for `:e some/dir`.** It is lazy on `keys`, so its `default_file_explorer` hijack isn't installed until `<leader>e` is pressed; with netrw disabled, `:e dir` opens neither. |
| L-8 | treesitter's `FileType` autocmd (and shift-select's `ModeChanged`) are **ungrouped**, so a reload stacks duplicates — violating `03-editor/03`'s own invariant. |
| L-9 | Visual-mode `<C-v>` shadows blockwise-visual mode. Intentional? Record it either way. |
| L-10 | gitsigns delete/topdelete glyphs are **empty strings** — a nerd-font character was lost. Both docs describe them as glyphs. |
| L-11 | The F5 miss path rings BEL, but `audible_bell = "Disabled"` and no visual bell is set: a mistyped jump letter gives **no feedback at all**. |
| L-12 | Dead files still shipped in the chezmoi source: `solo-window.{applescript,sh,ps1,vbs}`, `wsl-clip-prime.sh`, `background.png` — zero references in the live config. |


## S2 — my factual errors

| # | Finding |
|---|---|
| M-1 | `scrolloff=999` does **not** center the cursor "at all times" — the first and last half-screen are uncentered (measured). Three statements overclaim this. |
| M-2 | Shift-select acceptance criteria are off by one twice: one `<S-Right>` already selects two characters (`v<Right>`), and `<S-Left>` from insert selects two (`yz`), not one. |
| M-3 | Baseline is stated as "native 0.11" but the live binary is **0.12.4**, where `vim.highlight.on_yank` is deprecated in favor of `vim.hl`. `03-editor/03` prescribes the deprecated API. |
| M-4 | blink.cmp is specced as lazy on `InsertEnter`, but it is a dependency of nvim-lspconfig (`BufReadPre`), so it loads at first buffer read. |
| M-5 | `04-shell/03-zoxide.md` header says C 5; sources are C 4 (suite, dominant) and C 7 (fallback). No entry yields 5. |
| M-6 | `04-shell/01` folded the separate "Dirstack" entry (C 3 / U 7) in without listing it as a source or giving it a table row. |
| M-7 | `bb`/`ba` invoke **`brr`**, not `burrito`. Both binaries exist, so the name matters. |
| M-8 | The no-match HOME hazard comes from **`mkcd`** treating `""` as "no argument", not from `__zoxide_z`. |
| M-9 | Three enter-hijacking channels exist (`text`, `zoxide` → `actions:cd` spawning a nested shell, `recent-files` → `actions:edit`), not just `text`; and `text.toml` is a local override, not stock. |
| M-10 | `01-capsule/01` header carries `U 8–9` — a range, which the contract forbids. |
| M-11 | Critical path in `01-work-breakdown` used a non-existent edge (`S.7 → H.2`); H.2 depends on H.1 only. `[x] fixed` |
| M-12 | `11-colorscheme` acceptance says "all five highlights"; the requirement defines six. |
| M-13 | `06-help/02` acceptance ("`help ls` reaches the builtin") contradicts its own resolution order plus `06-help/01`, which documents `ls` variants as entries. |
| M-14 | `06-help/02` and `03` both render an entry's "source PRD", a field the content model's schema does not define. |
| M-15 | `06-help/00` claims all maps carry `desc`, but `03-editor/02` says the centered-jump maps carry none (and the visual-indent maps don't either) — so the drift check's "mismatched" class needs an exemption. |
| M-16 | `06-help/03` claims TAB-delimited rows "mirroring" `04-shell/07`, which specifies nuon and says nothing about channel row format. |
| M-17 | Editor epic says "13 files"; there are 14. |
| M-18 | Work breakdown targets a `conf/` directory for T.2/T.3/C.4 — legacy-only layout. |
| M-19 | Work breakdown claimed "every feature PRD appears exactly once"; `05-platform`'s children and `00-delivery`'s own PRDs were absent. |


## S2 — coverage gaps found

Live behavior no PRD and no inventory covers:

- **Shell:** `ollama-host` probe on every interactive start; `starship` (in no
  inventory entry at all); the tinty palette re-assert in `config.nu` (orphaned
  if theme is dropped); `$env.ENV_CONVERSIONS`; the `esc_clear` binding;
  `cursor_shape` / `table` / `sync_on_enter` / `completions.external` config
  blocks.
- **Television:** the `nu-history` channel — **`Alt-R` depends on it** — plus
  `alias`, `cht`/`cht-query` naming, `recent-files`, `channels`; the
  in-tv shortcut keys (with `cht.sh=f5` colliding with `burrito-sessions=f5`);
  and the non-cable assets (`bg-preview.sh`, `theme-preview.sh`).
- **Neovim:** `cmdheight`; and the fact that `plugins/editor.lua` actually
  holds five specs (gitsigns, which-key, autopairs, **conform**,
  **vim-table-mode**) — the filename appears nowhere in the tree, though three
  PRDs write it.
- **Provisioning:** covered now by
  [`capabilities-provisioning.md`](../../../docs/capabilities-provisioning.md) and
  [`05-platform`](../../05-platform/prd.md). `[x] fixed`


## S3 — hygiene

- Inventory sort order violated in `capabilities-nvim.md` (four rises) and
  `capabilities-nushell.md` (opacity below theme).
- `capabilities.md` (user-authored — **confirm before editing**): marker typo
  `DO NOT PORST`; missing markers on "Cross-platform Lua/shell/PowerShell
  parity", "Cross-platform dependency bootstrap", and "Just task runner",
  all of which the README treats as excluded or superseded; the header note
  describes verdicts as containing `|`, which none do; "maximiz:ed" typo;
  mini.nvim entry unmarked yet double-rated in `capabilities-nvim.md`.
- Opacity is `DO NOT PORT` in one inventory and `DEFER` in another, and
  `04-shell/04` both specs its channel and defers it.
- Duplicated facts the tree's own rule forbids: `cdi` in two PRDs; the
  kitty-protocol reason in three places; "the terminal owns the palette" in
  five, none of them the terminal epic (which has no invariants section).
- README stated exclusions twice; build order still listed the bootstrap third
  though `04-shell/01` depends on it. `[x] partially fixed`
- `00-delivery` PRDs carry no C/U ratings, and the "plans live in `docs/`"
  argument used to exile the Gantt would also exile them. Resolve by
  exempting meta-epics explicitly in `AGENTS.md`.
- Wrap limit exceeded in several files; tables should be exempted from the
  rule rather than the rule quietly broken.
