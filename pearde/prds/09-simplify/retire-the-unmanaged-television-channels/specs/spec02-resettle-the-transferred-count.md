---
complexity: 3
footprint:
  - .pearde/prds/09-simplify/retire-the-unmanaged-television-channels/prd.md
---

# spec02 — the transferred box counts nineteen, with the arithmetic written down

The acceptance box this PRD inherited from `09-simplify/06-neovim-television`
reads `ls ~/.config/television/cable | wc -l` is at most 15. Q1's answer
makes that unreachable and the PRD's own anchor says so in advance: adopting
the nine `git-*` channels takes the source from ten files to nineteen and the
machine to nineteen, so the threshold is *"the count the answer resettles, not
a number to tune silently. Raise it with the arithmetic written down, or
measure the box against what the source owns."*

Both of the anchor's two routes land on the same number, because spec01's
whole point is that the two sides agree: nineteen on the machine, nineteen in
the source. So this spec rewrites the box to nineteen and writes the sum next
to it — `10 owned after 9b80a71 + 9 adopted = 19` — with a sentence saying
that the answer to Q1 moved it and that it is exact, not a ceiling to grow
into. A box that reads "at most 19" would go green again the moment somebody
deleted a channel; "is 19" fails in both directions, which is what the
contract's sentence — the two sides agree — actually asks for.

This is a wording change to one file. It touches no configuration, deploys
nothing, and must not silently loosen any other clause: 06's two green
clauses (sixteen channels over ten cable files in the isolated fixture, and
`ls home/dot_config/television/cable | wc -l` at most 15) belong to 06 and
this spec does not reach them. Both of those now read against a directory of
nineteen, which is a finding for 06's owner and not this spec's to fix — see
`report.md`.

Quote every box spelling inside the PRD backtick-quoted, so the matcher does
not read a pasted example as a real box.

## Acceptance

- [x] The PRD's `## Acceptance` box no longer names the number 15 as its
      threshold.
- [x] The box asserts the machine count is exactly 19, and the same box or
      the line under it carries the sum `10 + 9 = 19` and says the answer to
      Q1 is what moved it.
- [x] The box is satisfied by the machine as it stands: running the count it
      names returns 19.
- [x] The PRD's `## Questions` and `## Answers` sections are unchanged, and
      the frontmatter is untouched.
- [x] No other PRD file is modified.

## Verify and Proof

```sh
cd /Users/feb/dev/dotfiles
P=.pearde/prds/09-simplify/retire-the-unmanaged-television-channels/prd.md
test "$(ls ~/.config/television/cable | wc -l | tr -d ' ')" = 19
box=$(sed -n '/^## Acceptance/,/^## Questions/p' "$P")
printf '%s' "$box" | grep -q 'at most 15' && { echo 'FAIL: 15 still the threshold'; exit 1; }
printf '%s' "$box" | grep -q '19'         || { echo 'FAIL: 19 not in the box';    exit 1; }
printf '%s' "$box" | grep -q '10 + 9'     || { echo 'FAIL: arithmetic not written down'; exit 1; }
grep -q '^\*\*Q1\*\*' "$P" || { echo 'FAIL: the answer was disturbed'; exit 1; }
echo ok
```
