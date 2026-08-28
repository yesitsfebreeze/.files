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

- [ ] `S1.10`'s baseline is the **source** file
      (`$S/src/dot_config/television/config.toml`), captured before the apply,
      and the check asserts the deployed target still equals it — i.e. the
      run_after generator left chezmoi's own output alone.
- [ ] The deployed file's existence is asserted separately, so the comparison
      cannot pass by comparing two `<absent>`s.
- [ ] A counterfactual drives `S1.10` red: with the generator **unmutated**, a
      tv stub that appends one line to the deployed
      `~/.config/television/config.toml` makes `stage_apply` exit non-zero.
- [ ] The knob that arms that stub is applied when the stub is written, not
      read from the environment inside it, and a comment records `env -i` as
      the reason.
- [ ] `R4`'s `chezmoi managed` pattern is anchored at `$INIT_REL`, and a
      comment names `.config/nushell/zoxide.nu` and `35e0fb4` as the measured
      collision.
- [ ] A companion check proves the anchored pattern still **matches** a
      managed init path, so a typo in it cannot read as a pass.
- [ ] Every replaced check carries a comment saying what it used to assert,
      which commits it was measured red at, and that the red was a fixture
      defect rather than a regression.
- [ ] `bash tests/shell-init.sh` exits 0 with no `FAIL` line.

## Verify and Proof

```sh
bash -n tests/shell-init.sh
bash tests/shell-init.sh --apply; echo "EXIT=$?"
bash tests/shell-init.sh; echo "EXIT=$?"
# the two replaced checks and their teeth, by name
bash tests/shell-init.sh --apply 2>&1 | grep -E 'S1\.10|teeth|R4 chezmoi managed|tv appends'
```
