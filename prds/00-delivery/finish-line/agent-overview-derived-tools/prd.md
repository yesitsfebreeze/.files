---
state: open
priority: 8
est: 2h
mode: afk
claim:
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

## Answers

Answered 2026-08-28 by the user, after the analyst's build found the node's
premise stale.

**Q1** — **Keep the title as the single source, and spend this node on the
gate.** Drop the render-time extraction from R1 and R2. The `idioms` title has
read `Search with rg, find with fd, pick with tv` since `0f9f635`
(2026-08-24, the H.5 grader's decision), so both of R1's testable clauses —
the line names the tools, and no renderer types a tool name — already hold as
shipped, and the title is corpus content, so there is still exactly one
source. The extraction was never the goal; the informing line was.

The build also measured that no corpus field *can* feed a specified
extraction: `use` backticks `grep` and `find` exactly as it backticks `rg` and
`fd`, so a derived line would tell an agent this environment has the tools it
deliberately does not. Separating them needs a stoplist of tool names inside
the renderer, which R1 forbids. Reproduced on a second fixture — the `grep`
entry's `use` yields the same mixed set.

**What this node becomes: the check that holds the fix there.** The analyst
proved it is needed by a red that would not come — revert the title in a
staged corpus and `tests/help-agent.sh`'s DISCOVERY check stays **green**,
because it reads the expected title out of the same corpus in the same run, so
any title matches itself. CF5 catches an id renamed away; nothing catches the
line ceasing to inform. The shipped H.5 fix is currently held by nothing, and
that is the work.

The check the build proposes: the overview's `idioms` line must name at least
three of the backticked bare words its own `use` names — red at 0 on the
reverted title, green at 3 today, and it types no tool name anywhere.

## Build attempt, 2026-08-28 — what the code passed through, and what it hit

Every number below was measured on a scratch `HOME` staged the way
`tests/help-agent.sh` stages one (the thirteen nushell modules plus the
corpus, `nu -n`, no `config.nu`), against the pinned nushell 0.114.1.
Baseline before touching anything: `bash tests/help-agent.sh` → **90 PASS,
0 FAIL, EXIT 0**.

**The premise this node was written from is stale, and that matters to the
fork below.** The Purpose above quotes the `idioms` line as reading "Use the
tools this environment actually has". It has not read that since commit
`0f9f635` on 2026-08-24, where the H.5 grader's decision changed the corpus
title to `Search with rg, find with fd, pick with tv`. Bare `help` today
renders:

    For agents:
      help --json — Read this manual as structured data
      help --md — Write this manual out as markdown
      idioms — Search with rg, find with fd, pick with tv

So R1's two testable clauses already hold as shipped: the line carries the
tool names, and `grep`-ing the renderers for `rg`/`fd`/`tv` as literals finds
nothing — the names are corpus content, rendered by `_help_curated`'s
`get title`. R5's re-run has also already happened once and passed; both runs
are recorded in `gates/manual/wave6.md`'s H.5, which needs no rewording from
this node.

**R4 is not the constraint, measured rather than assumed.** Bare `help`
renders in 4.8–6.5 ms over five runs, and `_help_overview` already binds
`let corpus = (_help_corpus)` once. Any extraction from the `idioms` entry
reads a record that is already in hand: no spawn, no extra file, no
measurable cost. Whichever answer the fork takes, R4 is satisfied by
construction.

**What the build hit: the corpus holds no shape a specified extraction can
read.** Four candidate sources were run against the staged corpus, and every
one produces the wrong set or nothing:

| source | what it yields for `idioms` |
|---|---|
| backticked tokens in `use` | `rg, fd, grep, find, tv, zi, cdi, cd` |
| `also`, resolved to its targets | `grep`(alias), `tv channel`(prose), `cd <path>`(alias), `zi`(command), `cdi`(alias) |
| `verify` | `[{kind: "prose"}]` — nothing to extract |
| backticked tokens in `title` | `[]` — 0 of the corpus's 96 titles carry a backtick |

The first row is the finding. The corpus backticks a prescription and a
prohibition identically — the `use` says "never \`grep\`/\`find\`" with each
name in its own backticks — so a render fed by it would tell an agent that
`grep` and `find` are among the tools this environment has, which is worse
than the pointer-only line the node was written to replace.

**Reproduced on a second fixture, not a second run of the same one.** The
`grep` entry's `use` ("Reach for \`rg\` and \`fd\`, not \`grep\` and
\`find\`.") yields `rg, fd, grep, find` under the same extraction — a
different entry, a different sentence, the same collision. The convention is
corpus-wide, not one string's accident.

Separating the two would need a stoplist of tool names inside `_help_tools`,
which is precisely what R1's second clause forbids. So the extraction cannot
be built from the corpus as it stands, and the missing piece is structure in
the corpus rather than logic in the renderer — a decision this node's own Out
of scope disclaims.

**One thing the build found that no answer should lose: the shipped fix is
held by nothing.** Proved by its own red, and it would not go red. Revert the
title to its pre-`0f9f635` wording in a staged corpus and bare `help` prints
`idioms — Use the tools this environment actually has` again, while
`tests/help-agent.sh`'s DISCOVERY check stays **green** — it reads the
expected title out of the same corpus in the same run, so any title matches
itself. CF5 catches an id *renamed away*; nothing catches the line ceasing to
inform. Whatever the fork settles, the check that bites on this is work this
node should carry.

**The probe, so pass two re-runs it instead of rebuilding it.** No renderer
change survived the attempt, so there is no code diff to leave; the probe is
the measurement. It has no home in the tree — `prds/` holds PRDs and nothing
else, and `tests/*.sh` is enumerated by `gates/nushell-module-staging.sh`,
`gates/nvim-seed-registry.sh` and `gates/wave-status.sh`, so a stray script
there turns wave gates red — so it is written out here. Stage a machine the
way `tests/help-agent.sh`'s `mk_machine` does, then:

```nu
let corpus = (["shell" "nvim" "terminal" "capsule"]
  | each {|f| open ($"~/.config/nushell/help/($f).nuon" | path expand) } | flatten)
let e = ($corpus | where cmd? == "idioms" | first)
$e.use | parse --regex '`(?<t>[^`]+)`' | get t   # -> includes grep, find
$e.verify                                        # -> [{kind: prose}]
$corpus | where {|x| $x.title =~ '`' } | length   # -> 0
```

The revert-red demonstration is `sed` on a **staged** copy of `shell.nuon`,
never the managed one:

```sh
sed -i '' 's/title: "Search with rg, find with fd, pick with tv"/title: "Use the tools this environment actually has"/' \
  "$M/home/.config/nushell/help/shell.nuon"
```

## Questions

### Q1: Where do the tool names get the structure a specified extraction reads?

The overview already names `rg`/`fd`/`tv` from corpus content and no renderer
types a tool name — the title fix landed at `0f9f635` and its reading test
passed — but there is no corpus shape a render-time extraction can read: the
`use` backticks `grep` and `find` exactly as it backticks `rg` and `fd`, and
`also`, `verify` and `title` yield the wrong set or nothing. Do we add the
structure, and where?

   1. **Mark the tools in `verify`** — change the `idioms` entry's `verify`
      from `[{kind: "prose"}]` to one `{kind: "command", name: …}` target
      per tool, and have the render read
      `verify | where kind == "command" | get name`. It uses structure the
      schema already has, adds no key, and `help --check` gains a real
      existence check on `rg`/`fd`/`tv` for free. Costs: this node's Out of
      scope widens by one field, and the render needs a rule that keeps the
      other two agent lines clean — `help --json` and `help --md` both carry
      a `command` target named `help`, which would otherwise render as noise.
      (recommended)
   2. **Add a `tools:` field to the entry schema** — a list of names,
      extracted verbatim, the one shape no rewording can make wrong. It is a
      corpus schema change, so it is
      [`06-help/01-content-model`](../../../06-help/01-content-model/prd.md)'s
      contract and its gate's, and this node becomes its reader.
   3. **Keep the title as the single source and spend this node on the
      gate** — drop the render-time extraction from R1/R2, since the title
      already satisfies both of their testable clauses, and build the check
      that holds it there: the overview's `idioms` line must name at least
      three of the backticked bare words its own `use` names, which is red at
      0 on the reverted title, green at 3 today, and types no tool name
      anywhere.
