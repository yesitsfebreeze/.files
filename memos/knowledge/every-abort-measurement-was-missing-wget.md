---
kind: knowledge
description: every measurement of the offline first-save abort ran on a PATH with no wget, which the machine has — the bug is unmeasured on a faithful PATH
read_when: "measuring an offline behaviour, or trusting the mason abort numbers"
---

# every-abort-measurement-was-missing-wget

The claim "launching Neovim offline discards the first buffer write" is
**unmeasured on a faithful PATH** — not reproduced, not refuted. Every
measurement on this tree was taken in a fixture whose `PATH` had no `wget`,
and this machine has `wget` at `/opt/homebrew/bin/wget`.

Any future check of this behaviour shims **both** `curl` and `wget`, and says
why: a fixture that omits `wget` is not an offline machine, it is a machine
missing a program. Deleting the `wget` shim to make the race fire again is
forbidden — that manufactures the result.

The mechanism: mason's fetch is `curl():or_else(wget):or_else(…)`. With no
`wget` binary the fallback fails at spawn rather than spawning, and the curl
stdin shutdown then lands in a starved window where `uv.shutdown` returns
`ENOTCONN`, re-raised inside a libuv callback and out through whatever was
pumping the loop. With `wget` present — real or shimmed — the sequence does
not reach that window.

The general law it leaves: a fixture is only as faithful as the programs it
carries, and an offline test that lacks a binary the machine has measures a
different machine.