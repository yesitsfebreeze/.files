---
state: open
mode: afk
deps: []
verify: ""
---

# Epic: Neovim

Purpose: Two Neovim configs exist. `capabilities.md` describes an older
mini.nvim one (self-bootstrapping `mini.deps`, vague theme, startify, noice);
the live config in `~/.config/nvim` is a newer, different setup — lazy.nvim +
telescope + blink.cmp + native 0.11 LSP, ~680 lines across 14 files. Only the
live one gets ported; the mini.nvim entries are superseded.

Goal: A minimal Neovim base that keeps the config's real value — the options
baseline, the modern plugin stack (LSP/completion/treesitter/telescope), and
the editor-style selection behavior — and sheds eye candy and dead lineage.

## Requirements

**Architecture invariants**

- [ ] **I1** — **Load order is load-bearing.** `options` → `keymaps` →
      `autocmds` → `lazy`. The leader key must be set before any plugin spec
      is evaluated.
- [ ] **I2** — **Lean on Neovim's built-ins.** 0.10+ has `gc` commenting; 0.11
      ships default LSP and diagnostic maps. Add only what's missing — never a
      plugin that duplicates core.
- [ ] **I3** — **One plugin per concern.** blink.cmp replaces the whole
      nvim-cmp stack; telescope replaces finder.nvim; conform owns formatting.
- [ ] **I4** — **Palette is derived, never duplicated.** Everything that needs
      colors reads tinted-nvim's live palette and re-derives on `ColorScheme`.
- [ ] **I5** — **Plugin-specific keymaps live in their spec** (`keys = …`) so
      they lazy-load; only general maps live in `keymaps.lua`.

- [ ] **I (from `05-platform/02` req 6)** — this epic references the Neovim
      version floor recorded in
      [`packages-installer`](../05-platform/02-package-provisioning/packages-installer/prd.md)
      rather than restating a version number.

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
