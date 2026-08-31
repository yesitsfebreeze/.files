# probe pass one — 2026-08-31, analyst-nvim-plugin

What was built and proved live (scratch sandbox, never the developer's real
Neovim state; XDG redirected, store seeded from real clones):

## Files stood up in the footprint (uncommitted)
- `home/dot_config/nvim/lua/plugins/claude.lua` — full plugin spec:
  claudecode.nvim as the one entry, snacks.nvim + claude-tmux.nvim as its
  `dependencies`, the README's default `<leader>a*` keyset swept for
  collisions, `cmd =` stub list, `config()` wiring the tmux provider only
  when `$TMUX` answers true.
- NO lockfile change carried yet — see "trap" below.

## Proved (sandbox at /tmp/cprobe2)
- All 14 `:ClaudeCode*` commands exist on a fresh start (lazy `cmd` stubs) —
  `vim.fn.exists(':X')` = 2 for every one, BEFORE any load.
- After load, lazy's spec carries all 11 key triggers; keymaps are live:
  `nvim_get_keymap` shows `<Space>ac ac Toggle Claude` etc. (probe1's
  literal `"<leader>ac"` lookup missed because `nvim_get_keymap` returns
  raw `<80>kc` bytes — use `keytrans` or match `desc`).
- Loaded config holds `provider = "auto"`, `split_width_percentage = 0.3`,
  `diff_opts.layout = "vertical"`, `auto_start = true`.
- Outside tmux: provider stays the string "auto", `is_available()` false;
  a real `:ClaudeCode` fires, opens a term://…/claude terminal buffer
  (snacks fallback), integration starts and stops cleanly.
- In tmux (private socket `-L probe-soc`): provider is the claude-tmux
  TABLE; `claude-tmux.setup()` returned config holds
  `{ toggle_key = "<C-j>", split_size = 30, split_side = "bottom" }`;
  `t.open(nil,nil)` created a real tmux bottom split (`split_window` →
  pane id echoed back); a second open focusses, does not duplicate.
  claudecode's `get_provider()` validates the table (all 7 required
  functions present on claude-tmux's provider) and calls
  `provider.setup(defaults)`.
- The in-editor `<C-j>` window-down map is untouched; the toggle binding is
  tmux-side, `bind -n C-j if-shell …`, pane-conditional, removed on close.

## The trap the next worker must keep, verbatim
`claude-tmux`'s `tmux_cmd` runs `tmux …` bare via `io.popen`, so from inside
a pane on a NON-DEFAULT socket (`tmux -L probe-soc`) it would hit the wrong
server — it worked in the probe only because the socket was passed through
`$TMUX`. Plain `tmux` without `-L` follows the outer `TMUX` env, so on the
standard setup it is correct. Do not "fix" this; it is the plugin's design.

## Trap: `Lazy! sync` in a scratch sandbox REWRITES THE WHOLE LOCKFILE
A sandbox sync resolved EVERY pinned plugin to current latest (nvim-lspconfig
221c4388 → 16286347, blink 78336bc → 101d718, …, and DROPPED several entries
when their clones failed mid-run). The lockfile delta this node commits must
be ONLY the three new lines at the commits actually cloned —
claudecode.nvim `2390c6e`, claude-tmux.nvim `90b221c`, snacks.nvim
`882c996c` (snacks is main-branch pinned in the repo lock's style). Never
paste the sandbox's whole rewritten lock over the repo's.

## Gate interaction found (the finding that shaped spec 2)
`tests/nvim-small-plugins.sh` seeds each probe from
`$HOME/.local/share/nvim/lazy/$LOCK_KEYS` and forbids git network calls
under its shim. With claude.lua in the tree and the three plugins absent
from BOTH the repo lockfile and the live store, lazy git-clones them inside
every probe — the gate's two hermeticity checks went red (git-calls.log 87
→ 91/94 lines). Two-step consequence, both measured:
1. until the three entries are in `lazy-lock.json`, the gate fails the
   hermeticity pair (lazy clones what the lock doesn't pin);
2. once they ARE in the lock, `need_seed_source` requires the live store to
   hold them, or it exits 127 with "ASSUMPTION MISSING".
So the implementer's live-store install (HELP_CHECK-clean, i.e. NOT via
`help --check`) is part of the unit, not an optional step.

## Not proved in pass one (deliberately, needs a human at the desk)
- `:ClaudeCode` connecting to a RUNNING interactive claude (pane was
  `claude --version`, which exits; MCP handshake untested).
- The `<C-j>` toggle from inside the claude pane (needs a TTY claude that
  stays open; the pane-conditional binding is confirmed present in tmux's
  key list after open).
- which-key's rendered `<leader>a` group under a real UI.