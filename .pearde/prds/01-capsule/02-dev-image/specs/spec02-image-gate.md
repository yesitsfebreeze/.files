# spec02 — the image gate (tests/dev-image.sh)

Write `tests/dev-image.sh`, the standing proof for spec01's Dockerfile: a
hermetic `--static` stage that needs no docker and a `--build` stage that
builds and probes the real image, including the R6 cache-reuse proof.
Register the static stage as wave 2's gate line. Style and PASS/FAIL
plumbing follow `tests/provisioning.sh` and `gates/lib.sh`'s `chk`.

**Est:** 2h

**Footprint:** `tests/dev-image.sh`, `gates/waves.tsv` (one line — see the
collision note at the end)

## Design

`bash tests/dev-image.sh [--static|--build]`; no argument runs both.

**`--static` — hermetic, parses `home/dot_config/capsule/Dockerfile`:**

- **Single definition.** `find` from the repo root: exactly one file
  matching `*[Dd]ockerfile*`, at the expected path.
- **Closed toolbox (R7).** Extract every package name from `apt-get
  install` lines; the set must equal, exactly, R2's apt names (`ripgrep
  fd-find fzf tmux neovim bat git build-essential python3 python3-pip
  zsh`) plus the support set (`curl ca-certificates sudo openssh-client`)
  plus `nodejs`. One extra or one missing name is a FAIL naming it.
  `npm install -g` installs exactly `@anthropic-ai/claude-code`.
- **Dropped toolchain guard.** Case-insensitive: `odin`, `pi-oilrig`,
  `pi-coding-agent` appear nowhere.
- **Layer order (R6).** The apt toolbox `RUN` precedes Node, Node precedes
  the agents, the agents precede `useradd`, and the `.zshrc` config layer
  is the final `RUN`. `USER dev`, `WORKDIR /workspace` and a `CMD` follow
  every `RUN`.
- **No pinned architecture.** `x86_64|amd64|aarch64|arm64` may appear only
  on the line(s) deriving the arch variable from `uname -m`; never inside
  a fetch URL, which must interpolate the variable.
- **No ingress.** No `COPY`, no `ADD` — nothing from the host can enter a
  layer (C.3 R5's no-secrets-in-image, enforced structurally).
- **Selftest controls** (law: a check that cannot fail proves nothing).
  Against a scratch copy, each mutation must exit 1: append
  `RUN apt-get install -y cowsay`; move the Node layer after the config
  layer; replace the eza URL's arch variable with a literal `x86_64`;
  insert a `COPY . /tmp/ctx`.

**`--build` — real, requires docker:**

- Docker CLI absent or daemon unreachable: FAIL with a line naming the
  assumption. Never skip-and-pass — this stage green must mean the image
  was built.
- Copy the Dockerfile to a scratch dir, build tag
  `capsule-gate-$$`; run spec01's runtime probes (`whoami`, `id -u`,
  `sudo -n true`, the 13-tool `$PATH` loop, `node --version` major ≥ 22,
  `zsh -ic 'echo $ZSH'` → `/opt/oh-my-zsh`, `docker inspect` for
  `WorkingDir`/`User`/`Cmd`).
- **Cache reuse (R6, the PRD's own acceptance line).** Mutate only the
  final config layer in the scratch copy (append a comment line to the
  `.zshrc` heredoc), rebuild under a second tag, then compare
  `docker image inspect --format '{{json .RootFS.Layers}}'` of both
  builds: every layer except the last must be digest-identical. A
  toolchain re-download shows up here as a diverged early digest.
- Always clean up: `docker rmi` both tags, remove the scratch dir, even on
  failure paths.

**Wave registry.** Append to `gates/waves.tsv` wave 2's gates cell:
`external bash tests/dev-image.sh --static`. Static only — waves gates run
from the repo root on every arm and must not be network-bound; the
`--build` stage is this node's own close-time proof. **Collision note:**
`gates/waves.tsv` is held by another lane at spec time. If it is still held
at implementation, land the test and report the one-line registration as
owed rather than editing a file another lane owns.

## Acceptance

- [x] `bash tests/dev-image.sh --static` exits 0 against spec01's
      Dockerfile with no docker daemon involved (provable by
      `PATH` without docker). 2026-08-22:
      `env -i HOME=$HOME PATH=/usr/bin:/bin bash tests/dev-image.sh
      --static` → EXIT=0.
- [x] Each of the four selftest mutations exits 1, each with a FAIL line
      naming the violated rule; the selftests run on every invocation.
      2026-08-22: all four PASS lines in every run; the inner FAIL lines
      are surfaced indented above each.
- [x] With an extra package smuggled into the apt layer of a scratch copy,
      `--static` FAILs naming the package (R7 executed, not asserted).
      2026-08-22: `extra: cowsay` in the surfaced FAIL line.
- [x] `bash tests/dev-image.sh --build` exits 0 on this host: image
      builds, all runtime probes pass. 2026-08-22: full run EXIT=0,
      47 PASS, 0 FAIL. (During long cold-build runs the repo-wide
      snapshot line can go red when sibling lanes land edits mid-run —
      concurrency, not a leak; isolated reruns are clean.)
- [x] The cache-reuse check passes — config-layer edit, rebuild, all
      pre-final layer digests identical — and, as a control, forcing the
      mutation into the apt layer instead makes it FAIL. 2026-08-22: both
      PASS. The boundary is the last TWO layers: `WORKDIR /workspace`
      after `USER dev` emits its own 0B layer that re-emits whenever the
      layer before it rebuilds; every layer before the config layer is
      digest-identical.
- [x] With docker unreachable (`PATH` shim), `--build` exits 1 naming the
      missing assumption — it does not pass vacuously. 2026-08-22:
      `FAIL build: docker CLI on PATH — ASSUMPTION MISSING ...`, EXIT=1.
- [x] No test run leaves a `capsule-gate-*` image or container behind
      (`docker images` after the run). 2026-08-22: both leftover checks
      PASS; `docker images` shows none.
- [x] Wave 2's gates cell carries
      `external bash tests/dev-image.sh --static`, or the report records
      the line as owed to the lane holding `gates/waves.tsv`. 2026-08-22:
      registered by the orchestrator while this lane observed the
      footprint hold; `gates/waves.tsv:23` carries the line.

## Verify

```sh
# --static is hermetic: no docker, no network.
bash tests/dev-image.sh --static
# Full run assumes docker CLI + running daemon + network (see spec01).
bash tests/dev-image.sh
```
