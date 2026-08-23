# spec01 — Close the fork in `01-capsule/02-dev-image` and seal its toolbox

est: 0.5h

## Goal

The fork is settled. `.mi/prds/01-capsule/02-dev-image/prd.md` still ends in
an `## Open questions` section asking it, which is the exact shape this
decision node exists to destroy: an open question on an `afk` node is an
invitation for the next agent to pick the recommendation and close a human's
fork on its behalf. Replace the question with the answer, dated and
attributed, and make the requirement list structurally unable to take the
dropped toolchain back.

This node's own acceptance names this file as the record destination
("the file this node names as its spec"), and `01-capsule/02-dev-image` is
the only node whose `deps` list `00-delivery/decisions/odin-toolchain`, so it
is also the whole of "every node listed as gated on this decision".

**Verified before speccing:** `grep -rniE "odin|oilrig" .mi/` finds the
toolchain named in exactly four live places — this PRD's `## Open questions`,
`.mi/prds/README.md`'s tree caption, `.mi/SYSTEM.md`'s Known gaps, and
`.mi/docs/capabilities.md` line 95 (the inventory entry the image is built
from). The last three are spec02's and are deliberately not touched here.
`03-editor/10-treesitter` R2 also installs an `odin` parser — that is the
**host** editor and is unrelated to the container image; leave it alone.

## Files touched

- `.mi/prds/01-capsule/02-dev-image/prd.md` — body only. **Do not edit the
  frontmatter block**; the orchestrator owns `state`, `deps` and `verify`,
  and the `deps` entry on this decision node stays until the orchestrator
  clears it.

Nothing else. In particular do not touch `.mi/prds/README.md`,
`.mi/SYSTEM.md`, `.mi/prds/01-capsule/prd.md` (spec02 owns all three) or
`.mi/docs/capabilities.md` (owned by `w0-4-s2-corrections/docs-inventories`,
whose R1 forbids editing it before the author confirms).

## What to write

### 1. Delete `## Open questions` entirely

The whole section, heading and bullet. A question that has been answered is
not documentation, it is a trap.

### 2. Add a `## Decisions` section at the end of the file

Matching the convention already used by
`00-delivery/corrections/w0-6-live-bugs/prd.md` — a `## Decisions` section
holding `**Decided <date> (<who>):**`. Write it as:

> ## Decisions
>
> **Decided 2026-08-21 (user): the Odin compiler built from source, and the
> `pi` agent with its ~20 pi-oilrig extensions, are dropped from the
> consolidated image.** Recorded from
> [`00-delivery/decisions/odin-toolchain`](../../00-delivery/decisions/odin-toolchain/prd.md),
> which is where the fork was put to the human. This matches the
> recommendation this PRD carried while the question was open.
>
> Why: they dominate cold build time and serve a minority of projects, so
> every capsule would pay a toolchain cost few of them use — against the
> epic's goal that cold start is dominated by docker itself and not by what
> we chose to bake in.
>
> The capability is **relocated, not lost**. A project that needs Odin or
> `pi` adds it per-project, in its own image built `FROM` this base; the
> base image and the capsule CLI install neither and know nothing about it.
> Layering per-project is outside the capsule tool's scope by design — see
> the epic's [Out of scope](../prd.md).

Keep the wrap at ~78 columns.

### 3. Add `R7`, the closed-toolbox requirement

The existing R2 (`ripgrep, fd, fzf, tmux, neovim, bat, eza, git,
build-essential, Python`) and R4 (`Claude Code and OpenCode`) already omit
the dropped toolchain, so **there is nothing to delete from them** — the risk
is not that it is there, it is that a later editor adds it back to a list
that never said it was closed. Make the list closed:

- [ ] **R7** — **Closed toolbox.** R2, R3 and R4 are exhaustive: the image
      installs nothing they do not name. Adding a language toolchain or a
      second agent to the base is an edit to those lines with a reason, never
      a quiet extra layer — one such toolchain was already dropped, see
      `## Decisions`.

Phrase R7 without naming Odin or `pi`. The `## Requirements` section is the
image's *positive* contract; the exclusion lives in `## Out of scope` and
`## Decisions`, and the verify command enforces that separation.

### 4. Add the exclusion to `## Out of scope`

Keep the existing bullet, append:

- The Odin compiler built from source, and the `pi` agent with its
  pi-oilrig extensions. Dropped 2026-08-21 — see `## Decisions` for the
  reason and for where the capability went instead.

Do not mark any box `[x]` or `[~]`. Nothing here is implemented; R7 is a
requirement of the future image, not a claim about today.

## Acceptance

- [x] `.mi/prds/01-capsule/02-dev-image/prd.md` has no `## Open questions`
      heading.
- [x] It has a `## Decisions` section containing the literal
      `Decided 2026-08-21 (user)`, naming both `Odin` and `oilrig`, recording
      the `per-project` escape hatch, and linking
      `decisions/odin-toolchain`.
- [x] No line under `## Requirements` mentions `Odin`, `oilrig`, or `pi` as a
      standalone word — the toolbox list states what is in, not what is out.
- [x] A requirement numbered `R7` exists and makes R2–R4 exhaustive.
- [x] `## Out of scope` names `Odin`.
- [x] R1–R6 keep their numbers and text; the requirement count does not drop.
      Other documents cite requirements by number.
- [x] Every box in the file is still open (`- [ ]`) — no `[x]`, no `[~]`.
- [ ] The frontmatter block is byte-identical to before the edit:
      `shasum -a 256` of the leading `---` fence of
      `prds/01-capsule/02-dev-image/prd.md`, equal before and after, both
      quoted. The original clause was dead twice over — its pathspec was
      `.mi/prds/01-capsule/02-dev-image/prd.md`, a path removed with the `.mi`
      tree, and the live file is untracked (`git ls-files --error-unmatch`, 2026-08-23) so a diff over
      it is silent anyway. Unprovable in retrospect: the pre-edit state was
      untracked, so git never held a copy and no `cp` aside was kept. What
      would have proved it: that fence hash, taken before the first write.
- [x] `.mi/docs/capabilities.md` is untouched by this spec — it is owned by
      `w0-4-s2-corrections/docs-inventories`, whose R1 blocks edits until the
      author confirms.

verify: ""

Proven RED against the current tree before being written here: it reports
`## Open questions still open`, `no ## Decisions section`, the five missing
`## Decisions` strings, `Out of scope does not exclude Odin`, and
`no closed-toolbox requirement`, exiting 1.

## Spent proof

`prds/01-capsule/02-dev-image/prd.md` has since been implemented and its
boxes closed; the guard was written to catch a box closing during this
node's own run.

Retired from `verify:` by
[`mi-rooted-verify-commands`](../../../corrections/mi-rooted-verify-commands/prd.md)
spec02. The command below is byte-identical to what spec01 left in this
file's `verify:`; it is kept because it is the execution record of a check
that once ran green.

```text
verify: `bash -c 'cd "$(git rev-parse --show-toplevel)"; f=prds/01-capsule/02-dev-image/prd.md; rc=0; D() { awk "/^## Decisions/{d=1;next} /^## /{d=0} d" "$f"; }; grep -q "^## Open questions" "$f" && { echo "FAIL: ## Open questions still open"; rc=1; }; grep -q "^## Decisions" "$f" || { echo "FAIL: no ## Decisions section"; rc=1; }; for s in "Decided 2026-08-21 (user)" "Odin" "oilrig" "per-project" "decisions/odin-toolchain"; do D | grep -qF "$s" || { echo "FAIL: ## Decisions lacks: $s"; rc=1; }; done; awk "/^## Requirements/{r=1;next} /^## /{r=0} r" "$f" | grep -nE "Odin|odin|oilrig|(^|[^A-Za-z])pi([^A-Za-z]|$)" && { echo "FAIL: dropped toolchain named in Requirements"; rc=1; }; awk "/^## Out of scope/{o=1;next} /^## /{o=0} o" "$f" | grep -q "Odin" || { echo "FAIL: Out of scope does not exclude Odin"; rc=1; }; awk "/^## Requirements/{r=1;next} /^## /{r=0} r" "$f" | grep -q "R7" || { echo "FAIL: no closed-toolbox requirement"; rc=1; }; grep -qE "^- \[[x~]\]" "$f" && { echo "FAIL: a box was closed"; rc=1; }; [ $rc -eq 0 ] && echo OK; exit $rc'`
```
