---
kind: routine
name: land-an-answered-fork
description: 08-claude-agent/02-nvim-plugin
read_when: "executing land-an-answered-fork"
---

# land-an-answered-fork

_Origin: `pearde/workflows/land-an-answered-fork.md` (workflow subject: "08-claude-agent/02-nvim-plugin")_


## Use when

- A fork that stopped a build has been answered, and the answer has to land in
  a configuration this repo deploys — the answer is now the contract, and the
  previous run's report on disk is history.
- NOT the case where nothing was asked and the build is fresh: that is an
  ordinary build against the owning epic, and the route for wiring a tool the
  shell cannot reach is `wire-a-tool-into-the-shell`.

## Steps

| # | atomic | why | on failure |
|---|--------|-----|------------|
| 1 | `take-the-answers-not-the-stale-report` | the report on disk carried a `Verdict:` line that read as current and described a contract two answers had already replaced | `stop` |
| 2 | `apply-scoped-not-bare` | the working tree held ~40 unrelated modified files; a bare `chezmoi apply` would have deployed every one of them alongside | `stop` |
| 3 | `read-the-merged-config-not-the-source` | the source file said nothing about which side the panel opens; only the plugin's own merged table and the real pane geometry could say, and they disagreed with the manual | `→ 2` |
| 4 | `rerun-the-drift-check` | `help --check` is the one command that says the configuration and its manual still agree | `→ 3` |
