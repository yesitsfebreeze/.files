---
kind: decision
date: 2026-09-29
status: decided
description: The deploy is real filenames plus a symlink farm — chezmoi is retired once the in-flight tmux/zen work lands
read_when: "touching install.sh, the home/ tree's file names, or asking why nothing needs an apply after an edit"
---

# the-deploy-is-symlinks

## Decision

The repo's files keep their real names (`home/.config/nushell/…`, plain
`cockpit` with the exec bit git already tracks), and a small install script
symlinks `home/` into `$HOME`. Chezmoi leaves the Brewfile when this lands.
Editing any dotfile is instantly live — there is no apply step and no
`rr`-equivalent: the symlink IS the deployment.

## Why

- An audit on 2026-09-29 found chezmoi doing almost nothing for this tree:
  filename mangling (`dot_`, `executable_`) on hundreds of files, ONE real
  template (gitconfig's two prompted strings — the identity is in the git
  history anyway), ONE run_onchange using `include | sha256sum` as a change
  detector, five plain bash run_after scripts, and an append-only
  `.chezmoiremove` ledger for deletions.
- Secrets were never chezmoi's job here: the Keychain is read at runtime
  (env.nu's TypeSafe key, capsule.nu's credentials), so no dynamic values
  are filled at apply time at all.
- A dangling-symlink sweep in the install script replaces `.chezmoiremove`
  (a retired source file's symlink is removed by the next link run), a
  hash-compare replaces the tmux reload detector, and `git pull` plus a
  post-merge relink replaces `chezmoi update`.

## Consequences

- One trade, accepted: a tool that rewrites a config in place (e.g.
  `gh auth setup-git` editing `~/.gitconfig`) now writes THROUGH the
  symlink into the repo — the tree goes visibly dirty instead of the live
  copy silently diverging. That is a feature: the change is reviewable and
  committable.
- The one-time migration replaces every deployed copy with a symlink and
  must check for drift first (live files newer than their source).
- TIMING: the migration waits for the in-flight tmux/zen session to land —
  a mass rename under its ~8 dirty open files would break that work. Until
  then chezmoi stays the deployer; nothing in this memo depends on new
  machinery landing first.
- install.sh's order contract (every tool on PATH before the apply) becomes
  the install script's order: PATH, brew, link, then the former run_afters.