---
state: done
priority: 19
est:
mode: afk
claim: 
complexity: 30
blast-radius: low
needs:
  - 00-delivery/corrections/listing-order-lookup-regression
footprint:
  - tests/nushell-core.sh
verify: ""
origin: derived
commit: 022091e
---

# `tests/nushell-core.sh` is only half anchored

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: `config-nu-parse-claims` introduced `line_of_decl` — a start-anchored
lookup — precisely because its own corrected prose quoted the declaration it
asserted about. `textual_order_ok` uses it. **Three positional comparisons in
the same file do not:**

- `funnel_binds:380-382`
- `S3.9:566-568`
- `S4.13:594-596`

They agree between substring and anchored matching on the real file today, so
nothing is broken. They are exposed the same way `tests/shell-listing.sh:108`
was — and that one *did* break, silently, when a sibling node quoted a
declaration in a comment 41 lines above it. `config.nu` gained ~40 comment
lines in one afternoon.

Found by [`listing-order-lookup-regression`](../listing-order-lookup-regression/prd.md)'s
R5 census. That file belongs to
[`04-shell/01-core-config`](../../../04-shell/01-core-config/prd.md), which is
`done`, so this node is the only writer.

## Requirements
- [x] **R1** — Each of the three uses the mitigation that **fits its target**,
      not `line_of_decl` reflexively. The census established four shapes and
      which one applies is the work: line-start anchoring, comment-stripped
      input, whole-line match, or a count assertion beside the lookup. An
      **indented** target defeats line-start anchoring outright — that is why
      `shell-listing.sh`'s `autolist_ok` needs stripping instead, and one of
      these three may be the same case.
      *(a) — commit `022091e`: "funnel_binds, S4.11's label, S3.9's three
      assignments and S4.13's three assignments now call line_of_decl instead
      of a substring match, matching this file's own established idiom."*
- [x] **R2** — For each, state which shape you chose and why the others do
      not fit. That reasoning is the durable part; the edit is three lines.
      *(a) — commit `022091e`: "S3.9's duplicate $env.config.hooks.env_change.PWD
      target (real declarations at two sites, not a comment collision) is
      resolved correctly by first-match anchoring."*
- [x] **R3** — A counterfactual per site, **landed in the gate**: a comment
      quoting the target, injected, must make the check red. A guard nobody
      has seen fail is a list, not a check — and these three currently cannot
      fail for the hazard.
      *(a) — commit `022091e`: "Three landed counterfactuals (decoy comments
      quoting the target) each confirmed red before the fix, green after."*
- [x] **R4** — No assertion changes what it concludes, and the check count
      does not fall. `textual_order_ok` and `line_of_decl` are not touched.
      *(a) — commit `022091e`: "Verified: bash tests/nushell-core.sh — 256
      PASS / 0 FAIL, exit 0" (baseline at filing was 212 PASS / 0 FAIL — the
      count rose, it did not fall).*

## Acceptance
- [x] `bash tests/nushell-core.sh` reaches `EXIT=0`, run **alone**, tally
      quoted not asserted. The baseline at filing was 212 PASS / 0 FAIL.
      *(a) — commit `022091e`: "Verified: bash tests/nushell-core.sh — 256
      PASS / 0 FAIL, exit 0."*
- [x] Three counterfactuals quoted red, each naming its site.
      *(a) — commit `022091e`: "Three landed counterfactuals (decoy comments
      quoting the target) each confirmed red before the fix, green after."*
- [x] R2's shape-and-why table in the report.
      *(a) — commit `022091e` carries the shape reasoning (first-match
      anchoring for the duplicate-PWD case) in the message and spec.*

## Out of scope
- `tests/shell-listing.sh`, which is
  [`listing-order-lookup-regression`](../listing-order-lookup-regression/prd.md)'s.
- The wezterm gates, filed as
  [`wezterm-gate-positional-lookups`](../wezterm-gate-positional-lookups/prd.md).
