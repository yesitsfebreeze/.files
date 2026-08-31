verify: "bash tests/live-bugs.sh"

# spec03 — make the ticket's own verify prove the table, the routing, and all twelve bugs

Closes the check side of **R1**'s recorded caveat, gives **R4** and **R2** a
real gate, and closes the three live-config bugs the script does not currently
touch.

## Why

`tests/live-bugs.sh` is this node's `verify:`. Today it proves nine of the
twelve rows against the live config (L-2, L-3, L-4, L-5, L-6, L-7, L-9, L-11,
L-12, plus L-13) and proves the table only by
`[ "$n" = 12 ]` on `grep -cE '^\| *L-[0-9]+'`. R1 records the weakness in its
own box: that count matches row *shape*, not identity or contents, so emptying
a cell or renumbering a row still passes, and promoting L-13 into the table
would report STALE for a correct change.

**L-1 is not checked at all** — the first bug `AGENTS.md` names. Neither are
L-8 and L-10. Verified live on 2026-08-21, all three still hold:

- **L-1** — `~/.config/nushell/config.nu:93` is `^du -sb ...$dirs e> /dev/null`.
  `/usr/bin/du -sb /tmp` exits **64** with `du: invalid option -- b`, and the
  `e>` redirect swallows it, so directory sizes silently stay inode sizes.
- **L-8** — `~/.config/nvim/lua/plugins/treesitter.lua:31`
  `nvim_create_autocmd("FileType", …)` and
  `~/.config/nvim/lua/config/keymaps.lua:58`
  `nvim_create_autocmd("ModeChanged", …)` both take no `group =`, while
  `lua/config/autocmds.lua` groups all four of its autocmds with
  `augroup(…, { clear = true })`.
- **L-10** — `~/.config/nvim/lua/plugins/editor.lua:12–13` are literally
  `delete = { text = "" }` and `topdelete = { text = "" }`; `add`, `change`
  and `changedelete` all carry `▎`.

## Files touched

- `tests/live-bugs.sh` — the only file. No PRD, no inventory.

**Footprint note:** this file is not in W0.6's `files` list in
`.mi/gantt/plan.json`, because W0.6 created it after the plan was written. No
other task in the plan lists it, and it is this node's `verify:`. Touching it
here is in-scope; do not treat that as licence to touch anything else outside
`.mi/prds/00-delivery/corrections/`.

## What to write

Apply after spec01 and spec02, since the new assertions read the three-column
table.

### 1. Replace the hard-coded row count with a per-id integrity loop

Delete `n=$(grep -cE …); [ "$n" = 12 ]`. In its place, for each id `L-1` …
`L-12`:

- the row matching `^\| *L-<n> *\|` occurs exactly once;
- splitting that row on `|` yields an Owner cell and a Finding cell that are
  both non-empty once whitespace is stripped.

Then assert separately that the table holds no id outside `L-1`…`L-12` — so a
future L-13 promotion fails loudly on one line that says which id is
unaccounted for, rather than reporting a stale count. Renumbering, emptying a
cell, or dropping a row must each produce a FAIL naming the id.

### 2. Assert the routing (R4 / R2's routing arm)

For every Owner cell:

- each `NN-epic/NN-node` path named resolves to an existing
  `.mi/prds/<path>/prd.md`;
- each `w0-4-s2-corrections/<child> R<n>` reference resolves — that child's
  `prd.md` has a line matching `\*\*R<n>\*\*` and that line contains the same
  `L-<id>`;
- the one row whose Owner is `none` (L-5) names an inventory file that exists
  and that contains a record for that id.

`L-11` names `w0-2-terminal-respec`, whose PRD does not yet carry the bug.
Assert only that the node directory exists and that
`.mi/docs/capabilities-terminal.md` contains `Live bug L-11` — the second path
to it. Do not assert a requirement number for L-11; W0.2 has not run.

### 3. Add the three missing live-config checks

New sections in the script's existing style, so all twelve rows are pinned:

- `L-1` — `config.nu` still calls `^du -sb`; the call still discards stderr
  with `e>`; and `/usr/bin/du -sb` on a real directory exits non-zero on this
  host, proving `-b` is unsupported. Guard the third assertion so a
  GNU-coreutils `du` earlier on `PATH` cannot make it pass by accident: invoke
  `/usr/bin/du` by absolute path.
- `L-8` — the `FileType` autocmd in `lua/plugins/treesitter.lua` and the
  `ModeChanged` autocmd in `lua/config/keymaps.lua` each have no `group =` in
  their option table (read the few lines following the
  `nvim_create_autocmd(` call, not the whole file — `lua/config/autocmds.lua`
  does group its autocmds and must not be what satisfies the grep).
- `L-10` — `delete` and `topdelete` are the empty string under
  `lua/plugins/`, while `add` and `change` carry a glyph. Compare against the
  glyph rows so a font-rendering accident in the checking terminal cannot
  make an empty string look correct.

### 4. Assert the L-6 / L-9 rows are answers, not questions

In the existing `L-6` and `L-9` sections, add a doc-side assertion that the
backlog row now contains `Decided 2026-08-21`, and that the table contains no
row matching `Intentional\?|Port one or the other|Record it either way`.

Do **not** weaken the existing `grep -q 'Live bug L-6, resolved'` inventory
assertions; the ticket's own `## Findings` calls them near-circular, and the
new row-side assertion is what makes the pair non-circular.

### 5. Keep the script's contract

Read-only against `~/.config` and the chezmoi source; `SKIP` (not FAIL) when
`$SRC` is absent; PASS/FAIL lines labelled so the reader can tell a live-config
drift from a doc edit; exit 0 clean, 1 stale.

## Acceptance

- [x] `bash tests/live-bugs.sh` exits 0 on a clean tree and prints no `FAIL`.
- [x] The script contains a live-config assertion for every one of `L-1` …
      `L-12` — checked by confirming each id appears in a section header and
      in at least one non-doc assertion.
- [x] `grep -c 'n = 12\|"$n" = 12' tests/live-bugs.sh` returns 0 — the
      hard-coded count is gone.
- [x] Blanking the Owner cell of any one row in the backlog makes the script
      exit 1 with a FAIL naming that id. Demonstrated on at least one row and
      reverted.
- [x] Renumbering `L-7` to `L-14` in the backlog makes the script exit 1 with
      a FAIL naming both the missing `L-7` and the unaccounted `L-14`.
      Demonstrated and reverted.
- [x] Pointing an Owner cell at a node path that does not exist makes the
      script exit 1. Demonstrated and reverted.
- [x] Reverting `delete = { text = "" }` in the live config would flip the
      L-10 assertion — verified by running the assertion's grep against a copy
      with a glyph substituted, not by editing `~/.config`.
- [x] The script writes nothing: `bash tests/live-bugs.sh` leaves
      `git status --porcelain` and `~/.config` byte-identical.
- [x] No file outside `tests/live-bugs.sh` is modified by this spec.
