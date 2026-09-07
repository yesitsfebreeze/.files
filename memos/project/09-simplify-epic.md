---
kind: project
description: the 09-simplify epic — the rebuild is built, this epic removes everything that is not the daily driver
read_when: "tracking what is left of the simplification plan, or the final I5 deploy"
---

# 09-simplify-epic

The rebuild is built. The week of 2026-08-26 measured what grew around
it: a 7.2 MB board beside 1.3 MB of configuration, a 6,185-line manual
for one reader, config files that are two-thirds comment, and 58 of 78
commits that never touched `home/`. The user's standing rule,
given 2026-09-02: **the smaller and more straightforward everything is,
the better.**

Five invariants (I1–I5) govern every config change in this repo:
no changelog comments, no PRD node for anything outside `home/`, no
stale counts in prose, a built-in over a wrapper, and every child
proven by deploying and using it.

Children (all `done` as of 2026-09-07 except `05-terminal` in `refine`):
`01-hygiene`, `02-board`, `03-help-system`, `04-nushell`,
`05-terminal`, `06-neovim-television`, `07-provisioning`,
`08-litellm-out` (failed). Four corrections trees retired, three open
decisions resolved, two on-axis PRDs.

When this epic is `done`: `home/` is ~6,300 lines instead of 10,800,
the board holds every `prd.md` and no spec, `AGENTS.md` is ~60 lines,
and no file in the repo cites `tests/`, `gates/` or `docs-site/` as if
they existed. Every gesture the daily driver uses still works, and the
four it loses are named in `08-litellm-out` and `04-nushell`.