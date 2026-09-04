---
state: done
origin: derived
from: 09-simplify/06-neovim-television
priority: 22
complexity: 11
blast-radius: mid
repo:
time:
  est:
  actual: 0.61h
needs:
  - 09-simplify/06-neovim-television
footprint:
  - home/dot_config/television/cable
  - home/.chezmoiremove
workflow: land-an-answered-fork
commit: bb86993
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

**The premise, settled from the record — do not re-derive it.** It is
tempting to say `.chezmoiremove` only speaks for paths this repo once managed,
which would mean these thirteen cannot be removed that way at all and would
shape the whole node around a constraint that is not there. The skeptic
disputed it, and the knowledge record settles it:
`[[260902-7c3a]]` — *".chezmoiremove removes a deployed orphan, but only while
chezmoi still recognises the file it wrote"*, measured 2026-09-02 during
`09-simplify/04-nushell` pass two, with `[[260902-f203]]` behind it. Note it is
on `~/dev/infra/pearde`'s board, not this one — see the memo on misrouted
knowledge.

What it establishes, and it is neither of the two positions above:

- `.chezmoiremove` **does** reach a file chezmoi has no state entry for — it is
  not limited to once-managed paths.
- But that is the *loud* shape. When the target is byte-identical to what
  chezmoi last wrote and the entry is still known, a scoped apply removes it
  silently at exit 0. When the target differs, **or chezmoi has forgotten the
  entry — which is exactly the condition all thirteen are in** — chezmoi asks
  `<path> has changed since chezmoi last wrote it?`, and in a session with no
  controlling terminal that is not a skip: it is `could not open a new TTY` and
  **exit 1 for the whole apply**.
- `--force` answers the prompt and removes the file. The scoped form does
  process removals; naming paths rather than running bare does not skip them.

So the mechanism works, and the spec must (a) apply `--force` where the
retirement is intended, and (b) assert each target's absence directly rather
than reading the apply's exit code — the same conclusion `04-nushell` reached
and wrote into its verify block. A canary at a never-managed path is still the
cheapest confirmation before the first spec, but it is now a check on a known
answer rather than an open question.

## Acceptance

- [x] `ls ~/.config/television/cable | wc -l` is exactly 19, and
      `ls home/dot_config/television/cable | wc -l` is the same 19 — the two
      sides list one set of names, which is asserted directly rather than
      inferred from two equal counts:
      `bash -c 'cd /Users/feb/dev/dotfiles && diff <(ls ~/.config/television/cable | sort) <(ls home/dot_config/television/cable | sort) && test "$(ls home/dot_config/television/cable | wc -l | tr -d " ")" = 19'`
      → `rc=0`.
      **The `diff` half was added 2026-09-02 on the skeptic's finding**, after
      the box was first written with the two counts alone: two nineteens with
      disjoint names pass a pair of `wc -l`s and fail the sentence the box
      actually makes. The count stays as corroboration; the `diff` is the
      assertion. Needs `bash -c` — process substitution, and this machine's
      shell is nushell.
      **Transferred from `09-simplify/06-neovim-television`'s R1 box on
      2026-09-02, after `9b80a71`** — see above for why it moved and the rule
      that governs such a move. The count is `10 + 9 = 19`: the ten channels
      the repo owned after `9b80a71`, plus the nine `git-*` channels Q1's
      answer adopts. Q1 is what sets this number — "keep the git ones, drop
      the rest" makes a smaller machine count unreachable, so the threshold
      it replaces was resettled by the answer, not tuned. It is exact, not a
      ceiling: a directory of 18 or of 20 fails it, because the contract asks
      that the machine and the source agree rather than that either stay
      small. The four Q1 drops — `bg`, `burrito-sessions`, `opacity`,
      `opencode-sessions` — leave through `home/.chezmoiremove`, and
      `tv list-channels` reads higher than the file count because some names
      are built into `tv` 0.15.9 rather than read from `cable`.

## Questions

### Q1: What to do with thirteen search lists nobody put here on purpose

Your search picker offers ten lists this repo owns and thirteen it has never
known about: nine search corners of git, two list sessions for other assistant
tools, two are one-offs for background images and transparency. Nobody
recorded them. Do they become part of the configuration you keep, or go away?

1. **Keep the git ones, drop the rest** — the nine git lists join the repo; the other four leave this machine. (recommended)
2. **Remove all thirteen** — the picker offers only what this repo puts there, and anything missed can be added back deliberately later.
3. **Keep all thirteen** — every one joins the repo as it stands, and a fresh machine gets the full set.

<!-- for the board: the thirteen are bg, burrito-sessions, git-deletions,
git-diff, git-reflog, git-remotes, git-repos, git-stash, git-submodules,
git-tags, git-worktrees, opacity, opencode-sessions. Answer 1 splits them
9 / 4: every `git-*` name is adopted (nine, not the seven the first draft of
this fork miscounted — git-deletions and git-submodules were omitted from that
list and are git lists too), and bg, opacity, burrito-sessions and
opencode-sessions are removed. "Adopt" means the file moves into
home/dot_config/television/cable so chezmoi owns it; "remove" means
home/.chezmoiremove plus a scoped `chezmoi apply --force` naming the target
paths, asserting each target's absence rather than reading the exit code — see
the settled premise above and .pearde/workflows/apply-scoped-not-bare.md.
Nine adopted takes the source from 10 to 19 cable files and the machine to 19,
so the transferred box's threshold of "at most 15" cannot be met by adoption:
it is the count the answer resettles, not a number to tune silently. Raise it
with the arithmetic written down, or measure the box against what the source
owns. -->

## Answers

**Q1** *(answered 2026-09-02 16:23)* — Keep the git ones, drop the rest — the seven git searches join the repo properly and travel to any new machine; the session lists and the two one-offs are removed from this machine.

## Report

spec01-reconcile-the-cable-directory: exit 0
ok   bg.toml gone
ok   burrito-sessions.toml gone
ok   opacity.toml gone
ok   opencode-sessions.toml gone
ok   bg.toml tombstoned
ok   burrito-sessions.toml tombstoned
ok   opacity.toml tombstoned
ok   opencode-sessions.toml tombstoned
ok   git-deletions.toml adopted and deployed
ok   git-diff.toml adopted and deployed
ok   git-reflog.toml adopted and deployed
ok   git-remotes.toml adopted and deployed
ok   git-repos.toml adopted and deployed
ok   git-stash.toml adopted and deployed
ok   git-submodules.toml adopted and deployed
ok   git-tags.toml adopted and deployed
ok   git-worktrees.toml adopted and deployed
ok   machine and source list the same files
ok   machine count is 19
ok   source count is 19
ok   06's dirs.toml intact
ok   06's docs.toml intact
ok   06's files.toml intact
ok   06's git-log.toml intact
ok   06's nu-history.toml intact
ok   06's quicklist.toml intact
ok   06's recent-dirs.toml intact
ok   06's recent-files.toml intact
ok   06's text.toml intact
ok   06's theme.toml intact
ok   earlier retirements still retired

verify rc=0
ok   bg.toml gone
ok   burrito-sessions.toml gone
ok   opacity.toml gone
ok   opencode-sessions.toml gone
ok   bg.toml tombstoned
ok   burrito-sessions.toml tombstoned
ok   opacity.toml tombstoned
ok   opencode-sessions.toml tombstoned
ok   git-deletions.toml adopted and deployed
ok   git-diff.toml adopted and deployed
ok   git-reflog.toml adopted and deployed
ok   git-remotes.toml adopted and deployed
ok   git-repos.toml adopted and deployed
ok   git-stash.toml adopted and deployed
ok   git-submodules.toml adopted and deployed
ok   git-tags.toml adopted and deployed
ok   git-worktrees.toml adopted and deployed
ok   machine and source list the same files
ok   machine count is 19
ok   source count is 19
ok   06's dirs.toml intact
ok   06's docs.toml intact
ok   06's files.toml intact
ok   06's git-log.toml intact
ok   06's nu-history.toml intact
ok   06's quicklist.toml intact
ok   06's recent-dirs.toml intact
ok   06's recent-files.toml intact
ok   06's text.toml intact
ok   06's theme.toml intact
ok   earlier retirements still retired

verify rc=0

spec02-resettle-the-transferred-count: exit 0
ok
