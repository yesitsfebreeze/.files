# spec01 — repair the four truncated rating headers

est: 0.5h

## Goal

Four of the five PRDs in this ticket's footprint lost the tail of their
`Parent:` line in the `8ecbbe4` flat-prose → node conversion. Each now ends
mid-clause, so the inventory entry the rating came from is gone and — for the
two nodes that merge several entries — the per-source `C`/`U` numbers with
it. `AGENTS.md`'s rating rules make both mandatory:

> A PRD header's `C`/`U` must match its inventory entry […] A PRD that merges
> several entries carries the dominant entry's rating and lists every source
> with its own numbers.

Today they read (verbatim, and this is the whole line):

| file | current header tail |
|---|---|
| `01-options` | `· sources: "Options baseline",` |
| `03-autocmds` | `· source: "Editor autocmds" in` |
| `11-colorscheme` | `· source: "Colorscheme +` |
| `12-small-plugins` | `· sources: "Git signs",` |

This is the same damage class already repaired in `05-platform` and in
`03-editor/14-shift-select`, both of which now carry a complete header with a
link to the inventory — copy their shape rather than inventing one.

The pre-conversion text is recoverable and was recovered:
`git show 8ecbbe4^:.mi/prd/03-editor/<node>.md | sed -n '3,4p'`. The C/U
numbers below were then re-checked against
[`capabilities-nvim.md`(../../../../../../../docs/capabilities-nvim.md) on
2026-08-21, entry by entry, rather than trusted from the old text.

## Files touched

- `.mi/prds/03-editor/01-options/prd.md` — the `Parent:` line only.
- `.mi/prds/03-editor/03-autocmds/prd.md` — the `Parent:` line only.
- `.mi/prds/03-editor/11-colorscheme/prd.md` — the `Parent:` line only.
- `.mi/prds/03-editor/12-small-plugins/prd.md` — the `Parent:` line only.

**Do not edit the frontmatter of any of them.** **Do not touch
`11-colorscheme`'s R6, R7 or its `## Decisions` section** — those landed
today from `00-delivery/decisions/tinty` and this spec goes nowhere near
them.

Not touched, and deliberately: `.mi/docs/capabilities-nvim.md` is
`w0-4-s2-corrections/docs-inventories` (W0.4a)'s file and is running
concurrently. This spec **reads** it and edits nothing there.

## What to write

Replace each `Parent:` line, keeping the epic's C/U numbers exactly as they
are (they are already correct against the inventory — only the source clause
was lost). Wrap at ~78 columns.

`01-options` — three sources, so every one gets its own numbers:

> Parent: [Neovim epic](../prd.md) · C 2 · U 9 · sources: "Options baseline"
> (C 2 / U 9 — dominant), "Whitespace rendering (VS Code parity)"
> (C 2 / U 7), "LSP log kill-switch" (C 1 / U 7) in
> [`capabilities-nvim.md`(../../../../../../../docs/capabilities-nvim.md)

`03-autocmds` — one source:

> Parent: [Neovim epic](../prd.md) · C 3 · U 8 · source: "Editor autocmds" in
> [`capabilities-nvim.md`(../../../../../../../docs/capabilities-nvim.md)

`11-colorscheme` — one source, whose name contains the `+` that the
truncation cut at:

> Parent: [Neovim epic](../prd.md) · C 5 · U 8 · source: "Colorscheme +
> mode-aware cursor" in
> [`capabilities-nvim.md`(../../../../../../../docs/capabilities-nvim.md)

`12-small-plugins` — three sources:

> Parent: [Neovim epic](../prd.md) · C 2 · U 7 · sources: "Git signs"
> (C 2 / U 7 — dominant), "which-key" (C 2 / U 7), "Autopairs" (C 1 / U 6) in
> [`capabilities-nvim.md`(../../../../../../../docs/capabilities-nvim.md)

Two notes for whoever applies this:

1. **The header numbers do not change.** Every one of the four already
   matches its dominant inventory entry (checked: Options baseline 2/9,
   Editor autocmds 3/8, Colorscheme + mode-aware cursor 5/8, Git signs 2/7).
   This spec restores provenance; it re-rates nothing. If you find yourself
   changing a `C` or a `U`, stop — that is a different correction and it
   belongs in the backlog.
2. **"Git signs" and "which-key" are both C 2 / U 7.** "Git signs" is marked
   dominant because it is the entry the node is named and ordered from, not
   because it out-ranks the other. Keep the marker on it so the header
   states one dominant entry rather than leaving a tie unresolved.

## Acceptance

- [ ] All four `Parent:` lines name `capabilities-nvim.md` and link to it.
- [ ] `01-options` names all three of its sources, each with its own C and U.
- [ ] `12-small-plugins` names all three of its sources, each with its own C
      and U.
- [ ] Exactly one source per merged header carries the `dominant` marker.
- [ ] `03-autocmds` and `11-colorscheme` each name their single source in
      full — `11-colorscheme`'s includes the words after the `+`.
- [ ] No `C` or `U` number in any of the four headers changed value.
- [ ] `11-colorscheme` still carries R6, R7 and its `## Decisions` section,
      byte for byte.
- [ ] Every requirement/acceptance box in the four files is still open — no
      `[x]`, no `[~]`. Restoring a header does not implement anything.
- [ ] No line inside any of the four `---` frontmatter fences changed.

verify: ""

**Proven RED against the current tree before this spec was written**, run
verbatim as the string above. It reports, in order: all four headers missing
`capabilities-nvim.md`; `01-options` omitting "Whitespace rendering" and "LSP
log kill-switch" and carrying zero of three per-source pairs;
`12-small-plugins` omitting "which-key" and "Autopairs" and carrying zero of
three; neither merged header marking a dominant source; and `11-colorscheme`
still cut at the `+`. Exit 1.

The clauses that already pass — the `C n · U n` presence check, the
`11-colorscheme` R7/`## Decisions` guards, the all-boxes-open check — are
regression guards, and the two `11-colorscheme` ones exist specifically
because today's `decisions/tinty` edit is the thing this spec must not
disturb.

The header is read as a whitespace-normalised paragraph
(`sed -n '/^Parent:/,/^$/p' | tr '\n' ' ' | tr -s ' '`) rather than as a
line, because the repaired headers wrap across three or four lines at 78
columns and every phrase worth asserting straddles a break. A line-wise grep
would false-negative on all of them.

## Spent proof

The editor lanes closed boxes in `prds/03-editor/01-options`, `03-autocmds`
and `11-colorscheme` after this node closed; the guard protects those files
against churn during this node's own run, not against their later
implementation, and every assertion on the `Parent:` headers this node
repaired still passes.

Retired from `verify:` by
[`mi-rooted-verify-commands`](../../../mi-rooted-verify-commands/prd.md)
spec02. The command below is byte-identical to what spec01 left in this
file's `verify:`; it is kept because it is the execution record of a check
that once ran green.

```text
verify: `bash -c 'cd "$(git rev-parse --show-toplevel)"; rc=0; hdr() { sed -n "/^Parent:/,/^$/p" "prds/03-editor/$1/prd.md" | tr "\n" " " | tr -s " "; }; for n in 01-options 03-autocmds 11-colorscheme 12-small-plugins; do h=$(hdr "$n"); printf "%s" "$h" | grep -qF "capabilities-nvim.md" || { echo "FAIL: $n header does not name capabilities-nvim.md"; rc=1; }; printf "%s" "$h" | grep -qE "C [0-9]+ . U [0-9]+" || { echo "FAIL: $n header lost its C/U"; rc=1; }; done; o=$(hdr 01-options); for s in "Options baseline" "Whitespace rendering" "LSP log kill-switch"; do printf "%s" "$o" | grep -qF "$s" || { echo "FAIL: 01-options header omits source: $s"; rc=1; }; done; [ "$(printf "%s" "$o" | grep -oE "C [0-9]+ / U [0-9]+" | wc -l | tr -d " ")" -eq 3 ] || { echo "FAIL: 01-options does not carry three per-source C/U pairs"; rc=1; }; p=$(hdr 12-small-plugins); for s in "Git signs" "which-key" "Autopairs"; do printf "%s" "$p" | grep -qF "$s" || { echo "FAIL: 12-small-plugins header omits source: $s"; rc=1; }; done; [ "$(printf "%s" "$p" | grep -oE "C [0-9]+ / U [0-9]+" | wc -l | tr -d " ")" -eq 3 ] || { echo "FAIL: 12-small-plugins does not carry three per-source C/U pairs"; rc=1; }; for n in 01-options 12-small-plugins; do [ "$(hdr "$n" | grep -oc "dominant")" -eq 1 ] || { echo "FAIL: $n does not mark exactly one dominant source"; rc=1; }; done; printf "%s" "$(hdr 11-colorscheme)" | grep -qF "mode-aware cursor" || { echo "FAIL: 11-colorscheme header still cut at the +"; rc=1; }; printf "%s" "$(hdr 03-autocmds)" | grep -qF "Editor autocmds" || { echo "FAIL: 03-autocmds header lost its source name"; rc=1; }; c=prds/03-editor/11-colorscheme/prd.md; grep -q "^## Decisions" "$c" || { echo "FAIL: 11-colorscheme lost its Decisions section"; rc=1; }; grep -q "R7\*\* — \*\*Where the inheritance stops" "$c" || { echo "FAIL: 11-colorscheme lost R7"; rc=1; }; for n in 01-options 03-autocmds 11-colorscheme 12-small-plugins; do grep -qE "^- \[[x~]\]" "prds/03-editor/$n/prd.md" && { echo "FAIL: a box was closed in $n"; rc=1; }; done; [ $rc -eq 0 ] && echo OK; exit $rc'`
```
