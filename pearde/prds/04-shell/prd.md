---
state: done
claim: 
priority: 0
est: 0h
kind: epic
mode: afk
needs:
verify: "sh -c 'n=$(grep -L \"^state: done\" prds/04-shell/*/prd.md | wc -l | tr -d \" \"); echo \"children not done: $n\"; test \"$n\" -eq 0'"
---

# Epic: Nushell daily driver

Purpose: Nushell is the daily driver, and the live config (~1900 lines across
10 modules, chezmoi-managed) has grown organically. The goal is NOT to port it
wholesale: every piece gets rated in
[capabilities-nushell.md(../../../docs/capabilities-nushell.md), and only the
genuinely useful ones are taken over into a minimal, well-understood base.

Goal: A minimal nushell configuration that keeps the four things that make the
current setup fast — zoxide-everywhere navigation, the television finder,
directory-scoped history, and the recency machinery — and sheds the WIP and
cosmetic surface (leader mode, overlay, the opacity picker).

## Requirements

**Architecture invariants**


These are what make the pieces compose; every child PRD leans on them:

**I1** — **`mkcd` is the single navigation funnel.** Real `cd`, zoxide
jumps, picker jumps, and the bare-word fallback all flow through it — so
start dir, the dirstack, and recents update no matter how you move.

**I2** — **The PWD hook is the single reaction point.** Auto-list and
dirstack push live there, not scattered per-navigation-command.

**I3** — **tv owns every picker screen, with exactly two named
exceptions.** No hand-coded TUIs; new pickers are new cable channels
plus a typed decode. Both exceptions are **fzf**. The first is reached
only through `zoxide query --interactive` behind `zi`/`cdi`
([03-zoxide](03-zoxide/prd.md) R2). The second is `cll`'s model picker
([10-litellm-launcher](10-litellm-launcher/prd.md) R2), decided
2026-08-25 and recorded in
[`decisions/fzf-model-picker`](../00-delivery/decisions/fzf-model-picker/prd.md)
— a catalogue of ~80 models across six providers needs group headers, a
per-row provider column and dim secondary text in one screen, and fzf's
`--ansi`/`--with-nth`/`--nth` do that where `input list` has no ANSI. Zoxide ships its own interactive
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

**I4** — **State lives in XDG state, generated integrations in cache.**
Shell launch does zero setup work; chezmoi's apply step generates
starship/zoxide/tv init files.

**I5** — **The palette comes from tinty, and no child hardcodes one.**
`tinty apply` is the source of truth: it writes both the WezTerm palette
and the tinted-shell artifact this epic re-asserts at shell start
(`01-core-config` R10), and television inherits it by running the
`default` ANSI theme (`04-television` R6) rather than a hex theme.
Decided 2026-08-21 — see
[`decisions/tinty`](../00-delivery/decisions/tinty/prd.md).

## Acceptance
- [x] Every child of this epic is `state: done`. This is the epic's own
      proof and it is the only claim an epic can make on its own behalf —
      the substance is proved by each child's `verify:`, run at that child's
      own transition.

      `verify:` above, run 2026-08-28 → `children not done: 0`, `EXIT=0`.
      **Proved by its own red**, per `G.1`: flipping `10-litellm-launcher`
      to `state: open` gives `children not done: 1`, `EXIT=1`; restoring it
      returns `EXIT=0`. All 10 children counted.

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

## Closed 2026-08-28 — what `done` rests on, and the correction that got it there

Transitioned by the orchestrator under
[`epic-invariants-prose`](../00-delivery/finish-line/epic-invariants-prose/prd.md)
R4.

**This epic was first closed with an empty `## Acceptance` and `verify: ""`,
and that was an overclaim.** A skeptic put the case plainly: the board's own
contract says `done` requires the verify commands actually run with output,
`verify: ""` means there is no command, and "all acceptance boxes closed" over
an empty set is vacuously true — so the epic closed because it was never
specified, not because it was finished. The tell was that the epics holding
real acceptance boxes were held to them, and the two that closed were exactly
the two with nothing to bite.

The fix is the acceptance box above, not an argument: one claim an epic can
honestly make, a command that produces output, and a demonstrated red. `done`
here now means what the contract says it means.

What it still does **not** mean: that this file was checked against the live
config. The substance lives in the children, each proved at its own
transition, and that is the correct place for it —
[`done-node-proof-gate`](../00-delivery/corrections/done-node-proof-gate/prd.md)
is the node that will assert every `done` node's `verify:` actually exits 0,
and this epic now passes that test rather than adding to its list.
