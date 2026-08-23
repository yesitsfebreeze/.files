---
state: done
priority: 44
est: 5h
task: P.2
mode: afk
needs:
  - 05-platform/01-deploy-mechanism/repo-skeleton
  - 00-delivery/decisions/fzf
verify: "bash tests/provisioning.sh"
---

# Tool installer (install.sh)

Parent: [`02-package-provisioning`](../prd.md) · source:
[`02-package-provisioning`](../prd.md) requirements R4, R5, R6, R7, R8; R1
and R2 withdrawn

The node id is its directory path, so the directory keeps its name even
though the heading no longer does — `02-package-provisioning`'s allocation
list and `plan.json`'s P.2 both cite the path.

## Requirements
- [ ] **R1** — **Tools as data.** *Withdrawn 2026-08-21.* This required the
      214-line YAML package set under `home/.chezmoidata/`, with the
      installer as a renderer over it. Commit `8fe3a71` (2026-08-19,
      *"Simplify dotfiles: drop theme/pi/data-driven machinery, minimal
      chezmoi, one plain install.sh"*) deleted both. Kept here with its
      number rather than deleted, because requirements are cited by number
      and a renumber reads as an error. See R8 for what replaces it.
- [ ] **R2** — **Re-run only on change.** *Withdrawn 2026-08-21.* This
      required a content-hash comment in the installer so chezmoi's
      change-detecting script stage re-ran it when — and only when — the list
      changed. The 486-line template it guarded went out with `8fe3a71`. See
      R8.
- [x] **R4** — **macOS path is the supported one.** brew for everything
      available there. The Linux ladder (distro package → prebuilt GitHub
      release tarball → cargo) exists for capsule containers; keep it, but
      macOS is what the gates test. The ladder lives in `install.sh` — §1
      brew/apt/pacman/dnf, §2 the `latest_tag`/`fetch_release` release
      tarballs, §3 cargo and git builds — not in a chezmoi template.
      **Built** as §1 package manager, §2 release rung, §3 the Neovim
      floor, §4 `chezmoi apply`; the cargo/git-build rung went out with its
      only two consumers (`keydr`, burrito), so the ladder is two rungs.
      **Proved** by `bash tests/provisioning.sh --packages`: with `uname`
      reporting Linux/x86_64 the run takes the apt branch, emits the
      `batcat`→`bat` and `fdfind`→`fd` symlinks, and falls through to
      release lines for `tv`, `nu`, `gh`, `lazygit`, `starship` and
      `tinty`; with no package manager present it warns and exits 0.
- [x] **R5** — **Never abort.** A failed package warns and continues
      (`command -v` guards keep it idempotent). A partial machine beats a
      dead apply. `install.sh` proves this by construction: `set -uo
      pipefail` with **no** `-e`, and every failure path calls `warn` and
      falls through.
      **Proved** by `bash tests/provisioning.sh --shape` and
      `--packages`: with `INSTALL_DRY_FAIL=install` the run exits 0, prints
      23 `!!` lines and still reaches `DRY chezmoi apply`; the failed batch
      is followed by 20 single-package retries, one per entry, because a
      lone `brew install` aborts on the first unknown formula and never
      attempts the names after it. An unresolvable release tag warns and
      names the repo instead of skipping silently.
- [x] **R6** — **Neovim version gate.** The config requires ≥ 0.11 (native
      `vim.lsp.enable`, blink.cmp) — in practice the live machine runs 0.12.x.
      Distro packages ship too-old builds, so on Linux override with the
      official release tarball when nvim is missing or older than the floor;
      macOS gets a current one from brew. **Record the floor in one place**
      and have [`03-editor`](../../../03-editor/prd.md) reference it rather than
      restating a version. `install.sh` §2 is where it is enforced: it parses
      `nvim --version`, and when the minor is below 11 it installs the
      official release tarball into `~/.local/opt/neovim`.
      **Built** in §3 rather than §2, recorded once as
      `install.sh:NVIM_MIN_MINOR`, and gated on the VERSION rather than on
      the OS — the live script wraps the whole check in `[ "$OS" !=
      "Darwin" ]`, so the floor is never asserted on the supported platform
      at all. **Proved** by `bash tests/provisioning.sh --nvim`: the
      constant is declared exactly once and the number appears nowhere else
      in the file; `0.9.5` and an unparseable banner take the override,
      `0.11.0`, `0.12.4` and `1.0.0` do not (the live parser is anchored to
      `^NVIM v0\.` and would downgrade a 1.x); the override is taken on
      Darwin as well as Linux; and with it forced to fail the run exits 0
      with a `!!` line naming the floor.
- [x] **R7** — **Required set.** At minimum: nushell, television, zoxide,
      starship, neovim, git, ripgrep, fd, bat, eza, fzf, lazygit, chezmoi,
      tinty, docker, gh. (`fzf` is in the set as `zi`'s
      dependency, not as a picker to reach for: `zoxide query --interactive`
      spawns it. **Decided 2026-08-21 (user)** — an accepted, documented
      exception to `04-shell`'s "tv owns every picker screen"; see
      [`decisions/fzf`](../../../00-delivery/decisions/fzf/prd.md) and the
      record in [`corrections`](../../../00-delivery/corrections/prd.md),
      decision 3.) The terminal multiplexer that used to close this list is
      out: `DO NOT PORT`, decided 2026-08-20, which names the required
      package set explicitly. `install.sh` §3 still builds it from its own
      justfile — the live script is not the spec, and this requirement
      describes the rebuild's required set, so the strip stands without
      reconciling against `install.sh`.
      **Proved** by `bash tests/provisioning.sh --packages`: the fresh
      macOS dry-run's batch line, parsed as a set, is a superset of the
      fifteen brew-able names, and `tinty` — which no package manager
      carries and which the live script never installs — is satisfied on
      the release rung in the same transcript. `chezmoi`, the other name
      the live script never installs, is in the batch.
- [x] **R8** — **Re-runnable by guard, not by hash.** Every install step is
      `command -v`-guarded, so a second run on a provisioned machine
      installs nothing and exits 0. This is what replaces R1 and R2: the
      cheap-re-run property survives, the data model and the hash gate that
      used to deliver it do not.
      **Proved** by `bash tests/provisioning.sh --shape`: against a
      provisioned scratch machine the run exits 0 with **zero**
      per-package `brew install` lines, no Homebrew-installer line and no
      cask line — only the batch and `chezmoi apply`. Guards key on the
      BINARY name, not the package name (`gnupg=gpg`, `git-delta=delta`),
      which `--packages` asserts.

## Acceptance
- [x] Every live requirement box above is `[x]` against the real thing:
      R4, R5, R6, R7 and R8, each proved by the stage of
      `tests/provisioning.sh` named on it — 114 PASS / 0 FAIL across
      `--shape`, `--packages` and `--nvim` (2026-08-21). R1 and R2 were
      withdrawn on 2026-08-21 and carry no check; they stay unticked
      because a withdrawn requirement has nothing to prove, not because it
      is outstanding.

## As built — deviations from the specs' literal snippets

Every one is a consequence of the specs' own rules colliding; recorded so a
reader comparing spec to code does not read drift.

- **`latest_tag` has an explicit dry branch instead of
  [`spec02`](specs/spec02.md)'s `run_read curl`.** A `run_read` that executes
  would still make a network read under `INSTALL_DRY_RUN`, and an unwrapped
  `curl` in command position is exactly what
  [`spec01`](specs/spec01.md)'s lint forbids. Under dry-run it answers with
  `DRY_TAG` so the URL builders downstream still have a value, and
  `INSTALL_DRY_FAIL` still forces the empty-tag path check 7 exists for.
- **Casks are guarded on a Caskroom directory test, not `brew list --cask`.**
  Spec02 marks that read `# NOT-MUTATING` and lets it execute — but executing
  `brew` *at all* trips spec01's own `REAL-INVOCATION` poison assertion,
  since the provisioned scratch bin's `brew` is a poison stub. The directory
  test needs no Homebrew process, works before shellenv has put brew on
  `PATH`, and the prefix comes from Homebrew's own `HOMEBREW_PREFIX`, so it
  needs no new test-only hook.
- **`run`'s `DRY` line goes to stderr, not stdout.** Spec01's snippet prints
  to stdout; a `tag="$(latest_tag …)"` would then swallow diagnostics into
  the value, and mixing a block-buffered stdout with an unbuffered stderr in
  one transcript reorders the very lines the ordering box asserts on.
- **`eval "$(…)"` is split into `env_out="$(…)"` then `eval "$env_out"`.**
  Spec01's design snippet keeps the compact form, but its own check 3 forbids
  that literal shape anywhere in the file. Splitting it satisfies both.
- **Sections are §1 package manager, §2 release rung, §3 the Neovim floor,
  §4 `chezmoi apply`.** R4 names a cargo/git-build rung; both its consumers
  (`keydr`, burrito) are `DO NOT PORT`, so it has nothing left to build and
  the floor moved into the freed §3. `wt` (worktrunk) went with it — it is in
  no requirement's package set.
- **A `# DRY-SEALED` marker, and what the lint does with it.** Three helper
  bodies are genuinely mutating (`brew_bootstrap_do`, `fetch_release_do`,
  `nvim_release_do`) and are reachable only through `run`. Marking their
  lines `# NOT-MUTATING` would be a lie, so the header carries `# DRY-SEALED`
  instead: the lint exempts the body and, in exchange, proves every call site
  of such a function goes through `run `.
- **`git-delta=delta` is in `PKGS`.** Spec02's rung table lists `delta` under
  brew for macOS; its `PKGS` snippet omits it and its gate check 2 names it.
  Added, which also makes check 2's second shape real rather than vacuous.
- **The final section reads `have chezmoi || [ -n "$DRY" ]`.** `chezmoi` is
  in `PKGS`, so a real run has it by then; a dry run installed nothing, and
  the seam has to show the call the real run would make for the "last `DRY`
  line" box to mean anything. The `have` guard and its warning are unchanged
  for real runs.

## Out of scope
- The sibling node's requirements. This document held two contracts and was split;
  the parent lists which requirement went where.

## Closing note

*Closed 2026-08-21 by the orchestrator.* `bash tests/provisioning.sh` →
**115 PASS / 0 FAIL, exit 0** across all three stages, re-run independently
(36 / 45 / 42 per stage), from a RED baseline of exit 127 on each. `install.sh`
(417 lines, executable) and `tests/provisioning.sh` both landed. R4–R8 and
Acceptance `[x]`; **R1/R2 left `[ ]` deliberately** — they are *withdrawn*, so
there is nothing to prove, and the implementer noted that in the acceptance box
rather than faking a tick.

**The dry-run seam held, and this is the ticket that mattered for.** During
analysis an agent broke this machine's login shell by prototyping a gate with a
scratch `HOME` and a `PATH` shim; the live `install.sh` §1 evaluates
`brew shellenv` by **absolute path**, which defeats the shim and then prepends
the real Homebrew prefix to `PATH`, making every later `brew install` real —
while still exiting 0. All 20 installer invocations here went through
`INSTALL_DRY_RUN=1` with scratch `HOME`, scratch `PATH` and `env -i`, both
scratch bins carrying poison stubs that exit 66. **Zero real invocations**,
asserted per run. `brew_shellenv` and `latest_tag` — the two calls that could
rewrite `PATH` or reach the network — each carry an explicit dry branch. The
new `install.sh` opens by recording that failure and its cause, so the next
reader meets it before the code.

**Every baseline value re-checked by the orchestrator and unchanged:** nushell
0.114.1, lazygit 0.64.0, gh 2.97.0, docker formula not installed with Docker
Desktop's `/usr/local/bin/docker` intact, `chezmoi source-path`
`/Users/feb/dev/.files/home`, `chezmoi.toml` sha256 `02d5d4ee…`, nvim 0.12.4.
`/Users/feb/dev/.files` untouched.

All eight do-not-reintroduce items verified absent: `kern`, burrito/`brr`,
`keydr`, nvm/Node/npm/`pi`, the macOS menu-bar `osascript`, the Linux
`/etc/sudoers.d` drop-in, and `worktrunk` (dropped because no requirement names
it).

**Real defects fixed, not just ported:** four of R7's sixteen were missing from
the live batch (`chezmoi`, `docker`, `eza`, `tinty` — `tinty` appeared zero
times despite four scheduled nodes inheriting the palette it owns); a single
batch `brew install` aborts on an unknown formula and never attempts the names
after it, so R5 needed the `have`-guarded per-package retry (proved: 20 of 20
retries after an induced batch failure, apply still reached); `~/.local/bin` was
never on `PATH` during the run, so a release binary from §2 was invisible to §3
and to the final `chezmoi apply`; an unresolvable GitHub tag was a silent skip
and now warns by name; the Neovim floor was never checked on macOS at all; and
the live parser anchored to `^NVIM v0\.` would treat a Neovim **1.x** as below
the floor and install an older tarball over it — dormant at 0.12.4, which is why
it would not have been noticed when it stopped being.

Eight deliberate deviations from the specs' literal snippets are recorded in the
ticket's `## As built` section, each a genuine collision between two spec rules
— e.g. spec02's `run_read curl` would still reach the network under dry-run, and
its `brew list --cask` read would trip spec01's own poison assertion, so casks
are guarded on a Caskroom directory test instead.

**Orchestrator follow-up applied:** `gates/waves.tsv` wave 1 listed P.2 among
its tasks while naming only `deploy-skeleton.sh` and `managed-config.sh` as its
gates — so when wave 1 armed it would have gone red for a gate that exists.
`external bash tests/provisioning.sh` added; `just gates` still exit 0.

One reporting inaccuracy worth noting: the implementer reported `install.sh` at
340 lines; it is 417. Immaterial to the work, but the number in its report was
wrong.
