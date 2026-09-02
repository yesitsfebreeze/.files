---
state: done        # open|analyzing|refine|question|specced|claimed|blocked|done|failed
origin: requested  # requested = the user asked | derived = the board found it
# from:            # derived only — the PRD whose work surfaced this one
priority: 20        # higher first
complexity: 0      # analyst, at spec time — 1-100. THE WEIGHT the board schedules by
blast-radius:      # analyst, at spec time — high|mid|low. What breaks if this is wrong
repo:              # the sub-repo the code lands in; delete if n/a
# workflow:        # OPTIONAL — how this kind of job is done: a slug in
#                  #   prds/workflows/. @references/workflow.md.
#                  #   Absent = the brief alone, as before workflows
time:              # OPTIONAL. See @references/parts/order.md
  est:             # the weight, only when complexity is absent. Not a duration
  actual: 1.14h
  # claim: <worker> <started>   # orchestrator-only, present while a worker holds this PRD
commit: 026c634
---
<!-- Ordering reads three axes and no clock: dependency (needs + footprint),
     vision importance (priority), and complexity/blast-radius. Add your own
     keys freely, at any nesting. Nothing outside state, origin, from,
     priority, complexity, blast-radius, claim, repo, workflow, needs and
     footprint is read, and nothing you add is ever dropped.
       needs:     — PRD dir names this one depends on. A hard gate in `plan`
       footprint: — paths this PRD touches. The overlap check
       workflow:  — the route a worker is handed, expanded into its brief

     One sitting is the limit: specs summing `complexity` above `split-above`
     or counting above `specs-above` (both in prds/settings.md, default 40 and
     6) make the analyst's verdict REFINE, and `pearde refine` lands the split
     under `## Children` here — the contract above it stays as written.

     A derived PRD states, in the body, which requested PRD it would otherwise
     get wrong. If it cannot, it is filed `state: deferred` — and if fixing it
     would change only how loudly the board notices, it is a memo, not a PRD.
     See @references/parts/derived.md. -->

# Epic: Claude agent — Claude Code manages tmux panes and edits in nvim

Parent: the board root · net-new · C 7 · U 8

Purpose: Claude Code already launches from this environment — `cc`/`cr`
([`04-shell/08`](../04-shell/08-claude-launchers/prd.md), done) — but it
cannot reach back into the environment it runs in. It has no way to create or
manage tmux panes, and its only editor is the one it opens through `$EDITOR`.
This epic gives Claude Code the two hands it is missing: a tmux MCP server so
it can spawn, watch and kill panes, and the claudecode.nvim integration so it
edits inside nvim with the full editor experience — inline diffs, buffer
management, send-selection. The agent then works the way a human at this desk
does: tmux owns the panes, nvim owns the editing, and the shell tools on PATH
are the same for both.

**When this is done:** Claude Code, launched from nvim (`<leader>ac`) or the
`cc` launcher, can create, split, watch and kill tmux panes through the
`tmux` MCP server; it edits files through nvim with inline diff accept/deny
and send-selection; and the whole thing runs inside the `main` tmux session
with Shift+Enter and notifications intact. `help --check` passes with the new
bindings documented.

## Constraints

- **The nushell mismatch is real and stays.** tmux-mcp's `--shell-type`
  supports `bash|zsh|fish`, not nushell, and the panes this environment
  spawns run nushell (`default-command`, 07-multiplexer). `execute-command`
  exit codes are therefore unreliable; agent workflows must rely on
  output-pattern monitoring (`start-and-watch` matches readiness patterns in
  output, not exit codes). No child may claim exit codes work.
- **Claude Code's Bash tool runs bash, not nushell.** It sources
  `~/.zshrc`/`~/.bashrc`/`~/.profile` at start. Nushell aliases and functions
  (`mkcd`, `cc` itself) are not available to Claude; the standalone binaries
  on PATH (television, zoxide, fd, rg, bat) are. "All our defined tools"
  means the binaries, not the nushell layer.
- **`help --check` binds.** Every new keybinding (`<leader>a*`, the
  claude-tmux `<C-j>` toggle) needs a `06-help` entry or the check fails.
- **The profile model is bypassed by the plugin.** claudecode.nvim launches
  `claude` directly, so it does not go through the `cc` profile picker
  (04-shell/08 R3). The nvim-launched instance uses the default profile.
  Accepted, not fixed, in this epic.
- **The extended-keys tension.** The repo deliberately pairs WezTerm's
  `enable_kitty_keyboard = false` with nushell's `use_kitty_protocol = false`.
  `set -s extended-keys on` changes what tmux SENDS to pane programs and can
  disturb that pairing. Ctrl+J works for newlines without it. The tmux-config
  child must decide this with the reason attached, not flip it blindly.

## Non-goals

- **No nushell support in tmux-mcp.** Out of our control; the mitigation is
  output-pattern monitoring.
- **No changes to the `cc`/`cr` launchers or the profile model.**
  [`04-shell/08`](../04-shell/08-claude-launchers/prd.md) is done and stays.
- **No second multiplexer.** Claude's panes are tmux panes in the `main`
  session, never a parallel scheme.
- **No changes to the tmux key tables.** F4/F5/F6 stay as 07-multiplexer
  shipped them; this epic only appends what Claude Code needs.

## Pointers

- `home/dot_config/nushell/claude.nu` — the `cc`/`cr` launchers and the
  profile model (04-shell/08, done).
- `home/dot_config/tmux/tmux.conf` — the tmux base; later nodes append
  sections and do not edit earlier ones.
- `home/dot_config/nvim/lua/plugins/` — the lazy.nvim plugin stack; a new
  `claude.lua` lands here.
- [`prds/07-multiplexer/prd.md`](../07-multiplexer/prd.md) — the tmux epic
  this one builds on.
- [`prds/04-shell/08-claude-launchers/prd.md`](../04-shell/08-claude-launchers/prd.md)
  — the launchers this extends.
- Research: the MadAppGang/tmux-mcp README (tool list, `--shell-type`/`--scope`
  flags), the coder/claudecode.nvim README (keymaps, snacks.nvim dependency),
  the mr55p-dev/claude-tmux.nvim README (tmux provider), and Claude Code's
  terminal-config docs (the tmux section).

## Children

| child | contract | needs |
|---|---|---|
| `01-tmux-mcp` | The tmux MCP server: `tmux-mcp` installed (an `install.sh` obligation), registered as an MCP server in `~/.claude/settings.json` with `--shell-type bash --scope agentic`, and the nushell exit-code caveat carried as a constraint. Claude can create, split, watch and kill panes through it. | — |
| `02-nvim-plugin` | claudecode.nvim + claude-tmux.nvim in the lazy.nvim stack: `lua/plugins/claude.lua`, snacks.nvim dependency, `<leader>a*` keymaps, Claude Code in a tmux split. | — |
| `03-tmux-config` | The tmux.conf additions Claude Code needs inside tmux: the extended-keys decision with its reason, and anything else the terminal-config docs require. | 07-multiplexer/01-session-and-windows |
| `04-help-entries` | `06-help` entries for the new bindings so `help --check` passes. | 02-nvim-plugin |

## Report

container: every child done — pearde collect closes it

children: 08-claude-agent/04-help-entries, 08-claude-agent/01-tmux-mcp, 08-claude-agent/03-tmux-config, 08-claude-agent/02-nvim-plugin
