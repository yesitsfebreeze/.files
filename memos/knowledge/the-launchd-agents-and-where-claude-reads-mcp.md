---
kind: knowledge
description: the proxy is two launchd agents and the MCP server is registered in ~/.claude.json, not settings.json
read_when: "wiring the proxy's service, or debugging a missing MCP server"
---

# the-launchd-agents-and-where-claude-reads-mcp

**The proxy is a launchd agent pair**, loaded by
`run_onchange_after_load-litellm.sh` keyed on the hook and both plists:
`litellm.plist` (KeepAlive — up from login, back within seconds of dying,
because litellm takes about two minutes to load ~2000 deployments) and
`litellm-sync.plist` (nightly 04:30 `llm sync`, so the scores, shelf and
windows are never older than a day). It is `run_onchange`, not `run_after`,
because a load restarts the proxy and that cuts every request in flight — a
plain run_after would do it on every apply. `llm sync` itself restarts the
proxy only when the generated config changed: an un-restarted proxy was stale
for days once, silently.

**The MCP server is registered in `~/.claude.json`, not
`~/.claude/settings.json`** — the upstream README says settings.json and it is
wrong: a block there is ignored and `claude mcp list` reports no servers.
`run_after_register-mcp.sh` writes top-level `mcpServers` there, with
`env -u CLAUDE_CONFIG_DIR` load-bearing: the multi-login profile model sets
that variable, and letting it through registers the server into whatever
profile was last used. The path is absolute because the apply's PATH is not
the login shell's.