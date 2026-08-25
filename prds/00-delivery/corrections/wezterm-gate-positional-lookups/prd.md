---
state: done
claim: 
priority: 26
est: 4.25h
mode: afk
needs:
  - 00-delivery/corrections/listing-order-lookup-regression
verify: "bash gates/wave-status.sh --run 4"
origin: derived
complexity: 55
blast-radius: high
commit: 1d4f92f
actual: 2026-08-24T14:10Z
---

# The highest-exposure file on the board is read positionally, with no guard

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: `home/dot_config/wezterm/wezterm.lua` is **595 comment lines out of
1237 — 48%**, the highest comment ratio of any input a gate reads. Three gates
compare *positions* inside it with no mitigation at all:

| gate | targets compared |
|---|---|
| `tests/wezterm-copy-mode.sh` | `act.ClearSelection` |
| `tests/wezterm-startup-layout.sh` | `return true` / `return false` |
| `tests/wezterm-tab-content-state.sh` | `get_foreground_process_name` |

**Each of those gates' own comments asserts "both strings occur only inside
that callback"** — an assumption a single quoting comment breaks, in a file
that is half comments and that seven terminal nodes write.

This is the same defect that silently defused `tests/shell-listing.sh:108`,
where a sibling node quoted `alias core-ls = ls` in a comment 41 lines above
the declaration and the counterfactual went green from that moment on.

Two more of a related shape, named by the same census: **`tests/live-bugs.sh:174`
and `gates/wave-status.sh:337` bound a `sed -n` window by a substring position
over prose.** A quoting comment there does not merely defuse a comparison — it
**moves the window**, changing what the assertion concludes.

`02-terminal` is being re-specced anyway, which makes this cheap to fix now
and expensive to fix later.

## Requirements
- [x] **R1** — Each of the three positional comparisons gets the mitigation
      that fits. **Corrected 2026-08-23: line-start anchoring will not work on
      any wezterm site.** Measured — every target is indented Lua, and
      `index($0,s)==1` returns 0 for **all ten** positions. These gates need
      **comment-stripped input**, already proven by `tests/nvim-statusline.sh`
      (`nocomm`) on the same language. Do not spend a run rediscovering that.
- [x] **R2** — The two `sed -n` window reads are handled as their own case:
      state whether the window can be bounded on something a comment cannot
      move, or whether the read must be taken over comment-stripped text.
      **This is the more dangerous half** — a defused comparison fails to
      catch, a moved window asserts something else.
- [x] **R3** — Each gate's "occurs only inside that callback" comment is
      corrected or removed. A gate carrying an assumption its own input can
      falsify is the shape this board has corrected twelve times.
- [x] **R4** — A counterfactual per site, **landed in each gate**: inject a
      comment quoting the target, and the check must go red.
- [x] **R5** — No assertion changes what it concludes. Three of these files
      belong to `done` terminal nodes; if a fix would change a conclusion,
      stop and report rather than adjusting it.

## Acceptance
- [x] All three wezterm gates and `tests/live-bugs.sh` reach `EXIT=0`, run
      **alone**, tallies quoted not asserted.
- [x] A counterfactual per site quoted red.
- [x] `bash gates/wave-status.sh --run 4` green, with a unique log path —
      concurrent `--run 4` invocations have collided on a shared scratchpad
      filename before.
- [x] R2's verdict on the two window reads, with its measurement.

## Out of scope
- `tests/shell-listing.sh` and `tests/nushell-core.sh`, each its own node.
- Any change to what a check concludes.

## Report

Closed 2026-08-24. Spec01-03 landed in an earlier session; spec04 was proved
in this one against the code that session left unverified, with no further
edit needed — every point it asks for was already met, and each was measured
rather than trusted.

Verify, run alone:

```
bash tests/wezterm-copy-mode.sh        EXIT=0
bash tests/wezterm-startup-layout.sh   EXIT=0
bash tests/wezterm-tab-content-state.sh EXIT=0
bash tests/live-bugs.sh                160 PASS, 0 FAIL, EXIT=0
bash gates/wave-status.sh --selftest   20 PASS, 0 FAIL, rc=0
bash gates/wave-status.sh --run 4      "wave 4 - PENDING 17/18", EXIT=0
```

The five cheap gates above were re-run by the orchestrator on the collect and
came back `EXIT=0` each. The `--run 4` line is the implementer's, quoted to a
unique mktemp log; the orchestrator did not re-run the full wave sweep.

**R2's verdict, per site** — the two window reads are different cases:

- `tests/live-bugs.sh` reads live Lua, so the read is taken over
  comment-stripped text: anchor and window both skip `--` lines, in one awk
  pass that keeps the file's own numbering. The defusal is `reproduced` on
  two different inputs (fixture: `treesitter.lua` and `keymaps.lua`, each
  mutated in scratch) — the old substring anchor lands on a planted quoting
  comment and reads UNGROUPED with a real `group =` present.
- `gates/wave-status.sh` reads markdown prose, which has no comment syntax to
  strip, so the bound cannot be anchored and is made self-checking instead:
  the position is used only when `\[tv needs a$` matches exactly once.
  `reproduced` twice with a different input (fixture: `prds/06-help/prd.md`
  with a duplicate planted above, then below the real line) — 1 match rc=0
  line 42; 2 matches rc=1 both ways.

Every landed counterfactual prints PASS across all five sites: copy-mode 2,
startup-layout 1, tab-content 2 static + 6 probe, live-bugs 1, wave-status
selftest 1.
