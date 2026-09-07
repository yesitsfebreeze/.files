---
workflow: simplify-a-nushell-surface-and-deploy-it
subject: 04-nushell — built-ins, one append, no tombstones
date: 2026-09-02
runs: 1
tags:
  - workflow
---

## Use when

- A PRD asks for real deletions and consolidations across a shell
  config's surface (dead code, tombstone comments, second-machine
  branches) AND its acceptance requires proving the result live, not
  just that it parses.
- Not when the change is deletion only with no live-behavior acceptance
  — `delete-what-nothing-reads` fits that alone.

## Steps

| # | atomic | why | on failure |
|---|--------|-----|------------|
| 1 | `measure-the-premise-not-the-prd` | two requirements (R9's shquote merge, part of R4's theme.nu range) rested on facts the earlier requirements in the same PRD had already changed | `stop` |
| 2 | `prove-nothing-reads-it` | confirmed both shquote helpers and the ChtSheet decode arm had zero callers left before deleting them | `→ 1` |
| 3 | `prove-in-a-shell-that-loaded-the-config` | `nu -c` loads neither env.nu nor config.nu; every acceptance check ran as `nu -l -c` against the deployed tree instead | `→ 1` |
| 4 | `apply-scoped-not-bare` | the working tree held many unrelated pending changes from other PRDs; `chezmoi apply <path>...` named every touched target instead | `stop` |
| 5 | `check-what-apply-left-behind` | four deleted source files (copymode.nu, three cable .toml) stayed deployed after the scoped apply and needed a manual `rm` | `→ 4` |
| 6 | `run-the-verify-twice` | ran the acceptance battery, then re-ran the F6 toggle and the keybindings count a second time before trusting either | `→ 3` |

A step naming an atomic already in the library (1, 2, 3, 4, 5, 6 above)
writes no new block — all six are already on record.
