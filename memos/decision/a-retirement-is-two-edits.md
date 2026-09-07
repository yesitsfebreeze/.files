---
kind: decision
date: 2026-09-02
status: decided
description: retiring a file from this configuration is two edits — the source file goes and its deployed target path is listed in home/.chezmoiremove — and the retirement is proven at the target path, never at the source or by an apply's exit code
read_when: "deleting anything from home/"
---

# a-retirement-is-two-edits

## Decision

A file leaves this configuration in **two edits, in the same change**:

1. the source file is deleted from `home/`, and
2. its destination-relative target path is appended to `home/.chezmoiremove`
   — one path per line, relative to `$HOME`, no `dot_` prefix and no leading
   `./`.

The retirement is then deployed by naming the **target** paths to
`chezmoi apply` — `chezmoi apply ~/.config/television/cable/alias.toml`, one
name per retired file. Applying `.chezmoiremove` itself, or the directory
above the targets, deploys nothing.

It is proven at the deployed path and nowhere else:

```sh
test ! -e ~/.config/<name>
grep -qxF '<target>' home/.chezmoiremove
```

The apply's own exit code is not the proof. Where the retirement is intended
and the target may have drifted, `chezmoi apply --force <target>`.

## Why

`chezmoi apply` only writes and updates; it never reaps an orphan. Deleting a
source file makes the deletion true of the repo and false of every machine the
file was already deployed to — chezmoi simply stops managing the path and
leaves the copy where it is. Measured in this repo on 2026-09-02: four source
files deleted, a scoped apply run, all four targets still present under
`~/.config`.

The second edit is the part the repo carries. Fixing it by hand — `rm
~/.config/…` — retires the file on the machine in front of you and on no
other; the next machine still holding the old deploy never hears about it. The
`.chezmoiremove` line travels with the commit, so the retirement holds
wherever the configuration lands.

The proof has to sit at the target because the removal is state-dependent and
can fail silently where it is byte-identical to what chezmoi last wrote and
chezmoi's state still knows the entry.

## Consequences

- A scoped apply with the target names is the deployment gesture, not a bare
  `chezmoi apply`.
- The `.chezmoiremove` list grows forever — it is the record of what this
  configuration stopped managing, and it is checked, never pruned.
- Anything a run_after script wrote outside a managed path is not covered by
  this memo and needs its own retirement edit.