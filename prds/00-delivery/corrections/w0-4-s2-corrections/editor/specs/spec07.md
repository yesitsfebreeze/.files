# spec07 — L-7: oil loads eagerly, and the acceptance line stands

est: 0.4h

Closes ticket **R6**. **Extends this ticket's footprint by one file** — see
the footprint note.

## Goal

Live bug L-7. Three facts, all re-checked 2026-08-21:

1. `~/.config/nvim/lua/plugins/explorer.lua` declares oil with
   `keys = { { "<leader>e", "<cmd>Oil<CR>" } }` and no `event`, `cmd` or
   `lazy = false`. lazy.nvim therefore does not load it until `<leader>e` is
   pressed.
2. oil's `default_file_explorer` hijack is installed by oil's `setup()` — it
   replaces the `BufEnter`/directory-open handling at load time. Unloaded oil
   hijacks nothing.
3. `~/.config/nvim/lua/config/lazy.lua:34` disables `netrwPlugin`, and
   `03-editor/04-plugin-manager` R-list specifies exactly that.

So in a fresh session `:e some/dir` opens **neither** — netrw is gone and oil
is not there yet. And `03-editor/06-explorer`'s third acceptance line is:

> - [ ] `:e some/dir` opens oil, not netrw.

That line asserts precisely what the bug prevents. R6 asks for one of two
corrections, and to say which.

## The decision: correct the load condition, keep the acceptance line

**Chosen: make oil eager (`lazy = false`), and `06-explorer`'s third
acceptance line stands unchanged.**

Reasoning, recorded so it is not re-derived:

- The node's own Purpose says oil "Replaces netrw (disabled in
  `04-plugin-manager`)". An explorer that replaces netrw only *after* you
  press a key has not replaced it — it has removed it. Keeping the lazy load
  and deleting the acceptance line would make the PRD self-consistent by
  giving up the capability it exists for.
- The alternative is strictly worse than stock vim. With netrw disabled and
  oil unloaded, `:e some/dir` is a dead end that a stock Neovim handles fine.
  Porting that is porting a regression.
- `<leader>e` still works either way; it is `keys` that becomes redundant as a
  *loader*, not as a binding.
- The cost is one small plugin at startup. oil is C 2 in the inventory, and
  this epic already loads tinted-nvim with `lazy = false` and
  `priority = 1000` for the same reason — a thing that must be in place before
  the user's first action cannot be lazy on that action.

This is an `afk` decision and R6 explicitly delegates it ("Correct the load
condition, or correct the acceptance line — and say which"), so it is settled
here rather than escalated. Both options and the reason for the choice go into
the PRD, because the next reader will otherwise see an eagerly-loaded plugin
in a config full of lazy ones and "optimise" it back.

## Footprint note

`.mi/prds/03-editor/06-explorer/prd.md` is **not** in W0.4c's `files` list in
`.mi/gantt/plan.json`, and R6 names it as the node to correct — there is no
other file in which R6 can be discharged. It is in **no other task's** `files`
list either (same check as spec06: no W0.4 sibling and no other plan task
claims any `03-editor/*` file beyond W0.4c's five). One-writer-per-file is not
at risk; the file is unassigned.

**The conductor should confirm this extension before the implementer runs.**

While the file is open, repair its truncated `Parent:` header — same
`8ecbbe4` damage (`· source: "File explorer`, cut mid-string). Recovered:
`git show 8ecbbe4^:.mi/prd/03-editor/06-explorer.md | sed -n '3,4p'`; the
entry is "File explorer (oil.nvim)" in `capabilities-nvim.md`, C 2 / U 8,
matching the header's existing numbers.

## Files touched

- `.mi/prds/03-editor/06-explorer/prd.md` — R1, a new R4, the `Parent:` line.
  **[footprint extension]**

**Do not edit the frontmatter.** Not touched: `04-plugin-manager` (netrw
stays disabled — that is not the half being corrected),
`.mi/prds/00-delivery/corrections/prd.md`, `.mi/docs/capabilities-nvim.md`
(W0.4a's; already carries the "Live bug L-7, do not reproduce" record),
`~/.config/nvim`.

## What to write

### 1. Extend R1 with the load condition

> - [ ] **R1** — **Plugin, loaded eagerly.** `stevearc/oil.nvim` with
>       `nvim-tree/nvim-web-devicons`, `lazy = false`. **Not lazy on `keys`**,
>       which is what the live config does and is live bug L-7: oil installs
>       its `default_file_explorer` hijack in `setup()`, so while it is
>       unloaded it hijacks nothing — and with netrw disabled by
>       [`04-plugin-manager`](../04-plugin-manager/prd.md), `:e some/dir`
>       opens neither, a dead end stock Neovim does not have. `<leader>e`
>       (R3) is unaffected; it stops being a *loader* and stays a binding.

### 2. New R4 recording the fork and the reason

> - [ ] **R4** — **Why oil is not lazy.** Recorded so it is not "optimised"
>       back: live bug L-7 offered two corrections — make oil eager, or drop
>       the `:e some/dir` acceptance check. The first was taken
>       (2026-08-21, afk, under
>       [`w0-4-s2-corrections/editor`](../../00-delivery/corrections/w0-4-s2-corrections/editor/prd.md)
>       R6). Dropping the check would have made this node self-consistent by
>       abandoning the capability its Purpose names — replacing netrw — and
>       left `:e some/dir` worse than stock. The cost is one C-2 plugin at
>       startup, the same trade
>       [`11-colorscheme`](../11-colorscheme/prd.md) R1 already makes for
>       tinted-nvim: a thing that must be in place before the user's first
>       action cannot be lazy on that action.

### 3. Header

> Parent: [Neovim epic](../prd.md) · C 2 · U 8 · source: "File explorer
> (oil.nvim)" in
> [`capabilities-nvim.md`](../../../docs/capabilities-nvim.md)

### 4. The acceptance line

Unchanged. Add nothing and remove nothing from
`- [ ] :e some/dir opens oil, not netrw.` — the point of this spec is that it
becomes true.

## Acceptance

- [ ] R1 specifies `lazy = false`.
- [ ] R1 explicitly rejects lazy-on-`keys` and cites L-7.
- [ ] R1 explains the mechanism — the hijack is installed at `setup()` time.
- [ ] R1 names the netrw interaction.
- [ ] There is a requirement recording that the fork was decided, which
      option was taken, and why the other was refused.
- [ ] The `:e some/dir` acceptance line is still present and unchanged.
- [ ] R2 and R3 keep their numbers and text.
- [ ] The `Parent:` line names and links `capabilities-nvim.md`, C/U
      unchanged at C 2 / U 8.
- [ ] Every box in the file is still open — no `[x]`, no `[~]`.
- [ ] `bash tests/live-bugs.sh` still exits 0.

verify: ""

**Proven RED against the current tree before this spec was written**, run
verbatim as the string above. It reports: R1 does not specify `lazy = false`,
does not cite L-7, does not reject lazy-on-`keys`, does not explain the
hijack, does not name netrw; no requirement records the fork, then its two
content clauses on the empty string; the header does not name
`capabilities-nvim.md`; and the header source name is still cut mid-string.
Exit 1.

The clauses that pass today are the ones this spec must **not** break: the
plugin name, R2 and R3 present, the `C 2 · U 8` numbers, all boxes open,
`tests/live-bugs.sh` green — and, most importantly, the two clauses asserting
that `- [ ] :e some/dir opens oil, not netrw.` is still there and still worded
that way. Those are the point: R6 offered deleting that line as an option, and
this spec's whole decision is that it stays. A verify that only checked the
new text would pass just as happily if an implementer took the other branch.

## Spent proof

`prds/03-editor/06-explorer/prd.md` has since been specced and its boxes
closed; the guard was written to catch a box closing during this node's own
run.

Retired from `verify:` by
[`mi-rooted-verify-commands`](../../../mi-rooted-verify-commands/prd.md)
spec02. The command below is byte-identical to what spec01 left in this
file's `verify:`; it is kept because it is the execution record of a check
that once ran green.

```text
verify: `bash -c 'cd "$(git rev-parse --show-toplevel)"; rc=0; F=prds/03-editor/06-explorer/prd.md; req() { awk -v n="$2" "BEGIN{p=\"\\\\*\\\\*\" n \"\\\\*\\\\*\"} \$0 ~ p {r=1} r && /^- \[.\] \*\*[RI][0-9]/ && \$0 !~ p {r=0} r && /^## / {r=0} r" "$1" | tr "\n" " " | tr -s " "; }; u=$(tr "\n" " " < "$F" | tr -s " "); r1=$(req "$F" R1); printf "%s" "$r1" | grep -qF "lazy = false" || { echo "FAIL: R1 does not specify lazy = false"; rc=1; }; printf "%s" "$r1" | grep -qF "L-7" || { echo "FAIL: R1 does not cite L-7"; rc=1; }; printf "%s" "$r1" | grep -qE "keys" || { echo "FAIL: R1 does not reject the lazy-on-keys load condition"; rc=1; }; printf "%s" "$r1" | grep -qF "default_file_explorer" || { echo "FAIL: R1 does not explain the hijack mechanism"; rc=1; }; printf "%s" "$r1" | grep -qF "netrw" || { echo "FAIL: R1 does not name the netrw interaction"; rc=1; }; printf "%s" "$r1" | grep -qF "stevearc/oil.nvim" || { echo "FAIL: R1 lost the plugin name"; rc=1; }; r4=$(req "$F" R4); [ -n "$r4" ] || { echo "FAIL: no requirement records the L-7 fork and its decision"; rc=1; }; printf "%s" "$r4" | grep -qE "2026-08-21" || { echo "FAIL: the fork record carries no decision date"; rc=1; }; printf "%s" "$r4" | grep -qE "two corrections|either|or drop|alternative" || { echo "FAIL: the fork record does not name the option that was refused"; rc=1; }; acc=$(awk "/^## Acceptance/{r=1;next} r&&/^## /{r=0} r" "$F" | tr "\n" " " | tr -s " "); printf "%s" "$acc" | grep -qF "some/dir" || { echo "FAIL: the :e some/dir acceptance line was removed - this spec keeps it"; rc=1; }; printf "%s" "$acc" | grep -qE "opens oil, not netrw" || { echo "FAIL: the :e some/dir acceptance line was reworded"; rc=1; }; for i in 2 3; do printf "%s" "$u" | grep -qF "**R$i**" || { echo "FAIL: lost R$i"; rc=1; }; done; h=$(sed -n "/^Parent:/,/^$/p" "$F" | tr "\n" " " | tr -s " "); printf "%s" "$h" | grep -qF "capabilities-nvim.md" || { echo "FAIL: header does not name capabilities-nvim.md"; rc=1; }; printf "%s" "$h" | grep -qE "C 2 . U 8" || { echo "FAIL: header lost or changed its C 2 / U 8"; rc=1; }; printf "%s" "$h" | grep -qF "oil.nvim)" || { echo "FAIL: header source name still cut mid-string"; rc=1; }; grep -qE "^- \[[x~]\]" "$F" && { echo "FAIL: a box was closed"; rc=1; }; bash tests/live-bugs.sh >/dev/null 2>&1 || { echo "FAIL: tests/live-bugs.sh no longer exits 0"; rc=1; }; [ $rc -eq 0 ] && echo OK; exit $rc'`
```
