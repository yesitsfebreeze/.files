---
state: open
priority: 19
est:
mode: afk
needs:
  - 00-delivery/corrections/listing-order-lookup-regression
footprint:
  - tests/nushell-core.sh
verify: "bash tests/nushell-core.sh"
origin: derived
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
- [ ] **R1** — Each of the three uses the mitigation that **fits its target**,
      not `line_of_decl` reflexively. The census established four shapes and
      which one applies is the work: line-start anchoring, comment-stripped
      input, whole-line match, or a count assertion beside the lookup. An
      **indented** target defeats line-start anchoring outright — that is why
      `shell-listing.sh`'s `autolist_ok` needs stripping instead, and one of
      these three may be the same case.
- [ ] **R2** — For each, state which shape you chose and why the others do
      not fit. That reasoning is the durable part; the edit is three lines.
- [ ] **R3** — A counterfactual per site, **landed in the gate**: a comment
      quoting the target, injected, must make the check red. A guard nobody
      has seen fail is a list, not a check — and these three currently cannot
      fail for the hazard.
- [ ] **R4** — No assertion changes what it concludes, and the check count
      does not fall. `textual_order_ok` and `line_of_decl` are not touched.

## Acceptance
- [ ] `bash tests/nushell-core.sh` reaches `EXIT=0`, run **alone**, tally
      quoted not asserted. The baseline at filing was 212 PASS / 0 FAIL.
- [ ] Three counterfactuals quoted red, each naming its site.
- [ ] R2's shape-and-why table in the report.

## Out of scope
- `tests/shell-listing.sh`, which is
  [`listing-order-lookup-regression`](../listing-order-lookup-regression/prd.md)'s.
- The wezterm gates, filed as
  [`wezterm-gate-positional-lookups`](../wezterm-gate-positional-lookups/prd.md).
