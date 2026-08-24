---
est: 1h
footprint:
  - tests/wezterm-tab-content-state.sh
---

# spec03 — wezterm-tab-content-state.sh's two block comparisons onto the Lua lookups

Move the two positional comparisons in `tests/wezterm-tab-content-state.sh`
onto spec01's helpers and land a counterfactual per site. Both comparisons run
over `$BLOCK` — the `sed -n '/── 05-tab-content-state/,/── R5: the tab
title/p'` extraction — which preserves Lua `--` comments, so
`line_of_lua_code` / `last_line_of_lua_code` apply to it unchanged. Runs
after spec01.

## The sites

Block measured 2026-08-24: `wezterm.lua:798-918`, every target a code line
inside it (block-relative):

| target | block line | lookup |
|---|---|---|
| `local ok, name = pcall(function()` | 63 | first |
| `get_foreground_process_name` | 64 | first |
| `return true` | 114 | first |
| `return false` | 118 | **last** |

- **Site A** (`:192-195`, R1 OR-shape): contract function over a file
  argument — `true_line` first, `false_line` via `last_line_of_lua_code`,
  pass iff both `> 0` and `true_line < false_line`.
- **Site B** (`:270-273`, R5 pcall guard): same shape — `pcall_line` and
  `fg_line` first occurrences, pass iff both `> 0` and
  `pcall_line <= fg_line`. Keep the `<=` — the two sit on adjacent lines and
  the guard clause allows equality today.
- Diagnostics keep printing the block-relative line numbers, as now.
- No only-inside-that-callback comment exists at these two sites; leave the
  surrounding prose alone unless the rewrite falsifies a sentence of it.

## The counterfactuals (landed in stage_static, on copies of $BLOCK under $SCRATCH)

- **CF-A** — copy `$BLOCK`; delete the code line containing `return true`;
  insert the comment `-- return true` near the top of the copy. `chk_fail`
  the site-A contract on the copy — the substring lookup resolves the
  comment (green, defused); the code lookup reads `true_line = 0`, red.
- **CF-B** — copy `$BLOCK`; delete the `local ok, name = pcall(function()`
  line; insert the comment `-- local ok, name = pcall(function()` after the
  `get_foreground_process_name` line. `chk_fail` the site-B contract on the
  copy.

## Out of this spec

The `$BLOCK` extraction itself (`:173`) bounds a `sed -n` window on the two
`── …` comment markers. The PRD's R2 names two window sites and this is not
one of them — reported as a finding, not changed here.

## Acceptance

- [x] Both site contracts are functions over a file argument (`r1_or_shape`,
      `r5_pcall_guard`), built on the spec01 helpers, every position tested
      `-gt 0` before the order comparison (R5 keeps its `<=`).
- [x] Real-block conclusions unchanged — run 2026-08-24: "PASS  static:
      return true (code line 114 of the block) precedes return false (code
      line 118) — the OR over panes, not an AND (R1)" and "PASS  static:
      pcall (code line 63 of the block) guards the accessor call (code line
      64) (R5)" — exactly the spec's block-relative measurements.
- [x] CF-A and CF-B are landed `chk_fail` lines in stage_static; run
      2026-08-24: "PASS  static: counterfactual return-true-quoted — the
      OR-shape contract goes red on the mutated block copy (true reads 0)"
      and "PASS  static: counterfactual pcall-quoted — the pcall-guard
      contract goes red on the mutated block copy (pcall reads 0)".
- [x] `bash tests/wezterm-tab-content-state.sh` run alone 2026-08-24: 72
      PASS, 0 FAIL, final line "wezterm-tab-content-state gate: ALL PASS",
      `EXIT=0`.

## Verify and Proof

```sh
bash tests/wezterm-tab-content-state.sh; echo "EXIT=$?"
```
