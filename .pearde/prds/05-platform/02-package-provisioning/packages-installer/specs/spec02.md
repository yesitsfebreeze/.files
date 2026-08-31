---
est: 1.75h
verify: "bash tests/provisioning.sh --packages"
---

# spec02 — the required set, and the platform ladder

Goal: fill the skeleton [`spec01`](spec01.md) built with the tools the other
five epics assume (R7) and the three-rung ladder that gets them onto a
machine (R4): distro/brew package → prebuilt GitHub release → nothing else.
macOS is the supported path and the one the gate tests; the Linux rungs exist
for capsule containers.

## Files

| File | State | Note |
|---|---|---|
| `install.sh` | extend | §1 the package sets, §2 the release ladder |
| `tests/provisioning.sh` | extend | the `--packages` stage; created in [`spec01`](spec01.md) |

## Design

### The required set, as data in the script

R7's minimum, plus four tools scheduled nodes need by name. Each entry is
`formula=binary`: the name the package manager knows and the name that must
resolve on `PATH` afterwards. They differ often enough (`gnupg`/`gpg`,
`git-delta`/`delta`) that a guard keyed on the package name is wrong.

```bash
PKGS=(
  # R7's required set
  nushell=nu television=tv zoxide=zoxide starship=starship neovim=nvim
  git=git ripgrep=rg fd=fd bat=bat eza=eza fzf=fzf lazygit=lazygit
  chezmoi=chezmoi docker=docker gh=gh
  # not in R7's list, required by a scheduled node:
  just=just    # this repo's own task runner — the justfile P.1 landed, and
               # the gate recipes G.1 imports into it
  jq=jq        # 06-help/05 acceptance: `help --json | jq '.topics | length'`
  gnupg=gpg    # the backend `pass` stores secrets in
  pass=pass    # 04-shell/02 R6 ships a nushell completion for it
)
CASKS=(
  # 02-terminal's font, per capabilities-terminal.md: "the live answer is
  # CaskaydiaCove Nerd Font at 14.0pt". The two other fonts named in the tree
  # are the ones that audit found wrong.
  font-caskaydia-cove-nerd-font
)
```

Three notes the implementer must not silently drop:

- **`tinty` is in R7 and is in no package manager.** `brew search tinty`
  returns nothing; the live machine's copy is at `~/.local/bin/tinty`, a
  release binary. The live `install.sh` **does not install it at all** — a
  real gap, and load-bearing since D.1b (2026-08-21) kept tinty as the
  palette owner four scheduled nodes inherit from. It goes on the release
  rung, on **both** platforms. Verified 2026-08-21 against the GitHub API:
  `tinted-theming/tinty` v0.34.1 publishes
  `tinty-<arch>-apple-darwin.tar.gz` and
  `tinty-<arch>-unknown-linux-gnu.tar.gz`.
- **`chezmoi` is in R7 and the live `install.sh` never installs it** — §7
  only warns when it is missing, so a genuinely fresh machine finishes the
  run with its configs unapplied. It goes in the brew set, and on the Linux
  release rung.
- **`docker` here is the CLI formula, not a container runtime.** It satisfies
  R7 literally ("each resolves on `PATH`"). Choosing the daemon — Docker
  Desktop, OrbStack, colima — is a licence-and-taste call that belongs to
  [`01-capsule`](../../../../01-capsule/prd.md), not to a package list; this
  machine has both `docker-desktop` and `orbstack` casks installed. Say so in
  a comment beside the entry so nobody "fixes" it by adding a GUI cask to an
  unattended installer.

### §1 — the batch, then the stragglers (R5 + R4)

```bash
names=(); for p in "${PKGS[@]}"; do names+=("$(pkg_name "$p")"); done
run brew install "${names[@]}" || warn "brew batch incomplete — retrying the stragglers individually"
for p in "${PKGS[@]}"; do
  have "$(pkg_bin "$p")" && continue
  run brew install "$(pkg_name "$p")" || warn "$(pkg_name "$p"): brew install failed"
done
```

The batch is one dependency resolution instead of nineteen, so it stays. But
it is **not** enough on its own for R5, and the parent's acceptance box
"simulating one failed package still completes the run" is not satisfied by a
single batch call: `brew install` aborts on an unknown formula and the names
after it are never attempted. The retry loop is what makes the failure
per-package. It is `have`-guarded, so on a provisioned machine it is silent
(R8, gated in [`spec01`](spec01.md)).

Casks are guarded on `brew list --cask <c>` — a **read**, so it is not
wrapped in `run` and carries a `# NOT-MUTATING` marker for spec01's lint.

The Linux branch keeps the live script's shape: `apt-get` / `pacman` / `dnf`,
a `warn` when none is present, the `batcat`→`bat` and `fdfind`→`fd` symlinks
Debian needs, and the build-tools block `lazy.nvim`'s `build` steps require.
Each distro list is the subset that distro actually carries; whatever it does
not carry falls to §2.

### §2 — the release rung

`latest_tag` and `fetch_release`, as in the live script, with two fixes:

```bash
latest_tag() {
  local t
  t="$(run_read curl -fsSL "https://api.github.com/repos/$1/releases/latest" \
       | grep -m1 '"tag_name"' \
       | sed -E 's/.*"tag_name"[[:space:]]*:[[:space:]]*"([^"]+)".*/\1/')"
  [ -n "$t" ] || warn "$1: could not resolve a latest release tag (GitHub rate limit?)"
  printf '%s' "$t"
}
```

- **An empty tag must warn.** Unauthenticated `api.github.com` is rate
  limited to 60 requests an hour and answers with a JSON error body, on which
  `grep '"tag_name"'` finds nothing. The live script's `[ -n "$tag" ] &&`
  guard then skips the tool **silently** — a machine that quietly lacks `tv`
  and `nu`, with a zero exit code. R5 says a failure warns.
- **`fetch_release` stays `have`-guarded and non-fatal**, and keeps writing to
  `$HOME/.local/bin`, which [`spec01`](spec01.md) put on `PATH` at the top of
  the run.

Rungs, by platform:

| Tool | macOS | Linux |
|---|---|---|
| everything in `PKGS` | brew | distro, where carried |
| `tv`, `nu`, `gh`, `lazygit`, `starship`, `delta`, `chezmoi` | brew | release (Debian/Ubuntu carry none of them) |
| `tinty` | **release** | **release** |
| `nvim` when below the floor | brew | release — [`spec03`](spec03.md) |

## The gate, stage `--packages`

Same harness as [`spec01`](spec01.md): `INSTALL_DRY_RUN=1`, scratch `HOME`,
scratch `PATH`, the `REAL-INVOCATION` poison assertion and the live-config
guard in and out. Assertions are **content-based and whitespace-normalised**:
the batch line is split on whitespace into a set of package names and
compared as a set, never as a string.

1. **R7 coverage.** Parse the fresh run's `DRY brew install <names…>` line
   into a set; assert it is a superset of R7's sixteen. The sixteen are
   written out literally in the gate, so R7 changing without the installer
   changing turns it red.
2. **Binary names, not package names.** For each `formula=binary` pair whose
   two halves differ, assert `install.sh` guards on the binary: the gate
   greps the pair list and checks `gnupg=gpg` and `git-delta=delta` shapes
   are present rather than `gnupg=gnupg`.
3. **`tinty` and `chezmoi` are actually installed somewhere.** Assert the
   macOS fresh transcript contains a `tinty` line, and that `chezmoi` appears
   in the batch set. Both are the live script's gaps, so both are the checks
   most likely to catch a copy-paste port.
4. **The cask.** `DRY brew install --cask font-caskaydia-cove-nerd-font` in
   the fresh run, absent in the provisioned run.
5. **Per-package retry.** With `INSTALL_DRY_FAIL=install` on the *fresh* run
   (nothing `have`-satisfied), assert at least fifteen single-package `DRY
   brew install <one-name>` lines follow the failed batch, each with its own
   `!!` line, and the run still exits 0.
6. **The Linux ladder.** With the `uname` stub reporting `Linux`/`x86_64`:
   the transcript takes the `apt-get` branch (the stub bin holds `apt-get`
   and not `pacman`/`dnf`), contains the `batcat`/`fdfind` symlink lines, and
   contains release lines for `tv`, `nu`, `gh`, `lazygit`, `starship` and
   `tinty`. With **no** package manager in the stub bin, the run warns and
   still exits 0.
7. **Empty-tag warning.** With `INSTALL_DRY_FAIL=api.github.com` forcing the
   tag lookup empty, assert a `!!` line naming the repo appears — the silent
   skip is what this check exists to forbid.

## Acceptance

Ran green 2026-08-21: `bash tests/provisioning.sh --packages` — exit 0, 45
PASS / 0 FAIL, `REAL-INVOCATION` absent from all six runs of the stage. The
"per-package brew install for **every** entry" box is asserted as an equality
against the batch line's own length (20 of 20), not as a floor.

- [x] The fresh macOS dry run's batch line, parsed as a set of names, is a
      superset of R7's required set: nushell, television, zoxide, starship,
      neovim, git, ripgrep, fd, bat, eza, fzf, lazygit, chezmoi, docker, gh —
      plus `tinty` satisfied on the release rung in the same transcript.
      (R7)
- [x] `install.sh` guards on binary names, not package names: the
      `formula=binary` list contains `gnupg=gpg` and does not contain
      `gnupg=gnupg`. (R8's guard is only cheap if it is correct)
- [x] `DRY brew install --cask font-caskaydia-cove-nerd-font` appears in the
      fresh run and not in the provisioned run.
- [x] With `INSTALL_DRY_FAIL=install` on a fresh run, the failed batch is
      followed by a per-package `brew install` for **every** entry, each with
      its own `!!` line, and the run exits 0. (R5, and the parent's
      "simulating one failed package" box, which a bare batch does not meet)
- [x] With `uname` reporting Linux/x86_64 and only `apt-get` in the stub bin,
      the run takes the apt branch, emits the `batcat`→`bat` and
      `fdfind`→`fd` symlink lines, and emits release lines for `tv`, `nu`,
      `gh`, `lazygit`, `starship` and `tinty`. (R4)
- [x] With Linux and **no** package manager present, the run warns and exits
      0. (R4, R5)
- [x] An unresolvable release tag produces a `!!` line naming the repo, not a
      silent skip. (R5)
- [x] No `REAL-INVOCATION` in any run; the live chezmoi config sha256 and
      `chezmoi source-path` are unchanged in and out of the stage.
- [x] `bash tests/provisioning.sh --packages` exits 0, and exits non-zero
      with one required name deleted from `PKGS` on a scratch copy.

## Proven RED

- `tests/provisioning.sh` does not exist; the literal `verify:` exits **127**
  (2026-08-21).
- Against the *live* `/Users/feb/dev/.files/install.sh`, the R7-coverage
  check fails by construction: its macOS batch is `neovim nushell ripgrep fd
  fzf entr television bat zoxide starship jq imagemagick python git git-delta
  lazygit gh worktrunk just gnupg pass`, which is **missing `eza`, `chezmoi`,
  `docker` and `tinty`** from R7's sixteen. Set difference computed against
  the file, not from memory.
- Also verified against the live file: `brew search tinty` returns no
  formula, and `tinty` appears nowhere in `install.sh` — the gap check 3
  exists for.

Proven GREEN in scratch: the prototype described in [`spec01`](spec01.md)
carried this `PKGS` list and its batch line parsed to exactly the nineteen
names above, superset assertion satisfied, with `REAL-INVOCATION` absent from
all five runs.

## Out of scope

- **P.3 (`homebrew-bootstrap`).** R3's mechanism is `install.sh` §1, written
  and gated here and in [`spec01`](spec01.md). P.3's `plan.json` footprint,
  `run_once_before_*`, names a chezmoi script stage commit `8fe3a71` deleted,
  so P.3 has no file of its own left. Recommended: close P.3 as **absorbed**,
  its R3 box marked `[x]` citing `bash tests/provisioning.sh --shape`. What
  it must **not** do is edit `install.sh` — that is a two-writer conflict on
  the one file this node owns.
- The Neovim floor — [`spec03`](spec03.md).
- A container runtime of any kind. See the `docker` note above; the choice
  belongs to `01-capsule`.
- WezTerm itself. It is in no requirement's package set and the live
  `install.sh` does not install it, yet `02-terminal` assumes it is present.
  Flagged for the corrections backlog rather than fixed by widening R7 here.
- Removing a tool from `PKGS` uninstalling it. The parent records that
  non-behaviour deliberately: this installer converges *up*, never down.
