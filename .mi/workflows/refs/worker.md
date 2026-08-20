# PRD worker

Read [`AGENTS.md`](../../../AGENTS.md) first. [`laws.md`](laws.md) is assumed by
every move below — it holds the reasons, this file holds only what is specific
to this board.

The board is the tree of `<node>/prd.md` files under `.mi/prd/`. The path is
the id and the parent link. Pick one ready node, claim it, work it, close it
honestly, take the next. One node at a time, same four moves at every level.

[`plugins/board/plugin.lua`](../../../src/plugins/board/plugin.lua) reads the
tree and offers `board.list` / `board.next` (pinned by `just lua-check`). Its
claims are local ([.mi/docs/memos/prd.md](../../docs/memos/prd.md)), so the
commit in §3 is still the only lock another session can see.

> **It computes §2. This block used to say it did not, and that was true when
> written and false by the time it was read** (re-corrected 2026-08-19,
> cc-1787162540, read out of `M.claimable` and `board.next`). The 2026-08-17
> correction (cc-1786992421) recorded five divergences from §2 and placed the
> gap on `p6f-lua-plugins`; `p6f` closed it (`cc-1786998805`, "§2 chosen over
> narrowing the claim") and `plugin.lua` now annotates each one at the line
> that fixed it — `divergence 1` `afk`, `2` escalation, `3` every-child-covered,
> `4` reopened, `5` the depth tie-break, now `>` where it was `<`. `board.next`
> dispatches straight into `M.claimable`, so it will not hand you a `hitl`
> node, an escalated node, or a node whose children are still open.
>
> **Still verify what it hands you against §2 rather than trusting it**, for
> the reason this block itself demonstrates twice: the plugin's claims are
> local ([.mi/docs/memos/prd.md](../../docs/memos/prd.md)), and a reader that
> restates a rule it does not run goes stale silently and reads as
> authoritative the entire time it is wrong. §2 below is the rule; the plugin
> is one implementation of it and the gate that pins it is `just lua-check`.

## The shelf

| Before | Read |
|---|---|
| a node under `.mi/prd/p6-rust-core/` | its memo in [`.mi/docs/memos/`](../../docs/memos/README.md) — the memo is the spec, the node is only where work against it is claimed. Work that contradicts its memo is a wall (move 3), not a fork |
| any non-trivial change | [`discipline.md`](../../docs/memos/discipline.md) — the memo lands in the same commit as the code; landing a port flips its status cell in the README table in that commit |
| the loop, while you are still writing | `just fast` — fmt, clippy and tests for the crates you changed and everything that depends on them, computed from the dependency graph. It **falls open**: a change it cannot place in a crate runs the whole gate instead. It can tell you "not yet"; it can never tell you "done" |
| any close | the gate — `just check` (Rust, includes the conformance replays) · `just lua-check` (Lua) · `just all` (both: mandatory for a shared format or a `conformance/` contract). There is no `just record`; a recording that must change is hand-edited in the same commit, with the reason |
| a port | [`RUST-CORE.md`](../../docs/RUST-CORE.md) (landed, order) · [`SURFACES.md`](../../docs/SURFACES.md) · [`LUA-PLUGINS.md`](../../docs/LUA-PLUGINS.md), which decides the language — a node never re-decides it |
| porting an extension | `/Users/feb/dev/_pi_extensions/integrated.md` |

## 0. Session id

`cc-<unix-timestamp>` (`date +%s`), computed once, used in every `claim:` field
and lock commit message.

## 1. Read the tree

```
find .mi/prd -name prd.md | sort
```

A node is a directory holding `prd.md`; a child is a subdirectory holding its
own. Anything else in the tree is that node's private material: opaque.

| field | meaning |
|---|---|
| `state` | `open` \| `claimed` \| `done` \| `out-of-scope` |
| `mode` | `afk` \| `hitl` — hitl needs the human (naming, taste, money) |
| `priority` | higher runs first (default 0) |
| `deps` | node paths that must be **resolved** before this one is ready; a list, `[]` when none |
| `claim` | the single active owner; absent means unclaimed |
| `verify` | command that proves this node's own requirements |
| `est` | working days, advisory |
| `max-workers` | root only, the concurrency cap |

Title = the first non-empty body line, `#` stripped. A header line that does
not parse is a **broken tree**: stop, name the file and line, fix that line
without changing node intent.

**Boxes are the only evidence, and the scheduler reads them.**

```
- [ ]  not met
- [~]  met against a STUB, fixture or in-process fake standing in for the
       real dependency — real code landed, the requirement did not
- [x]  met against the real thing, and you ran the check that proves it
```

`[ ]` and `[~]` both count OPEN. Counted under **any** heading — scoping the
scan to one heading is what lets an acceptance clause close unmet. A node
**owes** `unchecked + stubbed + (1 if it has an ## Escalation)`.

- **resolved** — `out-of-scope`, or `done` **and owes nothing**
- **reopened** — `done` with open boxes and no escalation: back on the queue
- **covered** — the node **and its whole subtree** resolved

## 2. Pick the node

**ready** = (`open` ∨ reopened) ∧ unclaimed ∧ `afk` ∧ no `## Escalation` ∧
**every child covered** ∧ **every `deps` entry resolved**. Order: `priority`
desc, then **depth desc** (finish a branch before fanning wider), then path.
Take the first.

> **`deps` added 2026-08-20**, escalated out of a board repair and cleared by
> the user. The predicate had no dependency term, so ordering fell through to
> path — and path order inverts real dependencies: in `01-capsule`,
> `01-container-lifecycle` depends on `02-dev-image`, so path order built the
> container before its image. `priority` is not a substitute: it orders
> *selection among ready nodes*, it does not gate readiness, so a downstream
> node stayed claimable while its dependency was still open.
>
> Two consequences. **`deps` is by node path, and resolved means §1 resolved**
> (`out-of-scope`, or `done` owing nothing) — not merely `done`, or a
> reopened dependency would count. **`plugin.lua` no longer computes §2**: it
> predates this term, so `M.claimable` and `board.next` will hand out nodes
> with unresolved `deps`. Until it is fixed and `just lua-check` pins it, §2
> is computed by hand — which is the divergence the block above warns about,
> now recorded at the line that caused it rather than discovered later.

Never take a **claimed** node (surface a stale claim, never steal it), a
**hitl** node (ask the user, write the answer into the body, then it closes
like anything else), or an **escalated** node (only a conductor or the user
clears one). Nothing takeable → stop and report the state of the tree.

## 3. Claim it — the git commit IS the lock

Rewrite that one node's frontmatter (`state: claimed`, add `claim: <session>`,
keep the fences and field order) and commit that one file, nothing else:

```
git add .mi/prd/<path>/prd.md
git commit -m "claim <path>: <session>" -- .mi/prd/<path>/prd.md
git push        # only if the branch has an upstream
```

With a remote the push decides the race. Rejected → `git pull --rebase`, push
again; a conflict **on your node file** means someone claimed first:
`git rebase --abort`, `git reset --hard @{upstream}`, re-read, take the next.
If the commit itself refuses, restore the file byte-for-byte and say so.

## 4. The four moves — the whole protocol, at every level

**1. WORK the node.** Implement its open boxes. A requirement too soft to
verify gets sharpened into this node first (move 2) — vagueness left in the
line ends up in the code. Requirements say WHAT; the how is yours, except that
observable interfaces named in the node (paths, flags, formats) are
requirements.

Before marking `[x]`, answer in one line: **what did I run, and what would it
have done if the requirement were unmet?** Real dependency not there yet → the
box stays `[~]`, name the stub beside it. `[~]` is not a lesser failure; it is
the honest record that a stub is load-bearing.

**2. AMEND only your own node.** Sharpening a requirement, recording a
decision, noting evidence — free. **Narrowing scope is not yours**: that is
move 3. Interfaces change only at the node that owns them.

**3. ESCALATE a wall.** A requirement is wrong, or your node's contract with
the system must change → write `## Escalation` into your own node (what you
hit, what change you need, why), release the claim (§6), surface it, stop. The
section takes the node off the work surface until someone folds it in and
deletes it.

**4. SPLIT a subsection and YIELD.** A coherent sub-area with its own contract
→ create a child (Appendix A), write its one-line contract into your own body,
give it `state: open`, **do not work it**, release your node. Your node is not
ready again until its children are covered; spawning while holding your slot
deadlocks the pool.

## 5. Orchestrate — subagents and ultracode

- **Explore with subagents** — reference implementations, tree sweeps, call
  sites. Keep the conclusions, not the file dumps; this is also what keeps you
  under the context gate.
- **Ultracode the implementation** — the default for real node work: parallel
  explorers → implementation → a verifier prompted to **refute** every box you
  intend to mark `[x]`, given the box text and the check you ran. A box
  survives refutation or stays open. Verification is in addition to running the
  proving check yourself, never instead of it.
- **Only the claim holder writes the tree.** Claims, box edits, amendments,
  escalations and every commit stay in the main session. Subagents read the
  tree freely and never write to `.mi/prd/`.

## 6. Close it — or release it, honestly

**DONE** — every box `[x]`, and if the node has `verify:`, **you ran it**; its
output is the evidence. Set `state: done`, delete the `claim:` line, commit
together with the work it verifies and with the memo where the subject lives:

```
git commit -m "close <path>: <session>" -- <the work> .mi/prd/<path>/prd.md
```

**Boxes still open?** Not done. Leave `state: open` and the honest boxes, drop
the `claim:` line, commit what landed (`release <path>: <session>`), report
which box is open and why. Splits and escalations release the same way; you
resume when the children land or the escalation is folded in.

Never leave a claim behind — closing and abandoning both clear the owner.

## 7. Loop — with the context gate

Re-read the tree from disk (other sessions move it), recompute ready, take the
next. One node closing does not end the loop.

**At ~65% of the context window, stop claiming.** Check before every new claim
and at natural pauses. At or past it: take nothing new, finish the current node
only if clearly within reach, else release it honestly and stop. A clean
release at 65% is resumable; a degraded close at 95% is corruption.

Stop when nothing is dispatchable or the gate fires, and report an artifact,
not a transcript: nodes closed with what you ran to prove each `[x]` · nodes
released with the open box and why · escalations written, children split ·
anything left hitl, escalated or claimed elsewhere · files touched, verify
output, box-by-box status, and a few lines of what changed and why.

---

## Appendix A — the node format

```markdown
---
state: open          # open | claimed | done | out-of-scope
mode: afk            # afk | hitl (needs the human: naming, taste, money)
priority: 0          # optional, higher runs first
deps: []             # node paths that gate readiness; [] when none
verify: <command>    # optional, proves this node's own requirements
---

# <Title>

Purpose: one paragraph — what this area is FOR.

## Requirements
- [ ] one verifiable behavior per line — WHAT it must do, not how

## Acceptance
- [ ] the end-to-end condition that makes this node true, as a box —
      prose here is invisible to the loop and closes unmet

## Out of scope
- explicit; this is the line that stops drift
```

## Appendix B — a new request arriving mid-run

Placed, not appended. Start at the root, pick exactly one:

1. **DESCEND** — a child's area owns it: repeat there. Two children owning
   different parts is two requests.
2. **ADD IN PLACE** — no child owns it, this node covers the area, and it is
   one more verifiable behavior: append one `- [ ]` line to `## Requirements`,
   set `state: open` if the node was done, commit that one file.
3. **SPLIT** — a coherent sub-area with its own contract: create a child
   (Appendix A), write its one-line contract into THIS node's body, leave this
   node open, commit both files. Do not work it.
4. **CONFLICT** — it contradicts this node's `## Out of scope`: quote the line
   that says no and stop. The reversal is the user's call.

Amend only the node you are at, create only its children. A node claimed by a
running worker is not yours to rewrite under them — report the placement and
let it be folded in when the claim clears.

## Appendix C — grilling, when requirements are soft

Open questions form a tree like the work does. Ask the **frontier** — every
question whose prerequisites are settled — as ONE numbered round, each with
your recommended answer, then wait. Questions depending on open ones belong to
a later round; recompute and ask again until the frontier is empty. No user in
the loop → answer your own frontier and record the assumptions under
`## Assumptions` in the node body.
