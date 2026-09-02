#!/usr/bin/env bash
# chezmoi run_after — register the tmux MCP server with Claude Code.
#
# Covers 08-claude-agent/01-tmux-mcp spec02. One idempotent thing per apply:
# `claude mcp add --scope user tmux-mcp -- ~/.local/bin/tmux-mcp
# -shell-type bash -scope agentic`. A failure of the tool it needs is a
# WARNING and never a dead apply (epic I4): a run_after exiting non-zero
# fails the whole apply, so this ends in an explicit `exit 0` and carries no
# `set -e`. It owns no file — ~/.claude-anything is not chezmoi-managed,
# which is exactly why the mechanism is a script the apply executes rather
# than a file chezmoi renders.
#
# WHY THE THINGS THAT LOOK ODD ARE THE WAY THEY ARE — drop any of these and a
# defect is reinstated, measured 2026-08-31 (Claude Code 2.1.251):
#
# 1. **The destination is top-level `mcpServers` in `~/.claude.json` (user
#    scope), NOT `~/.claude/settings.json`.** The PRD body and the upstream
#    README both say settings.json; a `mcpServers` block there is IGNORED —
#    `claude mcp list` reports no servers — while
#    `claude mcp add --scope user` writes top-level `mcpServers` in
#    ~/.claude.json and `claude mcp list` then sees it. The PRD's wording is
#    filed as a correction, not obeyed.
#
# 2. **`env -u CLAUDE_CONFIG_DIR` is load-bearing.** The multi-login profile
#    model (04-shell/08) writes that variable from `cc`'s picker, and agent
#    harnesses set it too. Let it through and the server registers into
#    whatever profile happened to be last-used, and the user's default `cc`
#    launch never sees it.
#
# 3. **The command is the ABSOLUTE `$HOME/.local/bin/tmux-mcp`.** The apply's
#    PATH is not the login shell's and must not be relied on to carry
#    ~/.local/bin — and the entry is read back later by whatever process
#    launches the server, with its own PATH.
#
# 4. **`claude mcp add` is itself the idempotency guard.** Overwriting an
#    existing entry is the goal, but the CLI does not agree on what that
#    looks like: it has been observed both ways on 2.1.251 — as a quiet
#    in-place overwrite (exit 0), and as "MCP server tmux-mcp already exists
#    in user config" followed by a NON-ZERO exit (seen 2026-08-31, from a
#    nested launch inside a live Claude Code session; unconfirmed whether
#    nesting is the trigger). So the exit code is not trusted: the output
#    is captured, an "already exists" counts as registered-and-fine, and
#    only any other failure stays a warning. No `claude mcp get` pre-check
#    either way: that spawns a health check — a real connection attempt per
#    apply — for information the rewrite makes stale anyway.
set -u

log()  { printf '\033[1;34m::\033[0m mcp: %s\n' "$*" >&2; }
warn() { printf '\033[1;33m!!\033[0m mcp: %s\n' "$*" >&2; }

if ! command -v claude > /dev/null 2>&1; then
    warn "claude is not on PATH — tmux-mcp stays unregistered (install Claude Code, then re-run \`claude mcp add --scope user tmux-mcp\`)"
    exit 0
fi

log "registering tmux-mcp (user scope, shell-type bash, scope agentic)"
out="$(env -u CLAUDE_CONFIG_DIR claude mcp add --scope user tmux-mcp -- \
    "$HOME/.local/bin/tmux-mcp" -shell-type bash -scope agentic 2>&1)" \
    && log "tmux-mcp registered (${out##*$'\n'})" \
    || case "$out" in
        *"already exists"*) log "tmux-mcp already registered — nothing to do" ;;
        *) warn "claude mcp add failed: ${out:-no error text}" ;;
       esac

# Explicit, and load-bearing: a non-zero run_after fails the whole apply.
exit 0