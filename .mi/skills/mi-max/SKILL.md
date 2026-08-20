---
name: mi-max
description: Set and store the maximum number of concurrent mi workers for this repo, by writing max-workers on the board root node. Use for "/mi-max 5", "set max workers", "how many agents can run", "limit concurrency", "raise the cap", or when a run reports the cap is the reason it took nothing.
---

# mi-max — the concurrency cap, stored where it is read

The cap has **one home**: the `max-workers` field on the board root node,
`.mi/prd/prd.md`. `mi-run` reads it as the *global* cap across every running
session, and `mi-gantt` reads it to size each wave. Storing it anywhere else
would be a second copy that can disagree with the first, so there is no config
file and no environment variable for this.

Absent that field, the default is **3** — enough that a wave of independent
files actually overlaps, few enough that a bad plan costs three worktrees
rather than twelve.

## Reading it

```
grep -n 'max-workers' .mi/prd/prd.md
find .mi/prd -name prd.md -exec grep -l 'claim:' {} +   # what is live right now
```

Report the stored value, how many claims are live against it, and the default
if the field is absent — say "unset, so 3 applies", never just "3".

## Setting it to N

1. **Check the argument.** An integer ≥ 1. Anything else: say what is wrong and
   stop.
2. **Read the root node** and find its frontmatter block. If there is no board
   in node form, stop and say so — there is nowhere to put this, and
   `/mi-repair` is what creates the board.
3. **Count live claims first.** If N is *below* the number of claims already
   out, say so before writing: lowering the cap does not stop work that is
   already running, and it does not release anything. The next session to look
   will simply find no free slot. Write it anyway if the user confirms.
4. **Edit only the `max-workers` line** — add it if absent, keeping the fences
   and every other field byte-for-byte. `max-workers` is a root-only field; on
   any other node it means nothing and is a bug.
5. **Commit that one file:**
   `git commit -m "max-workers: <N>" -- .mi/prd/prd.md`
6. **Report** the old value, the new value, live claims, and free slots.

## Choosing N, if asked

Independent files are what makes concurrency real, so the cap that pays is
bounded by the plan, not by the machine:

- **1** — serial. Correct when nearly every task writes the same file, or while
  debugging a workflow.
- **3** (default) — the honest general answer. A wave usually has three
  genuinely disjoint pieces in it.
- **higher** — only when the plan shows a wave that wide *and* the footprints
  are disjoint. Check the wave layout in `.mi/gantt/plan.md` before raising it;
  a cap above the widest wave buys nothing and just enlarges the blast radius
  of a bad plan.

Raising the cap does not make a serial plan parallel. If waves are narrow
because everything collides on one file, the fix is splitting that work into
separate files — a planning change, not a cap change. Say that rather than
raising the number.

## Out of scope

Releasing or stealing a claim (a lock is surfaced when stale, never taken —
clearing one is the user's call) · setting `max-workers` on a non-root node ·
capping a single session's lanes, which is `args.lanes` on the run itself and
not a stored value.
