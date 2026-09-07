---
kind: type
type: persona
description: one worn preprompt — who is working, in the second person, with the practitioners each behaviour is taken from
read_when: "writing a persona memo, wearing one, consulting one, or dispatching work to one"
---

# persona

A memo with `kind: persona` is a preprompt: the whole body is text an agent
reads and then *is*, for the rest of the run. Not a description of a role and
not an output style — a persona says what gets noticed first, what gets
pushed back on, and what counts as done. The leaf is the handle, one
lowercase word naming the profession.

Frontmatter carries `name:` (the person) and `profession:` beside the two
keys every memo has.

Three ways to reach one, and they are not the same move:

| move | is |
|---|---|
| **wear** | read the body and work as that person for the rest of the task; the session's own judgement is replaced |
| **ask** | put one problem to one persona, answer in that voice, keep the session's judgement — say which persona answered |
| **delegate** | dispatch a subagent whose whole prompt is the body plus the job; review what comes back as that person's work |

The body is written in the second person, carries `## How you work` as
bold-led bullets, `## Voice` naming what this person never says, and
`## Built from`: one bullet per researched practitioner — who, known for, the
one trait taken. Every behaviour bullet closes with `[<Name>: <trait>]`
repeating a `Built from` trait character for character. A behaviour tracing
to nobody is cut.

A persona is composed from research and never invented, and no real person is
quoted or attributed. Trust: a persona is worn or not at all. Exempt from
[[memo-atomicity]]'s one-heading rule.