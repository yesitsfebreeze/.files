---
kind: knowledge
description: rm.always_trash makes every rm a trash move, including the ones in scripts — `-p` on any path the user did not type
read_when: "writing a script that deletes files, or wondering where a deleted probe went"
---

# always-trash-changes-what-rm-means

`$env.config.rm.always_trash` is on, so a bare interactive `rm` moves the path
to the macOS Trash — the safety net for a mistyped argument, and the reason
nothing reaches for a `trash` wrapper.

It applies to **every** `rm` the shell runs, including the ones inside sourced
scripts, and that is the trap: the manual's drift check used to `mktemp` six
probe files per run and delete them one at a time — under `always_trash` each
delete was a trash move, so the sound played repeatedly and the probes piled
into `~/.Trash`. Reported 2026-09-01 as "a check that always makes sounds".

Two rules came out of that, and they outlive the check that surfaced them:

- **`-p` on any `rm` of a path the user did not type.** `capsule.nu`'s
  credential drop is the remaining caller, and it wants `-p` twice over — a
  trashed secret sits readable in `~/.Trash`.
- **A probe is not garbage, so stop treating cleanup as a step.** Write a
  run's scratch files into one fixed directory under `$nu.temp-dir` and empty
  it when the run *starts*, rather than deleting each file as you go. Nothing
  accumulates (the next run clears it); nothing is deleted mid-run, so a
  failed run leaves its evidence on disk under a name that says what it is
  instead of a `mktemp` string already unlinked by the time the error prints.