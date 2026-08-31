---
complexity: 8
footprint:
  - docs/capabilities-terminal.md
executor: orchestrator   # outside the PRD's declared footprint — see below
verify: "bash gates/tree-links.sh"
---

# spec02 — the third carrier the frontmatter does not list

`docs/capabilities-terminal.md:434-436` carries the same claim as the two
files [`spec01`](spec01.md) corrects, with `since` where they say `because`:

```
  repaints). Nothing is painted on a single-pane tab. The saved cells live in
  `GLOBAL` keyed by pane id, since the callbacks run in a different Lua
  context from the painter and a pane id survives a tab switch. All 26 letters
```

**Read this before executing.** This file is **not** in the PRD's
`footprint:`, which lists only `prds/02-terminal/03-f5-jump-mode/prd.md` and
`w0-2-terminal-respec/specs/spec04.md`. The analyst found it while measuring
and may not edit frontmatter, so the choice is the orchestrator's: extend the
footprint and apply the block, or split this carrier into its own node. What
is not an option is leaving it, quietly, as the one place the refuted reason
still reads as an assertion — that is the failure mode
[`wezterm-context-pool-claim`](../../wezterm-context-pool-claim/prd.md) cost
seven carriers to fix. Whichever route is taken, say which in the closing
note.

**The measurement is done, and it is not repeated here.** The fixture, the
numbers and the four verdicts are in [`spec01`](spec01.md) under
**R1 — the measurement, against the config that still carries the painter**.
Do not re-run the probe for this spec; `spec01` runs it once for the node.

**No box changes state** — this file's F5 entry carries none — no rating
moves, the entry keeps its `SIMPLIFY` marker and its `- 9` / `- 8` numbers
(complexity 9, usefulness 8, on lines 459-460), and the block adds no
markdown link, so the Tier A delta is exactly zero.

## Block C — the `## F5 jump-select  SIMPLIFY` entry

Replace lines 434-436 — from `repaints). Nothing is painted on a single-pane
tab. The saved cells live in` through `context from the painter and a pane id
survives a tab switch. All 26 letters` — with this. Line 433 above and line
437 (`are bound, not just the ones a pane has, …`) are untouched, so the
paragraph still runs. **Match the text, not the line number**: the range was
read on 2026-08-24 against a tree carrying other lanes' uncommitted edits.

```markdown
  repaints). Nothing is painted on a single-pane tab. The saved cells live in
  `GLOBAL` keyed by pane id for **lifetime**, not for context count: a
  module-local starts `nil` in every newly evaluated Lua context, every
  config reload makes new ones, and a reload landing inside the 5000 ms
  window (every `tinty apply` is one, because `colors.lua` is on the watch
  list — and F6 runs `tinty apply`) would strand the labels on screen with no
  saved text to put back. The pane-id key is the other half and it stands: a
  pane id survives a tab switch. The older wording — "the callbacks run in a
  different Lua context from the painter" — is **refuted**. Measured
  2026-08-24 on `20240203` against an **instrumented copy of the deployed
  `~/.config/wezterm/wezterm.lua`**, the only tree that still carries the
  painter, in two isolated `wezterm-gui` processes: 10 evaluations, **117
  handler fires**, **9 complete painter chains, 0 of them split across
  contexts**. The painter's `config.keys` callback, `paint_labels`, the
  key-table digit and letter callbacks, `unpaint_labels` and the
  `update-right-status` sweep on the timeout exit all ran in the same
  context, with exactly one context serving events at a time. A physical
  keypress is the one segment no probe can drive; that hop is recorded
  unmeasured rather than covered by the refutation. All 26 letters
```

## Not this spec's files

- `prds/02-terminal/03-f5-jump-mode/prd.md` and
  `w0-2-terminal-respec/specs/spec04.md` are [`spec01`](spec01.md)'s.
- `docs/capabilities-terminal.md:67-84` already carries the sibling node's
  corrected `wezterm.GLOBAL` constraint bullets. **Do not touch them** — they
  are a *different* claim, already settled, and Block C deliberately does not
  restate them.
- `~/.config/wezterm/wezterm.lua`. Read-only, and out of scope.

## Acceptance

- [x] The orchestrator's route is recorded in one sentence.

      **The footprint was extended and Block C applied here.** The alternative
      — splitting one line of prose into its own node — would have grown the
      derived tree by one while the tripwire is live, to correct a sentence
      identical to the two this node was already correcting. The frontmatter
      now lists `docs/capabilities-terminal.md` as a third footprint entry.

- [x] `docs/capabilities-terminal.md` carries Block C, and the assertive
      wording is gone.

      Wrap-insensitively (`tr '\n' ' ' | tr -s ' '`):

      ```
      "since the callbacks run in a different Lua context"  1 → 0
      "different Lua context"                               1 → 1
      ```

      The surviving hit is Block C's own retirement clause — a **mention**,
      not a **use**, the distinction `launchd-path-phrase-guard` and
      `stale-mi-keeplist-ruling` already ruled on.

- [x] The file's markdown link count is unchanged at **7**. `(../../../../../../prds/00-delivery/corrections/f5-context-claim/specs/ 7 → 7`.

- [x] The entry's rating is untouched.

      ```
      421:## F5 jump-select  SIMPLIFY
      - 9
      - 8
      ```

      Heading still carries `SIMPLIFY`; the two rating lines still close the
      entry.

- [x] The sibling node's `wezterm.GLOBAL` bullets are byte-identical:
      `grep -c 'as often as not'` reads **1** before and **1** after — the
      single hit is `wezterm-context-pool-claim`'s own quotation of the
      wording it retired, at line 80, undisturbed.

- [x] `bash gates/tree-links.sh` Tier A shows a zero delta: **0 broken**
      before and after, and no BROKEN line names this file. The corpus size
      moved (1057 → 1058) because a concurrent lane is rewriting the walker;
      the broken count, which is what this box is about, did not.

## Verify and Proof

```sh
cd "$(git rev-parse --show-toplevel)"
f=docs/capabilities-terminal.md
T=$(tr '\n' ' ' < "$f" | tr -s ' ')
echo "assertive: $(echo "$T" | grep -o 'since the callbacks run in a different Lua context' | wc -l | tr -d ' ')"   # 1 -> 0
echo "mentions : $(echo "$T" | grep -o 'different Lua context' | wc -l | tr -d ' ')"                                 # 1 -> 1
grep -o '(../../../../../../prds/00-delivery/corrections/f5-context-claim/specs/' "$f" | wc -l                    # 7, unchanged
grep -c 'as often as not' "$f"               # 1, unchanged (the sibling's own quotation)
grep -n '^## F5 jump-select' "$f"                                    # 421: ...  SIMPLIFY
awk '/^## F5 jump-select/{f=1} f&&/^----$/{exit} f' "$f" | tail -3   # ... / - 9 / - 8
bash gates/tree-links.sh | grep 'TIER A' -A1
```
