# spec04 — mark C-1..C-5 disposed in the corrections backlog

Appends the dated fix record to each row of the backlog's "S1 — capsule
collides with live bindings and rests on broken code" table, after spec01–
spec03 have landed. This is what makes the PRD's acceptance box "C-1 through
C-5 are each fixed or recorded as accepted with a reason" checkable. Run
this spec last.

**Est:** 0.5h

**Footprint:** `prds/00-delivery/corrections/prd.md` — the five `C-*` table
rows only.

Hard limits: never edit frontmatter. Touch nothing outside the five `C-*`
rows — the numbered open-decisions items and the `L-*` table are pinned
byte-for-byte by landed verifies (`tests/live-bugs.sh`,
`decisions/*/specs`).

## Edits — all in `prds/00-delivery/corrections/prd.md`

Append to the Finding cell (same table cell, after the existing text), and
change the Owner cell's `— **open**` to `— landed`, per row:

1. **C-1**: set the Owner cell to
   `\`w0-5-capsule-rebase\` R2 — landed. The \`Ctrl+Shift+B\` half was
   dissolved by decision 5(c); the \`Ctrl+Shift+T\` half by rekey.`
   Append to the Finding cell:
   `**Fixed 2026-08-22** — \`w0-5-capsule-rebase\` R2. \`SpawnTab\` keeps
   \`Ctrl+Shift+T\` and the recents new-tab variant is \`Ctrl+Shift+O\`
   (\`01-capsule/04\` R2; decision recorded there).`

2. **C-2**: append
   `**Fixed 2026-08-22** — \`w0-5-capsule-rebase\` R1; the epic purpose
   now reads build-once, informed by the legacy attempt, and
   \`01-capsule/01\` is retitled off "consolidates".`

3. **C-3**: the row already carries its `**Fixed 2026-08-21**` record. In
   the Finding cell, replace the closing clause
   `is \`w0-5-capsule-rebase\` R3 and has not landed.` with
   `is \`w0-5-capsule-rebase\` R3. **Residue landed 2026-08-22** — the
   epic is re-based (\`w0-5-capsule-rebase\` R1/R3).`
   Replace, do not append: a bare append leaves "has not landed" standing
   beside the landed record.

4. **C-4**: append
   `**Fixed 2026-08-22** — \`w0-5-capsule-rebase\` R4; \`01-capsule/02\`
   attributes zsh, oh-my-zsh and Claude Code to the capsule image and its
   \`Parent:\` source list is restored.`

5. **C-5**: append
   `**Fixed 2026-08-22** — \`w0-5-capsule-rebase\` via \`01-capsule/04\`
   R3: the picker surface announces the mode; the status bar stays
   clock-only.`

Cells are single table lines — keep each row on one line, do not re-wrap
the table.

## Acceptance

- [x] Rows C-1, C-2, C-4, C-5 each carry a dated `**Fixed** —
      \`w0-5-capsule-rebase\`` record; C-3 carries the dated residue
      record. Verify 2026-08-22: `PASS C-1..C-5` (all five record checks),
      `PASS no open C rows left`.
- [x] Only `| C-` rows changed. Checked 2026-08-22 with the scratch-copy
      procedure: `diff -U0 <pre-edit copy> prds/00-delivery/corrections/prd.md`
      shows one hunk, `@@ -60,5 +60,5 @@`, and every changed line starts
      `| C-`. Diff quoted in the implementer report.
- [x] The `L-*` table still has exactly 12 rows and the five numbered
      open-decisions items are byte-unchanged. Verify 2026-08-22:
      `PASS L table still 12 rows`, `PASS decision 5 intact`, `PASS
      decision 4 intact`; the scratch-copy diff touches no line outside
      the C rows, so the open-decisions items are byte-identical.

## Verify

```sh
cd "$(git rev-parse --show-toplevel)"
f=prds/00-delivery/corrections/prd.md
fail=0; chk(){ if eval "$2" >/dev/null 2>&1; then echo "PASS  $1"; else echo "FAIL  $1"; fail=1; fi; }
for id in C-1 C-2 C-4 C-5; do
  chk "$id: fixed record" "grep -E '^\| $id \|' $f | grep -qE 'Fixed 2026-08-[0-9]{2}.*w0-5-capsule-rebase'"
done
chk "C-3: residue landed"    "grep -E '^\| C-3 \|' $f | grep -qE 'Residue landed 2026-08-[0-9]{2}'"
chk "no open C rows left"    "! grep -E '^\| C-[0-9]+ \|' $f | grep -qF -- '— **open**'"
chk "C table still 5 rows"   "test \"\$(grep -cE '^\| C-[0-9]+ \|' $f)\" -eq 5"
chk "L table still 12 rows"  "test \"\$(grep -cE '^\| L-[0-9]+ \|' $f)\" -eq 12"
chk "decision 5 intact"      "grep -qF 'both are dropped, on the record, and' $f"
chk "decision 4 intact"      "grep -qF 'the deployed \`~/.config\` tree is canonical' $f"
exit $fail
```
