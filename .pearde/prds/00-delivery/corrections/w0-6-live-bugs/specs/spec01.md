verify: "bash tests/live-bugs.sh"

# spec01 — give every `L-*` row an owner column

Closes **R4** and the first half of acceptance line 2 ("every `L-*` row names
the node that owns its fix").

## Why this is in footprint

`.mi/gantt/plan.json` lists exactly one file for task W0.6:
`.mi/prds/00-delivery/corrections/prd.md`. This node **owns** the backlog
file. The earlier pass recorded R4 as unmeetable because "adding a column is a
write to another node's file" — that reading was wrong. The three decision
nodes that share the file (`D.1b`, `D.1c`, `D.1d`) all carry `W0.6` in their
`deps`, so they land *after* this node, not concurrently with it.

## Files touched

- `.mi/prds/00-delivery/corrections/prd.md` — the `## S2 — bugs in the live
  config (do not reproduce these)` table only (currently lines ~119–132).
  Nothing else in the file changes.

## What to write

Change the table header from

```
| # | Finding |
|---|---|
```

to a three-column form:

```
| # | Owner — must not reproduce it | Finding |
|---|---|---|
```

and fill the Owner cell of each of the twelve rows from the mapping below.
Every node path was checked to exist (`<path>/prd.md` present) on 2026-08-21.
Where a `w0-4-s2-corrections/*` requirement already carries the bug, name it
in the cell so the reader can jump straight to the correcting requirement —
each of those was verified present, by number, in the sibling PRD.

| # | Owner cell content |
|---|---|
| L-1 | `04-shell/06-listing` — carried by `w0-4-s2-corrections/shell` R3 |
| L-2 | `04-shell/04-television`, `04-shell/01-core-config` — carried by `w0-4-s2-corrections/shell` R7 |
| L-3 | `04-shell/04-television`, `04-shell/01-core-config` — carried by `w0-4-s2-corrections/shell` R1 |
| L-4 | `04-shell/07-quicklist` — carried by `w0-4-s2-corrections/shell` R2 |
| L-5 | none — `DO NOT PORT`; accepted-with-reason in `.mi/docs/capabilities-nushell.md` |
| L-6 | `03-editor/01-options`, `03-editor/02-keymaps` — carried by `w0-4-s2-corrections/editor` R3 |
| L-7 | `03-editor/06-explorer` — carried by `w0-4-s2-corrections/editor` R6 |
| L-8 | `03-editor/03-autocmds`, `03-editor/10-treesitter`, `03-editor/14-shift-select` — carried by `w0-4-s2-corrections/editor` R1 |
| L-9 | `03-editor/02-keymaps`, `03-editor/14-shift-select` — carried by `w0-4-s2-corrections/editor` R7 |
| L-10 | `03-editor/12-small-plugins` — carried by `w0-4-s2-corrections/editor` R2 |
| L-11 | `02-terminal/03-f5-jump-mode` — to be carried by `w0-2-terminal-respec`, which lists this node in its `deps` |
| L-12 | `05-platform/01-deploy-mechanism/managed-config` — carried by `w0-4-s2-corrections/platform` R4 |

L-11 is the only row whose owning node does not yet carry a requirement for
it. `w0-2-terminal-respec` is `state: open` and has
`00-delivery/corrections/w0-6-live-bugs` in its `deps`, so it reads this table
before it writes; the record in `.mi/docs/capabilities-terminal.md` ("Live bug
L-11, do not reproduce") is the second path to it. Do **not** edit
`w0-2-terminal-respec/prd.md` — it is another node's file.

Add one sentence under the section's existing lead-in ("The PRDs documented
these as working behavior. They are not.") saying what the Owner column means:
the node whose PRD must not reproduce the bug, and that `none` means the
capability is not being ported and the reason is recorded in the inventory.

## Acceptance

- [x] The S2 live-bug table has three columns; its header row reads
      `| # | Owner — must not reproduce it | Finding |`.
- [x] Each of `L-1` … `L-12` appears exactly once as a row id, and each row's
      Owner cell is non-empty after whitespace is stripped.
- [x] Every node path named in an Owner cell resolves to an existing
      `.mi/prds/<path>/prd.md`.
- [x] Every `w0-4-s2-corrections/<child> R<n>` reference in an Owner cell
      resolves: that child's `prd.md` contains a `**R<n>**` line, and that line
      names the same `L-` id.
- [x] The `L-5` row's Owner cell says `none` and points at
      `.mi/docs/capabilities-nushell.md`.
- [x] The `L-11` row's Owner cell names both `02-terminal/03-f5-jump-mode` and
      `w0-2-terminal-respec`.
- [x] No file outside `.mi/prds/00-delivery/corrections/prd.md` is modified by
      this spec.
- [x] `bash tests/live-bugs.sh` exits 0 (with spec03's strengthened
      assertions in place).
