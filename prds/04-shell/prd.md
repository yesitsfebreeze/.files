---
state: open
claim: 
priority: 0
est: 0h
kind: epic
mode: afk
needs:
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
cosmetic surface (leader mode, overlay, the opacity picker).

## Requirements

**Architecture invariants**


These are what make the pieces compose; every child PRD leans on them:

- [ ] **I1** — **`mkcd` is the single navigation funnel.** Real `cd`, zoxide
      jumps, picker jumps, and the bare-word fallback all flow through it — so
      start dir, the dirstack, and recents update no matter how you move.
- [ ] **I2** — **The PWD hook is the single reaction point.** Auto-list and
      dirstack push live there, not scattered per-navigation-command.
- [ ] **I3** — **tv owns every picker screen, with exactly one named
      exception.** No hand-coded TUIs; new pickers are new cable channels
      plus a typed decode. The exception is **fzf**, reached only through
      `zoxide query --interactive` behind `zi`/`cdi`
      ([03-zoxide](03-zoxide/prd.md) R2). Zoxide ships its own interactive
      mode, and replacing it with a tv channel would mean reimplementing its
      frecency ranking and its `--exclude $PWD` semantics to own one picker
      screen — so fzf stays in the required package set
      ([P.2](../05-platform/02-package-provisioning/packages-installer/prd.md)
      R7) as `zi`'s dependency, never as a picker anything else may reach
      for. It is an exception and **not a precedent**: a second picker
      outside tv is a new decision, not an appeal to this one, and `help`
      documents it so the manual does not teach a rule the environment
      breaks. Decided 2026-08-21 (user), recorded in
      [decisions/fzf](../00-delivery/decisions/fzf/prd.md).
- [ ] **I4** — **State lives in XDG state, generated integrations in cache.**
      Shell launch does zero setup work; chezmoi's apply step generates
      starship/zoxide/tv init files.
- [ ] **I5** — **The palette comes from tinty, and no child hardcodes one.**
      `tinty apply` is the source of truth: it writes both the WezTerm palette
      and the tinted-shell artifact this epic re-asserts at shell start
      (`01-core-config` R10), and television inherits it by running the
      `default` ANSI theme (`04-television` R6) rather than a hex theme.
      Decided 2026-08-21 — see
      [`decisions/tinty`](../00-delivery/decisions/tinty/prd.md).

## Acceptance

## Out of scope
- Leader mode and the nu-native overlay finder (`DO NOT PORT`).
- The opacity picker (`DEFER` — cosmetic). Its fate is no longer open: the
  [`wallpaper-opacity`](../00-delivery/decisions/wallpaper-opacity/prd.md)
  decision of **2026-08-21** dropped both the wallpaper pipeline and the
  opacity toggle, left the picker on its `DEFER` (deferred is not refused),
  and moved `Ctrl+Shift+B` to capsule. Also out: the theme switcher's
  background-override ladder and R/G/B tuner, which the 2026-08-21
  `SIMPLIFY` drops. The theme
  switcher itself is **not** out of scope any more: tinty owns the palette
  (I5): `theme.nu` (the A/B slots, `_theme_toggle`, the tv scheme picker) is
  [`09-theme-switcher`](09-theme-switcher/prd.md)'s, created 2026-08-21 when
  this decision landed, and the F6 binding that calls it is
  `w0-2-terminal-respec` R5's to place.
- Porting any zsh/oh-my-zsh behavior from the old `~/.files` (that ecosystem
  lives on only inside capsule containers, see
  [01-capsule/02](../01-capsule/02-dev-image/prd.md)).

## Note on children

The `## Children` table this epic used to carry is gone on purpose. Node
membership is by existence — a child is a subdirectory holding its own
`prd.md` — so a maintained list beside it is a second copy that goes stale
silently (laws.md law 4: "membership by existence, not by a maintained
list"). `find . -name prd.md` is the index.
