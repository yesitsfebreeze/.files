---
state: open
mode: afk
deps: []
verify: ""
---

# Epic: Nushell daily driver

Purpose: Nushell is the daily driver, and the live config (~1900 lines across
10 modules, chezmoi-managed) has grown organically. The goal is NOT to port it
wholesale: every piece gets rated in
[capabilities-nushell.md](../../docs/capabilities-nushell.md), and only the
genuinely useful ones are taken over into a minimal, well-understood base.

Goal: A minimal nushell configuration that keeps the four things that make the
current setup fast — zoxide-everywhere navigation, the television finder,
directory-scoped history, and the recency machinery — and sheds the WIP and
cosmetic surface (leader mode, overlay, theme/opacity pickers).

## Requirements

**Architecture invariants**


These are what make the pieces compose; every child PRD leans on them:

- [ ] **I1** — **`mkcd` is the single navigation funnel.** Real `cd`, zoxide
      jumps, picker jumps, and the bare-word fallback all flow through it — so
      start dir, the dirstack, and recents update no matter how you move.
- [ ] **I2** — **The PWD hook is the single reaction point.** Auto-list and
      dirstack push live there, not scattered per-navigation-command.
- [ ] **I3** — **tv owns every picker screen.** No hand-coded TUIs; new
      pickers are new cable channels plus a typed decode.
- [ ] **I4** — **State lives in XDG state, generated integrations in cache.**
      Shell launch does zero setup work; chezmoi's apply step generates
      starship/zoxide/tv init files.

## Acceptance

## Out of scope
- Leader mode and the nu-native overlay finder (`DO NOT PORT`).
- Theme switcher and opacity picker (`DEFER` — cosmetic, revisit later).
- Porting any zsh/oh-my-zsh behavior from the old `~/.files` (that ecosystem
  lives on only inside capsule containers, see
  [01-capsule/02](../01-capsule/02-dev-image/prd.md)).

## Note on children

The `## Children` table this epic used to carry is gone on purpose. Node
membership is by existence — a child is a subdirectory holding its own
`prd.md` — so a maintained list beside it is a second copy that goes stale
silently (laws.md law 4: "membership by existence, not by a maintained
list"). `find . -name prd.md` is the index.
