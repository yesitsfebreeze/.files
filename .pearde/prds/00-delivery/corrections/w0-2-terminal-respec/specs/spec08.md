verify: `bash -c 'cd "$(git rev-parse --show-toplevel)"; rc=0; r=prds/README.md; c=docs/capabilities.md; R="$(tr "\n" " " < "$r" | tr -s " ")"; echo "$R" | grep -qF "07-grid-centering" || { echo "FAIL: README tree does not list 07-grid-centering"; rc=1; }; grep -qF "## Nine-tab maximized startup windows  DO NOT PORT" "$c" || { echo "FAIL: legacy Nine-tab entry unmarked"; rc=1; }; grep -qF "## F5 one-shot jump mode  DO NOT PORT" "$c" || { echo "FAIL: legacy F5 entry unmarked"; rc=1; }; N=$(grep -c "^## " "$c"); [ "$N" = "30" ] || { echo "FAIL: entry count is $N, want 30"; rc=1; }; S="6 5 5 5 4 4 4 4 3 3 3 3 2 2 2 2 1 1 1 1 1 1 0 0 0 0 0 -1 -2 -2 "; G="$(awk "/^## /{n=0} /^- [0-9]+\$/{v[n++]=\$2} /^----/{if(n>=2) printf \"%d \", v[n-1]-v[n-2]}" "$c")"; [ "$G" = "$S" ] || { echo "FAIL: ratio sequence changed — an entry moved or was re-rated"; echo "  got:  $G"; rc=1; }; M=$(grep -cE "^## .*  (SIMPLIFY|CONSOLIDATE|DEFER|DO NOT PORT)\$" "$c"); [ "$M" = "26" ] || { echo "FAIL: $M marked headings, want 26 (24 + the two this spec adds)"; rc=1; }; U=$(grep "^## " "$c" | grep -vE "  (SIMPLIFY|CONSOLIDATE|DEFER|DO NOT PORT)\$" | sed "s/^## //" | tr "\n" "|"); W="Shell shortcuts and navigation helpers|Recent-workspace picker|Standalone dev container image|Credential propagation into containers|"; [ "$U" = "$W" ] || { echo "FAIL: take-over-as-is set is not the four entries Q4 leaves"; echo "  got:  $U"; rc=1; }; C=$(find prds/02-terminal -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d " "); T=$(echo "$R" | grep -o "02-terminal/ *Terminal" | wc -l | tr -d " "); [ "$C" = "7" ] || { echo "FAIL: 02-terminal has $C child dirs, want 7"; rc=1; }; for n in 01-appearance 02-startup-layout 03-f5-jump-mode 04-copy-mode 05-tab-content-state 06-launchd-path 07-grid-centering; do echo "$R" | grep -qF "$n" || { echo "FAIL: README tree omits $n"; rc=1; }; done; [ $rc -eq 0 ] && echo OK; exit $rc'`

est: 45m

# spec08 — the index: README in three places, and Q4's two markers

Goal: land the two edits that live outside `02-terminal/`, and make the three
places that count children agree. AGENTS.md: "When an epic's children change,
update three places together."

Files: `.mi/prds/README.md` and `.mi/docs/capabilities.md`.

**Proved RED 2026-08-21 — 7 failures**: `07-grid-centering` appears nowhere
in the README tree, both legacy `capabilities.md` entries are unmarked, that
file has 24 marked headings rather than 26 and an unmarked set of six rather
than four, and `02-terminal` has 6 child dirs rather than 7.

## Boxes

- [x] **B1 — the README tree gains `07-grid-centering`** with its `C8 U6 V-2`
      label, and the three children whose tree lines carry no rating at all
      today (`01-appearance`, `04-copy-mode`, `06-launchd-path`) gain theirs,
      matching the headers spec02/spec05/spec06 write.
- [x] **B2 — the child count reads seven** wherever the README states it, and
      `AGENTS.md`'s epic table says 6 for `02-terminal` — flag that, do not
      edit it; `AGENTS.md` is outside this task's footprint.
- [x] **B3 — Q4's two markers.** Append `  DO NOT PORT` (two spaces, matching
      the separator convention `docs-inventories` spec04 B7 normalised) to
      `## Nine-tab maximized startup windows` and `## F5 one-shot jump mode`
      in `capabilities.md`, with the reason recorded as superseded by
      `capabilities-terminal.md`. Nothing else in that file changes.
- [x] **B4 — the two guards that must stay green.** Entry count 30, and the
      ratio sequence `6 5 5 5 4 4 4 4 3 3 3 3 2 2 2 2 1 1 1 1 1 1 0 0 0 0 0
      -1 -2 -2` byte-identical. Markers are not a sort key and no C/U number
      moves. **Measured before writing this spec**, on a simulated copy of
      the post-edit file: both green, the ratio strings sha-identical.
- [x] **B5 — the README build order names T.8.** The row now exists:
      the conductor added `T.8` for `02-terminal/07-grid-centering` on
      2026-08-21, deps `W0.2, T.1`. Place it in the wave the dependency graph
      permits and keep the list a faithful summary of `plan.json` — the
      README says it is generated from that file, so the two must agree.
- [x] **B6 — the exclusion list is checked, not assumed.** burrito, the
      wallpaper pipeline, `background.png` and the opacity toggle are already
      recorded there. Confirm they still read correctly against the epic's
      rewritten Non-goals (spec01 B5) rather than duplicating them.

## The supersession this spec causes — routed, not resolved

`docs-inventories`' landed `specs/spec04.md` asserts that the take-over-as-is
set of `capabilities.md` is **exactly six** named entries, and that exactly
**24** headings carry a marker. Two of those six are the entries Q4 now marks.
Measured 2026-08-21 against a simulated post-Q4 copy, that landed verify goes
**RED on exactly two assertions** and no others:

```
FAIL: 26 headings carry a two-space-separated marker, want 24
FAIL: the take-over-as-is set is not the six entries the answer leaves unmarked.
```

Entry count (30) and the ratio sequence stayed **green**, exactly as the
orchestrator's blast-radius question anticipated — markers are not a sort key
and this spec adds no ratings.

That spec's own closing section predicted this: "If the block should be
marked entry-by-entry instead, that is a new question, and it belongs with
`w0-2-terminal-respec`." It is the same superseded-guard class the
corrections backlog already records for `decisions/fzf` and
`decisions/tinty` — a guard whose letter held when written and whose message
no longer describes the file. **Do not edit another ticket's spec.** This is
reported for the orchestrator to route.

## Out of scope

- `capabilities-terminal.md`, now **spec09's**. Its `:208-209` copy-mode
  defect is corrected in PRD prose by spec05 B3 and at source by spec09; the
  conductor widened this task's `files` to include it on 2026-08-21, so it is
  no longer an unowned defect.
- `AGENTS.md`'s epic table (B2), and `plan.json` (B5).
