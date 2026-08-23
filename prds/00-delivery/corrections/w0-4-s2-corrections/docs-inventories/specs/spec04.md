verify: ""

est: 25m

# spec04 — `capabilities.md`: the confirmed typo, legend and marker corrections

Goal: land R2 in full and R4's remaining half, now that the author has
confirmed them. This is the file R1 gated; the `## Answers` section of the
node's `prd.md` (2026-08-21) is that confirmation, so R1's box closes with
this spec rather than blocking it.

Files: `.mi/docs/capabilities.md` — and nothing else.

**The verify was proven RED on 2026-08-21** against the current file: 20
failures covering both typos, the dangling `02-terminal/02` citation, the six
head-legend assertions, all seven missing markers, the parenthesised
`CONSOLIDATE`, the marker-separator count and the take-over-as-is set.

**The two guards that already pass are the point of the spec.** Entry count
(30) and the exact ratio sequence
`6 5 5 5 4 4 4 4 3 3 3 3 2 2 2 2 1 1 1 1 1 1 0 0 0 0 0 -1 -2 -2` are green
now and must be green after. Together they assert what the answer promised:
**no entry moves and no C/U number changes.** Markers are not a sort key. A
later pass that "tidies" this file by re-sorting or re-rating it turns that
sequence red, which is exactly what the orchestrator asked be made
unfalsifiable.

## Boxes

- [ ] **B1 — `DO NOT PORST` → `DO NOT PORT`.** Line 154,
      `## OpenCode theme generation from terminal colors`. As written it
      matches no marker in the vocabulary, so anything reading verdicts sees
      the entry as unmarked — the opposite of the intent.
- [ ] **B2 — `maximiz:ed` → `maximized`.** Line 49. This is the load-bearing
      one: `02-terminal/02-startup-layout`'s header cites
      `source: "Nine-tab maximized` and that string currently matches no
      heading in the file. The verify re-reads that PRD's citation and greps
      it back as a heading here, so B2 is checked against the real consumer
      rather than against a literal this spec invented. (That `Parent:` line
      is also truncated mid-quote by commit `8ecbbe4`; repairing the
      truncation is `02-terminal`'s, not ours. The assertion is written to
      pass either way — it matches the cited prefix, not a closing quote.)
- [ ] **B3 — the head legend replaces the `|` note.** Lines 3–5 currently
      read "NOTE: everything that has | in the ## line. descibes what to do
      with it." No `##` line contains a `|`. Replace those three lines with
      the legend the author approved, keeping both of their examples:

      > Markers on the `##` line say what to do with a capability: nothing =
      > take over as-is, `SIMPLIFY` = take over a reduced version,
      > `CONSOLIDATE` = merge with overlapping capabilities into one tool,
      > `DEFER` = not part of the minimal base, `DO NOT PORT` = drop
      > entirely. For example the docker dev mount is `CONSOLIDATE` — it
      > should work flawlessly, as one tool — and nothing marked
      > `DO NOT PORT` is created or ported at all.

      Leave lines 7–12 (what the repo does, the rating scale, the sort rule)
      exactly as they are.
- [ ] **B4 — the head also points at `capabilities-terminal.md`.** Add one
      line to the head saying that the WezTerm entries below describe the
      **legacy** `~/.files` config, that the live one is rated in
      [`capabilities-terminal.md`](capabilities-terminal.md), and that
      `02-terminal` is specced from that file. This is the same treatment
      `capabilities-nvim.md`'s IMPORTANT note already gives the Neovim
      entries, and it is what makes B5's `DO NOT PORT` on a capability that
      *is* being ported read correctly: the capability survives, this
      description of it does not.
- [ ] **B5 — the seven confirmed markers are added.** Two `CONSOLIDATE`, five
      `DO NOT PORT`, no other change to any heading:

      | Line | Heading | Marker | Why |
      |---|---|---|---|
      | 19 | WezTerm terminal configuration | `DO NOT PORT` | Legacy config; superseded by `capabilities-terminal.md` (audit T-1…T-10) |
      | 44 | `` `mount` — drop the current dir into a container `` | `CONSOLIDATE` | `01-capsule/01` is titled "consolidates capsule + `mount` + justfile" |
      | 59 | Neovim: self-bootstrapping config | `DO NOT PORT` | mini.nvim; README's Neovim exclusion (**this is R4's other half**) |
      | 69 | Just task runner | `CONSOLIDATE` | Same `01-capsule/01` title; a merge, not a drop |
      | 79 | Cross-platform dependency bootstrap | `DO NOT PORT` | `capabilities-provisioning.md`'s head: "superseded… should not be ported" |
      | 89 | Neovim: shared theme + desktop-style keys | `DO NOT PORT` | mini.nvim-era theme bridge; `capabilities-nvim.md` head, "entries" plural |
      | 144 | Cross-platform Lua/shell/PowerShell parity | `DO NOT PORT` | Already in the README's exclusion list, Windows out of scope |

- [ ] **B6 — `(CONSOLIDATE)` stops being parenthesised.** Line 124,
      `## "Capsule" — … from the terminal (CONSOLIDATE)` →
      `…from the terminal  CONSOLIDATE`. In scope as a consequence of B3: the
      legend being installed defines markers as bare words appended to the
      heading, and this is the one heading that contradicts it. Safe —
      `01-capsule/01` cites the entry as `"Capsule"`, not by full heading.
- [ ] **B7 — every marker is separated by exactly two spaces.** Today 16 of
      the 17 existing markers use one space and only `## Zsh environment
      (oh-my-zsh)  DO NOT PORT` uses two. Normalise all of them, so all 24
      marked headings match `^## .*␣␣MARKER$` and the file can be parsed
      mechanically — which is what B3's legend now promises a reader.
      **This box goes beyond R2's letter**: R2 asked for three missing
      markers, not a separator sweep. It is zero-semantic-change and matches
      all four sibling inventories, but it is flagged so a reviewer can drop
      it knowingly rather than discover it in a diff.
- [ ] **B8 — the take-over-as-is set is exactly six entries.** After B5,
      precisely these carry no marker, and the verify pins the list so a
      later marker cannot be added or dropped silently: Shell shortcuts and
      navigation helpers · Nine-tab maximized startup windows · F5 one-shot
      jump mode · Recent-workspace picker · Standalone dev container image ·
      Credential propagation into containers.
- [ ] **B9 — nothing moves and nothing is re-rated.** 30 entries before, 30
      after; the ratio sequence byte-identical. Do not re-sort the file — it
      is the one inventory already correctly sorted, and it stays that way
      because markers do not affect the ratio.

## A tension this spec deliberately does not resolve

B5 marks `WezTerm terminal configuration` `DO NOT PORT` because it describes
a config that is not live — but `Nine-tab maximized startup windows` (line 49)
and `F5 one-shot jump mode` (line 74) are legacy WezTerm entries too, and the
audit found both wrong in the same way (T-5, T-7, T-8). They stay **unmarked**
here: the author confirmed three specific entries, not the whole legacy
WezTerm block, and marking two more would be an agent resolving a scope
question on its own. B4's head note is what covers them — it tells a reader
that every WezTerm entry in this file is the legacy one and points at the
inventory that supersedes them. If the block should be marked entry-by-entry
instead, that is a new question, and it belongs with `w0-2-terminal-respec`,
which is re-speccing `02-terminal` from `capabilities-terminal.md` anyway.

## Out of scope

- `.mi/prds/README.md`'s exclusion list, which does not yet name
  `Cross-platform dependency bootstrap` — **W0.4g's** file. Named and routed,
  not written here.
- `capabilities-terminal.md` — absent from W0.4a's `files` list in
  `plan.json`.
- `02-terminal/02-startup-layout`'s truncated `Parent:` line.
- Re-sorting or re-rating anything (B9).

## Spent proof

`docs/capabilities.md:58` and `:83` now carry `DO NOT PORT` markers on
"Nine-tab maximized startup windows" and "F5 one-shot jump mode", added
after this node closed, so the unmarked take-over-as-is set this pinned at
six entries is four today.

Retired from `verify:` by
[`mi-rooted-verify-commands`](../../../mi-rooted-verify-commands/prd.md)
spec02. The command below is byte-identical to what spec01 left in this
file's `verify:`; it is kept because it is the execution record of a check
that once ran green.

```text
verify: `bash -c 'cd "$(git rev-parse --show-toplevel)"; f=docs/capabilities.md; rc=0; RAT() { awk "/^## /{n=0} /^- [0-9]+\$/{v[n++]=\$2} /^----/{if(n>=2) printf \"%d \", v[n-1]-v[n-2]}" "$f"; }; N=$(grep -c "^## " "$f"); [ "$N" = "30" ] || { echo "FAIL: entry count is $N, want 30 — a marker edit must not add or drop an entry"; rc=1; }; S="6 5 5 5 4 4 4 4 3 3 3 3 2 2 2 2 1 1 1 1 1 1 0 0 0 0 0 -1 -2 -2 "; G="$(RAT)"; [ "$G" = "$S" ] || { echo "FAIL: the ratio sequence changed — an entry moved or was re-rated."; echo "  got:  $G"; echo "  want: $S"; rc=1; }; grep -q "PORST" "$f" && { echo "FAIL: the DO NOT PORST typo survives"; rc=1; }; grep -q "maximiz:ed" "$f" && { echo "FAIL: the maximiz:ed typo survives"; rc=1; }; grep -q "^## Nine-tab maximized startup windows" "$f" || { echo "FAIL: no heading reads Nine-tab maximized startup windows"; rc=1; }; C=$(sed -n "s/^Parent:.*source: \"\(.*\)\$/\1/p" prds/02-terminal/02-startup-layout/prd.md); if [ -n "$C" ]; then grep -qF "## $C" "$f" || { echo "FAIL: 02-terminal/02-startup-layout cites a source no heading matches: [$C]"; rc=1; }; fi; H=$(awk "/^## /{exit} {print}" "$f" | tr "\n" " " | tr -s " "); echo "$H" | grep -qF "has | in the ## line" && { echo "FAIL: the head still describes verdicts as containing a pipe"; rc=1; }; for s in "SIMPLIFY" "CONSOLIDATE" "DEFER" "DO NOT PORT" "take over" "capabilities-terminal.md"; do echo "$H" | grep -qF "$s" || { echo "FAIL: the new head legend lacks: $s"; rc=1; }; done; NEW="## WezTerm terminal configuration  DO NOT PORT|drop the current dir into a container  CONSOLIDATE|## Neovim: self-bootstrapping config  DO NOT PORT|## Just task runner  CONSOLIDATE|## Cross-platform dependency bootstrap  DO NOT PORT|## Neovim: shared theme + desktop-style keys  DO NOT PORT|## Cross-platform Lua/shell/PowerShell parity  DO NOT PORT"; OIFS=$IFS; IFS="|"; for h in $NEW; do IFS=$OIFS; grep -qF "$h" "$f" || { echo "FAIL: marker not added: $h"; rc=1; }; IFS="|"; done; IFS=$OIFS; grep -q "^##.*(CONSOLIDATE)" "$f" && { echo "FAIL: a marker is still parenthesised, which the new legend does not allow"; rc=1; }; M=$(grep -cE "^## .*  (SIMPLIFY|CONSOLIDATE|DEFER|DO NOT PORT)\$" "$f"); [ "$M" = "26" ] || { echo "FAIL: $M headings carry a two-space-separated marker, want 26 — markers are not uniformly separated"; rc=1; }; U=$(grep "^## " "$f" | grep -vE "  (SIMPLIFY|CONSOLIDATE|DEFER|DO NOT PORT)\$" | sed "s/^## //" | tr "\n" "|"); W="Shell shortcuts and navigation helpers|Nine-tab maximized startup windows|F5 one-shot jump mode|Recent-workspace picker|Standalone dev container image|Credential propagation into containers|"; [ "$U" = "$W" ] || { echo "FAIL: the take-over-as-is set is not the six entries the answer leaves unmarked."; echo "  got:  $U"; echo "  want: $W"; rc=1; }; [ $rc -eq 0 ] && echo OK; exit $rc'`
```
