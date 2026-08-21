---
state: open
mode: afk
deps:
  - .mi/prd/04-shell/06-listing
  - .mi/prd/06-help/01-content-model
verify: ""
---

# Claude launchers (SIMPLIFY)

Parent: [Nushell epic](../prd.md) · C 7 · U 6 · source: "Claude launchers"

Purpose: The current setup wraps Claude Code in a login-profile system
(`~/.claude/` subdir per account, heavy state shared back via symlinks,
credentials isolated) plus goal-loop (`cl`) and journal (`jj`) launchers. For
the minimal base, keep the daily commands and shed ceremony.

## Requirements
- [ ] **R1** — **`cc [...args]`** — Claude with
      `--dangerously-skip-permissions`.
- [ ] **R2** — **`cr [...args]`** — same, with `--resume`.
- [ ] **R3** — **Profile picker only when it matters.** With a single profile,
      `cc` launches directly — no picker. The multi-login machinery
      (`_claude_share` seeding, keychain-aware profile detection,
      `.last-login` ordering) activates only once a second profile exists.

## Acceptance
- [ ] Fresh machine, one login: `cc` starts Claude immediately, no prompt.
- [ ] After creating a second profile: `cc` offers the picker, last-used
      first, bare Enter relaunches it; the new profile shares plugins/history
      but logs in with its own credentials.

## Out of scope
- `cl <task>` — goal-loop seeding via `cl.py` under a pty.
- `jj` — zoxide-resolved journal dir + Claude.
- `zc` stays, but it's specced with the zoxide suite
  ([`03-zoxide`](../03-zoxide/prd.md)).
