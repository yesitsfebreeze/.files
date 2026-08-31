# spec03 — apply integration and the version check: `--apply`, `--live`

Covers R1 and R5 of [`../prd.md`](../prd.md), and the epic's I2 second-apply
box. Extends the file `spec02` creates; run spec02 first.

## Goal

Two more stages on `tests/shell-init.sh`:

- `--apply` — drive the generator **through a real `chezmoi apply`**, fully
  isolated, and prove the ordering contract (R1) and that the apply survives
  a failing tool.
- `--live` — the one stage that runs the **real** `tv` and the **real** `nu`,
  read-only, to prove R5: the generated television init still defines the
  command `Alt-R` is bound to.

## Exact files touched

- **edit** `tests/shell-init.sh` (created by spec02)

## Isolation — every chezmoi call, no exceptions

`HOME` does not isolate chezmoi: a scratch-`HOME` `chezmoi init --force`
rewrote the real `~/.config/chezmoi/chezmoi.toml` and repointed this machine.
And `--destination` does **not** isolate a `run_` script's `$HOME` — measured
today, a scratch-destination apply ran a `run_after` script that wrote to the
real `/Users/feb/ranlog`. So:

- every `chezmoi` invocation carries `--source`, `--destination`, `--config`,
  `--persistent-state`, `--cache`, `--no-tty` and `< /dev/null`, and `init`
  additionally carries `--config-path` — the `cz()` shape of
  `tests/deploy-skeleton.sh`;
- every invocation is wrapped in `env -i HOME="$S/home" …`, and
  **`--destination` is that same `$S/home`**, because in real use the
  destination *is* `$HOME` and the generator writes relative to `$HOME`;
- the whole stage runs inside `guard_begin "apply"` / `guard_end`, which
  records and re-checks the live config's sha256 and `chezmoi source-path`;
- `lint_no_bare_chezmoi "$SELF"` runs on this gate file itself.

Baseline this gate must report unchanged: `chezmoi source-path` →
`/Users/feb/dev/.files/home`, `~/.config/chezmoi/chezmoi.toml` sha256 prefix
`02d5d4ee`.

## Requirements — boxes a real check can fail

### stage `--apply`

- [x] **S3.1** — **Scratch source.** Copy `$REPO/home` into `$S/src` (that is
      what `.chezmoiroot: home` makes the source root), seed `$S/chezmoi.toml`
      with a `sourceDir` and the two `[data]` keys `.chezmoi.toml.tmpl`
      prompts for, so `init` never prompts and never reads ambient data.
      Never point chezmoi at `$REPO` itself.
- [x] **S3.2** — **Stubs and poison, as in spec02.** `$S/home/.local/bin`
      holds marker-printing `starship`/`zoxide`/`tv`; the PATH bin holds a
      poison `brew`; `SHELL_INIT_BREW_PREFIXES=` is passed empty through
      `env -i` (chezmoi passes its environment to `run_` scripts — verified).
      The transcript is checked for `REAL-INVOCATION`.
- [x] **S3.3** — **R1, ordering, proved not asserted.** The gate's `tv` stub
      records whether the managed target `$S/home/.gitconfig` (from
      `home/dot_gitconfig.tmpl`, P.5) exists **at the moment it runs**. It
      must record present — that is what "runs after every file target"
      means, and it is the only way to prove the `run_after` attribute is
      doing its job rather than the name merely looking right.
- [x] **S3.4** — **R1, the installer half, read-only.** In `install.sh`, the
      `chezmoi apply` call (§4) appears **after** the package sections; assert
      it by line index over the file's content (`idx`-style), never by editing
      it. `install.sh` is another node's file.
- [x] **S3.5** — **The apply produces the three files** under
      `$S/home/.cache/nushell/init/`, each equal to its stub marker, and
      `chezmoi apply` exits **0**.
- [x] **S3.6** — **Second apply, byte-identical (epic I2).** Re-apply; the
      sha256 of each generated file is unchanged.
- [x] **S3.7** — **A failing tool does not kill the apply (I4).** With the
      `home-broken` `tv` stub in place, `chezmoi apply` still exits **0** and
      `television.nu` is empty. Counterfactual proof that this box has teeth:
      a `run_after` script exiting 3 makes chezmoi print
      `chezmoi: <name>: exit status 3` and exit 1 — measured today.
- [x] **S3.8** — **S1.10, the clobber check.** Plant a sentinel
      `$S/home/.config/television/config.toml` before the apply; its sha256 is
      unchanged after. (Measured: `tv init nu` *creates* that file when absent
      — 7488 bytes — and leaves an existing one byte-identical. This is the
      "a generated file overwrote hand-written config" failure mode, and it is
      one apply-ordering mistake away from being real.)
- [x] **S3.9** — **The generated files are never managed.** After the apply,
      `chezmoi status` names no path containing `.cache`, and `chezmoi
      managed` lists none of the three files — R4's "not committed, always
      derived".
- [x] **S3.10** — **The documented status deviation.** After the apply,
      `chezmoi status` output, with the run-script line removed, is **empty**;
      and the run-script line is present and names
      `generate-shell-init.sh`. Assert both directions, and carry the reason
      in a comment: chezmoi reports an always-run script as pending `R`
      forever, by design, so "a second apply reports no changes" can only ever
      mean "no *file* changes". See Hand-offs.
- [x] **S3.11** — **Counterfactuals** (`cf` shape, against copies under the
      scratch dir): the source script renamed to `run_onchange_after_…` →
      `--apply` goes red (the second apply generates nothing); the final
      `exit 0` replaced by `exit 1` → `--apply` goes red.

### stage `--live`

Read-only. Runs no chezmoi, installs nothing, writes only under
`gates_tmpdir()`.

- [x] **S3.12** — **Preconditions**, each its own `chk` so a missing tool
      reports rather than silently passing: `tv`, `nu` and `starship` resolve
      on PATH. Record `nu --version` (baseline 0.114.1) and `tv --version` in
      the transcript.
- [x] **S3.13** — **R5, the command name is a literal constant in the gate:**
      `TV_HISTORY_CMD="tv_shell_history"`, with a comment citing
      `04-shell/05-history` R2 (`Alt-R` → `tv_shell_history`) and
      `04-shell/01` R9. The gate is the record; a tv upgrade that renames the
      command turns this red, which is exactly what R5 asks for.
- [x] **S3.14** — **R5, proved by definition, not by grep.** Capture the real
      `tv init nu` to a scratch file, then
      `nu -n -c "source <file>; if (scope commands | where name == '$TV_HISTORY_CMD' | is-not-empty) { print DEFINED }"`
      must print `DEFINED`. Verified feasible today against tv + nu 0.114.1.
      A `norm`ed content assertion that the same file contains
      `def tv_shell_history [` is the cheap second check, not the primary one.
- [x] **S3.15** — **Counterfactual:** the same probe with the constant
      changed to a name tv does not define must report red — so a `DEFINED`
      that comes from anywhere but the generated file cannot pass.
- [x] **S3.16** — **All three real inits parse.** `starship init nu`,
      `zoxide init nushell` and `tv init nu` into scratch files, then one
      `nu -n -c 'source a; source b; source c; print OK'` prints `OK`.
      Verified feasible today.
- [x] **S3.17** — **`--live` touches nothing outside its scratch**, including
      `$HOME/.config/television/config.toml`: snapshot it before, assert
      after. (`tv init nu` will create it if absent — on this machine it
      exists.)

### whole file

- [x] **S3.18** — The entry-point snapshot of spec02 S2.15 covers all three
      stages, and `assert_unchanged` plus the repo-root listing census run
      once at the end of `main`, after the counterfactuals.

## Acceptance

- [x] `bash tests/shell-init.sh` exits 0, all `PASS`.
- [x] The `guard[apply]` lines report `sha256 in == sha256 out` with prefix
      `02d5d4ee`, and `source-path in == source-path out ==
      /Users/feb/dev/.files/home`.
- [x] Nothing under `/Users/feb/dev/.files` was written (it is read-only for
      this ticket, and mid-revert).

## verify

```
bash tests/shell-init.sh
```

**Proved RED against the current tree** (2026-08-21): exits **127**,
`bash: tests/shell-init.sh: No such file or directory`.

**Proved GREEN 2026-08-21**: exits **0**, 95 `PASS` lines and 0 `FAIL`.
`guard[apply]` reports `sha256 in == sha256 out ==
02d5d4ee50b5d37955ffe7778938ddee82f4da24cbaf552b4dba3810d3c850a1` and
`source-path in == out == /Users/feb/dev/.files/home`. `--live` recorded
`nu 0.114.1` and `television 0.15.9`. Both `--apply` counterfactuals go red
as specified, and nothing under `/Users/feb/dev/.files` was written.

## Hand-offs — folded into `spec04`, not left for another ticket

Both consequences below were originally raised as hand-offs. The orchestrator
widened this node's footprint on 2026-08-21 so the lane that breaks a gate
fixes it in the same change: they are now
[`spec04.md`](spec04.md), and this section is the pointer.

1. **`tests/deploy-skeleton.sh` (P.1) goes RED the moment
   `home/run_after_generate-shell-init.sh` exists.** Measured twice: the same
   gate exits 0 on the current tree and exits 1 with exactly two FAILs when
   the script is planted, because chezmoi reports an always-run script as
   pending on every `status` and diffs it on every `apply --verbose`, forever,
   by design. spec04 narrows both assertions with `--exclude=always` and
   proves the narrowed form still fails on a genuine second-apply diff.
2. **`gates/waves.tsv` wave 2 has an empty gates cell** and P.4 is in it.
   spec04 adds `external bash tests/shell-init.sh`, in the same change that
   creates the file — a registry row naming a script nobody has written turns
   the sweep red for a missing file.

## Out of scope

- Registering the gate in `gates/justfile` — `just gate 2` reaches it
  through the `gates/waves.tsv` row that [`spec04`](spec04.md) adds, and no
  recipe file needs editing.
- The `Alt-R` keybinding itself — `04-shell/05-history` R2/R5 own it; this
  node only proves the command it binds to still exists.
