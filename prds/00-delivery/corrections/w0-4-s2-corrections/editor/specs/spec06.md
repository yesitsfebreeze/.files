# spec06 — L-6: record the `hlsearch` decision on both halves

est: 0.3h

Closes ticket **R3**. **Extends this ticket's footprint by one file** — see
the footprint note.

## Goal

Live bug L-6: `~/.config/nvim/lua/config/keymaps.lua:4` maps `<Esc>` →
`nohlsearch`, and `lua/config/options.lua:30` sets `opt.hlsearch = false`, so
there is never a highlight for the map to clear. The map is dead code that
looks alive.

R3 says "Port one or the other and say which." **It is already decided** — in
the backlog, on the L-6 row, and the decision is pinned by
`tests/live-bugs.sh`:

> **Decided 2026-08-21 (afk):** keep `opt.hlsearch = false` and drop the inert
> map. Rejected: the LazyVim pairing (turn `hlsearch` on, keep the map) — it
> changes the feel of every search to give one dead line a job, and
> `06-help`'s drift check would then have to document a binding that never
> fires.

So R3 is not a decision to make; it is a decision to *place*. The two nodes
that implement the two halves — `01-options` R6 and `02-keymaps` R1 — say
nothing about it today. `02-keymaps` R1 still reads, in whole: "**Search.**
`<Esc>` (normal) → `nohlsearch`." An implementer building from that node alone
rebuilds the bug, which is exactly what this sweep exists to prevent.

## Footprint note

`.mi/prds/03-editor/02-keymaps/prd.md` is **not** in W0.4c's `files` list in
`.mi/gantt/plan.json`, and R3 cannot be discharged without it — half the
decision lives there and nowhere else.

It is also in **no other task's** `files` list anywhere in `plan.json`
(checked against all seven W0.4 children and every other task): W0.4a takes
`.mi/docs/*`, W0.4b `04-shell/*`, W0.4d `06-help/*`, W0.4e `01-capsule/*`,
W0.4f `05-platform/*`, W0.4g `work-breakdown` and `README.md`. So the
one-writer-per-file rule is not at risk; the file is simply unassigned. Taking
it here is the cheapest correct route, and the alternative — a follow-up
ticket for one bullet — costs more than it saves.

**This is a footprint extension the conductor should confirm before the
implementer runs.** It does not extend to `14-shift-select`, which the
conductor excluded explicitly and which this spec does not touch.

While the file is open, repair its truncated `Parent:` header too — it carries
the same `8ecbbe4` conversion damage as the four in spec01 (`· source: "Core
keymaps" in`, ending there). Recovered pre-conversion text:
`git show 8ecbbe4^:.mi/prd/03-editor/02-keymaps.md | sed -n '3,4p'`, and the
C 2 / U 9 numbers re-checked against the "Core keymaps" entry in
`capabilities-nvim.md`.

## Files touched

- `.mi/prds/03-editor/01-options/prd.md` — R6 only.
- `.mi/prds/03-editor/02-keymaps/prd.md` — R1 and the `Parent:` line.
  **[footprint extension]**

**Do not edit either frontmatter.** Not touched:
`.mi/prds/00-delivery/corrections/prd.md` (W0.6's; `tests/live-bugs.sh` pins
the L-6 row and it stays true), `.mi/docs/capabilities-nvim.md` (W0.4a's;
already carries the "Live bug L-6, resolved" record), `~/.config/nvim`.

## What to write

### 1. `01-options` R6 — the half that is ported

> - [ ] **R6** — **Search.** `ignorecase` + `smartcase`, `incsearch`,
>       `hlsearch=false`. `hlsearch=false` is the surviving half of live bug
>       L-6 (decided 2026-08-21, afk): matches are highlighted while you type
>       and stop being highlighted when you stop, so there is nothing to
>       clear afterwards — which is why
>       [`02-keymaps`](../../../../../03-editor/02-keymaps/prd.md) R1 does **not** port the live
>       `<Esc>` → `nohlsearch` map. Turning `hlsearch` on to give that map a
>       job was considered and rejected; it changes the feel of every search
>       for one dead line.

### 2. `02-keymaps` R1 — the half that is not

Keep the number. `AGENTS.md`: "the number is kept because other documents cite
requirements by number", so R1 becomes a record of a non-port rather than
disappearing, and R2–R8 are not renumbered.

> - [ ] **R1** — **Search: no `nohlsearch` map.** The live `<Esc>` →
>       `<cmd>nohlsearch<CR>` map (`lua/config/keymaps.lua:4`) is **not
>       ported**. With [`01-options`](../../../../../03-editor/01-options/prd.md) R6's
>       `hlsearch=false` there is never a highlight to clear, so the map is
>       inert — live bug L-6, decided 2026-08-21 (afk) in
>       [the corrections backlog](../../../prd.md).
>       Rejected: the LazyVim pairing, turning `hlsearch` on and keeping the
>       map, which changes the feel of every search to give one dead line a
>       job and would make [`06-help`](../../../../../06-help/prd.md) document a
>       binding that never fires. This requirement keeps its number and
>       prescribes no keymap.

### 3. `02-keymaps` header

> Parent: [Neovim epic](../prd.md) · C 2 · U 9 · source: "Core keymaps" in
> [`capabilities-nvim.md`](../../../../../../docs/capabilities-nvim.md)

## Acceptance

- [ ] `01-options` R6 still sets `hlsearch=false` and now says why, citing
      L-6.
- [ ] `01-options` R6 links `02-keymaps` as the other half.
- [ ] `02-keymaps` R1 states the map is not ported.
- [ ] `02-keymaps` R1 cites L-6 and names the rejected alternative.
- [ ] `02-keymaps` R1 is still numbered R1; R2–R8 keep their numbers.
- [ ] No requirement anywhere prescribes an `<Esc>` → `nohlsearch` mapping.
- [ ] `02-keymaps`' `Parent:` line names and links `capabilities-nvim.md`,
      with its C/U unchanged at C 2 / U 9.
- [ ] Every box in both files is still open — no `[x]`, no `[~]`.
- [ ] `bash tests/live-bugs.sh` still exits 0.

verify: ""

**Proven RED against the current tree before this spec was written**, run
verbatim as the string above. It reports seven failures: `01-options` R6 does
not cite L-6 and does not link the other half; `02-keymaps` R1 does not say
the map is not ported, does not cite L-6, does not name the rejected
alternative; one line still prescribes `nohlsearch` without recording the
non-port (and prints it — `02-keymaps/prd.md:19`); and the `02-keymaps` header
does not name `capabilities-nvim.md`. Exit 1.

Passing today as regression guards: `hlsearch=false` present, R2–R8 present,
the header's `C 2 · U 9` and source name, boxes open, and
`tests/live-bugs.sh` green. So does the "R1 mentions `hlsearch`" clause —
`nohlsearch` contains the substring, so that one can only catch a total
rewrite, and it is kept for that and nothing more. The last
is the same guard as spec03's and for the same reason: L-6's row asserts the
map exists **in the live config**, which this spec does not touch. An
implementer who "fixes" L-6 by editing `~/.config/nvim` turns that assertion
red and gets caught.

The `nohlsearch` sweep is a whole-directory grep with an allow-list of the
phrasings that record a *non*-port, rather than a check on one requirement.
That way a later editor who reintroduces the map anywhere in `03-editor` —
including in a node this ticket never opened — fails the gate.

## Spent proof

The tree-wide `grep -rn nohlsearch prds/03-editor/` sweep now reaches spec
files written later:
`prds/03-editor/01-options/specs/spec01-options-config.md:79` states "no
`<Esc>` → `nohlsearch` map is added", which is the non-port record itself
but is too many words away from `nohlsearch` to match the guard's `no
.nohlsearch. map` exemption, and the other two hits are gate patterns —
while every assertion on the R6 and R1 text this node wrote still passes.

Retired from `verify:` by
[`mi-rooted-verify-commands`](../../../mi-rooted-verify-commands/prd.md)
spec02. The command below is byte-identical to what spec01 left in this
file's `verify:`; it is kept because it is the execution record of a check
that once ran green.

```text
verify: `bash -c 'cd "$(git rev-parse --show-toplevel)"; rc=0; O=prds/03-editor/01-options/prd.md; K=prds/03-editor/02-keymaps/prd.md; req() { awk -v n="$2" "BEGIN{p=\"\\\\*\\\\*\" n \"\\\\*\\\\*\"} \$0 ~ p {r=1} r && /^- \[.\] \*\*[RI][0-9]/ && \$0 !~ p {r=0} r && /^## / {r=0} r" "$1" | tr "\n" " " | tr -s " "; }; r6=$(req "$O" R6); printf "%s" "$r6" | grep -qF "hlsearch=false" || { echo "FAIL: 01-options R6 lost hlsearch=false"; rc=1; }; printf "%s" "$r6" | grep -qF "L-6" || { echo "FAIL: 01-options R6 does not cite L-6"; rc=1; }; printf "%s" "$r6" | grep -qF "02-keymaps" || { echo "FAIL: 01-options R6 does not link the other half"; rc=1; }; k1=$(req "$K" R1); [ -n "$k1" ] || { echo "FAIL: 02-keymaps has no R1"; rc=1; }; printf "%s" "$k1" | grep -qE "not ported|not.{0,4}ported" || { echo "FAIL: 02-keymaps R1 does not say the map is not ported"; rc=1; }; printf "%s" "$k1" | grep -qF "L-6" || { echo "FAIL: 02-keymaps R1 does not cite L-6"; rc=1; }; printf "%s" "$k1" | grep -qE "Rejected|rejected" || { echo "FAIL: 02-keymaps R1 does not name the rejected alternative"; rc=1; }; printf "%s" "$k1" | grep -qF "hlsearch" || { echo "FAIL: 02-keymaps R1 does not mention hlsearch"; rc=1; }; for i in 2 3 4 5 6 7 8; do tr "\n" " " < "$K" | grep -qF "**R$i**" || { echo "FAIL: 02-keymaps lost R$i"; rc=1; }; done; n=$(grep -rn "nohlsearch" prds/03-editor/ | grep -cvE "not ported|L-6|no .nohlsearch. map|does \*\*not\*\* port"); [ "$n" -eq 0 ] || { echo "FAIL: $n line(s) still prescribe nohlsearch without recording the non-port"; grep -rn "nohlsearch" prds/03-editor/ | grep -vE "not ported|L-6|no .nohlsearch. map|does \*\*not\*\* port"; rc=1; }; h=$(sed -n "/^Parent:/,/^$/p" "$K" | tr "\n" " " | tr -s " "); printf "%s" "$h" | grep -qF "capabilities-nvim.md" || { echo "FAIL: 02-keymaps header does not name capabilities-nvim.md"; rc=1; }; printf "%s" "$h" | grep -qE "C 2 . U 9" || { echo "FAIL: 02-keymaps header lost or changed its C 2 / U 9"; rc=1; }; printf "%s" "$h" | grep -qF "Core keymaps" || { echo "FAIL: 02-keymaps header lost its source name"; rc=1; }; for f in "$O" "$K"; do grep -qE "^- \[[x~]\]" "$f" && { echo "FAIL: a box was closed in $f"; rc=1; }; done; bash tests/live-bugs.sh >/dev/null 2>&1 || { echo "FAIL: tests/live-bugs.sh no longer exits 0"; rc=1; }; [ $rc -eq 0 ] && echo OK; exit $rc'`
```
