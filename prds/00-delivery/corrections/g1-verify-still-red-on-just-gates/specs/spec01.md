---
complexity: 30
footprint:
  - tests/shell-init.sh
---

# spec01 — `tests/shell-init.sh`'s two `apply:` reds are fixture defects; make both checks say what they mean

R2 asked whether S1.10 is a real regression — a user's television config being
overwritten by an apply — or a defect in the gate's own fixture. **It is a
fixture defect, and nothing overwrites a user's television config.** Both
`apply:` reds are, and neither was caused by `0b77a71`. The evidence is below,
and the work is to replace two checks that could not pass with two that can,
each with a counterfactual proving it can still fail.

## What was measured, and where

`bash tests/shell-init.sh --apply` was run from `git worktree` copies at three
commits. `home/dot_config/television/config.toml` and `tests/shell-init.sh`
**landed in the same commit**, `2714042`:

| tree | `S1.10` | `R4 chezmoi managed` |
|---|---|---|
| `2714042` — the commit that added this gate | FAIL | PASS |
| `0b77a71~1` — before the litellm node | FAIL | FAIL |
| `HEAD` | FAIL | FAIL |

**S1.10.** The block wrote `p4-sentinel = true` into
`$S/home/.config/television/config.toml`, called it "hand-written", and
asserted it byte-identical after the apply. But
`home/dot_config/television/config.toml` is a **managed source file**, so that
target is a managed target and `chezmoi apply` restores it — correctly. The
check has been red since the day it was written and could never have been
green. The real failure mode it names — the run_after generator's `tv init nu`
clobbering the file — is untested by it, and is separately proven green
against the real tv by the `--live` stage's `S3.17`.

**R4.** The pattern was the unanchored `(starship|zoxide|television)\.nu`,
matched against all of `chezmoi managed`. Measured in a scratch apply of the
real `home/`, the single line it returns is `.config/nushell/zoxide.nu` — the
zoxide **nushell module**, a legitimate managed file landed by
`04-shell/03-zoxide` in `35e0fb4`, which is why the check went red between
`2714042` and `0b77a71~1`. A basename collision outside the init directory is
not what R4 claims; the claim is that nothing under `.cache/nushell/init/` is
managed.

## Two traps, both hit while building this

1. `cz()` wraps every chezmoi call in `/usr/bin/env -i`. A counterfactual knob
   read as an environment variable *inside* the tv stub therefore never
   arrives, and the stage reports green while clobbering nothing — measured.
   The knob must be **baked into the stub at write time**, in the gate
   process.
2. A `chk_fail` passes just as happily on a typo in its pattern as on a
   correct tree. The anchored pattern needs its own positive check.

## Acceptance

- [x] `S1.10`'s baseline is the **source** file
      (`$S/src/dot_config/television/config.toml`), captured before the apply,
      and the check asserts the deployed target still equals it — i.e. the
      run_after generator left chezmoi's own output alone.
      — `tests/shell-init.sh` `stage_apply`: `local tvsrc="$S/src/dot_config/television/config.toml"`,
      `tv_want="$(sha_file "$tvsrc")"` taken **before** `cz "$S" apply`, and the
      post-apply assertion is
      `PASS  apply: S1.10 the generator left ~/.config/television/config.toml exactly as chezmoi wrote it`.
- [x] The deployed file's existence is asserted separately, so the comparison
      cannot pass by comparing two `<absent>`s.
      — two separate lines, and both are green:
      `PASS  apply: precondition: television/config.toml is a managed source file`
      and `PASS  apply: chezmoi deployed ~/.config/television/config.toml`.
      (`sha_file` returns the literal string `<absent>` for a missing path, so
      without these the equality would have been satisfiable by absence —
      the failure mode `prds/memos/an-absence-assertion-needs-a-positive-precondition-or-it-is-green-on-a-blank-screen.md`
      names.)
- [x] A counterfactual drives `S1.10` red: with the generator **unmutated**, a
      tv stub that appends one line to the deployed
      `~/.config/television/config.toml` makes `stage_apply` exit non-zero.
      — `bash tests/shell-init.sh`, counterfactual block:
      `PASS  counterfactual: --apply goes red when tv appends to the deployed television config (S3.8)`.
      A `cf` line reads PASS when the mutated stage went **red**, which is the
      claim.
- [x] The knob that arms that stub is applied when the stub is written, not
      read from the environment inside it, and a comment records `env -i` as
      the reason. — `cf_clobber` is expanded into the `cat > .../tv` heredoc in
      the gate process; its comment reads "It is baked into the stub HERE, in
      the gate process, rather than tested inside the stub at run time: `cz()`
      wraps every chezmoi call in `env -i`, so no variable this gate exports
      survives into a run_after script's child. Measured 2026-08-28 — the first
      version of this counterfactual did read it at run time and reported a
      green stage while clobbering nothing."
- [x] `R4`'s `chezmoi managed` pattern is anchored at `$INIT_REL`, and a
      comment names `.config/nushell/zoxide.nu` and `35e0fb4` as the measured
      collision. — the pattern is
      `(^|/)${INIT_REL}/(starship|zoxide|television)\.nu$`; the comment names
      both. Green as
      `PASS  apply: R4 chezmoi managed lists none of the three generated files under .cache/nushell/init/`.
- [x] A companion check proves the anchored pattern still **matches** a
      managed init path, so a typo in it cannot read as a pass.
      — `PASS  apply: R4's anchored pattern does match a managed init path (teeth)`,
      the same regex fed `.cache/nushell/init/television.nu`.
- [x] Every replaced check carries a comment saying what it used to assert,
      which commits it was measured red at, and that the red was a fixture
      defect rather than a regression. — both carry a `CORRECTED 2026-08-28
      (g1-verify-still-red-on-just-gates R2)` block naming `2714042`,
      `0b77a71~1` and `HEAD` for S1.10, and `0b77a71~1` plus `35e0fb4` for R4,
      each saying in terms that the red was a fixture defect.
- [x] `bash tests/shell-init.sh` exits 0 with no `FAIL` line.
      — `FULL EXIT=0`, **100 PASS / 0 FAIL**, ending
      `PASS — shell-init generation holds, and nothing real was written`.
      `bash tests/shell-init.sh --apply` on its own is `EXIT=0`, 45 PASS / 0
      FAIL. **This took one further fix, recorded below.**

## A third stale check, found by running this — `S3.10`

Corrected 2026-08-29, in this file, under R3.

The first `--apply` run of this pass was `EXIT=1` on a red neither this spec
nor the node had seen:

```
FAIL  apply: I2 chezmoi status is empty once the always-run script line is
      removed (got:  R seed-mason-registry.sh)
```

`S3.10` filtered chezmoi's status with `grep -v 'generate-shell-init\.sh'` — one
literal script name, correct on the day it was written because that was the
only always-run script in `home/`. `5e7934c` (2026-08-29, "C.4 harness + R7's
seeder") added a **second**, `home/run_after_seed-mason-registry.sh`. chezmoi
reports every always-run script as pending `R` on every status forever, by
design, so the gate read a correctly-added script as a regression.

The fix is the same one this node has now applied three times: replace the
hand-kept name with a predicate over the tree. `always_run_targets <srcdir>`
returns the chezmoi **target** name of every `run_*` that is neither
`run_once_*` nor `run_onchange_*` — target name, because chezmoi strips the
`run_`/`before_`/`after_` attributes from what it prints. Three assertions
replace the two:

- the source holds at least one always-run script — without which "nothing but
  always-run lines" would be green on a status that is empty because nothing
  ran;
- the status is empty once **every** always-run line is removed;
- and **every** always-run script has its own status line.

Measured after: `PASS  apply: precondition: the source holds at least one
always-run script (n=2: generate-shell-init.sh seed-mason-registry.sh )`.

The teeth are not hypothetical and were not staged: the pre-fix red above *is*
the old one-name filter failing against the two-script tree, observed before
the fix and quoted verbatim.

## Verify and Proof

```sh
bash -n tests/shell-init.sh
bash tests/shell-init.sh --apply; echo "EXIT=$?"
bash tests/shell-init.sh; echo "EXIT=$?"
# the two replaced checks and their teeth, by name
bash tests/shell-init.sh --apply 2>&1 | grep -E 'S1\.10|teeth|R4 chezmoi managed|tv appends'
```
