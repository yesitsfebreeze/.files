---
complexity: 9
footprint:
  - home/dot_config/nushell/config.nu
  - home/dot_config/nushell/help.nu
  - home/dot_config/nushell/help-check.nu
  - tests/shell-help.sh
---

# spec01 — `help --check` parses and dispatches, and the source order is gated

`help --check` is a `nu::parser::unknown_flag` today because `def help` has
nine flags and none of them is `--check`. This unit closes that: the flag on
`def help`, a one-line delegation to `_help_check`, the separate
`help-check.nu` that holds it, and the `config.nu` `source` line placed ABOVE
`help.nu`. The check cannot live in `help.nu` — `tests/shell-help.sh`'s
`render_no_spawn_ok` greps that file for `nvim|wezterm|git|tv|chezmoi` in
command position and `browse_only_spawner_ok` asserts `_help_browse` is its
only spawner, and `--check` spawns `nvim --headless`. The order is not a
convention: a `def` calling a `def` from a LATER `source` fails at run time,
measured, with ``Command `_help_check` not found`` at `help.nu:713`.

**What already stands** (uncommitted in the tree, built and measured
2026-08-29): `home/dot_config/nushell/help-check.nu` exists and parses;
`config.nu:609` sources it and `config.nu:610` sources `help.nu`;
`help.nu` carries `--check` in `def help`'s signature and
`if $check { return (_help_check) }` as clause 0. On a hermetic machine
`help --check` produces zero `unknown_flag` matches and enters
`help-check.nu`. Swapping the two `source` lines reproduces the run-time
`Command not found`.

**What is left**: the ordering has no gate. `tests/shell-help.sh:154
capture_ok` already asserts the chain
`# ── MODULES ── < history.nu < use std/help < alias core-help < help.nu <
# ── PALETTE ──`, each spelling present exactly once. Extend that chain with
`source ~/.config/nushell/help-check.nu`, positioned strictly after
`alias core-help = help` and strictly before `source
~/.config/nushell/help.nu`, counted exactly once — so the run-time failure
proven by counterfactual becomes a static red rather than a surprise in a
live shell. The gate's own counterfactual style applies: the new clause must
FAIL against a config.nu with the two lines swapped, or it is not a gate.

Nothing about what `_help_check` COMPUTES is in this unit. The resolvers, the
allowlist and the report/exit-code contract are siblings 02, 03, 05 and 06;
this unit is satisfied when the flag reaches `_help_check` at all.

## Acceptance

- [x] `def help` in `home/dot_config/nushell/help.nu` carries `--check` with
      the house trailing `#` comment, and `if $check { return (_help_check) }`
      runs before the `--delegate` clause
- [x] `home/dot_config/nushell/help.nu` still contains no spawn target —
      `tests/shell-help.sh`'s `render_no_spawn_ok` and `browse_only_spawner_ok`
      both pass
- [x] `config.nu` contains `source ~/.config/nushell/help-check.nu` exactly
      once, strictly below `alias core-help = help` and strictly above
      `source ~/.config/nushell/help.nu`
- [x] `tests/shell-help.sh`'s `capture_ok` asserts that position, and a
      counterfactual copy with the two `source` lines swapped makes
      `tests/shell-help.sh` exit non-zero naming the order
- [x] on a hermetic machine staging the repo tree, `help --check` emits no
      `nu::parser::unknown_flag`; any error it does emit is located inside
      `help-check.nu`, not inside the parser
- [x] `bash tests/shell-help.sh` exits 0

## Verify and Proof

```sh
cd "$(git rev-parse --show-toplevel)"

# the flag and the clause
grep -n -- '--check' home/dot_config/nushell/help.nu
grep -n '_help_check' home/dot_config/nushell/help.nu

# the source order, exactly once each and in this order
grep -nxF 'alias core-help = help'                     home/dot_config/nushell/config.nu
grep -nxF 'source ~/.config/nushell/help-check.nu'     home/dot_config/nushell/config.nu
grep -nxF 'source ~/.config/nushell/help.nu'           home/dot_config/nushell/config.nu

# the gate, and the counterfactual that proves the new clause can fail
bash tests/shell-help.sh; echo "shell-help rc=$?"
T=$(mktemp -d); cp -R home tests gates "$T"/
python3 - "$T/home/dot_config/nushell/config.nu" <<'PY'
import sys
p=sys.argv[1]; s=open(p).read()
a="source ~/.config/nushell/help-check.nu\nsource ~/.config/nushell/help.nu\n"
b="source ~/.config/nushell/help.nu\nsource ~/.config/nushell/help-check.nu\n"
assert s.count(a)==1
open(p,'w').write(s.replace(a,b))
PY
# The mutated tree MUST fail, and must fail by naming the order clause. Both
# halves are asserted, and neither may abort the block: this runner is
# `set -e -o pipefail`, so the mutated gate's correct rc 1 would otherwise
# kill the run through the pipe before the assertion is ever reached.
cf_out=$( cd "$T" && bash tests/shell-help.sh 2>&1 ) && cf_rc=0 || cf_rc=$?
echo "cf rc=$cf_rc (expect non-zero: the swapped source order must break the gate)"
test "$cf_rc" -ne 0 || { echo "COUNTERFACTUAL VACUOUS: swapped order still passes"; exit 1; }
printf '%s\n' "$cf_out" | grep -i 'FAIL.*help-check' \
  || { echo "COUNTERFACTUAL RED FOR THE WRONG REASON: not the order clause"; exit 1; }

# the flag dispatches on a hermetic machine (the parent probe's harness)
P=prds/06-help/04-drift-check/probe
M=$(bash $P/mk-machine.sh | head -1)
# Print the number AND assert it. A bare `grep -c` exits 1 on a zero count,
# so under `set -e -o pipefail` the EXPECTED answer aborts the block — the
# defect this board has now hit in three separate verify blocks.
uf=$( bash $P/nu-c.sh "$M" 'help --check' 2>&1 | grep -c 'unknown_flag' ) || true
echo "unknown_flag occurrences: $uf (expect 0)"
test "$uf" -eq 0
```
