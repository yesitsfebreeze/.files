---
kind: procedural
description: every memo carries one claim — the test is whether a second sentence in the body defends the first or starts another memo
read_when: "writing a new memo, splitting a bundle, or adding a section heading to an existing memo"
---

# one-claim-per-memo

Every memo carries **one claim**, and the test is one sentence: if the
body needs a second sentence that does not defend the first, the
second sentence is another memo.

- **The body proves the claim, does not organise itself.** Evidence is
  allowed as a list — four call sites, three measured numbers — as long
  as the list is proof of the one claim and not four claims wearing
  bullets.
- **No free-form `## ` sections.** The only headings a memo may carry
  are the templates': `## Decision`, `## Why`, `## Consequences` for
  a decision; `## Do`, `## Check` for a work item. A memo that needs
  its own headings to organise itself is more than one memo. `kind:
  documentation`, `kind: routine`, and `kind: persona` are exempt.
- **A split names its siblings.** When one claim is cut out of another,
  both bodies link to the other by leaf name. The connection is the
  link, never a shared file.
- **A bundle is a known thing on a list.** `memos-bundles.txt` at the
  repo root names every memo that pre-dates the one-claim law and
  still holds several. The list only shrinks. Adding a name to it to
  get a bundle past the gate is the one move this rule exists to
  forbid.

The gate (`scripts/memos-check.py`, `just memos-check`) refuses the
violation. A memo that opens a free-form `## ` heading it does not own
is **red on every run**, and the failure names the file and the count.