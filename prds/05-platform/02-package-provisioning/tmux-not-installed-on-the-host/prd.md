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

**Corrected 2026-08-29, and the correction matters because the original
wording is what this node's `hitl` was priced against.** This paragraph said
adding the row was "the first irreversible step" of installing a multiplexer
on the host. **That is wrong, measured:** `PKGS` is consumed at exactly
`install.sh:291` and `:298`, inside the script's own package step. Adding a
row installs nothing — it is a declaration a script reads when somebody
deliberately runs it, and `just cutover` has not run. The Linux lists
(`APT_PKGS`, `PACMAN_PKGS`, `DNF_PKGS` at :116–:118) are separate strings, so
a complete declaration is more than one line but no less inert. Found by
dotfiles-06 and verified here rather than taken on report.

**What actually holds this node is narrower, and it is not blast radius.** It
is that the board should not extend a direction its own user has not confirmed
to the session doing the extending. The direction reverses two invariants: `02-terminal` **I1** ("there is no second
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

**Corroboration on file, 2026-08-29, and why it is not sufficient here.**
Session `dotfiles-06` reports putting the direction to the user as a
three-answer fork and receiving *"Yes, I settled those 14"* — the epic's
fourteen-answer drill and the I1/I2 reversal, confirmed. It also established
the gap that made the question necessary: `prds/.transitions.jsonl` shows
`07-multiplexer` going straight to `open` at 08:50:56 with **no `question`
transition ever recorded**, so the board never parked on the user and the
`## Answers` block alone cannot distinguish a session that asked from one that
did not. That is good evidence and it is recorded here so whoever closes R1
inherits it. It is not this session's to act on: a peer relaying a user's
answer is not the user's answer to the session making the edit, and that is a
rule about who may license a change, not about how large the change is. One
word from the user in a session that can see it closes R1 — or `dotfiles-06`
makes the change itself on the direction confirmed to it, which is the same
outcome with the licence in the right place.

## Requirements
- [x] **R1** — Establish, before any edit, that the tmux direction is settled
      **by the user** and not only by a memo. Quote where. If it is not, stop
      and report; that is a correct outcome for this node.
      **Closed 2026-08-29 by session `dotfiles-06`, which held the licence
      first-hand.** It put the direction to the user through the
      ask-user-question mechanism as a three-answer fork — the epic's
      fourteen-answer drill and the I1/I2 reversal, against "a session wrote
      those answers without asking me" and "show me the memo first". The user
      chose *"Yes, I settled those 14"*. That is the user's own answer in the
      session that asked, not a relay, which is what this requirement was
      written to demand. The `.transitions.jsonl` gap recorded above is what
      made asking necessary and stands as part of the evidence.
- [x] **R2** — Add tmux to `install.sh`'s `PKGS` in the same guarded shape as
      every other entry, so a second run is a no-op. Name the binary as well
      as the formula if they differ.
      `install.sh:104` — `tmux=tmux`, formula and binary identical, in the
      "required by a scheduled node" group with the reason and the inertness
      recorded beside it. The guarded shape is inherited, not re-implemented:
      the straggler loop at `:303` is `have "${p##*=}" && continue`.
- [x] **R3** — Extend `tests/provisioning.sh`'s packages assertions to cover
      it, and prove the check by its own red: deleting the name from `PKGS`
      must fail the gate. The gate already does this per-name — follow that
      shape rather than inventing one.
      Two assertions added in the gate's own idiom: `packages: it carries
      tmux=tmux` beside the existing `gnupg=gpg` / `git-delta=delta` pair, and
      `packages/linux: apt carries tmux` on the Linux ladder. `PROV_BINS` also
      gained `tmux` — its own header says the list "has to grow whenever PKGS
      does", and without it the have-guard at `:303` would emit a per-package
      install line on a provisioned machine and redden `shape`/`prov`.
- [x] **R4** — Say what happens on a host that already has tmux from
      elsewhere, and on Linux, since `install.sh` runs on both.
      **Already present:** nothing runs. The batch at `:297` is one
      `brew install` over every name, which brew no-ops on an installed
      formula; the straggler loop at `:303` is `have tmux && continue`, so a
      host that got tmux from anywhere — MacPorts, a manual build, Nix — is
      skipped by binary presence rather than by package-manager bookkeeping.
      This is exercised, not asserted: the `packages/prov` stage runs with
      every `PROV_BINS` name resolvable, which now includes tmux, and is green.
      **On Linux:** the three distro strings at `:121`–`:123` each gained
      `tmux`, which is the correct name in apt, pacman and dnf alike, so no
      binary-rename shim of the `batcat`/`fdfind` kind is needed. Only the apt
      arm is asserted, because only the apt arm has a fixture.

## Acceptance
- [x] `grep -n tmux install.sh` matches, and `bash tests/provisioning.sh` is
      green with the count quoted before and after.
      `grep -n tmux install.sh` → lines 100, 104, 121, 122, 123.
      **Before** (a clean worktree at `d63f145`, carrying none of this change):
      **115 assertions, 0 FAIL**. **After** (working tree): **117 assertions,
      0 FAIL** — the two this node added. Both counts measured by running the
      gate, not derived from the diff; the first reading taken for this box
      was discarded because the worktree it ran in sat at `eea3102` rather
      than HEAD.
- [x] The counterfactual: with the name removed, the gate goes red — quoted.
      Three, on scratch copies, so the predicates are proven to discriminate
      rather than merely to pass:
      **CF1** drop the `tmux=tmux` row → `grep -qF 'tmux=tmux'` finds nothing
      (red); matches on the real file (green).
      **CF2** drop `tmux` from `APT_PKGS` → the apt pattern does not match
      (red); matches on the real file (green).
      **CF3** the substring trap — `DRY sudo apt-get install -y neovim
      libtmux eza` does **not** satisfy the apt check, so a name merely
      *ending* in `tmux` cannot green it.
      CF3 exists because the first draft of that assertion was written in BRE
      against a `grep -qE` matcher and was red for a reason that had nothing
      to do with the code. A check that fails for the wrong reason is one
      edit away from passing for the wrong reason.
- [x] R1's evidence is quoted in this node, or this node reports blocked.
      Quoted under R1 above.

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
