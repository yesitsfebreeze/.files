---
est: 2h
verify: "bash tests/provisioning.sh --shape"
---

# spec01 — `install.sh`: the script, its ordering, and the dry-run seam

Goal: create `install.sh` at the repo root — the one command that turns a
clone into a working machine — with the four properties the node's
requirements are about: Homebrew first and PATH re-resolved in the same run
(R3 / [`01-deploy-mechanism`](../../../01-deploy-mechanism/prd.md) R6), never
abort (R5), re-runnable by guard (R8), and `chezmoi apply` last (the epic's
I1). This spec builds the skeleton and those four properties; the package
list itself is [`spec02`](spec02.md) and the Neovim floor is
[`spec03`](spec03.md).

It also ships the node's gate, `tests/provisioning.sh`, and its **dry-run
seam** — the mechanism that lets a gate prove installer behaviour on a
machine it must not modify. That seam is not a convenience. See
`## The incident`.

## Files

| File | State | Note |
|---|---|---|
| `install.sh` | new | declared in the P.2 footprint |
| `tests/provisioning.sh` | new | **footprint addition** — see below |

`tests/provisioning.sh` is outside the footprint `plan.json` records for P.2
(`["install.sh"]`). It is claimed by no other task — checked against every
`files` list in `.mi/gantt/plan.json`; the only other `tests` entry is E.14's
`home/dot_config/nvim/tests/`. It follows the convention the repo already
has: `tests/deploy-skeleton.sh` is P.1's own gate for P.1's node and
`tests/help-content-model.nu` is H.1's. A node-specific check script is not
G.1's deliverable — G.1 owns the *runner* and the cross-cutting gates, and
picks this one up through the `import? 'gates/justfile'` seam P.1 landed.

Read-only, never written: everything under `home/` (P.1's skeleton, and the
per-app trees other tracks own). `install.sh` sits at the repo root, outside
`.chezmoiroot`, so it is not a managed file and never deploys.

## The incident — why the gate may not use a PATH shim

**This was done, not imagined, during this node's analysis on 2026-08-21.**

A first prototype of this gate isolated `install.sh` the way
`tests/deploy-skeleton.sh` isolates chezmoi: scratch `HOME`, and a scratch
`bin` first on `PATH` holding a `brew` shim. It ran the real Homebrew anyway
and **mutated this machine**: it upgraded `nushell` 0.114.1 → 0.115.0,
`lazygit` 0.64.0 → 0.64.1 and `gh` 2.97.0 → 2.98.0, and installed the
`docker` formula. The nushell bump broke the live shell — 0.115.0 makes `ans`
a builtin variable name and `~/.config/nushell/config.nu:279` binds `let ans`,
so every login shell aborted with `nu::parser::name_is_builtin_var`.
Everything was restored from the Homebrew download cache.

The cause is one line, and it is in the live `install.sh` too:

```bash
eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"
```

**Absolute paths defeat a `PATH` shim**, and this one does worse than run the
real `brew` once — the `shellenv` it evaluates *prepends the real Homebrew
prefix to `PATH`*, so the shim is displaced and every later `brew install` in
the run is real. The isolation does not merely leak; it is switched off by
the thing it was meant to isolate, silently, and the run still exits 0.

Two rules follow, and they are the reason this spec exists in this shape:

1. **The gate never relies on `PATH` alone.** Behaviour is proved with
   `INSTALL_DRY_RUN=1`, in which no mutating command is executed at all.
2. **`install.sh` routes every mutating command through one wrapper.** A
   command that is not wrapped is not dry-runnable, and the gate lints for
   that structurally, because a comment is not protection.

## Design

### The wrapper, and the seam

```bash
DRY="${INSTALL_DRY_RUN:-}"

# Every mutating command goes through run(). Under INSTALL_DRY_RUN it prints
# what it would do and returns without executing. This is what lets the gate
# prove behaviour on a machine it must not modify; see tests/provisioning.sh.
run() {
  if [ -n "$DRY" ]; then
    printf 'DRY %s\n' "$*"
    case " $* " in *" ${INSTALL_DRY_FAIL:-__none__} "*) return 1 ;; esac
    return 0
  fi
  "$@"
}
```

`INSTALL_DRY_FAIL` is the one test-only hook, and it exists because R5 cannot
be proved without a failure: it makes `run` return 1 for any command whose
argv contains the given word. It mirrors `P1_GUARD_MUTATE` in
`tests/deploy-skeleton.sh` — a hook that only ever makes the run *less*
effective, never more.

`have()` is deliberately **not** hooked. Under a scrubbed `PATH` the gate
gets "fresh machine" for free (`command -v` finds nothing) and, by planting
inert stubs in the scratch bin, "already provisioned" for free too. Since
`run` never executes under dry-run, those stubs are never invoked — which the
gate asserts.

### Homebrew first, PATH re-resolved (R3)

```bash
brew_shellenv() {
  local b
  for b in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    [ -x "$b" ] || continue
    if [ -n "$DRY" ]; then printf 'DRY eval %s shellenv\n' "$b"; return 0; fi
    eval "$("$b" shellenv)"
    hash -r
    return 0
  done
  warn "Homebrew installed but found at neither prefix"; return 1
}
```

- The prefix loop is a **function with a dry branch**, not a bare `eval`.
  That is the fix for the incident: the one call that can rewrite `PATH` is
  the one the seam must cover.
- `hash -r` after the eval. bash caches resolved command paths; a `PATH` that
  changed mid-run is not otherwise guaranteed to be re-searched. The live
  script omits it.
- `export PATH="$HOME/.local/bin:$HOME/.cargo/bin:$PATH"` runs **before**
  anything installs. The live script writes release binaries into
  `~/.local/bin` and never puts that directory on `PATH` during the run, so a
  tool it installed in §2 is invisible to §3 and to the final `chezmoi
  apply` — the exact failure
  [`01-deploy-mechanism`](../../../01-deploy-mechanism/prd.md) R6 exists to
  forbid.

### Never abort (R5)

- `set -uo pipefail`, with **no `-e`**, and a comment saying that the missing
  `-e` is deliberate so nobody "fixes" it.
- Every `run` call site is followed by `|| warn "<what failed>"`.
- The batch install is followed by a per-package retry loop (see
  [`spec02`](spec02.md)); a batch that dies on one bad formula therefore
  still leaves the other eighteen installed.

### Re-runnable by guard (R8)

`have <bin>` gates every step, and the binary name is checked, never the
package name — they differ often enough (`gnupg`/`gpg`, `nushell`/`nu`) that
guessing is wrong. On a provisioned machine the only surviving output is the
batch line, the cask line and `chezmoi apply`.

### `chezmoi apply` last (epic I1)

The last section of the script, guarded on `have chezmoi`, warning if absent.
Everything is installed by then, so `run_after_generate-shell-init.sh` (P.4)
runs with every tool on `PATH`.

### What comes out of the live script, and why

None of these is named by any requirement in this node or its epic, so none
is ported. Recorded here so the omissions read as decisions:

- **kern** (`relay-kern` release binary) — its consumer, the "kern local
  store / pi surface index", is `DO NOT PORT` in the
  [README exclusion list](../../../../README.md).
- **burrito / `brr`** (§3 git+just build) — `DO NOT PORT`, decided
  2026-08-20, which removed it from R7's required set by name.
- **keydr** (§3 `cargo install --git`) — a typing tutor; no PRD in the tree
  mentions it.
- **nvm + Node + the `pi` agent and its npm extensions** (§4) — no PRD
  requires node on the host. `8fe3a71`'s own message is "drop theme/pi/…
  machinery".
- **The macOS menu-bar auto-hide `osascript`** (§5) — a desktop preference,
  not provisioning, and named by no requirement.
- **The Linux `/etc/sudoers.d` PATH drop-in** (§6) — writes a root-owned file
  outside `$HOME` for a convenience no PRD asks for, and is the one part of
  the live script that cannot be undone by a user.

## The gate, stage `--shape`

`tests/provisioning.sh` takes a stage selector: `--shape` (this spec),
`--packages` ([`spec02`](spec02.md)), `--nvim` ([`spec03`](spec03.md)), no
argument = all three. Same idiom as `tests/deploy-skeleton.sh`: collect
failures, one line each, exit non-zero at the end.

**Every stage runs `install.sh` under `INSTALL_DRY_RUN=1`, with `HOME` and
`PATH` both pointed at scratch**, and the scratch bin holds only what the
script *reads*: `sed`, and a `uname` stub that reports the OS and arch the
stage wants. Two scratch bins:

- `bin-fresh/` — the reads only. `command -v` finds no tool, so the script
  takes the fresh-machine path.
- `bin-provisioned/` — the reads, plus an inert stub for every required
  binary. Each stub writes `REAL-INVOCATION <name> <args>` to stderr and
  exits 66, so if the seam ever leaks the gate says so by name.

Checks:

1. **Poison assertion, in every stage.** No `REAL-INVOCATION` in any run's
   output. This is the stand-in for `deploy-skeleton.sh`'s live-config guard:
   it fails on the leak itself, not on a style rule.
2. **The live-config guard, borrowed verbatim from `tests/deploy-skeleton.sh`.**
   `shasum -a 256 ~/.config/chezmoi/chezmoi.toml` and `chezmoi source-path`
   recorded on entry, asserted unchanged on exit. `install.sh` ends by calling
   `chezmoi apply`; if the seam leaks there, this catches it.
3. **Structural lint on `install.sh`.** Every line whose command position is
   `brew`, `curl`, `cargo`, `npm`, `git clone`, `sudo`, `apt-get`, `pacman`,
   `dnf`, `ln`, `cp`, `mkdir`, `rm`, `chezmoi`, `tar` must be preceded by
   `run `. Lines marked `# NOT-MUTATING` (the reads: `brew list --cask`,
   `nvim --version`) are exempt and must say why. Also: `set -` line contains
   no `e`; and no bare `eval "$(` anywhere — the incident's line shape.
4. **Ordering, content-based.** In the fresh run's transcript, the index of
   the Homebrew-installer line < the index of the `DRY eval … shellenv` line
   < the index of the first `DRY brew install` line, and `DRY chezmoi apply`
   is the last `DRY` line of the run. Compared on whitespace-normalised
   lines, by position, never by exact transcript equality.
5. **R8.** In the provisioned run: no `DRY brew install <single package>`
   line at all, and no Homebrew-installer line — only the batch, the cask and
   `chezmoi apply`.
6. **R5.** With `INSTALL_DRY_FAIL=install`, the run still exits **0** and
   prints at least one `!!` warn line, and still reaches `DRY chezmoi apply`.
7. **PATH re-resolution.** `install.sh` contains an `export PATH=` naming
   both `$HOME/.local/bin` and `$HOME/.cargo/bin`, placed before the first
   install section (line-index comparison, not a string match on the whole
   file).

## Acceptance

Ran green 2026-08-21: `bash tests/provisioning.sh --shape` — exit 0, 36 PASS
/ 0 FAIL, `REAL-INVOCATION` absent from all four runs of the stage. The
"writes nothing outside its scratch" box is asserted by sha256 over `.mi`,
`gates`, `tests`, `home` and `install.sh` plus a repo-root listing, not by
`git status --porcelain`: the `.mi/prd` → `.mi/prds` rename is staged and
uncommitted, so porcelain prints ~160 lines no gate caused (see
`gates/lib.sh`). Checked by hand as well — the only additions under the repo
root and `tests/` are `install.sh` and `tests/provisioning.sh`.

- [x] `install.sh` exists at the repo root, is executable, and `bash -n
      install.sh` parses.
- [x] A fresh-machine dry run exits 0 and its transcript contains, **in this
      order**: the Homebrew installer line, `DRY eval <prefix>/brew
      shellenv`, the first `DRY brew install`, and `DRY chezmoi apply` as the
      final `DRY` line.
- [x] A provisioned dry run exits 0 and contains **no** per-package `brew
      install` line and **no** Homebrew-installer line — the guards, not a
      hash gate, make the re-run cheap. (R8)
- [x] With `INSTALL_DRY_FAIL=install` the run exits **0**, prints at least one
      `!!` line, and still reaches `DRY chezmoi apply`. (R5)
- [x] `install.sh`'s `set -` line contains `u` and `o pipefail` and **not**
      `e`, and the file contains no bare `eval "$(`.
- [x] The structural lint finds no unwrapped mutating command in
      `install.sh`, and **does** find one when a bare `brew install foo` is
      appended to a scratch copy.
- [x] `install.sh` exports a `PATH` containing `$HOME/.local/bin` and
      `$HOME/.cargo/bin` before its first install section. (R6 of
      `01-deploy-mechanism`)
- [x] No run of the gate emits `REAL-INVOCATION`, and after the whole gate
      `~/.config/chezmoi/chezmoi.toml` has the same sha256 as before and
      `chezmoi source-path` still prints `/Users/feb/dev/.files/home`.
- [x] The gate writes nothing outside its scratch directory: `git status
      --porcelain` afterwards shows only the files this spec adds.
- [x] `bash tests/provisioning.sh --shape` exits 0, and exits non-zero with
      `install.sh` temporarily moved aside on a scratch copy.

## Proven RED

Against the tree as it stands, 2026-08-21:

- `install.sh` does not exist at the repo root (`[ -e install.sh ]` false).
- `tests/provisioning.sh` does not exist. All three specs' literal `verify:`
  commands exit **127**: `--shape`, `--packages`, `--nvim`.

Proven GREEN in scratch, against a prototype carrying exactly the design
above (`bash` 3.2, this machine, five runs):

- fresh macOS: exit 0, order as asserted, `DRY chezmoi apply` last.
- provisioned: exit 0, batch + cask + apply only, **zero** per-package lines.
- `GATE_NVIM_MINOR=9`: floor branch taken (see [`spec03`](spec03.md)).
- `INSTALL_DRY_FAIL=install`: exit 0, two `!!` lines, apply still reached.
- forced `uname -s` = Linux: exit 0, distro branch taken.
- **`REAL-INVOCATION` appeared in none of the five**, and `chezmoi
  source-path` / the live config sha256
  (`02d5d4ee50b5d37955ffe7778938ddee82f4da24cbaf552b4dba3810d3c850a1`) were
  unchanged throughout. The same five runs under the *rejected* PATH-shim
  design are what caused `## The incident`.

## Out of scope

- The package list and the platform ladder — [`spec02`](spec02.md).
- The Neovim floor — [`spec03`](spec03.md).
- **R3's own node.** `install.sh` §1 is where R3 lives, and §1 is one section
  of one flat file that cannot be split without re-introducing the modularity
  `8fe3a71` removed. P.2 therefore writes and gates R3's mechanism.
  `05-platform/02-package-provisioning/homebrew-bootstrap` (P.3) has no file
  left to write — its `plan.json` footprint `run_once_before_*` names a
  chezmoi script stage that no longer exists. **P.3 must not be dispatched to
  edit `install.sh`**; see the note in [`spec02`](spec02.md)'s Out of scope.
- `run_after_generate-shell-init.sh`. P.4 owns it; this script only calls
  `chezmoi apply`, which runs it.
- Anything under `home/`. `install.sh` is not a managed file.
