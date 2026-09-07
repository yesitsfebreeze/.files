---
kind: routine
name: drill
description: Conduct a deep plan/design interview, persist each Q&A, and move the topic file to a decision once a coherent picture exists.
read_when: "splitting work, designing anything non-trivial"
---

1. Prerequisites

- Read `memos/SYSTEM.md`, every `kind: question` memo, and the `kind: decision`
  memos the topic touches.
- Read `git diff` and `git status --short` before generating follow-up
  questions.
- If the topic file has unanswered entries (`A: ?`), resolve those gaps
  before adding new topics. After an answer, replace `A: ?` with the answer
  text in the same block, immediately.

2. Topic and storage model

- Each topic is one memo, `kind: question`, one file.
- A topic is created the moment a new subject appears that has no file;
  kebab-case name, written at `memos/question/<topic>.md`.
- All questions and answers for that topic live only in that file.
- Once every answer is in and the picture holds, rewrite the file in place:
  `kind: question` becomes `kind: decision`, the file moves to `decision/`,
  the body takes the decision block ([[memo-writing]]). Run `just memos-check`.

3. Interview behavior

- Interview about every aspect of the design until a shared understanding
  exists. Walk down each branch of the design tree, resolving dependencies
  between decisions one by one. For each question, give a recommended answer.
- If required details are discoverable by codebase inspection, inspect
  before asking.

4. Ask style

- Use the agent's native question tool. Without one:

```
? <clear-short-question-name>

<what is asked and what it entails>

R: <recommended-answer>
1: <best-option-to-R>
2: <best-option-to-1>
```