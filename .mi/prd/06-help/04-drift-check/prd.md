---
state: open
mode: afk
deps:
  - .mi/prd/00-delivery/corrections/w0-1-terminal-inventory
  - .mi/prd/00-delivery/corrections/w0-2-terminal-respec
  - .mi/prd/00-delivery/corrections/w0-3-platform-rewrite
  - .mi/prd/00-delivery/corrections/w0-4-s2-corrections
  - .mi/prd/00-delivery/corrections/w0-5-capsule-rebase
  - .mi/prd/00-delivery/corrections/w0-6-live-bugs
  - .mi/prd/00-delivery/decisions/fzf
  - .mi/prd/00-delivery/decisions/tinty
  - .mi/prd/00-delivery/decisions/wallpaper-opacity
  - .mi/prd/00-delivery/verification-gates
  - .mi/prd/01-capsule/01-container-lifecycle
  - .mi/prd/01-capsule/02-dev-image
  - .mi/prd/01-capsule/03-credential-propagation
  - .mi/prd/01-capsule/04-recent-workspaces
  - .mi/prd/02-terminal/01-appearance
  - .mi/prd/02-terminal/02-startup-layout
  - .mi/prd/02-terminal/03-f5-jump-mode
  - .mi/prd/02-terminal/04-copy-mode
  - .mi/prd/02-terminal/05-tab-content-state
  - .mi/prd/02-terminal/06-launchd-path
  - .mi/prd/03-editor/01-options
  - .mi/prd/03-editor/02-keymaps
  - .mi/prd/03-editor/03-autocmds
  - .mi/prd/03-editor/04-plugin-manager
  - .mi/prd/03-editor/05-completion
  - .mi/prd/03-editor/06-explorer
  - .mi/prd/03-editor/07-formatting
  - .mi/prd/03-editor/08-telescope
  - .mi/prd/03-editor/09-lsp
  - .mi/prd/03-editor/10-treesitter
  - .mi/prd/03-editor/11-colorscheme
  - .mi/prd/03-editor/12-small-plugins
  - .mi/prd/03-editor/13-statusline
  - .mi/prd/03-editor/14-shift-select
  - .mi/prd/03-editor/15-markdown-tables
  - .mi/prd/04-shell/01-core-config
  - .mi/prd/04-shell/02-aliases-utilities
  - .mi/prd/04-shell/03-zoxide
  - .mi/prd/04-shell/04-television
  - .mi/prd/04-shell/05-history
  - .mi/prd/04-shell/06-listing
  - .mi/prd/04-shell/07-quicklist
  - .mi/prd/04-shell/08-claude-launchers
  - .mi/prd/05-platform/01-deploy-mechanism/managed-config
  - .mi/prd/05-platform/01-deploy-mechanism/repo-skeleton
  - .mi/prd/05-platform/02-package-provisioning/homebrew-bootstrap
  - .mi/prd/05-platform/02-package-provisioning/packages-installer
  - .mi/prd/05-platform/03-shell-init-generation
  - .mi/prd/06-help/01-content-model
  - .mi/prd/06-help/02-help-command
  - .mi/prd/06-help/03-browser
  - .mi/prd/06-help/05-agent-interface
verify: "help --check exits 0"
---

# Drift check

Parent: [Help epic](../prd.md) · C 5 · U 8 · net-new

Purpose: The feature that makes this manual trustworthy instead of
aspirational: `help --check` diffs the documented entries against the live
configuration, in both directions. Undocumented bindings and stale
documentation are both failures.

## Requirements
- [ ] **R1** — **Introspect the shell.** `$env.config.keybindings` — match
      documented entries by keybinding `name` (which is why every binding in
      the config carries a meaningful one). `scope aliases` and `scope
      commands` for aliases and custom commands. Constraint: introspection
      must run in a *configured* shell — a bare `nu -c` has no config loaded
      and reports no aliases.
- [ ] **R2** — **Introspect Neovim.** `nvim --headless` + `nvim_get_keymap`
      per mode, emitted as JSON. Our maps carry `desc`, so the check can
      compare descriptions as well as existence, and flag a map whose `desc`
      no longer matches its documented `title`.
- [ ] **R3** — **Introspect the terminal.** `wezterm show-keys --lua`, plus
      `--key-table` for the F5 jump table
      ([02-terminal/03](../../02-terminal/03-f5-jump-mode/prd.md)).
- [ ] **R4** — **Report both directions.**
  - [ ] *Undocumented*: exists live, no manual entry. The common failure.
  - [ ] *Stale*: documented, no longer live. The dangerous failure — it sends
        a reader (or an agent) to a key that does nothing.
  - [ ] *Mismatched*: exists in both, but `desc` and `title` disagree.
- [ ] **R5** — **Exempt prose.** Entries with `verify: prose` are skipped by
      existence checks and counted separately, so concept entries don't need a
      fake binding.
- [ ] **R6** — **Allowlist noise.** Plugin- and core-provided maps (Neovim
      0.11 defaults, plugin internals) are not ours to document. Keep an
      explicit allowlist rather than silently ignoring — with one exception:
      the LSP defaults we *chose* not to re-map (`grn`, `gra`, `grr`, `gri`,
      `gO`, `K`, `]d`, `[d`) ARE documented, because they're part of how you
      use this editor ([03-editor/09](../../03-editor/09-lsp/prd.md)).
- [ ] **R7** — **Exit code.** Non-zero when anything is undocumented, stale,
      or mismatched — so it can gate a commit or run in CI.
- [ ] **R8** — **Not on the hot path.** `--check` spawns nvim and wezterm;
      plain `help` never does ([02](../02-help-command/prd.md), requirement 8).

## Acceptance
- [ ] Add a keybinding to the nushell config without a manual entry: `help
      --check` reports it as undocumented and exits non-zero.
- [ ] Delete a documented Neovim map: reported as stale.
- [ ] Change a map's `desc` but not the manual: reported as mismatched.
- [ ] A clean tree: exits zero and prints per-surface counts (documented,
      prose-only, allowlisted).

## Out of scope
- Anything this node's Requirements do not name. The epic ([`../prd.md`](../prd.md)) owns the shared invariants.
