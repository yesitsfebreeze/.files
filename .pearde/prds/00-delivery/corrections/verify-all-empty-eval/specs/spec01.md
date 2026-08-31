---
est: 0.75h
footprint:
  - prds/00-delivery/corrections/w0-4-s2-corrections/editor/specs/verify-all.sh
---

# spec01 — teach the runner that `""` is blank, and make skips visible

Fix `verify-all.sh` so a blanked `verify: ""` is skipped and counted instead
of evaluated, prove with fixtures that the runner can still fail, and leave a
comment that stops the next reader from "simplifying" the guard back to
`[ -z ]`. Covers ticket R1, R2 and R3.

## The measured defect

Run 2026-08-24, from the repo root and from `/tmp`:
`bash prds/00-delivery/corrections/w0-4-s2-corrections/editor/specs/verify-all.sh`
prints seven `line 37: : command not found` blocks (spec01, spec02, spec04,
spec05, spec06, spec07, spec08) and exits 1.

The extraction at lines 27–29 is

```sh
cmd=$(grep -m1 '^verify: ' "$spec" | sed 's/^verify: //')
cmd=${cmd#\`}
cmd=${cmd%\`}
```

Against a blanked spec the first `^verify: ` line is `verify: ""`, so after
the sed the value is the **two characters `""`** — no backtick to strip,
`[ -z "$cmd" ]` is false, and `eval '""'` runs the empty command name:
status 127, `: command not found`. The seven blanked specs each keep a
byte-identical copy of their retired command in a `## Spent proof` fence
further down the file; `grep -m1` stopping at the first match is what keeps
that copy inert, so the first-match semantics must survive this fix.

## Changes to `verify-all.sh`

1. **Guard.** After the backtick strip, treat the value `""` as blanked:

   ```sh
   if [ "$cmd" = '""' ]; then
     echo "SKIP  $name: verify is blanked (spent — see its ## Spent proof)"
     skipped=$((skipped + 1))
     continue
   fi
   ```

   Keep the existing `[ -z "$cmd" ]` branch as a FAIL — a spec with no
   `verify:` line at all is still a broken spec, not a spent one.

2. **Comment.** Above the guard, state the extraction shape: `verify: ""` is
   the board's blank encoding, it survives the sed and the backtick strip as
   the two quote characters, and `[ -z ]` alone therefore cannot catch it.
   Name `mi-rooted-verify-commands` spec02 as what blanked the seven. State
   that `grep -m1` must stay first-match so the `## Spent proof` copy is
   never run.

3. **Count.** Track `ran` and `skipped`. Rewrite the two summary lines so
   both counts always print, e.g.
   `OK — N ran green, M skipped (blanked).` and
   `RED — N ran, M skipped; see above.` A summary that hides the skip count
   reproduces the defect in the opposite direction (ticket R2).

4. Exit 0 iff no spec FAILed. All-skipped is a legal green: every guard in
   this directory can legitimately be spent.

## Counterfactual harness (ticket R3)

Run in a scratch directory, quote both outputs in the report:

```sh
T=$(mktemp -d); git -C "$T" init -q; mkdir "$T/specs"
cp prds/00-delivery/corrections/w0-4-s2-corrections/editor/specs/verify-all.sh "$T/specs/"
printf 'verify: ""\n' > "$T/specs/spec01.md"
printf 'verify: `false`\n' > "$T/specs/spec02.md"
bash "$T/specs/verify-all.sh"; echo "exit: $?"
```

Expected: one `SKIP  spec01` line, one `FAIL  spec02` line, exit 1. Without
the FAIL half this fix could have made the runner incapable of ever failing.

## Acceptance

- [x] `bash prds/00-delivery/corrections/w0-4-s2-corrections/editor/specs/verify-all.sh`
      prints zero `command not found` lines — quoted.
- [x] The seven blanked specs (spec01, spec02, spec04, spec05, spec06,
      spec07, spec08) each get one `SKIP` line naming them.
- [x] The summary line prints both counts — ran and skipped — on green and
      on red.
- [x] A spec file with no `verify:` line still produces a FAIL, distinct
      from a SKIP.
- [x] The comment states the `""` extraction shape and why `[ -z ]` alone
      was not enough, and pins `grep -m1` first-match semantics.
- [x] Counterfactual a: the fixture spec with `verify: ""` produces a SKIP
      line — output quoted.
- [x] Counterfactual b: the fixture spec with `` verify: `false` `` produces
      a FAIL line and overall exit 1 — output quoted.
- [x] `spec03` still RUNS (it is not blanked before spec02 of this node);
      its result is whatever its live command returns.

## Verify and Proof

```sh
bash prds/00-delivery/corrections/w0-4-s2-corrections/editor/specs/verify-all.sh 2>&1 \
  | grep -c 'command not found'   # must print 0
# plus the counterfactual harness above: SKIP + FAIL + exit 1, quoted.
```
