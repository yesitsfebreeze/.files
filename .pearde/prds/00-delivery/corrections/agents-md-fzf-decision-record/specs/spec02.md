---
complexity: 6
footprint:
  - prds/00-delivery/corrections/agents-md-fzf-decision-record/prd.md
---

# spec02 — Record the verdict on where the edit went, and the carrier census

R1 and R5 are both *report* requirements: they close by writing a finding into
this PRD's own body, not by changing any other file. R1 asks why spec04's
`AGENTS.md` edit is absent — the PRD offers three candidates (lost in the mi
retirement, overwritten by a later writer, never landed) and says none is
provable from git. R5 asks whether other `done` nodes fail their `verify:` on
`AGENTS.md` content for the same reason, which makes it a census.

Run this **after spec01 lands**, so the exit codes recorded for the carriers
are the post-fix ones and the record is coherent with the file on disk.

Write both findings into `prd.md` as new body sections, below `## Out of
scope`. Touch no frontmatter key — not `state`, not `verify`, not `footprint`;
the orchestrator owns those.

## R1 — what to establish, and the evidence that decides it

The question is decidable, and by two independent lines. Run both and quote
them; do not take this spec's word for either.

1. **Documentary — the spec was dropped, not lost.**
   `decisions/fzf/prd.md`'s `## Partial landing — 2026-08-21` says in as many
   words: *"**`spec04` is dropped and reassigned**, not outstanding.
   `decisions/tinty` owns `.mi/SYSTEM.md`'s Known-gaps
   bullet and deletes it outright."* That reassignment covers **one** of
   spec04's three edits. `decisions/tinty/specs/spec03.md` then fences itself
   off from the other two: *"Do not add anything to `## Scope decisions
   already made` beyond the correction described below"*, and it justifies
   deleting the Known-gaps bullet on the grounds that *"the burrito and fzf
   answers are recorded where they belong"* — an assumption that was false
   when written, because the only spec that would have recorded the fzf answer
   in `AGENTS.md` had been dropped hours earlier. Neither spec touched the
   `## Scope decisions` bullet or the `help` sentence; each read the other as
   the owner.

2. **Git — the string was never committed.** No commit of either `AGENTS.md`
   or `.mi/SYSTEM.md` has ever contained `zoxide query --interactive`.

Together these settle it: **the edit never existed on disk.** Note the limit
honestly — git alone proves only "never committed", and cannot separate
"never written" from "written and never committed"; it is the documentary
record that supplies the rest. Say so rather than presenting git as the whole
proof.

## R5 — the census, derived rather than listed

The population is *every* `verify:` on the board that reads `AGENTS.md`,
`CLAUDE.md` or `SYSTEM.md`. Derive it; do not start from the two carriers the
PRD's R5 already names, and do not stop at the frontmatter form — the fenced
`## Verify` block form is the shape `mi-rooted-verify-commands` found last,
precisely because a key-grep cannot see it. Sweep both:

```sh
grep -rlE '^verify:.*(AGENTS|CLAUDE|SYSTEM)\.md' prds --include='*.md'
for f in $(grep -rl 'AGENTS\.md\|CLAUDE\.md\|SYSTEM\.md' prds --include='*.md'); do
  awk '/^```/{inf=!inf} inf && /AGENTS\.md|CLAUDE\.md|SYSTEM\.md/{print FILENAME": "$0}' "$f"
done
```

For each carrier, record: spec path, owning node and its `state`, the
`verify:` exit code, its FAIL lines, and the verdict — does it fail **on
`AGENTS.md` content**, and if so is the failure this node's kind (a red
naming its own unfinished work) or drift (a guard matching text a later
ticket deliberately changed)? Then answer R5's actual question: is this a
class, or is `decisions/fzf` spec04 the only member?

## Acceptance

- [x] `prd.md` carries an R1 section stating one verdict plainly — never
      landed / lost in the retirement / overwritten / not decidable — and it
      is not hedged across two of them.
- [x] That section quotes the commands that support it, including a git
      search over every commit of `AGENTS.md` and `.mi/SYSTEM.md`, with its
      output (or its emptiness) shown.
- [x] It names the limit of the git evidence: git shows "never committed",
      and the documentary record is what closes the gap to "never written".
- [x] `prd.md` carries an R5 section that states the command the census was
      derived from and the size of the population it returned, before listing
      any member.
- [x] Every carrier the sweep returns appears in that list with its spec path,
      owning node, node `state`, `verify:` exit code and FAIL lines.
- [x] Each carrier carries an explicit verdict on whether its failure is
      `AGENTS.md` content, and the section closes with a yes/no on whether
      this is a class.
- [x] The fenced-block form was swept too, and the section says so with its
      result — including a nil result, if that is what it is.
- [x] `prd.md`'s frontmatter is byte-identical to the snapshot taken before
      this spec's first edit. Compare against that snapshot, **not** against
      `HEAD` — the orchestrator legitimately moves `state:` and `claim:` on
      every transition, so a `HEAD` comparison fires on work that is not
      yours.
- [x] No requirement or acceptance box in `prd.md` is flipped by this spec —
      R1's and R5's boxes are the orchestrator's to close on the transition.

## Verify and Proof

```sh
cd "$(git rev-parse --show-toplevel)"
N=prds/00-delivery/corrections/agents-md-fzf-decision-record/prd.md
FM() { awk 'NR==1&&/^---$/{f=1;next} f&&/^---$/{exit} f' "$1"; }

# 0. BEFORE the first edit — snapshot the frontmatter. Not `git show HEAD`:
#    the orchestrator moves `state:` and `claim:` on every transition.
FM "$N" > /tmp/fzfrec.fm.before

# ---- edit prd.md, then run everything below ----

rc=0
# 1. Both findings are present as sections.
grep -qE '^## .*R1' "$N" || { echo "FAIL: no R1 verdict section"; rc=1; }
grep -qE '^## .*R5' "$N" || { echo "FAIL: no R5 census section"; rc=1; }

# 2. R1 shows its git evidence and states one verdict, not a hedge.
grep -qF 'git rev-list --all' "$N" || { echo "FAIL: R1 cites no git sweep"; rc=1; }
R1SEC() { awk '/^## .*R1/{s=1;next} s&&/^## /{exit} s' "$N"; }
R1SEC | grep -qiE 'never (landed|existed|written|committed)|not decidable' \
  || { echo "FAIL: the R1 section states no verdict"; rc=1; }
R1SEC | grep -qF 'never committed' \
  || { echo "FAIL: R1 does not name the limit of the git evidence"; rc=1; }

# 3. The census is derived: every carrier the live sweep finds is named.
for p in $(grep -rlE '^verify:.*(AGENTS|CLAUDE|SYSTEM)\.md' prds --include='*.md' | sort); do
  grep -qF "$p" "$N" || { echo "FAIL: R5 census omits carrier $p"; rc=1; }
done
grep -qF 'grep -rl' "$N" || { echo "FAIL: R5 does not state the command it derived from"; rc=1; }

# 4. Frontmatter untouched, and no box flipped by this spec.
diff /tmp/fzfrec.fm.before <(FM "$N") || { echo "FAIL: frontmatter changed"; rc=1; }
[ "$(grep -cE '^- \[[x~]\]' "$N")" -eq 0 ] \
  || { echo "FAIL: a box was closed by this spec"; rc=1; }

[ $rc -eq 0 ] && echo OK; exit $rc
```
