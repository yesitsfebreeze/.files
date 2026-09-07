---
kind: type
type: work
description: one unit of planned work — `level: 1-10`, `status: open | done | blocked`, a `## Do` and a `## Check`; done when the Check passes
read_when: "writing a work memo"
---

# work

One unit of planned work. Frontmatter carries `level: 1-10` and
`status: open | done | blocked` plus, when blocked, `blocked-on: question |
person | external`; the body carries exactly `## Do` — what to change, the
files, the verbs — and `## Check` — the command or observation that proves it
done. Trust: `status: done` only when the Check passes. A memo with no Check
is not specced yet.

Level bounds the split: a level-10 item is one focused change a session
finishes; an item too big for level 10 drills into children one level
shallower, `subwork:` naming them, its own Check becoming "every child
done". `needs:` names the memos it waits for. [[work]] runs one;
[[plan-execution]] runs a plan's worth.