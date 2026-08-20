# Epic: Nushell daily driver

## Problem

Nushell is the daily driver, and the live config (~1900 lines across 10
modules, chezmoi-managed) has grown organically. The goal is NOT to port it
wholesale: every piece gets rated in
[capabilities-nushell.md](../../docs/capabilities-nushell.md), and only the
genuinely useful ones are taken over into a minimal, well-understood base.

## Goal

A minimal nushell configuration that keeps the four things that make the
current setup fast — zoxide-everywhere navigation, the television finder,
directory-scoped history, and the recency machinery — and sheds the WIP and
cosmetic surface (leader mode, overlay, theme/opacity pickers).

## Non-goals

- Leader mode and the nu-native overlay finder (`DO NOT PORT`).
- Theme switcher and opacity picker (`DEFER` — cosmetic, revisit later).
- Porting any zsh/oh-my-zsh behavior from the old `~/.files` (that ecosystem
  lives on only inside capsule containers, see
  [01-capsule/02](../01-capsule/02-dev-image.md)).

## Children

| # | Feature | C | U | V |
|---|---------|---|---|---|
| 01 | [Core config](01-core-config.md) — env, mkcd funnel, start dir | 3 | 9 | 6 |
| 02 | [Aliases + utilities](02-aliases-utilities.md) | 2 | 8 | 6 |
| 03 | [Zoxide navigation](03-zoxide.md) — wrappers + bare-word fallback | 5 | 9 | 4 |
| 04 | [Television finder](04-television.md) — typed picker + channels | 8 | 9 | 1 |
| 05 | [Directory-scoped history](05-history.md) | 5 | 8 | 3 |
| 06 | [Decorated ls + auto-list](06-listing.md) | 5 | 8 | 3 |
| 07 | [Quicklist recents](07-quicklist.md) | 6 | 6 | 0 |
| 08 | [Claude launchers](08-claude-launchers.md) — SIMPLIFY | 7 | 6 | -1 |

## Architecture invariants

These are what make the pieces compose; every child PRD leans on them:

1. **`mkcd` is the single navigation funnel.** Real `cd`, zoxide jumps,
   picker jumps, and the bare-word fallback all flow through it — so start
   dir, the dirstack, and recents update no matter how you move.
2. **The PWD hook is the single reaction point.** Auto-list and dirstack
   push live there, not scattered per-navigation-command.
3. **tv owns every picker screen.** No hand-coded TUIs; new pickers are new
   cable channels plus a typed decode.
4. **State lives in XDG state, generated integrations in cache.** Shell
   launch does zero setup work; chezmoi's apply step generates
   starship/zoxide/tv init files.

## Success criteria

The minimal config reproduces the daily workflow — jump, find, repeat a
command, land where you left off — with materially fewer lines than the
current ~1900, and every remaining line traceable to a KEEP rating.
