---
kind: routine
name: respell-the-proven-fix-in-the-config-file
description: the fix passed as argv and then silently never fired written as a backslash-continued line in the file; only the `{}` block survived the nesting
read_when: "executing respell-the-proven-fix-in-the-config-file"
---

# respell-the-proven-fix-in-the-config-file

_Origin: `pearde/workflows/respell-the-proven-fix-in-the-config-file.md` (workflow subject: "the fix passed as argv and then silently never fired written as a backslash-continued line in the file; only the `{}` block survived the nesting")_


## Do

1. Write each candidate as it would appear in the config file, into a fragment, and `source-file` it — never as an argv list.
2. Press the key again after each `source-file`; a fragment that sources without error and then does nothing is a fail, not a pass.

## Done when

- The candidate dispatches when sourced from a file, not only when passed as argv.

## Fails when
