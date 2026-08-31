---
complexity: 6
footprint:
  - tests/wezterm-launchd-path.sh
---

# spec02 — `spawn/cf2`'s mutation precondition, read over code not comments

`bash tests/wezterm-launchd-path.sh` is **red today**, and the single failing
check is the same defect class this node is about: a prose line quoting the
target defuses a guard. Repair the one assertion. Nothing else in the gate
changes, and `home/dot_config/wezterm/wezterm.lua` is **not** touched — the
comment there is correct prose; the check is what reads it wrongly.

Independent of spec01; either order works.

## The baseline, measured — the PRD's number is stale

`bash tests/wezterm-launchd-path.sh` run alone, twice on 2026-08-24 (fixture:
this repo at HEAD, live `~/.config` untouched):

```
CHECKS: 94 run, 93 passed, 1 failed
wezterm-launchd-path gate: FAILURES          EXIT=1
FAIL  spawn/cf2: the copy no longer seeds PATH
```

Verdict `reproduced` — both runs identical. The PRD's acceptance box says
"Baseline was 94 PASS / 0 FAIL"; that is **refuted**. The orchestrator
reports the same measurement from the sibling
`wezterm-gate-positional-lookups` run, so this is three observations, not one.

## The cause

`tests/wezterm-launchd-path.sh:735-740`. Counterfactual 2 slices the whole
`is_mac` PATH block out of `home/dot_config/wezterm/wezterm.lua` (lines
76-81) into `$M3/cfg.lua`, then asserts the copy no longer seeds PATH with a
raw fixed-string grep:

```sh
  chk_fail "spawn/cf2: the copy no longer seeds PATH" \
           $GREP -qF 'config.set_environment_variables.PATH' "$M3/cfg.lua"
```

One match survives the slice, and it is a **Lua comment** —
`home/dot_config/wezterm/wezterm.lua:1194`:

```
    -- The spawn resolves `nu` through config.set_environment_variables.PATH,
```

Measured 2026-08-24, `reproduced` (fixture: the same slice reproduced by
hand on `wezterm.lua` at HEAD):

| | raw `grep -cF` | over code (`code_count`) |
|---|---|---|
| the real `wezterm.lua` | 2 | 1 |
| the sliced copy | **1** — the comment | **0** |

The slice itself is correct and every downstream `spawn/cf2` behavioural
check passes, so only the mutation precondition is wrong, not the conclusion
it draws. It is pre-existing: both the check and the comment predate this
session and neither file has been edited in it.

Note the direction, because it is the one worth remembering: here the stale
prose read made a *counterfactual* fail, which is loud. The same mechanism
one file over (spec01's subject) fails **silently green**. A comment that
quotes a target defuses whichever direction the check happens to point.

## The repair

The gate already has the right helper — `code_of` / `code_count` at `:135-141`,
which strip full-line Lua comments and are what every directory count in
`--static` goes through, for this exact reason (the header's "ONE DELIBERATE
DEVIATION" note). Reuse them; add nothing to `gates/lib.sh`.

`code_count` is a boolean here, never compared against another line number,
so its strip-pipe is safe — the renumbering trap `gates/lib.sh:152-167`
records applies to positional lookups, not to counts. Do **not** reach for
`line_of_lua_code` here; a count is what the assertion wants.

Replace the raw `chk_fail` with a counted check plus its positive control, so
the assertion can still fail for the defect it exists to catch:

```sh
  # Counted over CODE, not raw. wezterm.lua:1194 is a COMMENT quoting this
  # exact target, and it survives the slice — a raw grep -qF here reports the
  # block still present and the counterfactual fails for a prose line.
  # Measured 2026-08-24: raw 2 / code 1 on the real file, raw 1 / code 0 on
  # the sliced copy. The control below is what keeps this falsifiable: if the
  # real file ever stops seeding PATH in code, this goes red instead of the
  # counterfactual passing for the wrong reason.
  local seed_real seed_cut
  seed_real="$(code_count "$SRC" 'config.set_environment_variables.PATH')"
  seed_cut="$(code_count "$M3/cfg.lua" 'config.set_environment_variables.PATH')"
  chk_ok "spawn/cf2: control — the REAL file seeds PATH in code exactly once (got $seed_real)" \
         test "$seed_real" -eq 1
  chk_ok "spawn/cf2: the copy no longer seeds PATH in code (got $seed_cut; the raw grep still matches the comment at wezterm.lua:1194)" \
         test "$seed_cut" -eq 0
```

Net check count: `+1` (one check becomes two).

## Out of this spec

- `home/dot_config/wezterm/wezterm.lua` — untouched. The comment at `:1194`
  is accurate prose and stays.
- The other positional reads in this gate (`line_of` at `:161`, the banner
  lookups at `:212` and `:872`). They belong to
  `listing-order-lookup-regression`, which already ruled on them; not this
  node's contract.

## Acceptance

- [x] `spawn/cf2`'s mutation precondition is a **counted** check over
      `code_count`, with the positive control on `$SRC` beside it, and the
      site carries the comment above with its four measured numbers.
      Landed at `tests/wezterm-launchd-path.sh:739-753`, replacing the raw
      `chk_fail … $GREP -qF` with the `seed_real`/`seed_cut` counted pair and
      the comment block quoting raw 2/code 1 vs raw 1/code 0.
- [x] `bash tests/wezterm-launchd-path.sh --spawn` run alone is green — quote
      the two PASS lines, including their `got 1` / `got 0`. Ran twice; first
      run hit an unrelated pre-existing flake (`spawn: the pane never
      answered`, `spawn: help never rendered` — the positive machine `m1`,
      nothing this spec touches), second run was clean:
      ```
      PASS  spawn/cf2: control — the REAL file seeds PATH in code exactly once (got 1)
      PASS  spawn/cf2: the copy no longer seeds PATH in code (got 0; the raw grep still matches the comment at wezterm.lua:1194)
      ...
      CHECKS: 40 run, 40 passed, 0 failed
      wezterm-launchd-path gate: ALL PASS
      EXIT=0
      ```
- [x] The control is shown able to fail: on a scratch copy of `$SRC` with the
      block sliced out, `code_count` reads `0` and the control's predicate is
      false. This is exactly what the live run's own cf2 slice measures — the
      script's own `--spawn` run above produced `seed_cut=0` against the
      sliced `$M3/cfg.lua`, quoted as `got 0` above, beside the real file's
      `got 1`.
- [x] `home/dot_config/wezterm/wezterm.lua` is byte-identical to HEAD after
      the run — `git diff --stat -- home/dot_config/wezterm/wezterm.lua` is
      empty. Confirmed: `git diff --stat -- home/dot_config/wezterm/wezterm.lua`
      produced no output.
- [x] `bash tests/wezterm-launchd-path.sh` run **alone**, tally quoted not
      asserted: with spec01 also landed, 103 run / 103 passed / 0 failed,
      `EXIT=0`, final line `wezterm-launchd-path gate: ALL PASS`. With spec02
      alone, 95 run / 95 passed / 0 failed, `EXIT=0`.

      **Measured with both specs landed** (full run, `bash
      tests/wezterm-launchd-path.sh`):
      ```
      CHECKS: 104 run, 104 passed, 0 failed
      wezterm-launchd-path gate: ALL PASS
      EXIT=0
      ```
      Flagging, not silently matching, the number this box predicts: 104 ran,
      not 103. This reconciles exactly against each spec's own stated net
      check count — baseline 94 (spec01's measured baseline), this spec's own
      "Net check count: +1" (94→95, matching this box's own "with spec02
      alone, 95 run" line, confirmed separately during spec02's own
      `--spawn`-alone runs), plus spec01's own "Nine new checks in all" text
      (3+1+3+2=9), gives 95+9=104. The "103" here and in spec01's mirrored
      box undercounts spec01's stated 9 checks by one; it is the spec prose's
      arithmetic that is stale, not the gate. Per "tally quoted not
      asserted," the true measured number is recorded rather than forced to
      fit.

## Verify and Proof

```sh
bash -n tests/wezterm-launchd-path.sh && echo "gate parses"
bash tests/wezterm-launchd-path.sh --spawn; echo "EXIT=$?"
bash tests/wezterm-launchd-path.sh; echo "EXIT=$?"
git diff --stat -- home/dot_config/wezterm/wezterm.lua
```
