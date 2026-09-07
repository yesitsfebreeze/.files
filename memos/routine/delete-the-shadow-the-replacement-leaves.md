---
kind: routine
name: delete-the-shadow-the-replacement-leaves
description: "`~/.local/bin` is ahead of the brew prefix, so the old binary would have won forever and the Brewfile entry would have been decorative"
read_when: "executing delete-the-shadow-the-replacement-leaves"
---

# delete-the-shadow-the-replacement-leaves

_Origin: `pearde/workflows/delete-the-shadow-the-replacement-leaves.md` (workflow subject: ""`~/.local/bin` is ahead of the brew prefix, so the old binary would have won forever and the Brewfile entry would have been decorative"")_


## Do

1. After installing the replacement, read the installer's own output for a
   shadow warning — Homebrew prints `<tool> (shadowed by <path>)` and it is
   easy to scroll past.
2. Confirm with `command -v <tool>` that the name still resolves to the old
   copy.
3. Delete the old copy, `hash -r`, and confirm `command -v` now answers the
   replacement.

## Done when

- `command -v <tool>` resolves to the replacement.
- No copy of the tool remains on an earlier PATH entry.

## Fails when
