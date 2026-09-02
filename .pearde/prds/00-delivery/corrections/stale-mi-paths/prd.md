---
state: done
claim:
priority: 48
est: 3h
needs:
mode: afk
verify: ""
origin: derived
from: 04-shell/09-theme-switcher
---

# Repo-wide `.mi/` path rot after the restructure

The 2026-08-22 restructure retired `.mi/` — the board now lives at `prds/`,
docs at `docs/` (see AGENTS.md, "Where things live"). Every help-manual entry
still records its provenance as `.mi/prds/...`: 91 `source:` values across
`home/dot_config/nushell/help/*.nuon`, plus whatever other shipped or test
files name `.mi/` paths. `tests/help-content-model.nu` resolves sources
against the repo root and now fails on every one of them — the gate is red
repo-wide for reasons unrelated to any node's own work, and every implementer
that runs the full gate trips over it.

Found by the S.9 analyst on 2026-08-22; confirmed by running the gate.

Done means: no shipped file, test, or gate references a `.mi/` path that no
longer exists; `nu tests/help-content-model.nu` passes again; and the sweep
covered the whole repo (`grep -r '\.mi/'`), not just the nuon files — with
anything that must legitimately keep saying `.mi/` (history, ledger quotes)
listed in the report rather than rewritten.

## Questions

- spec01 contradicts itself on the review files, and the implementer may
  not pick a side. Change 2 orders "`note` stay" and "Do NOT touch
  `why-review.nuon`"; acceptance box 4 orders the use-review diff to touch
  only `digest` values and why-review to be unmodified. Acceptance box 5
  and the Verify block order the final `rg -n '\.mi' home tests docs
  .gitignore` to return exactly two lines. Both cannot hold:
  `use-review.nuon:4,122,158,196` and `why-review.nuon:3,108,122` carry
  `.mi/` in exactly the header comments and `note:` fields the first pair
  of clauses freezes, so the sweep as implemented measures 9 lines, not 2.
  Neither set of lines is on the keep-list. Which clause wins: rewrite the
  seven review-file lines (`.mi/prds/` → `prds/`, `.mi/docs/` → `docs/` —
  digests are unaffected, they key on `use`+`source` only), or keep them as
  review-era records and correct box 5 and the Verify count to 9? All
  other changes are applied and green either way (`nu
  tests/help-content-model.nu` ok, `tests/live-bugs.sh` 0 FAIL, the three
  provisioning suites 0 FAIL, `gates/` untouched).

## Answers

- Rewrite the seven review-file lines; box 5's count of 2 stands
  (orchestrator, 2026-08-22). The node's done-condition — no shipped file
  references a dead `.mi/` path — outranks the freeze clauses, whose whole
  purpose is digest integrity: use-review digests key on `use`+`source`,
  why-review on `use`+`why`, so path rewrites in header comments and
  `note:` fields change no digest and fabricate no review claim. The notes
  cite documents that were `git mv`ed unchanged; repointing the citation is
  not falsifying the reading. Leaving `.mi/` in a `note:` beside a row
  whose `source:` this same spec already rewrote would be the incoherent
  outcome. Change 2's "`note` stay" is hereby narrowed to "no edits beyond
  the `.mi/`-prefix rewrite", and "Do NOT touch `why-review.nuon`" to "no
  digest recompute in `why-review.nuon`".

## Failure
