---
complexity: 12
footprint:
  - home/dot_config/nvim/lua/plugins/claude.lua
  - home/dot_config/nvim/lazy-lock.json
---

# spec01 — the claude.lua plugin spec, its lockfile pins and the live-store install

`home/dot_config/nvim/lua/plugins/claude.lua` exists in the tree and is
probed working (probe/pass-one.md, PRD dir): claudecode.nvim as the one
lazy spec — `cmd` stub list, the `<leader>a*` keymaps swept for collisions,
`opts` with terminal/diff settings, snacks.nvim +
mr55p-dev/claude-tmux.nvim as dependencies, and a `config()` that wires the
claude-tmux provider table only when `$TMUX` answers true, leaving
claudecode's `auto` (snacks) provider for non-tmux launches. What remains
is the bookkeeping the build exposed: the lockfile pins and the live store
that every nvim-launching gate seeds from.

## Acceptance

- [ ] `lazy-lock.json` carries exactly three NEW entries — claude-tmux.nvim
      `90b221c`, claudecode.nvim `2390c6e`, snacks.nvim `882c996c` (main-branch
      40-hex pins, sorted into the file) — and NO other line moves from the
      committed lock (measured trap: a full `Lazy! sync` rewrites every pin;
      take the three lines, never the rewritten lock, probe/pass-one.md).
- [ ] The live store `~/.local/share/nvim/lazy/` holds the three clones at
      those commits, installed WITHOUT network noise in a `HELP_CHECK=1`
      run (help/lazy.lua's contract: the drift check observes, never
      provisions) and without touching `~/.config/nvim` — which stays the
      pre-rebuild deploy until cutover.
- [ ] A `HELP_CHECK=1` headless start of the repo config installs nothing,
      loads neither plugin, and still produces all fourteen `:ClaudeCode*`
      command stubs and the nine `<leader>a*` lazy key stubs (the `cmd=2`
      and `SPEC-KEY` probe lines in probe/pass-one.md) — lazy-loading means
      the plugin body never runs at startup.
- [ ] Inside a real tmux session a headless nvim firing `:ClaudeCode` via
      the command resolves `terminal.provider` to the claude-tmux table,
      claude-tmux's returned config reads `{ toggle_key = "<C-j>",
      split_size = 30, split_side = "bottom" }`, and a tmux pane running
      `claude` exists in the probe's own session.
- [ ] Outside tmux the same fire resolves to the `auto` (snacks) fallback
      path; claude-tmux's `is_available()` answers false and `require`
      still succeeds — the fallback branch is live, not dead.

## Verify and Proof

```sh
# The four probes from pass one, run against a scratch config:
#   probe.lua  — cmd stubs, keymaps, claude-tmux module, outside-tmux answer
#   probe6.lua — merged state.config: provider / split width / diff layout
#   probe8.lua — the real :ClaudeCode and :ClaudeCodeFocus fire, rc 0
#   probe8/6 inside tmux -L <socket> — provider table, claude pane id
# Copy from prds/08-claude-agent/02-nvim-plugin/probe/ and adapt the sandbox
# staging used there; every gate below must keep passing as-is:
bash tests/nvim-keymaps.sh
bash gates/nvim-seed-registry.sh
git diff --stat home/dot_config/nvim/lazy-lock.json   # exactly 3 added lines
```