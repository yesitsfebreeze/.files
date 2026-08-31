---
est: 0.5h
footprint:
  - home/dot_config/wezterm/wezterm.lua
  - docs/capabilities-terminal.md
verify: "bash tests/wezterm-startup-layout.sh && bash gates/tree-links.sh"
---

# spec01 — the guard's lifetime, measured, in the config and the inventory

Replace two comment blocks in `home/dot_config/wezterm/wezterm.lua` and one
clause plus one new bullet in `docs/capabilities-terminal.md` with the
pre-resolved text below. **No line of Lua code changes.** The guard stays
where it is and keeps its shape: this spec edits comments and prose only.

The measurement is done. Do not re-derive it. Re-run the probe in **Verify
and Proof** once, quote its four numbers, and apply the blocks verbatim.

**Match the text, not the line number.** Every line number below was read
on 2026-08-23 against a working tree that already carries uncommitted edits
from other lanes, and three lanes are writing. Each block quotes the lines
it replaces, and the quoted text is the anchor.

The two board-tree carriers of the same claim are
[`spec02`](spec02.md), which the **orchestrator** executes.

## The claim, and what the record said about it

`home/dot_config/wezterm/wezterm.lua:293-296` says a latched `pcall` guard
"would silently disable healing for the rest of the session".
[`pwd-closure-blast-radius`](../../pwd-closure-blast-radius/prd.md) read two
contradicting comments in the same file — `:196-202` ("deliberately a
module-local, not GLOBAL … the same Lua context") and `:973-974` (GLOBAL
"survives the reload that resets every local in this file") — and concluded
the guard is **per-context and reload-scoped, not session-latched**.

That refutation was textual. Measured, one half of it holds and the other
half is wrong in the direction that matters: **the per-context half buys
nothing**, because a config generation's triggers are all served by one
context, so there is no sibling context left healing.

## The measurement

2026-08-23, WezTerm `20240203-110809-5046fc22`, macOS. Three independent
`wezterm-gui` processes, each started `env -i` with a scratch `HOME`,
`--always-new-process` and its own probe config file. The probe keeps its
context identity in a Lua **global** (`_G`), which survives a re-evaluation
of the file inside the same context, and a module-local `latched` flag with
the shape of `repairing`, set `true` by every handler and never released.
Every fire appends generation, context id, `latched` and window id to a log
outside the config directory. 10 config generations, 1-3 windows, 7 event
kinds (`gui-startup`, `window-config-reloaded`, `update-status`,
`update-right-status`, `window-focus-changed`, `format-tab-title`,
`format-window-title`), **268 fires**.

| Question | Measured |
|---|---|
| Lua contexts per config evaluation | **2** with one window, **4** with three. Every context runs the file body once (`evals=1` on every line), so each has its own `repairing` |
| Contexts that serve events | **1 per generation, in all 10 generations.** Sibling contexts served **0** fires |
| Does a busy context spill to a sibling | **No.** An 800 ms busy-wait held inside `update-status` against a 200 ms tick: 32 fires, still one context, enter/leave pairs never interleaved |
| Is a latched guard read as latched later | **Yes.** `latched=false` occurred **10 times in 268 fires** — always fire #1 of a generation, never later |
| Does a new window reset it | **No.** `window-config-reloaded` fires per window at birth with **no** new evaluation; windows 1 and 2 read `latched=true` on their first fire |
| Does a successful reload clear it | **Yes.** 6 reloads, each producing fresh contexts and `latched=false` on the first fire after it. The old generation's contexts logged nothing more |
| Does a failed reload clear it | **No.** A config with a syntax error produced **0** lines for that generation; the previous generation kept serving with `latched=true` |
| Is the mux process involved | **No.** `wezterm-mux-server` evaluates the file in exactly **1** context and serves `mux-startup` there. The repair path never runs there — all four of its triggers are GUI events |

**The reload is not hypothetical.** `home/dot_config/wezterm/wezterm.lua:694`
puts `colors.lua` on the reload watch list, so every `tinty apply` is a
successful reload of this config.

### The fixture trap, and the A/B that found it

The first consolidated probe run reported **55 contexts per generation and
28 of them serving events** — the opposite conclusion. The single difference
was where the probe wrote its log: a file in the **config file's own
directory** makes WezTerm re-evaluate the config on every write, so the
probe manufactured a reload storm and read it as a context pool. Same
script, one variable changed:

| log location | evaluations per generation | serving contexts | fires reading `latched=false` |
|---|---|---|---|
| outside the config dir | 2 | 1 | 2 of 66 |
| inside the config dir | 56 and 46 | 51 | 51 of 865 |

The storm run is what settles the mechanism, so it is kept as evidence
rather than discarded. In its 865 fires, `latched=false` appeared **51
times, every one of them on a context's first fire** (0 on a later fire of
a known context), and dispatch returned to an older context **0** times.
There is no observed case of the guard reading unlatched other than
immediately after this file is evaluated again.

Any re-measurement writes its log outside the config directory, or it
measures its own log writes.

## Verdicts, in the census vocabulary

- "A latched guard stops healing for every later trigger, in every window" —
  `reproduced (3 isolated GUI processes, 10 config generations, 1-3 windows,
  7 event kinds, 268 fires, one 800 ms busy-wait handler)`.
- "for the rest of the session" — `refuted (6 successful reloads: fresh
  contexts, first fire latched=false)` and `reproduced (1 unparseable
  reload: 0 evaluations, the latch survives)`.
- The record's rescue, "per-context, so a sibling context keeps healing" —
  `refuted (0 of 268 fires reached a sibling context; 0 returns to an older
  context across an 865-fire storm)`.

## R4 — the `wezterm.GLOBAL` question, answered

**`repairing` stays a module-local. It is deliberate, not a latent bug, and
it is not moved.** The recorded reason is right and incomplete. Two reasons
hold it:

1. It only has to hold across a synchronous re-entry, which by definition
   happens in the same Lua context — and measured, dispatch never leaves
   that context, so there is no sibling pass to guard against.
2. `wezterm.GLOBAL` would be **strictly worse**. GLOBAL survives the reload
   that resets every local in this file (`:973-974`), so a guard parked
   there would outlive the only event measured to clear a stuck one.

[`05-tab-content-state`](../../../../02-terminal/05-tab-content-state/prd.md)
puts its baseline map in GLOBAL for the opposite requirement: that map has
to **survive** a reload. The difference is the desired lifetime, not the
context count. Block A below adds reason 2 to the comment, which is what R4
asks for.

## Block A — `home/dot_config/wezterm/wezterm.lua`, the guard comment

Replace lines 196-202 — the seven comment lines above `local repairing =
false` — with this. Line 203 (`local repairing = false`) is untouched.

```lua
-- Re-entrancy guard. spawn_tab and perform_action pump the event loop, which
-- re-fires the repair triggers and calls us again in the middle of a repair.
-- A nested pass saw a half-built window -- two tabs, say -- concluded seven
-- slots were missing, and filled them while the outer pass was still filling
-- its own: startup produced 16 tabs instead of 9 before this guard. This one
-- is deliberately a module-local, not GLOBAL, for two reasons. It only has
-- to hold across a synchronous re-entry, which by definition happens in the
-- same Lua context. And GLOBAL survives a config reload (see the theme
-- block) while a local does not, so a guard parked in GLOBAL would outlive
-- the one event measured to clear a stuck one -- see the pcall below.
```

## Block B — `home/dot_config/wezterm/wezterm.lua`, the pcall comment

Replace lines 293-296 — the four comment lines between `repairing = true`
and `local done, err = pcall(function()` — with this. Both surrounding code
lines are untouched.

```lua
    -- pcall so a spawn failure (out of ptys, bad default_prog) can't leave
    -- the guard latched. Measured 2026-08-23 on 20240203 with a probe
    -- config in an isolated GUI: one evaluation of this file creates 2 Lua
    -- contexts (4 with three windows), and exactly one of them serves every
    -- trigger of that generation -- 0 of 268 fires reached a sibling, even
    -- with an 800 ms busy-wait held inside update-status. So a latched local
    -- is read as latched by every later fire, in every window, including
    -- windows opened after it latched, and only a re-evaluation of this file
    -- clears it: a reload does (every tinty apply is one, via the colors.lua
    -- watch), and a config that fails to parse does not, because the body
    -- never runs. A `false` left in the map is harmless: the next pass reads
    -- it as a dead slot and retries the refill.
```

## Block C — `docs/capabilities-terminal.md`, the clause

In `## Self-healing nine-tab floor`, replace lines 503-506 with this. Line
502 (`pump the event loop and a nested pass saw a half-built window and
filled its`) and line 507 (`on **by id** after the rebuild rather than
snapping you onto a blank`) are untouched, so the sentence still reads
through.

```markdown
  own holes — startup produced 16 tabs instead of 9; `pcall` around the
  repair, so a spawn failure cannot leave the guard latched — measured, a
  latched guard stops healing in every window until this file is evaluated
  again (see the next bullet); and focus handling that re-asserts the tab
  you were
```

## Block D — `docs/capabilities-terminal.md`, the measurement bullet

Insert this bullet immediately after the `- Verified live with `wezterm cli
list`:` bullet, which ends at line 516 with `repositioning working, not
appending.` — so it lands before the `- `SIMPLIFY`:` bullet. The entry's
two rating lines stay last and unchanged at `- 10` and `- 7`.

```markdown
- **The guard's lifetime, measured 2026-08-23 on `20240203`.** One
  evaluation of `wezterm.lua` creates **2** Lua contexts (4 with three
  windows) and each runs the file body once, so each holds its own
  `repairing` — but **exactly one context serves every trigger of that
  generation**: 0 of 268 fires across 10 generations, 1-3 windows and 7
  event kinds reached a sibling, including with an 800 ms busy-wait held
  inside `update-status` against a 200 ms tick. So a latched guard is read
  as latched by every later fire, in every window, including windows opened
  after it latched — `latched=false` occurred 10 times in 268 fires, always
  the first fire after an evaluation. Only re-evaluating the file clears it:
  a successful reload does, and every `tinty apply` is one because
  `colors.lua` is on the reload watch list; a config that fails to parse
  does **not**, because the body never runs. The probe that measures this
  writes its log **outside** the config directory — a write inside it
  re-triggers the reload, and the storm reads exactly like a context pool
  (56 evaluations and 51 serving contexts per generation, against 2 and 1).
```

## Not this spec's files

- `prds/02-terminal/02-startup-layout/prd.md` R7/R8 and
  `prds/00-delivery/corrections/w0-2-terminal-respec/specs/spec03.md`
  B7/B8 carry the same claim. Both are another PRD's body:
  [`spec02`](spec02.md), executed by the orchestrator.
- `prds/02-terminal/02-startup-layout/specs/spec01-tab-floor.md:95-98` says
  "must not latch the guard and silently disable healing" and states **no
  duration**. It is not a carrier. Leave it alone.
- `~/.config/wezterm/wezterm.lua:200-203` and `:292-296` carry the same
  comments. Read-only reference. Do not edit it.
- `gates/waves.tsv` and `gates/manual/wave*.md` belong to the orchestrator.
  No new row is needed: `tests/wezterm-startup-layout.sh` and
  `gates/tree-links.sh` already run, and neither asserts comment prose.
- **`docs/capabilities-terminal.md:67-76`**, the `wezterm.GLOBAL`
  constraint, says callbacks run "in whichever is free, so a module-local
  table reads back `nil` about as often as not". This fixture measured 0 of
  268 fires reaching a sibling context, so that reason does not reproduce
  here — but it was recorded against the **live** config, which this probe
  is not, and the same wording stands in six more places
  (`wezterm.lua:124-126` and `:812`,
  `prds/02-terminal/02-startup-layout/prd.md:68`,
  `prds/02-terminal/05-tab-content-state/specs/spec01.md:100`,
  `prds/00-delivery/corrections/w0-2-terminal-respec/specs/spec03.md:57`,
  `tests/wezterm-tab-content-state.sh:286-288`). Verdict `unmeasured (probe
  config, not the live one)`. That is its own correction node with seven
  carriers and a gate that asserts the reason. **Do not touch any of those
  lines here**, and do not weaken the GLOBAL rule itself: the slot maps and
  the baseline map must survive a reload, which this measurement confirms a
  local does not.

## Acceptance

- [x] `home/dot_config/wezterm/wezterm.lua` carries Block A and Block B
      verbatim, and **no code line changed**: `git diff -U0
      home/dot_config/wezterm/wezterm.lua` shows only comment lines, and
      `grep -c 'repairing'` is still **4** (the declaration, the early
      return, the set, the release).
- [x] The retired phrase is gone from both files:
      `grep -c 'silently disable healing'
      home/dot_config/wezterm/wezterm.lua docs/capabilities-terminal.md`
      → `0` for each. This is `retired-phrase-sweep` row **RP9**, which
      arms itself when this node reaches `done`.
- [x] `docs/capabilities-terminal.md` carries Blocks C and D, and the
      entry's last two list items are still `- 10` then `- 7`:
      `awk '/^## Self-healing nine-tab floor/,/^----/'
      docs/capabilities-terminal.md | grep -E '^- [0-9]+$'`.
- [x] The file's markdown link count is unchanged at **7** — neither block
      adds a link: `grep -o '(../../../../../../prds/00-delivery/corrections/wezterm-repairing-latch-claim/specs/' docs/capabilities-terminal.md | wc -l`
      → `7`.
- [x] `bash tests/wezterm-startup-layout.sh` → `ALL PASS`, asserted as a
      delta against the pre-edit run. Baseline 2026-08-23: `ALL PASS`,
      including the two R7/R8 rows (`local repairing = false` present, no
      `GLOBAL` on that line, `pcall` present, `tab reconcile failed`
      present).
- [x] `bash gates/tree-links.sh` reports **no new Tier A breakage**,
      asserted as a delta and never as an absolute. Two readings taken
      minutes apart on 2026-08-23, both before any edit here: exit 0, Tier A
      `checked 835 links in 135 files, 0 broken`; then exit **1**, Tier A
      `checked 839 links in 136 files, 2 broken`. Both broken links belong
      to another lane —
      `prds/00-delivery/corrections/mi-rooted-verify-commands/prd.md:110`
      and `:163` point at `stale-mi-keeplist-ruling` and
      `done-node-proof-gate`, which do not exist yet. This spec adds no
      markdown link at all, so its own delta is zero: quote the reading
      taken immediately before the edit next to the one after, and name any
      new BROKEN line's file. Tier B's 114 broken links are pre-existing,
      all under `specs/**`, and never gate.
- [x] The probe re-run is quoted with four numbers: evaluations per
      generation, serving contexts per generation, `latched=false` count
      against total fires, and log lines for the unparseable generation.
      Expect **2**, **1**, **1 per generation**, **0**.
- [x] No probe process is left running: `pgrep -f wezterm` names only the
      user's own GUI. Never `pkill wezterm-mux-server`.

## Verify and Proof

```sh
# --- the probe. Writes nothing into the repo tree. Opens one small GUI
# --- window for about 20 s and kills it again.
cat > /tmp/wzprobe.sh <<'SH'
set -u
D=$(mktemp -d); H=$(mktemp -d); O=$(mktemp -d)   # short paths: SUN_LEN
L=$O/probe.log; CFG=$D/wezterm.lua                # log OUTSIDE the config dir
gen() {
  cat > $CFG <<LUA
local wezterm = require 'wezterm'
local LOG, GEN = "$L", "$1"
if _G.CTX == nil then _G.CTX = tostring({}):gsub("table: 0x", ""); _G.N = 0 end
_G.N = _G.N + 1
local latched = false
local function say(w, win)
  local id = "-"
  pcall(function() if win and win.window_id then id = tostring(win:window_id()) end end)
  local f = io.open(LOG, "a")
  f:write(string.format("%-24s gen=%s ctx=%s evals=%d latched=%s win=%s\n",
    w, GEN, _G.CTX, _G.N, tostring(latched), id))
  f:close()
end
say("EVAL")
for _, ev in ipairs({ "gui-startup", "window-config-reloaded", "update-status",
                      "update-right-status", "window-focus-changed" }) do
  wezterm.on(ev, function(a) say("EV " .. ev, a); latched = true end)
end
wezterm.on("format-tab-title", function(t) say("EV format-tab-title"); latched = true; return " t " end)
return { default_prog = { "/bin/sh", "-c", "while :; do sleep 5; done" },
         automatically_reload_config = true, status_update_interval = 200,
         initial_cols = 60, initial_rows = 12, check_for_updates = false }
LUA
  [ "${2:-}" = broken ] && echo 'this is not lua ((( ' >> $CFG
}
gen g1
env -i HOME=$H PATH=/usr/bin:/bin:/usr/sbin:/sbin \
  /Applications/WezTerm.app/Contents/MacOS/wezterm-gui \
  --config-file $CFG start --always-new-process >$D/gui.out 2>&1 &
G=$!
sleep 6;  gen g2           # a successful reload
sleep 5;  gen g3 broken    # a reload that cannot parse
sleep 6
echo "evaluations per generation:"; awk '/EVAL/{print $2}' $L | sort | uniq -c
echo "serving contexts per generation:"
  grep '^EV ' $L | sed 's/.*\(gen=[^ ]*\).*\(ctx=[^ ]*\).*/\1 \2/' | sort -u
echo "fires: $(grep -c '^EV ' $L)  reading latched=false: $(grep '^EV ' $L | grep -c latched=false)"
echo "lines for the unparseable generation g3: $(grep -c gen=g3 $L)"
echo "last three lines:"; tail -3 $L
[ -f $H/.local/share/wezterm/pid ] && kill "$(cat $H/.local/share/wezterm/pid)" 2>/dev/null
kill $G 2>/dev/null; sleep 1
echo "probe processes left:"; pgrep -f "$CFG" || echo none
SH
bash /tmp/wzprobe.sh

# --- the retired phrase is gone from both carriers in this footprint
grep -c 'silently disable healing' home/dot_config/wezterm/wezterm.lua \
                                  docs/capabilities-terminal.md

# --- the code did not move
grep -c 'repairing' home/dot_config/wezterm/wezterm.lua        # 4
git diff -U0 home/dot_config/wezterm/wezterm.lua | grep -E '^[+-][^+-]' \
  | grep -v -- '^[+-] *--'                                     # no output

# --- the rating and the link count did not move
awk '/^## Self-healing nine-tab floor/,/^----/' docs/capabilities-terminal.md \
  | grep -E '^- [0-9]+$'                                       # - 10 then - 7
grep -o '(../../../../../../prds/00-delivery/corrections/wezterm-repairing-latch-claim/specs/' docs/capabilities-terminal.md | wc -l             # 7

# --- the gates
bash tests/wezterm-startup-layout.sh
bash gates/tree-links.sh

# --- nothing of ours is still running
pgrep -fl wezterm
```

### Proof, run 2026-08-23 by the implementer

Every box above is `[x]` against a command run in this working tree.

```
grep -c 'silently disable healing' home/dot_config/wezterm/wezterm.lua \
                                  docs/capabilities-terminal.md
  home/dot_config/wezterm/wezterm.lua:0
  docs/capabilities-terminal.md:0

grep -c 'repairing' home/dot_config/wezterm/wezterm.lua        -> 4

# my change set alone, reverse-applying Blocks A and B into a scratch copy
# and diffing it against the working file (plain `git diff` also shows three
# other lanes' uncommitted edits to this file, which are not mine):
diff -u <before> home/dot_config/wezterm/wezterm.lua \
  | grep -E '^[+-][^+-]' | grep -v -- '^[+-] *--'    -> no output

awk '/^## Self-healing nine-tab floor/,/^----/' docs/capabilities-terminal.md \
  | grep -E '^- [0-9]+$'                             -> - 10 then - 7
grep -o '(../../../../../../prds/00-delivery/corrections/wezterm-repairing-latch-claim/specs/' docs/capabilities-terminal.md | wc -l   -> 7

bash tests/wezterm-startup-layout.sh
  wezterm-startup-layout gate: ALL PASS   (exit 0)
  including PASS static: local repairing = false present (R7)
            PASS static: ...and no GLOBAL on that line (R7)
            PASS static: pcall present in the repair path (R8)
            PASS static: failure log message 'tab reconcile failed' (R8)
  Same reading before the edit: ALL PASS. Delta zero.

bash gates/tree-links.sh
  before the edit: TIER A checked 876 links in 143 files, 0 broken (exit 0)
  after  the edit: TIER A checked 876 links in 143 files, 0 broken (exit 0)
  Tier A delta 0 broken -> 0 broken. Tier B 114 broken before and after,
  all pre-existing under specs/**, none naming either edited file except
  the pre-existing wallpaper-opacity/specs/spec01.md:93 relative-path bug.

# the probe, log written outside the config dir, HOME from mktemp -d
evaluations per generation:  2 gen=g1, 2 gen=g2
serving contexts per generation: gen=g1 ctx=60000256ddc0
                                 gen=g2 ctx=6000025635c0   (1 each)
fires: 66  reading latched=false: 2                        (1 per generation)
lines for the unparseable generation g3: 0
last line: EV update-status gen=g2 ctx=6000025635c0 evals=1 latched=true win=1
  Expected 2 / 1 / 1 per generation / 0 — all four reproduced.

ps -Ao pid,args | grep -i wezterm
  85210 /Applications/WezTerm.app/Contents/MacOS/wezterm-gui   (the user's)
  Probe daemon killed via its own scratch HOME pidfile; the three mktemp
  dirs removed. `pkill wezterm-mux-server` was never run.
```
