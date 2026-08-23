---
est: 1.5h
footprint:
  - tests/shell-help.sh
---

# spec02 — gate the resolution with the export absent, and gate the loud failure

H.2's 60 checks were all green while the defect was live, for one reason:
`nu_c()` pins `XDG_CONFIG_HOME` on every run, so no check could fail for a
launch-time constant. Add a runner that does **not** set it, a stage that
uses that runner, counterfactuals against the pre-fix resolution, and probes
for the two silent failures spec01 makes loud.

Depends on spec01: these checks fail against today's `help.nu` by design.

## Where to edit

**The SAFETY block (lines 26–34).** It currently explains that
`XDG_CONFIG_HOME` is pinned *because* the corpus is addressed through a
launch-time constant. That reason is gone. Replace it with the new one: the
export is pinned in `nu_c` to keep the export-present and export-absent runs
comparable, and the corpus is addressed by the `~`-literal `config.nu` uses
to source `help.nu`. Add the new isolation rule below.

**`corpus_path_ok()` (lines 147–155).** Invert it. Require
`path join ".config" "nushell" "help"` and `$nu.home-dir`; require **0** hits
for `$nu.default-config-dir` and **0** for `$nu.config-path`; keep the
existing 0-hit rules for `dot_config` and `/Users/`. Update the check's label
and its counterfactual at lines 209–215: the counterfactual now restores
`$nu.default-config-dir` and must FAIL.

**The four hermetic probe expressions that read
`$nu.default-config-dir`** — lines 311, 312, 325 and 354. They compute the
corpus counts and the nested `nu -c` config paths. Switch every one to
`$nu.home-dir | path join ".config" "nushell"`. They must not depend on the
export, because the new stage runs without it.

**`nu_c()` (lines 276–292).** Leave it as it is. Add `nu_c_noxdg()` beside
it: identical, minus `XDG_CONFIG_HOME`. Both keep `HOME` inside the machine —
that is load-bearing now, see the isolation rule below.

## New: the mirror check (tree stage)

`config.nu` sources the module as the literal `~/.config/nushell/help.nu`,
and `help.nu` addresses the corpus as `$nu.home-dir/.config/nushell/help`.
Those two spellings must agree or the renderer and its corpus come from
different trees. Gate them together, the way the gate already keeps
`env.nu`'s and `dirstack.nu`'s `startdir.txt` paths in step:

- `config.nu` carries `source ~/.config/nushell/help.nu` exactly once
  (already checked by `capture_ok`; cite it rather than re-check).
- `help.nu`'s corpus expression names the same two segments, `".config"` and
  `"nushell"`, in that order.
- Counterfactual: a copy of `help.nu` with `".config"` changed to `".conf"`
  FAILS the mirror check.

## New: the export-absent stage

A new stage, `--noxdg`, run by the no-argument default after `--hermetic`, on
its own `mk_machine`. Every probe uses `nu_c_noxdg`.

1. **The constant's real value, recorded by the gate.**
   `$nu.default-config-dir` under `nu_c_noxdg` is **not** the machine's
   `.config/nushell`. Assert the inequality and echo the value. This is the
   defect's own signature; a future nushell that changes it should surface
   here, not in a bug report.
2. **`help` renders.** rc 0, empty stderr.
3. **The render is byte-identical to the export-present run.** `cmp` the
   `nu_c_noxdg` overview against a `nu_c` overview from the same machine.
   This is the check the defect could not survive.
4. **`help --all | length`** equals the staged corpus's entry count,
   computed from the staged files.
5. **`help "F5 <digit>"`** still renders
   `mode: terminal (host-only — the terminal is outside a capsule)`. R9's
   marking half, now proven under a root that supplies no export — see the
   PRD's R4 finding for why this, and not a container, is what R9's second
   half can actually be.
6. **Counterfactual: the pre-fix resolution FAILS.** A second machine whose
   `help.nu` has `$nu.home-dir | path join ".config" "nushell" "help"`
   `sed`-replaced by `$nu.default-config-dir | path join "help"` must exit
   non-zero on `help` under `nu_c_noxdg`. Without this the stage proves
   nothing: a passing check that would also pass before the fix is not a
   gate.
7. **The resolution cannot be split from the module.** Stage a second tree
   outside `$HOME/.config`, marked by an extra topic id in its own
   `topics.nuon`, and launch `nu --config <second tree>/config.nu` with
   `XDG_CONFIG_HOME` pointed at the machine's `.config`. The render must
   carry the machine's corpus and **not** the marker, because `config.nu`'s
   `~`-literal loaded the machine's `help.nu`. Counterfactual: the same
   probe against a `help.nu` using `$nu.config-path | path dirname` renders
   the marker — the renderer and the corpus from different trees, which is
   the "found somewhere wrong" failure the single resolution exists to stop.

## New: the loud-failure probes

On a throwaway machine, under `nu_c_noxdg`, four states and one survivor.
Every raising case must also print **nothing** on stdout — a partial render
followed by an error is still a manual that said something false.

1. **Corpus directory renamed away.** `help` exits non-zero; stderr carries
   `help:`, the resolved path, `chezmoi apply` and `--delegate`.
2. **The escape hatch is real.** In that same state, `help --delegate ls`
   exits 0.
3. **`topics.nuon` replaced by `[]`.** `help` exits non-zero. Counterfactual
   against a `help.nu` without spec01's length guard: rc 0 and an overview
   carrying `Topics:` with nothing under it. That render is what the box
   exists for.
4. **The four surface files replaced by `[]`.** `help` exits non-zero.
5. **A zero-byte `topics.nuon`.** `help` exits non-zero and the message is
   ours, not nushell's `incompatible_path_access`.

## New: the isolation rule

A `nu` run with no `XDG_CONFIG_HOME` writes to
`$HOME/Library/Application Support/nushell` — measured: `nu -l` with no
export created `env.nu` there. Every runner in this gate keeps `HOME` inside
its machine, so that lands in the scratch tree; the epilogue must prove it.
Add to the epilogue, beside the `~/.cache/nushell` leak check and in the same
shape (skip if it pre-existed):

- `$HOME/Library/Application Support/nushell` does not exist after the run.

State the rule in the SAFETY block too: **a runner that forgets `HOME` writes
into the live home**, which is exactly what the export-absent runs make
possible.

## Not this spec's files

`gates/waves.tsv` already registers this gate in wave 5 as
`external bash tests/shell-help.sh`, and the no-argument default runs every
stage — so the new stage needs no registry row and no
`gates/manual/wave5.md` step. Do not edit either file.

## Acceptance

- [x] `bash tests/shell-help.sh` reports 0 failed, and the run's check count
      is higher than 60: `CHECKS: 88 run, 88 passed, 0 failed` / `EXIT=0`.
      Per stage: `--tree` 32, `--hermetic` 38, `--noxdg` 26, each 0 failed
      standalone; 88 is the no-argument default, whose epilogue runs once.
- [x] `bash tests/shell-help.sh --noxdg` runs standalone and reports 0
      failed: `CHECKS: 26 run, 26 passed, 0 failed` / `EXIT=0`.
- [x] `/usr/bin/grep -c '\$nu\.default-config-dir' tests/shell-help.sh`
      counts only the counterfactual and the recorded-value probe — every
      probe that reads the corpus uses the `~`-literal expression. It
      reports **7**, and not one of them reads the corpus: one header
      comment explaining why the spelling is rejected (l.191), the 0-hit
      rule inside `corpus_path_ok` (l.206), the `prefix_resolution`
      counterfactual generator (l.227), two `chk` labels naming it
      (l.290-291), the recorded-value probe `DCD=$(nu_c_noxdg …)` (l.673),
      and the assertion that the counterfactual machine really carries the
      old resolution (l.720). Every corpus count in the gate goes through
      `CORPUS_DIR_EXPR` / `CORPUS_TOPICS_EXPR` / `CORPUS_ENTRIES_EXPR`,
      which spell the `~`-literal expression once.
- [x] The export-absent overview and the export-present overview are
      compared with `cmp` and are identical: `PASS  noxdg: the export-absent
      overview is byte-identical to the export-present one (1259 bytes)`.
- [x] Every counterfactual in this spec is asserted to FAIL, and each
      carries a staging assertion so a no-op `sed` cannot fake it:
      `PASS  tree: counterfactual pre-fix-$nu.default-config-dir FAILS the
      corpus-path check`, `PASS  tree: counterfactual
      .conf-instead-of-.config FAILS the mirror check`,
      `PASS  noxdg: counterfactual pre-fix-resolution FAILS 'help' under
      this launch (rc=1)`, `PASS  noxdg: counterfactual
      $nu.config-path-dirname renders the ALT tree's marker — renderer and
      corpus from different trees (1 hits)`, and `PASS  noxdg:
      counterfactual help.nu-without-the-spine-length-guard renders the
      EMPTY manual instead — rc 0, empty stderr, 'Topics:' with nothing
      under it (rc=0)`. A third tree counterfactual was added beyond the
      spec: `$nu.config-path | path dirname` also FAILS the tree stage's
      corpus-path check, because the check now bans both spellings.
- [x] Reverting `home/dot_config/nushell/help.nu` to its pre-spec01 state
      makes `bash tests/shell-help.sh` report a non-zero failure count:
      **`CHECKS: 88 run, 72 passed, 16 failed` / `EXIT=1`**. Three failures
      are in `--tree` (the corpus path, the pre-fix-differs staging check,
      the mirror) and thirteen in `--noxdg`; `--hermetic` stays 100% green,
      which is the blind spot `nu_c`'s pinned export created, displayed
      rather than described. The cheaper one-line variant in the Verify
      block below — the resolution swapped back but spec01's raises left in
      place — reports `CHECKS: 88 run, 77 passed, 11 failed`; the extra five
      failures in the full revert are the loud-failure probes, which the
      raises alone satisfy. Restoring the file returns
      `CHECKS: 88 run, 88 passed, 0 failed` both times.
- [x] The epilogue reports `~/.cache/nushell` absent and
      `~/Library/Application Support/nushell` absent, and the managed files
      byte-identical: `PASS  config.nu, env.nu, help.nu and shell.nuon are
      byte-identical`, `PASS  the whole corpus directory is byte-identical,
      file by file`, `PASS  ~/.cache/nushell does not exist …`,
      `PASS  ~/Library/Application Support/nushell does not exist …`. Both
      directories were also checked by hand after the sweep and neither
      exists.

## Verify and Proof

```sh
cd "$(git rev-parse --show-toplevel)"
bash tests/shell-help.sh | tail -4
bash tests/shell-help.sh --noxdg | tail -4

# the gate can fail for this defect. NOTE, corrected while running it: the
# delimiter has to be `#`, not `|` — the pattern itself contains a pipe, so
# the `|`-delimited form is not a valid sed script. The acceptance box was
# proven against a FULL reconstruction of the pre-spec01 file (comment block
# and unguarded defs, not only the one-line swap), which is a strictly
# stronger revert; this one-liner is the cheap reproduction.
cp home/dot_config/nushell/help.nu /tmp/help.nu.fixed
sed -i '' 's#(\$nu\.home-dir | path join ".config" "nushell" "help")#($nu.default-config-dir | path join "help")#' \
  home/dot_config/nushell/help.nu
bash tests/shell-help.sh | tail -2   # expect a non-zero failure count
cp /tmp/help.nu.fixed home/dot_config/nushell/help.nu
bash tests/shell-help.sh | tail -2   # expect 0 failed again

# no leak into the live home
ls "$HOME/Library/Application Support/nushell" ; ls "$HOME/.cache/nushell"
```
