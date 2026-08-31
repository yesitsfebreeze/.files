# spec03 — Restore the truncated source list; point R4 at the answer

est: 0.3h

## Goal

Two small repairs to the header and one requirement, both about the record
rather than the design.

### The `Parent:` line is truncated mid-list

It reads, in the current tree:

> `Parent: [Capsule epic](../prd.md) · C 9 · U 9 · sources: "Capsule" (CONSOLIDATE, C9 U9 — dominant),`

— ending on a comma, because the flat-prose → node conversion (`8ecbbe4`)
dropped the continuation line. The pre-conversion file
(`git show 8ecbbe4^:.mi/prd/01-capsule/01-container-lifecycle.md`) is
unambiguous:

> `sources: "Capsule" (CONSOLIDATE, C9 U9 — dominant),`
> `"`mount` — drop the current dir into a container", "Just task runner"`

So two of the three merged sources are missing. This matters beyond tidiness:
`AGENTS.md` requires that "a PRD that merges several entries carries the
dominant entry's rating **and lists every source with its own numbers**", and
the two lost sources are precisely the two that finding C-3 declares broken
(spec02). A reader who wants to check what was merged, and what the audit
said about each, currently cannot get from this file to either entry.

The numbers come from `.mi/docs/capabilities.md`, read this session:

| source entry | C | U |
|---|---|---|
| `"Capsule" — per-directory Docker dev containers from the terminal` (CONSOLIDATE, dominant) | 9 | 9 |
| `` `mount` — drop the current dir into a container `` | 3 | 7 |
| `Just task runner` | 3 | 6 |

The dominant 9/9 already matches the header's `C 9 · U 9`, so no rating
changes — this restores what was lost and adds the per-source numbers the
contract asks for. Finding M-10 (`U 8–9`, a range) is already fixed in this
file; the verify keeps a guard so it cannot come back.

### R4 does not point at the answer to its own collision

This ticket's **R2**. `decisions/wallpaper-opacity` landed a `## Decisions`
section in this file today: `Ctrl+Shift+B` is capsule's, the C-1 collision is
**dissolved not resolved** (the incumbent wallpaper pipeline is dropped
`DO NOT PORT`), and no rekey should be invented. R4 still reads:

> **R4** — **Forced rebuild.** An explicit flag (`capsule --rebuild`, bound
> to `Ctrl+Shift+B` in the terminal) that rebuilds the image and recreates
> the container.

The requirement and the decision are eleven boxes apart with no link between
them. Anyone who reads R4, then reads C-1's instruction to "pick new
bindings", has no signal from R4 that the question was already put to the
human and closed — and inventing a replacement key is the one outcome the
decision explicitly forbids, because the port exists to keep the muscle
memory. A pointer is cheap; a rekey costs the thing being ported.

Nothing about the decision is re-opened here, and `Ctrl+Shift+T` stays open
exactly as the `## Decisions` section leaves it.

## Files touched

- `.mi/prds/01-capsule/01-container-lifecycle/prd.md` — the `Parent:` line
  and the R4 bullet. **Do not edit the frontmatter block**, and do not touch
  the `## Decisions` section: it is another node's record, landed today.
- `.mi/prds/00-delivery/corrections/w0-4-s2-corrections/capsule/prd.md` —
  close the R2 box (body only, **not** the frontmatter).

Nothing else. Note in particular that `.mi/prds/01-capsule/02-dev-image/prd.md`
has the **same** truncation from the same commit (`· sources: "Standalone
dev`, cut mid-quote) and is **not** repaired here — it is not in this
ticket's footprint. It is reported upward instead.

## What to write

### 1. Replace the `Parent:` line

Wrapped at ~78 columns; the continuation lines are part of the same logical
line, which is how `03-credential-propagation` already wraps its `source:`.

> Parent: [Capsule epic](../prd.md) · C 9 · U 9 · sources: "Capsule"
> (CONSOLIDATE, C 9 / U 9 — dominant), "`mount` — drop the current dir into
> a container" (C 3 / U 7), "Just task runner" (C 3 / U 6)

No trailing comma. Three sources, three ratings, dominant marked.

### 2. Extend R4 with a pointer

Keep the number, keep `Ctrl+Shift+B`, add the reference:

> - [ ] **R4** — **Forced rebuild.** An explicit flag (`capsule --rebuild`,
>       bound to `Ctrl+Shift+B` in the terminal) that rebuilds the image and
>       recreates the container. The key is settled and needs no rekey
>       despite finding C-1 — see `## Decisions` below before changing it.

Do not restate the decision's reasoning in R4; it lives in `## Decisions` in
this same file, and duplicating it is what the tree's cross-link-don't-
duplicate rule forbids.

Do not mark any box in the PRD `[x]` or `[~]`.

## Acceptance

- [ ] The `Parent:` line names all three sources: `Capsule`, `mount`,
      `Just task runner`.
- [ ] It gives `mount` `C 3 / U 7` and `Just task runner` `C 3 / U 6`, each
      as single numbers.
- [ ] It does not end on a comma.
- [ ] The header carries no C/U range (regression guard for M-10).
- [ ] R4 still names `Ctrl+Shift+B` and now references `## Decisions` (or the
      `wallpaper-opacity` node) as the place the key was settled.
- [ ] The `## Decisions` section is byte-identical — this spec does not
      reword another node's record.
- [ ] Every box in `01-container-lifecycle/prd.md` is still open — no `[x]`,
      no `[~]`.
- [ ] No line inside the leading `---` fence changed. Reviewer check, not in
      the verify: the file carries uncommitted orchestrator frontmatter edits
      already, so a `git diff` clause would false-fail on someone else's
      change.

verify: ""

**Proven RED against the current tree before this spec was written**, run
verbatim as the string above: six FAILs — both lost sources, both missing
ratings, the trailing comma, and R4's missing pointer — exiting 1. The M-10
range guard, the `Ctrl+Shift+B` guard and the box-state guard pass today and
are regressions guards.

The `Parent:` line is read as an awk range from `^Parent:` to `^Purpose:`,
then whitespace-normalised, so the assertions survive the wrap that the
restored line will need — grepping the single line `^Parent:` would fail on
correct output, which is the same 78-column trap that produced a false
negative earlier today.

## Spent proof

`prds/01-capsule/01-container-lifecycle/prd.md` now holds twelve closed
boxes because the capsule lanes implemented it after this node closed; the
guard was written to catch a box closing during this node's own run.

Retired from `verify:` by
[`mi-rooted-verify-commands`](../../../mi-rooted-verify-commands/prd.md)
spec02. The command below is byte-identical to what spec01 left in this
file's `verify:`; it is kept because it is the execution record of a check
that once ran green.

```text
verify: `bash -c 'cd "$(git rev-parse --show-toplevel)"; f=prds/01-capsule/01-container-lifecycle/prd.md; rc=0; P=$(awk "/^Parent:/{p=1} p&&/^Purpose:/{p=0} p" "$f" | tr "\n" " " | tr -s " "); R4=$(awk "/\*\*R4\*\*/{r=1} r&&/^- \[.\] \*\*R[0-9]/&&!/R4/{r=0} r&&/^## /{r=0} r" "$f" | tr "\n" " " | tr -s " "); printf "%s" "$P" | grep -qF "mount" || { echo "FAIL: Parent line lost the mount source"; rc=1; }; printf "%s" "$P" | grep -qF "Just task runner" || { echo "FAIL: Parent line lost the Just task runner source"; rc=1; }; printf "%s" "$P" | grep -qE "C ?3 ?[/ ]+ ?U ?7" || { echo "FAIL: the mount source carries no C 3 / U 7"; rc=1; }; printf "%s" "$P" | grep -qE "C ?3 ?[/ ]+ ?U ?6" || { echo "FAIL: the Just task runner source carries no C 3 / U 6"; rc=1; }; printf "%s" "$P" | grep -qE ",[[:space:]]*$" && { echo "FAIL: the Parent line still ends mid-list on a comma"; rc=1; }; printf "%s" "$P" | grep -qE "U [0-9]+[-–][0-9]" && { echo "FAIL: a C/U range is back in the header (M-10)"; rc=1; }; printf "%s" "$R4" | grep -qE "Decisions|wallpaper-opacity" || { echo "FAIL: R4 does not point at the recorded Ctrl+Shift+B answer"; rc=1; }; printf "%s" "$R4" | grep -qF "Ctrl+Shift+B" || { echo "FAIL: R4 no longer names Ctrl+Shift+B"; rc=1; }; grep -qE "^- \[[x~]\]" "$f" && { echo "FAIL: a box in the PRD was closed"; rc=1; }; [ $rc -eq 0 ] && echo OK; exit $rc'`
```
