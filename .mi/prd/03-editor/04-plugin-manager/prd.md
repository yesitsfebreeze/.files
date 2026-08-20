---
state: open
mode: afk
deps:
  - .mi/prd/03-editor/01-options
  - .mi/prd/06-help/01-content-model
verify: "nvim --headless '+Lazy! sync' +qa exits 0"
---

# Plugin manager (lazy.nvim)

Parent: [Neovim epic](../prd.md) · C 4 · U 9 · source: "lazy.nvim bootstrap

Purpose: Self-bootstrapping lazy.nvim: a clean config dir plus one launch
yields a fully installed editor, with startup trimmed of unused built-ins.

## Requirements
- [ ] **R1** — **Load order.** `init.lua` requires `config.options` →
      `config.keymaps` → `config.autocmds` → `config.lazy`, in that order
      (leader before specs).
- [ ] **R2** — **Bootstrap.** If `stdpath("data")/lazy/lazy.nvim` is absent,
      clone it (`--filter=blob:none --branch=stable`); on clone failure, echo
      the error, wait for a keypress, and exit rather than continuing into a
      broken state. Prepend it to `rtp`.
- [ ] **R3** — **Spec loading.** `{ import = "plugins" }` — one file per
      concern under `lua/plugins/`.
- [ ] **R4** — **Defaults.** `lazy = false` and `version = false` as defaults
      (specs opt into lazy-loading via `event`/`cmd`/`keys`/`ft` individually,
      and pin only where required — e.g. blink's tagged `1.*`).
      `rocks.hererocks` off.
- [ ] **R5** — **Lockfile.** `lazy-lock.json` is committed — reproducible
      plugin state across machines.
- [ ] **R6** — **Updates.** Checker enabled but `notify = false`;
      `change_detection` silent. Informed, not interrupted.
- [ ] **R7** — **Install colorscheme.** `install.colorscheme` =
      `base16-gruvbox-dark-hard` so the first-run install screen isn't
      unstyled.
- [ ] **R8** — **Disable unused built-ins** for startup time: gzip, tarPlugin,
      tohtml, tutor, zipPlugin, netrwPlugin (netrw is replaced by
      [oil](../06-explorer/prd.md)).

## Acceptance
- [ ] `rm -rf ~/.local/share/nvim/lazy` then launch: everything reinstalls to
      the lockfile's versions unattended.
- [ ] Launch with networking off on a clean machine: a clear error, no hang.
- [ ] `:Lazy` shows lazy-loaded plugins as not-yet-loaded until their trigger.

## Out of scope
- Anything this node's Requirements do not name. The epic ([`../prd.md`](../prd.md)) owns the shared invariants.
