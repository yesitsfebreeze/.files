---
workflow: prove-a-key-binding-on-a-real-client
subject: 05-terminal — tmux.conf to ~250 lines, one palette path
date: 2026-09-02
updated: 2026-09-02
runs: 1
---

## Use when

- A change lands on an interactive binding — a key, a chord, a prompt, a
  popup — and the only honest question is "does pressing it still do the
  thing", which no shell command asks.
- Not when the surface answers from a shell and the binding is incidental:
  that is `replace-a-hand-rolled-mechanism` for a swap, or
  `cut-a-feature-its-readers-still-name` when the machinery has live readers
  and the keys are unchanged.

## Steps

| # | atomic | why | on failure |
|---|--------|-----|------------|
| 1 | `measure-the-premise-not-the-prd` | the prior pass's own notes said the live files were untouched; they had been rewritten nine minutes later, and a report that trusted them would have re-done every cut | `stop` |
| 2 | `drive-the-surface-on-a-real-client` | `new-session -d` refuses a `display-popup`, so the binding read as broken on the convenient harness; a pty client turned "unknown command" into a real dispatch | `stop` |
| 3 | `bisect-which-command-expands-the-format` | `-e` arrived literal and `-d` did not, which is the whole defect; testing the same popup as a key binding, inside a template, and through `run-shell` is what separated the expander from the expandee | `→ 2` |
| 4 | `respell-the-proven-fix-in-the-config-file` | the fix passed as argv and then silently never fired written as a backslash-continued line in the file; only the `{}` block survived the nesting | `→ 3` |
| 5 | `carry-the-why-across-the-rewrite` | the deleted essays were measured days, so each cut left one line naming the trap and pointing at the manual section that already holds the long form | `→ 4` |
| 6 | `run-the-verify-twice` | the first run passed on an ordering artefact — Shift+F3 read as dead only because an Escape three steps earlier had not settled | `→ 5` |
