---
kind: documentation
description: The memo frontmatter and templates for writing the record
read_when: before writing or changing a memo
---

# memo-writing

## What a memo is

```markdown
---
kind: <one of the kinds declared in system/>
description: <one line, what it holds>
read_when: <one line, what question sends a reader here>
---

# <name>

<body>
```

- **One memo = one thing.** A concept, one decision, one destination. When
  two subjects share a file, split it.
- **Frontmatter is for machines and the index; the body is for the reader.**
  The `description` is what a cold agent sees before deciding to read, and
  `read_when` is what tells it whether this is the memo for the question it
  has. Both are read straight out of the memo into the generated index, so
  they are written once and never copied.
- **The body carries its links.** A memo links by leaf name,
  `[[memo-atomicity]]` — Obsidian wikilinks. Leaf names are unique across
  `memos/`, so a link resolves to exactly one file. A reader follows it when
  it needs the detail.

## The kind property

One axis, not two: `kind` is what type of knowledge the memo carries and why
the reader should trust it. There is no second vocabulary — a memo's shape
follows from its kind. A kind is declared by a `kind: type` memo in `system/`
— `type:` the name, the body what a memo of that kind is, which keys and
headings it carries, and what makes a reader trust it.
`system/_index_.md` lists the whole vocabulary; a `kind:` no `system/` memo
declares fails the gate.

A memo carries exactly one `kind`, and its folder is that kind unless it
belongs to the base system. Links between memos go by leaf name and resolve
to exactly one file.

## Writing a memo

Copy the block. Do not remember it — a protocol that relies on recall gets
violated by its own author.

**A decision** (something settled that would otherwise be re-argued):

```markdown
---
kind: decision
date: 2026-09-07
status: decided | refuted | unmeasured
description: <the decision in one line>
read_when: <what question sends a reader here>
---

# <kebab-case name>

## Decision
<what was chosen>

## Why
<the forces that bit, the alternatives considered, what each would have cost>

## Consequences
<what follows from this being true>
```

**A question** (something the drill is still asking):

```markdown
---
kind: question
description: <the topic in one line>
read_when: <what question sends a reader here>
---

# <kebab-case name>

----
Q: <question text>
A: ?
```

Once every `A:` is filled and the picture holds, it is rewritten in the
decision block above — `kind: question` becoming `kind: decision` — and moves
to `decision/`.

**A work item** (one unit of planned work):

```markdown
---
kind: work
level: <1-10>
status: open | done | blocked | blocked-on: question | person | external
description: <the unit in one line>
read_when: <what question sends a reader here>
---

# <kebab-case name>

## Do
<what to change, the files, the verbs>

## Check
<the command or observation that proves it done>
```

It lives at `work/<kebab-name>.md`. **Level bounds the split**: a level-10
item is one focused change a session finishes; an item too big for level 10
drills into children one level shallower — `subwork:` naming the children in
its body, each child its own work memo, the parent's `Check` becoming "every
child done". A parent is `done` only when every child is. `status: done` only
when the `Check` passes. A `status: blocked` memo carries `blocked-on:`
naming who unblocks it — `question` (a drill answer), `person` (a human act),
`external` (an unrelated commit or install); a routine picking up work skips
`blocked-on: person`.

A memo with no `## Check` is not specced yet.

Superseding an older decision: the older one keeps its text and the new one
names what it supersedes — an edit adds, it never deletes the sentence it
corrects.

**Anything else** (a concept, a finding, a connection, a reference): one
file, the block above, body in whatever shape the subject needs. The kind
does the work the shape would.

See [[memo-layout]] and [[memo-atomicity]].