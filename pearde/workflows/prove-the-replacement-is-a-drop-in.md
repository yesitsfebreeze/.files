---
atomic: prove-the-replacement-is-a-drop-in
subject: brew's tinty was installed beside the release copy and asked for the same scheme, the same 538 entries and the same hook write BEFORE anything was deleted
date: 2026-09-02
updated: 2026-09-02
runs: 0
tags:
  - atomic
---

## Do

1. Install the replacement alongside the incumbent — do not remove anything yet.
2. Address the new one by its absolute path and ask it the questions the
   incumbent answers in daily use: its version, the state it reads, the
   artefact it writes. Here: `/opt/homebrew/bin/tinty current`,
   `… list | wc -l`, and one `tinty apply` watched against
   `~/.config/tmux/colors.conf`'s mtime.
3. Restore any state the probe moved.

## Done when

- The replacement reports the same live state as the incumbent, and its side
  effect lands in the same file.
- The machine is left in the state it started in.

## Fails when
