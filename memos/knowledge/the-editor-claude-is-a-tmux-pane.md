---
kind: knowledge
description: nvim's Claude pane is a real tmux pane through claude-tmux, spawned via cll so the model is picked at spawn and the login survives
read_when: "touching claude.lua, the nvim↔claude wiring, or a login profile that is not picked up"
---

# the-editor-claude-is-a-tmux-pane

Inside nvim, Claude Code is a real tmux pane: claudecode.nvim with
mr55p-dev/claude-tmux.nvim as its terminal provider, named a **dependency** of
claudecode so lazy loads it before claudecode's `config` runs — claude-tmux has
no user-facing surface of its own, and a second spec entry would add a load
trigger where there is nothing to trigger.

The provider is wired **conditionally**: inside tmux the claude-tmux provider
wins (`:ClaudeCode` opens a split below nvim in the `main` session; `<C-j>`
returns to the editor from that pane only, pane-locally bound); outside tmux
claudecode's default `auto` (snacks) runs — which is also what runs under
`--headless`. snacks.nvim is a dependency even though the tmux provider
bypasses it: the `auto` fallback and diff sizing go through snacks.

The pane spawns through **`cll`** (`terminal_cmd = "cll"`), so the model is
picked at spawn and cll owns the routing: a `native:*` pick execs through
`cc`'s login picker, a proxied pick sets `CLAUDE_CONFIG_DIR` to the litellm
profile and exports the proxy pair. The Lua resolution still earns its keep by
seeding the `CLAUDE_CONFIG_DIR` that cll's native branch inherits when it does
not run its own picker: an inherited logged-in dir is left alone; else
`~/.claude/.last-login` names the profile that is **actually logged in** (the
test is `"oauthAccount"` in the profile's `.claude.json` — `settings.json`
alone exists in logged-out profiles, so file existence decides nothing); else
nothing is exported and Claude's own login flow runs. Resolution happens when
the plugin first loads, not per spawn — a fresh nvim picks up a login from a
`cc` that ran since; a long-running instance does not.

Claudecode's IDE env (`CLAUDE_CODE_SSE_PORT`, `ENABLE_IDE_INTEGRATION`) is
injected independently of `terminal_cmd`, so the WebSocket integration survives
the detour through cll — measured: neither branch unsets those two, and the SSE
port survives `exec`.