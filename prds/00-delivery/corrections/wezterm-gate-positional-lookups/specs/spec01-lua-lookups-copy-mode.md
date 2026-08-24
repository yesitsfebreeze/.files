---
est: 1.25h
footprint:
  - gates/lib.sh
  - tests/wezterm-copy-mode.sh
---

# spec01 — Lua-comment lookups in gates/lib.sh; wezterm-copy-mode.sh moved onto them

Add two Lua-aware positional lookups to `gates/lib.sh` and rebuild the two
positional comparisons in `tests/wezterm-copy-mode.sh` on them, with a landed
counterfactual per site. R1's measurement stands: every target is indented
Lua, so `line_of_decl`'s column-1 anchor returns 0 on all of them and the
mitigation is comment-stripped input — but taken with awk keeping the file's
own `NR`, never a strip-pipe, per the renumbering trap `gates/lib.sh:152-167`
already paid for.

## The helpers (gates/lib.sh)

Beside `line_of_code`, same shape, Lua comment test:

```sh
# line_of_lua_code <file> <string> — first NON-comment line containing the
# string, the file's own line number; 0 if absent. Lua twin of line_of_code:
# a Lua comment starts with --, and the awk keeps NR so the answer is a line
# of the file, never of a stripped stream.
line_of_lua_code() {
  awk -v s="$2" '$0 !~ /^[[:space:]]*--/ && index($0, s) { print NR; exit }' "$1" \
    | { read -r n; echo "${n:-0}"; }
}

# last_line_of_lua_code <file> <string> — LAST such line; 0 if absent.
last_line_of_lua_code() {
  awk -v s="$2" '$0 !~ /^[[:space:]]*--/ && index($0, s) { n = NR } END { print n + 0 }' "$1"
}
```

Rules that bind the helpers:

- Never name anything `line_of` — fourteen gates define their own and would
  shadow it (`gates/lib.sh:96-101`).
- awk with a comment test, never `grep -v | grep -n` — a pipe renumbers, and
  these answers are compared against other line numbers.
- Carry the why as a comment: the wezterm targets are indented, `line_of_decl`
  cannot anchor them, and `line_of_code`'s `#` test does not see a Lua `--`.

## The two sites (tests/wezterm-copy-mode.sh)

Positions measured 2026-08-24 in `home/dot_config/wezterm/wezterm.lua`; every
one is a code line today, so no conclusion changes (PRD R5):

| target | occurrences | lookup |
|---|---|---|
| `act.ClearSelection` | 613, 1251 | first |
| `act.ActivateCopyMode` | 614 | first |
| `act.CopyTo("ClipboardAndPrimarySelection"), pane` | 1250 | first |
| `act.ClearSelection, pane` | 613, 1251 | **last** |
| `act.SendKey({ key = "c", mods = "CTRL" })` | 1253 | first |

- **Site A** (`:76-79`, R1 order): replace the `$GREP -n … | head -1` pair
  with a contract function taking the file as `$1` — `clear` and `activate`
  via `line_of_lua_code`, pass iff both `> 0` and `clear < activate`.
- **Site B** (`:140-146`, R7 order): same shape — `copy` first, `clear2`
  via `last_line_of_lua_code`, `send` first; pass iff all three `> 0` and
  `copy < clear2 && clear2 < send`.
- Every position `> 0` is part of each contract — a deleted target must read
  red, not compare `0 < n` green.
- The `chk` diagnostics keep printing the line numbers, now the code lines.
- The comment at `:72-74` ("enter_copy_mode is the first place either name
  appears … first occurrences compare") is the "occurs only inside that
  callback" assumption PRD R3 retires. Replace it: the lookups read code, so
  a comment quoting a target cannot move them.

## The counterfactuals (landed in stage_static, on copies under $SCRATCH)

Shape from `tests/shell-listing.sh:422-424`: contract as a function, mutated
copy, `chk_fail`.

- **CF-A** — copy `$SRC`; delete the first
  `window:perform_action(act.ClearSelection, pane)` line; insert the comment
  `-- act.ClearSelection` on the line above the `act.ActivateCopyMode` line.
  `chk_fail` the site-A contract on the copy. (A substring lookup resolves
  the comment and stays green — the defusal this node closes; the code
  lookup finds 1251 > 614 and goes red.)
- **CF-B** — copy `$SRC`; delete the `act.SendKey({ key = "c", mods =
  "CTRL" })` line; insert the comment
  `-- act.SendKey({ key = "c", mods = "CTRL" })` after the last
  `act.ClearSelection, pane` line. `chk_fail` the site-B contract on the
  copy (`send` reads 0).

## Acceptance

- [x] `gates/lib.sh` defines `line_of_lua_code` and `last_line_of_lua_code`
      as above — awk comment test, file's own NR, nothing named `line_of`.
      `bash -n gates/lib.sh` → "lib parses"; both helpers re-measured
      2026-08-24 against `home/dot_config/wezterm/wezterm.lua` and reproduce
      every spec position (613, 614, 1250, 1251 last, 1253, 1152, 1155).
- [x] Both site contracts are functions over a file argument (`r1_order`,
      `r7_order`); real-file conclusions unchanged — run 2026-08-24: "PASS
      static: ClearSelection (code line 613) precedes ActivateCopyMode (code
      line 614) (R1)" and "PASS static: Ctrl+C callback order — CopyTo (code
      line 1250) < ClearSelection-after-copy (code line 1251) < SendKey
      fallthrough (code line 1253) (R7)".
- [x] Every lookup in both contracts is required `> 0` — `r1_order` tests
      both `-gt 0`, `r7_order` tests all three `-gt 0`, before any `<`.
- [x] The `:72-74` first-occurrence assumption comment is gone; the contract
      comment now states the code-read mechanism and quotes the old
      assumption only as the retired justification.
- [x] CF-A and CF-B are landed `chk_fail` lines in stage_static; run
      2026-08-24: "PASS static: counterfactual clear-quoted — the R1 order
      contract goes red on the mutated copy" and "PASS static:
      counterfactual send-quoted — the R7 order contract goes red on the
      mutated copy (send reads 0)".
- [x] `bash tests/wezterm-copy-mode.sh` run alone 2026-08-24: 70 PASS,
      0 FAIL, final line "wezterm-copy-mode gate: ALL PASS", `EXIT=0`.

## Verify and Proof

```sh
bash tests/wezterm-copy-mode.sh; echo "EXIT=$?"
bash -n gates/lib.sh && echo "lib parses"
```
