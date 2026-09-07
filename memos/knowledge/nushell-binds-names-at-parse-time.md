---
kind: knowledge
description: nushell binds names at parse time and three kinds of name differently — def is order-free, alias and source are not
read_when: "reordering a source or alias in config.nu, or chasing a silently dead navigation"
---

# nushell-binds-names-at-parse-time

Nushell binds names at **parse** time, and three kinds of name differently —
almost every ordering constraint in `config.nu` follows from this:

| Kind | When it binds | Order matters? |
|---|---|---|
| `def` | predeclared for the whole block before any body is parsed | **No** — a closure may call a `def` written below it |
| `alias` | where the parser meets the `alias` line | **Yes** |
| `source` | the sourced names enter scope from that line downwards | **Yes** |

Measured both directions (nushell 0.114.1): a PWD closure calling `def la`
written **below** it ran fine on the first `cd`; `alias core-ls = ls` **must**
precede `def ls` — alias after the def answered `Command core-ls not found`
loudly on the first `ls`.

The silent one: `alias cd = mkcd` must come **before** the generated zoxide
init is sourced. The generated `~/.cache/nushell/init/zoxide.nu` calls `cd` in
two places, and nushell binds those calls when it parses *that* file. Alias
after — the jump still lands and prints **nothing**; `startdir.txt` and the
dirstack simply never update for zoxide jumps. The navigation funnel invariant
dies quietly.

The corollary that bit: an unresolved name binds as an **external**. The
reversed MODULES order made `zc` (which calls `cc`) resolve `cc` to
`/usr/bin/cc`, the C compiler — no parse error, a compiler invocation at
runtime. Every entry point a def body names must be parsed before the body.