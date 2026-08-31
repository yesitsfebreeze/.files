---
complexity: 10
footprint:
  - prds/02-terminal/02-startup-layout/prd.md
  - prds/02-terminal/05-tab-content-state/specs/spec01.md
  - prds/00-delivery/corrections/w0-2-terminal-respec/specs/spec03.md
executor: orchestrator   # all three files are another PRD's body
verify: "bash gates/tree-links.sh"
---

# spec02 — the three board-tree carriers, corrected to the measured lifetime

Replace three passages with the pre-resolved text below. All three are
another PRD's body, so **the orchestrator makes these edits**; no implementer
may write another PRD's body.

The text is final. Do not re-derive it and do not re-measure: the fixture,
the numbers and the four verdicts are in [`spec01`](spec01.md) under
**R1 — the measurement, against the live config**. `02-startup-layout` and
`05-tab-content-state` are both `done` — this changes what their requirements
*say the reason is*, never what they demand.

**Match the text, not the line number.** All three line ranges were read on
2026-08-24 while other lanes were writing the tree. The quoted text is the
anchor.

**No box changes state.** Every box stays `[x]`, keeps its number, no rating
moves, and no block adds a markdown link, so the Tier A link delta is exactly
zero.

## What changes, and what deliberately does not

All three passages give the reason for `wezterm.GLOBAL` as "callbacks run in
whichever context is free, so a module-local reads back `nil` about as often
as not". Measured against an instrumented copy of the live config in two
isolated GUIs — 16 evaluations, 9 event kinds, 2770 fires — that is
**`refuted`**: 5 nil reads, every one a freshly evaluated context's first
fire, 0 of 2765 later fires, exactly one serving context at a time.

**The rule those passages defend is not in doubt and gets stronger.** A
module-local starts `nil` in every new context and every evaluation makes new
ones, so the slot map and the baseline map still have to live in
`wezterm.GLOBAL` — for **desired lifetime across a reload**, not for context
count. That is the sentence all three were missing, and it is what each block
below now carries. **Nothing moves into or out of `wezterm.GLOBAL`.**

## Carrier 1 — `prds/02-terminal/02-startup-layout/prd.md`

Replace lines 66-76 — requirement **R5**, from `- [x] **R5** — **Per-window
slot maps` through `rebuilt as a plain table and reassigned rather than
mutated in place.` — with this. R4 above and R6 below are untouched.

```markdown
- [x] **R5** — **Per-window slot maps in `wezterm.GLOBAL`, with both
      reasons.** `wezterm.GLOBAL` because the map must **survive a config
      reload**, which is a lifetime reason rather than a context-count one.
      Every evaluation of the config creates fresh Lua contexts (measured: 2
      per evaluation) and a module-local starts `nil` in each, so a local
      `slots` table is emptied by every reload — and every `tinty apply` is
      one, because `colors.lua` is on the reload watch list — leaving each
      pass to re-adopt the current tab order as gospel and destroying the one
      piece of state that has to survive. Measured 2026-08-24 on `20240203`
      against an instrumented copy of the live config in two isolated GUIs:
      exactly one context serves events at a time, dispatch never returns to
      an older one, and a module-local read back `nil` **5 times in 2770
      fires**, every one of them a freshly evaluated context's first fire.
      **Per window** because a single shared list had two windows reading
      each other's ids as dead slots and refilling forever. Values stay
      JSON-shaped (an array of integer ids under string keys), and a value
      read back out is a **copy** — assigning into it does not write through
      — so the map is rebuilt as a plain table and reassigned rather than
      mutated in place.
```

## Carrier 2 — `w0-2-terminal-respec/specs/spec03.md`

Full path:
`prds/00-delivery/corrections/w0-2-terminal-respec/specs/spec03.md`.
Replace lines 55-64 — bullet **B5**, from `- [x] **B5 — per-window slot maps`
through `rebuilt as a plain table and reassigned rather than mutated in
place.` — with this. B4 above and B6 below are untouched.

```markdown
- [x] **B5 — per-window slot maps in `wezterm.GLOBAL`, with both reasons.**
      `GLOBAL` because the map must **survive a config reload**: every
      evaluation of the config makes fresh Lua contexts and a module-local
      starts `nil` in each, so a local `slots` table is emptied by every
      reload — every `tinty apply` is one — and each pass then re-adopts the
      current tab order as gospel, destroying the one piece of state that has
      to survive. The reason is desired **lifetime**, not context count:
      measured 2026-08-24, one context serves every trigger at a time and a
      module-local read back `nil` 5 times in 2770 fires, always a fresh
      context's first fire. **Per window** because a single shared list had
      two windows reading each other's ids as dead slots and refilling
      forever. Values stay JSON-shaped (array of integer ids, string keys),
      and a value read back out is a **copy**, so the map is rebuilt as a
      plain table and reassigned rather than mutated in place.
```

## Carrier 3 — `prds/02-terminal/05-tab-content-state/specs/spec01.md`

Replace lines 98-105 — the Lua comment block from `-- The baselines live in
wezterm.GLOBAL for the reason the slot map above` through `-- value.` — with
this. Line 97 (`--`) and line 106 (`local function pane_programs()`) are
untouched.

This block mirrors the config comment that [`spec01`](spec01.md) Block B
lands, and must stay a faithful mirror of it — the only differences are this
spec's `htop` example in place of "a long-lived TUI", kept as written.

```lua
-- The baselines live in wezterm.GLOBAL for the reason the slot map above
-- records, and it is a LIFETIME reason: a module-local starts nil in every
-- new Lua context, and every config reload makes new ones (every `tinty
-- apply` is a reload), so a baseline map parked in a local would be emptied
-- on each -- and an empty baseline map re-learns against whatever is running
-- RIGHT NOW, which would record `htop` as a pane's own program and read that
-- tab as empty for as long as it ran. Not "whichever context is free":
-- measured, one context serves at a time -- see the slot map comment.
-- JSON-shaped, as GLOBAL requires: pane id as a string key, the executable
-- path as the value.
```

## Not this spec's files

- `home/dot_config/wezterm/wezterm.lua`, `docs/capabilities-terminal.md` and
  `tests/wezterm-tab-content-state.sh` are [`spec01`](spec01.md)'s, and an
  implementer's.
- `prds/02-terminal/02-startup-layout/specs/spec01-tab-floor.md:49-51` says
  "more than one Lua context and a local `slots` read back `nil`" with **no
  frequency and no dispatch rule**, and both clauses reproduce against this
  fixture. Not a carrier. Leave it.
- `prds/02-terminal/03-f5-jump-mode/prd.md:130` and
  `w0-2-terminal-respec/specs/spec04.md:80` carry a **different** claim —
  the F5 painter's callbacks running "in a different Lua context from the
  painter". Out of this node's contract. Do not touch them while editing
  `spec03.md`.
- `prds/00-delivery/corrections/pwd-closure-blast-radius/specs/spec02.md:228`
  reports the inconsistency rather than asserting either wording. Not a
  carrier.
- This node's own `prd.md` header still calls the claim `unmeasured`. Moving
  it to `refuted` is the orchestrator's, in the closing note; an analyst may
  not write it.
- `gates/waves.tsv` and `gates/manual/wave*.md`. No new row is needed.

## Acceptance

Executed by the orchestrator 2026-08-24. Readings quoted are the ones run,
pre-edit against `cp` asides taken immediately before the first replacement.

- [x] All three files carry their block verbatim, and
      `grep -c 'as often as not'` → `0` for each.

      ```
      pre : 02-startup-layout/prd.md 1 · 05-tab-content-state/spec01.md 1 · w0-2/spec03.md 1
      post: 02-startup-layout/prd.md 0 · 05-tab-content-state/spec01.md 0 · w0-2/spec03.md 0
      ```

- [x] No box changed state: `grep -c '^- \[x\]'` and `grep -c '^- \[ \]'` on
      `prds/02-terminal/02-startup-layout/prd.md` are identical to the
      pre-edit readings — quote both. Same for the two spec files' `- [x]`
      counts.

      ```
      02-startup-layout/prd.md   [x] 14 → 14 · [ ] 6 → 6
      05-tab-content-state/spec01.md  [x] 10 → 10 · [ ] 0 → 0
      w0-2-terminal-respec/spec03.md  [x] 14 → 14 · [ ] 0 → 0
      ```

- [x] All three blocks name the two things the measurement settles: that
      `GLOBAL` is chosen for **desired lifetime across a reload**, and that
      exactly one context serves events at a time (so the every-other-callback
      story is refuted). This is R4's sentence, landed in the tree.

      Matched wrap-insensitively (the phrases wrap across lines, so a
      per-line `grep -c` reads 0 on carrier 1 and is the wrong instrument):

      ```
      02-startup-layout/prd.md   "survive a config reload"      · one-context sentence 1
      05-tab-content-state/spec01.md  "LIFETIME reason"          · one-context sentence 1
      w0-2/spec03.md   "survive a config reload", "desired **lifetime**" · one-context sentence 1
      ```

- [x] Carrier 3's Lua block is a faithful mirror of `spec01` Block B: `diff`
      the two blocks and show the only differing lines are the `htop` example
      and the JSON-shape tail — quoted.

      Line-level `diff` reports a rewrap, which is an artefact of the
      substitution being a different width, so the comparison was taken at
      word level (`wezterm.lua:830-839` against `spec01.md:98-107`, both
      stripped of `-- ` and split on whitespace). The entire difference:

      ```
      71,73c71
      < a
      < long-lived
      < TUI
      ---
      > `htop`
      ```

      Nothing else differs — the JSON-shape tail is byte-identical in
      substance.

- [x] Nothing moved into or out of `wezterm.GLOBAL` in any of the three files
      (R4): `grep -c 'wezterm.GLOBAL\|`GLOBAL`'` per file is unchanged from
      the pre-edit reading, quoted both ways.

      ```
      GLOBAL occurrences   pre → post
      02-startup-layout/prd.md        5 → 5
      05-tab-content-state/spec01.md  9 → 9
      w0-2/spec03.md                  7 → 7
      ```

- [x] `bash gates/tree-links.sh` reports **no new Tier A breakage**, asserted
      as a delta and never as an absolute — quote the reading taken
      immediately before the edit beside the one after, and name any new
      BROKEN line's file. No block here adds a markdown link, so the delta is
      zero by construction.

      ```
      pre : Tier A 1045 links / 154 files / 0 broken · Tier B 537 / 289 / 119
      post: Tier A 1045 links / 154 files / 0 broken · Tier B 537 / 289 / 119
      delta 0; gate EXIT=0. No new BROKEN line, in either tier.
      ```

- [x] No line outside the three replaced passages moved: `cp` each file aside
      before the edit, then `diff` after, with only the named line ranges
      differing — quoted. `git diff` cannot answer it for the untracked
      files, and other lanes carry uncommitted edits to the tracked ones.

      Exactly one hunk per file, each inside its named range:

      ```
      02-startup-layout/prd.md        67,76c67,84   (spec names 66-76)
      05-tab-content-state/spec01.md  99,105c99,107 (spec names 98-105)
      w0-2/spec03.md                  56,64c56,68   (spec names 55-64)
      ```

## Verify and Proof

```sh
# aside copies first — this is the only thing that can prove the boxes below
for f in prds/02-terminal/02-startup-layout/prd.md \
         prds/02-terminal/05-tab-content-state/specs/spec01.md \
         prds/00-delivery/corrections/w0-2-terminal-respec/specs/spec03.md; do
  cp "$f" "/tmp/aside-$(basename "$(dirname "$f")")-$(basename "$f")"
done

# the refuted wording is gone from all three carriers
grep -c 'as often as not' \
  prds/02-terminal/02-startup-layout/prd.md \
  prds/02-terminal/05-tab-content-state/specs/spec01.md \
  prds/00-delivery/corrections/w0-2-terminal-respec/specs/spec03.md

# the replacement reason is present in all three
grep -n 'survive a config reload\|LIFETIME reason\|lifetime' \
  prds/02-terminal/02-startup-layout/prd.md \
  prds/02-terminal/05-tab-content-state/specs/spec01.md \
  prds/00-delivery/corrections/w0-2-terminal-respec/specs/spec03.md

# no box changed state
grep -c '^- \[x\]' prds/02-terminal/02-startup-layout/prd.md
grep -c '^- \[ \]' prds/02-terminal/02-startup-layout/prd.md

# nothing moved into or out of GLOBAL
grep -c 'GLOBAL' \
  prds/02-terminal/02-startup-layout/prd.md \
  prds/02-terminal/05-tab-content-state/specs/spec01.md \
  prds/00-delivery/corrections/w0-2-terminal-respec/specs/spec03.md

# only the named ranges moved
for f in prds/02-terminal/02-startup-layout/prd.md \
         prds/02-terminal/05-tab-content-state/specs/spec01.md \
         prds/00-delivery/corrections/w0-2-terminal-respec/specs/spec03.md; do
  diff "/tmp/aside-$(basename "$(dirname "$f")")-$(basename "$f")" "$f"
done

# the gate
bash gates/tree-links.sh
```
