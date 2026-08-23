---
est: 0.75h
footprint:
  - prds/00-delivery/parallelization/prd.md
---

# spec01 — the body states the rules; `gates/waves.tsv` and `plan` state the membership

Rewrite the body of [`prd.md`](../prd.md) so it holds the **contract for
concurrent execution** and no copy of computed data. Two systems already own
the membership, and the body owns neither:

| system | answers | source of truth | enforced by |
|---|---|---|---|
| gate waves 0–6 | when does a wave's gate arm | `gates/waves.tsv` rows | `gates/wave-status.sh --validate` |
| plan waves | what may be dispatched concurrently now | every node's `needs:` + `footprint:` | `python3 .claude/skills/pearde/plane/sync.py plan` |

Every number below was **measured 2026-08-23** against the board at commit
`eee74fd` and is quoted so the implementer can re-derive it, not trust it.
[spec02](spec02-drift-check.md) turns the same numbers into a check; write it
after this one, because it parses the tables this spec defines.

## What comes out

Delete the `## Waves` table. It is a hand copy of `gates/waves.tsv` and it has
already drifted on 4 of its 7 rows — measured by comparing the two:

| wave | body says | registry says |
|---|---|---|
| 0 | `W0.1–W0.4` | 22 task ids |
| 2 | 4 tasks | 5 (`D.2` absent from the body) |
| 4 | 15 tasks | 18 (`S.9`, `T.6`, `T.7`, `D.3` absent) |
| 6 | `H.4, H.5, full-system gate` | `H.4 H.5 H.1c` |

Delete the per-wave **Agents** column with it. Its values run to 12 and
`prds/settings.md` sets `workers: 3`, so every cell is wrong by a factor of
four. The registry is also live under other lanes — wave 4 gained two gate
commands while this spec was written — which is exactly why a second copy
cannot hold.

Delete the sentence "Peak concurrency is 12, in waves 3 and 4 — comfortably
inside a 16-agent cap." There is no 16-agent cap.

## What goes in

### The two wave systems

State the table above. State that gate-wave rows are a **gate-arming set, not
a dispatch set**: a row legitimately contains tasks that wrote the same file
at different times, because `wave-status.sh` reads it to decide when a gate
arms, and a finished task is not a writer any more.

### The agent count

State it as a derivation, never a literal:

- The cap is `workers:` in `prds/settings.md` — currently 3.
- `plan` prints two different numbers per wave and they are not the same
  thing: `N in parallel` is **wave membership**, `workers=M` is the cap. Wave
  membership routinely exceeds the cap — measured 2026-08-23: wave 1 held 41
  members at `workers=3`. The scheduler packs the members onto `M` slots; the
  agent count for a wave is therefore `min(N, M)`.
- Anyone reading `41 in parallel` as "41 agents" has misread the line. Say so.

### Three classes of contended path

This is the section that replaces the current three-row exception table, whose
`plugins/editor.lua` row is stale: E.11, E.12 and E.15 were split into
`conform.lua`, `gitsigns.lua`/`which-key.lua`/`autopairs.lua` and
`table-mode.lua`, so no such clash exists on the board.

Write the classes as a definition list, then the declared-exception table:

1. **Exclusive content file** — one writer at a time, full stop. Two live
   tasks whose footprints meet here is a defect.
2. **Shared append-only registry** — many tasks each add their own rows, and
   concurrent appends are the intended use. Measured writer counts:
   `gates/waves.tsv` 11, `tests/nvim-options.sh` 10,
   `home/dot_config/nvim/lazy-lock.json` 9, `gates/manual/wave4.md` 6,
   `gates/manual/wave3.md` 4, and each file under
   `home/dot_config/nushell/help/`. Enumerate exactly these path patterns —
   the check reads the list. 37 of the board's 42 intra-wave footprint
   overlaps are on this class alone; serialising them by wave would put the
   most parallel track in the build into single file.
3. **Non-file exclusive resource** — no path, so no footprint can express it
   and the planner cannot separate it. Three exist: the live `$HOME` under
   `chezmoi apply`, a GUI WezTerm session (`gates/manual/wave4.md` boxes need
   one), and a capsule rebuild loop. Rule: one actor, at a gate, never inside
   a wave; `isolation: "worktree"` is for these and nothing else.

Then the exception table — the only place in the body a task id may appear
outside the adversarial-verify list:

| path | class | tasks | rule |
|---|---|---|---|
| `home/dot_config/nvim/init.lua` | ordered | E.3 E.4 | E.4 landed first; E.3 appends |
| `home/dot_config/wezterm/wezterm.lua` | ordered | T.6 T.7 C.4 | T.6 then T.7; C.4 appends last |
| `home/dot_config/nushell/capsule.nu` | ordered | C.3 C.4 | C.3 then C.4 |

Those are the board's five exclusive-content overlaps, measured. State that
**zero of them are live-vs-live today** — one side of every pair is `done` —
and that the rule binds any future pair.

### The planner's readable-input contract

The planner reads data, never prose — and never the key this repo's PRDs
actually use. Measured:

- `sync.py` reads `needs:` at line 1128. It reads `deps:` **nowhere**, and
  neither does any other file in `.claude/skills/pearde/`. 40 undone nodes
  declare their graph in `deps:`, so 40 dependency edges are invisible and the
  only ordering `plan` honours today is the implicit parent-after-children
  one.
- `parse_prd` parses block lists only. An inline `needs: [a, b]` becomes the
  single string `[a, b]` and fails lookup — both undone nodes using that form
  produce a `no such PRD, ignored` warning on every `plan` run.
- An inline `footprint: [a, b]` becomes one bogus path that overlaps nothing.
  Measured: `03-editor/02-keymaps` and `03-editor/12-small-plugins` both write
  `gates/waves.tsv`, and `overlap()` on their parsed footprints returns
  `False`. The fix recorded in
  [`a-prose-footprint-is-invisible-to-the-planner`](../../../memos/a-prose-footprint-is-invisible-to-the-planner.md)
  wrote that footprint in inline form, so the clash it was written to expose is
  still invisible; what actually moved `15-markdown-tables` out of wave 1 was
  its own block-form footprint clashing with `12-small-plugins`. Link the memo
  and say this plainly — it is the same instrument defect one level down.
- 53 of the 70 registry tasks have no readable footprint at all. `(unspecced)`
  in a `plan` listing means "no footprint readable", which is not "no specs".

State the rule in one line: **a node's graph goes in `needs:`, its paths in
`footprint:`, both as block lists, on `prd.md` or a spec — anything else is
documentation the planner cannot read.**

### Dispatch order is not the printed order

`plan` sorts within a wave by `priority`. Corrections hold p43–p8 and port
nodes hold p0–p14, so the printed order puts derived work first — the opposite
of the policy in
[`port-first-over-derived-findings`](../../../memos/port-first-over-derived-findings.md).
State that the wave layout says what *may* run together and the port-first
rule says what *takes the slots*, and that the printed order is neither.

### Keep, unchanged in substance

`## The property that makes this cheap`, the fan-out patterns, and the five
rules for concurrent agents all stay. Two edits inside them:

- Re-derive the "no fan-out for Track S" claim or drop it — Track S is now
  almost entirely `done` and `config.nu` no longer appears in any live
  footprint overlap.
- Name the three adversarial-verify tasks by **node path as well as task id**,
  because the id is not the spec: E.14 = `03-editor/14-shift-select` (`open`),
  S.4 = `04-shell/03-zoxide` (`done`), H.2 = `06-help/02-help-command`
  (`done`). Only E.14 is still owed.

## Acceptance

- [ ] `prd.md` contains no `## Waves` section and no per-wave Agents column.
- [ ] `prd.md` contains no literal integer presented as a wave's agent count;
      the cap is named as `workers:` in `prds/settings.md`.
- [ ] `prd.md` states the membership-vs-cap distinction and gives the
      `min(N, M)` derivation.
- [ ] `prd.md` defines exactly three contended-path classes and enumerates the
      shared append-only registry paths as patterns a check can read.
- [ ] The declared-exception table has one row per exclusive-content overlap
      on the board, each naming the path, the class `ordered`, its tasks, and
      the order.
- [ ] `prd.md` states that `sync.py` reads `needs:` and not `deps:`, and that
      inline `[...]` lists are unreadable, each with its measured consequence.
- [ ] `prd.md` names the three adversarial-verify tasks by node path and task
      id, with the state of each.
- [ ] `prd.md` states that the printed intra-wave order is not the dispatch
      order, and links the port-first memo.
- [ ] No task id appears in `prd.md` outside the exception table and the
      adversarial-verify list.
- [ ] Wrapped at ~78 columns; tables exempt. No `deps:`/`needs:`/`state:`
      frontmatter key is edited — the orchestrator owns those.

## Verify and Proof

```sh
# the body no longer copies the registry
! grep -qE '^## Waves' prds/00-delivery/parallelization/prd.md

# the cap is named, not copied
grep -q 'prds/settings.md' prds/00-delivery/parallelization/prd.md
grep -q 'workers' prds/00-delivery/parallelization/prd.md

# the three classes and the three adversarial nodes are named by path
grep -q 'shared append-only registry' prds/00-delivery/parallelization/prd.md
for n in 03-editor/14-shift-select 04-shell/03-zoxide 06-help/02-help-command; do
  grep -q "$n" prds/00-delivery/parallelization/prd.md || { echo "missing $n"; exit 1; }
done

# the planner's real key, stated
grep -q 'needs:' prds/00-delivery/parallelization/prd.md
grep -q 'deps:'  prds/00-delivery/parallelization/prd.md

# re-derive the drift this spec deletes, so the deletion is justified on the run
python3 .claude/skills/pearde/plane/sync.py plan | head -3
awk -F'\t' '!/^#/ && NF>=2 && $1!="wave" && $1!="" {print $1, NF, split($2,a," ")}' gates/waves.tsv
```
