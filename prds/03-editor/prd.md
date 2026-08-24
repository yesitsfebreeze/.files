---
state: open
claim: 
priority: 0
est: 0h
kind: epic
mode: afk
needs:
verify: ""
---

# Epic: Neovim

Purpose: Two Neovim configs exist. `capabilities.md` describes an older
mini.nvim one (self-bootstrapping `mini.deps`, vague theme, startify, noice);
the live config in `~/.config/nvim` is a newer, different setup — lazy.nvim +
telescope + blink.cmp + Neovim's native LSP API, 683 lines across 14 files.
Only the live one gets ported; the mini.nvim entries are superseded.

Goal: A minimal Neovim base that keeps the config's real value — the options
baseline, the modern plugin stack (LSP/completion/treesitter/telescope), and
the editor-style selection behavior — and sheds eye candy and dead lineage.

## Requirements

**Architecture invariants**

- [ ] **I1** — **Load order is load-bearing.** `options` → `keymaps` →
      `autocmds` → `lazy`. The leader key must be set before any plugin spec
      is evaluated.
- [ ] **I2** — **Lean on Neovim's built-ins.** `gc` commenting, and the
      default LSP and diagnostic maps, ship in core at or below the version
      floor (see I6). Add only what's missing — never a plugin that
      duplicates core.
- [ ] **I3** — **One plugin per concern.** blink.cmp replaces the whole
      nvim-cmp stack; telescope replaces finder.nvim; conform owns formatting.
- [ ] **I4** — **Palette is derived, never duplicated.** Everything that needs
      colors reads tinted-nvim's live palette and re-derives on `ColorScheme`.
- [ ] **I5** — **Plugin-specific keymaps live in their spec** (`keys = …`) so
      they lazy-load; only general maps live in `keymaps.lua`.

- [ ] **I6** — **Version floor, and version target.** This epic references
      the Neovim version floor recorded in
      [`packages-installer`](../05-platform/02-package-provisioning/packages-installer/prd.md)
      req 6 rather than restating a version number.

      The floor is what the config may not require below. The **target** —
      the binary every acceptance check in this epic is executed against —
      is the live 0.12.4, so a 0.12 deprecation binds even where the floor
      is lower: `vim.highlight.*` is deprecated in favour of `vim.hl.*`, and
      [`03-autocmds`](03-autocmds/prd.md) R1 is written to the new name
      (correction M-3).

- [ ] **I7** — **Every autocmd lives in a cleared augroup.** Every
      `nvim_create_autocmd` call in the config passes
      `group = nvim_create_augroup("<name>", { clear = true })` — including
      the ones declared inside a plugin spec's `config`/`init` function,
      which is where this rule is actually broken. Without it, re-sourcing
      the config or re-running a plugin's `config` registers a second copy
      of the callback and it fires twice per event; `clear = true` is what
      makes the registration idempotent. **Live bug L-8, do not reproduce.**
      Three sites break it live (swept 2026-08-21):
      `lua/plugins/treesitter.lua:31` (`FileType`),
      `lua/config/keymaps.lua:58` (`ModeChanged`), and
      `lua/plugins/editor.lua:80` (`FileType`, vim-table-mode — a third site
      the backlog's L-8 row does not list). All four autocmds in
      `lua/config/autocmds.lua` *are* grouped, and so are the ones in
      `statusline.lua`, `colorscheme.lua` and `lsp.lua`, so a grep for
      `augroup` finds seven hits and passes falsely — the check has to be
      per call site, not per file. Binds
      [`03-autocmds`](03-autocmds/prd.md),
      [`09-lsp`](09-lsp/prd.md),
      [`10-treesitter`](10-treesitter/prd.md),
      [`11-colorscheme`](11-colorscheme/prd.md),
      [`13-statusline`](13-statusline/prd.md),
      [`14-shift-select`](14-shift-select/prd.md) and
      [`15-markdown-tables`](15-markdown-tables/prd.md) — every node that
      registers an autocmd.

- [ ] **I8** — **One file per plugin under `lua/plugins/`.** Each plugin
      spec lives in a file named for the plugin; there is no catch-all.
      The live config has one — `lua/plugins/editor.lua`, holding five
      unrelated specs (gitsigns, which-key, nvim-autopairs, conform,
      vim-table-mode) — and three nodes of this epic write to it:
      [`07-formatting`](07-formatting/prd.md) (conform),
      [`12-small-plugins`](12-small-plugins/prd.md) (the first three) and
      [`15-markdown-tables`](15-markdown-tables/prd.md) (vim-table-mode).
      Until this invariant existed the filename appeared nowhere in this
      epic, so nothing warned the three that they collide, and the
      resolution lived only in
      [`parallelization`](../00-delivery/parallelization/prd.md) — a
      document none of them links. Splitting is what makes the three
      buildable in parallel instead of serialised, and it is why each node
      below names its own target files.

## Acceptance

## Out of scope
- The mini.nvim plugin set and its `mini.deps` bootstrap (`DO NOT PORT`).
- Insert-mode-first modal inversion and its `<F24>` Karabiner dependency
  (`DO NOT PORT` — Karabiner is out of scope entirely).
- Smear cursor (`DEFER` — pure eye candy).

## Note on children

The `## Children` table this epic used to carry is gone on purpose. Node
membership is by existence — a child is a subdirectory holding its own
`prd.md` — so a maintained list beside it is a second copy that goes stale
silently (laws.md law 4: "membership by existence, not by a maintained
list"). `find . -name prd.md` is the index.
