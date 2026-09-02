---
state: done
claim:
priority: 18
est: 2.5h
task: E.2
mode: afk
needs:
  - 03-editor/01-options
  - 06-help/01-content-model
verify: ""
---

# Plugin manager (lazy.nvim)

Parent: [Neovim epic](../prd.md) · C 4 · U 9 · source: "lazy.nvim bootstrap
and plugin loading" in
[`capabilities-nvim.md`(../../../../docs/capabilities-nvim.md)

Purpose: Self-bootstrapping lazy.nvim: a clean config dir plus one launch
yields a fully installed editor, with startup trimmed of unused built-ins.

## Requirements

Executed 2026-08-22 by `bash tests/nvim-plugin-manager.sh` (all three
stages, exit 0) on nvim 0.12.4: text checks in `--tree`, the effective
opts introspected from `lazy.core.config` in `--headless`, the real
bootstrap in `--network`.

- [~] **R1** — **Load order.** `init.lua` requires `config.options` →
      `config.keymaps` → `config.autocmds` → `config.lazy`, in that order
      (leader before specs). Met at the E.2 slice: `config.options` first,
      `config.lazy` last (gate `--tree`); the keymaps/autocmds requires
      land at E.3/E.4 and close this box.
- [x] **R2** — **Bootstrap.** If `stdpath("data")/lazy/lazy.nvim` is absent,
      clone it (`--filter=blob:none --branch=stable`); on clone failure, echo
      the error, wait for a keypress, and exit rather than continuing into a
      broken state. Prepend it to `rtp`. The keypress wait is guarded by
      `#vim.api.nvim_list_uis() > 0` — a bare `getchar()` blocks forever in
      `--headless` (measured; the gate's guard counterfactual hangs).
      Proven: real bootstrap in `--network` (HEAD at the `stable` tag's
      commit, `partialclonefilter=blob:none`), clone failure exit 1 with
      `Failed to clone lazy.nvim` on stderr in <10s.
- [x] **R3** — **Spec loading.** `{ import = "plugins" }` — one file per
      concern under `lua/plugins/`. `lua/plugins/init.lua` (`return {}`) is
      the permanent import anchor: lazy errors `No specs found` when
      `lua/plugins/` is missing or empty, and git cannot track an empty dir.
      Proven: launch stderr clean; import-rename and anchor-delete
      counterfactuals both surface `No specs found`; a sibling `demo.lua`
      spec loads alongside the anchor.
- [x] **R4** — **Defaults.** `lazy = false` and `version = false` as defaults
      (specs opt into lazy-loading via `event`/`cmd`/`keys`/`ft` individually,
      and pin only where required — e.g. blink's tagged `1.*`).
      `rocks.hererocks` off. Proven introspected: `def_lazy=false`,
      `def_version=false`, `hererocks=false`; a triggerless `dir=` spec IS
      loaded at startup.
- [x] **R5** — **Lockfile.** `lazy-lock.json` is committed — reproducible
      plugin state across machines. Generated from a real run; `Lazy!
      restore` then `rev-parse HEAD` ==
      `306a05526ada86a7b30af95c5cc81ffba93fef97`, the lockfile's commit.
- [x] **R6** — **Updates.** Checker enabled but `notify = false`;
      `change_detection` silent. Informed, not interrupted. Proven
      introspected: `checker_enabled=true`, `checker_notify=false`,
      `cd_notify=false`; checker-off counterfactual goes red.
- [x] **R7** — **Install colorscheme.** `install.colorscheme` =
      `base16-gruvbox-dark-hard` so the first-run install screen isn't
      unstyled. Proven introspected: `colorscheme1=base16-gruvbox-dark-hard`.
- [x] **R8** — **Disable unused built-ins** for startup time: gzip, tarPlugin,
      tohtml, tutor, zipPlugin, netrwPlugin (netrw is replaced by
      [oil](../06-explorer/prd.md)). Proven introspected, exact-equality on
      the six-name list; netrw-drop counterfactual goes red.

## Acceptance
- [x] `rm -rf ~/.local/share/nvim/lazy` then launch: everything reinstalls to
      the lockfile's versions unattended. 2026-08-22, staged form (gates
      never touch real `~/.local/share`): a fresh empty XDG root bootstraps
      unattended, and `Lazy! restore` lands lazy.nvim on the lockfile's
      commit exactly (`--network` stage, exit 0).
- [x] Launch with networking off on a clean machine: a clear error, no hang.
      2026-08-22, hermetic form: unseeded root + git shim exiting 128 →
      `Failed to clone lazy.nvim` on stderr, exit 1, under the 10s
      watchdog; with the guard sed'd out the same launch TIMEOUTs — the
      no-hang is the guard's doing.
- [x] `:Lazy` shows lazy-loaded plugins as not-yet-loaded until their
      trigger. 2026-08-22, state level (`lazy.core.config.plugins[n]._.loaded`
      is the data the TUI renders; headless cannot draw it, and no real
      plugin exists at E.2): a `cmd=` fake spec reports
      `pre_lazy_loaded=false`, then `post_lazy_loaded=true` after its
      command fires; `:Lazy` itself registered (`exists(':Lazy') == 2`).

## Out of scope
- Anything this node's Requirements do not name. The epic ([`../prd.md`](../prd.md)) owns the shared invariants.
