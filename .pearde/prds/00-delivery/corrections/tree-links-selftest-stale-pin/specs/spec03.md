---
complexity: 20
footprint:
  - gates/tree-links.sh
  - gates/tree-links.py
  - prds/00-delivery/corrections/tree-links-selftest-stale-pin/
---

# spec03 — prove the rewritten checks bite, then run the sweep

R3 is the reason this node exists rather than a one-line bump from 9 to 13: a
check rewritten to stop failing must be shown still able to fail. This unit
introduces three violations against three different fixtures, watches each go
red, removes it, watches it go green, and quotes both — then clears
`gates/selftest.sh` and records what `G.1`'s own `verify:` actually does.
Every probe is reverted; nothing here is left in the tree.

## The three fixtures

Three, not one, because the two rewritten assertions guard two different
faults and R3's literal wording names a third.

| probe | fixture | what it should turn red |
|---|---|---|
| **A** | `gates/tree-links.py` — defeat the `outside specs/` guard so a `prd.md` marker *is* honoured | spec01's before/after differential |
| **B** | `gates/tree-links.py` — drop `file_exempt += 1` so exempted links go uncounted | spec02's reappearance check and both non-vacuity guards |
| **C** | the real tree — a well-formed `target-file-vantage` marker in a `README.md` under `prds/`, where it is never honoured | the gate proper, and the selftest's real-tree green check |

Probe C is the fixture R3 names literally. It must show the marker exempting
nothing — the tally stays put while the link under it is still reported
`BROKEN` — and the gate exiting non-zero on the `outside specs/` `ERROR`.

## The sweep, and the artifact to expect

`bash gates/selftest.sh` hashes the tree around each gate and attributes any
difference to whichever gate is in flight, so a parallel lane writing during
the window trips an unrelated gate — recorded in
[`a-concurrent-lane-trips-the-scratch-guard`(../../../../../../prds/memos/a-concurrent-lane-trips-the-scratch-guard.md).
A `wrote nothing outside its scratch` red naming a file the gate has no
business with is that artifact, and the tell is that it **moves to a different
gate on a re-run** while a real violation stays put. Re-run before believing
it, and say which you saw.

## Acceptance

- [x] Each of probes A, B and C is quoted twice — the red it produces and the
      green after it is removed — naming the check line that moved.

      **Probe A** — `gates/tree-links.py:176`, `if not in_specs:` →
      `if False and not in_specs:`. Selftest rc **1**, 32 PASS / 3 FAIL; the
      line that moved is spec01's differential:

      ```
      FAIL  fail-closed: the prd.md marker exempts nothing — the tally is unmoved ('13 5' -> '14 6')
      ```

      Reverted → `PASS  fail-closed: the prd.md marker exempts nothing — the
      tally is unmoved ('13 5' -> '13 5')`, rc 0, 35 PASS / 0 FAIL. The
      `13 5 -> 14 6` movement is the bait link being exempted; without the
      bait this probe reads `13 5 -> 13 5` and passes through the fault, which
      is the blind spot the old pinned check shared for its whole life.

      **Probe B** — `gates/tree-links.py:256`, `file_exempt += 1` → `pass`.
      Selftest rc **1**, 31 PASS / 4 FAIL:

      ```
      FAIL  vacuity: the exempt link is counted in the exempt line, never invisible
      FAIL  fail-closed: and is not vacuously zero — there are exemptions to move
      FAIL  derived: it is not vacuously zero — there are exemptions to account for
      FAIL  derived: every exempted link reappears as a checked one (1673 + 0 = 1686)
      ```

      Reverted → all four PASS, `1673 + 13 = 1686`, rc 0, 35 PASS / 0 FAIL.

      **Probe C** — a well-formed marker plus a broken link appended to the
      real `prds/README.md`, where the marker is never honoured. The gate
      proper, rc **1**:

      ```
      BROKEN prds/README.md:238 -> ./no-such-probe-c-target.md (prds/no-such-probe-c-target.md)
      ERROR prds/README.md:236 -> target-file-vantage marker outside specs/ — the marker is honoured only in a node spec, never in a prd.md, README.md or docs page
            checked 1674 links in 491 files, 1 broken
            exempt 13 links in 5 files (target-file-vantage)
      ```

      The marker exempts nothing: the exempt tally is unmoved at `13 5` while
      the link under it is reported `BROKEN`, and `checked` rises 1673 → 1674
      because that link stayed in the checked set. The selftest went rc **1**
      with 30 PASS / 5 FAIL, including
      `FAIL  green: the real tree exits 0 over the merged set (specs/**
      included)`. Reverted → gate rc 0, `checked 1673 links in 491 files, 0
      broken` / `exempt 13 links in 5 files`, selftest rc 0 with
      `PASS  green: the real tree exits 0 over the merged set (specs/**
      included)`, 35 PASS / 0 FAIL.
- [x] After every probe is reverted, `git status --porcelain` shows
      `gates/tree-links.sh` and this node's `specs/` and nothing else from
      this unit; `gates/tree-links.py` is byte-identical to `HEAD`.

      ```
       M gates/tree-links.sh
       M prds/00-delivery/corrections/g1-verify-still-red-on-just-gates/prd.md
       M prds/00-delivery/corrections/nushell-core-s430-stall/prd.md
       M prds/00-delivery/finish-line/agent-overview-derived-tools/prd.md
      ?? prds/00-delivery/corrections/tree-links-selftest-stale-pin/specs/
      ```

      The three other `prd.md` entries belong to concurrent lanes, not to this
      unit — none is a file this unit ever opened. `prds/README.md` is absent
      from the list, so probe C left nothing behind. `gates/tree-links.py`:
      `git diff --stat` empty, and sha256 `4f9c549b611d2ccc…` in the working
      tree equals `git show HEAD:gates/tree-links.py`.
- [x] `bash gates/selftest.sh` exits 0, **or** every remaining red is named
      with the file it blames, the gate it blames, and a re-run showing the
      blame moving.

      Three serial runs. The first two were red on the known concurrency
      artifact and the third was clean, so both halves of this box are on the
      record:

      | run | rc | tally | gate blamed | file it blames |
      |---|---|---|---|---|
      | 1 | 1 | 47 PASS / 1 FAIL | `retired-phrases.sh` | `tests/shell-init.sh` |
      | 2 | 1 | 46 PASS / 2 FAIL | `audit-findings.sh` | `tests/shell-init.sh` |
      | 2 | 1 | — | `manual-coverage.sh` | `tests/managed-config.sh`, `tests/shell-litellm.sh` |
      | 3 | **0** | **48 PASS / 0 FAIL** | — | — |

      The blame moved from `retired-phrases.sh` to `audit-findings.sh` between
      runs while the file it named stayed the same, which is the tell the memo
      describes. The cause was visible directly: a concurrent lane was
      rewriting `tests/shell-init.sh` (15:03:23), `tests/shell-litellm.sh`
      (15:03:46) and `tests/managed-config.sh` (15:05:15) while the sweep ran,
      and `git status` showed all three modified alongside a rename of
      `home/dot_config/litellm/config.yaml`. None is a file any of the three
      accused gates writes. Run 3, after that lane's window closed:
      `sweep3_rc=0`, 48 PASS / 0 FAIL.

      `tree-links.sh` passed its own contract in every run, including the two
      red ones:
      `PASS  contract: tree-links.sh wrote nothing outside its scratch`.
- [x] An isolated short-window hash over `gates tests docs AGENTS.md
      install.sh justfile .gitignore .chezmoiroot` is identical before and
      after `bash gates/tree-links.sh --selftest` — this gate is not the
      writer.

      Deep hash (listing plus per-file sha256, the `_gates_hash_path --deep`
      shape), taken immediately either side of one selftest run:

      ```
      before: 4c1fbe9fe3d7268388bac9366bb863328e94c655a358381bb37bacd977019739
      selftest_rc=0
      after:  4c1fbe9fe3d7268388bac9366bb863328e94c655a358381bb37bacd977019739
      IDENTICAL — this gate is not the writer
      ```
- [x] `just gate-selftest && just gates` is run and its result recorded. If
      it does not pass, that is stated with the failing checks named, and
      `G.1`'s own state is reported as wrong rather than edited.

## Verify and Proof

```sh
cd /Users/feb/dev/dotfiles
bash gates/tree-links.sh --selftest 2>&1 | grep -cE '^PASS'
bash gates/tree-links.sh --selftest >/dev/null 2>&1; echo "selftest=$?"
git diff --stat -- gates/tree-links.py            # must be empty
bash gates/selftest.sh 2>&1 | grep -E '^FAIL|held to the contract'
just gate-selftest; echo "gate-selftest=$?"
just gates 2>&1 | grep -E '^FAIL |sweep rc='
```


      **Run 2026-08-28, detached so it survived — both halves pass.**
      `just gate-selftest` → `GATE-SELFTEST_RC=0`, 9 scripts held to the
      contract, 59 external reported not failed. `just gates` → `sweep rc=0`,
      `GATES_RC=0`, ending on the live-safety pair: `LIVE chezmoi.toml
      unchanged` and `LIVE chezmoi source-path unchanged
      (/Users/feb/dev/.files/home)`.

      **Stated precisely, because the green is younger than this node.** When
      this node's analyst measured it, `just gates` was `rc=1` on five
      failures in `tests/managed-config.sh` and `tests/shell-init.sh`. Those
      are not this node's and were filed as
      [`g1-verify-still-red-on-just-gates`](../../g1-verify-still-red-on-just-gates/prd.md);
      that lane's fixes were in the working tree when this ran. So what is
      proven here is: **this node's own half — `gate-selftest` — is green on
      its own merit**, and the sweep is green with the other lane's work
      applied. `G.1`'s state is that node's to settle, not this one's.