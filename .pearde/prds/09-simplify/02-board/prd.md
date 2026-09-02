---
state: open        # open|analyzing|refine|question|specced|claimed|blocked|done|failed
origin: requested  # requested = the user asked | derived = the board found it
priority: 38        # higher first
complexity: 0      # analyst, at spec time — 1-100. THE WEIGHT the board schedules by
blast-radius: mid
repo:
time:
  est:
  actual:
needs:
  - 09-simplify/01-hygiene
footprint:
  - AGENTS.md
  - .pearde/prds
  - .pearde/memos
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

- [ ] **R1** — Every `specs/` directory under `.pearde/prds/` is removed
      with `git rm -r`. Before removal, four specs carry knowledge that must
      already be in `manual/internals/` or is moved there in this change:
      `04-shell/04-television/specs/spec01.md` (the `nu-history` sqlite path
      derivation and the `\\:` trap), `07-multiplexer/03-status-bar/specs/spec01.md`
      (why each status option is set), and the two named by the implementer
      after grepping `specs/` for `TRAP` and `measured`.
- [ ] **R2** — Every `verify:` in a `prd.md` that names a path under
      `tests/`, `gates/` or `docs-site/` becomes `verify: ""`.
- [ ] **R3** — The memos about board or gate mechanics move to
      `.pearde/memos/archive/`. The five that stay: `tmux-owns-multiplexing…`,
      `tests-and-gates-retire…`, `the-manual-is-markdown…`,
      `mason-refresh-off…`, `every-abort-measurement-was-missing-wget`.
      `pearde memo index` regenerates `memos/README.md` and
      `pearde memo check` is silent afterwards — if the checker refuses an
      archive subdirectory, the archived memos are deleted instead; git holds
      them.
- [ ] **R4** — `AGENTS.md` is rewritten at about 60 lines and keeps only:
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
- [ ] **R5** — `.pearde/prds/README.md` drops the `## Build order` wave
      list (it was folded from a retired planner and names ids no node
      carries) and keeps the tree and the exclusion list. The tree gains
      `09-simplify`.
- [ ] **R6** — The three open nodes outside this epic stay open.
      `00-delivery/finish-line/done-node-proof-gate` and the pearde-shell
      node are about the pearde tooling; each gets one line in its body
      saying so, and `state: deferred`.

## Acceptance

- [ ] `find .pearde/prds -type d -name specs | wc -l` prints 0
- [ ] `grep -rlE 'verify: "?[^"]*(tests|gates|docs-site)/' .pearde/prds | wc -l` prints 0
- [ ] `ls .pearde/memos/*.md | wc -l` prints 6 (five memos and README) and `pearde memo check` is silent
- [ ] `wc -l AGENTS.md` prints at most 80, and `grep -c 'Corrected 20' AGENTS.md` prints 0
- [ ] `find .pearde/prds -name prd.md | wc -l` prints the same number before and after this child, plus the nine this epic added
- [ ] `du -sh .pearde/prds` is under 3 MB

## Out of scope

- Deleting or merging any `prd.md`.
- The `docs/capabilities-*.md` inventories.
- `docs/simplification-plan.md` — deleted by the last child of this epic to
  close, not here.
