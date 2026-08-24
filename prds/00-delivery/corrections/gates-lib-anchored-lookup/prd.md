---
state: done
commit: 754e9aa
claim:
priority: 33
est: 0.75h
actual: 20m
mode: afk
footprint:
  - gates/lib.sh
  - gates/selftest.sh
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

## Closed 2026-08-24 by the orchestrator

`done`, every box `[x]` — one of them amended, see below. `bash
gates/selftest.sh --selftest` → **35 PASS / 0 FAIL, rc 0**, 6m38s at load 3.31,
against a measured baseline of **23 PASS / 0 FAIL** at 6m35s. The floor rose
23 → 35 and the analyst's 6m24s figure reproduced within seconds.

**`actual: 20m` against `est: 0.75h`** — and 13 of those minutes were the two
mandatory `--selftest` runs, which is exactly how the analyst priced it.
Estimating the wall clock of the *proof* separately from the work is what made
that estimate hold.

**The trap is closed and measured.** On `capsule.nu`'s indented
`^git credential fill` at line 219: substring **219**, `line_of_decl` **0**,
the `grep -vE | grep -n` pipeline **102**, `line_of_code` **219**. 102 is not a
line of that file. And the three existing `line_of_decl` copies —
`gates/lib.sh`, `tests/nushell-core.sh:413`, `tests/shell-listing.sh:100` — all
answer **204** and are **byte-identical**, so dropping the locals later is
provably verdict-neutral.

**Two classification findings that invert the intuition:** the section banners
(`# ── MODULES ──`, 15 of the 42 declaration sites) **are comments**, so
`line_of_code` answers 0 on them and is the *wrong* helper there despite being
the more general one. And every `line_of_code` target measured is genuinely
indented, which is why anchoring cannot defuse it.

**The finding that reframes the whole positional-lookup backlog:** no gate is
red from this class today, **and none can be without a new comment being
written**. The managed tree holds exactly **two** live carriers —
`alias core-ls = ls` (comment 163 vs declaration 204) and `use std/help`
(comment 572 vs declaration 580) — and both are already defused, the first by
the local `line_of_decl` in two gates, the second by `-nxF` at
`shell-help.sh:161`. The 85 target positions behind 51 convertible sites are
**prophylactic, not repairs**.

**R4 reconciled the PRD's arithmetic instead of inheriting it**: the census
reproduces at 74 sites and 49 raw calls; the `positions` column does sum to 32,
while the `fits` column carries numbers in only 2 of 9 rows so it sums to 13 and
cannot be cross-checked — that is the arithmetic gap, not a wrong total. Eight
of nine per-gate ranges are stale, `shell-television.sh:199-206` holds **zero**
lookups today, and `shell-zoxide.sh:452` is not a lookup at all (it is
`} > "$CF_PWD"`).

**One box was amended rather than ticked**, and the reason is worth keeping:
`git diff --name-only` over the whole tree measures the board's activity, not a
node's write set — 19 files were modified by other lanes during this run — and
`gates/selftest.sh` was **untracked**, so it could never appear in a diff.
Scope a footprint box to `git diff --name-only -- <footprint paths>`.

**Two files are under version control again** because of that box:
`gates/selftest.sh` and `gates/manual/wave5.md`, committed as `a654ded`. The
orchestrator excluded both from tonight's commits while lanes held them — right
at the time — and did not come back for them, which is how the meta-gate that
holds every gate to its contract ended up outside git.

**Reported, not fixed:** `tests/shell-television.sh:249` anchors `name: $n` at
the line **end** only, so a comment ending in `name: tv_remote` still matches;
`gates/tree-links.sh:89` has no `head -1`, so a second occurrence of its phrase
makes the downstream `grep -q` malformed (unguarded rather than broken —
`grep -c` finds 0 carriers today); the `${TMPDIR}` leak is now at **33**
orphaned dirs, already queued; and `gates/lib.sh:293` trips shellcheck SC1125
on an em-dash inside a disable directive, pre-existing and cosmetic.
