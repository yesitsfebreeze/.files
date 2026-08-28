---
complexity: 25
footprint:
  - gates/waves.tsv
---

# spec01 — register `S.10`'s gate in wave 5, where its dependency already sits

`gates/waves.tsv` names no row for `S.10` and no row names
`tests/shell-litellm.sh`. Add both to the **wave 5** row — one task id in the
tasks cell, one `external bash tests/shell-litellm.sh` in the gates cell — and
prove the addition is load-bearing rather than decorative.

**Why wave 5, and why not 6.** `04-shell/10-litellm-launcher`'s `needs:` holds
exactly one edge, `04-shell/08-claude-launchers` = `S.8`, and `S.8` is in wave
5. A gate-wave row is a *gate-arming set, not a dispatch set*
([`parallelization`](../../../parallelization/prd.md) says so explicitly), so
"same row as the dependency" is the correct reading of "arms when that
dependency's gate arms" — it is not a claim that the two ran concurrently.
Wave 6 is the alternative and it is **worse, measurably**: wave 6 holds `H.4`
`H.5` `H.1c`, all open or blocked, so wave 6 is `PENDING 0/3`, and
`wave-status.sh` runs a PENDING wave's gates but explicitly does **not** fail
on them ("reported, not gating"). Registering there would satisfy
`--validate` while leaving `tests/shell-litellm.sh` unable to fail the sweep —
the same "proof not wired up" defect this node exists to close, one level
subtler. Wave 5 is `ARMED 6/6` after the addition, so the gate genuinely
gates.

**Do not disturb the wave 4 row.** A concurrent lane added
`bash gates/wezterm-config-fields.sh` there. That row is correct and is not
this spec's to touch; the diff must be one line.

## Acceptance

- [x] The wave 5 tasks cell reads `S.6 S.7 S.8 S.10 H.2 H.3` and its gates
      cell ends `| external bash tests/shell-litellm.sh`; `git diff
      gates/waves.tsv` is **one** changed line and the wave 4 row is
      byte-identical to HEAD. Run 2026-08-28 — `git diff --numstat
      gates/waves.tsv` → `1	1	gates/waves.tsv`, the single hunk being
      `-5	S.6 S.7 S.8 H.2 H.3	… | external bash tests/help-browser.sh` /
      `+5	S.6 S.7 S.8 S.10 H.2 H.3	… | external bash tests/help-browser.sh
      | external bash tests/shell-litellm.sh`. And
      `diff <(git show HEAD:gates/waves.tsv | awk -F'\t' '$1=="4"')
      <(awk -F'\t' '$1=="4"' gates/waves.tsv)` is empty — the wave 4 row,
      `bash gates/wezterm-config-fields.sh` and all, is untouched.
- [x] `bash gates/wave-status.sh --validate` exits 0 and prints
      `PASS  registry: every board task appears in a wave row (missing: none)`
      and
      `PASS  registry: every script under tests/ is named by a row (unreferenced: none)`.
      Both other five assertions still PASS; the tally is quoted from the
      output, not asserted. Run 2026-08-28, `EXIT=0`, all seven lines quoted
      verbatim:

      ```
      ── registry integrity: /Users/feb/dev/dotfiles/gates/waves.tsv ───────
      PASS  registry: every board task appears in a wave row (missing: none)
      PASS  registry: no task appears in two wave rows (duplicated: none)
      PASS  registry: every registered task id is a board node's `task:` (unknown: none)
      PASS  board: no two nodes carry the same `task:` (duplicated: none)
      PASS  registry: waves 0-6 each appear exactly once (bad: none)
      PASS  registry: every script under tests/ is named by a row (unreferenced: none)
      PASS  registry: every gates/ script it names exists (missing: none)
      ```
- [x] `bash gates/wave-status.sh --matrix` shows wave 5 as `ARMED 6/6` with
      `6 registered`. Run 2026-08-28 — `5      ARMED    6/6      6 registered`.
      The counter-row the spec's argument rests on is in the same output:
      `6      PENDING  0/3      1 registered`, so wave 6 would indeed have
      been reported-not-gating.
- [x] `bash gates/wave-status.sh --run 5` exits 0 and its own output carries
      the line `── wave 5: bash tests/shell-litellm.sh (external …)` followed
      by `PASS  wave 5 gate: bash tests/shell-litellm.sh`. The gate must be
      shown *running*, not merely registered. Run 2026-08-28, `EXIT=0` over
      614 lines opening `══ wave 5 — ARMED 6/6 ═══`; the last gate of the six
      is the new one:

      ```
      ── wave 5: bash tests/shell-litellm.sh (external — owned by another node, not held to the --selftest contract)
      …
      PASS  wave 5 gate: bash tests/shell-litellm.sh
      ```

      The five pre-existing gates (`shell-claude.sh`, `shell-history.sh`,
      `shell-help.sh`, `shell-quicklist.sh`, `help-browser.sh`) each PASS in
      the same run, so the addition did not disturb the row.
- [x] **The row can go red.** On a scratch copy of `prds/` with `S.10` flipped
      to `state: open`, `bash gates/wave-status.sh --matrix --board <scratch>`
      reports wave 5 `PENDING 5/6` — proving the tasks cell is read. And
      `bash gates/wave-status.sh --selftest --registry <pre-fix copy>` exits 1
      on `FAIL  baseline: the real registry validates against a board copy`,
      while the same command against the live registry exits 0. Neither
      counterfactual writes the real registry or the real board. Both run
      2026-08-28.

      Counterfactual A — `cp -R prds "$SCRATCH/board"`, then
      `sed -i '' 's/^state: done$/state: open/'` on the scratch copy of
      `04-shell/10-litellm-launcher/prd.md`:

      ```
      wave   state    tasks    gates
      5      PENDING  5/6      6 registered
      ```

      Five of six, not six of six — the tasks cell is genuinely read, so the
      new `S.10` id is load-bearing rather than decorative. The live node is
      untouched: `grep -n '^state:' prds/04-shell/10-litellm-launcher/prd.md`
      → `2:state: done`.

      Counterfactual B — `git show HEAD:gates/waves.tsv > "$SCRATCH/pre.tsv"`
      is the registry as it stood before this node. Against it,
      `bash gates/wave-status.sh --selftest --registry "$SCRATCH/pre.tsv"`
      exits **1** with exactly one red, and it is the baseline:

      ```
      FAIL  baseline: the real registry validates against a board copy
      PASS  coverage: a board task in no wave row makes the runner red
      … 18 further PASS lines
      ```

      The same command with no `--registry` — the live, fixed registry —
      exits **0** with all 20 lines PASS, `PASS  baseline: …` among them. The
      registry file is unchanged by either run: `git diff --numstat
      gates/waves.tsv` still reads `1	1	gates/waves.tsv`, the one line of
      this spec's own edit.
- [x] `bash gates/selftest.sh` is quoted with its exit code. If it is not 0,
      the remaining red is named with the assertion text and shown to be a
      different fault from this one — measured 2026-08-28 it is
      `tree-links.sh`, whose `--selftest` pins the exempt count at *9 links in
      4 files* while `bash gates/tree-links.sh` reports *13 links in 5 files*.
      `gates/tree-links.sh` reads no `waves.tsv` (`grep -n waves.tsv
      gates/tree-links.sh gates/tree-links.py` is empty), so the registry row
      cannot move it. Re-measured 2026-08-28 at 13:26 and 13:31, and the
      count has **not** moved since the spec was written:
      `SELFTEST_EXIT=1`, with

      ```
      FAIL  contract: tree-links.sh accepts --selftest and exits 0 (rc 1)
      ```

      and the two reds inside `bash gates/tree-links.sh --selftest` (rc 1)
      being

      ```
      FAIL  fail-closed: the prd.md marker exempts nothing — the exempt count stays 9
      FAIL  green: the real tree's exemptions are exactly 9 links in 4 files
      ```

      against a live `bash gates/tree-links.sh` (rc **0**) reporting
      `checked 1661 links in 485 files, 0 broken` /
      `exempt 13 links in 5 files (target-file-vantage)`. The independence
      holds as written: `grep -n waves.tsv gates/tree-links.sh
      gates/tree-links.py` prints nothing and exits 1, so no registry row —
      this spec's included — can move that count. This is a stale pin in
      another gate's selftest, not this node's fault, and per the node's
      Out of scope it is not fixed here.

      **A second red appeared and is a concurrency artifact, not a fault.**
      The 13:26 run also carried `FAIL  contract: retired-phrases.sh wrote
      nothing outside its scratch`, preceded by `changed:
      /Users/feb/dev/dotfiles/tests/help-agent.sh`. The 13:31 re-run carried
      the same failure attached to a **different** script —
      `FAIL  contract: wezterm-config-fields.sh wrote nothing outside its
      scratch` — naming the same `changed:
      /Users/feb/dev/dotfiles/tests/help-agent.sh`. A fault that migrates
      between two unrelated gates while naming one constant file is not
      either gate writing outside its scratch; it is a concurrent lane
      editing `tests/help-agent.sh` inside the sha256 window (`stat -f '%Sm'
      tests/help-agent.sh` → `Aug 28 13:26:22`, mid-run). `tree-links.sh` is
      the only red that reproduces in the same place across both runs.

## Verify and Proof

```sh
bash gates/wave-status.sh --validate; echo "EXIT=$?"
bash gates/wave-status.sh --matrix | awk 'NR==1 || $1 == "5"'
bash gates/wave-status.sh --run 5 2>&1 | grep -E 'wave 5.*shell-litellm'
git diff --stat gates/waves.tsv

# counterfactual A — the tasks cell is read
SCRATCH="$(mktemp -d)"; cp -R prds "$SCRATCH/board"
sed -i '' 's/^state: done$/state: open/' "$SCRATCH/board/04-shell/10-litellm-launcher/prd.md"
bash gates/wave-status.sh --matrix --board "$SCRATCH/board" | awk '$1 == "5"'

# counterfactual B — the pre-fix registry still fails the harness's own baseline
git show HEAD:gates/waves.tsv > "$SCRATCH/pre.tsv"
bash gates/wave-status.sh --selftest --registry "$SCRATCH/pre.tsv" | head -4; echo "EXIT=$?"

bash gates/selftest.sh; echo "SELFTEST_EXIT=$?"
```
