---
state: open
mode: afk
deps:
  - .mi/prd/00-delivery/corrections/w0-5-capsule-rebase
  - .mi/prd/00-delivery/decisions/odin-toolchain
  - .mi/prd/05-platform/02-package-provisioning/packages-installer
  - .mi/prd/06-help/01-content-model
verify: ""
---

# Dev image

Parent: [Capsule epic](../prd.md) · C 7 · U 8 · sources: "Standalone dev

Purpose: Exactly one image definition for capsule containers, merging the two
previous images (the standalone `devzsh`-style toolbox and the capsule image).
Ubuntu LTS base, unprivileged `dev` user, `/workspace` as workdir.

## Requirements
- [ ] **R1** — **Shell environment.** zsh + oh-my-zsh as the interactive shell
      (the zsh config itself is container-only; the host zshrc is not ported).
- [ ] **R2** — **CLI toolbox.** ripgrep, fd, fzf, tmux, neovim, bat, eza, git,
      build-essential, Python.
- [ ] **R3** — **Runtimes.** Node 22 (or current LTS).
- [ ] **R4** — **Agents.** Claude Code and OpenCode preinstalled.
- [ ] **R5** — **User.** Unprivileged `dev` user with passwordless sudo,
      created by the image or first-run setup — not running as root.
- [ ] **R6** — **Layering for speed.** Order layers so tool installs cache
      well; a config tweak must not re-download toolchains.

## Acceptance
- [ ] Single `Dockerfile` in the repo; nothing else builds a dev image.
- [ ] Cold build completes without interaction; rebuild after editing only the
      final config layer reuses all toolchain layers.
- [ ] `whoami` inside a capsule prints `dev`; `sudo true` succeeds without a
      password; all listed tools are on `$PATH`.

## Out of scope
- Anything this node's Requirements do not name. The epic ([`../prd.md`](../prd.md)) owns the shared invariants.

## Open questions

- Keep the Odin-compiler-from-source and pi/pi-oilrig extensions from the old
  standalone image, or drop them from the consolidated image? They dominate
  build time; default recommendation is **drop** and add per-project later.
