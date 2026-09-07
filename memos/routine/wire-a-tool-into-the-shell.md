---
kind: routine
name: wire-a-tool-into-the-shell
description: pearde-shell-wiring
read_when: "executing wire-a-tool-into-the-shell"
---

# wire-a-tool-into-the-shell

_Origin: `pearde/workflows/wire-a-tool-into-the-shell.md` (workflow subject: "pearde-shell-wiring")_


## Use when

- A tool is installed on the machine but not reachable from the shell — an
  alias, an exported variable, a PATH entry — and this repository's shell
  configuration is where it has to land.
- NOT the case where the tool's behaviour itself is what changes, or where a
  new command is being written rather than wired: that is an ordinary build
  against the owning epic, not this route.

## Steps

| # | atomic | why | on failure |
|---|--------|-----|------------|
| 1 | `recover-the-contract` | the PRD body was an unfilled template; two independent sources named the two lines, which is what made building possible without asking | `stop` |
| 2 | `write-into-the-chezmoi-source` | put both lines in `home/`, never in the deployed tree, so the change survives the next apply | `stop` |
| 3 | `apply-scoped-not-bare` | the working tree held unrelated pending changes; a bare `chezmoi apply` would have deployed them alongside | `→ 2` |
| 4 | `prove-in-a-shell-that-loaded-the-config` | `nu -c` loads no config and reports a correct change as absent — this is the step that catches the false negative | `→ 2` |
| 5 | `document-the-new-surface` | this shell's drift check fails on any alias with no manual entry, so the entry is part of the change, not a follow-up | `→ 2` |
| 6 | `rerun-the-drift-check` | `help --check` is the one command that says the configuration and its manual still agree | `→ 5` |
