---
kind: documentation
description: the repo tree — which directory holds what, and which file is authority for which question
read_when: "looking for where something lives"
---

# The tree

| path | holds | authority for |
|---|---|---|
| `home/` | the chezmoi source — the deliverable | how the machine is configured |
| `memos/SYSTEM.md` | the entry point linking into [[memo-layout]] and [[memo-index]] | what a memo is |
| `memos/system/` | kind declarations, memo protocols, commands, routines | what a kind is, adding a kind |
| `memos/<kind>/` | every memo of that kind | the record itself |
| `.pearde/prds/` | the PRD board — work in flight, moved through nine states | what is being built now |
| `.pearde/workflows/` | how a kind of job is done, improved on every run | worker procedure |
| `docs/capabilities-*.md` | the rated inventories — the rating record, no longer edited | why a capability was taken or left |
| `scripts/` | `board-guard.py`, `generate-manual.mjs`, `memos-check.py` | the gates |
| `home/dot_config/nushell/help/manual/` | the environment manual, shipped with the shell | how the user drives the machine |
| `justfile` | every command | the commands |

`CLAUDE.md` and `AGENTS.md` are the same file by symlink — one protocol,
two names.

No second planning file: a plan is work memos. No changelog: git is the
archive ([[the-frontier-law]]).