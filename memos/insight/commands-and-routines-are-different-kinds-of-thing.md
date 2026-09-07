---
kind: insight
description: a command is a memo, a routine is a procedure — the second exists to be invoked, the first exists to be remembered
read_when: "deciding whether a procedure becomes a routine or a memo, or which one a reader reaches for"
---

# commands-and-routines-are-different-kinds-of-thing

A `command` (`memos/system/commands.md`) is the index of every executable
shape a session reaches for — `just memos-check`, `just manual`, `llm
sync`, the two board-guard targets. The reader is anyone, including an
agent on a fresh clone, who needs the verb and the recipe. It is a memo
because it is the catalogue.

A `routine` (`memos/routine/<name>.md`, frontmatter `name:`, the
invocation handle) is the procedure that owns the call: `work`, `drill`,
`plan-execution`, `improve`. The reader is the session running the
procedure. The first step names the catalogue it pulls from — `just
memos-check`, the record's kinds, `git status --short` — by leaf name and
literal path, so the author's search happens once at write time and every
later run inherits it. The procedures are *prepared context* for their
verbs.

The mistake the two are not: a routine that names no ingredient is a style
guide (a list of verbs, nothing a reader can hold onto), and a command
that includes its own procedure is duplicated (the same `just memos-check`
in both `commands.md` and a hypothetical `run-the-check.md`). The
distinction is the reader's job, not the author's: the commands doc gets
read by an agent deciding what to do; the routine gets followed by an
agent doing it.