---
state: done
claim:
priority: 26
est: 5h
task: C.1
mode: afk
needs:
  - 00-delivery/decisions/odin-toolchain
  - 06-help/01-content-model
  - 05-platform/02-package-provisioning/packages-installer
  - 00-delivery/corrections/w0-5-capsule-rebase
verify: "bash tests/dev-image.sh"
---

# Dev image

Parent: [Capsule epic](../prd.md) · C 7 · U 8 · sources: "Standalone
dev container image" (C 7 / U 8 — dominant), the image half of
"Capsule" (CONSOLIDATE, C 9 / U 9)

Purpose: Exactly one image definition for capsule containers, merging
the two legacy images: the standalone `devzsh`-style toolbox and the
capsule image. The interactive layer is the capsule image's alone —
`devzsh` bakes in no zsh (`CMD ["bash"]`), no oh-my-zsh, and no
Claude Code (finding C-4) — so R1 and R4 are specified from the
capsule image definition, not ported from `devzsh`. Ubuntu LTS base,
unprivileged `dev` user, `/workspace` as workdir.

## Requirements
- [x] **R1** — **Shell environment.** zsh + oh-my-zsh as the interactive shell
      (the zsh config itself is container-only; the host zshrc is not ported).
      2026-08-22: `getent passwd dev` → `/usr/bin/zsh`; `zsh -ic 'echo $ZSH'`
      → `/opt/oh-my-zsh`; `.zshrc` baked in the image's final layer.
- [x] **R2** — **CLI toolbox.** ripgrep, fd, fzf, tmux, neovim, bat, eza, git,
      build-essential, Python. 2026-08-22: 13-tool `$PATH` probe PASS in
      `tests/dev-image.sh --build`.
- [x] **R3** — **Runtimes.** Node 22 (or current LTS). 2026-08-22:
      `node --version` → `v24.19.0` (NodeSource current LTS).
- [x] **R4** — **Agents.** Claude Code and OpenCode preinstalled. 2026-08-22:
      `claude` and `opencode` resolve on `$PATH` as `dev`.
- [x] **R5** — **User.** Unprivileged `dev` user with passwordless sudo,
      created by the image or first-run setup — not running as root.
      2026-08-22: `whoami` → `dev`, `id -u` → `1001`, `sudo -n true` exits 0.
- [x] **R6** — **Layering for speed.** Order layers so tool installs cache
      well; a config tweak must not re-download toolchains. 2026-08-22:
      config-layer edit rebuilt with every earlier layer digest-identical;
      apt-layer control diverged (`tests/dev-image.sh --build`).
- [x] **R7** — **Closed toolbox.** R2, R3 and R4 are exhaustive: the image
      installs nothing they do not name. Adding a language toolchain or a
      second agent to the base is an edit to those lines with a reason, never
      a quiet extra layer — one such toolchain was already dropped, see
      `## Decisions`. 2026-08-22: `--static` compares the apt and npm sets
      literally and FAILs naming any extra or missing package; smuggled-
      package selftest fires on every invocation.

## Acceptance
- [x] Single `Dockerfile` in the repo; nothing else builds a dev image.
      2026-08-22: `--static` census PASS —
      `home/dot_config/capsule/Dockerfile` is the only non-markdown
      `*[Dd]ockerfile*` match in the repo.
- [x] Cold build completes without interaction; rebuild after editing only the
      final config layer reuses all toolchain layers. 2026-08-22: cold build
      PASS; cache-reuse proof PASS (`tests/dev-image.sh --build`, EXIT=0).
- [x] `whoami` inside a capsule prints `dev`; `sudo true` succeeds without a
      password; all listed tools are on `$PATH`. 2026-08-22: `dev` /
      `SUDO-OK` / `TOOLS-OK` (spec01's Verify block, run verbatim).

## Out of scope
- Anything this node's Requirements do not name. The epic ([`../prd.md`](../prd.md)) owns the shared invariants.
- The Odin compiler built from source, and the `pi` agent with its
  pi-oilrig extensions. Dropped 2026-08-21 — see `## Decisions` for the
  reason and for where the capability went instead.

## Decisions

**Decided 2026-08-21 (user): the Odin compiler built from source, and the
`pi` agent with its ~20 pi-oilrig extensions, are dropped from the
consolidated image.** Recorded from
[`00-delivery/decisions/odin-toolchain`](../../00-delivery/decisions/odin-toolchain/prd.md),
which is where the fork was put to the human. This matches the recommendation
this PRD carried while the question was open.

Why: they dominate cold build time and serve a minority of projects, so every
capsule would pay a toolchain cost few of them use — against the epic's goal
that cold start is dominated by docker itself and not by what we chose to
bake in.

The capability is **relocated, not lost**. A project that needs Odin or `pi`
adds it per-project, in its own image built `FROM` this base; the base image
and the capsule CLI install neither and know nothing about it. Layering
per-project is outside the capsule tool's scope by design — see the epic's
[Out of scope](../prd.md).
