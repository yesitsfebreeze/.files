---
complexity: 40
# compute: three extra pty machines in stage_hermetic. Measured 2026-08-24:
#          2.0 s wall for all three, against a 13.6 s whole-gate baseline.
#          No scope change is bought by trimming them.
footprint:
  - tests/nushell-core.sh
verify: "bash tests/nushell-core.sh"
---

# spec02 — the consequence, hermetically: same error, opposite outcome

`tests/nushell-core.sh`'s `--hermetic` stage gains three machines that drive
R4: a throwing PWD closure inserted **ahead** of the dirstack push leaves
`dirs.txt` **never created**, the byte-identical closure appended **last**
leaves it recording both moves, and the unmodified config is the control. Four
new checks, `DO.6` – `DO.9`. This spec touches no other file and needs nothing
from spec01 — the ids continue that spec's series and nothing else does.

R4 says *lift M4/M5 from
[`pwd-closure-blast-radius`](../../pwd-closure-blast-radius/specs/spec01.md),
do not re-derive*. They are lifted below, **and re-run in this gate's own
harness** before being specced, because M4/M5 were measured in a standalone
rig and what has to go green is this file's `mk_machine` + `nu_pty`.

## Where it lands

In `stage_hermetic`, immediately after the `ST.4` block restores
`MACHINE_CFG="$SAVED_CFG"` (today `tests/nushell-core.sh:1122` — a reading of
2026-08-24, not a constant). ST.3/ST.4 directly above are the pattern this
follows: derive a config copy into `$SCRATCH`, point `MACHINE_CFG` at it,
build a machine, drive it under `nu_pty`, and **restore `MACHINE_CFG` when
done**. An unrestored `MACHINE_CFG` silently re-points every machine below.

## The fixture

One extra PWD closure, written to a file so both copies get the same bytes:

```sh
local EXTRA="$SCRATCH/pwd-thrower.nu"
cat > "$EXTRA" <<'NUEOF'
$env.config.hooks.env_change.PWD = (
    $env.config.hooks.env_change.PWD
    | append {|before, after|
        if $before != null and $after != $before and $nu.is-interactive {
            ^definitely-not-a-binary e> /dev/null
        }
    }
)
NUEOF
local CAH="$SCRATCH/cfg-thrower-ahead.nu" CAF="$SCRATCH/cfg-thrower-after.nu"
sed -e "/^# ── HOOKS ──\$/r $EXTRA" "$CONFIG_NU" > "$CAH"
{ cat "$CONFIG_NU"; cat "$EXTRA"; } > "$CAF"
```

Three things about that, each of which cost a measurement:

- **The block comes from a FILE, never `awk -v`.** `awk -v x="$MULTILINE"`
  dies with `awk: newline in string` and writes a truncated config carrying
  **zero** PWD appends; the machine then runs a config that proves nothing and
  `dirs.txt` is absent for the wrong reason. Measured 2026-08-24.
- **`sed … r` inserts AFTER the anchor line**, so the block lands at 370 —
  above the dirstack's own append at 388 in that copy. That is what makes it
  the FIRST append, which is the whole experiment.
- **The guards are copied from the dirstack closure verbatim.**
  `$before != null` is what makes the startup fire skip, so two `cd`s give two
  error boxes and not three.

`^definitely-not-a-binary` is resolvable nowhere; no PATH narrowing is needed
and none should be added. The `ST.x` machines narrow `$env.PATH` because
`stty` is a real binary that `env.nu` puts back — a different problem.

## The checks

- **DO.6 — the two copies differ only in insertion point.** Same `wc -l`
  (863 today), each with exactly three `$env.config.hooks.env_change.PWD = (`
  lines and exactly one `^definitely-not-a-binary` line, and the extra block's
  own line number printed for each (370 vs 856 today). Print the pair; an
  equal pair means the `sed` no-opped and both halves below would agree for a
  reason that has nothing to do with order.
- **DO.7 — AHEAD: `dirs.txt` is never created.** `MACHINE_CFG="$CAH"`, a fresh
  machine with `s1`/`s2`, `nu_pty` sending `cd …/s1`, `cd …/s2`, `exit`. Then
  `chk_fail test -f "$M/home/.local/state/nushell/dirs.txt"` — **absent, not
  empty and not stale** — and `chk_ok` that the transcript carries
  `nu::shell::external_command` twice, so the machine is proved to have fired
  the thrower rather than to have failed to start.
- **DO.8 — AFTER: the same closure, appended last, records both moves.**
  `MACHINE_CFG="$CAF"`, same drive. `dirs.txt` equals
  `printf '%s\n%s' "$M/home/s2" "$M/home/s1"` — the ST.2 comparison, verbatim
  — with the **same two** error boxes. Same error, opposite outcome, decided
  only by position.
- **DO.9 — the control.** `MACHINE_CFG="$CONFIG_NU"`, same drive: `dirs.txt`
  records both moves and the transcript carries **zero**
  `nu::shell::external_command`. Without it, DO.8 cannot distinguish "the
  dirstack survived the thrower" from "this machine records moves anyway".

Restore `MACHINE_CFG="$SAVED_CFG"` after DO.9. Echo one `      ` diagnostic
line per machine in the file's house style — boxes, name hits, and the
`dirs.txt` contents or `<ABSENT>` — because that line is what a reader of a
red run has.

## The measurements

Re-run 2026-08-24 in a harness assembled from this gate's own parts: the pty
runner extracted from `tests/nushell-core.sh:182-298`, the machine layout of
`mk_machine`, `nu 0.114.1`, `--env-config env.nu`, two `cd`s then `exit`.
Rig at
`/private/tmp/claude-501/-Users-feb-dev-dotfiles/213855ec-904d-4391-9d38-797ec60472ad/scratchpad/m4m5b.sh`.

| Machine | `nu::shell::external_command` | `dirs.txt` |
|---|---|---|
| thrower AHEAD of the dirstack push | 2 | **`<ABSENT>`** |
| thrower appended LAST | 2 | `…/s2 \| …/s1` |
| control, unmodified `config.nu` | 0 | `…/s2 \| …/s1` |

Verdict: **reproduced** — M4 and M5 hold in this gate's harness, and the run
costs 2.0 s wall for all three machines.

Run again with a **different thrower body**, `error make {msg:
"boom-ordering-probe"}` in place of the missing external: AHEAD `<ABSENT>`,
AFTER `…/s2|…/s1`, control unchanged. The mechanism is the abort, not the
missing binary — which is also M1/M2's finding, now confirmed on the ordering
half. Note the arithmetic changes with the body: `error make` produces **0**
`nu::shell::external_command` and four mentions of its message. **Spec the
missing-external body**, so DO.7/DO.8's box counts mean what they say, and do
not copy the count across bodies.

## Acceptance

- [x] DO.6 PASSES twice, with the pair quoted: `DO.6 ahead: 864 lines,
      thrower at 374; after: 864 lines, thrower at 861` →
      `PASS  hermetic: DO.6 the two thrower copies have the same line count and
      three PWD appends each` and `PASS  hermetic: DO.6 …and the thrower sits
      at a DIFFERENT line in each (374 ahead vs 861 last)`. 864, not the spec's
      863 — this node's own R5 comment line landed in `config.nu` first.
- [x] DO.7's `chk_fail` on `test -f …/dirs.txt` PASSES. Diagnostic:
      `DO.7 AHEAD: external_command boxes=2, name hits=6, dirs.txt=<ABSENT>`
      → `PASS  hermetic: DO.7 with the thrower AHEAD of the dirstack push,
      dirs.txt is never created` and `PASS  hermetic: DO.7 …and the machine
      really fired the thrower (two nu::shell::external_command)`. M4
      **reproduced** in this gate's own harness (fixture:
      `$SCRATCH/cfg-thrower-ahead.nu` + `mk_machine`/`nu_pty`, nu 0.114.1).
- [x] DO.8 PASSES, and reads directly beside DO.7's line:
      `DO.8 AFTER: external_command boxes=2, name hits=6,
      dirs.txt=…/m-thrower-after/home/s2|…/m-thrower-after/home/s1`
      → `PASS  hermetic: DO.8 the same closure appended LAST leaves the
      dirstack recording BOTH moves` and `PASS  hermetic: DO.8 …with the SAME
      two error boxes`. Same error, same two boxes, opposite outcome —
      M5 **reproduced** (same fixture, insertion point the only difference).
- [x] DO.9 PASSES: `DO.9 CONTROL: external_command boxes=0,
      dirs.txt=…/m-thrower-control/home/s2|…/m-thrower-control/home/s1`
      → `PASS  hermetic: DO.9 control: the unmodified config records both
      moves` and `PASS  hermetic: DO.9 …with ZERO
      nu::shell::external_command`.
- [x] `MACHINE_CFG` is restored. From `git diff -- tests/nushell-core.sh`,
      the four added assignments are `+  MACHINE_CFG="$CAH"`,
      `+  MACHINE_CFG="$CAF"`, `+  MACHINE_CFG="$CONFIG_NU"` and, as the last
      line of the block, `+  MACHINE_CFG="$SAVED_CFG"`.
- [x] The gate is insertions-only: `256	0	tests/nushell-core.sh`
      for both specs together — 0 deletions.
- [x] `bash tests/nushell-core.sh` run alone reaches `EXIT=0` with
      **233 PASS / 0 FAIL** in 16.7 s — the re-measured 212-PASS baseline
      plus spec01's 13 and this spec's 8 checks. A reading, not an absolute.
      One caveat worth the record: the FIRST full run after this block landed
      **stalled** past 6m40s and reported one red, `FAIL  hermetic: S4.30
      end-to-end … (got )`, i.e. an empty `nu_pty_e` capture. It did **not**
      reproduce — the two runs after it were 16.7 s and 16.0 s, both
      233 PASS / 0 FAIL, and the
      `--hermetic` stage alone is 83 PASS / 0 FAIL in 12.7 s. Verdict on the
      stall: **unmeasured** (one observation, no reproduction; fixture: full
      gate on this working tree). S4.30 is `04-shell/01`'s check and outside
      this node's footprint — reported, not touched.

## Out of scope

- The textual order and roster checks, `config.nu`'s comment line, and the
  `DO.1` – `DO.5` ids. spec01.
- `ST.1` – `ST.4` above, and their PATH-narrowing. They belong to
  `unguarded-startup-externals` and are untouched.
- Any change to `mk_machine`, `nu_pty`, or the pty runner. The three machines
  here use them exactly as ST.3/ST.4 do; if one of them needs a change, that
  is a finding, not an edit.
- `config.nu`. Not in this spec's footprint.

## Verify and Proof

```sh
cd /Users/feb/dev/dotfiles

# the four checks and their diagnostics
bash tests/nushell-core.sh --hermetic 2>&1 | /usr/bin/grep -E 'DO\.[6-9]|dirs\.txt'

# insertions only
git diff --numstat -- tests/nushell-core.sh

# the gate, ALONE (~14 s)
bash tests/nushell-core.sh
```
