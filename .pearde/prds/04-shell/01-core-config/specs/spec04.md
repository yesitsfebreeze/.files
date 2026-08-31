# spec04 — the gate: `tests/nushell-core.sh`

Proves [`../prd.md`](../prd.md)'s Acceptance, and every box in
[`spec01`](spec01.md), [`spec02`](spec02.md) and [`spec03`](spec03.md).

`verify: "bash tests/nushell-core.sh"`

## Goal

One gate, three stages, that reads the three managed files, runs a **real**
nushell against them in an isolated `HOME`, and drives them through a **real**
`chezmoi apply` into a scratch destination — without ever touching the user's
live shell, live chezmoi config, or live `~/.cache`.

## RED, proved before any of it was written

A prototype carrying six of this gate's checks was run against the tree as it
stands today:

```
FAIL  env.nu present in the managed tree
FAIL  config.nu present in the managed tree
FAIL  dirstack.nu present in the managed tree
FAIL  cd alias is parsed before the generated zoxide init (funnel binds)
FAIL  no 'let ans' binding (builtin variable name in nushell 0.115)
FAIL  nu -c keeps the caller's cwd (R7)
EXIT=1
```

The prototype's behavioural core is already proven able to go green *and* to
catch its own violation: with `alias cd = mkcd` before the sourced zoxide init
the funnel printed `MKCD-SAW /tmp`, and with the alias after it the jump
succeeded and printed nothing — a silent bypass that only a check of this shape
catches (spec03 D1).

## Exact files touched

- **create** `tests/nushell-core.sh` (mode 0755)

Read-only: `gates/lib.sh` (sourced for `chk`, `guard_begin`/`guard_end`,
`lint_no_bare_chezmoi`, `gates_tmpdir`), and
`home/run_after_generate-shell-init.sh` (the `--apply` stage runs it, never
edits it). **Writes nothing** in `gates/`, `tests/deploy-skeleton.sh`,
`tests/managed-config.sh` or `.mi/prds/02-terminal/**` — other agents hold
those.

## Safety — the rules this gate is built around, each from a failure measured
in this repo

- [x] **S4.1** — **`HOME` does not isolate chezmoi and `--destination` does
      not isolate a `run_` script's `$HOME`.** Both bit this repo today. Every
      chezmoi invocation goes through one `cz()` helper that carries
      `/usr/bin/env -i HOME="$S/home"` **and** `--destination "$S/home"` at the
      same path, plus `--source`, `--config`, `--persistent-state`, `--cache`,
      `--no-tty` and `< /dev/null`. `tests/shell-init.sh:289` is the precedent
      and is to be followed, not re-derived.
- [x] **S4.2** — **`lint_no_bare_chezmoi "$SELF"` runs as a check**, so a
      future edit that adds a bare `chezmoi` call turns the gate red
      structurally rather than at the next incident.
- [x] **S4.3** — **`guard_begin`/`guard_end` wrap every stage**, so the live
      `~/.config/chezmoi/chezmoi.toml` hash and `chezmoi source-path` are
      recorded in and out. The gate's own output must show
      `source-path out = /Users/feb/dev/.files/home`.
- [x] **S4.4** — **Never snapshot `~/.config/nushell` wholesale.** The user's
      own live shell rewrites `~/.config/nushell/history.sqlite3-wal` at any
      moment (measured: 4.2 MB, mtime moving during this analysis), so a
      directory hash over it is red for reasons that have nothing to do with
      this gate. The untouched-file proof is a per-file `shasum -a 256` over
      exactly `~/.config/nushell/config.nu`, `env.nu` and `dirstack.nu`, taken
      before and after.
- [x] **S4.5** — **`~/.cache/nushell` must not exist when the gate finishes.**
      It does not exist today (measured). The generated init files belong to a
      scratch `HOME`; a real one appearing means an isolation leak.
- [x] **S4.6** — **`SHELL_INIT_BREW_PREFIXES=` (empty) on every generator
      invocation**, for the reason `tests/shell-init.sh` records: a PATH shim
      does not isolate a script that evaluates `/opt/homebrew/bin/brew
      shellenv` by absolute path.
- [x] **S4.7** — **`/usr/bin/grep`, always.** `grep` in this environment is a
      shell function resolving to **ugrep**; an unqualified `grep` in the gate
      is a different program on a different machine.
- [x] **S4.8** — **Nothing is installed and `/Users/feb/dev/.files` is never
      written.** Every binary the stages need is either already present or
      stubbed inside the scratch tree.

## Stage `--tree` — the managed files as text

- [x] **S4.9** — The three files exist under `home/dot_config/nushell/` and
      are regular files.
- [x] **S4.10** — **The anchor contract (spec03 S3.14).** All ten anchors are
      present in `config.nu`, exactly once each, and their line numbers are
      strictly increasing in the specified order. Counterfactual: a copy with
      `PALETTE` moved below `THEME` must fail this check.
- [x] **S4.11** — **The funnel binds (spec03 D1).** The line number of
      `alias cd = mkcd` is less than the line number of the
      `init/zoxide.nu` source line. Counterfactual: the reversed copy fails.
- [x] **S4.12** — **`let ans` appears nowhere** in any of the three files
      (spec03 D2).
- [x] **S4.13** — **The generated paths agree with the generator.** The three
      `source` paths in `config.nu` are derived from
      `home/run_after_generate-shell-init.sh`'s own `INIT_DIR` and output
      names by reading that file, not by restating the strings. The generator
      moving without this node moving turns the gate red.
- [x] **S4.14** — **None of the three superseded live paths** (`~/.zoxide.nu`,
      `~/.cache/starship/init.nu`, `~/.cache/television/init.nu`) appears in
      `config.nu`.
- [x] **S4.15** — **The mirrored state path agrees** (spec01 S1.11): `env.nu`
      and `dirstack.nu` compute the same `startdir.txt` location — same
      `XDG_STATE_HOME` default, same `nushell` segment, same filename.
- [x] **S4.16** — **`path expand` appears nowhere in `env.nu`** (spec01 D2).
- [x] **S4.17** — **`rcwd` appears in `dirstack.nu` only inside a sentence
      naming live bug L-3** (spec02 D4).
- [x] **S4.18** — **The manual still matches** (spec03 S3.19): `esc_clear`
      is present in both `config.nu` and
      `home/dot_config/nushell/help/shell.nuon`, and this gate **only reads**
      the `.nuon`.

## Stage `--hermetic` — a real nushell, an isolated HOME, no chezmoi

Every run is `/usr/bin/env -i HOME="$M/home" PATH="$M/bin:/usr/bin:/bin" nu
--config <repo>/home/dot_config/nushell/config.nu --env-config
<repo>/home/dot_config/nushell/env.nu -c '<probe>'`, with poison stubs
(`echo REAL-INVOCATION … >&2; exit 66`) for `bash`, `tinty`, `ollama-host`,
`starship`, `zoxide`, `tv` in `$M/bin`, and the three generated init files
present as harmless stubs so the `source` lines parse.

- [x] **S4.19** — **The config parses at all**, with no output on stderr. This
      is the check that catches a nushell upgrade breaking the record (the
      0.115 `ans` incident's class).
- [x] **S4.20** — **`nu -c 'pwd'` from a third directory prints that
      directory** (R7), including when run under `script(1)` so the caller has
      a real terminal. Measured basis: `is-terminal --stdout` is false for
      `-c` even on a pty, while `/bin/sh`'s `[ -t 1 ]` is true there.
- [x] **S4.21** — **No escape byte and no spawn under `nu -c`** (the PRD's
      last acceptance line): `nu -c 'print hi'` produces exactly `hi\n` —
      byte-compared — and none of the poison stubs is tripped.
- [x] **S4.22** — **`$env.config` reads back correctly**: `history.isolation`
      false, `history.max_size` 100000, `history.file_format` `sqlite`,
      `history.sync_on_enter` true, `shell_integration.osc133` false,
      `osc633` false, `osc7` true, `use_kitty_protocol` false,
      `completions.algorithm` `fuzzy`, `completions.external.enable` true,
      `completions.external.max_results` 100, `filesize.unit` `binary`,
      `rm.always_trash` true, `edit_mode` `emacs`, `show_banner` false,
      `cursor_shape.emacs` `block`, `table.mode` `rounded`.
- [x] **S4.23** — **`esc_clear` is bound** with `modifier: none`,
      `keycode: escape`, modes exactly `[emacs vi_insert]`, event
      `{edit: clear}`.
- [x] **S4.24** — **PATH repair (R1)**: from `PATH=/usr/bin:/bin`, the
      resulting `$env.PATH` begins `<HOME>/.cargo/bin`, `<HOME>/.local/bin`,
      contains `/opt/homebrew/bin`, and `($env.PATH | uniq | length) ==
      ($env.PATH | length)`. Re-running with the first run's exported `PATH`
      inherited yields a byte-identical export (S1.4).
- [x] **S4.25** — **R2's variables** all read back with the values spec01
      S1.6 lists.
- [x] **S4.26** — **The `ollama-host` probe**: with a stub that exits 1,
      `OLLAMA_HOST` is unset; with a stub that prints a marker and exits 0, an
      interactive-guarded run sets it to the trimmed marker; under `nu -c` the
      poison stub is never spawned.
- [x] **S4.27** — **The palette ladder (R10)**, four machines: artifact
      present + marker `bash` → artifact reached, `tinty` not spawned;
      artifact absent + marker `tinty` → `tinty init` reached; both absent →
      no spawn, no error; `nu -c` → neither spawned (S4.21 covers the byte
      check).
- [x] **S4.28** — **`mkcd` (R6)**: `mkcd` into an existing dir moves and writes
      `startdir.txt`; `mkcd -` toggles; `mkcd` with no argument reaches
      `$env.HOME`; a non-existent target with a **blank** keypress on stdin
      creates and enters it; with `y` on stdin prints `aborted`, creates
      nothing and does not move.
- [x] **S4.29** — **The dirstack (R8)**: after three moves the hook has pushed
      three entries newest-first; a repeat visit dedups; 150 pushes cap at
      100; `_dirstack_list` drops a deleted path and a blank line and leaves
      the file unmodified.
- [x] **S4.30** — **The start dir (R7)**: with `startdir.txt` holding an
      existing scratch dir, an interactive-guarded start lands there; with it
      holding a deleted path, it falls back to `<HOME>/dev`; with the file
      absent, likewise, and `<HOME>/dev` is created.
- [x] **S4.31** — **Counterfactual: a missing generated init file.** Remove
      one of the three stubs and re-run: nushell must fail with
      `nu::parser::sourced_file_not_found`. This is the check that keeps
      `05-platform/03`'s "the file always exists" guarantee load-bearing
      rather than incidental (spec03 S3.16).

## Stage `--apply` — through a real chezmoi

- [x] **S4.32** — The scratch source root is a **copy of `home/`** (that is
      what `.chezmoiroot: home` makes it); chezmoi is never pointed at the
      repo root or at `/Users/feb/dev/.files`.
- [x] **S4.33** — `cz "$S" apply` lands all three files at
      `$S/home/.config/nushell/`, and the `run_after` generator produces
      `$S/home/.cache/nushell/init/{starship,zoxide,television}.nu`.
- [x] **S4.34** — **The deployed files are what the shell then runs**: repeat
      S4.19–S4.23 against `$S/home/.config/nushell/{config,env}.nu` with
      `HOME="$S/home"`, so the generated init files are found at the literal
      paths `config.nu` sources — the end-to-end proof that R9's contract with
      `05-platform/03` holds.
- [x] **S4.35** — **A failing tool never kills the apply**: with poison stubs
      the apply still exits 0 and the three init files still exist (empty).
- [x] **S4.36** — **The live files are untouched**: the three sha256 values
      from S4.4 are unchanged, `~/.cache/nushell` is absent (S4.5), and
      `guard_end` reports the live `chezmoi.toml` hash and
      `source-path = /Users/feb/dev/.files/home` unchanged.

## Out of scope

- The `--live` idea of running the *user's real* shell. Nothing in this gate
  starts an interactive nushell against the real `HOME`; every interactive
  path is exercised by driving the guarded branches with an isolated `HOME`
  and stubbed binaries.
- Anything owned by `tests/deploy-skeleton.sh` or `tests/managed-config.sh`.
