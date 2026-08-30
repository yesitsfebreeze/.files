---
state: open
priority: 8
est: 5h
task: H.4
mode: afk
needs:
  - 01-capsule/02-dev-image
  - 01-capsule/01-container-lifecycle
  - 01-capsule/03-credential-propagation
  - 01-capsule/04-recent-workspaces
  - 00-delivery/decisions/tinty
  - 00-delivery/decisions/fzf
  - 00-delivery/decisions/wallpaper-opacity
  - 03-editor/01-options
  - 03-editor/06-explorer
  - 03-editor/07-formatting
  - 03-editor/12-small-plugins
  - 03-editor/13-statusline
  - 03-editor/14-shift-select
  - 03-editor/15-markdown-tables
  - 03-editor/04-plugin-manager
  - 03-editor/02-keymaps
  - 03-editor/03-autocmds
  - 03-editor/11-colorscheme
  - 03-editor/05-completion
  - 03-editor/09-lsp
  - 03-editor/10-treesitter
  - 03-editor/08-telescope
  - 00-delivery/verification-gates
  - 06-help/01-content-model
  - 06-help/02-help-command
  - 06-help/03-browser
  - 06-help/05-agent-interface
  - 05-platform/01-deploy-mechanism/repo-skeleton
  - 05-platform/02-package-provisioning/packages-installer
  - 05-platform/02-package-provisioning/homebrew-bootstrap
  - 05-platform/03-shell-init-generation
  - 05-platform/01-deploy-mechanism/managed-config
  - 04-shell/01-core-config
  - 04-shell/02-aliases-utilities
  - 04-shell/06-listing
  - 04-shell/03-zoxide
  - 04-shell/04-television
  - 04-shell/05-history
  - 04-shell/07-quicklist
  - 04-shell/08-claude-launchers
  - 02-terminal/01-appearance
  - 02-terminal/02-startup-layout
  - 02-terminal/03-f5-jump-mode
  - 02-terminal/04-copy-mode
  - 02-terminal/05-tab-content-state
  - 02-terminal/06-launchd-path
  - 00-delivery/corrections/w0-1-terminal-inventory
  - 00-delivery/corrections/w0-2-terminal-respec
  - 00-delivery/corrections/w0-3-platform-rewrite
  - 00-delivery/corrections/w0-4-s2-corrections
  - 00-delivery/corrections/w0-5-capsule-rebase
  - 00-delivery/corrections/w0-6-live-bugs
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
- Deciding whether a documented entry *should* exist. H.4 checks that the
  manual and the live surfaces agree, not that the configuration is right.
  The fzf exception ([decisions/fzf](../../00-delivery/decisions/fzf/prd.md),
  decided 2026-08-21) needed no requirement change here for that reason: it
  changes the manual's content, which is
  [01-content-model](../01-content-model/prd.md)'s, not the check's rules.

## Questions (answered 2026-08-28)

Board-frontier drill round, 2026-08-28 — the whole remaining frontier put in
one round. This node's fork:

### Q1: Does `help --check` ship for three surfaces, or fewer?

This node is 5h and unspecced, `--check` exists nowhere in `help.nu` beyond a
comment, and it is the only substantial thing left unbuilt on the board. Its
three surfaces are not equally valuable — how much of it ships now?

1. **Shell + Neovim, defer WezTerm** — build R1 and R2; move R3 to its own
   deferred node. The terminal check already carries a measured blind spot
   (`Ctrl+Shift+T` resolves against WezTerm's own `SpawnTab` default, so it
   passes either way), which makes it the least load-bearing third.
   (recommended)
2. **Full three surfaces as specified** — build R1-R8 as written, closing
   `coverage` cleanly at the cost of the whole 5h.
3. **Drop it from the minimal base** — record `help --check` as deferred and
   unblock `coverage` by hand-running its R5 resolution once. The manual stops
   being self-checking and drift returns silently.

## Answers

Answered 2026-08-28 by the user, in the [finish-line](../../00-delivery/finish-line/prd.md)
drill round.

**Q1** — **Shell + Neovim only; the WezTerm surface defers.** R1 and R2 ship
here; **R3 moves to
[`drift-check-terminal-surface`](../../00-delivery/finish-line/drift-check-terminal-surface/prd.md)**,
deferred and not cancelled. The terminal was the surface to cut because its
check already has a measured blind spot — `Ctrl+Shift+T` resolves against
WezTerm's own `SpawnTab` default, so it passes whether or not a capsule
binding is ever written.

R4–R8 apply to the two built surfaces. R6's allowlist and R5's prose exemption
are unchanged. Consequence carried into
[`coverage`](../01-content-model/coverage/prd.md): its R3 defers with the
terminal surface, and R5 closes for shell and Neovim only.

## Children

| child | contract | needs |
|---|---|---|
| `01-check-plumbing` | help --check` parses and runs: the flag on `def help`, `help-check.nu`, config.nu source order, and the eleven sibling `MODULES=` constants plus the `[a-z-]+` regex fix so no gate dies at parse | — |
| `02-shell-resolver` | R1 resolves keybinding/alias/command in a configured shell, and the four wrong-kind corpus defects are reported | 01-check-plumbing |
| `03-nvim-resolver` | R2 for global maps: one headless spawn that never installs plugins and raises on a missing config, the seven normalization rules, the three-state `desc | 01-check-plumbing |
| `04-nvim-buffer-maps` | The eight `scope: "buffer"` targets resolve against an LSP-attached and filetype-loaded buffer, or the check declares them unresolvable with the measurement | 03-nvim-resolver |
| `05-allowlist` | R6: the ~281 live handles classified explicitly, the `_`-private convention written down, the LSP-defaults exception kept documented | 02-shell-resolver, 03-nvim-resolver |
| `06-report-and-gate` | R4/R5/R7 report and exit code, and `tests/help-drift-check.sh` proving all four acceptance mutations including the Neovim-default collision | 05-allowlist, 04-nvim-buffer-maps |
| `07-tmux-key-resolver` | The memo's `tmux-key` verify kind resolves against `tmux -L … list-keys`, and terminal.nuon's ~20 `wezterm-key` entries convert | 01-check-plumbing |
