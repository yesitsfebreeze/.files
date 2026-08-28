---
state: blocked
claim:
priority: 8
est: 1.25h
task: H.5
mode: afk
needs:
  - 06-help/03-browser
  - 00-delivery/finish-line/agent-overview-derived-tools
verify: "bash tests/help-agent.sh"
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
- [ ] A fresh agent session, given only the output of `help`, can navigate
      (bare-word jump), find a file (`Ctrl-Space` or telescope), and start a
      capsule — without inventing a tool that isn't installed.

      **Owed as a manual gate, not fakeable green.** This is a reading, not a
      command: the box belongs in `gates/manual/wave6.md` as H.5, and that
      file is the orchestrator's. The machinery it needs is in place and
      measured — bare `help` now names `idioms` with its corpus title, so the
      "reach for `fzf`" failure has a line in the only output the box allows
      the session to see.
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

## Questions (answered 2026-08-28)

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
