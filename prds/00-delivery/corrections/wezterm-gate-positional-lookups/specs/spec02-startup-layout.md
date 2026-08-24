---
est: 0.5h
footprint:
  - tests/wezterm-startup-layout.sh
---

# spec02 — wezterm-startup-layout.sh's R14 order onto the Lua lookups

Move the one positional comparison in `tests/wezterm-startup-layout.sh` onto
spec01's `line_of_lua_code`, retire its "both strings occur only inside that
callback" comment, and land the counterfactual. Runs after spec01 — it
consumes the helpers spec01 puts in `gates/lib.sh`.

## The site

`tests/wezterm-startup-layout.sh:103-107`. Positions measured 2026-08-24 in
`home/dot_config/wezterm/wezterm.lua`, both code lines, each occurring once:

| target | line |
|---|---|
| `mark_closing(mux_win:window_id())` | 1152 |
| `act.CloseCurrentTab({ confirm = false })` | 1155 |

- Replace the `$GREP -n … | head -1` pair with a contract function over a
  file argument: `mark` and `close` via `line_of_lua_code`, pass iff both
  `> 0` and `mark < close`.
- The comment at `:103-104` — "both strings occur only inside that callback,
  so first occurrences compare" — is the assumption PRD R3 retires. Replace
  it: the lookups read code, so a quoting comment cannot move them.
- The `chk` diagnostic keeps printing both line numbers.

## The counterfactual (landed in stage_static, on a copy under $SCRATCH)

- **CF** — copy `$SRC`; delete the `mark_closing(mux_win:window_id())` line;
  insert the comment `-- mark_closing(mux_win:window_id())` on the line above
  the `act.CloseCurrentTab({ confirm = false })` line. `chk_fail` the
  contract on the copy — a substring lookup resolves the comment and stays
  green; the code lookup reads `mark = 0` and goes red.

## Acceptance

- [x] The R14 order check is the contract function `r14_order` over a file
      argument, built on `line_of_lua_code`, both positions tested `-gt 0`
      before the `<`.
- [x] Real-file conclusion unchanged — run 2026-08-24: "PASS  static:
      mark_closing (code line 1152) precedes the CloseCurrentTab loop (code
      line 1155) (R14)"; both positions re-measured independently via the
      helper, 1152 and 1155, matching the spec's measurement.
- [x] The `:103-104` only-inside-that-callback comment is gone; the R14 site
      comment now states the code-read mechanism, and the contract-function
      comment quotes the old assumption only as the retired justification.
- [x] The counterfactual is a landed `chk_fail` in stage_static; run
      2026-08-24: "PASS  static: counterfactual mark-quoted — the R14 order
      contract goes red on the mutated copy (mark reads 0)".
- [x] `bash tests/wezterm-startup-layout.sh` run alone 2026-08-24: 36 PASS,
      0 FAIL, final line "wezterm-startup-layout gate: ALL PASS", `EXIT=0`.

## Verify and Proof

```sh
bash tests/wezterm-startup-layout.sh; echo "EXIT=$?"
```
