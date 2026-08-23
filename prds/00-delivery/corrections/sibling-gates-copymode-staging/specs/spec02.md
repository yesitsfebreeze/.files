---
est: 1.5h
footprint:
  - gates/nushell-module-staging.sh
---

# spec02 — `gates/nushell-module-staging.sh`, the staging drift gate

The defect this node corrects is not a missing line. It is that adding a
`source` to `config.nu` does not force the gates to notice. `copymode.nu`
arrived at `config.nu:436` and six gates went silently red; `help.nu`
arrived at `config.nu:450` and `shell-television` went red the same way and
is still red. Nothing in the suite reports that class. This gate does.

It derives BOTH sides — the module list from `config.nu`, the gate list
from `tests/` — so neither can go stale. `tests/shell-help.sh` already
holds the hand-maintained version of this idea: a `MODULES=` string and a
`SIBLINGS=` string of six gate names, with a per-sibling staging check. It
passes 60/60 today and still missed `shell-television` entirely, because
`shell-television` is not in its `SIBLINGS` list. A maintained list is the
failure mode, not the fix.

## Part A — the authoritative module list, proven by parsing

Derive the list from `config.nu` itself:

```sh
CONFIG_NU="$REPO_ROOT/home/dot_config/nushell/config.nu"
MODULES="$(/usr/bin/grep -oE '^source ~/\.config/nushell/[a-z]+\.nu$' "$CONFIG_NU" \
           | sed 's|.*/||')"
```

Ten today: `dirstack pass claude zoxide history capsule finder copymode
help theme`, all `.nu`.

A regex is a guess until it is executed, so prove the list IS the
parse-time requirement set:

- Build one scratch machine: `$M/home/.config/nushell/` holding every
  derived module copied from `home/dot_config/nushell/`, plus
  `$M/home/.cache/nushell/init/{starship,zoxide,television}.nu` as one-line
  stubs, because `config.nu:420-422` sources those three literal paths too.
- `nu --no-history --config "$CONFIG_NU" --env-config "$ENV_NU" -c 'exit 0'`
  under `/usr/bin/env -i` with `HOME="$M/home"` and an explicit `PATH`
  exits 0.
- For each derived module in turn: delete it from the machine, re-run, and
  require exit non-zero AND `nu::parser::sourced_file_not_found` naming
  that module's own line in `config.nu`. Restore it and continue.

Eleven `nu` runs, each well under a second. A module the regex missed would
show up here as an exit-0 run where the deletion should have been fatal.

Measured 2026-08-23 — the full machine parses silently, and every deletion
is fatal at its own line. This is the table the gate must reproduce:

```
ALL STAGED rc=0 bytes=0
drop dirstack.nu    rc=1 at=config.nu:285
drop pass.nu        rc=1 at=config.nu:430
drop claude.nu      rc=1 at=config.nu:431
drop zoxide.nu      rc=1 at=config.nu:432
drop history.nu     rc=1 at=config.nu:433
drop capsule.nu     rc=1 at=config.nu:434
drop finder.nu      rc=1 at=config.nu:435
drop copymode.nu    rc=1 at=config.nu:436
drop help.nu        rc=1 at=config.nu:450
drop theme.nu       rc=1 at=config.nu:510
```

Do not name the drop loop's variable `m` if the machine builder also loops
on `m`. A shell function shares the caller's scope, so the builder's loop
overwrites it and every iteration then deletes the same module — measured,
and it produced ten identical `theme.nu` rows that all looked like passes.

## Part B — the in-scope gate list, derived

A gate is in scope when it writes a `.nu` file into a scratch
`.config/nushell` directory. One grep, no list:

```sh
GATES="$(/usr/bin/grep -lE 'cp +"[^"]+" +"[^"]*/\.config/nushell/[^"]*\.nu"' \
         "$REPO_ROOT"/tests/*.sh)"
```

Measured 2026-08-23 this selects exactly eight — `nushell-aliases`,
`nushell-core`, `shell-claude`, `shell-help`, `shell-history`,
`shell-listing`, `shell-television`, `shell-zoxide` — and excludes
`deploy-skeleton`, `managed-config` and `theme-switcher`, whose `--config`
flags belong to `chezmoi` and which stage no module.

Assert the count is at least the eight named above and print the selected
list, so a gate that stops matching the predicate is visible rather than
silently dropped.

## Part C — every in-scope gate names every module

Per `(gate, module)` cell, require a staging WRITE whose destination is
that module inside a scratch `.config/nushell`. Two idioms exist in the
suite and both must pass:

```sh
names_it() { # $1 gate file, $2 module basename e.g. copymode.nu
  # explicit: cp/cat/printf/redirect to ".../.config/nushell/<mod>"
  /usr/bin/grep -qE "(cp|cat|printf|>) .*\"[^\"]*/\.config/nushell/$2\"" "$1" \
    && return 0
  # list-driven: a templated destination plus a `for … in` or MODULES= line
  # naming the module
  /usr/bin/grep -qE "/\.config/nushell/\\\$[a-zA-Z_]+(\.nu)?\"" "$1" \
    && /usr/bin/grep -E '(for +[a-zA-Z_]+ +in|MODULES=)' "$1" \
       | /usr/bin/grep -qE "(^|[^a-zA-Z0-9_])${2%.nu}(\.nu)?([^a-zA-Z0-9_.]|$)" \
    && return 0
  return 1
}
```

This predicate was validated against the running suite: over the 8 × 10
grid it reports exactly seven misses — `copymode.nu` in six gates and
`help.nu` in `shell-television` — and those seven are precisely the seven
runtime reds measured on 2026-08-23. The static verdict and the behavioural
verdict agree cell for cell.

One `chk` per miss, naming gate and module, so the FAIL line says what to
add and where. Print the full grid on the way through.

## Isolation

`gates/lib.sh`'s rules, followed, not re-derived: source `lib.sh`; wrap the
run in `guard_begin`/`guard_end`; every `nu` invocation under `/usr/bin/env
-i` with `HOME` pinned into `$(gates_tmpdir)`; `/usr/bin/grep` throughout,
because plain `grep` resolves to `ugrep` on this machine; `snapshot_paths`
over `$HOME/.cache/nushell` and the managed nushell tree, asserted
unchanged at the end. Nothing is installed and nothing outside the scratch
root is written.

## The `--selftest` contract

`gates/selftest.sh` holds every `gates/*.sh` to four clauses, and a new
gate signs them. Under `--selftest`:

- Induce the violation in a `scratch_tree` copy — never the real tree. Add
  `source ~/.config/nushell/newmod.nu` to the copy's `config.nu` and a
  `home/dot_config/nushell/newmod.nu` beside it, stage nothing anywhere,
  re-run against the copy, and require non-zero. Print the `MUTATION:` and
  `MUTATION HOST:` lines.
- Run the GREEN counterfactual on a second `scratch_tree` copy: repair the
  one MISS this suite still carries — add `help` to
  `tests/shell-television.sh`'s `for m in …` loop — and require exit 0.
  That MISS is real and belongs to a separate finding, so it must be
  repaired in the copy, never in the repo.
- `--selftest` exits 0 only when both halves held.

Do not register the gate in `gates/waves.tsv` — that file is the
orchestrator's. Report the exact segment to append to wave 0's gates cell:
`| bash gates/nushell-module-staging.sh`. Say in the report that wave 0
goes red on registration until `shell-television` also stages `help.nu`,
and that the red would be correct.

## Acceptance

- [x] `bash gates/nushell-module-staging.sh` prints the derived module list
      (10 entries), the derived gate list (8 files), and the full grid.
- [x] The parse proof runs: one green machine, then one red run per module
      whose `sourced_file_not_found` names that module's own `config.nu`
      line. 10 reds, 10 module names, no exit-0 deletion.
- [x] The gate reports exactly one MISS after spec01 has landed —
      `tests/shell-television.sh` / `help.nu` — and `EXIT=1`.
- [x] `bash gates/nushell-module-staging.sh --selftest` exits 0, prints a
      `MUTATION:` line and a `MUTATION HOST:` line, and the mutation host
      is under `$TMPDIR`, not the repo.
- [x] The gate's own run leaves `$HOME/.cache/nushell` absent and the
      managed nushell tree byte-identical, both asserted by the gate.
- [x] `git status --porcelain home/ tests/` gains no entry from a gate run.
- [x] `bash gates/selftest.sh` reports the new gate under contract and does
      not report it as unverified-by-contract.

## Verify and Proof

```sh
bash gates/nushell-module-staging.sh; echo "EXIT=$?"
bash gates/nushell-module-staging.sh --selftest; echo "SELFTEST EXIT=$?"

# the mutation host is not the repo
bash gates/nushell-module-staging.sh --selftest | grep -E 'MUTATION'

# the gate is inert on the tree it reads
shasum -a 256 home/dot_config/nushell/*.nu > /tmp/nu-before.sha
bash gates/nushell-module-staging.sh > /dev/null 2>&1
shasum -a 256 -c /tmp/nu-before.sha
test ! -e "$HOME/.cache/nushell" && echo "no ~/.cache/nushell"

# the meta-gate accepts it
bash gates/selftest.sh 2>&1 | grep -i 'nushell-module-staging'
```
