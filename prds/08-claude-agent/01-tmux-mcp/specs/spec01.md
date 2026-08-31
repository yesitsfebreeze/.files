---
complexity: 7
footprint:
  - install.sh
---

# spec01 — the tmux-mcp release rung in install.sh

A `have tmux-mcp`-guarded block in section 2 of `install.sh` (the GitHub
-release rung, after tinty, before the Neovim floor) that installs
`tmux-mcp` from the MadAppGang release tarball into `~/.local/bin`. It
follows the tinty pattern exactly: `latest_tag MadAppGang/tmux-mcp`, then
`fetch_release` on
`https://github.com/MadAppGang/tmux-mcp/releases/download/$tag/tmux-mcp-$TRIPLE.tar.gz`,
where `$TRIPLE` is `darwin_amd64` / `darwin_arm64` / `linux_amd64` /
`linux_arm64` (the four assets the release carries; measured on v1.7.1 —
the tarball holds the binary and a README at its root, which is the shape
`fetch_release_do`'s `find` already handles). Go is NOT a requirement: the
prebuilt release is the mechanism, the same rung tinty rides, and the PRD
names this file as where the install obligation lands.

What already stands, as of the 2026-08-31 pass one: the binary itself is
installed at `~/.local/bin/tmux-mcp` (v1.7.1, extracted by hand) and the
MCP registration is live (spec02's territory). What is left is only the
installer obligation: a fresh machine gets the binary without Go, and a
machine that has it stays silent (R8).

Two measured facts the implementer must not re-derive:

- **The Go-flag syntax is single-dash.** The binary parses `-shell-type
  bash -scope agentic` (double-dash also accepted by Go's flag package).
- **The version flag is `-version`**, which answers `1.7.1` and exits 0 —
  the cheap check a later wave can pin on.

Constraints carried verbatim: every mutating step through `run()` (the
tarball fetch already lives inside the DRY-sealed `fetch_release_do`),
`latest_tag`'s warn-not-skip contract for an empty tag, R5 (a failure
warns and the run continues), R8 (have-guard). Do not add `tmux-mcp` to
PKGS: it is no formula. Do not add a checksum step `fetch_release` does
not have for tinty — same rung, same trust line; widening it here is a
correction to 05-platform/02, not this spec.

## Acceptance

- [x] `INSTALL_DRY_RUN=1 ./install.sh` prints a `DRY-READ tag` line for
      `repos/MadAppGang/tmux-mcp/releases/latest` and a
      `DRY fetch_release_do tmux-mcp …releases/download/v0.0.0-dry/…`
      line, both AFTER section 2 and BEFORE the `DRY chezmoi apply` line
      that must remain the last DRY line of the transcript.
      Measured 2026-08-31, impl-tmux-mcp. On THIS machine the bare
      `INSTALL_DRY_RUN=1` transcript is box 2's (the binary is on PATH), so
      the fresh-machine transcript was taken the way `tests/provisioning.sh`
      takes it — a scratch HOME and a stubbed PATH:
      `env -i HOME=/tmp/scr-home PATH=/tmp/gatebins:/usr/bin:/bin INSTALL_DRY_RUN=1 bash install.sh | grep -nE 'tmux-mcp|DRY chezmoi apply'`
      printed (Darwin/arm64):
      `30:DRY-READ tag https://api.github.com/repos/MadAppGang/tmux-mcp/releases/latest`
      `31:DRY fetch_release_do tmux-mcp https://github.com/MadAppGang/tmux-mcp/releases/download/v0.0.0-dry/tmux-mcp_darwin_arm64.tar.gz`
      `40:DRY chezmoi apply`
      and with the uname stub answering Linux/x86_64 the same two lines read
      `linux_amd64`, at 5/6 with `DRY chezmoi apply` at 28. Line 31's URL is
      the spec's `…/v0.0.0-dry/…` shape.
- [x] On a machine that already has `tmux-mcp` on PATH, the block prints
      nothing and runs nothing (R8, have-guard). Measured 2026-08-31:
      `INSTALL_DRY_RUN=1 ./install.sh 2>&1 | grep -iE 'tmux-mcp|chezmoi apply'`
      on this machine (which has the binary) answers only `DRY chezmoi apply`.
- [x] `bash tests/provisioning.sh` passes with the new block in place —
      its structural assertions (run() wrapping, the last DRY line, R5
      warn-not-abort) still hold. Measured 2026-08-31: 0 FAIL lines, all
      counterfactuals pass, `the gate wrote nothing outside its scratch`.
      Its `every PKGS binary is provided` check is unaffected (tmux-mcp is
      deliberately not in PKGS).
- [x] Running the script for real on a machine WITHOUT `tmux-mcp` on PATH
      ends with `~/.local/bin/tmux-mcp -version` printing a `1`-leading
      semver and exit 0. Closed 2026-08-31 by running the rung for real:
      a full real `./install.sh` on this machine re-enters section 1's
      unconditional `brew install` batch, so the rung was exercised as a
      slice — install.sh's own code (constants, `have`/`log`/`warn`/`run`,
      `latest_tag`, `fetch_release`, `fetch_release_do`, verbatim) plus the
      new block verbatim, run under `env -i PATH=/usr/bin:/bin HOME=$HOME`
      with the pass-one binary moved off PATH first
      (`mv ~/.local/bin/tmux-mcp ~/.local/bin/tmux-mcp.pre-slice-backup`).
      Output: `:: installed tmux-mcp`, slice rc=0; then
      `~/.local/bin/tmux-mcp -version` → `1.7.1`, rc=0. The backup was
      removed afterwards; the installed binary is the release asset's.

      **One measured deviation from this spec, kept and not silently
      absorbed:** the release assets are named `tmux-mcp_$TRIPLE.tar.gz`
      (UNDERSCORE) — this spec's `tmux-mcp-$TRIPLE.tar.gz` answers 404 on
      every one of the four assets for v1.7.1 (HTTP 404 measured on all
      four). The first slice run proved it: `curl: (56) … 404`, then the
      R5 warn. The landed block uses the underscore spelling; the GitHub API
      asset list for v1.7.1 is `tmux-mcp_{darwin,linux}_{amd64,arm64}.tar.gz`,
      four assets, plus `checksums.txt`. The triple list, the tarball shape
      and every constraint held as written.

## Verify and Proof

```sh
cd /Users/feb/dev/dotfiles && INSTALL_DRY_RUN=1 ./install.sh 2>&1 | grep -iE 'tmux-mcp|chezmoi apply'
bash tests/provisioning.sh
~/.local/bin/tmux-mcp -version
```