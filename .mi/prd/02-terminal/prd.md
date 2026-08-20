---
state: open
mode: afk
deps: []
verify: ""
---

# Epic: Terminal (WezTerm)

Purpose: WezTerm is the daily driver; its look, startup shape, and navigation
speed set the tone for everything else. The old config mixed keepers with
features marked `DO NOT PORT` (split layout, dropdown pane, status bar, image
cycling) — this epic ports only the keepers, cleanly.

Goal: A WezTerm config that looks right on first launch, opens in the
preferred nine-tab shape, and makes tab/pane navigation a single keystroke.

## Acceptance

## Out of scope
Anything on the `DO NOT PORT` list: three-pane split layout, quake dropdown,
container-aware status bar, background image cycling, opacity toggle.

## Note on children

The `## Children` table this epic used to carry is gone on purpose. Node
membership is by existence — a child is a subdirectory holding its own
`prd.md` — so a maintained list beside it is a second copy that goes stale
silently (laws.md law 4: "membership by existence, not by a maintained
list"). `find . -name prd.md` is the index.
