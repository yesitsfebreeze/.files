---
complexity: 18
footprint:
  - tests/nvim-claude.sh
  - gates/nvim-seed-registry.sh
  - home/dot_config/nvim/lazy-lock.json
---

# spec02 — the gate: tests/nvim-claude.sh, and the seed exposure it accounts for

A gate in the shape of tests/nvim-small-plugins.sh: staged config, seeded
from the live store per lazy-lock.json, headless probes for the claude.lua
spec. What the build proved (probe/pass-one.md) is what the gate encodes;
what the build hit (the seeding/lockfile coupling) is what it must guard.

## The build finding this unit answers

With `home/dot_config/nvim/lua/plugins/claude.lua` present and the three
pins absent from `lazy-lock.json`, tests/nvim-small-plugins.sh fails its
hermeticity pair — lazy git-clones claudecode.nvim at every staged startup
(git-calls.log 87 → 91 lines, `git clone https://github.com/coder/...`
lines per cf staging). The same exposure sits in every gate that seeds the
full lockfile (nvim-keymaps, nvim-completion, nvim-session, …): until the
pin lands, each probe clones the unpinned plugins; once the pin lands, the
seed source check (`need_seed_source`) requires them in the live
`~/.local/share/nvim/lazy` or exits 127. The lockfile entries are the
switch that turns the first failure into the second, and the live-store
install is part of spec01.

## Acceptance

- [ ] tests/nvim-claude.sh exists and follows the runner rules tests/
      already holds (nvim results to stderr, scratch XDG dirs everywhere,
      /usr/bin/grep, no `timeout` — nvim backgrounded with a poll-loop
      kill, TIMEOUT recorded).
- [ ] Stage --tree checks the spec text itself: the `cmd` stub list is the
      fourteen commands, `provider = "auto"` is present with the tmux
      replacement happening in `config()`, snippets.nvim is named
      `folke/snacks.nvim` and claude-tmux.nvim as a `dependencies` entry of
      the claudecode spec (one entry, not two), and `lazy-lock.json` pins
      the three plugins to 40-hex commits.
- [ ] Stage --headless (seeded, offline, git-shimmed like its siblings):
      all fourteen cmd stubs exist before any load; the nine `<leader>a*`
      stubs are in `nvim_get_keymap` with n-mode or v-mode as specced; no
      plugin body loaded (no `claudecode.` in package.loaded at startup);
      firing :ClaudeCode outside tmux leaves claude-tmux's is_available()
      false and resolves the auto provider.
- [ ] The lockfile counterfactual: with one of the three lock entries
      deleted from a COPY, the staged startup records a git-clone attempt
      (the measured hermeticity break) — proving the pin is what the offline
      guarantee rides on.
- [ ] gates/nvim-seed-registry.sh still exits 0 after the change and its
      launcher table still set-equals the accounted gates — a new nvim
      launcher (tests/nvim-claude.sh) added to tests/ must declare itself
      seeded or immune, per that gate's Part B.
- [ ] With spec01's lockfile landed, `bash tests/nvim-small-plugins.sh`
      exits 0 again — the three clones stop, because seeding now copies the
      pinned plugins from the live store instead of letting lazy fetch.

## Verify and Proof

```sh
bash tests/nvim-claude.sh
bash gates/nvim-seed-registry.sh
bash tests/nvim-small-plugins.sh
```