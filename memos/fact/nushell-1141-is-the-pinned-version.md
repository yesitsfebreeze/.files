---
kind: fact
description: nushell 0.114.1 is the pinned version — every measurement in the manual was taken on it
read_when: "upgrading nushell, or chasing a behaviour that the manual's measurements might no longer hold"
---

# nushell-1141-is-the-pinned-version

Every measurement recorded in the manual's internals was taken on **nushell
0.114.1**, and that is the version Brewfile pins. Upgrading is a known hazard
the manual has hit: on 0.115 `ans` became a builtin variable name, and an
agent upgrading nushell broke this machine's login shell because the
navigation-funnel's `let reply` was renamed to `let ans`. The shipped code
uses `let reply`; the fix is `let ans` plus a regression spell, but only when
the upgrade lands.

Two other constants the pinned version is the only place the measurement
holds: `$nu.default-config-dir` and `$nu.history-path` resolve at launch and
behave as documented on this version. A future nushell may follow the same
behaviour, but no measurement says it will.