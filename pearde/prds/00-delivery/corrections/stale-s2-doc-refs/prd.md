---
state: done
claim:
priority: 25
est: 1.5h
needs:
mode: afk
verify: ""
origin: derived
from: 04-shell/02-aliases-utilities
---

# Stale references left by the bb/ba `DO NOT PORT` decision

Two documents still describe the world as it was before
[`04-shell/02-aliases-utilities`](../../../04-shell/02-aliases-utilities/prd.md)
dropped the `bb`/`ba` session aliases and renumbered around them. Found by
the S.2 analyst on 2026-08-22 while speccing; out of that node's lane, so
recorded here instead of fixed there.

- `home/dot_config/nushell/help/shell.nuon` carries a `bb / ba` entry with
  `source: .mi/prds/04-shell/02-aliases-utilities/prd.md` and `verify`
  targets on aliases `bb`/`ba` — aliases that PRD's Out of scope rates
  `DO NOT PORT`. The manual documents commands that will never ship, sourced
  to the PRD that excludes them. Removing the entry touches 06-help's data
  and its review rows.
- `prds/05-platform/01-deploy-mechanism/prd.md` (Out-of-scope note) says
  `rr` moved to the aliases node as "R4"; it is **R3** there — R4 was
  bb/ba's number and is a deliberate gap. One-line stale cross-reference.

Done means: no board or shipped file references `bb`/`ba` as a live alias,
and the `rr` cross-reference names R3.

## Failure
