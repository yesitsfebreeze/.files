# probe pass two — 2026-09-02, analyst-nvim (re-spec after Q1/Q2 were answered)

Ran against the **deployed** config, not a sandbox. Pass one staged a scratch
XDG tree; this pass took the shorter route the board now prescribes — deploy
it and use it — because `tests/` and `gates/` are gone (`ad3f1a6`).

## Route

```sh
chezmoi apply ~/.config/nvim/lua/plugins/claude.lua      # scoped: ~40 unrelated M files in the tree
tmux -L npprobe -f /dev/null new-session -d -x 200 -y 50 -s p "/bin/bash run.sh"
# run.sh: PROBE_OUT=out.txt nvim --headless -c 'lua vim.defer_fn(function() dofile("fire.lua") end, 2500)'
tmux -L npprobe list-panes -t p -F '#{pane_id} left=#{pane_left} #{pane_width}x#{pane_height}'
tmux -L npprobe list-keys -T root | grep C-j
nu --env-config ~/.config/nushell/env.nu --config ~/.config/nushell/config.nu -c 'help --check'
```

`fire-deployed.lua` beside this file is the probe body: it fires `:ClaudeCode`
through the command path a person would press, then reads back
`claudecode.state.config` and `claude-tmux.get_config()`.

## Output

```
TMUX /private/tmp/tmux-501/npprobe,40053,0
FIRE-ClaudeCode true
TERMINAL-CMD cll
PROVIDER-TYPE table
CT-AVAILABLE true
CT-CONFIG true { ... split_side = "right", split_size = 30, split_width_percentage = 0.3,
                 terminal_cmd = "cll", toggle_key = "<C-j>" }
%0 left=0 top=0 139x50 cmd=bash
%1 left=140 top=0 60x50 cmd=bash
bind-key -T root C-j if-shell -F "#{==:#{pane_id},%1}" "select-pane -t %0" "send-keys C-j"
help --check: clean   (stale 0 · mismatched 0 · undocumented 0 · unresolved 3, all pre-existing)
```

## What this pass settles

- **Q2 is landed and true.** No `split_side` key in the source; the pane still
  opens right, 60 columns of 200. Third independent reproduction.
- **The `<C-j>` toggle is a tmux ROOT binding, pane-conditional**, so nvim's
  own `<C-j>` window-down is untouched by construction — outside the Claude
  pane tmux passes the key straight through with `send-keys C-j`. Pass one
  listed this as needing a human; it does not. On record as `[[260902-18ad]]`.

## Still not proved, and not provable headless

`:ClaudeCode` connecting to an **interactive** Claude over the MCP handshake.
The probe pane spawns `cll`, whose model picker wants a TTY; the pane came up
`bash`. This belongs at `manual → internals/unverified`, owned by 06-help.

## Trap kept from pass one, re-confirmed

Do not seed a staged plugin store with symlinks — lazy.nvim reads the dirent
type and reports every linked plugin `not installed`. `cp -Rc` (APFS
clonefile) instead. On record as `[[260902-5a05]]`.
