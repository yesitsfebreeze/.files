---
est: 20m             # calibrated: this board's 37 clean est/actual pairs run
                     #   4.0x high (62.75h est / 15.58h actual), so a naive
                     #   1.3h reads as 20m. Two gate runs at 91s each are the
                     #   floor of the wall clock.
footprint:
  - tests/nvim-statusline.sh
---

# spec01 — make the DevIcon counterfactual mutate both declarations

`tests/nvim-statusline.sh` counterfactual 2 deletes
`dependencies = { "nvim-tree/nvim-web-devicons" }` from its staged copy of
`lua/plugins/statusline.lua` and then asserts the rendered line carries **no**
`%#lualine_x_filetype_DevIcon` group. It is red because
`lua/plugins/explorer.lua:37` declares the same plugin, so devicons stays in
the lazy spec and the icon still renders. Delete both lines in the copy and the
check discriminates again. This spec changes the counterfactual's staging only
— no assertion is relaxed, and no config file is touched.

## R1's verdict: (a), already measured

Measured 2026-08-23, `nvim v0.12.4`, staged copy of
`home/dot_config/nvim` with the whole `lazy-lock.json` seeded from
`~/.local/share/nvim/lazy`, render probe identical to the gate's PROBE C:

| staged mutation | `nvim-web-devicons` in the lazy spec | loaded | `lualine_x_filetype_DevIcon` groups in the render |
|---|---|---|---|
| none (baseline) | true | true | 1 |
| `statusline.lua` dependencies line deleted | true | true | 1 |
| **both** dependencies lines deleted | false | false | **0** |

So the FAIL is a counterfactual that stopped discriminating when `06-explorer`
landed a second declaration. It is **not** a rendering regression: the
unmutated baseline still renders the icon, which is what PROBE C's
`render: a lualine_x_filetype_DevIcon group …` check asserts, and that check is
green today.

`tests/nvim-explorer.sh` CF3 (line 708 onward) is the shape to mirror — the
same dependency, the same two-line mutation, the reason in a comment.

## The change

In the counterfactual-2 block of `stage_headless` (`R="$W/cf-deps"`, around
line 995):

1. After `cf_stage "$R" '/^    dependencies = …$/d'` and its staging `chk`, also
   delete the declaration from the copy's `lua/plugins/explorer.lua`.
2. Add one staging `chk` proving the second deletion is not a no-op **and**
   that nothing under the staged `lua/` tree still declares the plugin —
   `! /usr/bin/grep -rq 'nvim-web-devicons' "$R/config/nvim/lua"`. Measured: no
   comment or other file under `lua/` names the plugin, so this grep is clean
   today and turns a future third declaration into a red staging check instead
   of a silently inert counterfactual.
3. Put the reason in a comment above the block: one line alone is inert because
   two nodes declare the same plugin, with the measurement date and the
   `06-explorer` cross-reference. State the fact, not the history.

In `selftests`, add the pair for `f_dep` — a copy with the dependencies line
deleted must go red on `f_dep`. After change 1, that text check is the only
thing defending `statusline.lua`'s **own** declaration, and it has no selftest
today. This is the same reasoning `tests/nvim-explorer.sh` records for
`f_devi`.

Touch nothing else: not `home/dot_config/nvim/**`, not `tests/nvim-explorer.sh`,
not the PRD frontmatter.

## Acceptance

- [ ] Before changing anything, `bash tests/nvim-statusline.sh` shows exactly
      one red check and it is the `counterfactual: the dependency deleted …`
      line. If any other check is red, **stop and report** — that is another
      node's defect.
- [ ] `bash tests/nvim-statusline.sh` exits 0 and `grep -c '^FAIL'` over its
      output is 0, run **alone**.
- [ ] `grep -c '^PASS'` over that output is **at least 190** (189 existing
      checks with the repaired one green, plus the new staging check; the
      `f_dep` selftest pair adds two more). The number is quoted in the
      report, not asserted by the gate.
- [ ] The counterfactual-2 block deletes the declaration from **both**
      `lua/plugins/statusline.lua` and `lua/plugins/explorer.lua` in the staged
      copy, and its staging check fails if either deletion is a no-op or if any
      file under the staged `lua/` tree still names `nvim-web-devicons`.
- [ ] The reason comment above the block names the two declarations, the
      measurement date, and `tests/nvim-explorer.sh` CF3.
- [ ] `f_dep` has a selftest: a copy with the dependencies line deleted goes
      red on it. Quote both selftest lines.
- [ ] PROBE C's `render: a lualine_x_filetype_DevIcon group …` check and the
      `--tree` check `tree: dependencies = { nvim-tree/nvim-web-devicons }
      (R1)` are unmodified and green. Quote both lines from the passing run.
- [ ] `git diff --name-only` lists `tests/nvim-statusline.sh` and nothing else.
- [ ] The report carries R1's verdict (a) with the measurement above
      reproduced from the implementer's own run: the pre-change red line quoted
      verbatim, and the post-change green line quoted verbatim.
- [ ] The report carries R4's recommendation — why two nodes both correctly
      reported this red and neither owned it, and what board rule prevents the
      next one.
- [ ] R5: the passing run is the **last** action before the report. If any
      other nvim lane landed on `home/dot_config/nvim` or `lazy-lock.json`
      during the work, re-run and quote the later run.

## Verify and Proof

```sh
bash tests/nvim-statusline.sh; echo "exit=$?"
bash tests/nvim-statusline.sh 2>&1 | grep -c '^PASS'
bash tests/nvim-statusline.sh 2>&1 | grep -c '^FAIL'
git diff --name-only
```

One run is ~91 s wall clock; run it once and tee the output rather than three
times.
