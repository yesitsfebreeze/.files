# Feature: Claude launchers (SIMPLIFY)

Parent: [Nushell epic](00-epic.md) · C 7 · U 6 · source: "Claude launchers"
in capabilities-nushell.md · verdict: take over a reduced version

## Summary

The current setup wraps Claude Code in a login-profile system (`~/.claude/`
subdir per account, heavy state shared back via symlinks, credentials
isolated) plus goal-loop (`cl`) and journal (`jj`) launchers. For the minimal
base, keep the daily commands and shed ceremony.

## Requirements (minimal base)

1. **`cc [...args]`** — Claude with `--dangerously-skip-permissions`.
2. **`cr [...args]`** — same, with `--resume`.
3. **Profile picker only when it matters.** With a single profile, `cc`
   launches directly — no picker. The multi-login machinery (`_claude_share`
   seeding, keychain-aware profile detection, `.last-login` ordering)
   activates only once a second profile exists.

## Deferred (personal add-ons, not part of the base)

- `cl <task>` — goal-loop seeding via `cl.py` under a pty.
- `jj` — zoxide-resolved journal dir + Claude.
- `zc` stays, but it's specced with the zoxide suite
  ([03-zoxide.md](03-zoxide.md)).

## Acceptance criteria

- Fresh machine, one login: `cc` starts Claude immediately, no prompt.
- After creating a second profile: `cc` offers the picker, last-used first,
  bare Enter relaunches it; the new profile shares plugins/history but logs
  in with its own credentials.
