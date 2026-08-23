---
est: 0.25h
footprint:
  - prds/02-terminal/02-startup-layout/prd.md
  - prds/00-delivery/corrections/w0-2-terminal-respec/specs/spec03.md
executor: orchestrator   # both files are another PRD's body
verify: "bash gates/tree-links.sh"
---

# spec02 — the two board-tree carriers, corrected to the measured lifetime

Replace two passages with the pre-resolved text below. Both are another
PRD's body, so **the orchestrator makes this edit**; no implementer may
write another PRD's body.

The text is final. Do not re-derive it and do not re-measure: the fixture,
the numbers and the verdicts are in [`spec01`](spec01.md) under **The
measurement**, and `02-startup-layout` is `done` — this changes what its
requirements *say happened*, never what they demand.

**Match the text, not the line number.** Both line ranges were read on
2026-08-23 while three lanes were writing the tree. The quoted text is the
anchor.

**No box changes state.** Both requirements stay `[x]`, both keep their
number, no rating moves, and neither block adds a markdown link, so the
Tier A link delta is exactly zero.

## What changes, and why it is not the refutation on record

Both passages say a latched guard "silently disable[s] healing for the rest
of the session". [`spec01`](spec01.md) measured the guard: the claim is
right that a latch stops healing everywhere, and wrong only about how it
ends. It ends when this file is evaluated again — a successful reload does
that, and an unparseable one does not. The refutation that stood in this
node's own Purpose, "per-context, so not session-latched", is **refuted**:
0 of 268 fires reached a sibling context, so being per-context rescues
nothing.

`retired-phrase-sweep` row **RP9** bans
`silently disable healing for the rest of the session` and arms itself when
this node reaches `done`. Both passages below are outside this node's
folder, so both must lose the phrase or that gate goes red.

## Carrier 1 — `prds/02-terminal/02-startup-layout/prd.md`

Replace lines 78-89 — requirements **R7** and **R8** — with this. R6 above
and R9 below are untouched.

```markdown
- [x] **R7** — **A re-entrancy guard, with the failure it prevents.**
      `spawn_tab` and `perform_action` pump the event loop, so a nested pass
      saw a half-built window, concluded seven slots were missing, and filled
      them while the outer pass was still filling its own — **startup
      produced 16 tabs instead of 9**. The guard is deliberately
      module-local, not `wezterm.GLOBAL`, for two reasons. It only has to
      hold across a synchronous re-entry, which by definition happens in the
      same Lua context. And `wezterm.GLOBAL` survives the config reload that
      resets every local in this file, so a guard parked there would outlive
      the one event measured to clear a stuck one (R8).
- [x] **R8** — **`pcall` around the repair**, so a spawn failure (out of
      ptys, a bad `default_prog`) cannot leave the guard latched. Measured
      2026-08-23 on `20240203`: one evaluation of the config creates 2 Lua
      contexts (4 with three windows) and exactly one of them serves every
      trigger of that generation — 0 of 268 fires across 10 generations
      reached a sibling context — so a latched guard is read as latched by
      every later fire, in every window, including windows opened after it
      latched. Only re-evaluating the file clears it: a successful reload
      does, and every `tinty apply` is one because `colors.lua` is on the
      reload watch list; a config that fails to parse does not, because the
      body never runs. A `false` left in the map is harmless: the next pass
      reads it as a dead slot and retries.
```

## Carrier 2 — `w0-2-terminal-respec/specs/spec03.md`

Full path: `prds/00-delivery/corrections/w0-2-terminal-respec/specs/spec03.md`.

Replace lines 67-77 — bullets **B7** and **B8** — with this. B6 above and
B9 below are untouched.

```markdown
- [x] **B7 — a re-entrancy guard, with its failure.** `spawn_tab` and
      `perform_action` pump the event loop; a nested pass saw a half-built
      window, concluded seven slots were missing and filled them while the
      outer pass was still filling its own — **startup produced 16 tabs
      instead of 9**. Deliberately module-local, not `GLOBAL`, for two
      reasons: it only has to hold across a synchronous re-entry, which by
      definition happens in the same Lua context; and `GLOBAL` survives the
      config reload that resets every local in the file, so a guard parked
      there would outlive the one event measured to clear a stuck one.
- [x] **B8 — `pcall` around the repair**, so a spawn failure (out of ptys, a
      bad `default_prog`) cannot leave the guard latched. Measured
      2026-08-23: exactly one Lua context serves every trigger of a config
      generation, so a latched guard is read as latched by every later fire
      in every window, and only re-evaluating the file clears it — a
      successful reload does, an unparseable one does not. A `false` left in
      the map is harmless: the next pass reads it as a dead slot and
      retries.
```

## Not this spec's files

- `home/dot_config/wezterm/wezterm.lua` and
  `docs/capabilities-terminal.md` are [`spec01`](spec01.md)'s, and an
  implementer's.
- `prds/02-terminal/02-startup-layout/specs/spec01-tab-floor.md:95-98`
  states no duration. Not a carrier. Leave it.
- `prds/02-terminal/02-startup-layout/prd.md:68` and
  `w0-2-terminal-respec/specs/spec03.md:57` carry the *other* claim — "a
  module-local table reads back `nil` about as often as not". Seven
  carriers, its own node, `unmeasured` here. Do not touch those lines while
  editing the two files.
- This node's own `prd.md` Purpose states the refuted per-context reading as
  fact. Correcting it is the orchestrator's, in the same pass or in the
  closing note; an analyst may not write it.
- `gates/waves.tsv` and `gates/manual/wave*.md`. No new row is needed.

## Acceptance

- [ ] Both files carry their block verbatim, and
      `grep -c 'silently disable healing'` → `0` for each.
- [ ] No box changed state: both files still carry `- [x] **R7**` /
      `- [x] **R8**` and `- [x] **B7` / `- [x] **B8` respectively, and
      `grep -c '^- \[ \]' ` on `prds/02-terminal/02-startup-layout/prd.md`
      is unchanged from the pre-edit reading.
- [ ] Both blocks name the two things the measurement settles: that a
      latched guard is read as latched by every later fire, and that only a
      successful re-evaluation clears it.
- [ ] R7 and B7 each carry **both** reasons for the module-local — the
      synchronous re-entry *and* that `GLOBAL` would survive the reload.
      This is R4's answer, landed in the tree.
- [ ] `bash gates/tree-links.sh` reports **no new Tier A breakage**,
      asserted as a delta. Two readings minutes apart on 2026-08-23, both
      before any edit: exit 0, `checked 835 links in 135 files, 0 broken`;
      then exit **1**, `checked 839 links in 136 files, 2 broken`, both
      breaks belonging to another lane's
      `prds/00-delivery/corrections/mi-rooted-verify-commands/prd.md:110`
      and `:163`. This spec adds no markdown link, so its own delta is
      zero.
- [ ] No line of `02-startup-layout`'s requirements outside R7 and R8 moved:
      `cp prds/02-terminal/02-startup-layout/prd.md` aside before the edit,
      then `diff -q` after, with only the R7/R8 lines differing — quoted.
      `git diff -U0` cannot answer it: that file is untracked
      (`git ls-files --error-unmatch`, 2026-08-23), so "shows one hunk" is a
      claim about a diff that has no hunks at all. Unprovable in retrospect if
      the edit has already landed and no aside was kept — the pre-edit state
      was untracked, so git never held a copy. What would have proved it: the
      `cp` aside above, taken before the first write.

## Verify and Proof

```sh
# the retired phrase is gone from both carriers
grep -c 'silently disable healing' \
  prds/02-terminal/02-startup-layout/prd.md \
  prds/00-delivery/corrections/w0-2-terminal-respec/specs/spec03.md

# both reasons for the module-local are present
grep -n 'survives the config reload' \
  prds/02-terminal/02-startup-layout/prd.md
grep -n 'survives the' \
  prds/00-delivery/corrections/w0-2-terminal-respec/specs/spec03.md

# no box changed state
grep -c '^- \[x\]' prds/02-terminal/02-startup-layout/prd.md
grep -c '^- \[ \]' prds/02-terminal/02-startup-layout/prd.md

# one hunk each
git diff -U0 prds/02-terminal/02-startup-layout/prd.md \
  prds/00-delivery/corrections/w0-2-terminal-respec/specs/spec03.md \
  | grep -c '^@@'

# the gate
bash gates/tree-links.sh
```
