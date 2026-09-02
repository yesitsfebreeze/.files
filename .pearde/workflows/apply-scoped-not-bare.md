---
atomic: apply-scoped-not-bare
subject: the working tree held unrelated pending changes; a bare `chezmoi apply` would have deployed them alongside
date: 2026-09-02
updated: 2026-09-02
runs: 3
---

## Do

1. `chezmoi diff` first, and read what else is pending.
2. `chezmoi apply <each target path>` — name the files, do not run it bare.

## Done when

- `chezmoi diff <those paths>` prints nothing, and everything else that was
  pending is still pending.

## Fails when

- `chezmoi diff` renders `home/run_after_*.sh` run-scripts as new files at
  `$HOME` root, which reads as three scripts about to be written into the home
  directory. They are scripts chezmoi EXECUTES, not files it deploys.
  Alarming, not a defect — do not scope around them in a panic.
