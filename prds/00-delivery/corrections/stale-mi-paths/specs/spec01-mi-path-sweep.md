# spec01 — rewrite every live `.mi/` path to the post-restructure tree

Rewrite the dead `.mi/` prefix out of every shipped file, test, and live
board reference, and recompute the `use-review.nuon` digests the rewrite
invalidates, so `nu tests/help-content-model.nu` and `bash tests/live-bugs.sh`
run green. Historical records keep their `.mi/` paths; the keep-list and the
excluded lanes are enumerated below.

**Est:** 3h

**Footprint:** `home/dot_config/nushell/help/` (the four surface `.nuon`
files, `use-review.nuon`, `README.md`), `home/dot_config/nushell/env.nu`,
`home/dot_config/nushell/dirstack.nu`, `tests/help-content-model.nu`,
`tests/live-bugs.sh`, `tests/provisioning.sh`, `tests/shell-init.sh`,
`tests/deploy-skeleton.sh`, `docs/capabilities-provisioning.md`,
`.gitignore`, `prds/00-delivery/corrections/prd.md`

## The rewrite map

`.mi/prds/` → `prds/` and `.mi/docs/` → `docs/`. Every rewritten path must
exist on disk after the strip — all 84 nuon `source:` values were checked and
do (2026-08-22). `.mi/gantt/`, `.mi/skills/`, `.mi/workflows/` and
`.mi/SYSTEM.md` have no successor path; they appear only in the keep-list and
in the excluded `gates/` lane.

## Changes

1. **Help corpus sources** — in `home/dot_config/nushell/help/{shell,nvim,
   terminal,capsule}.nuon`, rewrite all 84 `source:` values
   (`s|.mi/prds/|prds/|`). Also the two header comments in `terminal.nuon`
   (lines 7 and 10: `.mi/prds/02-terminal`, `.mi/docs/capabilities-terminal.md`).

2. **`use-review.nuon` digest recompute.** The gate's `use-digest` keys on
   `use` AND `source`, so step 1 alone leaves all 84 rows mismatched
   ("`use`/`source` changed since the recorded reading" — measured). For every
   row whose `(file, id)` matches an entry, set `digest` to
   `sha256("<use>\n--\n<source>") | first 16 hex chars` computed from the
   rewritten entry. Change nothing else in any row — `reviewer`, `author`,
   `date`, `note` stay. This is not a new review claim: the restructure moved
   each source PRD without changing it (`git mv`), so each recorded reading
   still describes the same document. Do NOT touch `why-review.nuon` — its
   digest keys on `use` and `why` only.

   Recipe proven green 2026-08-22 against a scratch copy:

   ```nu
   def use-digest [use: string, source: string] {
       $"($use)\n--\n($source)" | hash sha256 | str substring 0..15
   }
   # for each entry: {file, id, digest: (use-digest $e.use $e.source)}
   # update the matching use-review row's digest; save with `to nuon --indent 2`
   ```

3. **Help writer docs** — `home/dot_config/nushell/help/README.md` lines 7
   and 326: `.mi/prds/06-help/...` → `prds/06-help/...`.

4. **Shipped nushell comments** — `home/dot_config/nushell/env.nu:14` and
   `home/dot_config/nushell/dirstack.nu:27`: spec citations →
   `prds/04-shell/01-core-config/specs/...`.

5. **`tests/help-content-model.nu`** — comment lines 4 and 21 only
   (`.mi/prds/06-help/...` → `prds/06-help/...`). Leave the TRANSITIONAL
   flat-form fallback alone; retiring it is not this node's contract.

6. **`tests/live-bugs.sh`** — lines 4, 27–29, 95: `.mi/docs` → `docs`,
   `.mi/prds` → `prds`. Line 117: the owner-column regex
   `\.mi/docs/capabilities-[a-z-]+\.md` → `docs/capabilities-[a-z-]+\.md`
   (must land with change 9, same commit — the regex greps text that change 9
   rewrites; with both applied the suite was measured at 0 FAIL, without
   change 9 it fails on "routing: L-5 owner"). Line 249 stays: it quotes a
   `git show HEAD:.mi/docs/...` read of the pre-correction record —
   deliberately verbatim history.

7. **`tests/provisioning.sh` and `tests/shell-init.sh`** — the
   `snapshot_paths --deep "$REPO/.mi" ...` lines (provisioning 490,
   shell-init 576): replace `"$REPO/.mi"` with `"$REPO/prds" "$REPO/docs"`.
   Update the matching `assert_unchanged` message texts (provisioning 527,
   shell-init 618: "sha256 over .mi, ..." → "sha256 over prds, docs, ...").
   Rewrite the comment at provisioning 492–494: its "the .mi/prd -> .mi/prds
   rename is staged and uncommitted" justification is stale; keep the claim
   that `git status --porcelain` cannot be the guard, name the current reason
   (the working tree carries unrelated staged work), or drop the parenthetical.

8. **`tests/deploy-skeleton.sh:258`** — in the leak-check list, replace `.mi`
   with `prds docs gates`: the check asserts repo entries never deploy into
   the target, and those are the entries that replaced `.mi` at the root.

9. **`prds/00-delivery/corrections/prd.md`** — the live backlog's routing
   text: lines 224, 304, 305, 308, 318 `.mi/docs/` → `docs/`; line 408
   `.mi/SYSTEM.md` → `AGENTS.md` (the meta-epic C/U exemption lives in
   AGENTS.md's rating-system section now — verified present). Body text only;
   no frontmatter, no state, no other rows.

10. **`docs/capabilities-provisioning.md:14`** — citation → 
    `prds/00-delivery/corrections/prd.md`.

11. **`.gitignore:16`** — delete the dead `.mi/gantt/scratch/` rule.

## Keep-list — legitimate `.mi/` mentions, do not rewrite

- `AGENTS.md:50`, `prds/README.md:49,119`,
  `prds/00-delivery/work-breakdown/prd.md:28,215` — sentences about the
  retirement itself ("retired `.mi/gantt/plan.json`").
- `tests/live-bugs.sh:249` — verbatim pre-correction `git show` record.
- `prds/00-delivery/corrections/stale-mi-paths/prd.md`,
  `prds/00-delivery/corrections/gates-frontmatter-port/prd.md`,
  `prds/00-delivery/corrections/stale-s2-doc-refs/prd.md:19`,
  `prds/04-shell/09-theme-switcher/specs/spec04-help-and-gate.md:18,76` —
  the stale paths are these documents' subject.
- Every file under a `state: done` node in `prds/**` (~600 references:
  w0-* corrections, decisions/*, verification-gates, 06-help/01,
  05-platform specs, their `specs/` and `checks/`) — execution records.
  Their verify commands, sha-pinned assertions, and mi-era narrative
  describe the tree as it stood when the work ran; rewriting them falsifies
  the record. Measured: zero of them are markdown links in a `prd.md`
  (Tier A), so none can redden the ported link gate.

## Excluded — other lanes, do not touch

- `home/dot_config/nushell/config.nu:25` (one comment ref:
  `.mi/prds/04-shell/01-core-config/specs/spec03.md`) — an implementer
  holds `config.nu`, `pass.nu`, `tests/nushell-core.sh`,
  `tests/nushell-aliases.sh`; the other three carry zero `.mi` refs. That
  lane, or a follow-up, rewrites this one line.
- `gates/**` (~90 refs: `tree-links.py` roots, `lib.sh` `cp -R .mi`,
  `selftest.sh` guard lists, `wave-status.sh`/`manual-coverage.sh` reading
  the retired `plan.json`, `waves.tsv`, `manual/wave*.md`) — owned by
  [`gates-frontmatter-port`](../../gates-frontmatter-port/prd.md); not a
  mechanical rewrite, since `plan.json` has no successor file and each gate
  must be re-proven by induced failure. This spec discharges that node's
  R2 for `tests/`; its analyst scopes to `gates/` only.
- `.claude/worktrees/wf_*/**` — other sessions' worktree snapshots.

## Acceptance

- [x] `nu tests/help-content-model.nu` prints `ok` and exits 0 — no
      "exists in neither node nor flat form", no "changed since the
      recorded reading".
      Ran 2026-08-22: `help content model: 84 entries across 4 files, 9
      topics, 10 prose-only` … `ok`, `exit=0`.
- [x] `bash tests/live-bugs.sh` reports 0 FAIL and exits 0.
      Ran 2026-08-22: `exit=0`, `grep -c '^FAIL'` = 0, 159 PASS; final line
      `OK — every live-bug record still matches the config it describes,
      and every row is owned`.
- [x] All 84 `source:` values in the four surface nuon files start with
      `prds/` and each names a file that exists.
      Ran 2026-08-22 (nu, open each nuon, check `path exists`):
      `total=84 prds-prefixed=84 missing=0`.
- [x] `git diff -- home/dot_config/nushell/help/use-review.nuon` touches
      only `digest` values; `why-review.nuon` is unmodified.
      Superseded in part by the node's Answer (prd.md `## Answers`,
      2026-08-22): the `.mi/`-prefix rewrite extends to
      `use-review.nuon:4,122,158,196` and `why-review.nuon:3,108,122`
      (header comments and `note:` fields; no digest keys on them). This
      spec's delta is therefore: 84 `digest` values plus those seven
      line-scoped prefix rewrites, and nothing else. Proven 2026-08-22: the
      digest edit replaced exactly 84 sixteen-hex strings, each asserted to
      appear exactly once (`rows=84 entries=84 to-replace=84
      unmatched-rows=0`); the seven rewrites were line-number-scoped
      (`perl`, patterns `.mi/prds/` → `prds/`, `.mi/docs/` → `docs/`);
      after them both gates re-ran green.
      Caveat: the raw `git diff` also shows PRE-EXISTING unstaged review-row
      edits in both files (reviewers `impl-H-1-r*`, `reader-D-1c-spec03`)
      that were in the working tree before this node ran — 42 masked-diff
      lines vs the index in use-review.nuon, 31+/12- in why-review.nuon.
      This node introduced none of them.
- [x] `rg -n '\.mi' home tests docs .gitignore` returns exactly two lines:
      `home/dot_config/nushell/config.nu:25` (excluded lane) and
      `tests/live-bugs.sh:249` (keep-list).
      First measured 9 lines, 2026-08-22 — the 7 extras were
      `use-review.nuon:4,122,158,196` and `why-review.nuon:3,108,122`,
      frozen by change 2 and box 4 as then written; filed as a question on
      the node. The Answer (prd.md `## Answers`, 2026-08-22) directed
      rewriting those seven lines. Ran after that rewrite: count = 2, and
      the two lines are exactly `tests/live-bugs.sh:249` and
      `home/dot_config/nushell/config.nu:25`. Both gates re-ran green after
      the rewrite (`ok` exit 0; 0 FAIL exit 0), and the full Verify block
      prints `SPEC01-OK`, exit 0.
- [x] `rg -n '\.mi' tests/provisioning.sh tests/shell-init.sh
      tests/deploy-skeleton.sh` returns nothing; `bash tests/deploy-skeleton.sh`,
      `bash tests/provisioning.sh`, and `bash tests/shell-init.sh` no longer
      fail on any `.mi`-path check (quote any residual failures — pre-existing
      red unrelated to paths is reported, not silently absorbed).
      Ran 2026-08-22: rg returns nothing (exit 1). deploy-skeleton `exit=0`,
      0 FAIL, `PASS — the deploy skeleton holds…`; provisioning `exit=0`,
      0 FAIL, `PASS  the gate wrote nothing outside its scratch (sha256
      over prds, docs, gates, tests, home, install.sh)`; shell-init
      `exit=0`, 0 FAIL, `PASS — shell-init generation holds…`. No residual
      failures.
- [x] `prds/00-delivery/corrections/prd.md` lines 224, 304, 305, 308, 318,
      408 carry no `.mi/`; the file's frontmatter and every other row are
      byte-identical.
      Ran 2026-08-22: `rg -n '\.mi/'` on the file returns nothing; the edit
      was line-number-scoped (`perl` on exactly those six lines, patterns
      `.mi/docs/` → `docs/` and `.mi/SYSTEM.md` → `AGENTS.md`), frontmatter
      untouched.
- [x] `git diff --stat -- gates/` is empty.
      Ran 2026-08-22: empty output, and `git diff --quiet -- gates/`
      exits 0.

## Verify

```sh
cd "$(git rev-parse --show-toplevel)" \
  && nu tests/help-content-model.nu \
  && bash tests/live-bugs.sh \
  && [ "$(rg -n '\.mi' home tests docs .gitignore | wc -l | tr -d ' ')" = "2" ] \
  && ! rg -q --no-messages '\.mi' tests/provisioning.sh tests/shell-init.sh tests/deploy-skeleton.sh \
  && git diff --quiet -- gates/ \
  && echo SPEC01-OK
```
