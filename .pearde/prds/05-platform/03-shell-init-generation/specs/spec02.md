# spec02 — the hermetic gate: `tests/shell-init.sh --gen`

Covers R2, R3, R4 of [`../prd.md`](../prd.md) by running the generator
directly, with no chezmoi involved. spec03 adds the apply-integration and the
live version stages to the same file.

## Goal

A gate in this repo's house dialect that runs
`home/run_after_generate-shell-init.sh` against scratch machines, proves the
three files are always there and never truncated, and — the point of the
whole exercise — **proves the run never reached a real tool**, because a
PATH shim alone demonstrably does not isolate this script.

## Exact files touched

- **create** `tests/shell-init.sh`

Sourced read-only: `gates/lib.sh`. Nothing under `gates/` is edited (see
Hand-offs in `spec03`).

## The isolation contract, and why each half is load-bearing

Both halves were reproduced today.

1. **A PATH shim does not isolate this script.** Run under
   `env -i HOME=<scratch> PATH=/usr/bin:/bin`, the live generator still
   produced a 2280-byte *real* starship init, a 1998-byte *real* zoxide init
   and a 1809-byte *real* tv init — because it evaluates
   `/opt/homebrew/bin/brew shellenv` by absolute path, and that shellenv
   prepends the real Homebrew prefix over the scratch PATH. So this gate runs
   every invocation with `SHELL_INIT_BREW_PREFIXES=` (spec01 D5) **and**
   plants a poison `brew` stub **and** asserts on file *content*, so a leak
   fails on the leak itself and not on a style rule.
2. **`$HOME` is where the damage lands.** `--destination` does **not** set a
   `run_` script's `$HOME`: measured today, a scratch-destination apply ran a
   `run_after` script that wrote to the **real** `/Users/feb/ranlog` (removed).
   Every invocation here sets `HOME` explicitly, and the real user paths are
   sha256-snapshotted across the whole run.

## Requirements — boxes a real check can fail

- [x] **S2.1** — `tests/shell-init.sh` sources `gates/lib.sh` and uses its
      `chk` / `chk_ok` / `chk_fail` / `norm` / `snapshot_paths` /
      `assert_unchanged` / `gates_tmpdir`, in the dialect
      `tests/provisioning.sh` uses. It never writes `gates/lib.sh`.
- [x] **S2.2** — Stages: `--gen` (this spec), `--apply` and `--live`
      (spec03); no argument runs all three; anything else exits 2 with a
      usage line. Every stage takes the **path to the generator** as its
      argument, so a counterfactual can pass a mutated copy — the shape
      `tests/provisioning.sh` uses for `install.sh`.
- [x] **S2.3** — **Scratch machines.** Built under `gates_tmpdir()`:
      - `home-bare` — a HOME with an empty `.local/bin`; PATH holds only
        `/usr/bin:/bin` plus a poison `brew`. No tool resolves.
      - `home-stubbed` — a HOME whose `.local/bin` holds three stubs,
        `starship`, `zoxide`, `tv`, each printing a unique **marker line**
        (`# STUB-STARSHIP-INIT` etc.) and exiting 0.
      - `home-broken` — like `home-stubbed`, but the `tv` stub prints half a
        line and exits 1.
      - `home-silent` — like `home-stubbed`, but the `zoxide` stub prints
        nothing and exits 0.
      A poison stub prints `REAL-INVOCATION <name> $*` to stderr and exits 66
      (`tests/provisioning.sh`'s `mk_poison`). Poison `brew` in every bin.
- [x] **S2.4** — **Every run is `env -i`,** carrying only `HOME`, `PATH`,
      `SHELL_INIT_BREW_PREFIXES=` (empty), and runs the generator with
      `/bin/bash` explicitly, which proves spec01 S1.2 (bash 3.2) at the same
      time.
- [x] **S2.5** — **No leak, asserted twice.** Every transcript is checked for
      `REAL-INVOCATION`; and on `home-stubbed` each generated file must equal
      **exactly** its stub's marker output. A real tool leaking in changes the
      content and turns the check red even if no poison stub was reached.
- [x] **S2.6** — **R2, the one location.** On `home-stubbed`, the three files
      exist at `$HOME/.cache/nushell/init/{starship,zoxide,television}.nu`,
      and **none** of `$HOME/.zoxide.nu`, `$HOME/.cache/starship/init.nu`,
      `$HOME/.cache/television/init.nu` exists — the old split must be gone,
      not merely duplicated.
- [x] **S2.7** — **R3, on `home-bare`.** All three files exist, all three are
      **empty**, and the run exits 0.
- [x] **S2.8** — **R3, on `home-broken`.** `television.nu` exists and is
      **empty** — the half-line the failing stub printed must not survive —
      while `starship.nu` and `zoxide.nu` hold their markers, and the run
      exits 0.
- [x] **S2.9** — **R3, on `home-silent`.** `zoxide.nu` exists and is empty;
      the run exits 0.
- [x] **S2.10** — **No `*.tmp` residue** under any scratch HOME after any run.
- [x] **S2.11** — **Writes nothing else.** After a run on `home-stubbed`, the
      set of regular files under that HOME, minus the three planted stubs, is
      exactly the three generated files.
- [x] **S2.12** — **R4, byte-identical re-run (epic I2).** Run twice on
      `home-stubbed` and on `home-bare`; the sha256 of each of the three
      files is unchanged. (Verified feasible today: the live generator is
      byte-identical on re-run, and `starship init nu`, `zoxide init nushell`
      and `tv init nu` each hash identically across invocations.)
- [x] **S2.13** — **The generated files parse as nushell.** When `nu` is on
      PATH, `nu -n -c 'source …; source …; source …; print OK'` prints `OK`
      for the `home-bare` (three empty files) case and for the
      `home-stubbed` case. Guarded by a `precondition:` chk so a machine
      without `nu` reports the skip rather than passing silently.
- [x] **S2.14** — **Counterfactuals, in `tests/provisioning.sh`'s `cf`
      shape**, each against a *copy* of the generator under the scratch dir,
      never the real file:
      - the truncate-on-failure branch deleted → `--gen` goes red;
      - the `mkdir -p "$INIT_DIR"` line deleted → `--gen` goes red;
      - `INIT_DIR` pointed back at `$HOME/.cache/starship` → `--gen` goes red;
      - the final `exit 0` changed to `exit 1` → `--gen` goes red.
- [x] **S2.15** — **Untouched-file guard, sha256, not git.** At entry,
      `snapshot_paths --deep "$REPO/.mi" "$REPO/gates" "$REPO/tests"
      "$REPO/home" "$REPO/install.sh"` and `snapshot_paths` (listing mode) over
      the **real user paths** `$HOME/.cache/nushell`, `$HOME/.cache/starship`,
      `$HOME/.cache/television`, `$HOME/.zoxide.nu`, `$HOME/.config/nushell`,
      `$HOME/.config/television`, `$HOME/.config/chezmoi`; `assert_unchanged`
      at exit. Plus the repo-root listing census
      (`ls -A "$REPO" | LC_ALL=C sort`) before and after.
      `git diff --quiet` / `git status --porcelain` are **not** usable here —
      the tree is staged-but-uncommitted and porcelain prints ~160 lines no
      gate caused.
- [x] **S2.16** — **Content assertions go through `norm`.** Any assertion on
      prose or on a wrapped line normalises whitespace first; no naive
      multi-word `grep` across a line break.

## Acceptance

- [x] `bash tests/shell-init.sh --gen` exits 0 and every line is `PASS`.
- [x] Every counterfactual of S2.14 prints its `PASS  counterfactual: …` line
      — i.e. the mutated copy really did turn the stage red.
- [x] The final `assert_unchanged` passes, and `/Users/feb/ranlog`-class
      litter appears nowhere: no file under the real `$HOME` changed.

## verify

```
bash tests/shell-init.sh --gen
```

**Proved RED against the current tree** (2026-08-21): exits **127**,
`bash: tests/shell-init.sh: No such file or directory`.

**Proved GREEN 2026-08-21**: exits **0**, every line `PASS`, including all
four counterfactuals of S2.14 and both `assert_unchanged` guards (the repo
trees deep, and the real `~/.cache/{nushell,starship,television}`,
`~/.zoxide.nu`, `~/.config/{nushell,television,chezmoi}`).

## Out of scope

- chezmoi. This stage never invokes it; `--apply` (spec03) does, under
  `guard_begin`/`guard_end`.
- The television/`Alt-R` version check — that needs the *real* `tv` and is
  `--live` (spec03).
