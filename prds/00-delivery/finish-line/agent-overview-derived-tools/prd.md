---
state: analyzing
priority: 8
est: 2h
mode: afk
claim: analyst-derived-tools 2026-08-28T12:30Z
needs:
verify: "bash tests/help-agent.sh"
origin: requested
from: 00-delivery/finish-line
---

# The agent overview names its tools, without holding a second copy of them

Parent: [Finish line](../prd.md) · net-new

Purpose: H.5's reading test, run 2026-08-24 against a deliberately uninformed
agent, found the `For agents:` block **routes** and does not **inform**. The
agent picked `idioms` for the right reason unprompted — "my task is a text
search, i.e. precisely the decision that it exists to settle" — and then wrote
`rg` into its command list anyway, saying: *"ripgrep (`rg`) — nothing above
mentions it. Not one word. I reached for it because it is what I always reach
for."*

`_help_curated` renders `id — <corpus title>` by design, so the `idioms` line
reads "Use the tools this environment actually has" and names none of them. An
agent that follows the pointer is saved; an agent in a hurry is not.

Answer 5 of the [finish-line round](../prd.md) rejects both easy paths. Naming
`rg`/`fd`/`tv` inline as prose would create a second place those names live —
the duplication the render exists to prevent, and the drift six documents on
this board hit in one week. Keeping it pointer-only accepts a measured
near-miss. The third way: **derive** the names from the corpus at render time,
so the block informs and there is still exactly one source.

**Dependency note, 2026-08-28.** `needs:` used to name
[`06-help/05-agent-interface`](../../../06-help/05-agent-interface/prd.md) and
no longer does, because the two together formed a cycle the scheduler refuses:
that node is `blocked` on *this* one — its last acceptance box is the reading
test, and Answer 5 routes the fix here — while this node needed it `done`.

The dependency was never on that node's **state**. It is on its **code**, and
that shipped: the render spine landed at `51396f0` and every one of spec01's
sixteen acceptance boxes closed at `235e179`. `_help_curated` exists to be
modified. Depending on a state that cannot arrive until this node lands is
what made the pair unschedulable; depending on a commit that already exists is
what is actually true.

## Requirements
- [ ] **R1** — The overview's `idioms` line carries the tool names, extracted
      from the `idioms` entry's own corpus content at render time. No tool
      name is typed into a renderer.
- [ ] **R2** — The extraction is **specified**, not incidental: what field it
      reads and what shape it pulls out, so a corpus edit changes the overview
      predictably rather than by accident.
- [ ] **R3** — Extraction that finds nothing degrades to today's behaviour —
      the bare title, still a working pointer — and never renders a truncated
      or empty tool list.
- [ ] **R4** — R8 of [02](../../../06-help/02-help-command/prd.md) still
      holds: this runs on the plain `help` path, so it must not spawn anything
      or read a file the hot path does not already read. Measure the cost.
- [ ] **R5** — The H.5 reading test is **re-run** against a fresh uninformed
      agent, and the finding is whether it still reaches for a tool the text
      does not name. A change made because a reading test failed is not proven
      by anything except that reading test passing.

## Acceptance
- [ ] `help`'s overview names the tools the `idioms` entry names, and
      `grep`-ing the renderers for `rg`/`fd`/`tv` as literals finds nothing.
- [ ] Editing the `idioms` entry's content changes the overview with no
      renderer edit.
- [ ] `bash tests/help-agent.sh` exits 0, tally quoted.
- [ ] The re-run reading test is recorded verbatim, pass or fail. A fail is a
      finding, not a reason to revert quietly.

## Out of scope
- The rest of the `For agents:` block, which the test found working.
- Any change to what the `idioms` entry says; this node reads it.
