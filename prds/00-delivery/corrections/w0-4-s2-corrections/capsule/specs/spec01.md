# spec01 — Name the cleanup invocations in R6

est: 0.4h

## Goal

`06-help/01-content-model` (H.1) closed on 2026-08-21 and left a finding
aimed straight at this file. Quoting the record in
`home/dot_config/nushell/help/use-review.nuon`:

> `01-capsule/01-container-lifecycle` R6 names two cleanup modes and neither
> invocation, so `capsule clean`'s gesture cannot be written down honestly
> until it is corrected.

R6 today reads, in whole:

> **R6** — **Cleanup.** A subcommand to list capsules and remove stopped/all
> ones (absorbs the old `dk` force-remove alias for capsule containers).

"stopped/all" is two modes with no way to ask for either. The consequence is
not hypothetical: `capsule.nuon`'s `capsule clean` entry ships today saying
"Which of the two a bare `capsule clean` does, and what you pass to get the
other, is not settled" — a manual entry that documents a gap instead of a
gesture, because the specification left it one. Its reviewer note is explicit
that inventing `--all` in the manual would be "the same false record pointing
the other way". The invocation has to be named here, in the PRD, and then the
manual can describe it.

Two names are already in the record and are adopted rather than invented:
`capsule list` and `capsule clean` are the `cmd` ids of two entries in
`home/dot_config/nushell/help/capsule.nuon`, both sourced to this PRD. H.1's
reader flagged them as the manual's invention *because the PRD was silent*;
blessing them makes the two documents agree without changing any shipped
text. The one genuinely new token is the all-mode flag, specced below as
`--all`.

This is not a fork for the human. The modes were chosen when R6 was written;
what is missing is their spelling, the default, and the blast radius — all
three of which the tool's own safety depends on, and none of which the user
was ever asked about.

## Files touched

- `.mi/prds/01-capsule/01-container-lifecycle/prd.md` — the R6 bullet only.
  **Do not edit the frontmatter block.**
- `.mi/prds/00-delivery/corrections/w0-4-s2-corrections/capsule/prd.md` —
  close the R3 box (body only, **not** the frontmatter).

Nothing else. In particular:

- **`home/dot_config/nushell/help/capsule.nuon` is not touched here.** Its
  `capsule clean` entry becomes stale the moment R6 lands, and the digest in
  `use-review.nuon` keys on the `use`/`source` pair — so re-writing that
  entry is `06-help` work with a re-read attached, not a side effect of a
  PRD correction. It is reported upward instead.
- `.mi/prds/01-capsule/prd.md`, `02-dev-image`, `04-recent-workspaces` — not
  this ticket's footprint at any point.

## What to write

Replace the R6 bullet with a longer one that keeps the number, keeps the `dk`
provenance, and names all three invocations. Wrap at ~78 columns, and keep
the box open (`- [ ]`) — nothing here is implemented.

> - [ ] **R6** — **Cleanup.** Two subcommands over the same set.
>       `capsule list` prints every capsule this tool owns — one row per
>       container, with its name, the directory it was made from, and
>       whether it is running or stopped. `capsule clean` removes the
>       **stopped** ones; a bare invocation never kills a running container,
>       because the cheap mistake has to be the safe one. `capsule clean
>       --all` additionally stops and removes the running ones. Both only
>       ever touch containers this tool created (the `capsule-` name prefix
>       of R1) — never any other container on the host, which is what the
>       old `dk` force-remove alias could not promise.

Three things that must survive rewording:

1. **The default is stopped-only.** A bare `capsule clean` that could kill
   the container you are sitting in is a tool people stop trusting after
   exactly one incident.
2. **`--all` is stated as "additionally"**, not as a different set: it is
   stopped-plus-running, so `clean --all` is never *less* than `clean`.
3. **The scope bound is a `never`, not a nicety.** R1 already defines the
   `capsule-<dirname>` naming; R6 leans on it so the safe set is derivable
   rather than a matter of implementation taste.

`capsule list`'s output columns are specified because H.1's reader found the
opposite problem there too: the manual asserts "whether each is running or
stopped" and nothing in the PRD backs it. After this edit, it does.

Then close **R3** on this ticket's own `prd.md` (the `- [ ]` box added by the
analyst that names this correction), marking it `- [x]` with the check that
was run.

## Acceptance

- [ ] R6 names `capsule list`, `capsule clean` and `capsule clean --all`,
      each in backticks.
- [ ] R6 states what a bare `capsule clean` does (the word `bare`, `by
      default`, `default mode` or `on its own` appears in it).
- [ ] R6 distinguishes running from stopped capsules.
- [ ] R6 bounds both subcommands to containers this tool created, as an
      `only`/`never`.
- [ ] R6 still carries the `dk` provenance — the sentence exists to record
      which legacy capability was absorbed.
- [ ] R6 is still numbered R6 and no other requirement is renumbered;
      R1–R5 and R7 keep their text.
- [ ] Every box in `01-container-lifecycle/prd.md` is still open — no `[x]`,
      no `[~]`. A PRD requirement is not met by being written.
- [ ] No line inside the leading `---` fence of
      `01-container-lifecycle/prd.md` is added, removed or changed by this
      spec. Reviewer check, deliberately not in the verify: the file already
      carries uncommitted frontmatter edits from the orchestrator
      (`priority`/`est`/`task` added, `deps` reflowed), so a `git diff` clause
      would false-fail on someone else's change.
- [ ] `home/dot_config/nushell/help/capsule.nuon` is untouched by this spec.

verify: ""

**Proven RED against the current tree before this spec was written**, and run
verbatim as the string above. It reports all six of: R6 does not name
`capsule list`, `capsule clean`, `capsule clean --all`; does not say what a
bare invocation does; does not bound clean to capsule-owned containers; does
not distinguish running from stopped — exiting 1. The `dk` and box-state
clauses pass today and are regression guards, which is why they are in the
list.

The command strings are matched **without** their surrounding backticks. A
`grep` pattern containing a backtick inside a `bash -c` script is a command
substitution, not a literal — the first draft of this verify printed
`bash: capsule: command not found` three times and then passed those three
clauses on empty strings. Backtick formatting is house style; the check tests
the names.

Note the check reads a whitespace-normalised R6 (`tr "\n" " " | tr -s " "`)
rather than grepping lines. Prose here wraps at 78 columns, so any phrase
long enough to be worth asserting will straddle a line break; a naive
line-wise grep produced a false negative earlier today.

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
verify: `bash -c 'cd "$(git rev-parse --show-toplevel)"; f=prds/01-capsule/01-container-lifecycle/prd.md; rc=0; R6=$(awk "/\*\*R6\*\*/{r=1} r&&/^- \[.\] \*\*R[0-9]/&&!/R6/{r=0} r&&/^## /{r=0} r" "$f" | tr "\n" " " | tr -s " "); for s in "capsule list" "capsule clean" "capsule clean --all"; do printf "%s" "$R6" | grep -qF -- "$s" || { echo "FAIL: R6 does not name: $s"; rc=1; }; done; printf "%s" "$R6" | grep -qE "bare|by default|default mode|on its own" || { echo "FAIL: R6 does not say what a bare invocation does"; rc=1; }; printf "%s" "$R6" | grep -qE "(only|never)[^.]{0,90}(capsule|it created)" || { echo "FAIL: R6 does not bound clean to capsule-owned containers"; rc=1; }; printf "%s" "$R6" | grep -qE "running" || { echo "FAIL: R6 does not distinguish running from stopped"; rc=1; }; printf "%s" "$R6" | grep -qF "dk" || { echo "FAIL: R6 dropped the dk provenance"; rc=1; }; grep -qE "^- \[[x~]\]" "$f" && { echo "FAIL: a box in the PRD was closed"; rc=1; }; [ $rc -eq 0 ] && echo OK; exit $rc'`
```
