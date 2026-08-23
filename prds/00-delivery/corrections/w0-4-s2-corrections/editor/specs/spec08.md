# spec08 — L-9: put the `<C-v>` shadow decision where the keymaps live

est: 0.35h

Closes ticket **R7** on the `02-keymaps` side. **Uses the same footprint
extension as spec06** (`02-keymaps`), and leaves a declared residual on
`14-shift-select`.

## Goal

Live bug L-9: `~/.config/nvim/lua/config/keymaps.lua` binds `<C-v>` in
**visual mode**, which shadows vim's blockwise-visual entry from a visual
selection. The backlog settled it:

> **Decided 2026-08-21 (afk): intentional — port as-is and leave `<C-q>`
> unbound.** It is half of the `<C-c>`/`<C-v>` pair that is the point of
> shift-select; the map is `v`-mode only, so normal-mode `<C-v>` still enters
> blockwise, `virtualedit=block` still applies, and the built-in `<C-q>` still
> covers promoting an existing selection. Rejected: moving paste to another
> key, which breaks the pair for a mode that keeps a working alternative.

`tests/live-bugs.sh` pins all three legs of that: `map("v", "<C-v>"` exists,
`map("v", "<C-c>"` exists alongside it, and `grep -r 'C-q' ~/.config/nvim/lua/`
returns **zero** hits.

The decision is recorded in the backlog and in `capabilities-nvim.md`. It is
recorded in **neither node that implements it**. Verified 2026-08-21:
`grep -rn 'C-q' .mi/prds/03-editor/` returns nothing, and `02-keymaps` says
only that `<C-c>`/`<C-v>` "are specced separately in 14-shift-select" — no
mention of the shadow, of blockwise-visual, or of `<C-q>`.

That is R7's whole point, and its wording says so: record it "in both
`03-editor/02-keymaps` and `03-editor/14-shift-select` […] so the decision is
reachable from the nodes that implement it."

The `<C-q>` half matters more than it looks. It is a **negative**
requirement — a key deliberately left unbound so that the shadowed capability
keeps a route. Negative requirements are the ones that vanish silently: no
later agent grepping for `<C-q>` finds anything, so nothing stops the next
person from binding it and closing the escape hatch that made L-9 acceptable.
Writing it down is the entire safeguard.

## Footprint note and the declared residual

`02-keymaps` is the footprint extension already argued in
[`spec06`](spec06.md) — not in W0.4c's `files` list, not in any other task's,
and unreachable-by-any-other-lane. This spec touches the same file, so it adds
no new extension; apply it in the same pass as spec06.

**Residual, declared not absorbed: `14-shift-select` gets nothing here.** The
conductor excluded it from this ticket's footprint, and it was written today
by `00-delivery/decisions/shift-select-scope` (the DECLINED simplification,
C 7 / U 7 preserved), so a concurrent second writer is exactly the risk the
one-writer rule exists for. Its R7 today specifies visual `<C-v>` → `"_dP`
with no word about the shadow or `<C-q>`. **R7's second half is therefore not
discharged by this ticket** and needs a one-bullet follow-up. It is a
paste-in, not analysis: the same decision text, aimed at that node's R7.

## Files touched

- `.mi/prds/03-editor/02-keymaps/prd.md` — one new requirement, **R9**.
  **[footprint extension, shared with spec06]**

**Do not edit the frontmatter.** Not touched: `14-shift-select` (see above),
`.mi/prds/00-delivery/corrections/prd.md` (W0.6's, and `tests/live-bugs.sh`
pins the L-9 row), `.mi/docs/capabilities-nvim.md` (W0.4a's; already carries
the "L-9, resolved" record), `~/.config/nvim`.

## What to write

Append after R8, keeping every existing number:

> - [ ] **R9** — **`<C-v>` shadows blockwise-visual, deliberately; `<C-q>`
>       stays unbound.** [`14-shift-select`](../14-shift-select/prd.md) R7
>       binds `<C-v>` in **visual mode** to `"_dP`, which shadows vim's entry
>       into blockwise-visual from a selection. That is live bug L-9, and it
>       was **decided 2026-08-21 (afk) to port as-is** — see
>       [the corrections backlog](../../00-delivery/corrections/prd.md). It is
>       half of the `<C-c>`/`<C-v>` pair that is the whole point of
>       shift-select, and the shadow is narrow: the map is `v`-mode only, so
>       normal-mode `<C-v>` still enters blockwise, and
>       [`01-options`](../01-options/prd.md) R9's `virtualedit=block` still
>       applies. Rejected: moving paste to another key, which breaks the pair
>       for a mode that keeps a working alternative.
>
>       **`<C-q>` is left unbound, on purpose.** It is vim's built-in synonym
>       for blockwise-visual and the route the shadow leaves open, so binding
>       it to anything closes the escape hatch that makes L-9 acceptable. No
>       node in this epic may map it. This is stated as a requirement because
>       an unbound key is invisible to search — nothing else in the tree
>       would stop a later agent from taking it.

## Acceptance

- [ ] `02-keymaps` has a requirement naming `<C-v>`, blockwise-visual and
      L-9.
- [ ] It states the decision is to port the shadow as-is, with its date.
- [ ] It names the rejected alternative.
- [ ] It states that the map is visual-mode only and that normal-mode
      `<C-v>` is unaffected.
- [ ] It states that `<C-q>` is left unbound and why.
- [ ] It links `14-shift-select`.
- [ ] R1–R8 keep their numbers and text (R1's text changes in spec06, not
      here).
- [ ] No PRD in `03-editor` binds `<C-q>` to anything.
- [ ] Every box in the file is still open — no `[x]`, no `[~]`.
- [ ] `14-shift-select/prd.md` still carries `C 7 · U 7`, its
      `## Simplification option — DECLINED 2026-08-21` section, and R1–R8 —
      the shape today's `shift-select-scope` lane left it in.
- [ ] `bash tests/live-bugs.sh` still exits 0.

verify: ""

**Proven RED against the current tree before this spec was written**, run
verbatim as the string above. It reports: `02-keymaps` has no R9, then all ten
of R9's content clauses on the empty string (`L-9`, `C-v`, `C-q`,
`14-shift-select`, the date, blockwise, unbound, rejected, visual-mode-only).
Exit 1.

Passing today as regression guards: R1–R8 present, the `<C-q>` sweep (zero
hits in `03-editor` today, and the allow-list means it keeps passing once R9
lands while still catching anyone who *binds* it), boxes open, the
`14-shift-select` shape clauses, and `tests/live-bugs.sh` green.

Two of those guards are substance rather than hygiene. The `<C-q>` sweep
enforces a negative requirement — the only mechanical thing that can stop a
later agent from binding the key the decision depends on staying free. And the
`14-shift-select` clauses catch an implementer who helpfully discharges R7's
other half in a file this ticket was told to leave alone; that residual is
reported upward, not absorbed.

Those clauses are **content** checks — `C 7 · U 7`, the `## Simplification
option` heading, R1–R8 — and not `git diff --quiet`. The first draft used the
diff form and it failed RED for the wrong reason: every file under
`.mi/prds/03-editor/` is currently staged-and-modified (`git status` reports
`AM` on all sixteen), so a clean-tree clause is red before anyone touches
anything. A guard that cannot be green is not a guard.

## Spent proof

The tree-wide `grep -rn C-q prds/03-editor/` sweep now reaches
`02-keymaps/specs/spec01-keymaps-config.md` and `spec02-gate.md`, written
later, whose four hits restate R9's "`<C-q>` is left unbound" and the gate
pattern enforcing it — one of them saying so across a line break the
exemption regex cannot span — while the R9 text this node wrote into
`02-keymaps/prd.md` passes every other assertion.

Retired from `verify:` by
[`mi-rooted-verify-commands`](../../../mi-rooted-verify-commands/prd.md)
spec02. The command below is byte-identical to what spec01 left in this
file's `verify:`; it is kept because it is the execution record of a check
that once ran green.

```text
verify: `bash -c 'cd "$(git rev-parse --show-toplevel)"; rc=0; K=prds/03-editor/02-keymaps/prd.md; req() { awk -v n="$2" "BEGIN{p=\"\\\\*\\\\*\" n \"\\\\*\\\\*\"} \$0 ~ p {r=1} r && /^- \[.\] \*\*[RI][0-9]/ && \$0 !~ p {r=0} r && /^## / {r=0} r" "$1" | tr "\n" " " | tr -s " "; }; u=$(tr "\n" " " < "$K" | tr -s " "); r9=$(req "$K" R9); [ -n "$r9" ] || { echo "FAIL: 02-keymaps has no R9 recording the L-9 decision"; rc=1; }; for s in "L-9" "C-v" "C-q" "14-shift-select" "2026-08-21"; do printf "%s" "$r9" | grep -qF "$s" || { echo "FAIL: 02-keymaps R9 does not name: $s"; rc=1; }; done; printf "%s" "$r9" | grep -qE "blockwise" || { echo "FAIL: R9 does not name blockwise-visual, the shadowed capability"; rc=1; }; printf "%s" "$r9" | grep -qE "unbound" || { echo "FAIL: R9 does not state that C-q is left unbound"; rc=1; }; printf "%s" "$r9" | grep -qE "Rejected|rejected" || { echo "FAIL: R9 does not name the rejected alternative"; rc=1; }; printf "%s" "$r9" | grep -qE "visual.mode only|v.-mode only|only in visual" || { echo "FAIL: R9 does not state the map is visual-mode only"; rc=1; }; for i in 1 2 3 4 5 6 7 8; do printf "%s" "$u" | grep -qF "**R$i**" || { echo "FAIL: 02-keymaps lost R$i"; rc=1; }; done; bind=$(grep -rn "C-q" prds/03-editor/ | grep -cvE "unbound|left unbound|synonym|may map it"); [ "$bind" -eq 0 ] || { echo "FAIL: $bind line(s) in 03-editor reference C-q other than as deliberately unbound"; grep -rn "C-q" prds/03-editor/ | grep -vE "unbound|left unbound|synonym|may map it"; rc=1; }; grep -qE "^- \[[x~]\]" "$K" && { echo "FAIL: a box was closed"; rc=1; }; S=prds/03-editor/14-shift-select/prd.md; us=$(tr "\n" " " < "$S" | tr -s " "); printf "%s" "$us" | grep -qE "C 7 . U 7" || { echo "FAIL: 14-shift-select lost its C 7 / U 7 - shift-select-scope declined that re-rating"; rc=1; }; grep -q "^## Simplification option" "$S" || { echo "FAIL: 14-shift-select lost its DECLINED simplification section"; rc=1; }; for i in 1 2 3 4 5 6 7 8; do printf "%s" "$us" | grep -qF "**R$i**" || { echo "FAIL: 14-shift-select lost R$i"; rc=1; }; done; bash tests/live-bugs.sh >/dev/null 2>&1 || { echo "FAIL: tests/live-bugs.sh no longer exits 0"; rc=1; }; [ $rc -eq 0 ] && echo OK; exit $rc'`
```
