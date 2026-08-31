# spec01 — the generator: `home/run_after_generate-shell-init.sh`

Covers R1, R2, R3, R4 of [`../prd.md`](../prd.md), and the epic's I1/I2/I4.
R5 is proved by the gate (spec03), not by the generator.

## Goal

One chezmoi `run_after` script that regenerates the three nushell integration
files at apply time, into **one** directory, guaranteeing each file exists so
`config.nu`'s `source` lines can never fail, and never failing the apply.

## Exact files touched

- **create** `home/run_after_generate-shell-init.sh` (mode 0755)

Nothing else. Not `install.sh` (its §4 `chezmoi apply` already runs this by
construction), not `home/.chezmoiignore` (its patterns are `README.md` and
`.DS_Store`; a source name of `run_after_generate-shell-init.sh` matches
neither, verified), not any `04-shell` PRD (see Decision D1).

## Decisions this spec makes, with the evidence

**D1 — the one location is `~/.cache/nushell/init/`**, files
`starship.nu`, `zoxide.nu`, `television.nu`. R2 asked for one location and
for the shell epic's invariant to be updated to match; `04-shell/prd.md` I4
already reads *"generated integrations in cache"*, so this pick **matches the
invariant as written and no `04-shell` file needs editing**. The `init/`
subdirectory (rather than `~/.cache/nushell/` directly) keeps the generated
set out of the way of anything nushell itself may cache under its own name.

**D1a — the path is literal `$HOME/.cache/...`, `XDG_CACHE_HOME` is NOT
honoured.** This is not laziness. Nushell's `source` is resolved at *parse*
time and cannot read `$env`, so `config.nu` physically cannot write
`source ($env.XDG_CACHE_HOME | path join ...)`. If the generator honoured the
variable and the shell could not, a machine that sets `XDG_CACHE_HOME` would
generate into one directory and source from another — three `source` lines
failing at every shell start. One hardcoded path on both sides cannot
diverge. (The live config proves the tilde form parses: it already runs
`source ~/.cache/starship/init.nu`.)

**D2 — PATH precedence is `~/.local/bin`, `~/.cargo/bin`, *then* Homebrew —
i.e. the brew resolution happens FIRST and the user bins are prepended over
it**, exactly as the live script does. The reason is not cosmetic: the
generated init must describe the binary **the shell will actually run**, and
`04-shell/01` R1 defines that order as `~/.local/bin` + `~/.cargo/bin`
prepended, Homebrew appended. `install.sh` ends up with the opposite
precedence (it exports the user bins at the top, then `brew_shellenv`
prepends the brew prefix over them) — so the two scripts genuinely disagree,
and the generator must follow the *shell*, not the installer. Measured on
this machine: `~/.local/bin/zoxide` is 0.9.9 and `/opt/homebrew/bin/zoxide` is
0.10.0, and their `init nushell` output differs (1998 vs 1966 bytes). Under
D2 the generator emits the 0.9.9 init, which is correct, because 0.9.9 is
what the shell launches. A stale binary in `~/.local/bin` is a machine-hygiene
problem; a generator that describes a binary the shell never runs is a bug.

**D3 — the `pass`-store advisory of the live script is deliberately dropped.**
R1–R5 do not name it, and the PRD's Out of scope is "anything this node's
Requirements do not name". Recorded here so its absence reads as a decision.
If it is wanted it belongs to `install.sh` (which installs `pass`) or to
`04-shell/02` R6 (which ships the completion), not to a file generator.

**D4 — `run_after_`, not `run_onchange_after_`.** Measured in isolation:
`run_onchange_` runs exactly once and never again, which fails R4 (a tool
upgrade's new init would never be picked up). `run_after_` runs on every
apply. The cost of that choice is real and is recorded in the Hand-offs
section below.

**D5 — `SHELL_INIT_BREW_PREFIXES` is a test-only seam, and it exists because
a PATH shim does not isolate this script.** Measured today: the live script
run under `env -i HOME=<scratch> PATH=/usr/bin:/bin` still produced a
2280-byte real starship init, because it evaluates `/opt/homebrew/bin/brew
shellenv` by **absolute path** and that shellenv then prepends the real
Homebrew prefix to PATH. Same failure class as the `install.sh` incident that
produced P.2's `INSTALL_DRY_RUN`. The variable defaults to the two real
prefixes and is never set in normal use; the gate sets it empty.

## Requirements — boxes a real check can fail

- [x] **S1.1** — The file exists at `home/run_after_generate-shell-init.sh`,
      is executable, starts `#!/usr/bin/env bash`, and sets `set -uo pipefail`
      with **no** `set -e` (a failed tool must not abort the apply — epic I4).
- [x] **S1.2** — It runs clean under **bash 3.2** (`/bin/bash` on this
      machine is 3.2.57 and is what a fresh macOS gives a `#!/usr/bin/env
      bash` shebang before Homebrew is on PATH). Concretely: no `declare -A`,
      no `${a[@]}` over a possibly-empty array, no `<<<`-into-`read -a`. Use
      `IFS=:` word splitting for the prefix list.
- [x] **S1.3** — **PATH re-resolve, in D2's order.** The script resolves
      Homebrew first — iterating `${SHELL_INIT_BREW_PREFIXES-/opt/homebrew:/usr/local}`,
      taking the first entry with an executable `bin/brew`, `eval`ing its
      `shellenv` — and only *then* prepends `$HOME/.local/bin:$HOME/.cargo/bin`
      to PATH. An empty `SHELL_INIT_BREW_PREFIXES` must iterate zero times and
      evaluate no brew at all. `hash -r` after the PATH change (bash caches
      resolved command paths; `install.sh:brew_shellenv` already carries this
      and the live generator omits it).
- [x] **S1.4** — **One directory (D1).** `INIT_DIR="$HOME/.cache/nushell/init"`
      appears as a single assignment; the three outputs are
      `$INIT_DIR/starship.nu`, `$INIT_DIR/zoxide.nu`, `$INIT_DIR/television.nu`
      and no other path is written. The old three-way split
      (`~/.cache/starship/init.nu`, `~/.zoxide.nu`,
      `~/.cache/television/init.nu`) appears nowhere in the file.
- [x] **S1.5** — **The generator commands are exactly** `starship init nu`,
      `zoxide init nushell`, `tv init nu`. Each is guarded by
      `command -v <binary>`.
- [x] **S1.6** — **Never break `source` (R3).** After the script exits, each
      of the three files exists and is a regular file, whatever happened:
      tool absent, tool present, tool exits non-zero, tool prints nothing.
- [x] **S1.7** — **No truncated file, ever.** Output is written to a temp file
      in `$INIT_DIR` and moved into place with `mv -f` (a same-directory
      rename, therefore atomic), and **only** when the tool exited 0; a
      non-zero exit truncates the target to empty instead of leaving partial
      nushell that would be a parse error in every shell. No `*.tmp` file
      survives the run.
- [x] **S1.8** — **Never fails the apply.** The script ends in an explicit
      `exit 0`. Measured: a `run_after` script exiting 3 makes
      `chezmoi apply` print `chezmoi: <script>: exit status 3` and exit 1, so
      this is the difference between a warning and a dead apply (epic I4).
- [x] **S1.9** — **Writes nothing outside `$INIT_DIR`.** The script itself
      creates no other path. (`tv init nu` separately creates
      `~/.config/television/config.toml` when none exists — see S1.10.)
- [x] **S1.10** — **Does not clobber hand-written config.** Measured today:
      `tv init nu` **creates** `~/.config/television/config.toml` (7488 bytes)
      and `~/Library/Application Support/com.television/television.log` when
      the config is absent, and **leaves an existing one byte-identical**
      (verified with a sentinel file). The generator therefore must stay a
      `run_after` script (S1.11) so `04-shell/04-television`'s managed
      `config.toml` is already on disk before `tv` is ever invoked. This box
      is the record of the behaviour; spec03 asserts the sentinel.
- [x] **S1.11** — **Runs last (R1).** The source name carries the `run_after_`
      attribute, which is chezmoi's contract for "after every file target".
      `install.sh` §4 already calls `chezmoi apply` after §1–§3, so the
      installer half of R1/`01-deploy-mechanism` R6 needs no change — assert
      it read-only, do not edit `install.sh`.
- [x] **S1.12** — **Regenerated every apply (R4).** The name is
      `run_after_generate-shell-init.sh`, **not** `run_onchange_after_…` (D4),
      and the generated files live outside both the chezmoi source tree and
      the managed target set, so nothing about them is ever committed.
- [x] **S1.13** — **A header comment carries the *why*, not just the what:**
      D1a (nushell `source` is parse-time), D2 (the generator follows the
      shell's PATH order, with the 0.9.9/0.10.0 zoxide observation), D5 (the
      absolute-path brew leak, dated 2026-08-21), and S1.8 (a non-zero exit
      kills the apply).

## Acceptance

- [x] With **no tools on PATH at all** and no brew seam, the script exits 0
      and leaves three empty regular files in `$HOME/.cache/nushell/init/`.
- [x] `nu -n -c 'source …starship.nu; source …zoxide.nu; source …television.nu;
      print OK'` prints `OK` both when the three files are empty and when they
      hold real init (both directions verified as feasible today against nu
      0.114.1).
- [x] Two consecutive runs in the same HOME leave byte-identical files
      (verified feasible: the live script is byte-identical on re-run, and
      all three tools' output is deterministic — sha256 stable across
      invocations).

## verify

```
bash -c 'set -e; T=$(mktemp -d); env -i HOME="$T" PATH=/usr/bin:/bin SHELL_INIT_BREW_PREFIXES= /bin/bash home/run_after_generate-shell-init.sh; for f in starship zoxide television; do test -f "$T/.cache/nushell/init/$f.nu"; done; test -z "$(find "$T" -name "*.tmp" -print -quit)"; test -z "$(find "$T" -type f -not -path "$T/.cache/nushell/init/*" -print -quit)"; rm -rf "$T"'
```

**Proved RED against the current tree** (2026-08-21): exits **127**,
`/bin/bash: home/run_after_generate-shell-init.sh: No such file or
directory`. The same command shape run against the live reference script
(`/Users/feb/dev/.files/home/run_after_generate-shell-init.sh`) exits 0 and
produces files, so the check is red for the absent artefact and not for a
malformed assertion.

**Proved GREEN 2026-08-21**, after the generator landed: exits **0**. The
three files are created at `$T/.cache/nushell/init/`, all three **empty** —
which is the isolation working: with `SHELL_INIT_BREW_PREFIXES=` the loop
iterates zero times, no brew is evaluated by absolute path, and the real
2280/1998/1809-byte inits the old script leaked are nowhere. No `*.tmp`
survives and no file is written outside the init directory.

## Out of scope

- Syntax-checking the generated nushell by launching `nu` from the generator.
  It costs a spawn on every apply, and `nu` may legitimately be absent on the
  machine being provisioned. The gate does it instead (spec03).
- The `pass` advisory (D3).
- The `source` lines in `config.nu` — those are `04-shell/01` R9's, and D1 is
  the contract they must match.
