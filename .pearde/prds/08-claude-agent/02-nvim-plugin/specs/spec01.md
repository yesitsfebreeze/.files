---
complexity: 8
footprint:
  - home/dot_config/nvim/lua/plugins/claude.lua
  - home/dot_config/nvim/lazy-lock.json
---

# spec01 — claude.lua, its three lockfile pins, and the commit

The plugin file is built, deployed and measured working; this unit is the
bookkeeping left around it. `home/dot_config/nvim/lua/plugins/claude.lua`
carries claudecode.nvim as the one lazy spec — the fourteen `cmd` stubs, the
nine `<leader>x*` keys, `terminal_cmd = "cll"`, `folke/snacks.nvim` and
`mr55p-dev/claude-tmux.nvim` as its dependencies, and a `config()` that swaps
in the claude-tmux provider only when `is_available()` answers true.
`lazy-lock.json` carries the three new pins. Both files are modified in the
working tree and neither is committed. That commit is what is left.

## What already stands, measured 2026-09-02

Against the **deployed** `~/.config/nvim`, not a sandbox — `chezmoi apply`
scoped to the one file, then `:ClaudeCode` fired from a real headless nvim
inside a private tmux server (`tmux -L npprobe`, 200x50 client):

- `FIRE-ClaudeCode true`, `TERMINAL-CMD cll`, `PROVIDER-TYPE table`,
  `CT-AVAILABLE true`.
- Merged claude-tmux config reads `split_side = "right"`, `split_size = 30`,
  `toggle_key = "<C-j>"`, `split_width_percentage = 0.3`.
- Panes: `%0 left=0 139x50`, `%1 left=140 60x50` — a right split.
- `bind-key -T root C-j if-shell -F "#{==:#{pane_id},%1}" "select-pane -t %0"
  "send-keys C-j"` is present in the tmux key table.
- `help --check` → `clean`: stale 0, mismatched 0, undocumented 0.
- `git diff --stat home/dot_config/nvim/lazy-lock.json` → `1 file changed,
  3 insertions(+)`; 23 entries, sorted.
- The live store holds claudecode.nvim `2390c6e`, claude-tmux.nvim `90b221c`,
  snacks.nvim `882c996` at the pinned commits.

## What is left

The commit. Both files are `M` in a working tree holding roughly forty
unrelated modifications, so the commit is scoped to these two paths and
nothing else.

## Acceptance

- [x] `home/dot_config/nvim/lua/plugins/claude.lua` holds no `split_side` key
      — only the comment explaining why the panel is not this file's choice
      (Q2, answered 2026-09-02). `grep -n 'split_side =' ` over the file
      matches only lines beginning with `--`.
- [x] `git diff --stat HEAD -- home/dot_config/nvim/lazy-lock.json` reports
      exactly `3 insertions(+)` and `0 deletions`, the entries being
      claude-tmux.nvim `90b221c…`, claudecode.nvim `2390c6e…`,
      snacks.nvim `882c996c…`, each a 40-hex `main`-branch pin, sorted into
      place, with no other line moved.
- [x] `chezmoi diff ~/.config/nvim/lua/plugins/claude.lua` prints nothing —
      the source and the deployed file agree.
- [x] `help --check` exits 0 and reports `stale: 0 · mismatched: 0 ·
      undocumented: 0`, run in a shell that loaded the config
      (`nu --env-config ~/.config/nushell/env.nu --config
      ~/.config/nushell/config.nu -c 'help --check'` — `nu -c` alone loads no
      config and answers on an empty corpus).
- [~] One commit exists whose `--stat` names those two paths and no third.

## Verify and Proof

```sh
grep -n 'split_side =' home/dot_config/nvim/lua/plugins/claude.lua
git diff --stat HEAD -- home/dot_config/nvim/lazy-lock.json
chezmoi diff ~/.config/nvim/lua/plugins/claude.lua
nu --env-config ~/.config/nushell/env.nu --config ~/.config/nushell/config.nu \
   -c 'help --check'
git show --stat --oneline HEAD -- home/dot_config/nvim/
```

## Out of scope

- No checks written. Q1, answered 2026-09-02: the `tests/` and `gates/`
  retirement stands, and this integration is proven by deploying it and using
  it. The former spec02 named `tests/nvim-claude.sh` and
  `gates/nvim-seed-registry.sh`, both deleted by `ad3f1a6`; it is deleted, not
  rewritten.
- No manual entries. `home/dot_config/nushell/help/nvim.nuon` belongs to
  `08-claude-agent/04-help-entries`; one stale sentence there is a finding in
  the report, not work here.
