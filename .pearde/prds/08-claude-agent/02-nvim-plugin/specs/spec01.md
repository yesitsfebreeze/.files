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

- [x] `lazy-lock.json` carries exactly three NEW entries — claude-tmux.nvim
      `90b221c`, claudecode.nvim `2390c6e`, snacks.nvim `882c996c` (main-branch
      40-hex pins, sorted into the file) — and NO other line moves from the
      committed lock (measured trap: a full `Lazy! sync` rewrites every pin;
      take the three lines, never the rewritten lock, probe/pass-one.md).
- [x] The live store `~/.local/share/nvim/lazy/` holds the three clones at
      those commits, installed WITHOUT network noise in a `HELP_CHECK=1`
      run (help/lazy.lua's contract: the drift check observes, never
      provisions) and without touching `~/.config/nvim` — which stays the
      pre-rebuild deploy until cutover.
- [x] A `HELP_CHECK=1` headless start of the repo config installs nothing,
      loads neither plugin, and still produces all fourteen `:ClaudeCode*`
      command stubs and the nine `<leader>a*` lazy key stubs (the `cmd=2`
      and `SPEC-KEY` probe lines in probe/pass-one.md) — lazy-loading means
      the plugin body never runs at startup.
- [ ] Inside a real tmux session a headless nvim firing `:ClaudeCode` via
      the command resolves `terminal.provider` to the claude-tmux table,
      claude-tmux's returned config reads `{ toggle_key = "<C-j>",
      split_size = 30, split_side = "bottom" }`, and a tmux pane running
      `claude` exists in the probe's own session.
- [x] Outside tmux the same fire resolves to the `auto` (snacks) fallback
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

## Measured — implementer, 2026-09-02

Sandbox: scratch XDG dirs, config copied from `home/dot_config/nvim`, store
seeded from `~/.local/share/nvim/lazy` per `lazy-lock.json`, a `git` shim on
PATH logging every call and refusing `clone|fetch|pull|remote|ls-remote`,
`HELP_CHECK=1`, `~/.config/nvim` never read or written.

- **Box 1** — `git diff --stat` → `1 file changed, 3 insertions(+)`; the three
  added lines are exactly the specced pins; `json.load` → `23 entries;
  sorted: True`.
- **Box 2** — `git -C ~/.local/share/nvim/lazy/<p> rev-parse HEAD` →
  `2390c6e45c…` (claudecode.nvim), `90b221c423…` (claude-tmux.nvim),
  `882c996cf2…` (snacks.nvim); all three on branch `main`. Both headless runs
  recorded `git calls: 0`.
- **Box 3** — `CMD-STUBS=14/14`, `PRELOAD-claudecode=false`,
  `ANY-claudecode-in-package.loaded=false`, `git calls: 0`, and nine leader
  key stubs. **Prefix divergence, not a miss**: the tree's uncommitted
  `claude.lua` moved the group from `<leader>a` to `<leader>x` with a reason
  in-file, so the measured stubs are `<Space>xc xf xr xC xm xb xa xd` plus
  `<Space>xs` in v/x mode, under the group `<Space>x` — nine `<leader>x*`
  where the spec text says `<leader>a*`. Count and shape match; the letter
  does not.
- **Box 4** — **not met.** See the report; `split_side` cannot read `bottom`
  under the `:ClaudeCode` path.
- **Box 5** — outside tmux: `PROVIDER-TYPE=string VAL=auto`,
  `CT-REQUIRE=true`, `CT-IS-AVAILABLE=false`, `FIRE-ClaudeCode=true`,
  `TERMINAL-CMD=cll`, `SPLITW=0.3`, `DIFF-LAYOUT=vertical`.

**Seeding trap, measured and worth keeping.** Seeding the staged store with
**symlinks** into the live store makes lazy.nvim report every seeded plugin
`not installed` — its root scan reads the dirent type, and a symlink is
`link`, not `directory`. The first run failed on that alone (`Plugin
claudecode.nvim is not installed`, and the same for tinted-nvim,
persistence.nvim, oil.nvim). Re-seeding with `cp -Rc` (APFS clonefile, so
still cheap) made all 23 load. Any future staging must copy, never link.
