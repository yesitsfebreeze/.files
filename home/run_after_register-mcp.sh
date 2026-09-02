#!/usr/bin/env bash
# chezmoi run_after — register the tmux MCP server with Claude Code.
#
# TRAP: the destination is top-level `mcpServers` in `~/.claude.json` (user
# scope), NOT `~/.claude/settings.json`. Both the upstream README and this
# board's own PRD say settings.json; a `mcpServers` block there is IGNORED —
# `claude mcp list` reports no servers — while `claude mcp add --scope user`
# writes ~/.claude.json and `claude mcp list` then sees it. Measured
# 2026-08-31 on Claude Code 2.1.251. See internals/provisioning for the rest.
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