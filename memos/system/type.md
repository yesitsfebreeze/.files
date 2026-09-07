---
kind: type
type: type
description: the one kind the gate hardcodes — a kind declaration, the only shape the index reads by name
read_when: "adding a kind, or asking why the folders are what they are"
---

# type

A memo with `kind: type` is a declaration, and the only shape the gate reads
by name. Its `type:` line is the name it declares: `system/decision.md`
carries `type: decision`. The leaf is the same word wherever that word is
free — `system/work-memo.md` declares `work` because the routine [[work]]
holds the leaf. Nothing else registers a type — no const, no config. The body
says what a memo of that kind is, which keys it requires and allows, which
headings its body may carry, and what makes a reader trust it.

The folder is the kind: a memo with `kind: X` lives at `memos/X/<leaf>.md`.
The gate refuses a memo outside `system/` whose folder is not its kind, and a
kind no `system/` memo declares. An unknown kind is not silently accepted:
write the declaration.