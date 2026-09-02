---
atomic: write-a-proof-not-a-build-script
subject: run twice, exit 0 twice, nothing staged — the form the last run got wrong and that blocked a collect
date: 2026-09-02
updated: 2026-09-02
runs: 2
---

## Do

1. Assert the post-state, never the act. No `git add`, no `git commit`, no
   `chezmoi apply` without `--dry-run` — and no build recipe (`just <x>`,
   `make`, a generator) whose output paths you have not first passed through
   the held-paths guard: a regenerated file is an act, and the tree is
   shared with whoever is claimed right now.
2. Never end a test on a bare `grep -c` — 0 is a legitimate answer and it
   exits 1. Use `test "$(grep -c … || true)" = 0`.
3. Run the whole block twice and check the exit code both times.

## Done when

- Two consecutive runs exit 0 and `git status --short` is unchanged across
  them.

## Fails when
