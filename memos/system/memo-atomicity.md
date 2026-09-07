---
kind: documentation
description: One memo carries one claim, its evidence, and its consequences
read_when: before writing or splitting a memo
---

# memo-atomicity

**One memo is one claim.** Not one topic, not one area, not one afternoon's
findings — one thing a reader could cite on its own. The test is a sentence:
if the body needs a second sentence that does not defend the first, the second
sentence is another memo.

The cheat this rule exists to stop is the bundle: a file that says "here are
seven things about persistence" and calls itself one memo because the seven
share a subject. A bundle is cheaper to write and worthless to read — the
`description` cannot describe it, so a cold agent cannot tell whether to open
it, and links into it land on the file instead of the claim.

So the shape is fixed:

- **A body carries one claim, its evidence, and why it matters.** Evidence may
  be a list — four files, three call sites — as long as the list is proof of
  the one claim and not four claims wearing bullets.
- **No free-form `## ` sections.** The only headings a memo may carry are the
  templates': `Decision`, `Why`, `Consequences` for a decision, `Do` and
  `Check` for a work item. A memo that needs its own section headings to
  organize itself is more than one memo. `kind: documentation`, `kind: routine`
  and `kind: persona` are exempt — an index, a procedure and a worn preprompt
  are lists by nature.
- **A split names its siblings.** When one claim is cut out of another, both
  bodies link to the other by leaf name. The connection is the link, never a
  shared file.

**The rule runs.** `just memos-check` fails on any memo carrying a heading
outside that set. A name in `memos-bundles.txt` at the repo root is a memo
that predates the law; the gate also fails when a listed name has become
atomic, so the list can only shrink. Adding a name to it to get a bundle past
the gate is the one move this whole section exists to forbid.

See [[memo-writing]] and [[memo-layout]].