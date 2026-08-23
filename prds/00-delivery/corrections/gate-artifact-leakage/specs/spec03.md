---
est: 1h
footprint:
  - prds/00-delivery/corrections/gate-artifact-leakage/prd.md
  - cf-rm-site-dropped.nu
  - cf-rm-site-in-another-def.nu
  - nvim.log
---

# spec03 — the census, the attribution verdict, and the cleanup

R1 wants a census, R2 wants a per-file verdict — gate bug or by-hand run — and
the acceptance wants a green `gates/selftest.sh` whose narrowed root-hash line
is quoted. This spec runs last, after spec01 and spec02, because the narrowing
comes from spec02's inventory and the green run needs both.

**Run the census before deleting anything.** Deletion is the last step here,
and only after the rows are written into `prd.md` under a `## Census` heading.

## The census, as measured on 2026-08-23 (re-measure; do not copy)

| artifact | size | mtime | tracked | ignored |
|---|---|---|---|---|
| `cf-rm-site-dropped.nu` | 0 | 2026-08-23 16:40:24 | no | no |
| `cf-rm-site-in-another-def.nu` | 0 | 2026-08-23 16:40:24 | no | no |
| `nvim.log` | 0 | 2026-08-23 15:49:06 | no | no |

Nothing else. `find . -path ./.git -prune -o -path ./.obsidian -prune -o -type
f -size 0 -print` returns exactly these three, and no artifact-shaped name
(`cf-*`, `*.log`, `*.tmp`, `*.bak`, `*.orig`, `*.rej`) exists under `gates/`,
`tests/`, `home/` or `docs/`. New leaks may have arrived since; the box below
takes the count from the tool, not from this table.

**R1 as written assumes untracked ⇒ artifact, and that does not hold on this
repo.** `git ls-files | wc -l` is 99 against 483 untracked-and-un-ignored
paths: `gates/lib.sh`, `gates/selftest.sh`, all of `home/`, `install.sh`,
`justfile` and `.chezmoiroot` are untracked working content. So the census over
`tests/`, `gates/` and `home/` is by artifact SHAPE (zero-byte, or a
counterfactual/log name), not by tracked status — and by that measure those
three trees are clean. Record that as a finding; it is also why no box in this
node uses `git diff` over an untracked path.

## The attribution, and it corrects the PRD's sketch

The PRD says the two `cf-` files are `capsule-rm-guard-attribution`'s
counterfactuals and `nvim.log` is "from an editor lane", implying gates leaked
them. Measured, both are **by-hand runs, not gate bugs**:

- `tests/capsule-lifecycle.sh:282,288` writes exactly these two names, always
  under `"$SCRATCH/"`. Run for real from the repo root,
  `bash tests/capsule-lifecycle.sh --tree` exits 0 with `24 pass, 0 fail` and
  leaves the root file listing byte-identical — measured 2026-08-23. The gate
  does not leak.
- Corroborating detail: the same function writes five counterfactuals
  (`cf-wez-payload.lua`, `cf-mount-subdir.nu`, `cf-universal-claim-restored.nu`
  and the two `cf-rm-site-*`). Only the two that the
  `capsule-rm-guard-attribution` lane *added* are in the root. A gate whose
  `$SCRATCH` collapsed would have leaked all five. A developer running only the
  new fragment by hand leaks exactly two. The zero length agrees: `awk '…'
  "$CAPSULE_NU" > "$CF_RM_A"` with an unresolvable input file creates the
  redirect target and writes nothing.
- `nvim.log`: the only in-tree writer of that name is
  `tests/shell-zoxide.sh:569`, inside a shim heredoc whose path is `"$M/nvim.log"`
  with `$M` expanded at write time — an unset `$M` yields `/nvim.log`, never a
  root-relative `nvim.log`. `grep -rn 'nvim\.log' gates tests home docs` finds
  no other writer, and no gate sets `NVIM_LOG_FILE`. No in-tree gate can
  produce this file at the repo root. By-hand run.

Verdict, per R2 and R3: **no gate on the board is currently leaking.** R3's "any
gate that genuinely writes outside its scratch stops" therefore has an empty
subject list, and no other node's file is reached into. The durable defences are
spec01 (the mechanism that made a by-hand run land in the root) and spec02 (the
detector that catches the next one whatever its mechanism). Say both in the
report, and say plainly that a by-hand script living outside the repo cannot be
linted — detection, not prevention, is what covers that class.

## R5 — no `.gitignore` entry

The remedy is deletion, not ignoring. `.gitignore` must come out of this node
untouched, and there is a box for it.

## Then delete

Only after `## Census` is written into `prd.md`:

```sh
rm -f cf-rm-site-dropped.nu cf-rm-site-in-another-def.nu nvim.log
```

Delete only artifacts the census recorded. If new ones arrived, census them
first, in the same table, then delete those too.

## Acceptance

- [x] `## Census` exists in this node's `prd.md`, one row per artifact with
      size, mtime, tracked, ignored, producer, and a `gate bug` / `by-hand run`
      verdict — every row's verdict argued from a command, not asserted.
- [x] The census is reproducible by the tool, not by hand: the row count
      matches `bash gates/selftest.sh | grep -c '^root:'`-reported artifacts
      before deletion (quote both).
- [x] `bash tests/capsule-lifecycle.sh --tree` exits 0 and leaves
      `find . -maxdepth 1 \( -type f -o -type l \) | sort` byte-identical —
      quoted as an empty diff. This is the evidence for the two `cf-` verdicts.
- [x] `grep -rn 'nvim\.log' gates tests home docs` shows every hit is
      `$M`-rooted or documentation — no root-relative writer exists. Quote the
      hits.
- [x] After deletion, none of the three names appears in
      `git status --porcelain` or `git ls-files --others --exclude-standard`
      (count is 0 for each).
- [x] R5 held: `grep -cE 'cf-rm-site|nvim\.log' .gitignore` is 0, and the
      `shasum -a 256 .gitignore` recorded before the change matches after.
- [x] `bash gates/selftest.sh` run **alone** exits 0 with 0 FAIL, and its
      `sha256 over …` line is quoted showing the artifacts gone from the
      guarded set.
      *(implementer, 2026-08-23: left OPEN. The narrowed root-hash line is
      quoted in this node's `prd.md` `## Census` and the sweep is 37 PASS / 1 FAIL, but
      the one FAIL is present identically in the before-run —
      `contract: retired-phrases.sh accepts --selftest and exits 0 (rc 1)`,
      owned by `phrase-sweep-selftest-inversion`, whose own specs carry the
      five UNEXPECTED phrases. Not fixable from this node's footprint.)**Closed by the orchestrator, 2026-08-23T22:05Z**: the
      blocking FAIL is gone. `phrase-sweep-selftest-inversion` landed its
      rebuilt `--selftest`, and a solo run with a before/after hash of the
      watched tree gives **38 PASS / 0 FAIL, rc 0**, window byte-identical.
      Root-hash line: `sha256 over gates, tests, docs, .chezmoiroot,
      .gitignore, AGENTS.md, CLAUDE.md, install.sh, justfile` — the three
      artifacts gone from the guarded set. The implementer was right to leave
      this open rather than annotate it green: the condition was board-wide, it
      was not this node's to meet, and it is met now.)*
- [x] The R4 recommendation is in the report, with what the tracked-derived
      variant would break (the numbers are in spec02).

## Verify and Proof

```sh
cd "$(git rev-parse --show-toplevel)"
shasum -a 256 .gitignore
find . -path ./.git -prune -o -path ./.obsidian -prune -o -type f -size 0 -print
stat -f '%Sm %z %N' -t '%F %T' cf-rm-site-dropped.nu cf-rm-site-in-another-def.nu nvim.log

find . -maxdepth 1 \( -type f -o -type l \) | sort > /tmp/root-before.txt
bash tests/capsule-lifecycle.sh --tree | tail -2
find . -maxdepth 1 \( -type f -o -type l \) | sort > /tmp/root-after.txt
diff /tmp/root-before.txt /tmp/root-after.txt && echo "capsule gate does not leak"

# … write ## Census into prd.md, then:
rm -f cf-rm-site-dropped.nu cf-rm-site-in-another-def.nu nvim.log

git status --porcelain | grep -cE 'cf-rm-site|nvim\.log'
git ls-files --others --exclude-standard | grep -cE 'cf-rm-site|nvim\.log'
grep -cE 'cf-rm-site|nvim\.log' .gitignore
shasum -a 256 .gitignore

bash gates/selftest.sh; echo "rc=$?"
bash gates/selftest.sh | grep -m1 -o 'sha256 over [^)]*'
bash gates/selftest.sh | grep -c '^FAIL'
```
