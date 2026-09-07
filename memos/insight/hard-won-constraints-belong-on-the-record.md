---
kind: insight
description: a non-obvious constraint with a measurement behind it belongs in memos — the manual is the source, memos are the surface a cold agent lands on
read_when: "writing any rule into a config file, or deciding whether the rule needs a memo or just a code comment"
---

# hard-won-constraints-belong-on-the-record

A constraint that took a measurement to discover belongs in the memos, not
inside the file it defends. The `internals/*.md` pages already carry the
measurement, but a cold agent opens the memo index first, not the manual —
and the index names one claim per row, not a prose page.

The pattern across what got written: each memo starts with "this works on
nushell 0.114.1 / tmux 3.7c / wezterm 20240203-110809-5046fc22", states the
shape of the trap (the third clause of why the file is shaped the way it
is), and ends with the next thing to re-measure when the pinned version
moves. The prose is already in the manual; the memo is the *claim* the prose
is the proof of.

A constraint whose evidence is a comment in a config file ages with the
file: a comment is rewritten or removed when the behaviour it defends
against no longer bites, and a reader who never hit the trap cannot tell
which comments are decorative and which carry a day of measurement.
Carrying the claim in a memo and a one-line `TRAP` reference in the code
keeps the evidence alive without depending on the comment surviving.