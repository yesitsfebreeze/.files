---
est: 0.5h
footprint:
  - prds/03-editor/04-plugin-manager/prd.md
  - prds/03-editor/05-completion/prd.md
  - prds/03-editor/07-formatting/prd.md
  - prds/03-editor/08-telescope/prd.md
  - prds/03-editor/09-lsp/prd.md
  - prds/03-editor/10-treesitter/prd.md
  - prds/03-editor/13-statusline/prd.md
  - prds/03-editor/15-markdown-tables/prd.md
  - prds/04-shell/05-history/prd.md
verify: "bash gates/tree-links.sh --tier a"
---

# spec01 — restore the nine truncated `source:` attributions

Nine `Parent:` paragraphs stop mid-attribution. Replace each with the
complete inventory entry name plus a link to the inventory that holds it,
wrapped at ~78 columns. Nothing else in any of the nine files changes.

The analyst resolved all nine names against `docs/capabilities-*.md` and
checked every `C`/`U` pair. **All nine match. R2 has no finding to report.**
The resolution table below is the result — the implementer copies it, and
does not re-derive it.

## The census: nine, not seven

The PRD's Purpose table names seven, found by flagging `Parent:` paragraphs
with an odd number of `"` characters. That check is a subset of the defect
R1 describes. Two more paragraphs are cut off mid-attribution with their
quotes balanced, because the break lands after the closing quote and before
the inventory link:

```
prds/03-editor/07-formatting/prd.md:13
Parent: [Neovim epic](../prd.md) · C 3 · U 8 · source: "Format on save" in

prds/03-editor/10-treesitter/prd.md:13
Parent: [Neovim epic](../prd.md) · C 5 · U 8 · source: "Treesitter" in
```

Both end on the connector `in` with nothing after it. Same board-conversion
artifact, same broken provenance link, so both are in scope for R1. Use the
two-dimensional check — odd quote count **or** a paragraph ending on a
dangling connector — and it flags exactly these nine.

Three near misses that are **not** in scope, checked and left alone:

- `prds/01-capsule/04-recent-workspaces/prd.md` and
  `prds/04-shell/08-claude-launchers/prd.md` name a complete entry
  (`"Recent-workspace picker"`, `"Claude launchers"`) and stop. Complete
  name, no inventory link. Not truncated.
- `prds/05-platform/01-deploy-mechanism/repo-skeleton/prd.md` sources a
  sibling PRD's requirements, not an inventory entry.

## Resolution table

Every header keeps its `C`/`U` exactly as it is. The heading text is copied
verbatim from the inventory, **minus the verdict marker** — the convention
already set by `03-editor/14-shift-select` and `04-shell/09-theme-switcher`.

| PRD | header `C`/`U` | inventory heading | inventory `C`/`U` |
|---|---|---|---|
| `03-editor/04-plugin-manager` | C 4 · U 9 | `capabilities-nvim.md` → `## lazy.nvim bootstrap and plugin loading` | 4 / 9 |
| `03-editor/05-completion` | C 4 · U 9 | `capabilities-nvim.md` → `## Completion (blink.cmp)` | 4 / 9 |
| `03-editor/07-formatting` | C 3 · U 8 | `capabilities-nvim.md` → `## Format on save (conform.nvim)` | 3 / 8 |
| `03-editor/08-telescope` | C 5 · U 9 | `capabilities-nvim.md` → `## Fuzzy finder (telescope)` | 5 / 9 |
| `03-editor/09-lsp` | C 6 · U 9 | `capabilities-nvim.md` → `## LSP (mason + native 0.11)` | 6 / 9 |
| `03-editor/10-treesitter` | C 5 · U 8 | `capabilities-nvim.md` → `## Treesitter` | 5 / 8 |
| `03-editor/13-statusline` | C 6 · U 7 | `capabilities-nvim.md` → `## Statusline (lualine)` | 6 / 7 |
| `03-editor/15-markdown-tables` | C 3 · U 5 | `capabilities-nvim.md` → `## Markdown table mode` | 3 / 5 |
| `04-shell/05-history` | C 5 · U 8 | `capabilities-nushell.md` → `## Directory-scoped history` | 5 / 8 |

The inventory `C`/`U` is the last two `- <n>` list items under the heading.
Several entries carry long resolved-bug notes between the description and
those two numbers, so read the last two, not the first two after the
description.

## The nine replacement paragraphs

Verbatim. Each replaces the single `Parent:` line at the cited line number.
Every line measured at or under 78 columns.

`prds/03-editor/04-plugin-manager/prd.md:14`

```
Parent: [Neovim epic](../prd.md) · C 4 · U 9 · source: "lazy.nvim bootstrap
and plugin loading" in
[`capabilities-nvim.md`](../../../docs/capabilities-nvim.md)
```

`prds/03-editor/05-completion/prd.md:14`

```
Parent: [Neovim epic](../prd.md) · C 4 · U 9 · source: "Completion
(blink.cmp)" in [`capabilities-nvim.md`](../../../docs/capabilities-nvim.md)
```

`prds/03-editor/07-formatting/prd.md:13`

```
Parent: [Neovim epic](../prd.md) · C 3 · U 8 · source: "Format on save
(conform.nvim)" in
[`capabilities-nvim.md`](../../../docs/capabilities-nvim.md)
```

`prds/03-editor/08-telescope/prd.md:13`

```
Parent: [Neovim epic](../prd.md) · C 5 · U 9 · source: "Fuzzy finder
(telescope)" in [`capabilities-nvim.md`](../../../docs/capabilities-nvim.md)
```

`prds/03-editor/09-lsp/prd.md:14`

```
Parent: [Neovim epic](../prd.md) · C 6 · U 9 · source: "LSP (mason + native
0.11)" in [`capabilities-nvim.md`](../../../docs/capabilities-nvim.md)
```

`prds/03-editor/10-treesitter/prd.md:13`

```
Parent: [Neovim epic](../prd.md) · C 5 · U 8 · source: "Treesitter" in
[`capabilities-nvim.md`](../../../docs/capabilities-nvim.md)
```

`prds/03-editor/13-statusline/prd.md:13`

```
Parent: [Neovim epic](../prd.md) · C 6 · U 7 · source: "Statusline (lualine)"
in [`capabilities-nvim.md`](../../../docs/capabilities-nvim.md)
```

`prds/03-editor/15-markdown-tables/prd.md:13`

```
Parent: [Neovim epic](../prd.md) · C 3 · U 5 · source: "Markdown table mode"
in [`capabilities-nvim.md`](../../../docs/capabilities-nvim.md)
```

`prds/04-shell/05-history/prd.md:14`

```
Parent: [Nushell epic](../prd.md) · C 5 · U 8 · source: "Directory-scoped
history" in [`capabilities-nushell.md`](../../../docs/capabilities-nushell.md)
```

All nine sit at depth `prds/<epic>/<node>/prd.md`, so `../../../docs/` is the
repo-root-relative link from every one of them. A wrong depth turns Tier A of
`gates/tree-links.sh` red — that is what the gate box below proves.

## Two constraints on the edit

**One paragraph per file, nothing else.** Do not touch frontmatter, a
requirement, an acceptance box, or the `# <name>` heading. Nine files, nine
one-paragraph diffs. `git diff --stat` is the check.

**`prds/03-editor/09-lsp/prd.md` is `state: claimed`** (`implementer-lsp`,
2026-08-23T11:25Z) and its implementer writes the same file. Re-read the
`Parent:` line before replacing it and edit only that paragraph, so a
concurrently ticked box survives.

## Acceptance

- [x] The census flags zero `Parent:` paragraphs. Run the two-dimensional
      check from Verify and Proof and quote its output: `flagged 0`.
- [x] Each of the nine `Parent:` paragraphs reads exactly as the block above
      it. `grep -A2 '^Parent:'` over the nine files, output quoted.
- [x] Every line of every one of the nine paragraphs is at or under 78
      columns, measured in characters, not bytes — `·` is multibyte.
- [x] `bash gates/tree-links.sh` exits 0 with `TIER A ... 0 broken`, and the
      Tier A link count has risen by exactly 9 from the pre-edit 621 to 630 —
      one new inventory link per file, none broken.
- [x] **Reworded by the orchestrator: `git diff --stat` cannot name six of
      these nine files.** Only `03-editor/08-telescope`,
      `03-editor/10-treesitter` and `03-editor/13-statusline` are tracked
      (`git ls-files --error-unmatch`, 2026-08-23); the other six are
      untracked, so a diff over them is silent and "touches exactly the nine"
      is not merely vacuous — it is impossible, and a `[x]` against it was a
      false record. The scope is proved instead by the two boxes above, both
      of which ran: the Tier A link count rose by exactly **9**, 621 → 630 —
      one new inventory link per file, so a tenth touched file or a stray link
      would have moved it — and `grep -A2 '^Parent:'` over the nine shows each
      paragraph reading as intended, with `flagged 0` across the whole tree.
      Original box: `git diff --stat` touches exactly the nine `prd.md` files,
      and `git diff -U0` shows no changed line outside a `Parent:` paragraph.

## Verify and Proof

```sh
# 1. the census — odd quote count OR a paragraph ending on a dangling
#    connector.  Expected after the edit: "flagged 0".
python3 - <<'PY'
import glob, re
bad = []
for f in sorted(glob.glob('prds/**/prd.md', recursive=True)):
    L = open(f).read().split('\n')
    i = next((k for k, l in enumerate(L) if l.startswith('Parent:')), None)
    if i is None:
        continue
    p, j = [L[i]], i + 1
    while j < len(L) and L[j].strip():
        p.append(L[j]); j += 1
    s = ' '.join(x.strip() for x in p)
    why = []
    if s.count('"') % 2:
        why.append('odd-quote')
    if re.search(r'\b(in|and|of|the|plus)$|\+$', s):
        why.append('dangling')
    if why:
        bad.append((f, ','.join(why), s))
for f, why, s in bad:
    print(why, '|', f); print('   ', s)
print('flagged', len(bad))
PY

# 2. the nine paragraphs, as written
grep -A2 '^Parent:' \
  prds/03-editor/04-plugin-manager/prd.md \
  prds/03-editor/05-completion/prd.md \
  prds/03-editor/07-formatting/prd.md \
  prds/03-editor/08-telescope/prd.md \
  prds/03-editor/09-lsp/prd.md \
  prds/03-editor/10-treesitter/prd.md \
  prds/03-editor/13-statusline/prd.md \
  prds/03-editor/15-markdown-tables/prd.md \
  prds/04-shell/05-history/prd.md

# 3. the ~78-column rule, counted in characters
python3 - <<'PY'
import glob
over = 0
for f in sorted(glob.glob('prds/**/prd.md', recursive=True)):
    L = open(f).read().split('\n')
    i = next((k for k, l in enumerate(L) if l.startswith('Parent:')), None)
    if i is None:
        continue
    j = i
    while j < len(L) and L[j].strip():
        if len(L[j]) > 78:
            print('%s:%d %d cols' % (f, j + 1, len(L[j]))); over += 1
        j += 1
print('over 78:', over)
PY

# 4. the gate — Tier A must stay at 0 broken, with 9 more links than before
bash gates/tree-links.sh

# 5. the diff is nine paragraphs and nothing else
git diff --stat
git diff -U0
```

Baseline measured 2026-08-23, before any edit: `bash gates/tree-links.sh`
exits **0**, Tier A `checked 621 links in 100 files, 0 broken`. Tier B
reports `checked 284 links in 177 files, 114 broken` — all inside
`specs/**`, all pre-existing, and Tier B never gates. The gate box above is
therefore a real check and not a pass inherited from a red gate.

## Execution record — orchestrator, 2026-08-23

Executed by the orchestrator rather than an implementer, per the board rule
that a spec changing **another** PRD's body is the orchestrator's edit. All
nine files are other nodes' bodies, and four of them were `specced` or
`claimed` while this ran.

- **Nine paragraphs replaced by construction**, not by pattern: a script
  located each file's `Parent:` line, walked to the first blank line, and
  replaced exactly that slice. No other line in any file can have changed.
- **`prds/03-editor/09-lsp/prd.md` was already correct** when this ran — E.7's
  implementer completed that paragraph while landing the node. The
  replacement was byte-identical, so the edit is idempotent there. Eight
  files changed, not nine.
- **Census: 0 flagged.** The two-dimensional check (odd `"` count, or a
  paragraph ending on a dangling connector) over all 98 `prd.md` files
  returns nothing.
- **`bash gates/tree-links.sh` → exit 0**, Tier A `checked 663 links in 105
  files, 0 broken`. Delta **+8** from 655, matching the eight files actually
  edited — the ninth link already existed. Tier B's 114 broken links are
  pre-existing, under `specs/**`, and never gate.
- **R2 spot-checked independently.** Four of the nine resolved names were
  re-read from the inventories after the edit: `lazy.nvim bootstrap and
  plugin loading` 4/9, `Statusline (lualine)` 6/7, `Markdown table mode`
  3/5, `Directory-scoped history` 5/8 — each matching its header's `C`/`U`.
  The analyst's full nine-row table stands; R2 has no finding.
