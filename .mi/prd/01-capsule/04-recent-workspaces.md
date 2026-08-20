# Feature: Recent-workspace picker

Parent: [Capsule epic](00-epic.md) · C 5 · U 7 · source: "Recent-workspace picker"

## Summary

Fast re-entry into previously used workspaces: a picker over the last mounted
directories, opened from the terminal, landing either in the current pane or a
new tab.

## Requirements

1. **Recording.** Every successful capsule mount appends the directory to a
   recency list (`.cache/recent`), deduplicated, capped at 20, most recent
   first. Written by the lifecycle tool, not by the terminal layer.
2. **Picker.** `Ctrl+Shift+S` opens a fuzzy-selectable list and mounts the
   choice in the current pane; `Ctrl+Shift+T` mounts it in a new tab.
3. **Feedback.** While the picker is active, the status area indicates
   "Recent:" mode so a stray keypress isn't mistaken for the normal prompt.
4. **Hygiene.** Directories that no longer exist are skipped or pruned on
   read; the list survives terminal restarts.

## Acceptance criteria

- Mount three directories, restart WezTerm, press `Ctrl+Shift+S`: all three
  appear, newest first; selecting one attaches to its capsule.
- A deleted directory no longer appears after the next picker open.
