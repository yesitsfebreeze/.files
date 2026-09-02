---
complexity: 10
footprint:
  - home/run_after_seed-mason-registry.sh
---

# spec02-mason-hook — R7, answered Automatic, built and branch-tested

`Q1`'s answer (`## Answers` in `prd.md`) is **Automatic**: a brand new
machine quietly fetches its language-server tools the first time it runs,
no extra step. This spec keeps `home/run_after_seed-mason-registry.sh`
(the comment's option that answer maps to) and fixes the thing that made
that answer false as the file stood: `09-simplify/07-provisioning` (`done`,
`6a65c29`) deleted `export MASON_SEED=1` from `install.sh` as part of its
own R2, and its report names the consequence directly — "R2 removed
`export MASON_SEED=1` from `install.sh`, and that variable is the script's
own early-exit guard... 06-neovim-television owns it, and its decision is
now the only thing keeping the file alive." With `MASON_SEED` never set by
anything any more, the guard `if [ -z "${MASON_SEED:-}" ]; then exit 0;
fi` made the script a permanent no-op — automatic seeding was dead on
every machine, not just old ones.

The fix: the `MASON_SEED` switch is gone. The script's only gate is now
the registry-absence check it already had — "a registry directory with
something in it is a seeded one" — which **is** exactly what "first run on
a new machine" means, so no external switch is needed to keep it cheap on
every later apply. The comment preamble is cut from 53 lines citing three
now-deleted test files (`tests/provisioning.sh`, `tests/deploy-skeleton.sh`,
`tests/nvim-lsp.sh`) to one paragraph carrying the two facts that still
matter — why the refresh is off, and why this script is a no-op after the
first seed — pointing at
`.pearde/memos/mason-refresh-off-trades-auto-bootstrap.md` (the corrected
path R7 asked for; the file previously pointed at the non-existent
`prds/memos/...`). The seeding mechanism itself (nvim-on-PATH check, `Lazy!
sync` then `MasonUpdate`, warn-and-exit-0 on every failure) is unchanged
from the version `05-platform/01-deploy-mechanism` R7 built and measured
2026-08-29 — only the outer gate around it moved.

104 → 55 lines; mechanism lines (non-comment, non-blank) 29 → 26, holding
the "~30 mechanism lines" R7 asked for. No `tests/` string remains.

This spec does not touch `install.sh` — it is outside this PRD's
footprint, and re-adding `export MASON_SEED=1` there would restore a
switch this fix makes unnecessary, not repair a gap.

## Acceptance

- [x] `rg -l 'tests/' home/run_after_seed-mason-registry.sh` finds nothing
- [x] `rg -q 'MASON_SEED\b' home/run_after_seed-mason-registry.sh` fails
      (the switch is gone; `MASON_SEED_DATA_DIR`, a different name, stays)
- [x] `rg -q '.pearde/memos/mason-refresh-off-trades-auto-bootstrap.md'
      home/run_after_seed-mason-registry.sh` succeeds
- [x] `bash -n home/run_after_seed-mason-registry.sh` exits 0
- [x] with a scratch `MASON_SEED_DATA_DIR` holding a non-empty
      `registries/` directory, the script prints nothing and exits 0
- [x] with a scratch `MASON_SEED_DATA_DIR` holding no `registries/`
      directory and `nvim` stubbed to fail `+MasonUpdate`, the script
      prints a warning naming `MasonUpdate failed` and exits 0
- [x] with the same cold scratch dir and `nvim` stubbed to succeed
      (writing a `registries/` entry on `+MasonUpdate`), the script prints
      `registry seeded` and exits 0 — proving the seed path fires from the
      registry check alone, with no `MASON_SEED` set anywhere in the
      environment

## Verify and Proof

Probe at
`.pearde/prds/09-simplify/06-neovim-television/probe/mason-seed-branches.sh`
exercises all four branches above against a `mktemp -d` scratch tree, never
the real `$XDG_DATA_HOME/nvim/mason` (confirmed seeded on this machine
before this spec ran — the probe never touches it).

```sh
set -eu
cd /Users/feb/dev/dotfiles
fail() { echo "FAIL: $*"; exit 1; }

if rg -q 'tests/' home/run_after_seed-mason-registry.sh
then fail "a tests/ citation survives"; fi

if rg -q 'MASON_SEED\b' home/run_after_seed-mason-registry.sh
then fail "the MASON_SEED switch survives"; fi

rg -q '\.pearde/memos/mason-refresh-off-trades-auto-bootstrap\.md' \
    home/run_after_seed-mason-registry.sh \
    || fail "the memo path is not corrected"

bash -n home/run_after_seed-mason-registry.sh || fail "does not parse"

mech=$(grep -vE '^\s*#|^\s*$' home/run_after_seed-mason-registry.sh | wc -l | tr -d ' ')
test "$mech" -le 30 || fail "mechanism is $mech lines, over 30"

bash .pearde/prds/09-simplify/06-neovim-television/probe/mason-seed-branches.sh \
    || fail "the branch probe failed"

echo "spec02-mason-hook OK"
```
