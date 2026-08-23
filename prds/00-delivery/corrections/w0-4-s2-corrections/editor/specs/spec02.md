# spec02 — L-8: make "every autocmd is grouped" an invariant, not a habit

est: 0.75h

Closes ticket **R1**.

## Goal

Live bug L-8: some autocmds in the live config take no `group =`, so a config
reload registers a second copy of the callback and it fires twice per event.
`03-autocmds`' Purpose already claims the opposite —

> Each lives in its own cleared augroup so a config reload never stacks
> duplicates.

— but it says it in *prose*, about *its own four*, in the one file that
already obeys the rule. Nothing in the tree binds the autocmds declared inside
plugin specs, which is where every violation lives. That is the shape of the
defect: the invariant exists and is unenforceable.

**Re-measured on 2026-08-21, and L-8's two-site list is short by one.** A full
sweep of `~/.config/nvim` (`grep -rn 'nvim_create_autocmd' .` cross-checked
against `grep -rn 'group *='`) finds ten autocmds at eight call sites. Seven
are grouped. Three are not:

| site | event | node that will own it |
|---|---|---|
| `lua/plugins/treesitter.lua:31` | `FileType` | `03-editor/10-treesitter` |
| `lua/config/keymaps.lua:58` | `ModeChanged` | `03-editor/14-shift-select` |
| `lua/plugins/editor.lua:80` | `FileType` (vim-table-mode) | `03-editor/15-markdown-tables` |

The third is a **new finding**, not in the backlog's L-8 row. Do not edit the
L-8 row to add it — `.mi/prds/00-delivery/corrections/prd.md` belongs to W0.6
and `tests/live-bugs.sh` pins that row's contents. Record it here, in the
epic, where it changes what gets built; report it upward as a backlog
addendum.

The grouped seven, for contrast, are all four in `lua/config/autocmds.lua`
plus `lua/plugins/statusline.lua:56`, `lua/plugins/colorscheme.lua:38` and
`lua/plugins/lsp.lua:25`. This is why a naive grep passes falsely: `augroup`
appears seven times in the config, so "does the config group its autocmds?"
answers yes while three of them do not.

## Where R1's "both places" lands, and why it is not literally both

R1 asks for the requirement "in both places" — meaning the two nodes that will
implement the offending autocmds. Neither `10-treesitter` nor `14-shift-select`
is in this ticket's footprint (`.mi/gantt/plan.json`, W0.4c `files`), and the
conductor has excluded `14-shift-select` explicitly. So the requirement goes
where `AGENTS.md` says a rule spanning several children belongs:

> **Epics own the invariants.** Shared architecture […] goes in the epic, and
> children reference it rather than restating it.

The epic **is** in this footprint, and every child already ends with "The epic
owns the shared invariants", so an epic invariant binds all three offending
nodes today without a writer touching three files. That is a better fix than
R1 asked for, not a smaller one — R1's two-site framing would still have
missed `15-markdown-tables`.

**Residual, reported and not silently absorbed:** `10-treesitter` R3,
`14-shift-select` R2 and `15-markdown-tables` carry no local pointer at the
new invariant. Anyone reading one of those nodes alone still has to follow the
epic link. Adding a one-clause pointer to each is a follow-up ticket, not this
one.

## Files touched

- `.mi/prds/03-editor/prd.md` — one new invariant in the Requirements block.
- `.mi/prds/03-editor/03-autocmds/prd.md` — one new requirement, **R5**.

**Do not edit either frontmatter block.** Nothing else — in particular not
`10-treesitter`, `14-shift-select`, `15-markdown-tables`, the corrections
backlog, or `tests/live-bugs.sh`.

## What to write

### 1. The epic gains a numbered invariant

The epic's Requirements block currently ends with an invariant that carries
**no number** — `**I (from 05-platform/02 req 6)**`. Number it **I6** (nothing
in the tree cites it, so this creates no dangling reference; verified with
`grep -rn 'I (from' .mi/`), then append the new one as **I7**. Wrap at ~78
columns and leave both boxes open.

> - [ ] **I7** — **Every autocmd lives in a cleared augroup.** Every
>       `nvim_create_autocmd` call in the config passes
>       `group = nvim_create_augroup("<name>", { clear = true })` — including
>       the ones declared inside a plugin spec's `config`/`init` function,
>       which is where this rule is actually broken. Without it, re-sourcing
>       the config or re-running a plugin's `config` registers a second copy
>       of the callback and it fires twice per event; `clear = true` is what
>       makes the registration idempotent. **Live bug L-8, do not reproduce.**
>       Three sites break it live (swept 2026-08-21):
>       `lua/plugins/treesitter.lua:31` (`FileType`),
>       `lua/config/keymaps.lua:58` (`ModeChanged`), and
>       `lua/plugins/editor.lua:80` (`FileType`, vim-table-mode — a third site
>       the backlog's L-8 row does not list). All four autocmds in
>       `lua/config/autocmds.lua` *are* grouped, and so are the ones in
>       `statusline.lua`, `colorscheme.lua` and `lsp.lua`, so a grep for
>       `augroup` finds seven hits and passes falsely — the check has to be
>       per call site, not per file. Binds
>       [`03-autocmds`](03-autocmds/prd.md),
>       [`09-lsp`](09-lsp/prd.md),
>       [`10-treesitter`](10-treesitter/prd.md),
>       [`11-colorscheme`](11-colorscheme/prd.md),
>       [`13-statusline`](13-statusline/prd.md),
>       [`14-shift-select`](14-shift-select/prd.md) and
>       [`15-markdown-tables`](15-markdown-tables/prd.md) — every node that
>       registers an autocmd.

### 2. `03-autocmds` gains R5

Promote its Purpose sentence into a box, because a testable claim living only
in prose is invisible to the scheduler and closes unmet — the reason the tree
was converted at all. Keep the Purpose sentence; R5 is what makes it
enforceable.

> - [ ] **R5** — **Grouped, and cleared.** Each of R1–R4 registers under its
>       own `nvim_create_augroup(<name>, { clear = true })`:
>       `highlight_yank`, `last_loc`, `trim_whitespace`, `close_with_q`. This
>       file is the part of the config that already satisfies the epic's
>       [I7](../prd.md) — it is stated here as a requirement so a later edit
>       cannot quietly drop a `group =` and still pass review. The
>       violations I7 exists for are in the plugin specs, not here.

### 3. Add one acceptance line to `03-autocmds`

> - [ ] `:source $MYVIMRC` twice, then yank: the region flashes once, not
>       three times. (The observable form of R5 — a stacked callback shows up
>       as repeats, not as an error.)

## Acceptance

- [ ] The epic carries an invariant requiring `group =` /
      `clear = true` on every autocmd, and it names L-8.
- [ ] That invariant names all three live violation sites, including
      `editor.lua`.
- [ ] It states why a file-level grep passes falsely.
- [ ] It names the nodes it binds, including `10-treesitter`,
      `14-shift-select` and `15-markdown-tables`.
- [ ] The previously unnumbered `I (from 05-platform/02 req 6)` invariant now
      has a number, and no existing numbered invariant `I1`–`I5` was
      renumbered.
- [ ] `03-autocmds` has an **R5** naming all four augroups.
- [ ] `03-autocmds` R1–R4 keep their numbers and text (R1's text changes in
      spec04, not here).
- [ ] `03-autocmds` has an acceptance line about re-sourcing / stacking.
- [ ] Every box in both files is still open — no `[x]`, no `[~]`.
- [ ] `.mi/prds/00-delivery/corrections/prd.md` and `tests/live-bugs.sh` are
      untouched by this spec.

verify: ""

**Proven RED against the current tree before this spec was written**, run
verbatim as the string above. It reports: the epic has no I7 invariant, then
all ten I7 content clauses on the empty string; the unnumbered
`**I (from` invariant still present; `03-autocmds` has no R5, then its six
content clauses on the empty string; and no acceptance line about
re-sourcing. Exit 1.

The `I1`–`I5` and `R1`–`R4` presence clauses and the box-state clause pass
today — they are regression guards against renumbering, which `AGENTS.md`
forbids because other documents cite requirements by number.

Both files are read whitespace-normalised, and each invariant/requirement is
sliced out with `awk` before matching, so a phrase that straddles the 78-column
wrap still matches and a phrase found in a *different* requirement does not
count as a pass.

## Spent proof

`prds/03-editor/03-autocmds/prd.md` has closed boxes because the autocmds
node has since been implemented; the guard was written to catch a box
closing during this node's own run.

Retired from `verify:` by
[`mi-rooted-verify-commands`](../../../mi-rooted-verify-commands/prd.md)
spec02. The command below is byte-identical to what spec01 left in this
file's `verify:`; it is kept because it is the execution record of a check
that once ran green.

```text
verify: `bash -c 'cd "$(git rev-parse --show-toplevel)"; rc=0; E=prds/03-editor/prd.md; A=prds/03-editor/03-autocmds/prd.md; ue=$(tr "\n" " " < "$E" | tr -s " "); ua=$(tr "\n" " " < "$A" | tr -s " "); inv=$(awk "/\*\*I7\*\*/{r=1} r&&/^- \[.\] \*\*I/&&!/I7/{r=0} r&&/^## /{r=0} r" "$E" | tr "\n" " " | tr -s " "); [ -n "$inv" ] || { echo "FAIL: the epic has no I7 invariant"; rc=1; }; for s in "clear = true" "L-8" "treesitter.lua" "keymaps.lua" "editor.lua" "10-treesitter" "14-shift-select" "15-markdown-tables"; do printf "%s" "$inv" | grep -qF "$s" || { echo "FAIL: epic I7 does not name: $s"; rc=1; }; done; printf "%s" "$inv" | grep -qE "nvim_create_augroup" || { echo "FAIL: epic I7 does not name nvim_create_augroup"; rc=1; }; printf "%s" "$inv" | grep -qE "falsely|false|per call site" || { echo "FAIL: epic I7 does not record why a file-level grep passes falsely"; rc=1; }; printf "%s" "$ue" | grep -qE "\*\*I6\*\* — .{0,40}from .05-platform" || printf "%s" "$ue" | grep -qE "\*\*I6\*\*" || { echo "FAIL: the unnumbered version-floor invariant was not numbered"; rc=1; }; printf "%s" "$ue" | grep -qF "**I (from" && { echo "FAIL: an unnumbered I invariant remains in the epic"; rc=1; }; for i in 1 2 3 4 5; do printf "%s" "$ue" | grep -qF "**I$i**" || { echo "FAIL: epic lost invariant I$i"; rc=1; }; done; r5=$(awk "/\*\*R5\*\*/{r=1} r&&/^- \[.\] \*\*R[0-9]/&&!/R5/{r=0} r&&/^## /{r=0} r" "$A" | tr "\n" " " | tr -s " "); [ -n "$r5" ] || { echo "FAIL: 03-autocmds has no R5"; rc=1; }; for g in highlight_yank last_loc trim_whitespace close_with_q; do printf "%s" "$r5" | grep -qF "$g" || { echo "FAIL: 03-autocmds R5 does not name augroup $g"; rc=1; }; done; printf "%s" "$r5" | grep -qF "clear = true" || { echo "FAIL: 03-autocmds R5 does not require clear = true"; rc=1; }; for i in 1 2 3 4; do printf "%s" "$ua" | grep -qF "**R$i**" || { echo "FAIL: 03-autocmds lost R$i"; rc=1; }; done; acc=$(awk "/^## Acceptance/{r=1;next} r&&/^## /{r=0} r" "$A" | tr "\n" " " | tr -s " "); printf "%s" "$acc" | grep -qE "source|reload|re-source" || { echo "FAIL: 03-autocmds has no acceptance line about re-sourcing"; rc=1; }; for f in "$E" "$A"; do grep -qE "^- \[[x~]\]" "$f" && { echo "FAIL: a box was closed in $f"; rc=1; }; done; [ $rc -eq 0 ] && echo OK; exit $rc'`
```
