---
state: open
priority: 8
est:
mode: hitl
needs:
verify: ""
origin: derived
from: 07-multiplexer/01-session-and-windows
claim:
complexity: 0
blast-radius:
---

# tmux is a host dependency of `07-multiplexer` and is in no host package list

Parent: [Package provisioning](../prd.md) · net-new

Purpose: [`07-multiplexer`](../../../07-multiplexer/prd.md) treats tmux as a
hard dependency of the host shell. **`install.sh` never installs it.**
Measured 2026-08-29: `grep -n tmux install.sh` matches nothing. tmux appears
in this repo only at `home/dot_config/capsule/Dockerfile` and in
`tests/dev-image.sh`, `tests/shell-help.sh` and `tests/help-agent.sh` — that
is the apt toolbox **inside the capsule container**, which is a different
machine from the one the epic wants a multiplexer on.

Surfaced by `07-multiplexer/01-session-and-windows`'s analyst (session
dotfiles-06) and handed across the footprint split: the epic is theirs,
`install.sh` is this node's.

**`tmux-main`'s fallback arm makes the absence survivable, not correct.** A
host that silently degrades is exactly the shape
[`packages-installer`](../packages-installer/prd.md) R8 exists to avoid, and
the epic's own gates cannot be honest about a dependency the provisioning
layer does not provide.

## Blocked on a decision that is not this node's, and not the board's

**Do not add `tmux=tmux` to `PKGS` on the strength of this node alone.**
Installing a multiplexer on the host is the first irreversible step of a
change that reverses two invariants: `02-terminal` **I1** ("there is no second
multiplexer") is withdrawn and **I2** loses its second clause, per
[`tmux-owns-multiplexing-wezterm-keeps-the-chrome`](../../../memos/tmux-owns-multiplexing-wezterm-keeps-the-chrome.md).
That memo is `status: decided`, but it was written by a board session on
2026-08-29 and **this node has seen no evidence the user sanctioned the
direction** — only that a session recorded it. Adding the package would make
the board's provisioning layer assert the decision before the person whose
daily driver it is has been asked.

So this node is filed to make the gap visible and to hold the argument, not to
close it. It implements when either the user confirms the tmux direction, or
`07-multiplexer` reaches a state where its dependency is unambiguous.

## Requirements
- [ ] **R1** — Establish, before any edit, that the tmux direction is settled
      **by the user** and not only by a memo. Quote where. If it is not, stop
      and report; that is a correct outcome for this node.
- [ ] **R2** — Add tmux to `install.sh`'s `PKGS` in the same guarded shape as
      every other entry, so a second run is a no-op. Name the binary as well
      as the formula if they differ.
- [ ] **R3** — Extend `tests/provisioning.sh`'s packages assertions to cover
      it, and prove the check by its own red: deleting the name from `PKGS`
      must fail the gate. The gate already does this per-name — follow that
      shape rather than inventing one.
- [ ] **R4** — Say what happens on a host that already has tmux from
      elsewhere, and on Linux, since `install.sh` runs on both.

## Acceptance
- [ ] `grep -n tmux install.sh` matches, and `bash tests/provisioning.sh` is
      green with the count quoted before and after.
- [ ] The counterfactual: with the name removed, the gate goes red — quoted.
- [ ] R1's evidence is quoted in this node, or this node reports blocked.

## Out of scope
- Anything in `07-multiplexer`, which is another session's half of the tree.
- Configuring tmux. This node installs a binary; the config is that epic's.

<!-- Three more headings exist, and none of them is a slot to copy down. Each
     is a claim about the state of this PRD, so an empty copy of it is a false
     one: an empty `## Questions` stops the board on nothing, an empty
     `## Answers` reads as answered, an empty `## Failure` reads as a failed
     attempt. Write the heading when it has content; until then it is absent,
     which is the honest state. @resources/questions.py reports the empty
     ones, and `doctor`'s `questions` row runs it. -->

<!-- `## Questions` — analyst-only, when blocked on the user: one round in the
     format of drill.md — `### Q1: <title>`, the fork in 1-3 sentences ending
     in "?", then exactly three prepared answers, each a complete decision,
     one `(recommended)`. Only real forks the user must settle (naming, scope,
     cost) — never facts a worker could look up, never the PRD restated. A PRD
     parked on the user with no such round never says what it is asking. -->

<!-- `## Answers` — orchestrator-only (or the view), written after asking the
     user: `**Q1** — <the picked answer verbatim, or the user's own words>`,
     numbers matching the round above it. Analysts read these before speccing.
     An `## Answers` with no `## Questions` above it answers nothing. -->

<!-- `## Failure` — implementer-only, after a FAILED attempt: what broke, what
     was tried. `retry` moves this into the body as history and reopens the
     PRD. -->
