---
complexity: 20
footprint:
  - tests/nushell-core.sh
verify: "bash tests/nushell-core.sh"
# COMPUTE COST: negligible. Every check this spec adds is a string
# classification over a fabricated buffer plus one live pty run with a 2 s
# ceiling. Measured cost of the whole gate today, this machine, 2026-08-24:
# --tree 2.8 s / --hermetic 13.2 s / --apply 3.9 s / full 20 s at load 7.6.
---

# spec01 — a timeout and a wrong directory stop being the same finding

`S4.30`'s four pty checks currently pipe the raw capture through
`$GREP -o 'PWDIS:.*' | head -1`, so when the pty runner **kills the child at
its ceiling** the filter throws away the only evidence of that and the check
reports `(got )` — an empty parenthesis that reads as "the shell opened
somewhere unexpected". That is the conflation R3 names: a *timeout* and a
*wrong answer* are different findings and today they print the same way.

The evidence is already produced and already discarded. The runner writes
`\n<NUPTY-TIMEOUT>\n` after the buffer when it SIGKILLs the child
(`tests/nushell-core.sh:324`), and `tests/shell-quicklist.sh:1077,1092` is the
precedent in this repo for asserting on that marker from a raw capture. This
spec brings the same discipline into `nushell-core.sh`: keep the raw bytes,
classify them, and let the two outcomes print differently — with the load
average printed beside a timeout, which the standing memo
[`a-headless-gate-red-may-be-load-not-code`](../../../../memos/a-headless-gate-red-may-be-load-not-code.md)
makes every timing failure owe.

Verified before writing this spec, so the implementer does not have to
rediscover it: `python3 <the extracted runner> 2 -- /bin/sh -c 'sleep 30'`
prints `<NUPTY-TIMEOUT>` and the runner itself still exits 0. The marker is
reachable; only the filter hides it.

This spec is R3 and R5. It lands **first** so that spec02's runs under load,
if one of them does hit the ceiling, identify themselves instead of being
mistaken for a directory bug — which is exactly how this node was born.

## The classifier

A pure function beside the gate's other "runnable against a broken copy"
helpers (`anchors_ok`, `funnel_binds`, today around
`tests/nushell-core.sh:388-410` — a reading, not a constant). It takes the
**raw** capture, never a pre-filtered one, and prints exactly one of:

- `PWDIS:<dir>` — the shell answered.
- `TIMEOUT:<ceiling>s` — the runner hit its ceiling; the child was killed.
- `NOANSWER` — the child exited without ever printing `PWDIS:`, and without a
  timeout. A third finding, and it must not be folded into either of the
  first two: it is the shape a parse error or an early `exit` produces.

Each `S4.30` site captures raw into a file under its machine (the way
`shell-quicklist.sh` keeps `ctrlq.raw`), classifies, and puts the
classification into the check label. A `TIMEOUT` line additionally echoes the
load average — `uptime | sed 's/.*load average[s]*: //'`, the shape
`tests/nvim-shift-select.sh:280` already uses as `ss_load()`.

## The ceiling stays 40, and the gate proves it

The counterfactual needs a run that reaches the ceiling, and waiting 40 s for
one in every gate run is a cost this node does not need to pay. So: a third
helper that takes the ceiling as its **first argument**, used only by the
counterfactual probe, while `nu_pty` and `nu_pty_e` keep the literal `40` they
have today.

That opens a door the memo closes, so close it in the same change: a `--tree`
check asserts that `nu_pty` and `nu_pty_e` each still pass a **literal 40** to
the runner and that no `@` -parameterised or environment-overridable ceiling
reaches them. Widening the budget to buy green then goes red at the site that
forbids it, instead of relying on a reader remembering the memo.

## Check ids

Prefix `PT`. Free in this gate — the ids in use on 2026-08-24 are
`S1 S2 S3 S4 CP DO OH PB ST WG` (census:
`/usr/bin/grep -oE '\b[A-Z]{1,3}[0-9]?\.[0-9]+\b' tests/nushell-core.sh`),
and `PT` returns nothing.

## Acceptance

- [x] The classifier, fed a fabricated raw capture containing
      `<NUPTY-TIMEOUT>` and **no** `PWDIS:` line, prints `TIMEOUT:` and the
      check that consumes it goes red with a label naming a timeout — not
      `(got )`. Landed as `PT.1` in `--tree`, both halves quoted from the run:
      `PASS  tree: PT.1 a capture holding <NUPTY-TIMEOUT> and NO PWDIS line
      classifies as a timeout (got TIMEOUT:40s)` and `PASS  tree: PT.1
      counterfactual a timed-out capture FAILS the start-dir check, naming
      the timeout instead of an empty (got ) — (got TIMEOUT:40s)`.
- [x] The classifier, fed a fabricated raw capture whose `PWDIS:` line names
      the *wrong* directory, prints that directory and the check goes red with
      a label naming the wrong directory. `PT.2`: `PASS  tree: PT.2 a capture
      naming the WRONG directory classifies as that directory (got
      PWDIS:/machine/somewhere-else)` and `PASS  tree: PT.2 counterfactual a
      wrong-directory capture FAILS the start-dir check with the directory in
      the label (got PWDIS:/machine/somewhere-else)`. Same helper, same
      fabricated-capture shape, **different** failure text from `PT.1` — which
      is the whole finding.
- [x] A third counterfactual: a capture with neither marker nor `PWDIS:`
      classifies `NOANSWER`, distinct from both above. `PT.3`: `PASS  tree:
      PT.3 a capture with neither marker nor PWDIS classifies NOANSWER — a
      third finding (got NOANSWER)` and `PASS  tree: PT.3 counterfactual a
      no-answer capture FAILS the start-dir check, distinct from both above
      (got NOANSWER)`.
- [x] A **live** forced-timeout probe: the runner driven with a short ceiling
      (≤ 3 s) against a command that never prints emits `<NUPTY-TIMEOUT>`, and
      the classifier calls it `TIMEOUT`. Landed as `PT.4`, driving
      `pty_at 2 -- /bin/sh -c 'sleep 30'`. Wall time quoted from the run's own
      diagnostic line: `PT.4 live forced-timeout probe: 2s wall, raw=17 bytes,
      class=TIMEOUT:2s` — 2 s, inside the 5 s the spec allows, and the gate
      asserts that bound itself (`PASS  tree: PT.4 …at 2s of wall, not the
      40 s the real helpers budget`). The 17 raw bytes are exactly
      `\n<NUPTY-TIMEOUT>\n` and nothing else: `PASS  tree: PT.4 …and the
      marker really is in the raw bytes the old filter threw away`.
- [x] The timeout branch prints the load average on the same run. From that
      same `--tree` run, on the line immediately above the probe's own:
      `      TIMEOUT:2s — pty ceiling hit; load average: 3.86 13.43 18.01`.
      It goes to stderr because callers read `pwd_class_v`'s stdout as the
      classification.
- [x] `--tree` asserts `nu_pty` and `nu_pty_e` each pass a literal `40`.
      `PASS  tree: PT.5 nu_pty hands the runner a LITERAL 40 (reads 40)` and
      `PASS  tree: PT.5 nu_pty_e hands the runner a LITERAL 40 (reads 40)`,
      plus a control that the reader can tell the two apart at all:
      `PASS  tree: PT.5 …and the guard can tell a literal from a variable at
      all: pty_at reads VAR("$ceiling")`.
      **The red is quoted, and it is a real one, not a `chk_fail`.** A whole
      copy of the patched gate with both `40`s sed-replaced by `90`, run from
      a scratch tree outside the repo, ends `EXIT=1` on:
      `FAIL  tree: PT.5 nu_pty hands the runner a LITERAL 40 (reads 90)` /
      `FAIL  tree: PT.5 nu_pty_e hands the runner a LITERAL 40 (reads 90)`.
      In-gate, both the widened and the environment-overridable shapes are
      also carried as counterfactuals: `PASS  tree: PT.6 counterfactual
      nu_pty at a widened 90 s ceiling FAILS the literal-40 check (reads 90)`
      and `PASS  tree: PT.7 counterfactual an ENVIRONMENT-OVERRIDABLE ceiling
      FAILS the literal-40 check too — nu_pty reads
      VAR("${NUPTY_CEILING:-40}")`.
- [x] R5 holds: the four `S4.30` checks still conclude exactly what they
      concluded before about R7 — same directories asserted, same pass/fail
      meaning. Before, from `git show HEAD:tests/nushell-core.sh` run out of a
      scratch tree (`--hermetic`, 83 PASS / 0 FAIL, scratch `gates.1ixXUt`):

      ```
      PASS  hermetic: S4.30 startdir.txt holding an existing dir is where the shell opens (got PWDIS:…/m-start-hit/target)
      PASS  hermetic: S4.30 a startdir.txt pointing at a deleted path falls back to <HOME>/dev (got PWDIS:…/m-start-dead/home/dev)
      PASS  hermetic: S4.30 end-to-end: a move in one shell is where the NEXT shell opens (got PWDIS:…/m-start-e2e/home/landed)
      PASS  hermetic: S4.30 with startdir.txt absent the shell opens in <HOME>/dev (got PWDIS:…/m-start-none/home/dev)
      ```

      After, from the patched full run (scratch `gates.Y3mXih`): the same four
      labels with the same four `PWDIS:` answers under the new scratch root,
      plus the two unchanged boolean siblings (`precondition: <HOME>/dev does
      not exist yet`, `…and <HOME>/dev was created`). Six `S4.30` PASS lines
      before, six after, byte-identical apart from the scratch directory name.
      That is expected by construction: on a run with no `<NUPTY-TIMEOUT>` in
      the buffer, `pwd_class` returns the same `PWDIS:<dir>` string the old
      `$GREP -o 'PWDIS:.*' | head -1` pipeline returned.
- [x] `bash tests/nushell-core.sh` alone: `0 FAIL`, `EXIT=0`, tally **quoted
      not asserted**. Reading of 2026-08-24 on the patched file: **250 PASS /
      0 FAIL**, `EXIT=0`, 19.3 s wall. The baseline reading quoted for
      comparison, never asserted, was 233 PASS / 0 FAIL — this spec adds the
      seventeen `PT` checks.

## Verify and Proof

```sh
bash tests/nushell-core.sh --tree
bash tests/nushell-core.sh --hermetic
bash tests/nushell-core.sh
```
