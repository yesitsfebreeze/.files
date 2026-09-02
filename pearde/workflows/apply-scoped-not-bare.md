---
atomic: apply-scoped-not-bare
subject: the working tree held unrelated pending changes; a bare `chezmoi apply` would have deployed them alongside
date: 2026-09-02
updated: 2026-09-02
runs: 9
---

## Do

0. `chezmoi source-path` first, and compare it to `git rev-parse
   --show-toplevel`. If they differ you are in a worktree the deploy tool does
   not read, and **no apply from here reaches the machine**. Do not reach for
   `--source <this worktree>/home` to force it: the rest of that tree is the
   branch point, so the apply would deploy every *other* file at its stale
   version and erase whatever another lane has pending on the machine. Deploy
   from the source root after the merge, and prove the post-state now by
   applying into a throwaway `--destination` instead.
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
  which reads as "the apply did nothing". Some names are compiled into the
  binary rather than read from a file, and a file whose name matches one of
  them *shadows* it rather than adding a row. Measured 2026-09-02 against a
  fixture holding an empty `television/cable` and nothing else, `tv` 0.15.9
  compiles in **ten**: `bash-history`, `dirs`, `docker-images`, `env`,
  `files`, `git-branch`, `git-diff`, `git-log`, `git-repos`, `text`. So
  `len(tv list-channels) = 10 + files - shared`, where `shared` is how many
  of the ten the cable directory also supplies, and the gap between the list
  and the directory is `10 - shared` — **not a constant**. It moves the
  moment an adopted or retired name collides with a built-in, which is
  exactly the situation this atomic is warning about. Today's arithmetic:
  19 files sharing six names (`dirs`, `files`, `git-diff`, `git-log`,
  `git-repos`, `text`) gives `10 + 19 - 6 = 23`, and the same formula
  reproduces the 27 measured at 23 files. Count the directory, which you
  own, before you read the tool's list, which you do not. (An earlier
  measurement in this atomic named `env` and `git-branch` alone — two where
  there are ten — and a later one named four, the four that 19-file
  directory happened not to shadow. Both read a shadowing effect as a fixed
  offset and turn a correct apply into an apparent failure.)
- You find a tracked source file deleted in the working tree that no
  requirement names, and restore it as a stray. `chezmoi` then refuses with
  `inconsistent state (<source path>, remove)`: the path is already in
  `.chezmoiremove` and the deletion is the other half of a retirement an
  earlier node left unfinished. Finish it — do not put the source file back.
