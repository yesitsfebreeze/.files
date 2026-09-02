---
state: open
origin: derived
priority: 22
complexity: 0
blast-radius:
repo:
time:
  est:
  actual:
needs:
  - 09-simplify/06-neovim-television
footprint:
  - home/dot_config/television/cable
  - home/.chezmoiremove
---

# retire the unmanaged television channels

Thirteen channel files live in `$HOME/.config/television/cable` that no PRD and
no source in this repo owns: `bg`, `burrito-sessions`, `git-deletions`,
`git-diff`, `git-reflog`, `git-remotes`, `git-repos`, `git-stash`,
`git-submodules`, `git-tags`, `git-worktrees`, `opacity`, `opencode-sessions`.
Established 2026-09-02 by the skeptic called on
`09-simplify/06-neovim-television`, and measured after that node's `9b80a71`:
the live directory holds 23 files, the chezmoi source holds 10.

**Consequence for a requested PRD, and where this box came from.**
`09-simplify/06-neovim-television` R1 caps the television surface. Its box
carried three clauses; two — an isolated-fixture count of 16 channels over 10
cable files, and `ls home/dot_config/television/cable | wc -l` at most 15 — are
green and stay there. The third is the acceptance box below, transferred here
whole on 2026-09-02.

It was transferred only after the in-footprint work that could have moved it
had landed and been measured. Before `9b80a71`, 06 could still move the machine
number and had not, which is why the skeptic ruled it stayed. `9b80a71`
appended five lines to `home/.chezmoiremove` and applied by naming the five
target paths; the machine went `28 → 23` files and `tv list-channels` `30 → 27`
(only three names left the list — `env` and `git-branch` are baked-in `tv`
0.15.9 channel names that outlive their files). What remains is `23 - 10 = 13`
files 06's footprint has never reached. The second reason it belongs here: once
they are gone, the machine count and the isolated-fixture count measure the same
ten files and the same 16, so the clause was never a check on 06.

**What exists when this is done.** The live cable directory and the chezmoi
source agree. Decide per file which way it goes: wanted means adopting it into
`home/dot_config/television/cable` so the repo owns it; unwanted means removing
it from the machine, which in this repo means `home/.chezmoiremove` plus a
`chezmoi apply` naming the target paths — not a bare `rm`, and not applying
`.chezmoiremove` itself. See `.pearde/workflows/apply-scoped-not-bare.md`.

**What must not change.** The ten channels the repo owns after `9b80a71`, and
06's own five retirements. This node adjudicates only files the source has
never carried.

**A premise to test before speccing, not to assume.** It is tempting to say
`.chezmoiremove` only speaks for paths this repo once managed, which would mean
these thirteen cannot be removed that way at all and would shape the whole node
around a constraint. The skeptic disputes it and points at the disproof already
on this board: `03-help-system/probe/verify.sh:108-117` plants a canary at
`manual.toml` and watches chezmoi take it away, and at that moment the file has
no source entry — the same condition the thirteen are in. chezmoi's state is the
source tree plus `.chezmoiremove`; it keeps no memory of "once managed". Settle
it with one canary at a genuinely never-managed path before writing any spec.

## Acceptance

- [ ] `ls ~/.config/television/cable | wc -l` is at most 15.
      **Transferred from `09-simplify/06-neovim-television`'s R1 box on
      2026-09-02, after `9b80a71`** — see above for why it moved and the rule
      that governs such a move. Measured at transfer: `23` files on the
      machine against `10` in the source, and `tv list-channels` at `27`.
      The threshold is 15 and was not tuned; 06 left it red rather than raise
      it to `23`.

## Questions

- **Q1 — Each of the thirteen unmanaged television channels: adopt it into the
  repo, or delete it from the machine?** They are not the same kind of thing —
  `git-*` channels look like a coherent set someone installed on purpose,
  `opencode-sessions` and `burrito-sessions` name tools this repo may or may not
  still carry, and `bg` and `opacity` look like one-offs. The node cannot be
  specced until this is settled, because "retire" and "adopt" produce opposite
  work. Answer it per file, or per group, or as one rule for all thirteen.

## Answers

## Asked
