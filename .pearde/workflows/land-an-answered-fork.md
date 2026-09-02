---
workflow: land-an-answered-fork
subject: 08-claude-agent/02-nvim-plugin
date: 2026-09-02
updated: 2026-09-02
runs: 2
---

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
