---
atomic: apply-scoped-not-bare
subject: the working tree held unrelated pending changes; a bare `chezmoi apply` would have deployed them alongside
date: 2026-09-02
updated: 2026-09-02
runs: 5
---

## Do

1. `chezmoi diff` first, and read what else is pending.
2. `chezmoi apply <each target path>` — name the files, do not run it bare.
3. For a retirement, name the target paths that should DISAPPEAR, not the
   source file that lists them. Deleting a file from `home/` deploys
   nothing on its own: chezmoi stops managing the path and leaves the
   deployed copy where it is. The deletion reaches the machine only once the
   target path is listed in `home/.chezmoiremove` AND that target path is
   named to `apply` — `chezmoi apply ~/.config/television/cable/alias.toml`,
   one path per name, five names for five files. Applying `.chezmoiremove`
   itself, or the directory above the targets, does neither.

## Done when

- `chezmoi diff <those paths>` prints nothing, and everything else that was
  pending is still pending.
- Every path you retired is gone from the target, and every file you did not
  name in that directory is still there. `ls` the directory and count it —
  an apply that removed nothing exits 0 just as happily as one that worked.

## Fails when

- `chezmoi diff` renders `home/run_after_*.sh` run-scripts as new files at
  `$HOME` root, which reads as three scripts about to be written into the home
  directory. They are scripts chezmoi EXECUTES, not files it deploys.
  Alarming, not a defect — do not scope around them in a panic.
- A retirement applies correctly and the tool's own count does not move,
  which reads as "the apply did nothing". Some names are baked into the
  binary rather than read from a file: measured 2026-09-02, retiring five
  television channels left `tv list-channels` at `27` where `25` was
  predicted, because `env` and `git-branch` are `tv` 0.15.9 built-in channel
  names and outlive the files. Count the directory, which you own, before
  you read the tool's list, which you do not.
- You find a tracked source file deleted in the working tree that no
  requirement names, and restore it as a stray. `chezmoi` then refuses with
  `inconsistent state (<source path>, remove)`: the path is already in
  `.chezmoiremove` and the deletion is the other half of a retirement an
  earlier node left unfinished. Finish it — do not put the source file back.
