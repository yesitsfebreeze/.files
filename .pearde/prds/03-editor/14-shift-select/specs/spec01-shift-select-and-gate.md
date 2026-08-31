---
est: 2h
footprint:
  - home/dot_config/nvim/lua/config/shift-select.lua
  - home/dot_config/nvim/init.lua
  - tests/nvim-shift-select.sh
  - tests/nvim-options.sh
---

# spec01 — shift-to-select, in its own module, gated on the RPC input path

Port R1–R8 of the live shift-select block
(`~/.config/nvim/lua/config/keymaps.lua:42-127`, read-only) into a **new
module**, `lua/config/shift-select.lua`, and write `tests/nvim-shift-select.sh`
to pin it. Counts are the ones the user settled on 2026-08-24: charwise
inclusive, two characters per press. The behaviour is already measured — the
table in the PRD's `## Questions` is this spec's expected-value table, and the
implementer's job is to reproduce it, not to rediscover it.

## Why a new module, and not `keymaps.lua`

`keymaps.lua` looks like the natural home (epic I5 puts general maps there,
and E.3's spec reserved "everything below line 46" for this node), but
`tests/nvim-keymaps.sh` — E.3's gate, committed and green at 108 PASS — asserts
the opposite about that file, per call site:

| Guard | `tests/nvim-keymaps.sh` | What it forbids |
|---|---|---|
| `f_noshift` | `:478`, `:608` | any `shift_select`, `<S-Up>`, `<S-Down>`, `<S-Left>`, `<S-Right>` in the file |
| `f_noau` | `:480`, `:609` | any `nvim_create_autocmd` in the file (I7 / live bug L-8) |
| `f_nokeys` | `:488`, `:612` | any `map(` call taking `<C-q>`, `<C-c>` or `<C-v>` |

Each has its own selftest that plants exactly this node's code and asserts the
guard goes red. Appending the block to `keymaps.lua` therefore turns a `done`
node's gate red by construction. So: **a separate module, required from
`init.lua`.** `keymaps.lua` is not in this spec's footprint and must come out
of the run byte-identical.

Two constraints that follow, both checked and safe:

- E.3's `i_order` filters the require list to `^config\.(options|keymaps|lazy)$`
  (`tests/nvim-keymaps.sh:516-521`), so a fourth require does not disturb it.
  Insert `require("config.shift-select")` **after** `require("config.keymaps")`
  and **before** `require("config.lazy")`, keeping epic I1's order.
- A new file under `home/dot_config/nvim/` costs a **census entry** in
  `tests/nvim-options.sh:231`, whose `find . -type f | LC_ALL=C sort` string is
  exact. `./lua/config/shift-select.lua` sorts immediately after
  `./lua/config/options.lua`. One entry, plus the label on `:232` which names
  the census generation ("post-E.12" becomes "post-E.14"); nothing else in that
  file. Omitting this is what left a sibling's gate red for an hour.

## What the module contains

A near-verbatim port of the live block — one `feed` helper over
`nvim_feedkeys` + `nvim_replace_termcodes` (R8), the `shift_select` flag (R2),
`select_start` / `select_extend` / `select_start_insert` / `visual_motion`, and
22 maps whose `desc` strings must match the shipped manual
(`home/dot_config/nushell/help/nvim.nuon`, entries `<S-Up> <S-Down> <S-Left>
<S-Right>`, `h j k l (visual)`, `<C-c> (visual)`, `<C-v> (visual)`) exactly:

| Mode | Keys | rhs / behaviour | `desc` |
|---|---|---|---|
| n | `<S-Up/Down/Left/Right>` | `feed("v" .. motion)` | `Select up/down/left/right` |
| v | `<S-Up/Down/Left/Right>` | `feed(motion)` | `Extend selection up/down/left/right` |
| i | `<S-Up/Down/Left>` | `feed("<Esc>v" .. motion)` | `Select up/down/left` |
| i | `<S-Right>` | `feed("<Esc>lv<Right>")` — the extra `l` (R5) | `Select right` |
| v | `h` `j` `k` `l` `<Up>` `<Down>` `<Left>` `<Right>` | `visual_motion` (R6), count preserved in **both** branches | `Move (collapse selection)` |
| v | `<C-c>` | `y` | `Copy to clipboard` |
| v | `<C-v>` | `"_dP` | `Paste over selection` |

**One deliberate deviation from live, required by the epic:** the `ModeChanged`
autocmd must pass `group = vim.api.nvim_create_augroup("shift_select", {
clear = true })`. Epic **I7** names `lua/config/keymaps.lua:58` — this exact
autocmd — as one of the three live sites that break the augroup rule, and binds
`14-shift-select` by name. The live ungrouped form is live bug L-8 and is not
to be reproduced. Everything else about the autocmd is the live form: pattern
`*:*`, and the guard `vim.v.event.old_mode:find("^[vV\22]")`.

## The gate must drive keys over RPC, not `nvim_feedkeys`

The PRD's `## How the gate must drive the keys` is binding; the harness shape
that satisfies it, measured 2026-08-24 on Neovim 0.12.4:

```sh
nvim --headless --listen "$SOCK" &          # HOME + all five XDG roots in $S
nvim --server "$SOCK" --remote-send '<S-Right>'   # one press per call
nvim --server "$SOCK" --remote-expr 'string(getpos("v"))'
```

- **Readiness is a round-trip, not a file.** `[ -S "$SOCK" ]` reported absent
  on the last poll pass while the very next `--remote-expr` connected. Poll
  until `--remote-expr 1` succeeds, with a deadline.
- **One press per `--remote-send`, then drain.** Poll
  `[mode(), line('.'), col('.'), line('v'), col('v')]` until two consecutive
  readings are identical or a 2s deadline expires; a deadline hit is a
  `FAIL … TIMEOUT`, never a skip. Two `<S-Right>` in one batch measure
  *normal* mode, because the second callback's queued `v` toggles visual off.
- **`nvim_input` is not an option** — inside `-c luafile` it never drains: 8
  probes, mode unchanged, buffer untouched, rc 0.
- Inherited from `tests/nvim-keymaps.sh`, unchanged and not re-derived here:
  `. "$REPO/gates/lib.sh"` for `chk` / `chk_ok` / `chk_fail` /
  `assert_unchanged`; `/usr/bin/grep` always; `cp -R` only to a nonexistent
  destination; no `timeout` binary on this machine, so background plus a poll
  loop and `kill -9` on overrun. Tear the server down with
  `--remote-send '<Esc>:qa!<CR>'` and a `kill -9` fallback, and leave no
  scratch directory behind.

Fixture for every behavioural check: at least **six** lines — the PRD's
acceptance says why — with line 2 `ijklmnop` and the cursor on `k`
(1-based column 3):

```
abcdefgh / ijklmnop / qrstuvwx / yz012345 / AAAAAAAA / BBBBBBBB / CCCCCCCC / DDDDDDDD
```

Expected values, all measured on the live block through this harness:

| Keys | anchor → cursor | mode | selection |
|---|---|---|---|
| `<S-Right>` | 3 → 4 | v | `kl` |
| `<S-Right>` `<S-Right>` | 3 → 5 | v | `klm` |
| `<S-Left>` | 3 → 2 | v | `jk` |
| `i`, `x`, `<S-Left>` | 3 → 2 | v | `jx` |
| `i`, `<S-Right>` | 3 → 4 | v | `kl` |
| `<S-Right>`, `l` | col 5, no selection | n | — |
| `<S-Down>`, `3j` | line 6 | n | — |
| `v`, `l` | 3 → 4 | v | `kl` |
| `<S-Right>`, `<Esc>`, `v`, `l` | 4 → 5 | v | 2 chars |

## Acceptance

All boxes below were closed on 2026-08-24 by `bash tests/nvim-shift-select.sh`
— 157 PASS, 0 FAIL, rc 0, 33 s at load average 4.45. The measured values, the
census red/green pair and the two mechanics this build added are recorded in
the PRD's `## Implementation` section rather than repeated here.

Tree stage:

- [x] `lua/config/shift-select.lua` holds exactly **22** `map(` call sites, and
      every mode/lhs/`desc` triple matches the table above; the `desc` strings
      are compared against the 18 `nvim-map` verify targets in
      `home/dot_config/nushell/help/nvim.nuon` and differ from none of them.
- [x] The file has exactly **one** `nvim_feedkeys` call site and **one**
      `nvim_replace_termcodes` call site (R8) and zero `<cmd>` strings.
- [x] The single `nvim_create_autocmd` call passes
      `group = …nvim_create_augroup("shift_select", { clear = true })`
      (epic I7), with pattern `*:*` and the `^[vV\22]` old-mode guard.
- [x] `require("config.shift-select")` sits after `require("config.keymaps")`
      and before `require("config.lazy")` in `init.lua`.
- [x] `home/dot_config/nvim/lua/config/keymaps.lua` is byte-identical to its
      committed content (`git diff --exit-code` on that one path), and
      `bash tests/nvim-keymaps.sh --tree` exits 0 with its three guard lines
      green — `tree: no shift-select machinery`, `tree: zero autocmds`,
      `tree: no map call on <C-q>, <C-c> or <C-v>`.
- [x] `bash tests/nvim-options.sh --tree` exits 0 with
      `./lua/config/shift-select.lua` in the census string, and the run
      **records both halves**: the same command red before the census entry was
      added, naming the census check, and green after — with the file's
      `sha … -> sha …` printed on one line so the edit is visible rather than
      inferred.

Behaviour, over the RPC input path:

- [x] Every row of the expected-value table above reproduces: anchor, cursor,
      mode and selected text, each read back and printed. The two insert-mode
      rows are the ones `nvim_feedkeys` gets wrong, so they carry a note in the
      output saying which path measured them.
- [x] R6 both branches: `<S-Right>` then `l` ends in normal mode at column 5
      with no selection; `<S-Down>` then `3j` ends in normal mode on **line
      6** — the fixture is long enough that clamping cannot produce it.
- [x] R2's real discriminator: after `<S-Right>` `<Esc>`, a fresh `v` then `l`
      still **extends** (mode `v`). Recorded in the output beside the plain
      `v`, `l` case, with the measured note that the plain case passes with or
      without the autocmd and therefore proves nothing on its own.
- [x] R7: `<C-c>` on a selection returns to normal mode with the selection in
      the unnamed register; `<C-v>` over a selection replaces that text, and a
      second `<C-v>` elsewhere pastes **the same** text (the register
      survived). Whether the scratch clipboard provider's copy counter moves is
      reported as measured either way — E.3 measured that this headless Neovim
      does not route implicit yanks through the provider under
      `clipboard=unnamedplus`, so the unnamed register carries the proof and
      the provider is the containment check that no probe reached the real
      pasteboard.

Counterfactuals. Each mutates a scratch copy and prints `sha … -> sha …` on one
line before and after, shows the copy **red** with a `FAIL` naming this gate and
the subject, and hashes back after repair:

- [x] Delete the `ModeChanged` autocmd → the escape-path probe collapses:
      measured `mode=n`, anchor = cursor = column 5, where the correct module
      gives `mode=v`, anchor 4 → cursor 5.
- [x] `lv<Right>` → `v<Right>` on insert `<S-Right>` → anchor moves 3 → 2 and
      the selection becomes `jk`.
- [x] Drop `count` from the collapse branch → `<S-Down>` `3j` lands on line 4,
      not line 6.
- [x] `"_dP` → `p` on visual `<C-v>` → the second paste puts the wrong text.
- [x] Vacuity control, with the module absent: all 22 lhs read `maparg == ""`
      **and** the keys still do something — normal `<S-Left>` moves word-left
      (column 3 → 1) and `<S-Down>` pages down (line 2 → 8). The control
      asserts those two built-in effects by value, so it cannot pass by
      measuring nothing. This is the `<C-l>` class E.3 found, on four keys per
      mode: R3 and R5 **replace** Neovim's built-in word-motion and page
      motions on `<S-Left>`/`<S-Right>` and `<S-Up>`/`<S-Down>`, deliberately
      and now on the record.

## Verify and Proof

```sh
bash tests/nvim-shift-select.sh          # the node's gate, both stages
bash tests/nvim-keymaps.sh --tree        # E.3 owns keymaps.lua; it must stay green
bash tests/nvim-options.sh --tree        # the census entry this node adds
git diff --exit-code -- home/dot_config/nvim/lua/config/keymaps.lua
```
