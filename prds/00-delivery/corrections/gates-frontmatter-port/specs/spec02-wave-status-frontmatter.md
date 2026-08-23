# spec02 — wave-status reads the board's frontmatter, not plan.json

Replace `gates/wave-status.sh`'s plan.json reads with the board itself:
task→node from each node's `task:` frontmatter, state from `state:`. Update
`gates/waves.tsv` for the tasks and gates that exist now. Requires spec01
(lib.sh).

**Est:** 2.5h

**Footprint:** `gates/wave-status.sh`, `gates/waves.tsv`

## The successor data source

`.mi/gantt/plan.json` has no successor file. The schedule was folded into
node frontmatter: 45 nodes carry `task: <id>` (verified 2026-08-22, every
waves.tsv id resolves; `kind: epic`/`kind: doc` nodes carry none). The
board is the plan.

## Changes

### `gates/wave-status.sh`

1. Replace `PLAN`/`--plan` with `BOARD`, default `$ROOT/prds`, overridable
   as `--board <dir>` for scratch boards. Update the usage string.
2. `plan_pairs` becomes `board_pairs`: emit `id<TAB>node` for every
   `prds/**/prd.md` whose frontmatter carries `task:`; the node is the path
   between the board root and `/prd.md`. `node_of` and `plan_ids` (rename
   `board_ids`) read from it. Frontmatter only — stop at the closing `---`,
   the same discipline `node_state` already has.
3. `node_state` reads `$BOARD/$node/prd.md`.
4. `validate` keeps its five checks re-pointed at the board, and gains one
   that plan.json's structure used to guarantee implicitly: **no two nodes
   carry the same `task:`** — red naming both nodes. (Zero duplicates today,
   verified 2026-08-22.)
5. Matrix footer and every comment: `plan.json` → the frontmatter wording.
   The header's ARMED/PENDING contract, the empty-gates-cell rule and the
   `external` rule are unchanged — this port must not weaken them.
6. `selftest()` rework:
   - All counterfactuals drive `--registry` and `--board` at scratch copies;
     nothing writes the real registry or board.
   - The planted-task case (`Z.99`) becomes a scratch board copy plus one
     extra node dir whose `prd.md` says `task: Z.99`, registered in no wave
     row → validate red. Add the inverse for check 4: a scratch board where
     two nodes carry the same `task:` → validate red.
   - The arming counterfactuals stop leaning on live node states (they used
     W0.2-open, which is now done — a live state is a moving target). Build
     a synthetic two-node scratch board (`state: done` + `state: open`,
     tasks `X.1`/`X.2`) and synthetic single-wave registries over it:
     ARMED+empty-cell red, ARMED+gate green, ARMED+failing-gate red,
     PENDING resolves PENDING, PENDING+failing-gate reported not fatal.
   - The `norm` counterfactual locates the wrapped `[tv needs a TTY]` link
     in `prds/06-help/prd.md` by `grep -n`, not by hardcoded line numbers.
   - The git-dirty check stays (the guard must not borrow git's opinion);
     its echo names the current reason for the dirt, not the mi rename.

### `gates/waves.tsv`

7. Add `W0.7 W0.8 W0.9` to wave 0's tasks cell (stale-framework-links,
   gate-reconciliation, gate-home-isolation — all `done`; without this, the
   ported validate is red on "task on the board, in no wave row").
8. Register the two gates whose tasks closed without registering them —
   the exact lapse the empty-cell rule exists for:
   wave 3 gains `external bash tests/nushell-core.sh` (S.1, done);
   wave 4 gains `external bash tests/nushell-aliases.sh` (S.2, done).
   Without this, validate is red on "script under tests/ named by no row".
9. Rewrite the header comment: membership follows
   `prds/00-delivery/parallelization/prd.md`'s Waves table; task→node and
   states come from frontmatter. Delete the plan.md/delivery-gantt
   scheduling-wave paragraph — its subject is retired. Keep the gate-command
   format rules and the empty-cell rule verbatim in meaning.

## Acceptance

- [ ] `bash gates/wave-status.sh --matrix` prints all seven waves and exits
      0; wave 0 counts W0.7–W0.9 among its done tasks.
- [ ] `bash gates/wave-status.sh --validate` exits 0 against the live tree.
- [ ] `bash gates/wave-status.sh --selftest` exits 0, with the duplicate-
      `task:` counterfactual and all five arming counterfactuals present as
      `MUTATION:`-annotated checks.
- [ ] No wave resolves ARMED against the live board (W0.5 is not done), so
      `--run` exits 0 with every red reported, none gating — quote the run.
- [ ] `rg -n '\.mi|plan\.json' gates/wave-status.sh gates/waves.tsv` returns
      nothing.

## Verify

```sh
cd "$(git rev-parse --show-toplevel)" \
  && bash gates/wave-status.sh --validate \
  && bash gates/wave-status.sh --selftest \
  && ! rg -q '\.mi|plan\.json' gates/wave-status.sh gates/waves.tsv \
  && echo SPEC02-OK
```
