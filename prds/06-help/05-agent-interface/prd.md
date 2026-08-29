---
state: done
priority: 8
est: 1.25h
task: H.5
commit: 4475488
mode: afk
needs:
  - 06-help/03-browser
  - 00-delivery/finish-line/agent-overview-derived-tools
verify: "bash tests/help-agent.sh"
actual: 0.02h
---

# Agent interface

Parent: [Help epic](../prd.md) · C 3 · U 8 · net-new

Purpose: Agents are a first-class reader of this manual, not an afterthought.
An agent that runs one command should learn how to operate this environment
correctly — which finder is installed, how navigation works, what the keys do
— instead of guessing from defaults.

## Requirements
- [x] **R1** — **Structured output.** `help --json` emits the full manual as
      one JSON document: topics, entries, and every field from
      [01-content-model](../01-content-model/prd.md). Stable field names — this is an
      interface, so renaming a field is a breaking change.

      **The published field list**, eleven keys in this order, emitted by
      `_help_norm` on **every** entry: `id key cmd title use topic mode also
      why verify source`. Optional corpus fields are materialised as `""` /
      `[]`, never omitted — a consumer must not have to tell absent from
      empty. No corpus row index and no `version` key are published, and no
      per-topic count: an index is an unstable handle inside a stable
      interface, and a stored count is the stale-number shape this board keeps
      correcting.

      Checked: `help --json | jq '.topics | length'` → 9, `.entries | length`
      → 92, `[.entries[] | has("why")] | all` → `true`, and
      `tests/help-agent.sh` asserts the **exact** key set on every entry, so
      an added key is as red as a renamed one.
- [x] **R2** — **Document output.** `help --md` emits the whole manual as
      markdown, grouped by topic. This is what gets pasted into an issue, read
      by an agent that prefers prose, or written to a file for review.

      Checked: 1137 lines, one `## ` per topic in spine order (9), one
      `### <id>` per entry (92), the host-only marker on exactly the 16
      `mode: "terminal"` entries, and no `std/help` tail anywhere.
- [x] **R3** — **Plain by default under capture.** With stdout not a TTY,
      plain `help` already emits unstyled text ([02](../02-help-command/prd.md),
      requirement 7), so an agent that just runs `help` gets something usable
      without knowing about any flag. `--json` is the optimization, not the
      requirement.

      Checked rather than assumed: `help --json`, `help --md` and bare `help`
      each carry no `0x1b` byte under capture (first ESC index `-1` on all
      three).
- [x] **R4** — **Discovery.** Agents only use what they know exists, so:
  - [x] `AGENTS.md` states that `help` is the manual and should be consulted
        before suggesting shell or editor workflows;

        Checked: `AGENTS.md:125` — "**`help` is the manual for this
        environment**", with "Consult it before suggesting or writing any
        shell/editor workflow" under it. Read only; that file is another
        lane's.
  - [x] the entry for a surface names the tool actually installed, so an agent
        reads "television (`tv`)" and stops reaching for `fzf`;

        Checked: the `idioms` entry's `use` says "Pick with television
        (`tv`) — the single exception is `zi`, which opens fzf".
  - [x] the `agents` topic documents the agent-facing surface itself:
        `cc`/`cr` ([04-shell/08](../../04-shell/08-claude-launchers/prd.md)), how
        capsules get credentials
        ([01-capsule/03](../../01-capsule/03-credential-propagation/prd.md)), and
        `help --json` itself.

        Met with **one value**: `credentials in a capsule` added to the `cc
        [...args]` entry's `also`. The entry itself stays in `containers`,
        where it belongs by reader task, and the `agents` topic now reaches
        it. No prose moved, so no digest moved — `nu
        tests/help-content-model.nu` still exits `ok`.
- [x] **R5** — **Idioms, not just keys.** Include the handful of "do it this
      way here" rules an agent would otherwise get wrong: `rg`/`fd` over
      `grep`/`find`, `tv` as the picker, nushell pipelines return structured
      data (so `| where`, not `| grep`), and the fact that `cd` in this shell
      can create directories.

      **This was satisfied in the corpus and invisible in the render, which is
      the whole point of the node.** Measured before this change: bare `help`
      printed the nine topics with counts, four first keys and the go-deeper
      line, and never named `idioms` — so an agent that ran `help` once, which
      is what `AGENTS.md` asks it to do, read a table of contents and still
      had to guess. The fix is a `For agents:` block in `_help_overview`,
      built by the same curated-id mechanism the `First keys:` block uses, so
      it renders `id — <corpus title>` and writes no prose of its own:

          For agents:
            help --json — Read this manual as structured data
            help --md — Write this manual out as markdown
            idioms — Search with rg, find with fd, pick with tv

      (The `idioms` title was `Use the tools this environment actually has`
      until 2026-08-24, when the H.5 reading test showed the block routed but
      did not inform — the grader's decision was to make the corpus title name
      the tools, keeping the render prose-free.)

      Checked by `tests/help-agent.sh`'s DISCOVERY check, with a
      counterfactual that renames the `idioms` entry in a scratch **corpus**
      and proves the block loses that line silently.
- [x] **R6** — **Honest boundaries.** Entries mark host-only vs
      container-available ([02](../02-help-command/prd.md), requirement 9) so an
      agent inside a capsule isn't told about WezTerm keys it cannot press.

      Checked: `--json` publishes `mode` verbatim on every entry, and `--md`
      appends the **same** host-only sentence `_help_entry_detail` already
      used — one literal in `_help_host_only`, called by both — on exactly the
      16 `mode: "terminal"` entries and on no other.

## Acceptance
- [x] `help --json | jq '.topics | length'` works, and every entry visible in
      `help --all` is present in the JSON.

      `jq '.topics | length'` → 9; `jq '.entries | length'` → 92 =
      `help --all | length`; and `[.entries[].id]` equals `help --all | get
      key` element for element, because all three whole-manual renders iterate
      the one `_help_spine` walk.
- [x] A fresh agent session, given only the output of `help`, can navigate
      (bare-word jump), find a file (`Ctrl-Space` or telescope), and start a
      capsule — without inventing a tool that isn't installed.

      **Owed as a manual gate, not fakeable green.** This is a reading, not a
      command: the box belongs in `gates/manual/wave6.md` as H.5, and that
      file is the orchestrator's. The machinery it needs is in place and
      measured — bare `help` now names `idioms` with its corpus title, so the
      "reach for `fzf`" failure has a line in the only output the box allows
      the session to see.

      **Updated 2026-08-28 — what holds this box has changed twice today, and
      what remains is a person.** It was blocked on
      [`agent-overview-derived-tools`](../../00-delivery/finish-line/agent-overview-derived-tools/prd.md),
      per this node's `## Answers`. That node is now `done`: the fix it was
      going to make had already shipped at `0f9f635`, and what it built instead
      is the gate that holds the fix there — `tests/help-agent.sh` is 100 PASS
      and its CF6 proves the hole, since reverting the title leaves
      `discovery_ok` green while INFORMING goes red.

      So every board dependency is satisfied and the machinery is gated. What
      is left is the H.5 row itself, and `gates/manual/wave6.md:51-78` says
      twice that the two runs on file are **evidence, not a tick**: the subject
      is an agent's behaviour on first contact, so the session has to be
      uncontaminated, and nobody who has read this repo — including this
      orchestrator — can be the grader. That is a human's job by construction,
      not by convention.

      **Closed 2026-08-29 by user decision, on the filed evidence — see this
      node's `## Answers` Q2 and the amended H.5 row in
      [`gates/manual/wave6.md`](../../../gates/manual/wave6.md).** The
      paragraph above stands as written and is not deleted: it is the correct
      reading of the box, and the tick is a decision to accept the weaker of
      the two properties it asks for. What is proven is an uncontaminated
      **subject**, graded against a tool list fixed in advance. What is not
      proven is an uncontaminated **grader**, and no run on this board can
      supply that.
- [x] `help --md > manual.md` produces a document readable top to bottom.

      Produced and read: an H1, one line saying `help --json` carries the same
      content, then per topic `## <id> — <title>` with the topic summary, and
      per entry `### <id>`, its title, its `use`, then `why:`/`also:` when
      non-empty and `mode:`/`source:` always. Spine order throughout, and a
      topic emptied by `--mode` is skipped whole rather than left as an empty
      heading.
- [x] Renaming a JSON field requires updating this PRD's field list.

      Mechanical, not aspirational: R1 above now **carries** the field list,
      and `tests/help-agent.sh` holds the same eleven names in one
      `NORM_KEYS` string that it asserts twice — against `_help_norm`'s text
      in `--tree` and against every entry of a real `help --json` in
      `--hermetic`. Counterfactual 1 renames `use` to `usage` on a scratch
      copy and both halves go red.

## Out of scope
- Anything this node's Requirements do not name. The epic ([`../prd.md`](../prd.md)) owns the shared invariants.

## Blocked 2026-08-24 — one box, the H.5 reading, and the evidence for it

`bash tests/help-agent.sh` → **90 checks, 0 FAIL, EXIT 0**; `nu
tests/help-content-model.nu` → `ok`; `bash tests/shell-help.sh` → 93/93, EXIT
0; `help-browser.sh`, `nushell-module-staging.sh`, `tree-links.sh`,
`manual-coverage.sh` and `retired-phrases.sh` green beside them. R1–R6 and
three of four acceptance boxes `[x]`.

The fourth is the **H.5 reading**, now written into `gates/manual/wave6.md`,
and it needs a person to grade it. `gates/waves.tsv`'s wave-6 gates cell was
**empty** and now carries `external bash tests/help-agent.sh`.

### The reading test was run, and it half-worked

The orchestrator ran H.5 on 2026-08-24 with a deliberately uninformed agent:
given the rendered `help` output and nothing else, no repo access and no tools,
and a task needing both a string search and a file-find.

**What worked — the routing.** Asked what it would do *before running
anything*, it answered `idioms`, and gave the right reason unprompted: "my task
is a text search, i.e. precisely the decision (`rg` vs `grep` vs a nushell
pipeline) that it exists to settle. Running my habitual `rg` first and reading
`idioms` after would be doing the thing the manual is there to prevent." It also
reasoned from the topic blurbs to `~/.config/wezterm` for the tab-jump, and
worked out that `F5 <digit>` is likely a `for i in 1..9` loop so the literal
`F5` and `ActivateTab` are two different greps. That is the `For agents:` block
doing its job.

**What did not work — the overview names no tools.** Its own answer to "what
did the text tell you": *"ripgrep (`rg`) — nothing above mentions it. Not one
word. I reached for it because it is what I always reach for."* It wrote `rg`
into the command list anyway, with a `grep -rn` fallback, and flagged the
near-miss itself: *"my instinct was to open with `rg capsule ~/.config` and read
the manual only if that came back empty. On a machine whose manual has a
command whose entire job is to tell me which search tool exists, that ordering
is the error."*

So the block **routes** correctly and does not **inform**. `_help_curated`
renders `id — <corpus title>`, by design, so the `idioms` line reads "Use the
tools this environment actually has" and names none of them. An agent that
follows the pointer is saved; an agent in a hurry is not.

**That is a genuine trade, not a defect, which is why it is recorded rather
than fixed.** The render writes no prose precisely so the overview cannot drift
from the corpus — the failure mode six documents on this board hit today.
Naming `rg`, `fd` and `tv` inline would make the overview self-sufficient and
reintroduce exactly that duplication. Whoever grades H.5 should decide which
they want; the measurement is here either way.

Incidental, and worth knowing: rendering `help` at all required a staged
`HOME`, because `_help_dir` resolves `~/.config/nushell/help` — the deployed
corpus — and `just cutover` has not run.

### Two deviations, both accepted

1. **The spec's `help --delegate ls` rc-0 box is not achievable in this gate**,
   and the reason is the gate's own design: no `config.nu` means `core-help` is
   unbound, which is the same absence that makes the no-`core-help` assertion
   work. The property clause 1 actually carries was asserted instead — with the
   corpus gone, `--delegate` still dies at `core-help` and names **no** corpus
   path, so the escape hatch is corpus-free. The rc-0 half belongs to
   `tests/shell-help.sh`, on a machine that loads `config.nu`.
2. **`tests/help-agent.sh` had to spell out its `MODULES=` list.** A derived
   `$(grep …)` is invisible to `gates/nushell-module-staging.sh`'s predicate,
   which reported 11 MISSes and turned a wave-0 gate red. The list is spelled
   out with a `modules_fresh` check comparing it against `config.nu`'s own
   `source` lines in the same run, so it can be stale for exactly one gate run.

**Markdown heading markers are built with `char hash`, not written** — a
literal `# ` in a string would have falsified the claim `shell-help.sh`'s
`strip_comments` rests on. That was the one real collision between two spec
constraints and it resolved cleanly.

**Two lanes composed without being told to:** `gates/lib.sh` gained
`line_of_decl` / `line_of_code` mid-run from the `gates-lib-anchored-lookup`
lane, and this gate adopted `line_of_code` for its three code lookups while
keeping a local `line_of` for the clause **comment** lookups, which
`line_of_code` skips by construction.

### The reading test, re-run 2026-08-24 after the title fix

Same protocol as the first run: a fresh `claude -p` session outside the repo,
no tools, no repo context, given only the rendered `help` output — which now
carries `idioms — Search with rg, find with fd, pick with tv` — and a task
needing a string search and a file-find (locate where the terminal's tab-jump
keys are configured).

**Result: the failure mode of the first run did not recur.** The plan it
produced routed through `help terminal` and `help "F5 <digit>"` before any
search, used `fd -H wezterm ~` to locate the config and `rg -in` for both the
literal `F5` and the `ActivateTab` fallback, and pipelined `help --json`
through nushell forms (`open | to text`). Its own attribution, verbatim:

> **"idioms — Search with rg, find with fd, pick with tv"** dictates the
> tooling in steps 5–7: `fd` to locate files, `rg` to search contents,
> rather than `find`/`grep`.

No `grep`, `find` or `fzf` appears anywhere in its eight steps. The one
outside-knowledge item it used (`ActivateTab`) it flagged itself as not
coming from the help text. Graded against the H.5 PASS line this is a pass by
the letter; the tick in `gates/manual/wave6.md` remains the human's.

## Questions (rounds answered 2026-08-28 and 2026-08-29)

Board-frontier drill round, 2026-08-28. This node's fork — the H.5 grade the
`## Blocked` section above says needs a person.

### Q1: Should the agent overview name the tools, and if so where do the names live?

The reading test found the block routes and does not inform: the agent picked
`idioms` for the right reason, then reached for `rg` anyway because nothing in
the text named it. Naming `rg`/`fd`/`tv` inline fixes that and creates a
second place those names live — the duplication the render exists to prevent.
Which cost is paid?

1. **Derive the names from the corpus at render time** — the render reads the
   `idioms` entry's own content and pulls the tool names out of it. The block
   informs and there is still exactly one source, so it cannot drift. More
   work than either alternative. (recommended)
2. **Name them inline as prose** — write `rg`/`fd`/`tv` into the overview
   block. Cheap and immediate, and accepts a second copy.
3. **Keep pointer-only** — close H.5 recording that an agent following the
   pointer is saved and an agent in a hurry is not, as an accepted limitation.

### Q2: H.5 blocks six nodes and two uncontaminated sessions have already passed it. Who gets to grade it?

Board-frontier drill round, 2026-08-29. The `## Blocked` section records two
runs of the reading test, both by sessions that knew nothing about this repo,
both passing, and both filed with the words *"Evidence, still not a tick."*
The second ran after commit `0f9f635` changed the `idioms` title, was given
only the rendered `help` output, prescribed `fd` to locate and `rg` to search,
credited the idioms line for both, and named no `grep`, `find` or `fzf`
anywhere. That is the PASS line met verbatim, twice.

1. **Tick on the filed evidence** — record the transcript as the grade, name
   who set the run up, and close the node. (recommended)
2. **The user runs a third themselves**, and the two filed runs become
   corroboration rather than the grade.
3. **Withdraw H.5 entirely** — a check only an outsider can run is not a gate
   this board owns; close on the automated surface and accept that the manual
   ships with no first-contact test.


## Answers

**Q1** — **Derive the names from the corpus at render time.** The work is
[`agent-overview-derived-tools`](../../00-delivery/finish-line/agent-overview-derived-tools/prd.md),
which owns R1–R5 including the re-run of the reading test — a change made
because a reading test failed is not proven by anything except that test
passing.

This settles the fourth acceptance box, so **the H.5 grade is no longer what
blocks this node**; the derived-tools node is. The two deviations recorded
above stand unchanged, and R1–R6 stay `[x]` — the interface itself was never
the thing in question.

**Q2** *(answered 2026-08-29)* — **Tick on the filed evidence.** The second
run is the grade of record: post-`0f9f635`, uncontaminated, given only the
rendered `help` output, and meeting the PASS line's named tools exactly.

**What the tick does not claim.** The box says *"Why a human sets it up"*, and
the human who set both runs up was the orchestrator — so the independence
being relied on is the *subject* session's, never the grader's. That is the
weaker of the two properties the box was written to get, and it is the one on
file. It is recorded here rather than smoothed over, because the next reader
deserves to know which half was proven: an uncontaminated subject, graded
against a list written in advance precisely so the grade could not be argued
with.


## Implementer run, 2026-08-28 — spec01 re-measured end to end

The spec's sixteen acceptance boxes are now `[x]` in
[`specs/spec01-json-and-markdown-renders.md`](specs/spec01-json-and-markdown-renders.md),
each with the output it was closed against. Nothing in the code needed
changing: `help.nu`'s `_help_norm` / `_help_json` / `_help_md`, the two flags
and their validation, the shared `_help_curated` render and the `For agents:`
block, and the one `also` value on `shell.nuon`'s `cc [...args]` entry were
all present and green. The three verify commands:

```
bash tests/help-agent.sh          90 PASS, 0 FAIL, EXIT 0
nu tests/help-content-model.nu    ok — 96 entries across 4 files, 9 topics
bash tests/shell-help.sh          CHECKS: 93 run, 93 passed, 0 failed
```

**The counts in R1, R2 and the first acceptance box are readings of
2026-08-24 and have moved, which is exactly what those checks are built to
survive.** Re-measured today on a scratch `HOME` with no `config.nu`: the
corpus is **96** entries, not 92, and `help --md` is **1183** lines, not
1137. Everything the numbers were evidence *for* still holds, and holds
because nothing is frozen — `.entries | length` still equals
`help --all | length` (96 = 96) and `[.entries[].id]` still equals
`help --all | get key` element for element; `.topics | length` is still 9 and
equals `topics.nuon`'s row count computed in the same run; the host-only
marker still lands on exactly the 16 `mode: "terminal"` entries; and every one
of the 96 entries carries the same single eleven-key tuple in the documented
order (`distinct key tuples: 1`). The earlier readings are left where they
stand rather than overwritten: they were true when taken, and the point of
this paragraph is that a count in prose is a reading of its day.

Two things a later reader should not have to rediscover.

**The `--delegate` rc-0 half of the missing-corpus box is provable, and the
PRD's deviation 1 is `reproduced`.** Fixture: the same scratch `HOME` with
`help/` renamed to `help-gone/`. Under bare `nu -n` with no `config.nu`,
`help --delegate ls` exits 1 at ``Command `core-help` not found`` and names no
corpus path — the escape hatch is corpus-free, which is the property the gate
asserts. Bind the alias the way `config.nu` binds it (`alias core-help =
help`) and the same command with the corpus still gone exits **rc 0**,
printing nushell's own `ls` help. So the deviation is a property of the gate's
deliberately config-free staging, not of the code.

**`help --md` does contain the string `std/help`, twice, and that is not the
tail the spec forbids.** Both hits are the `help` entry's own corpus `use` and
`why` prose at `manual.md:1093` and `:1095`, describing the delegation. The
render shells out nowhere: `core-help` occurs in `help.nu` at lines 24, 27,
38, 484, 534, 645, 657, 708, 773 and 782, while `_help_norm` spans 359-375,
`_help_json` 388-390 and `_help_md` 421-456 — not one occurrence falls inside
any of the three.

One wording slip, in the spec and not in the code: section 5's prose says
"Four counterfactuals" and then lists five. Five is what is specified and five
is what `tests/help-agent.sh` runs; the spec's box is ticked against five.

The second acceptance box above is untouched. It is the H.5 reading, owed to
`gates/manual/wave6.md` (the orchestrator's file), and the `## Answers`
section routes the change behind it to
[`agent-overview-derived-tools`](../../00-delivery/finish-line/agent-overview-derived-tools/prd.md) —
neither is this run's to close.

## Report

spec01-json-and-markdown-renders: exit 0
── stage --tree: help.nu and shell.nuon as text
      guard[tree] watching /Users/feb/.config/chezmoi/chezmoi.toml
      guard[tree] sha256 in       = 02d5d4ee50b5d37955ffe7778938ddee82f4da24cbaf552b4dba3810d3c850a1
      guard[tree] source-path in  = /Users/feb/dev/.files/home
PASS  tree: help.nu is a regular file in the managed tree
PASS  tree: this gate's spelled-out MODULES list still equals config.nu's own `source` lines — the list is spelled out for gates/nushell-module-staging.sh's predicate, so it needs its own freshness check
PASS  tree: _help_norm publishes exactly the eleven documented keys, in order — id key cmd title use topic mode also why verify source
PASS  tree: …with every optional corpus field materialised as "" or [], never omitted — a consumer that has to tell absent from empty is reading a dump
PASS  tree: none of the six new defs names `core-help` — it is an ALIAS from config.nu, so under `nu -n` it binds as an external at parse time, and `--md` would shell out to std/help once per command entry
PASS  tree: --json and --md are in `def help`'s signature with the house trailing `#` comments
PASS  tree: every `#` in help.nu OPENS a comment — none sits inside a string, and the only ones with code before them are the parameter comments in `def help`'s signature. This is the structural claim tests/shell-help.sh's `strip_comments` rests on, and it is why _help_md builds its markdown headings with `char hash` instead of writing them
PASS  tree: ONE spine walk — _help_all_table, _help_json and _help_md each iterate _help_spine/_help_spine_grouped and none re-walks _help_corpus, so --all, --json and --md agree BY CONSTRUCTION rather than by three sorts that happen to match
PASS  tree: ONE host-only literal (R6) — the sentence appears once, in _help_host_only, and both _help_entry_detail and _help_md call it
PASS  tree: ONE curated-id render — _help_curated is defined once, called twice from _help_overview, and `get title` lives only inside it, so neither block writes a sentence of its own
PASS  tree: the overview carries BOTH curated blocks — `For agents:` with help --json/help --md/idioms and 06-help/02's untouched `First keys:` with its four ids
PASS  tree: the go-deeper line APPENDS `· help --json · help --md` after `help --fuzzy` and leaves 06-help/02's exact substring intact — tests/shell-help.sh:539 asserts it with grep -oF, so inserting inside it turns that gate red
PASS  tree: the existing clause numbering did not move — 1, then the LETTERED 1a/1b renders, then 2,3 … 10 in order, with the corpus-free `--delegate` return above both renders
PASS  tree: the validation names every rejected flag — --json/--md exclusive, no query, and drop --all/--fuzzy/--entry/--topic/--delegate
PASS  tree: shell.nuon's `cc [...args]` entry lists `credentials in a capsule` in `also`, which is the ONE value that makes R4's third bullet true — the entry itself stays in `containers`, where it belongs by reader task
PASS  tree: …and that `also` target really is a live entry id, so 01-content-model's also-resolution check stays green
      guard[tree] sha256 out      = 02d5d4ee50b5d37955ffe7778938ddee82f4da24cbaf552b4dba3810d3c850a1
      guard[tree] source-path out = /Users/feb/dev/.files/home
PASS  tree: LIVE chezmoi.toml unchanged (02d5d4ee50b5d37955ffe7778938ddee82f4da24cbaf552b4dba3810d3c850a1)
PASS  tree: LIVE chezmoi source-path unchanged (/Users/feb/dev/.files/home)
── stage --hermetic: a real nushell, a scratch HOME, and NO config.nu
      guard[hermetic] watching /Users/feb/.config/chezmoi/chezmoi.toml
      guard[hermetic] sha256 in       = 02d5d4ee50b5d37955ffe7778938ddee82f4da24cbaf552b4dba3810d3c850a1
      guard[hermetic] source-path in  = /Users/feb/dev/.files/home
PASS  hermetic: precondition: nu is on PATH
PASS  hermetic: precondition: nu is the pinned 0.114.1 (nothing is installed or upgraded here)
PASS  hermetic: precondition: this gate's spelled-out MODULES list still equals config.nu's own `source` lines
PASS  hermetic: precondition: python3 is on PATH — the JSON is parsed by a second implementation, not only by nushell's own `from json`
PASS  hermetic: the machine holds NO config.nu and NO env.nu — that absence IS the no-`core-help` assertion, because `core-help` is an alias only config.nu binds
PASS  hermetic: `help --json` exits 0 under a bare `nu -n` with only help.nu sourced (rc=0, stderr 0 bytes)
PASS  hermetic: …and nushell's own `from json` round-trips it back to a record with `topics` and `entries` at the top level
PASS  hermetic: …and python3's json.load parses the same bytes — one document, two implementations
PASS  hermetic: .topics | length equals the staged topics.nuon row count — 9, read in this same run and never pinned
PASS  hermetic: .entries | length equals the staged corpus entry count — 96, counted over the four surface files in this same run
PASS  hermetic: …and equals `help --all | length`, which is what makes the PRD's "every entry visible in help --all is present in the JSON" a measurement rather than a hope
PASS  hermetic: every entry's `topic` is one of the spine's own ids — no entry claims a topic the document does not list
PASS  hermetic: EVERY entry carries exactly the eleven keys id key cmd title use topic mode also why verify source — no twelfth, none missing (0 entries disagree)
PASS  hermetic: …and `why`/`also` are PRESENT with the right type on entries that carry neither in the corpus — jq '.entries[].why' never hits a missing key
PASS  hermetic: …and BOTH shapes really occur, so the defaults are exercised rather than merely declared: 34 entries with an empty `why` and 18 with an empty `also`
PASS  hermetic: every entry carries a non-empty `key` OR a non-empty `cmd` — both are published because which one an entry has is itself information
PASS  hermetic: NO corpus row index is published — an index shifts whenever an entry is added, and an unstable handle inside a stable interface is worse than no handle
PASS  hermetic: [.entries[].id] equals `help --all | get key` element for element, so --json and --all cannot disagree about order
PASS  hermetic: the id carrying an apostrophe is present (1 such entries) with non-empty `use`, `why` and `source` — 03-browser had to address a row index for this id; here the document is complete instead
PASS  hermetic: `help --md` exits 0 under the same bare `nu -n` (rc=0, stderr 0 bytes, 1183 lines)
PASS  hermetic: …opening with an H1 and one line saying `help --json` is the same content, and NO count in it
PASS  hermetic: …one `## ` heading per topic in spine order, matching the staged spine's own id sequence
PASS  hermetic: …one `### <id>` per entry, 96 of them, and the id is UNQUOTED and UNBACKTICKED — one live id carries an apostrophe and no id needs fencing to survive markdown
PASS  hermetic: …and the host-only marker on EXACTLY the `mode: "terminal"` entries — 16 of them, counted from the staged corpus in this run (R6: marked, never hidden)
PASS  hermetic: …and NO `std/help` tail anywhere in the document — `core-help` is unbound here, and 28 command-kind entries would mean 28 shell-outs
PASS  hermetic: …every entry's `mode:` and `source:` lines are rendered, one per `### ` heading
PASS  hermetic: `help --json --mode nvim` narrows to the nvim subset — 29 of 96 entries, every one of them nvim*
PASS  hermetic: …while `topics` stays the whole spine, so a filtered document still names the topics its entries claim
PASS  hermetic: `help --md --mode nvim` renders the SAME subset — 29 `### ` headings against --json's 29 entries — and skips every topic the filter emptied (2 of 9 headings remain)
PASS  hermetic: `help --json --mode tmux` exits non-zero (rc=1) and the message names the four surfaces it does take
PASS  hermetic: `help --md --mode tmux` exits non-zero (rc=1) and the message names the four surfaces it does take
PASS  hermetic: `help --json ctrl-r` exits non-zero (rc=1) with a message naming `--json`
PASS  hermetic: `help --md ctrl-r` exits non-zero (rc=1) with a message naming `--md`
PASS  hermetic: `help --json --md` exits non-zero (rc=1) with a message naming `--md`
PASS  hermetic: `help --json --all` exits non-zero (rc=1) with a message naming `--all`
PASS  hermetic: `help --md --fuzzy` exits non-zero (rc=1) with a message naming `--fuzzy`
PASS  hermetic: `help --json --entry ls` exits non-zero (rc=1) with a message naming `--entry`
PASS  hermetic: `help --md --topic find` exits non-zero (rc=1) with a message naming `--topic`
PASS  hermetic: `help --json --delegate ls` exits non-zero (rc=1) with a message naming `--delegate`
PASS  hermetic: R3 `help --json` carries no 0x1b byte under capture (first ESC at index -1)
PASS  hermetic: R3 `help --md` carries no 0x1b byte under capture (first ESC at index -1)
PASS  hermetic: R3 `help (bare)` carries no 0x1b byte under capture (first ESC at index -1)
PASS  hermetic: bare `help` exits 0 with an empty stderr (rc=0) — no flag, no argument, which is what AGENTS.md tells an agent to run
PASS  hermetic: DISCOVERY — bare `help` names `help --json`, `help --md` and `idioms` each with that entry's CORPUS title, the four first keys with theirs, all 9 topics with computed counts, and both new flags appended to the go-deeper line. This is the check this node exists for: before it, an agent that ran `help` once never saw `idioms` at all
PASS  hermetic: INFORMING — the overview's `idioms` line NAMES 4 of the 8 bare words that entry's own `use` backticks (rg fd find tv), at or above the floor of 3. H.5 found the `For agents:` block ROUTED and did not INFORM; this is the check that holds that fix, and it types no tool name — both sides are read from the staged corpus
PASS  hermetic: …and neither render TYPES one — none of those bare words appears word-bounded in `_help_curated` or `_help_overview`, so the line informs FROM the corpus and there is still exactly one place those names live
PASS  hermetic: with the corpus renamed away, `help --json` raises (rc=1) naming the resolved path and `chezmoi apply` — it never renders an empty manual, which is the most expensive wrong answer help can give
PASS  hermetic: with the corpus renamed away, `help --md` raises (rc=1) naming the resolved path and `chezmoi apply` — it never renders an empty manual, which is the most expensive wrong answer help can give
PASS  hermetic: …while `help --delegate ls` still returns at clause 1 BEFORE any corpus read — with the corpus gone it fails on the unbound `core-help` alias (rc=1) and names no corpus path, so the escape hatch is corpus-free. Its rc-0 half needs a config.nu and belongs to tests/shell-help.sh
── counterfactuals: each mutation hashed, red before repair, hashed back
      CF use-renamed-to-usage: sha db54c04f19cd -> cf0ea4ca2e3f
PASS  cf: use-renamed-to-usage really changed the copy — a claimed mutation is not a made one
PASS  hermetic: CF use-renamed-to-usage FAILS norm_keys_ok in tests/help-agent.sh — the eleven-key list is an INTERFACE, and a rename is a breaking change that has to be recorded in the PRD's field list
PASS  hermetic: …and the RUN agrees rather than the text alone: every one of the 96 entries the mutated copy emits disagrees with the published key set
      CF use-renamed-to-usage repaired: sha db54c04f19cd (want db54c04f19cd)
PASS  cf: use-renamed-to-usage repaired — the sha is back
      CF md-calls-core-help: sha db54c04f19cd -> b43bae555bb8
PASS  cf: md-calls-core-help really changed the copy — a claimed mutation is not a made one
PASS  hermetic: CF md-calls-core-help FAILS no_core_help_ok in tests/help-agent.sh — `core-help` is an ALIAS defined in config.nu, so with no config loaded the name binds as an EXTERNAL at parse time
PASS  hermetic: …and the mutated copy really dies when RUN, which is what makes the text check above proof rather than decoration: `help --md` under `nu -n` exits non-zero on the unbound alias
      CF md-calls-core-help repaired: sha db54c04f19cd (want db54c04f19cd)
PASS  cf: md-calls-core-help repaired — the sha is back
      CF go-deeper-drops-help--json: sha db54c04f19cd -> 295521200761
PASS  cf: go-deeper-drops-help--json really changed the copy — a claimed mutation is not a made one
PASS  hermetic: CF go-deeper-drops-help--json FAILS go_deeper_ok in tests/help-agent.sh — the flags are APPENDED to 06-help/02's line, so losing one is visible in the text
PASS  hermetic: …and the rendered overview FAILS the discovery check too — the mutated copy prints an overview that never names `help --json`
      CF go-deeper-drops-help--json repaired: sha db54c04f19cd (want db54c04f19cd)
PASS  cf: go-deeper-drops-help--json repaired — the sha is back
      CF cc-also-drops-the-credentials-entry: sha 39d95caa5b31 -> 2f20251483f3
PASS  cf: cc-also-drops-the-credentials-entry really changed the copy — a claimed mutation is not a made one
PASS  hermetic: CF cc-also-drops-the-credentials-entry FAILS cc_also_ok in tests/help-agent.sh — R4's third bullet is met by exactly this value, and nothing else in the `agents` topic points at what a capsule hands an agent
PASS  hermetic: …and the rendered document agrees: the mutated corpus's `cc [...args]` entry no longer lists it in `also`
      CF cc-also-drops-the-credentials-entry repaired: sha 39d95caa5b31 (want 39d95caa5b31)
PASS  cf: cc-also-drops-the-credentials-entry repaired — the sha is back
      CF corpus-renames-the-idioms-entry: sha 39d95caa5b31 -> 68e0652cd04b
PASS  cf: corpus-renames-the-idioms-entry really changed the copy — a claimed mutation is not a made one
      CF corpus-renames-the-idioms-entry: the For agents: block silently lost a line — 2 remain under it (was 3)
PASS  hermetic: CF corpus-renames-the-idioms-entry FAILS the discovery check in tests/help-agent.sh, naming `idioms` — the curated render drops an id the corpus does not have, WITHOUT complaint, so renaming the one entry that says `rg`/`fd` over `grep`/`find` would silently take it out of the only output an agent reads
PASS  hermetic: …and the mutation was otherwise harmless — the mutated corpus still renders a full overview at rc 0, which is exactly why the loss is silent and has to be asserted
      CF corpus-renames-the-idioms-entry repaired: sha 39d95caa5b31 (want 39d95caa5b31)
PASS  cf: corpus-renames-the-idioms-entry repaired — the sha is back
      CF corpus-reverts-the-idioms-title-to-a-pointer: sha 39d95caa5b31 -> 261d783412dc
PASS  cf: corpus-reverts-the-idioms-title-to-a-pointer really changed the copy — a claimed mutation is not a made one
      CF corpus-reverts-the-idioms-title-to-a-pointer: the line now reads [  idioms — Use the tools this environment actually has]
PASS  hermetic: CF corpus-reverts-the-idioms-title-to-a-pointer FAILS the INFORMING check in tests/help-agent.sh — the `idioms` line stops naming any of the bare words its own `use` backticks, which is precisely the H.5 finding `0f9f635` fixed
PASS  hermetic: …and THIS is the hole the INFORMING check closes: the same reverted corpus still PASSES discovery_ok, because that check reads the expected title out of the same corpus in the same run, so any title matches itself. CF5 catches an id renamed away; nothing caught the line ceasing to inform
      CF corpus-reverts-the-idioms-title-to-a-pointer repaired: sha 39d95caa5b31 (want 39d95caa5b31)
PASS  cf: corpus-reverts-the-idioms-title-to-a-pointer repaired — the sha is back
      CF corpus-strips-the-backticks-out-of-the-idioms-use: sha 39d95caa5b31 -> 7648d7da68d7
PASS  cf: corpus-strips-the-backticks-out-of-the-idioms-use really changed the copy — a claimed mutation is not a made one
      CF corpus-strips-the-backticks-out-of-the-idioms-use: tool_words yields []
PASS  hermetic: CF corpus-strips-the-backticks-out-of-the-idioms-use FAILS the INFORMING check in tests/help-agent.sh — with no bare word left in `use` there is no evidence to weigh, and a check with nothing to assert has to be RED rather than vacuously green
PASS  hermetic: …and that red is the EMPTY EVIDENCE and not a lost title — the mutated corpus's `idioms` line is byte-identical to the unmutated one, so the two counterfactuals fail for two different reasons
      CF corpus-strips-the-backticks-out-of-the-idioms-use repaired: sha 39d95caa5b31 (want 39d95caa5b31)
PASS  cf: corpus-strips-the-backticks-out-of-the-idioms-use repaired — the sha is back
      guard[hermetic] sha256 out      = 02d5d4ee50b5d37955ffe7778938ddee82f4da24cbaf552b4dba3810d3c850a1
      guard[hermetic] source-path out = /Users/feb/dev/.files/home
PASS  hermetic: LIVE chezmoi.toml unchanged (02d5d4ee50b5d37955ffe7778938ddee82f4da24cbaf552b4dba3810d3c850a1)
PASS  hermetic: LIVE chezmoi source-path unchanged (/Users/feb/dev/.files/home)
── epilogue: the managed tree and the live machine are untouched
PASS  the managed files this node touches are byte-identical (help.nu, help/shell.nuon, config.nu)
PASS  the live ~/.config/nushell listing is unchanged — never edited, only read
PASS  ~/.cache/nushell does not exist (a real one appearing means an isolation leak)
EXIT=0
help content model: 96 entries across 4 files, 9 topics, 16 prose-only
╭───┬────────────┬─────────╮
│ # │   topic    │ entries │
├───┼────────────┼─────────┤
│ 0 │ navigate   │      12 │
│ 1 │ find       │      12 │
│ 2 │ history    │       4 │
│ 3 │ edit       │      29 │
│ 4 │ git        │       2 │
│ 5 │ terminal   │      13 │
│ 6 │ agents     │       6 │
│ 7 │ config     │       8 │
│ 8 │ containers │      10 │
╰───┴────────────┴─────────╯
ok
── stage --tree: the managed files as text
      guard[tree] watching /Users/feb/.config/chezmoi/chezmoi.toml
      guard[tree] sha256 in       = 02d5d4ee50b5d37955ffe7778938ddee82f4da24cbaf552b4dba3810d3c850a1
      guard[tree] source-path in  = /Users/feb/dev/.files/home
PASS  tree: help.nu is a regular file in the managed tree
PASS  tree: the corpus dir ships beside it with topics.nuon and the four surface files
PASS  tree: history.nu < 'use std/help' < 'alias core-help = help' < help.nu < PALETTE, each once (use at line 607)
PASS  tree: counterfactual use-std-help-below-the-shadow FAILS the order check
PASS  tree: help.nu is defs only — one 'def help [', no config-record write, no keybinding upsert
PASS  tree: counterfactual config-record-write-appended FAILS the purity check
PASS  tree: the RENDER path in help.nu spawns nothing — 0 hits for nvim, wezterm, git, tv or chezmoi in either spelling, and no $env.EDITOR, with _help_browse's body excised (R8)
PASS  tree: _help_browse is the ONLY def in help.nu that names a spawn target — got [_help_browse ]
PASS  tree: counterfactual git-spawn-inserted FAILS the re-scoped no-spawn check
PASS  tree: counterfactual git-spawn-inserted FAILS the only-spawner check
PASS  tree: the spawn-in-a-render-def counterfactual really differs from help.nu (a no-op sed would fake the two checks below)
PASS  tree: counterfactual tv-call-inside-a-render-def FAILS the re-scoped no-spawn check — the excision does not hide a spawn outside _help_browse
PASS  tree: counterfactual tv-call-inside-a-render-def FAILS the only-spawner check
PASS  tree: the corpus is addressed by $nu.home-dir joined with .config/nushell/help — neither launch-time candidate, no repo path, no developer home
PASS  tree: the pre-fix counterfactual really does differ from help.nu (a no-op sed would fake every check below it)
PASS  tree: counterfactual pre-fix-$nu.default-config-dir FAILS the corpus-path check
PASS  tree: counterfactual $nu.config-path-dirname FAILS the corpus-path check
PASS  tree: counterfactual hardcoded-repo-path FAILS the corpus-path check
PASS  tree: the mirror holds — config.nu sources ~/.config/nushell/help.nu (checked above, once) and help.nu names the same .config/nushell segments
PASS  tree: counterfactual .conf-instead-of-.config FAILS the mirror check
PASS  tree: tests/nushell-core.sh stages help.nu exactly once (config.nu sources it, so a hermetic run without it dies at parse)
PASS  tree: tests/nushell-aliases.sh stages help.nu exactly once (config.nu sources it, so a hermetic run without it dies at parse)
PASS  tree: tests/shell-listing.sh stages help.nu exactly once (config.nu sources it, so a hermetic run without it dies at parse)
PASS  tree: tests/shell-zoxide.sh stages help.nu exactly once (config.nu sources it, so a hermetic run without it dies at parse)
PASS  tree: tests/shell-history.sh stages help.nu exactly once (config.nu sources it, so a hermetic run without it dies at parse)
PASS  tree: tests/shell-claude.sh stages help.nu exactly once (config.nu sources it, so a hermetic run without it dies at parse)
PASS  tree: counterfactual staging-line-dropped FAILS the staging check
PASS  tree: shell.nuon carries the 'help' entry naming this PRD as its source
PASS  tree: the settled-collision rule replaced the 'not settled' caveat (spec02)
PASS  tree: …and the new why names the three disambiguators
PASS  tree: this gate left shell.nuon byte-identical
      guard[tree] sha256 out      = 02d5d4ee50b5d37955ffe7778938ddee82f4da24cbaf552b4dba3810d3c850a1
      guard[tree] source-path out = /Users/feb/dev/.files/home
PASS  tree: LIVE chezmoi.toml unchanged (02d5d4ee50b5d37955ffe7778938ddee82f4da24cbaf552b4dba3810d3c850a1)
PASS  tree: LIVE chezmoi source-path unchanged (/Users/feb/dev/.files/home)
── stage --hermetic: a real nushell, an isolated HOME, the corpus staged
      guard[hermetic] watching /Users/feb/.config/chezmoi/chezmoi.toml
      guard[hermetic] sha256 in       = 02d5d4ee50b5d37955ffe7778938ddee82f4da24cbaf552b4dba3810d3c850a1
      guard[hermetic] source-path in  = /Users/feb/dev/.files/home
PASS  hermetic: precondition: nu is on PATH
PASS  hermetic: precondition: nu is the pinned 0.114.1 (nothing is installed or upgraded here)
PASS  hermetic: precondition: python3 is on PATH (the JSON probe parses, never eyeballs)
      corpus: 9 topics, 96 entries
PASS  hermetic: the staged corpus is readable and non-empty (9 topics, 96 entries)
PASS  hermetic: 'help' exits 0 with nothing on stderr (rc=0)
PASS  hermetic: the overview lists all 9 topic ids with a summary
PASS  hermetic: the per-topic counts sum to the corpus entry count (96 = 96)
PASS  hermetic: the overview names the four first keys with their titles
PASS  hermetic: the overview carries the delegation sentence
PASS  hermetic: the overview names the ways to go deeper
PASS  hermetic: nu -c 'help' | complete carries no ESC byte (R7 — got index -1)
PASS  hermetic: 'help navigate' lists the zoxide suite with the bare-word fallback and all three listing entries
PASS  hermetic: 'help find | to json' parses as JSON and carries a 'key' column
PASS  hermetic: "help find | where key =~ 'Ctrl'" composes and finds rows (R2's own example)
PASS  hermetic: 'help selection' returns the shift-select entries, with a 'topic' column
PASS  hermetic: 'help select' delegates to std/help, because 'select' is a nushell builtin (clause 8)
PASS  hermetic: 'help ls' shows the manual's entry
PASS  hermetic: …and ends with std/help's own output for ls (Usage: and '> ls' in the tail, 43 lines total)
PASS  hermetic: 'help --entry ls' and 'ls --help' are byte-identical (R10 — indistinguishable at the call site)
PASS  hermetic: 'help ctrl-r' explains the directory scope and points at Alt-R
PASS  hermetic: 'help find' reaches OUR topic, not the builtin (a corpus-only entry id is present)
PASS  hermetic: 'help history' reaches OUR topic, not the builtin
PASS  hermetic: 'help config' reaches OUR topic, not the builtin
PASS  hermetic: 'help --delegate find' reaches the builtin's own help instead
PASS  hermetic: 'help commands | length' is over 400 — longest-match parsing keeps std's subcommand (got 617)
PASS  hermetic: 'fakecmd --help' prints the external stub's OWN usage (got: FAKECMD-OWN-USAGE: fakecmd [--flag])
PASS  hermetic: 'help --all --mode nvim' returns rows and every mode starts with nvim (got: nvim:normal,nvim:visual,nvim:insert)
PASS  hermetic: 'help --all --mode tmux' exits non-zero — the surface list is closed (rc=1)
PASS  hermetic: 'help "F5 <digit>"' renders the entry and marks it host-only
PASS  hermetic: 'timeit { help }' is under 100 ms inside the configured shell (got: fast, single sample: 5ms 900µs 458ns)
PASS  hermetic: 'help qqqxyzzy' exits 0 — clause 10 hands an unknown word to std's own search (rc=0)
PASS  hermetic: the poison 'tv' on PATH was never invoked across every probe above (got 0 invocations)
      guard[hermetic] sha256 out      = 02d5d4ee50b5d37955ffe7778938ddee82f4da24cbaf552b4dba3810d3c850a1
      guard[hermetic] source-path out = /Users/feb/dev/.files/home
PASS  hermetic: LIVE chezmoi.toml unchanged (02d5d4ee50b5d37955ffe7778938ddee82f4da24cbaf552b4dba3810d3c850a1)
PASS  hermetic: LIVE chezmoi source-path unchanged (/Users/feb/dev/.files/home)
── stage --noxdg: the same nushell with NO XDG_CONFIG_HOME exported
      guard[noxdg] watching /Users/feb/.config/chezmoi/chezmoi.toml
      guard[noxdg] sha256 in       = 02d5d4ee50b5d37955ffe7778938ddee82f4da24cbaf552b4dba3810d3c850a1
      guard[noxdg] source-path in  = /Users/feb/dev/.files/home
PASS  noxdg: precondition: nu is on PATH
      the launch-time constant under this launch = /private/var/folders/_p/tzmzw3m10kg7sg9hc7_mkm7w0000gn/T/gates.yKmJB8/m-noxdg/home/Library/Application Support/nushell
      the machine's own config dir               = /private/var/folders/_p/tzmzw3m10kg7sg9hc7_mkm7w0000gn/T/gates.yKmJB8/m-noxdg/home/.config/nushell
PASS  noxdg: the launch-time constant is NOT the machine's .config/nushell — the defect's signature, recorded rather than assumed
PASS  noxdg: 'help' exits 0 with nothing on stderr under a launch that exports no XDG_CONFIG_HOME (rc=0)
PASS  noxdg: the export-absent overview is byte-identical to the export-present one (1462 bytes)
PASS  noxdg: 'help --all | length' equals the staged corpus's own entry count (96 = 96)
PASS  noxdg: 'help "F5 <digit>"' still marks the terminal entry host-only (R9's marking half)
PASS  noxdg: the poison 'tv' on PATH was never invoked (got 0 invocations)
PASS  noxdg: the counterfactual machine really carries the pre-fix resolution (a no-op sed would fake the check below)
PASS  noxdg: counterfactual pre-fix-resolution FAILS 'help' under this launch (rc=1)
PASS  noxdg: the alt tree's own corpus really carries the marker (staging check)
PASS  noxdg: 'nu --config <tree outside .config>/config.nu' renders the MACHINE's corpus, not that tree's (rc=0, 0 marker hits)
PASS  noxdg: the dirname counterfactual machine really carries that resolution
PASS  noxdg: counterfactual $nu.config-path-dirname renders the ALT tree's marker — renderer and corpus from different trees (1 hits)
PASS  noxdg: corpus directory renamed away — 'help' raises with an empty stdout and a message naming the path, chezmoi apply and --delegate (rc=1)
      Error: nu::shell::error
      
        x help: the manual's corpus directory /private/var/folders/_p/
        | tzmzw3m10kg7sg9hc7_mkm7w0000gn/T/gates.yKmJB8/m-noxdg-loud/home/.config/
        | nushell/help is missing — run `chezmoi apply`; `help --delegate <name>`
        | still reaches nushell's own help
PASS  noxdg: …and the escape hatch is real: 'help --delegate ls' still exits 0 in that state (rc=0)
PASS  noxdg: topics.nuon replaced by [] — 'help' raises instead of rendering 'Topics:' with nothing under it (rc=1)
PASS  noxdg: a ZERO-BYTE topics.nuon raises with OUR message, not nushell's incompatible_path_access (rc=1)
PASS  noxdg: the four surface files replaced by [] — 'help' raises rather than rendering every topic as zero entries (rc=1)
PASS  noxdg: the no-guard counterfactual machine really differs from help.nu
PASS  noxdg: counterfactual help.nu-without-the-spine-length-guard renders the EMPTY manual instead — rc 0, empty stderr, 'Topics:' with nothing under it (rc=0)
      guard[noxdg] sha256 out      = 02d5d4ee50b5d37955ffe7778938ddee82f4da24cbaf552b4dba3810d3c850a1
      guard[noxdg] source-path out = /Users/feb/dev/.files/home
PASS  noxdg: LIVE chezmoi.toml unchanged (02d5d4ee50b5d37955ffe7778938ddee82f4da24cbaf552b4dba3810d3c850a1)
PASS  noxdg: LIVE chezmoi source-path unchanged (/Users/feb/dev/.files/home)
── epilogue: the live machine is untouched
PASS  config.nu, env.nu, help.nu and shell.nuon are byte-identical
PASS  the whole corpus directory is byte-identical, file by file
PASS  ~/.cache/nushell does not exist (a real one appearing means an isolation leak)
PASS  ~/Library/Application Support/nushell does not exist (where an export-absent nu writes when a runner forgets HOME)
CHECKS: 93 run, 93 passed, 0 failed
EXIT=0
