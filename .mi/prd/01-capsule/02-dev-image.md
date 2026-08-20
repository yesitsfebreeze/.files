# Feature: Dev image

Parent: [Capsule epic](00-epic.md) · C 7 · U 8 · sources: "Standalone dev
container image", capsule image description

## Summary

Exactly one image definition for capsule containers, merging the two previous
images (the standalone `devzsh`-style toolbox and the capsule image). Ubuntu
LTS base, unprivileged `dev` user, `/workspace` as workdir.

## Requirements

1. **Shell environment.** zsh + oh-my-zsh as the interactive shell (the zsh
   config itself is container-only; the host zshrc is not ported).
2. **CLI toolbox.** ripgrep, fd, fzf, tmux, neovim, bat, eza, git,
   build-essential, Python.
3. **Runtimes.** Node 22 (or current LTS).
4. **Agents.** Claude Code and OpenCode preinstalled.
5. **User.** Unprivileged `dev` user with passwordless sudo, created by the
   image or first-run setup — not running as root.
6. **Layering for speed.** Order layers so tool installs cache well; a config
   tweak must not re-download toolchains.

## Open questions

- Keep the Odin-compiler-from-source and pi/pi-oilrig extensions from the old
  standalone image, or drop them from the consolidated image? They dominate
  build time; default recommendation is **drop** and add per-project later.

## Acceptance criteria

- Single `Dockerfile` in the repo; nothing else builds a dev image.
- Cold build completes without interaction; rebuild after editing only the
  final config layer reuses all toolchain layers.
- `whoami` inside a capsule prints `dev`; `sudo true` succeeds without a
  password; all listed tools are on `$PATH`.
