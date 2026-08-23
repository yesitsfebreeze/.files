---
state: open
priority: 33
est:
mode: afk
footprint:
  - gates/lib.sh
verify: "bash gates/selftest.sh"
origin: derived
from: 00-delivery/corrections/listing-order-lookup-regression
---

# One helper in `gates/lib.sh` closes 22 of 55 exposed positions

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: [`listing-order-lookup-regression`](../listing-order-lookup-regression/prd.md)'s
census enumerated **47 positional lookup groups** across `tests/` and
`gates/`. **25 are substring form on prose-bearing input with no effective
guard, covering 55 target positions.** One live defusal existed and that node
closed it.

The leverage is that they are not 25 different problems. **Eight of the nine
unfiled gates copy the same `line_of` body and then look up the same section
banners — `# ── MODULES ──`, `# ── PALETTE ──` — by substring.** One shared
**anchored** helper in `gates/lib.sh` closes **22 of the 55 positions at
once**, and every future gate that sources `lib.sh` inherits it.

The nine gates and what fits each, from that census:

| gate | owner | positions | fits |
|---|---|---|---|
| `capsule-lifecycle.sh:110-117`, `:667` | `01-capsule/01-container-lifecycle` | 6 | anchoring (4) + comment-stripping (2) |
| `capsule-credentials.sh:143-144` | `01-capsule/03-credential-propagation` | 2 | comment-stripping |
| `shell-television.sh:199-206`, `:214-221` | `04-shell/04-television` | 5 | anchoring |
| `shell-claude.sh:103-108` | `04-shell/08-claude-launchers` | 3 | anchoring |
| `shell-help.sh:159-165` | `06-help/02-help-command` | 2 | whole-line match |
| `shell-history.sh:185-190`, `:226-228`, `:270-275` | `04-shell/05-history` | 7 | anchoring (5) + comment-stripping (2) |
| `shell-zoxide.sh:136-140`, `:452` | `04-shell/03-zoxide` | 4 | anchoring |
| `nushell-aliases.sh:197-201` | `04-shell/02-aliases-utilities` | 2 | whole-line match |
| `gates/tree-links.sh:89` | the gate harness | 1 | count assertion |

**A rule this node must not inherit uncorrected.** That census also refuted a
generalisation it was seeded with: a count assertion beside a lookup makes it
loud **only if the count is a substring count**. Measured — `-cF` fires
(1 → 2, loud red); `-cxF` and `-cE '^…$'` **do not increment** when the quote
is `#`-prefixed or indented, which is exactly what a prose quote looks like.
So a whole-line count sitting beside a substring lookup protects nothing.

## Requirements
- [ ] **R1** — `gates/lib.sh` gains one **anchored** positional lookup helper
      (the `line_of_decl` shape from `tests/nushell-core.sh:401-410` — read
      what landed, including its "do not simplify this back" comment) and,
      where the census says anchoring cannot work, a comment-stripping
      counterpart. **Indented targets defeat anchoring outright** — that is
      measured, and it is why `shell-listing.sh`'s in-block site needed
      stripping instead.
- [ ] **R2** — The helper carries its reason in a comment: a substring lookup
      resolves a declaration quoted in an earlier comment, which silently
      defuses any comparison built on it. Cite the one live instance
      (`shell-listing.sh:108`, `core=161` against a declaration at 202) so the
      next reader sees a case, not a rule.
- [ ] **R3** — **A counterfactual in `gates/selftest.sh`'s contract**, not
      only in a report: a comment quoting a target must make the helper's
      answer move. A helper nobody has seen fail is a convention.
- [ ] **R4** — **Convert no gate here.** `gates/lib.sh` is the harness's; each
      of the nine gates belongs to a different node, and one writer per file
      holds. Report which gates would need only a helper swap once R1 lands,
      and which need the comment-stripping form — that report is what the
      per-gate nodes are specced from.
- [ ] **R5** — Recommend, without building it, whether the per-gate work is
      nine nodes or one sweep. Nine nodes is nine footprints and nine
      transitions for 33 remaining positions; a sweep is one writer touching
      nine other nodes' files, which the board's one-writer rule forbids.
      Argue it, and name the sequencing either way.

## Acceptance
- [ ] `bash gates/selftest.sh` reaches exit 0 with 0 FAIL, run **alone** — a
      concurrent write to a shared tree has produced a false FAIL there three
      times today, so re-run solo before believing one.
- [ ] R3's counterfactual quoted red, then green.
- [ ] The R4 report: nine gates, positions each, and the mitigation that fits.
- [ ] R5's recommendation with its sequencing.

## Out of scope
- Editing any of the nine gates.
- `tests/nushell-core.sh` and `tests/shell-listing.sh`, each already owned:
  [`nushell-core-positional-lookups`](../nushell-core-positional-lookups/prd.md)
  and the node that filed this one.
- The wezterm gates, which are
  [`wezterm-gate-positional-lookups`](../wezterm-gate-positional-lookups/prd.md)'s
  — and note **anchoring will not work there**, every target is indented Lua.
