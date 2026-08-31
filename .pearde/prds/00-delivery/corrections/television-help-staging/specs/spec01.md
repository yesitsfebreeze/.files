---
est: 0.25h
footprint:
  - tests/shell-television.sh
---

# spec01 — stage `help.nu` in `tests/shell-television.sh`

`home/dot_config/nushell/config.nu:450` sources `help.nu`. A `source` of a
missing file is a PARSE error in nushell, so the scratch machine in
`tests/shell-television.sh` dies before its first assertion. The gate stages
its modules from a list, so the fix is one word on that list.

One line changes. Line 471, inside `mk_machine`:

```sh
  for m in dirstack pass theme claude zoxide history capsule finder copymode help; do
```

Nothing else. No assertion, no label, no count, no fixture, no new `cp`
line — the derived list is the shape that makes the next module visible to
`gates/nushell-module-staging.sh`, and a hand-rolled copy beside it defeats
that.

## Measured, 2026-08-23, in a scratch copy outside the repo

The scratch copy is `cp -R gates tests home prds docs AGENTS.md` into a
directory outside the tree. Both scripts derive their root from their own
location, so a copy runs against the copy.

| state | `shell-television` | `sourced_file_not_found` | `nushell-module-staging` |
|---|---|---|---|
| word absent (in-tree today) | PASS=40 FAIL=20, EXIT=1 | 7 hits, `config.nu:450` | EXIT=1, 1 MISS |
| word absent (frozen copy) | PASS=42 FAIL=18, EXIT=1 | 7 hits, `config.nu:450` | EXIT=1, 1 MISS |
| word present (frozen copy) | PASS=57 FAIL=3, EXIT=1 | 0 hits | EXIT=0, `misses: 0` |

`PASS=57 FAIL=3` reproduced twice with an identical FAIL set. The drift gate
takes 2s; `shell-television` takes ~123s.

**Do not anchor on the parse-dead FAIL count.** It is path-dependent, so 18,
19 and 20 are all the same outage:

- The check `hermetic: …and the error names the channel and the row count`
  greps the captured stderr for the literals `files` and `2`. While the
  machine is parse-dead that stderr is the parse error naming the scratch
  path, and a path containing a digit satisfies the `2` half by accident. It
  FAILs in-tree and PASSes from `/private/tmp/claude-501/…`. Once `help.nu`
  is staged it passes on the real error message.
- `FAIL the managed nushell and television files are byte-identical` appeared
  in the in-tree run only. `home/dot_config/nushell/env.nu` was written at
  15:04:37 by another implementer while that run was in flight. That
  assertion is a snapshot over the managed tree, so any concurrent write
  convicts this gate. Run it while the nushell tree is quiet, or re-run.

The measurement that matters is `sourced_file_not_found`: 7 hits before, 0
after.

## Run the gates ALONE

Parallel gate runs empty the pty output and produce false reds. Two
implementers are working the board. An unexplained FAIL is re-run solo before
it is believed.

## The three residuals are not this node's

After the change, exactly these three stay red, and the PRD's R3 allows all
three:

1. `hermetic: Ctrl-T inserts the pick at the cursor, single-quoted — the
   double space survives execution only if quoted`
2. `hermetic: an F1 dirs pick moved PWD to the picked directory (print
   $env.PWD line present)`
3. `hermetic: …and the PWD hook auto-listed it (REMOTE-CANARY row painted: 0)`

They belong to [`04-shell/04-television`](../../../../04-shell/04-television/prd.md).
A fourth FAIL is a finding: report it, do not absorb it.

## `git diff` cannot prove this change

`tests/shell-television.sh` is UNTRACKED — `git ls-files` prints nothing for
it and `git log -1 --` prints nothing. A diff over it is empty by
construction, so an acceptance box built on `git diff` cannot fail and a
`[x]` against it is a false record.
[`sibling-gates-copymode-staging`](../../sibling-gates-copymode-staging/specs/spec01.md)
hit this and proved the property against a reconstructed baseline. Do the
same: copy the file aside before editing, `diff` against that copy after, and
require exactly one changed line carrying no assertion token.

## Acceptance

- [x] Line 471 of `tests/shell-television.sh` reads
      `for m in dirstack pass theme claude zoxide history capsule finder copymode help; do`.
      Confirmed by `sed -n '471p'` after the edit.
- [x] The reconstructed diff against a pre-edit copy is exactly ONE changed
      line, and `grep -cE 'chk|chk_ok|chk_fail|-eq|-ne|-ge|-le|==|!='` over
      that line is 0. Quote both numbers. `git diff` is empty by
      construction and proves nothing here.
      Changed lines: **2** diff lines (`471c471`, one `<` and one `>`) = one
      changed line. Assertion tokens: **0**. `git diff` = 0 lines.
- [x] `bash tests/shell-television.sh`, run alone, reports `PASS=57 FAIL=3`
      with ZERO `sourced_file_not_found` hits. Quote the tally and the hit
      count. Measured: `tv EXIT=1`, `PASS=57 FAIL=3 SNF=0`.
- [x] The three FAILs are named and each is one of the three above. A fourth
      is a finding, not an acceptable residual. The three matched exactly;
      there was no fourth.
- [x] `bash gates/nushell-module-staging.sh` goes from `EXIT=1` with exactly
      one MISS line to `EXIT=0` with `grid: … (misses: 0)`. Before:
      `FAIL  MISS tests/shell-television.sh does not stage help.nu —
      config.nu sources it at line 450, so this gate dies at parse before its
      own first assertion` (`EXIT=1`, `PASS=39 FAIL=2`). After: `PASS  grid:
      every in-scope gate stages every module config.nu sources (misses: 0)`
      (`EXIT=0`, `PASS=40 FAIL=0`).
- [x] Counterfactual, both halves, in a copy outside the repo with the word
      stripped: `nushell-module-staging` is `EXIT=1` and its only MISS line
      is `MISS tests/shell-television.sh does not stage help.nu`, and
      `shell-television` is parse-dead again — 7 `sourced_file_not_found`
      hits at `config.nu:450`. Both halves reproduced; `SNF=7`, six lines
      naming `config.nu:450:8` and the seventh inside the vacuous
      channel/row-count PASS line.
- [x] `bash gates/nushell-module-staging.sh --selftest` is `EXIT=0` after the
      change. Its GREEN half repairs this same MISS in a copy; the change
      must not turn that half red. Measured `EXIT=0`, 6 PASS, 0 FAIL.
      Re-measured after the change: `EXIT=0`, `PASS=6 FAIL=0`.
- [x] `gates/waves.tsv` is byte-identical across the whole run — same md5
      before and after. Report the drift gate as ready for wave 0 with the
      segment ` | bash gates/nushell-module-staging.sh`; the orchestrator
      appends it. md5 before and after both
      `2ddb9cf3960e263061896b6be55bf051`; the file was not touched.

## Verify and Proof

```sh
# 0 — the baseline the diff is reconstructed against, and the before runs
T="$(mktemp -d)"
cp tests/shell-television.sh "$T/baseline.sh"
md5 -q gates/waves.tsv | tee "$T/waves.before"
bash gates/nushell-module-staging.sh > "$T/drift-before.log" 2>&1
echo "drift EXIT=$?"; grep -E '^FAIL' "$T/drift-before.log"

# 1 — the edit
LC_ALL=C sed -i '' -E \
  's/^([[:space:]]*for m in [a-z ]*copymode)(; do)/\1 help\2/' \
  tests/shell-television.sh
sed -n '471p' tests/shell-television.sh

# 2 — the reconstructed diff: one line, no assertion in it
diff "$T/baseline.sh" tests/shell-television.sh
diff "$T/baseline.sh" tests/shell-television.sh \
  | grep -E '^[<>]' | grep -cE 'chk|chk_ok|chk_fail|-eq|-ne|-ge|-le|==|!='

# 3 — the two gates, SERIALLY, nothing else running
bash gates/nushell-module-staging.sh > "$T/drift-after.log" 2>&1
echo "drift EXIT=$?"; grep -E 'misses:' "$T/drift-after.log"
bash tests/shell-television.sh > "$T/tv-after.log" 2>&1
echo "tv EXIT=$?"
printf 'PASS=%s FAIL=%s SNF=%s\n' \
  "$(grep -c '^PASS' "$T/tv-after.log")" \
  "$(grep -c '^FAIL' "$T/tv-after.log")" \
  "$(grep -c 'sourced_file_not_found' "$T/tv-after.log")"
grep '^FAIL' "$T/tv-after.log"

# 4 — the drift gate's own selftest still holds
bash gates/nushell-module-staging.sh --selftest > "$T/selftest.log" 2>&1
echo "selftest EXIT=$?"; grep -c '^FAIL' "$T/selftest.log"

# 5 — the counterfactual, outside the repo tree
CF="$(mktemp -d)"; mkdir -p "$CF/repo"
cp -R gates tests home prds docs AGENTS.md "$CF/repo/"
cp "$T/baseline.sh" "$CF/repo/tests/shell-television.sh"
bash "$CF/repo/gates/nushell-module-staging.sh" 2>&1 | grep -E '^FAIL'
bash "$CF/repo/tests/shell-television.sh" 2>&1 \
  | grep -c 'sourced_file_not_found'

# 6 — waves.tsv untouched
md5 -q gates/waves.tsv; cat "$T/waves.before"
```
