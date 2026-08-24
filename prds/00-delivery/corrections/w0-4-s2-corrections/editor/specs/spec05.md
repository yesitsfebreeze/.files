# spec05 — R5: `plugins/editor.lua` is three PRDs writing one unnamed file

est: 0.5h

Closes ticket **R5**, and the `cmdheight` half of the backlog's Neovim
coverage-gap bullet (whose other half is R5 itself).

## Goal

`~/.config/nvim/lua/plugins/editor.lua` is a catch-all holding **five**
unrelated plugin specs — gitsigns, which-key, nvim-autopairs, conform, and
vim-table-mode (verified 2026-08-21; lines 5, 19, 33, 39, 67). Three PRDs in
this epic write to it:

| node | task | what it puts there |
|---|---|---|
| [`07-formatting`](../../../../../03-editor/07-formatting/prd.md) | E.11 | conform.nvim |
| [`12-small-plugins`](../../../../../03-editor/12-small-plugins/prd.md) | E.12 | gitsigns, which-key, autopairs |
| [`15-markdown-tables`](../../../../../03-editor/15-markdown-tables/prd.md) | E.15 | vim-table-mode |

**The filename appears nowhere in the `03-editor` tree.** `grep -rn
'editor\.lua' .mi/prds/03-editor/` returns zero hits. It appears only in
`00-delivery/work-breakdown` (three table rows) and in
`00-delivery/parallelization`, which already names the collision and picks the
resolution:

> | `plugins/editor.lua` | E.11, E.12, E.15 | Split into one file per plugin
> (cheaper than serializing). |

So the decision exists and is recorded in a delivery-planning document, while
the three nodes that would implement it cannot see it — none of them names a
target file at all. That is the defect: a three-way write collision that is
invisible from every node involved, resolved in a document none of them
links.

The fix is not to restate the resolution in three places (`AGENTS.md`:
"Cross-link, don't duplicate"; "Epics own the invariants"). It goes in the
epic, once, as a file-layout invariant that every child already inherits, and
the one node in this ticket's footprint names its own files under it.

`12-small-plugins` is the only one of the three in this footprint.
`07-formatting` and `15-markdown-tables` gain nothing local and are reported
as a residual — the epic invariant binds them, but neither carries a pointer.

## The `cmdheight` gap

The same backlog bullet reads: "**Neovim:** `cmdheight`; and the fact that
`plugins/editor.lua` actually holds five specs". R5 names only the second
half. The first is one line — `lua/config/options.lua:18` is
`opt.cmdheight = 1`, which is **Neovim's own default**. Recording it is
honest bookkeeping, not a behaviour change, and the record has to say that or
the next reader will hunt for the reason it was set. It costs one clause in
`01-options` R2, a file this spec is not otherwise touching but which is in
footprint.

## Files touched

- `.mi/prds/03-editor/prd.md` — one new invariant, **I8**.
- `.mi/prds/03-editor/12-small-plugins/prd.md` — a target-files clause.
- `.mi/prds/03-editor/01-options/prd.md` — `cmdheight` in R2.

Apply spec02 first: it introduces **I7**, and this invariant is **I8**.
**Do not edit any frontmatter.** Not touched: `07-formatting`,
`15-markdown-tables`, `00-delivery/work-breakdown` (W0.4g's),
`00-delivery/parallelization`.

## What to write

### 1. The epic gains I8

> - [ ] **I8** — **One file per plugin under `lua/plugins/`.** Each plugin
>       spec lives in a file named for the plugin; there is no catch-all.
>       The live config has one — `lua/plugins/editor.lua`, holding five
>       unrelated specs (gitsigns, which-key, nvim-autopairs, conform,
>       vim-table-mode) — and three nodes of this epic write to it:
>       [`07-formatting`](../../../../../03-editor/07-formatting/prd.md) (conform),
>       [`12-small-plugins`](../../../../../03-editor/12-small-plugins/prd.md) (the first three) and
>       [`15-markdown-tables`](../../../../../03-editor/15-markdown-tables/prd.md) (vim-table-mode).
>       Until this invariant existed the filename appeared nowhere in this
>       epic, so nothing warned the three that they collide, and the
>       resolution lived only in
>       [`parallelization`](../../../../parallelization/prd.md) — a
>       document none of them links. Splitting is what makes the three
>       buildable in parallel instead of serialised, and it is why each node
>       below names its own target files.

### 2. `12-small-plugins` names its files

Add as the last requirement (**R4** — the file currently ends at R3):

> - [ ] **R4** — **Three files, not one.** Per the epic's
>       [I8](../prd.md), these three specs live in
>       `lua/plugins/gitsigns.lua`, `lua/plugins/which-key.lua` and
>       `lua/plugins/autopairs.lua` — never in a shared
>       `lua/plugins/editor.lua`, which is what the live config has and what
>       puts this node, [`07-formatting`](../../../../../03-editor/07-formatting/prd.md) and
>       [`15-markdown-tables`](../../../../../03-editor/15-markdown-tables/prd.md) in a three-way
>       write collision.

### 3. `01-options` R2 gains `cmdheight`

Append to R2's list:

> …`fillchars.eob=" "` (no `~` past the last line), and `cmdheight=1` — set
> explicitly in the live config and identical to Neovim's default, recorded
> because the audit listed it as uncovered, not because it changes anything.
> If a later node wants a hidden command line it is `cmdheight=0` and a
> decision, not a tweak here.

## Acceptance

- [ ] The epic has an **I8** requiring one file per plugin.
- [ ] I8 names `editor.lua` and lists all five specs it holds.
- [ ] I8 names all three colliding nodes.
- [ ] I8 links `parallelization`.
- [ ] `12-small-plugins` names its three target `.lua` files.
- [ ] `12-small-plugins` R1–R3 keep their numbers and text.
- [ ] `01-options` R2 names `cmdheight` and says it equals the default.
- [ ] `grep -rn 'editor\.lua' .mi/prds/03-editor/` is no longer empty — the
      filename is reachable from the epic.
- [ ] Every box in all three files is still open — no `[x]`, no `[~]`.

verify: ""

**Proven RED against the current tree before this spec was written**, run
verbatim as the string above. It reports: the epic has no I8, then all ten of
I8's content clauses on the empty string; `12-small-plugins` names none of its
three target files; `01-options` R2 does not name `cmdheight` and does not
record that it equals the default; and `editor.lua` is still unreachable from
the `03-editor` tree. Exit 1.

The R1–R3 presence clauses and the box-state clause pass today and guard
against renumbering.

The last clause (`grep -rqF "editor.lua" .mi/prds/03-editor/`) is the
whole-tree form of R5's actual complaint — "the filename appears nowhere in
the tree though three PRDs write it" — and it is deliberately a
directory-wide grep rather than a check on one file, so it stays true however
a later editor moves the invariant around.

## Spent proof

`prds/03-editor/01-options/prd.md` was implemented after this node closed,
so its boxes are closed; the guard was written to catch a box closing during
this node's own run.

Retired from `verify:` by
[`mi-rooted-verify-commands`](../../../mi-rooted-verify-commands/prd.md)
spec02. The command below is byte-identical to what spec01 left in this
file's `verify:`; it is kept because it is the execution record of a check
that once ran green.

```text
verify: `bash -c 'cd "$(git rev-parse --show-toplevel)"; rc=0; E=prds/03-editor/prd.md; P=prds/03-editor/12-small-plugins/prd.md; O=prds/03-editor/01-options/prd.md; req() { awk -v n="$2" "BEGIN{p=\"\\\\*\\\\*\" n \"\\\\*\\\\*\"} \$0 ~ p {r=1} r && /^- \[.\] \*\*[RI][0-9]/ && \$0 !~ p {r=0} r && /^## / {r=0} r" "$1" | tr "\n" " " | tr -s " "; }; i8=$(req "$E" I8); [ -n "$i8" ] || { echo "FAIL: the epic has no I8 file-layout invariant"; rc=1; }; printf "%s" "$i8" | grep -qF "editor.lua" || { echo "FAIL: I8 does not name editor.lua"; rc=1; }; for s in gitsigns which-key autopairs conform vim-table-mode; do printf "%s" "$i8" | grep -qF "$s" || { echo "FAIL: I8 does not list the spec: $s"; rc=1; }; done; for n in 07-formatting 12-small-plugins 15-markdown-tables; do printf "%s" "$i8" | grep -qF "$n" || { echo "FAIL: I8 does not name the colliding node: $n"; rc=1; }; done; printf "%s" "$i8" | grep -qF "parallelization" || { echo "FAIL: I8 does not link parallelization"; rc=1; }; up=$(tr "\n" " " < "$P" | tr -s " "); for f in "lua/plugins/gitsigns.lua" "lua/plugins/which-key.lua" "lua/plugins/autopairs.lua"; do printf "%s" "$up" | grep -qF "$f" || { echo "FAIL: 12-small-plugins does not name target file: $f"; rc=1; }; done; for i in 1 2 3; do printf "%s" "$up" | grep -qF "**R$i**" || { echo "FAIL: 12-small-plugins lost R$i"; rc=1; }; done; r2=$(req "$O" R2); printf "%s" "$r2" | grep -qF "cmdheight" || { echo "FAIL: 01-options R2 does not name cmdheight"; rc=1; }; printf "%s" "$r2" | grep -qE "default" || { echo "FAIL: 01-options R2 does not record that cmdheight equals the default"; rc=1; }; grep -rqF "editor.lua" prds/03-editor/ || { echo "FAIL: editor.lua is still unreachable from the 03-editor tree"; rc=1; }; for f in "$E" "$P" "$O"; do grep -qE "^- \[[x~]\]" "$f" && { echo "FAIL: a box was closed in $f"; rc=1; }; done; [ $rc -eq 0 ] && echo OK; exit $rc'`
```
