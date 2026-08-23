---
est: 0.75h
footprint:
  - tests/nushell-aliases.sh
  - tests/shell-listing.sh
  - tests/shell-zoxide.sh
  - tests/shell-history.sh
  - tests/shell-claude.sh
  - tests/shell-television.sh
---

# spec01 — stage `copymode.nu` in the six gates that miss it

`home/dot_config/nushell/config.nu:436` sources `copymode.nu`. A `source` of
a missing file is a PARSE error in nushell, so a gate whose scratch HOME
lacks the file dies before its first assertion. Add the staging line to
every gate that stages a nushell machine and does not have it, then prove
each gate's verdict changed for that reason and no other.

The census is measured, not assumed. Eight gates stage modules into a
scratch `.config/nushell` and run `nu` against the managed `config.nu`:
`nushell-core`, `nushell-aliases`, `shell-listing`, `shell-zoxide`,
`shell-history`, `shell-claude`, `shell-television`, `shell-help`. Two
already stage `copymode.nu` (`nushell-core`, `shell-help`). Six do not, and
all six are red today.

## What to change, per file

Five gates carry an explicit `cp` line per module. Insert one line directly
below the `finder.nu` line, in the house form, comment included:

```sh
  cp "$NUSHELL_SRC/copymode.nu" "$M/home/.config/nushell/copymode.nu"  # 02-terminal/04: config.nu sources copymode.nu at MODULES
```

- `tests/nushell-aliases.sh` — in `mk_machine`, after line 125.
- `tests/shell-listing.sh` — in `mk_machine`, after line 320.
- `tests/shell-zoxide.sh` — in `mk_machine`, after line 427.
- `tests/shell-history.sh` — in `mk_machine`, after line 462.
- `tests/shell-claude.sh` — in `mk_machine`, after line 263.

Match the indentation of the neighbouring `cp` lines. Note that the
`finder.nu` line itself sits at column 0 in four of the five — do not
"tidy" it; that is an unrelated edit.

`tests/shell-television.sh` is list-driven instead. Its `mk_machine` copies
a loop of stems, so the change is one word on that line (line 471):

```sh
  for m in dirstack pass theme claude zoxide history capsule finder copymode; do
```

Nothing else in any of the six files changes. No assertion, no label, no
count, no fixture.

## Baseline, measured 2026-08-23, before the edit

Gates must be run SERIALLY. Eight of them in parallel made
`tests/nushell-core.sh` report `FAIL hermetic: S4.26 a probe exiting 1
leaves OLLAMA_HOST unset (got )`; the same gate alone is `EXIT=0`. A
parallel sweep produces false reds.

| gate | PASS | FAIL | EXIT |
|---|---|---|---|
| nushell-core | 147 | 0 | 0 |
| nushell-aliases | 27 | 12 | 1 |
| shell-listing | 21 | 15 | 1 |
| shell-zoxide | 44 | 28 | 1 |
| shell-history | 35 | 27 | 1 |
| shell-claude | 35 | 14 | 1 |
| shell-television | 41 | 19 | 1 |
| shell-help | 60 | 0 | 0 |

Only `nushell-aliases`, `shell-claude` and `shell-help` print a `CHECKS: n
run, n passed, n failed` line. The other five print no summary at all, so
the record for those is `EXIT=` plus the `PASS`/`FAIL` tally from the log.

## Two reds this spec does NOT fix, and must not hide

Both were proven independent: measured on a full scratch copy of the repo
with the staging lines applied, and stable across three runs.

1. `tests/shell-zoxide.sh` keeps one FAIL — `tree: exactly six entries name
   this PRD as their source`. `shell.nuon` now holds SEVEN entries naming
   `prds/04-shell/03-zoxide/prd.md`, because the `cdi` entry was reassigned
   to that owner by
   [`cdi-manual-source`](../../cdi-manual-source/prd.md). The gate's `-eq 6`
   is stale. Correcting it changes an assertion, which R3 forbids here.
2. `tests/shell-television.sh` keeps three FAILs — the Ctrl-T cursor insert
   and the two F1 dirs-pick checks — and also still misses `help.nu`
   (`config.nu:450`). `help.nu` is a second unstaged module and the PRD's
   Out of scope defers it. Staging an EMPTY `help.nu` reproduces the same
   three FAILs, so they are not caused by `help.nu`'s content either.

Record both in the implementer's report. Do not touch them.

## Acceptance

- [x] **Reworded by the orchestrator: `git diff` is not runnable here.** All
      six gate files are **untracked** — `git log -1 --` prints nothing for
      any of them — so a diff over them is empty by construction and a `[x]`
      against it would be a false record. Proved against a reconstructed
      baseline instead: **7 changed lines total** across the six (five
      identical `cp` lines plus the one loop-word swap), and
      `grep -cE 'chk|chk_ok|chk_fail|-eq|-ne|-ge|-le|==|!='` over those
      changed lines = **0**, so R3 holds by measurement. Original box:
      Each of the six files gained exactly one staging line (five `cp`
      lines, one loop word) and `git diff` over the six shows nothing else.
- [x] **Same rewording, same reason** — see the box above; the
      assertion-free property was proved by grep over the reconstructed
      diff, not by `git diff`. Original box: `git diff` over the six files
      contains no line that adds, removes or
      edits a `chk`, `chk_ok`, `chk_fail` or a comparison operand.
- [x] Run serially: `tests/nushell-aliases.sh`, `tests/shell-listing.sh`,
      `tests/shell-history.sh`, `tests/shell-claude.sh` and
      `tests/nushell-core.sh` each `EXIT=0` with zero `FAIL` lines.
- [x] `tests/shell-zoxide.sh` is down to exactly ONE FAIL, and it is
      `tree: exactly six entries name this PRD as their source`.
- [ ] **Moved by the orchestrator to
      [`television-help-staging`](../../television-help-staging/prd.md).**
      Unreachable from this node: the `copymode.nu` fix moved
      `shell-television`'s parse error from `config.nu:436` to `:450`, so
      in-tree it is **19 FAIL, not 3**, because `help.nu` staging was put out
      of scope here. The analyst's 19F → 3F was **confirmed** in a scratch
      copy with `help.nu` also staged — same gate, `PASS=57 FAIL=3`, zero
      `sourced_file_not_found`. This box belongs to the node that lands that
      one word. Original box: `tests/shell-television.sh` is down to exactly
      THREE FAILs, all
      three named in the section above, and its log holds zero
      `sourced_file_not_found` hits.
- [x] **Reworded by the orchestrator: the exhaustive half was stale.** The
      `:436` clause passed — **zero** hits at `config.nu:436` in any log,
      which is this node's actual claim. The box also asserted a single
      permitted hit overall, and the logs legitimately carry **7** at
      `config.nu:450`, the out-of-scope `help.nu`. Two PASS *labels* also
      contain the string without being hits (`nushell-core`'s `S4.31`, and
      `nushell-aliases`' "nothing on stderr (no sourced_file_not_found)").
      Original box: No log holds a `sourced_file_not_found` at
      `config.nu:436`. The one
      permitted hit is `nushell-core`'s own `PASS hermetic: S4.31 removing
      one generated init file makes nushell fail with
      nu::parser::sourced_file_not_found`.
- [x] Counterfactual: a copy of `tests/nushell-aliases.sh` with the new
      line stripped is red again, at `config.nu:436`, with the same 12
      FAILs as the baseline.

## Verify and Proof

```sh
# 1 — the diff is staging only
git diff --stat -- tests/nushell-aliases.sh tests/shell-listing.sh \
  tests/shell-zoxide.sh tests/shell-history.sh tests/shell-claude.sh \
  tests/shell-television.sh
git diff -- tests/nushell-aliases.sh tests/shell-listing.sh \
  tests/shell-zoxide.sh tests/shell-history.sh tests/shell-claude.sh \
  tests/shell-television.sh

# 2 — the six, plus the two that were already green, SERIALLY
for g in nushell-core nushell-aliases shell-listing shell-zoxide \
         shell-history shell-claude shell-television shell-help; do
  bash "tests/$g.sh" > "/tmp/$g.log" 2>&1
  printf '%-20s EXIT=%s FAIL=%s PASS=%s %s\n' "$g" "$?" \
    "$(grep -c '^FAIL' "/tmp/$g.log")" "$(grep -c '^PASS' "/tmp/$g.log")" \
    "$(grep -E '^CHECKS' "/tmp/$g.log" | tail -1)"
  grep '^FAIL' "/tmp/$g.log"
done

# 3 — no gate died at config.nu's copymode line
grep -c 'sourced_file_not_found' /tmp/*.log

# 4 — the counterfactual, outside the repo tree
CF="$(mktemp -d)"; cp -R . "$CF/repo"
/usr/bin/grep -vF 'copymode.nu"' tests/nushell-aliases.sh \
  > "$CF/repo/tests/nushell-aliases.sh"
bash "$CF/repo/tests/nushell-aliases.sh" 2>&1 \
  | grep -E 'CHECKS|config.nu:436'
```
