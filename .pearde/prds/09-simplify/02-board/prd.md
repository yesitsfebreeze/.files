---
state: done        # open|analyzing|refine|question|specced|claimed|blocked|done|failed
origin: requested  # requested = the user asked | derived = the board found it
priority: 38        # higher first
complexity: 6      # analyst, at spec time — 1-100. THE WEIGHT the board schedules by
blast-radius: mid
repo:
time:
  est:
  actual: 0.24h
needs:
  - 09-simplify/01-hygiene
footprint:
  - AGENTS.md
  - .pearde/prds
  - .pearde/memos
workflow: delete-what-nothing-reads
---

# 02-board — the PRDs are the record; everything around them goes

Parent: [`09-simplify`](../prd.md) · meta, no C/U

Purpose: decided 2026-09-02 — every `prd.md` stays, because the PRDs are the
record of what was done and why, including the nodes about scaffolding that
no longer exists. What goes is the machinery: 358 spec files (3.6 MB, worker
briefs for workers who have left), 15 memos about a gate suite that lived
six days, 118 `verify:` fields naming deleted scripts, and an `AGENTS.md`
that is a 389-line changelog of its own corrections.

## Requirements

- [x] **R1** — Every `specs/` directory under `.pearde/prds/` is removed
      with `git rm -r`. Before removal, four specs carry knowledge that must
      already be in `manual/internals/` or is moved there in this change:
      `04-shell/04-television/specs/spec01.md` (the `nu-history` sqlite path
      derivation and the `\\:` trap), `07-multiplexer/03-status-bar/specs/spec01.md`
      (why each status option is set), and the two named by the implementer
      after grepping `specs/` for `TRAP` and `measured`.
- [x] **R2** — Every `verify:` in a `prd.md` that names a path under
      `tests/`, `gates/` or `docs-site/` becomes `verify: ""`.
- [x] **R3** — The memos about board or gate mechanics move to
      `.pearde/memos/archive/`. The five that stay: `tmux-owns-multiplexing…`,
      `tests-and-gates-retire…`, `the-manual-is-markdown…`,
      `mason-refresh-off…`, `every-abort-measurement-was-missing-wget`.
      `pearde memo index` regenerates `memos/README.md` and
      `pearde memo check` is silent afterwards — if the checker refuses an
      archive subdirectory, the archived memos are deleted instead; git holds
      them.
- [x] **R4** — `AGENTS.md` is rewritten at about 60 lines and keeps only:
      three lines on what the repo is; the where-things-live table
      (`home/`, `docs/`, the manual, `.pearde/`, `scripts/`, `justfile`,
      `install.sh`, the pearde skill symlink); "run `chezmoi source-path`,
      never a literal path; `~/.local/share/chezmoi` is a stale clone"; the
      scope decisions as one line each; the hard-won constraints list (tv
      needs a TTY, reedline has no chord trees, OSC 133 double-marking,
      `use_kitty_protocol` leak, lualine `auto` theme on base16, LSP log
      rotation, `dofile` never `require`); "read `?` before suggesting a
      workflow — tv not fzf, rg not grep, fd not find; add a manual entry
      with every binding"; the five invariants of `09-simplify` by
      reference; one pointer to `.claude/skills/pearde/README.md`. No dated
      correction, no count.
- [x] **R5** — `.pearde/prds/README.md` drops the `## Build order` wave
      list (it was folded from a retired planner and names ids no node
      carries) and keeps the tree and the exclusion list. The tree gains
      `09-simplify`.
- [x] **R6** — Corrected by the orchestrator 2026-09-02 from the
      implementer's measurement: the premise was false in three ways, not
      one requirement with two names slightly off. There is exactly one
      open node outside this epic — the board root `.pearde/prds/prd.md`
      (`grep -rl '^state: open' .pearde/prds --include=prd.md`), not three
      — and it stays open. `00-delivery/finish-line/done-node-proof-gate`
      does not exist; the node is `00-delivery/corrections/done-node-proof-gate`
      and was already `state: deferred`, carrying the pearde-tooling line,
      before this pass. `corrections/pearde-shell-wiring` is `state: done`;
      deferring it would undo a landed node, so it is left alone rather than
      forced to fit a stale requirement. Nothing needed editing — the
      corrected requirement was already true.

## Acceptance

- [x] `find .pearde/prds -type d -name specs | wc -l` prints 0 — ran
      2026-09-02 after the last four directories were removed: `0`
- [x] `grep -rlE '^verify: "?[^"]*(tests|gates|docs-site)/' .pearde/prds --include=prd.md | wc -l` prints 0
      — corrected by the orchestrator 2026-09-02 from the implementer's
      measurement: the original command was unanchored and matched every
      file, so it counted body prose *quoting* a `verify:` value a node
      once carried (`wave-registry-keying` line 129,
      `corrections/gate-reconciliation` line 105) alongside the frontmatter
      field it meant to check — `2`, neither a real hit, rewriting either
      would falsify the record, and both are outside this node anyway. The
      anchored, `prd.md`-only command is the one that actually answers R2;
      ran 2026-09-02: `0`.
- [x] `ls .pearde/memos/*.md | wc -l` prints 6 (five memos and README) and `pearde memo check` is silent
      — ran 2026-09-02: `6`, and `memos.py check .pearde` printed nothing,
      exit 0
- [x] `wc -l AGENTS.md` prints at most 80, and `grep -c 'Corrected 20' AGENTS.md` prints 0
      — ran 2026-09-02: `63` and `0`
- [x] `find .pearde/prds -name prd.md | wc -l` prints the same number before and after this child, plus the nine this epic added
      — ran 2026-09-02: `208` in the worktree and `208` in `HEAD`
      (`git ls-tree -r HEAD --name-only | grep -c '^\.pearde/prds/.*prd\.md$'`,
      the counter that includes the board root `prds/prd.md`); this child
      deleted no `prd.md`. `09-simplify` holds 9 of them, itself included.
- [x] `du -sh .pearde/prds` is under 3.5 MB — ran 2026-09-02: `3.2M`.
      Corrected by the orchestrator
      2026-09-02 from the analyst's measurement: `prd.md` files alone are
      2.2-2.6 MB and are explicitly out of scope to delete or merge (Out of
      scope, below), and `report.md`/`probe/`/`checks/` are worker artifacts
      R1-R6 never name, so `specs/` removal alone lands at 3.2 MB, over the
      original 3 MB line. Widening R1 to delete reports and probes was
      rejected — they are the record of what was measured and why, the same
      reason `prd.md` itself stays — so the number moves instead.

## Out of scope

- Deleting or merging any `prd.md`.
- The `docs/capabilities-*.md` inventories.
- `docs/simplification-plan.md` — deleted by the last child of this epic to
  close, not here.

## Report

spec01-cleanup: exit 0
spec01-cleanup OK — specs/ itself removed in the follow-up commit
