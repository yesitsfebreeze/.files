---
kind: knowledge
description: help reads entries from the .nuon surfaces, ? reads prose line by line through television — one corpus, four constraints
read_when: "touching help.nu, the manual, or the .nuon surfaces"
---

# the-help-command-is-two-searches-over-one-corpus

`help` addresses the manual's **entries** — one key, one command, by name —
reading the four `.nuon` surfaces under `~/.config/nushell/help`. `?` addresses
the manual's **prose** — every line of `guide/`, `reference/` and
`internals/`, which `just manual` generates from those same surfaces — and
opens the hit in the editor at that line. Two searches over one corpus,
deliberately separate.

Four constraints shape `help.nu`:

1. **The `std/help` capture is in `config.nu` and cannot move.** `use std/help`
   and `def help` in one file fail at parse (`unknown_flag` into
   `std/help/mod.nu`) — nushell predeclares a block's defs before parsing its
   statements, so std's `@example {help --find}` attribute resolves against our
   predeclared signature. `core-help` is an **alias** on purpose: alias targets
   bind at parse time, so it stays bound to std's help after our def shadows
   the name, and it must precede the shadow.
2. **The corpus is addressed one way and no other**: `$nu.home-dir | path join
   ".config" "nushell" "help"`. `config-path`-style resolution can name a
   directory that did not supply the running `help.nu` — a manual that renders,
   exits 0, and describes a different machine (measured with a marker def in
   two trees). No fallback chain: one resolution, never "try elsewhere" — a
   fallback is what turns "not found" into "found somewhere wrong".
3. **Every failure is loud.** A corpus that is absent or degenerate raises; it
   never renders an empty manual — a zero-byte `topics.nuon` printed
   `Topics:` with nothing under it and exited 0, which reads as "this
   environment has no custom bindings", the most expensive wrong answer help
   can give.
4. **`ls --help` and `help ls` are indistinguishable** — nushell routes
   `<cmd> --help` to the custom help, so both spellings resolve identically and
   anything undocumented is forwarded to `core-help` untouched.

`guide/` and `reference/` are generated from the `.nuon` surfaces and cannot
drift; `internals/` is hand-written and nothing regenerates it, so a new page
gets its index row in the same change. The renderers hold layout only, never
content — a description of a binding written in `help.nu` is a bug, because it
would be a second source for something the corpus says once.