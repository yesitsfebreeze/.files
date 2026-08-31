---
complexity: 15
footprint:
  - gates/nushell-module-staging.sh
  - tests/help-agent.sh
  - tests/help-browser.sh
  - tests/nushell-aliases.sh
  - tests/nushell-core.sh
  - tests/shell-claude.sh
  - tests/shell-help.sh
  - tests/shell-history.sh
  - tests/shell-listing.sh
  - tests/shell-quicklist.sh
  - tests/shell-television.sh
  - tests/shell-zoxide.sh
---

# spec02 — the hyphen the staging gate could not see, and the eleven gates

Adding one `source` line to `config.nu` kills every gate that stages a
hermetic nushell HOME, at PARSE, with `nu::parser::sourced_file_not_found`,
before one assertion of its own runs. `gates/nushell-module-staging.sh` exists
precisely to report that class of outage — and it could not report this one.
It derives the module list with `^source ~/\.config/nushell/[a-z]+\.nu$`:
**no hyphen**, so `help-check.nu` never enters the list and the gate passes,
printing "misses: 0", while eleven gates are broken. This unit widens the
derivation, stages the module in all eleven, and proves the gate discriminates
afterwards — a fix that leaves the gate unable to fail is the same defect
wearing a patch.

A **second**, independent hyphen hole sits in the same gate and was found only
by building: `names_it`'s list-driven branch matched a stem with
`(^|[^a-zA-Z0-9_])$stem(\.nu)?([^a-zA-Z0-9_.]|$)`. `-` is in neither boundary
class, so with `help-check` present in a `for m in` list the stem `help`
matches the `help` inside `help-check`, and a gate that dropped `help.nu`
entirely would still read as staging it. That is the gate's OWN selftest GREEN
half, which deletes `help` from `tests/shell-television.sh` and requires red
before repair — so the hole would have made the selftest vacuous the moment
this node landed. Both boundary classes must exclude `-`.

**What already stands** (uncommitted, built and measured 2026-08-29): both
copies of the derivation regex widened to `[a-z-]+`
(`gates/nushell-module-staging.sh:83` and the second, private copy in
`tests/help-agent.sh:151 modules_fresh`); `names_it`'s boundary classes
tightened; the selftest's two `sed` expressions rewritten from `[a-z ]*` (which
can no longer match a hyphenated list) to anchor on `help-check`; and all
eleven gates staging the module in their own idiom — two `MODULES=` constants
(`help-agent:147`, `shell-help:101`), three `for m in` lists
(`help-browser:517`, `shell-quicklist:671`, `shell-television:565`) and six
explicit `cp` lines (`nushell-aliases`, `nushell-core`, `shell-claude`,
`shell-history`, `shell-listing`, `shell-zoxide` — exactly
`tests/shell-help.sh:105`'s `SIBLINGS`). Measured: the gate derives 14 modules,
the 10x14 grid is all `.`, Part A proves dropping `help-check.nu` is fatal at
`config.nu:609`, `--selftest` is rc=0 both halves, the counterfactual that
removes `help-check` from one gate's list produces `MISS ... does not stage
help-check.nu`, and all eleven gates run green (1043 assertions, zero FAILs).

**What is left**: the gate's header comment and `tests/help-agent.sh:138-146`
still describe the pre-fix world — "Known state on 2026-08-23: ZERO misses"
with no mention that the derivation was blind to hyphens or that the stem
predicate was. In this suite the comment IS the contract, and the next
hyphenated module is the next silent outage, so record both defects and their
counterfactuals where the next reader will hit them.

The `--repo` override is how every counterfactual runs: a gate that induces its
violation in the real tree corrupts the thing it measures.

## Acceptance

- [x] no `^source ~/\.config/nushell/[a-z]+\.nu$` remains in the repo; both
      copies read `[a-z-]+` (`gates/nushell-module-staging.sh`,
      `tests/help-agent.sh`)
- [x] `names_it`'s stem boundary classes both exclude `-`
- [x] `bash gates/nushell-module-staging.sh` exits 0, derives `help-check` in
      its module list, and prints `misses: 0`
- [x] its Part A prints `drop help-check.nu rc=1 at=config.nu:<the line that
      sources it>` with `nu::parser::sourced_file_not_found`
- [x] `bash gates/nushell-module-staging.sh --selftest` exits 0, both halves,
      including the GREEN half's red-before-repair
- [x] against a scratch copy with `help-check` removed from ONE gate's staging
      list, `gates/nushell-module-staging.sh --repo <copy>` exits non-zero and
      names that gate and `help-check.nu`
- [x] against a scratch copy with `help` removed from `shell-television`'s
      `for m in` list while `help-check` stays, the gate still reports
      `does not stage help.nu` — the boundary fix, proven rather than read
- [x] all eleven gates exit 0: `help-agent help-browser nushell-aliases
      nushell-core shell-claude shell-help shell-history shell-listing
      shell-quicklist shell-television shell-zoxide`
- [x] `gates/nushell-module-staging.sh`'s header records the hyphen defect in
      the derivation AND the one in `names_it`, each with the counterfactual
      that catches it, and `tests/help-agent.sh`'s `modules_fresh` comment says
      its regex is a second copy that must move with the gate's

## Verify and Proof

```sh
cd "$(git rev-parse --show-toplevel)"

# no narrow copy of the derivation survives
! grep -rn 'nushell/\[a-z\]+' gates tests

# the gate, its self-proof, and the eleven
bash gates/nushell-module-staging.sh            | grep -E 'help-check|misses:|drop help-check'
bash gates/nushell-module-staging.sh; echo "gate rc=$?"
bash gates/nushell-module-staging.sh --selftest; echo "selftest rc=$?"
for g in help-agent help-browser nushell-aliases nushell-core shell-claude \
         shell-help shell-history shell-listing shell-quicklist \
         shell-television shell-zoxide; do
  bash "tests/$g.sh" >/dev/null 2>&1; echo "$g rc=$?"
done

# counterfactual A — a gate that stops staging help-check must go red
T=$(mktemp -d); cp -R home tests gates "$T"/
sed -i '' -E 's/^(  for m in .*copymode) help-check help; do$/\1 help; do/' \
  "$T/tests/shell-television.sh"
bash gates/nushell-module-staging.sh --repo "$T" 2>&1 | grep 'does not stage help-check.nu'

# counterfactual B — the boundary fix: dropping help while help-check stays
T2=$(mktemp -d); cp -R home tests gates "$T2"/
sed -i '' -E 's/^(  for m in .*help-check) help; do$/\1; do/' \
  "$T2/tests/shell-television.sh"
bash gates/nushell-module-staging.sh --repo "$T2" 2>&1 | grep 'does not stage help.nu'
```
