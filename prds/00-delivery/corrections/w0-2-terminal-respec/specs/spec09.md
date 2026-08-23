verify: ""

est: 30m

# spec09 — correct the copy-mode defect at its source

Goal: fix `capabilities-terminal.md:208-209` in the inventory itself, not only
in the PRD derived from it. spec05 B3 writes the right thing into
`04-copy-mode`; this writes it into the file the next re-spec will read.

Files: `.mi/docs/capabilities-terminal.md` — and nothing else.

**Why this is not optional tidying.** The line claims copy mode keeps
"searches". It does not. Leaving it means the next agent to spec from this
inventory promises a key that is not there — which is, exactly and
precisely, how `02-terminal` became invalid in the first place. Fixing the
derived document and leaving the source would rebuild the trap this whole
task exists to dismantle.

**Proved RED 2026-08-21 — 5 failures**, all in the copy-mode entry: the
`motions and searches` claim and the `all 55 builtin` count are both still
present, and `54 builtin`, `search_mode` and `Ctrl+Shift+F` are all absent.
**Seven assertions are already green and are the point of the spec** — entry
count 30, line count 550, the ratio sequence, the entry's `4 / 9` rating,
`## Appearance baseline` at line 220, and the `Live bug L-11` string. This is
an inventory, the rating rules bind it, and the correction is prose only.

## What was measured

Against `wezterm show-keys --lua` on `20240203-110809-5046fc22`, the effective
key set (263 rows):

- `key_tables.copy_mode` has **55 rows in total**, one of which is this
  config's own `c` (`act.EmitEvent "user-defined-0"`). So **54 are builtin**,
  not 55. The inventory's count silently includes the config's own addition
  in the number it calls "builtin".
- `copy_mode` contains **no search facility at all**: no `/`, and no
  `NextMatch`, `PriorMatch`, `ClearPattern` or `CycleMatchType`.
- All of those live in a **separate 10-row `search_mode` table**, reached
  from normal mode by WezTerm's default `Ctrl+Shift+F` / `Cmd+F` — bindings
  this config neither sets nor shadows.

## Boxes

- [x] **B1 — the count is 54 builtin motions.** Replace "all 55 builtin
      motions and searches survive". Keeping the total is useful, so say both
      if it fits: 54 builtins, and 55 rows once the config's own `c` is
      counted. The word "searches" comes out either way.
- [x] **B2 — record the absence, not just the corrected count.** A reader
      must learn that copy mode has no search, or the next spec re-derives
      the same wrong promise from silence. Name the four match actions that
      are *not* there, because "no search" alone reads as "no `/` key" and
      the match-navigation keys are the ones a vim user would reach for next.
- [x] **B3 — say where search actually lives.** The separate 10-row
      `search_mode` table, reached from normal mode via the default
      `Ctrl+Shift+F` / `Cmd+F`. Without this the correction is a bare
      negative and `06-help` has nowhere to send a user looking for search.
- [x] **B4 — line-count neutral.** The file must stay **550 lines**. Four
      documents cite line numbers *after* the edit point — `:220-229`,
      `:220-231`, `:259-275` and `:351` — and no verify pins them, so a shift
      would rot silently rather than fail loudly. That is the worse failure
      mode, and it is free to avoid: the entry's body is 11 lines and the
      correction fits in 11. The verify checks both the total and that line
      220 is still `## Appearance baseline`.
- [x] **B5 — nothing else moves.** The rating stays `4` / `9`, the entry
      keeps its position, the entry count stays 30 and the ratio sequence
      stays byte-identical. Markers and prose are not a sort key. Do **not**
      touch the F5 entry, which is where `Live bug L-11` lives and which
      `tests/live-bugs.sh:211` asserts on.
- [x] **B6 — the `Verified in wezterm show-keys --lua` provenance survives.**
      It is what makes the entry trustworthy, and it is what the corrected
      numbers were measured with. Extend it rather than dropping it.

## Blast radius — measured, not assumed

Checked the same way as the Q4 supersession, on a simulated line-neutral copy:

- **`gates/audit-findings.sh`** — **0** references to
  `capabilities-terminal.md`. Unaffected.
- **`tests/live-bugs.sh`** — exactly **one** reference, line 211:
  `grep -q 'Live bug L-11' "$DOCS/capabilities-terminal.md"`. That string is
  at line **406**, inside the F5 entry, which B5 forbids touching. Green on
  the simulated file.
- **No verify anywhere pins a line number into this file.** The only two
  `capabilities-terminal.md:NNN` strings inside any spec are this node's own
  spec05 and spec08 prose. Citation drift is therefore a silent-rot risk
  rather than a gate failure, which is why B4 makes it structurally
  impossible instead of relying on a check.
- **`docs-inventories/specs/spec04.md`** greps the literal string
  `capabilities-terminal.md` — but inside `capabilities.md`'s **head
  legend**, a different file. Unaffected.
- **`backlog-closeout/specs/check05.sh`** asserts the corrections backlog
  *names* this file. Unaffected.
- On the simulated file: 550 lines, 30 entries, ratio sequence identical,
  copy-mode still `4 9`, line 220 still `## Appearance baseline`, L-11
  present, and `motions and searches` gone. **Nothing goes red.**

## Out of scope

- The F5 entry's `SIMPLIFY` marker and the tab floor's, both withdrawn by Q1
  and Q2. Marker moves in *this* inventory are a rating-rule change and would
  need the author, exactly as Q4 did for `capabilities.md`; the PRD headers
  record the withdrawal instead (spec03, spec04, spec07).
- Everything else in the file. W0.1 wrote it against the live config and it
  held up under this re-spec's independent re-measurement.

## Spent proof

`docs/capabilities-terminal.md` is 577 lines today because later nodes added
entries to it, so both the 550-line neutrality pin and the `line 220 == "##
Appearance baseline"` offset address a file layout the inventory has since
outgrown.

Retired from `verify:` by
[`mi-rooted-verify-commands`](../../mi-rooted-verify-commands/prd.md)
spec02. The command below is byte-identical to what spec01 left in this
file's `verify:`; it is kept because it is the execution record of a check
that once ran green.

```text
verify: `bash -c 'cd "$(git rev-parse --show-toplevel)"; f=docs/capabilities-terminal.md; rc=0; grep -qF "motions and searches" "$f" && { echo "FAIL: the 55-builtins-and-searches claim survives at the source"; rc=1; }; grep -qF "all 55 builtin" "$f" && { echo "FAIL: still says 55 builtin"; rc=1; }; grep -qF "54 builtin" "$f" || { echo "FAIL: does not state 54 builtin motions"; rc=1; }; grep -qF "search_mode" "$f" || { echo "FAIL: does not name the separate search_mode table"; rc=1; }; grep -qF "Ctrl+Shift+F" "$f" || { echo "FAIL: does not name how search is actually reached"; rc=1; }; N=$(grep -c "^## " "$f"); [ "$N" = "30" ] || { echo "FAIL: entry count is $N, want 30 — a prose fix must not add or drop an entry"; rc=1; }; L=$(wc -l < "$f" | tr -d " "); [ "$L" = "550" ] || { echo "FAIL: file is $L lines, want 550 — the edit must be line-count neutral or every downstream :NNN citation shifts"; rc=1; }; S="8 7 7 7 6 6 6 6 6 5 5 5 5 5 5 4 4 4 4 3 3 1 0 -1 -2 -2 -3 -4 -5 -5 "; G="$(awk "/^## /{n=0} /^- [0-9]+\$/{v[n++]=\$2} /^----/{if(n>=2) printf \"%d \", v[n-1]-v[n-2]}" "$f")"; [ "$G" = "$S" ] || { echo "FAIL: ratio sequence changed — an entry moved or was re-rated"; echo "  got:  $G"; rc=1; }; CU="$(awk "/^## Copy mode/{f=1} f&&/^- [0-9]+\$/{printf \"%s \", \$2} f&&/^----/&&NR>206{exit}" "$f")"; [ "$CU" = "4 9 " ] || { echo "FAIL: copy-mode entry rates [$CU], want [4 9 ] — the rating must not move"; rc=1; }; [ "$(sed -n "220p" "$f")" = "## Appearance baseline" ] || { echo "FAIL: line 220 is no longer ## Appearance baseline; the :220-229 citations have shifted"; rc=1; }; grep -q "Live bug L-11" "$f" || { echo "FAIL: tests/live-bugs.sh:211 asserts this string is present"; rc=1; }; [ $rc -eq 0 ] && echo OK; exit $rc'`
```
