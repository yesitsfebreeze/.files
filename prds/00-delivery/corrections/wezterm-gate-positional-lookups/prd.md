---
state: open
priority: 26
est:
mode: afk
needs:
  - 00-delivery/corrections/listing-order-lookup-regression
verify: "bash gates/wave-status.sh --run 4"
origin: derived
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
- [ ] **R1** — Each of the three positional comparisons gets the mitigation
      that fits. **Corrected 2026-08-23: line-start anchoring will not work on
      any wezterm site.** Measured — every target is indented Lua, and
      `index($0,s)==1` returns 0 for **all ten** positions. These gates need
      **comment-stripped input**, already proven by `tests/nvim-statusline.sh`
      (`nocomm`) on the same language. Do not spend a run rediscovering that.
- [ ] **R2** — The two `sed -n` window reads are handled as their own case:
      state whether the window can be bounded on something a comment cannot
      move, or whether the read must be taken over comment-stripped text.
      **This is the more dangerous half** — a defused comparison fails to
      catch, a moved window asserts something else.
- [ ] **R3** — Each gate's "occurs only inside that callback" comment is
      corrected or removed. A gate carrying an assumption its own input can
      falsify is the shape this board has corrected twelve times.
- [ ] **R4** — A counterfactual per site, **landed in each gate**: inject a
      comment quoting the target, and the check must go red.
- [ ] **R5** — No assertion changes what it concludes. Three of these files
      belong to `done` terminal nodes; if a fix would change a conclusion,
      stop and report rather than adjusting it.

## Acceptance
- [ ] All three wezterm gates and `tests/live-bugs.sh` reach `EXIT=0`, run
      **alone**, tallies quoted not asserted.
- [ ] A counterfactual per site quoted red.
- [ ] `bash gates/wave-status.sh --run 4` green, with a unique log path —
      concurrent `--run 4` invocations have collided on a shared scratchpad
      filename before.
- [ ] R2's verdict on the two window reads, with its measurement.

## Out of scope
- `tests/shell-listing.sh` and `tests/nushell-core.sh`, each its own node.
- Any change to what a check concludes.
