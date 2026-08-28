---
complexity: 75
footprint:
  - prds/00-delivery/corrections/waves-registry-missing-s10/census.py
  - prds/00-delivery/corrections/waves-registry-missing-s10/prd.md
---

# spec02 — the census of the same class, and the gap `--validate` cannot see

R4 is the part of this node that outlives the fix. `S.10` was missed, and the
question is how many other `done` nodes carry the same gap. Answering it by
re-running `gates/wave-status.sh --validate` would be a census written from
the answer: validate's two assertions are exactly the two that were red, so
after spec01 they report zero by construction and prove nothing about the
population.

**What validate actually asserts, and what it does not.** Assertion 1 says
every board `task:` id appears in *some* row's tasks cell. Assertion 6 says
every script under `tests/` is named by *some* row's gates cell. They are two
independent set-coverage checks and **nothing ties a node to its own gate.** A
node's task can sit in wave 3 while the script its `verify:` names is
registered only in wave 5, and both stay green while the gate arms on a wave
that has nothing to do with the node. That pairing is what the census walks.

`census.py` is the probe, already in the tree uncommitted. It enumerates the
population **before** looking at the answer — every node under `prds/` whose
frontmatter carries both `task:` and `state: done`, nodes with no gate
included rather than filtered out, because "no gate" is the same defect one
step earlier. It classifies each into A (gate registered in its own wave row),
B (gate named by no row — the `S.10` class), C (gate registered in a
*different* wave from its task), D (gate script lives outside `tests/` and
`gates/`, where assertion 6's glob is blind by construction), E (`verify:`
names no script at all).

The measured result, 2026-08-28, live tree with spec01 applied — **the number
R4 asks for is B = 0: `S.10` was the only one of its class** — and four other
findings the census turned up that no assertion on this board covers:

| class | count | what it means |
|---|---|---|
| population | 67 of 71 `task:` nodes are `done` | the denominator |
| A | 44 | gate registered against its own wave row |
| B | **0** | `S.10` was the only node whose gate no row named |
| C | 2 | `W0.8`, `W0.9` — both verify with `tests/deploy-skeleton.sh`, registered in wave 1 while their tasks sit in wave 0 |
| D | 2 | `W0.4d`, `W0.4b` — real, runnable `verify.sh` scripts under `prds/`, named by no row and run by no sweep |
| E | 20 | `verify:` names no script: 17 empty, `G.1` self-referential (`just gates`), `S.7` prose (`quicklist round-trips a pick (wave-5 gate)`), `P.3` empty |

None of C, D or E is this node's to fix — they are other lanes' frontmatter
and other rows. They are **reported**, which is what R4 asks for.

**Why `S.10` slipped, since B = 0 makes it a single event rather than a
pattern.** `0b77a71` landed the node and `tests/shell-litellm.sh` across 36
files and did not touch `gates/waves.tsv`. The node's own Provenance section
says it was built ahead of the board at the user's direction — "code now, PRD
after" — so it skipped `open → specced → claimed`, and the registry row that a
spec's footprint would have carried was never written by anybody. The
mechanism is a skipped board transition, not a silent check.

## Acceptance

- [x] `python3 prds/00-delivery/corrections/waves-registry-missing-s10/census.py`
      exits 0 and prints the population line, the five class counts, and every
      member of B, C, D and E by task id and node path. Run 2026-08-28,
      `EXIT=0`:

      ```
      ── registry census · …/gates/waves.tsv · …/prds
         board nodes carrying `task:`      71
         of those, `state: done`           67   <- the population

      A  done node, gate registered in its own wave row   44
      B  done node, gate named by NO row (the S.10 class) 0
      C  done node, gate registered in a DIFFERENT wave   2
           W0.9   00-delivery/corrections/gate-home-isolation  ->  deploy-skeleton.sh: task in wave ['0'], script in wave ['1']
           W0.8   00-delivery/corrections/gate-reconciliation  ->  deploy-skeleton.sh: task in wave ['0'], script in wave ['1']
      D  done node whose gate script lives OUTSIDE tests/|gates/  2
           W0.4d  …/w0-4-s2-corrections/help   ->  …/help/verify.sh
           W0.4b  …/w0-4-s2-corrections/shell  ->  …/shell/verify.sh
      E  done node whose `verify:` names no script at all 20
           … 18 with `verify: ''`, plus G.1 `just gates` and S.7
           `quicklist round-trips a pick (wave-5 gate)`
      ```

      Every B, C, D and E member is printed by task id and node path in the
      full output; the twenty E members are elided here only for width.
- [x] The population is derived from the board, not from a list: the count of
      `done` nodes it prints equals
      `grep -l '^state: done' $(find prds -name prd.md) | xargs grep -l '^task:' | wc -l`
      run independently. Run 2026-08-28 — that command prints **67**, and so
      does the reversed form `find prds -name prd.md -exec grep -l '^task:'
      {} + | xargs grep -l '^state: done' | wc -l`. The census's own
      `of those, \`state: done\`  67   <- the population` agrees with both,
      and it walks `rglob('prd.md')` with a frontmatter parser rather than a
      hardcoded list — the two paths to 67 share no code.
- [x] **The census can go red, on more than one fixture.**
      `python3 …/census.py --selftest` exits 0 having proved three things:
      class B is reported when a `done` node's gate is dropped from every row;
      class C is reported when that gate is moved to a row its task is not in;
      and `bash gates/wave-status.sh --validate` **stays green (exit 0)** on
      that mispaired registry — the gap the census exists to cover. The
      selftest mutates only scratch copies under `mktemp -d`. Run 2026-08-28,
      `SELFTEST_EXIT=0`, all three red proofs holding:

      ```
      MUTATION HOST: /var/folders/…/T/census-uspmr4sn
      baseline: B=0 C=2
      MUTATION: …/waves-drop-script.tsv drops the gates entry naming tests/shell-litellm.sh
      PASS  class B is reported when a done node's gate is named by no row (B=1)
      MUTATION: …/waves-mispaired.tsv registers tests/shell-litellm.sh in wave 1, while S.10 stays in wave 5
      PASS  class C is reported when a gate is registered in a wave its node is not in (C=3)
      PASS  and `--validate` stays GREEN on that mispaired registry (exit 0) — the gap this census covers
      ── census selftest rc=0
      ```

      The third line is the load-bearing one: B goes 0 → 1 and C goes 2 → 3
      under mutation, so neither count is a constant the probe prints; and on
      the mispaired fixture `--validate` returns **0** while the census
      returns C=3, which is the blind spot stated in this spec's opening
      demonstrated rather than argued. The real registry is untouched
      throughout — `git diff --numstat gates/waves.tsv` still reads
      `1	1	gates/waves.tsv`, spec01's one line — and the `mktemp -d` host is
      removed on exit (no `census-*` directory survives in `$TMPDIR`).
- [x] The same two classes reproduce on a **second and third fixture**, a
      different node/script pair each time, so the counterfactual is not
      special-cased to `shell-litellm.sh`: moving `tests/nvim-keymaps.sh`
      (`E.3`, wave 3) into the wave 0 row raises C to 3 with `--validate`
      still exit 0; dropping `tests/theme-switcher.sh` (`S.9`) from every row
      raises B to 1 with `--validate` exit 1. Both run 2026-08-28 on scratch
      registries under `mktemp -d`, exactly as predicted:

      ```
      === fixture 2 — class C ===
      C  done node, gate registered in a DIFFERENT wave   3
           W0.9   00-delivery/corrections/gate-home-isolation  ->  deploy-skeleton.sh: task in wave ['0'], script in wave ['1']
           W0.8   00-delivery/corrections/gate-reconciliation  ->  deploy-skeleton.sh: task in wave ['0'], script in wave ['1']
           E.3    03-editor/02-keymaps  ->  nvim-keymaps.sh: task in wave ['3'], script in wave ['0']
      fixture2 validate exit=0

      === fixture 3 — class B ===
      B  done node, gate named by NO row (the S.10 class) 1
           S.9    04-shell/09-theme-switcher  ->  tests/theme-switcher.sh
      fixture3 validate exit=1
      ```

      Three distinct pairs now demonstrate the asymmetry — `S.10`/
      `shell-litellm.sh` in the selftest, `E.3`/`nvim-keymaps.sh` here,
      `S.9`/`theme-switcher.sh` here — so it is a property of the two
      assertions, not of one script. And the pair of exits is the finding:
      **dropping** a gate is caught by `--validate` (exit 1), **moving** it to
      the wrong wave is not (exit 0), even though the moved gate then arms on
      a wave that has nothing to do with its node. Nothing on this board
      checks the second case except this census.
- [x] The census is written into `prd.md` under a `## Census` heading — the
      table above, with the date it was measured and the command that produced
      it. Body only; the frontmatter is not this spec's to touch. Written
      2026-08-28: `grep -n '^## Census' prd.md` → `134:## Census`, the
      section carrying the six-row table, the measurement date, the command
      `python3 prds/00-delivery/corrections/waves-registry-missing-s10/census.py`
      and the independently-derived denominator. It also carries the
      three-pair proof of the `--validate` blind spot and the `0b77a71`
      explanation of why `S.10` slipped. `git diff prd.md` touches no line
      above `## Requirements`, so the frontmatter is untouched.

      One correction to the table as this spec drafted it: the E breakdown
      reads **18 empty** rather than "17 empty … `P.3` empty" — `P.3` is one
      of the empties, not a nineteenth line, and 18 + `G.1` + `S.7` = 20 as
      before. The class total is unchanged; only the prose split of it was
      double-counting `P.3`.

## Verify and Proof

```sh
python3 prds/00-delivery/corrections/waves-registry-missing-s10/census.py
echo "EXIT=$?"
python3 prds/00-delivery/corrections/waves-registry-missing-s10/census.py --selftest
echo "SELFTEST_EXIT=$?"

# the population, derived a second way
find prds -name prd.md -exec grep -l '^task:' {} + \
  | xargs grep -l '^state: done' | wc -l

# fixture 2 — a different pair, class C, validate stays green
SP="$(mktemp -d)"
python3 - "$SP" <<'PY'
import re, sys, pathlib
sp = pathlib.Path(sys.argv[1]); txt = open('gates/waves.tsv').read()
t = re.sub(r'\s*\|\s*external bash tests/nvim-keymaps\.sh', '', txt).split('\n')
for i, l in enumerate(t):
    f = l.split('\t')
    if len(f) >= 3 and f[0] == '0':
        f[2] += ' | external bash tests/nvim-keymaps.sh'; t[i] = '\t'.join(f)
(sp / 'f2.tsv').write_text('\n'.join(t))
(sp / 'f3.tsv').write_text(
    re.sub(r'\s*\|\s*external bash tests/theme-switcher\.sh', '', txt))
PY
python3 prds/00-delivery/corrections/waves-registry-missing-s10/census.py \
  --registry "$SP/f2.tsv" | sed -n '/^C /,/^D /p'
bash gates/wave-status.sh --validate --registry "$SP/f2.tsv" >/dev/null 2>&1
echo "fixture2 validate exit=$?"   # expect 0 — the blind spot

# fixture 3 — a different pair, class B, validate goes red
python3 prds/00-delivery/corrections/waves-registry-missing-s10/census.py \
  --registry "$SP/f3.tsv" | sed -n '/^B /,/^C /p'
bash gates/wave-status.sh --validate --registry "$SP/f3.tsv" >/dev/null 2>&1
echo "fixture3 validate exit=$?"   # expect 1
```
