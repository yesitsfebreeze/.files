---
complexity: 20
footprint:
  - home/dot_config/wezterm/wezterm.lua
  - docs/capabilities-terminal.md
  - tests/wezterm-tab-content-state.sh
verify: "bash tests/wezterm-tab-content-state.sh && bash tests/wezterm-startup-layout.sh"
---

# spec01 — the claim, measured against the live config, in the four non-PRD carriers

Re-run the probe once, quote its four numbers, then apply the pre-resolved
blocks below to `home/dot_config/wezterm/wezterm.lua` (two comment blocks),
`docs/capabilities-terminal.md` (one bullet replaced, one added) and
`tests/wezterm-tab-content-state.sh` (**one shell comment, no assertion**).

**No line of Lua changes, no shell assertion changes, no box changes state.**
This spec edits comments and prose only.

The measurement is done. Do not re-derive it — re-run the probe in **Verify
and Proof**, check its four numbers against the table below, and apply the
blocks verbatim.

**Match the text, not the line number.** Every line number here was read on
2026-08-24 against a working tree carrying uncommitted edits from other
lanes. Each block quotes the text it replaces, and the quoted text is the
anchor.

The three board-tree carriers of the same claim are [`spec02`](spec02.md),
which the **orchestrator** executes.

## R1 — the measurement, against the live config

2026-08-24, WezTerm `20240203-110809-5046fc22`, macOS 25.2.0. Two independent
`wezterm-gui` processes, each `env -i` with a scratch `HOME` from `mktemp -d`
(short, so the mux socket fits `SUN_LEN` — R5) and `--always-new-process`,
running an **instrumented copy of `home/dot_config/wezterm/wezterm.lua`
itself**, not a probe config. This is what
[`wezterm-repairing-latch-claim`](../../wezterm-repairing-latch-claim/prd.md)
could not say: its verdict was `unmeasured (probe config, not the live one)`,
and this fixture closes exactly that gap.

The copy differs from the live file in **one** non-probe line —
`window:toggle_fullscreen()` suppressed, so the probe does not seize the
user's screen — plus an inserted probe preamble and three `probe_note` calls
at the head of `reconcile_tabs`, `center_grid` and `learn_pane_programs`. The
preamble holds a **module-local** `probe_local`, nil at evaluation, written by
every handler; each fire logs whether it read `nil` on entry, the context
identity (kept in `_G`, which survives a re-evaluation inside the same
context), the write count and a `wezterm.GLOBAL` counter. **The log is written
outside the config directory** — a write inside it re-triggers the reload, and
that storm reads exactly like a context pool (R1's own warning, and the trap
that produced the earlier probe's opposite result).

| | run 1 (1 window) | run 2 (2 `cli spawn --new-window`) | union |
|---|---|---|---|
| Lua contexts created | 6 | 10 | **16** |
| contexts that ever served an event | 2 | 3 | **5 of 16** |
| handler fires | 1247 | 1523 | **2770** |
| fires reading the module-local as `nil` | 2 | 3 | **5** |
| …of those, NOT the context's first fire | 0 | 0 | **0** |
| later fires (writes > 1) reading non-`nil` | 1245 | 1520 | **2765** |

Nine event kinds fired: `gui-startup`, `window-config-reloaded`,
`update-status`, `update-right-status`, `format-tab-title`, plus the three
instrumented functions. Every generation created 2 contexts, of which
**exactly one served events**; the serving context changed only when the file
was evaluated again, and dispatch **never returned to an older context**.
Run 2's `wezterm cli spawn` client evaluated the config in its own process (2
more contexts, `GLOBAL` unset there, 0 fires) — which is where some of the
"more than one context" impression comes from.

### The verdicts, in the census vocabulary

- "WezTerm … runs event callbacks in whichever is free, so a module-local
  table reads back `nil` about as often as not" —
  **`refuted (2 isolated GUI processes running an instrumented copy of
  home/dot_config/wezterm/wezterm.lua, 16 evaluations, 2770 fires, 9 event
  kinds: 5 nil reads, every one a fresh context's first fire, 0 of 2765
  later fires)`**. The claim predicts about 1385 of 2770.
- `wezterm.lua`'s stronger wording, a local `slots` table "read back as nil
  on **every single** event here" — **`refuted (same fixture: 5 of 2770)`**.
  This is the inconsistency
  `pwd-closure-blast-radius/specs/spec02.md:228` recorded and could not
  settle.
- "WezTerm evaluates this config into more than one Lua context" —
  **`reproduced (same fixture: 2 contexts per evaluation, 16 across the two
  runs)`**. This half stands; only the dispatch story falls.
- "a module-local starts `nil` after every evaluation of this file" —
  **`reproduced (same fixture: 5 of 5 nil reads were a freshly evaluated
  context's first fire; 16 of 16 evaluations began with it nil)`**. **This
  is the replacement reason**, and it is a *lifetime* fact, not a context
  count — R4's sentence.

**The GLOBAL rule is untouched and gets stronger, not weaker.** A
module-local is reset by every evaluation, every successful reload is one, and
every `tinty apply` is a successful reload because `colors.lua` is on the
watch list (`wezterm.lua:705`). The slot map and the baseline map must survive
that. Nothing moves into or out of `wezterm.GLOBAL` (R4).

## Block A — `home/dot_config/wezterm/wezterm.lua`, the slot-map comment

Replace lines 123-131 — from `-- Both the closing marks and the slot lists`
through `-- are derived against the live list each pass, never stored).` —
with this. Line 122 (`--`) and line 132 (`-- One slot list PER WINDOW…`) are
untouched, so the paragraph still reads through.

```lua
-- Both the closing marks and the slot lists live in wezterm.GLOBAL, NOT in
-- plain module-local tables, and the reason is LIFETIME rather than context
-- count. Every evaluation of this file creates fresh Lua contexts (measured:
-- 2 per evaluation) and a module-local starts nil in each, so a local slots
-- table is wiped by every config reload -- and every `tinty apply` is one,
-- because colors.lua is on the reload watch list further down. An emptied
-- slot map made each pass re-adopt the current tab order as gospel --
-- exactly the state that has to survive to know WHICH slot died.
-- What this comment used to claim, and what does NOT happen: callbacks do
-- not land "in whichever context is free". Measured 2026-08-24 on 20240203
-- against an instrumented copy of this file in two isolated GUIs -- 16
-- evaluations, 9 event kinds, 2770 fires -- exactly one context served
-- events at a time, dispatch never returned to an older one, and a
-- module-local read back nil 5 times, every one of them that context's
-- FIRST fire (0 of 2765 later fires). GLOBAL is still the documented
-- cross-context store; values must stay JSON-shaped, so the slot list is a
-- plain array of integer tab ids (holes are derived against the live list
-- each pass, never stored).
```

## Block B — `home/dot_config/wezterm/wezterm.lua`, the baseline comment

Replace lines 821-826 — from `-- The baselines live in wezterm.GLOBAL for the
reason` through `-- pane's own program and read that tab as empty for as long
as it ran.` — with this. Line 827 (`-- JSON-shaped, as GLOBAL requires:…`) is
untouched.

```lua
-- The baselines live in wezterm.GLOBAL for the reason the slot map above
-- records, and it is a LIFETIME reason: a module-local starts nil in every
-- new Lua context, and every config reload makes new ones (every `tinty
-- apply` is a reload), so a baseline map parked in a local would be emptied
-- on each -- and an empty baseline map re-learns against whatever is running
-- RIGHT NOW, which would record a long-lived TUI as a pane's own program and
-- read that tab as empty for as long as it ran. Not "whichever context is
-- free": measured, one context serves at a time -- see the slot map comment.
```

## Block C — `docs/capabilities-terminal.md`, the constraint bullet

Replace lines 67-75 — the whole `- **`wezterm.GLOBAL` is the only
cross-context store.**` bullet, ending `it is rebuilt as a plain table and
reassigned.` — with the two bullets below. The next bullet
(`- **`pane:get_current_working_directory()` does not exist on 20240203.**`)
is untouched.

```markdown
- **`wezterm.GLOBAL` is the only store that survives a config reload.**
  WezTerm evaluates the config into more than one Lua context — measured, 2
  per evaluation — and **every evaluation makes fresh ones**, so a
  module-local starts `nil` in each. That, and not context count, is the
  reason for `GLOBAL`: a module-local `slots` table is wiped by every
  reload, and every `tinty apply` is a reload because `colors.lua` is on the
  watch list, leaving each reconcile pass to re-adopt the current tab order
  as gospel — exactly the state that has to survive. `GLOBAL` values must
  stay JSON-shaped (array of integer ids, string keys), and a value read
  back out of it is a **copy**: assigning into it does not write through, so
  it is rebuilt as a plain table and reassigned.
- **The every-other-callback story is refuted, and the rule above does not
  rest on it.** This entry used to say callbacks run "in whichever is free,
  so a module-local table reads back `nil` about as often as not". Measured
  2026-08-24 on `20240203`, against an **instrumented copy of
  `wezterm.lua` itself** in two isolated `wezterm-gui` processes — 16
  evaluations, 9 event kinds, **2770 handler fires** — a module-local read
  back `nil` **5 times**, and every one was the **first** fire of a freshly
  evaluated context: **0 of 2765 later fires**. Exactly one context served
  events at any moment and dispatch never returned to an older one. The
  config's stronger wording, a local `slots` table "read back as nil on
  every single event", is refuted by the same fixture. The probe writes its
  log **outside** the config directory: a write inside it re-triggers the
  reload, and that storm reads exactly like a context pool — which is the
  most likely origin of the wording being corrected here.
```

## Block D — `tests/wezterm-tab-content-state.sh`, the comment above the R6 check

Replace lines 337-338 — the two shell comment lines reading `# And no
module-local table holds the baselines, which is the multi-context` /
`# rule the slot map above records.` — with this. **The `chk_ok` on lines
339-340 is not touched**: it still asserts that no module-local table holds
the baselines, and it still concludes what it concluded about the baseline
map's placement (R3, R4).

```sh
  # And no module-local table holds the baselines, which is the LIFETIME rule
  # the slot map above records: every evaluation of the config makes fresh Lua
  # contexts and a module-local starts nil in each, so a baseline parked in a
  # local would be emptied by every reload -- and every `tinty apply` is one.
  # Measured 2026-08-24: 5 nil reads in 2770 fires, all of them a fresh
  # context's FIRST fire -- not the every-other-callback story this comment
  # used to name.
```

## Not this spec's files

- `prds/02-terminal/02-startup-layout/prd.md` R5,
  `prds/02-terminal/05-tab-content-state/specs/spec01.md:98-105` and
  `prds/00-delivery/corrections/w0-2-terminal-respec/specs/spec03.md` B5 are
  the other three carriers, and all three are another PRD's body:
  [`spec02`](spec02.md), executed by the orchestrator.
- `~/.config/wezterm/wezterm.lua:70` carries the same sentence. It is the
  **deployed** copy and read-only reference — do not edit it. It picks the
  correction up on the next `chezmoi apply`.
- `prds/02-terminal/02-startup-layout/specs/spec01-tab-floor.md:49-51` says
  "evaluates the config into more than one Lua context and a local `slots`
  read back `nil`". It states **no frequency and no dispatch rule**, and both
  of its clauses *reproduce* against this fixture (2 contexts per evaluation;
  nil on the first fire after each). **Not a carrier. Leave it alone** — the
  same standard by which the latch node excluded that file's line 95-98.
- `prds/02-terminal/03-f5-jump-mode/prd.md:130` and
  `w0-2-terminal-respec/specs/spec04.md:80` say the F5 painter's callbacks
  "run in a different Lua context from the painter". That is a **different
  claim** about a different mechanism, not one of the seven. Do not touch it;
  report it instead (this node's report already does).
- `prds/00-delivery/corrections/pwd-closure-blast-radius/specs/spec02.md:228`
  *reports* the inconsistency between the two wordings rather than asserting
  either. Not a carrier. Leave it.
- `gates/waves.tsv` and `gates/manual/wave*.md` belong to the orchestrator.
  No new row is needed: `tests/wezterm-tab-content-state.sh` and
  `tests/wezterm-startup-layout.sh` already run, and neither asserts the
  prose being changed here.

## Acceptance

- [x] The probe is re-run once and its four numbers quoted: contexts created,
      contexts that served an event, total fires, and nil reads split by
      whether they were a context's first fire. The last must be **0** later
      fires; a nonzero reading is a finding that stops this spec and is
      reported instead of being written into a block.
      Re-run 2026-08-24, `wezterm 20240203-110809-5046fc22`, 1 window:
      `contexts created : 6` · `contexts that served :  204 ctx=600002ab16c0`
      / `1061 ctx=600002ad0a40` (**2 of 6**) · `total fires : 1265` ·
      `nil reads : 2` · `nil reads NOT a first fire (must be 0): 0`. Both nil
      reads are a fresh context's first fire:
      `EV gui-startup  ctx=600002ad0a40 evals=1 pre=true writes=1 global=1`
      and
      `EV format-tab-title  ctx=600002ab16c0 evals=1 pre=true writes=1 global=1062`.
      Matches the table's run-1 column on every structural number (6 / 2 / 2 /
      0); total fires read 1265 against the table's 1247, a timing-driven
      count of `format-tab-title` repaints, not a disagreement in kind.
- [x] The probe's log path is shown, and it is **outside** both the config
      directory and the scratch `HOME`'s `.config` — quoted as three distinct
      `mktemp -d` paths (R1). The run printed
      `config=/var/folders/_p/tzmzw3m10kg7sg9hc7_mkm7w0000gn/T/tmp.26XxtDnLzy`,
      `home=/var/folders/_p/tzmzw3m10kg7sg9hc7_mkm7w0000gn/T/tmp.gCEZ5lP33h`,
      `log=/var/folders/_p/tzmzw3m10kg7sg9hc7_mkm7w0000gn/T/tmp.Mt6YBGhIqZ/probe.log`
      — three distinct temp directories, so no write lands in the config dir
      or under the scratch `HOME`.
- [x] `home/dot_config/wezterm/wezterm.lua` carries Block A and Block B
      verbatim, and **no code line changed**: reverse-apply a pre-edit copy
      and show
      `diff | grep -E '^[+-][^+-]' | grep -v -- '^[+-] *--'` produces **no
      output**. Plain `git diff` cannot answer it — other lanes carry
      uncommitted edits to this file.
      Against a copy taken before any edit:
      `diff $PRE/wezterm.lua home/dot_config/wezterm/wezterm.lua | grep -E
      '^[+-][^+-]' | grep -v -- '^[+-] *--'` printed nothing (grep exit 1),
      and the same filter over `diff -u` printed nothing. Every changed line
      is a `--` comment line.
- [x] The refuted wording is gone from both edited source files:
      `grep -c 'as often as not' home/dot_config/wezterm/wezterm.lua
      docs/capabilities-terminal.md` → `0` for each, and
      `grep -c 'every single event' home/dot_config/wezterm/wezterm.lua` →
      `0`.
      Measured: `home/dot_config/wezterm/wezterm.lua` → **0** for both greps
      (was 2 and 1 before). `docs/capabilities-terminal.md` → **1**, not 0,
      and the one hit is line 80 — inside Block C's own quotation of the
      wording it retires: ``This entry used to say callbacks run "in whichever
      is free, so a module-local table reads back `nil` about as often as
      not"``. **The literal `0` and Block C verbatim cannot both hold**: the
      block quotes the phrase on purpose. The box's substance — the wording is
      nowhere *asserted* — does hold. The spec anticipated exactly this for
      the sister phrase, which is why its `every single event` grep names only
      `wezterm.lua` even though Block C quotes that phrase in the doc too; the
      `as often as not` grep should have been scoped the same way. Reported to
      the orchestrator rather than fixed by rewriting the block.

      **Rescoped by the orchestrator on collect, 2026-08-24.** The
      implementer is right and its refusal to paper over it was correct. This
      grep now names `home/dot_config/wezterm/wezterm.lua` only — identical
      scoping to the sister `every single event` grep three lines down, and
      for identical reasons. A retired phrase written inside a quotation that
      marks it as retired is a **mention**, not a **use**; asserting `0`
      occurrences over a file whose job is to record what the wording used to
      be is an assertion that can only be satisfied by deleting the record.
      This board has already ruled the same way twice on the same
      distinction: `launchd-path-phrase-guard`'s mention/use strip, which
      exists because the retired wording is legitimately present in its
      target PRD as the wording it retires, and `stale-mi-keeplist-ruling`'s
      point/measurement split. The measured state after the edit stands:
      `wezterm.lua` 2 → 0, and the doc's single remaining hit is Block C's
      own quotation at line 80.
- [x] `docs/capabilities-terminal.md` carries Block C, and the file's
      markdown link count is unchanged at **7** — neither block adds a link:
      `grep -o '](' docs/capabilities-terminal.md | wc -l` → `7`.
      Read `7` before the edit and `7` after.
- [x] `tests/wezterm-tab-content-state.sh` carries Block D and **no
      assertion changed**:
      `grep -c 'chk_ok\|chk_fail' tests/wezterm-tab-content-state.sh` is
      identical before and after (quote both readings), and the line
      `chk_ok "static: no module-local baseline table — every table literal
      in the block is function-scoped (R6)"` is still present byte for byte.
      Both readings are **56** and **56**. The `chk_ok` line is present
      unchanged at line 344. A diff against a pre-edit copy filtered to
      non-`#` lines
      (`diff pre now | grep -E '^[<>]' | grep -v -E '^[<>] *#'`) printed
      nothing: only comment lines moved.
- [x] `bash tests/wezterm-tab-content-state.sh` reaches `EXIT=0`, run alone,
      asserted as a delta against a pre-edit run of the same command.
      Post-edit: `tabstate EXIT=0`, closing
      `wezterm-tab-content-state gate: ALL PASS`. Delta against the pre-edit
      run: **72 PASS / 0 FAIL both times**; the only three differing lines are
      line-number readings that moved because comments were added — e.g.
      `got 121 lines` → `got 123 lines`, and
      `pcall (code line 63 of the block) guards the accessor call (code line
      64)` → `(code line 65) … (code line 66)`. No check changed verdict.
- [x] `bash tests/wezterm-startup-layout.sh` → `ALL PASS`, asserted as a
      delta against a pre-edit run. It reads the same config file and must
      not move. Post-edit: `startup EXIT=0`,
      `wezterm-startup-layout gate: ALL PASS`. Delta: **36 PASS / 0 FAIL both
      times**; one differing line, again a line-number reading —
      `mark_closing (code line 1152) precedes the CloseCurrentTab loop (code
      line 1155)` → `(code line 1163) … (code line 1166)`.
- [x] Every probe daemon is killed via its own scratch `HOME` pidfile, and
      `ps -Ao pid,args | grep -i wezterm` afterwards names only the user's
      own GUI, alive — quoted. **`pkill wezterm-mux-server` is never run**
      (R5).
      The probe checked `$H/.local/share/wezterm/pid` and it printed
      `no pidfile` — the run spawned no mux daemon under the scratch `HOME`,
      only the foreground `wezterm-gui`, which was killed by its own job pid
      (`37915 Terminated: 15`). Afterwards
      `ps -Ao pid,args | grep -i wezterm | grep -v grep` names one process:
      `85210 /Applications/WezTerm.app/Contents/MacOS/wezterm-gui` — the
      user's own GUI, the same pid recorded before the probe started, still
      alive on `ps -p 85210`. No `pkill` was run at any point.

## Verify and Proof

```sh
# ── the probe: an instrumented copy of the LIVE config, log outside the
# ── config dir. Opens one GUI window for about 45 s and kills it again.
# ── Three separate mktemp -d paths: config dir, scratch HOME, log dir.
D=$(mktemp -d); H=$(mktemp -d); O=$(mktemp -d)   # short paths: SUN_LEN (R5)
CFG=$D/wezterm.lua; L=$O/probe.log
echo "config=$D  home=$H  log=$L"
mkdir -p "$H/.config/nushell" "$H/.config/wezterm"
: > "$H/.config/nushell/config.nu"; : > "$H/.config/nushell/env.nu"

python3 - home/dot_config/wezterm/wezterm.lua "$CFG" "$L" <<'PY'
import sys
src, dst, log = sys.argv[1], sys.argv[2], sys.argv[3]
pre = '''
local PROBE_LOG = %r
if _G.PCTX == nil then _G.PCTX = tostring({}):gsub("table: 0x", ""); _G.PEV = 0 end
_G.PEV = _G.PEV + 1
local probe_local = nil          -- MODULE-LOCAL under test
local probe_writes = 0
local function plog(tag, pre_nil)
    local f = io.open(PROBE_LOG, "a")
    f:write(string.format("%%-28s ctx=%%s evals=%%d pre=%%s writes=%%d global=%%s\\n",
        tag, _G.PCTX, _G.PEV, tostring(pre_nil), probe_writes,
        tostring(wezterm.GLOBAL.probe_marker)))
    f:close()
end
local function probe_note(tag)
    local was_nil = (probe_local == nil)
    if probe_local == nil then probe_local = { seen = 0 } end
    probe_local.seen = probe_local.seen + 1
    probe_writes = probe_writes + 1
    wezterm.GLOBAL.probe_marker = (wezterm.GLOBAL.probe_marker or 0) + 1
    plog(tag, was_nil)
end
plog("EVAL", probe_local == nil)
for _, ev in ipairs({ "gui-startup", "window-config-reloaded", "update-status",
                      "window-resized", "window-focus-changed", "pane-focus-changed",
                      "update-right-status", "user-var-changed" }) do
    wezterm.on(ev, function() probe_note("EV " .. ev) end)
end
wezterm.on("format-tab-title", function() probe_note("EV format-tab-title"); return nil end)
''' % (log,)
out, dp = [], False
for ln in open(src).read().split("\n"):
    out.append(ln)
    if not dp and ln.startswith("local act = wezterm.action"):
        out.append(pre); dp = True
res = []
for ln in out:
    if ln.startswith(("local function reconcile_tabs(window)",
                      "local function center_grid(window)",
                      "local function learn_pane_programs()")):
        res.append(ln)
        res.append('    probe_note("FN %s")' % ln.split("(")[0].split()[-1])
        continue
    if ln.strip() == "window:toggle_fullscreen()":
        res.append("    -- PROBE: toggle_fullscreen suppressed"); continue
    res.append(ln)
open(dst, "w").write("\n".join(res))
PY

# exactly one non-probe deviation from the live file
diff home/dot_config/wezterm/wezterm.lua "$CFG" | grep '^[<>]' | grep -vi probe

env -i HOME="$H" PATH=/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin \
  /Applications/WezTerm.app/Contents/MacOS/wezterm-gui \
  --config-file "$CFG" start --always-new-process > "$D/gui.out" 2>&1 &
G=$!
sleep 25
printf '\n-- gen2\n' >> "$CFG"       # a successful reload
sleep 20

echo "contexts created      : $(grep -c '^EVAL' "$L")"
echo "contexts that served  :"; grep '^EV \|^FN ' "$L" | sed 's/.*\(ctx=[^ ]*\).*/\1/' | sort | uniq -c
echo "total fires           : $(grep -c '^EV \|^FN ' "$L")"
echo "nil reads             : $(grep '^EV \|^FN ' "$L" | grep -c 'pre=true')"
echo "nil reads NOT a first fire (must be 0): $(grep '^EV \|^FN ' "$L" | grep 'pre=true' | grep -vc 'writes=1 ')"
grep '^EV \|^FN ' "$L" | grep 'pre=true'

# shut down: pidfile only, NEVER pkill (R5)
[ -f "$H/.local/share/wezterm/pid" ] && kill "$(cat "$H/.local/share/wezterm/pid")" 2>/dev/null
kill $G 2>/dev/null; sleep 2
ps -Ao pid,args | grep -i wezterm | grep -v grep

# ── the refuted wording is gone
grep -c 'as often as not' home/dot_config/wezterm/wezterm.lua docs/capabilities-terminal.md
grep -c 'every single event' home/dot_config/wezterm/wezterm.lua

# ── no code line moved, no assertion moved
grep -c 'chk_ok\|chk_fail' tests/wezterm-tab-content-state.sh
grep -o '](' docs/capabilities-terminal.md | wc -l          # 7

# ── the gates
bash tests/wezterm-tab-content-state.sh
bash tests/wezterm-startup-layout.sh
```
