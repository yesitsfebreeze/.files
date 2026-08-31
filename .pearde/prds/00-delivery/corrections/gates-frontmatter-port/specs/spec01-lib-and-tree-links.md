# spec01 — port lib.sh and the tree link gate to the root layout

Port the shared library and `gates/tree-links.{py,sh}` from the retired
`.mi/` layout to the reconciled tree: board at `prds/`, inventories at
`docs/`, contract at `AGENTS.md` (a real file; `CLAUDE.md` symlinks to it).
This spec goes first: every other gate's `--selftest` runs through
`lib.sh`'s `scratch_tree`.

**Est:** 2.5h

**Footprint:** `gates/lib.sh`, `gates/tree-links.py`, `gates/tree-links.sh`

## Changes

### `gates/lib.sh`

1. `scratch_tree` copies `prds/`, `docs/`, `tests/` and `home/` (each only
   if present) plus every root-level regular file and symlink, instead of
   `.mi/`. `cp -R` copies the `CLAUDE.md` symlink as a symlink; it resolves
   against the copied `AGENTS.md`.
2. Rewrite every comment that names `.mi/`:
   - the header's `scratch_tree` line and the root-files comment inside it
     (the board links out to `AGENTS.md` at the root — that is why root
     files are copied);
   - the `snapshot_paths`/`assert_unchanged` rationale: keep the claim that
     `git diff --quiet` and `git status --porcelain` cannot be the guard,
     state the current reason (the working tree carries staged work no gate
     caused), drop the `.mi/prd -> .mi/prds` story;
   - the deep-hash cost note: re-measure `find prds docs -type f | wc -l`
     and time, quote the new numbers or drop the numbers.
3. Nothing else in `lib.sh` changes: `chk*`, `norm`, the snapshot and
   manifest machinery, the chezmoi guard and the lint are layout-free.

### `gates/tree-links.py`

4. `collect()` Tier A: `prds/**/prd.md` and `prds/**/README.md` (the walk
   already picks both names; `prds/README.md` comes with it),
   `docs/capabilities*.md`, and `AGENTS.md`. Directories named `scratch`
   stay excluded from the walk.
5. `collect()` Tier B: `specs/**` under board nodes only. Drop the
   `.mi/gantt` walk and the `delivery-gantt.md` case — both files are
   retired with no successor.
6. Delete the `.mi/SYSTEM.md` vantage machinery entirely: the special-cased
   `base = root`, the `--system-from` flag, and its report lines. `AGENTS.md`
   is a real file at the root; its links resolve from its own directory like
   any other file. Renegotiated on the record: the vantage counterfactual's
   subject no longer exists; AGENTS.md coverage is proven by a new
   counterfactual instead (change 9).
7. Rewrite the docstring: keep the two-tier contract, the whole-file-text
   matching rationale (~78-column wrap, the per-line silent-pass class), the
   fence rule and the anchor rule. Name the new Tier A set. No `.mi`, no
   SYSTEM.md story.
8. Keep `--per-line`, `--tier`, `--quiet-b`, `--count-only`, `--root`
   unchanged.

### `gates/tree-links.sh`

9. `selftest()` mutations, each located by content (`grep -n`), never by a
   hardcoded line number:
   - NEW — AGENTS.md coverage: append a broken link to the copy's
     `AGENTS.md`, assert Tier A goes red naming `AGENTS.md`; this replaces
     the deleted vantage counterfactual as the proof that the contract file
     is walked.
   - scratch exclusion: plant `prds/00-delivery/scratch/planted.md` with a
     broken link in the copy; assert neither tier moves and the file is
     never named.
   - multi-line: repoint the wrapped `[tv needs a TTY(../../../../../../prds/00-delivery/corrections/gates-frontmatter-port/specs/...)` link in the
     copy's `prds/06-help/prd.md` (it still wraps there, verified
     2026-08-22); assert the whole-text walker reports it and `--per-line`
     reports 0.
   - fences: append the fenced/unfenced pair to the copy's
     `prds/README.md`; same three assertions, including the line number
     surviving fence stripping.
   - green counterfactual: repair every Tier A breakage in the copy, demand
     exit 0.
   - red counterfactual: `rm -rf` the copy's `prds/06-help/04-drift-check`
     (exists, and is Tier-A-linked), demand non-zero.
10. Header comment: drop the `.mi` tier summary pointer text that no longer
    matches; keep the "Python because bash cannot match across lines"
    rationale.

Measured baseline for the ported walker (2026-08-22, this analysis, against
the live tree): Tier A 597 links, 0 broken; Tier B 243 links, 113 broken
(reported, never gating). The gate asserts the mechanism, never these
numbers.

## Acceptance

- [ ] `python3 gates/tree-links.py` exits 0; Tier A reports 0 broken and
      its file set includes `prds/README.md`, `docs/capabilities-nushell.md`
      and `AGENTS.md` (spot-check: each contributes to the file count).
- [ ] `python3 gates/tree-links.py --system-from mi` fails with "unrecognized
      arguments" — the vantage flag is gone.
- [ ] `bash gates/tree-links.sh --selftest` exits 0 and prints one
      `MUTATION:` line per induced case, including the AGENTS.md case and
      both counterfactual directions (green exit 0, red non-zero).
- [ ] `rg -n '\.mi' gates/lib.sh gates/tree-links.py gates/tree-links.sh`
      returns nothing.
- [ ] A scratch_tree copy contains `prds/`, `docs/`, `AGENTS.md` and a
      working `CLAUDE.md` symlink (check inside the selftest output or by
      sourcing lib.sh and calling it).

## Verify

```sh
cd "$(git rev-parse --show-toplevel)" \
  && python3 gates/tree-links.py \
  && bash gates/tree-links.sh --selftest \
  && ! rg -q '\.mi' gates/lib.sh gates/tree-links.py gates/tree-links.sh \
  && echo SPEC01-OK
```
