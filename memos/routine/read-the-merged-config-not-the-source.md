---
atomic: read-the-merged-config-not-the-source
subject: the source file said nothing about which side the panel opens; only the plugin's own merged table and the real pane geometry could say, and they disagreed with the manual
date: 2026-09-02
updated: 2026-09-02
runs: 3
tags:
  - atomic
---

## Do

1. Deploy the configuration, then start the real program so it loads it — not
   a staged copy, not a sandbox.
2. Fire the command a person would press, through the command path they would
   use.
3. Read the value back out of the program's own merged state
   (`require("<plugin>").state.config`, the plugin's `get_config()`), and read
   the observable result independently — pane geometry, key table, window
   layout.
4. Compare the two. The source file's value is a request; the merged table is
   what runs.

## Done when

- The measured value and the observable result agree with each other, and any
  disagreement with the source file is written down as the finding.

## Fails when

- The probe quits the program as its last act, and the window or pane
  layout is torn down before it can be listed. A single full-size pane then
  reads as "the split never happened", which is the opposite of the truth.
  Polling does not save you — teardown beats the tick. Drop the quit from
  the probe body and kill the whole server after measuring, or hold the
  program open on a timer; read the merged table and the layout from the
  *same* live process.
