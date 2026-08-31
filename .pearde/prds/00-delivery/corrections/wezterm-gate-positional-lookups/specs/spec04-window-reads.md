---
est: 1.5h
footprint:
  - tests/live-bugs.sh
  - gates/wave-status.sh
---

# spec04 — the two `sed -n` window reads, plus the wave-4 proof

Fix the two window reads PRD R2 names — `tests/live-bugs.sh:174` and
`gates/wave-status.sh:337` — each by the mechanism its input admits, land a
counterfactual per site, and close the PRD's acceptance with the wave-4 run.
The two sites are different cases and get different verdicts; both verdicts
land as comments at the site.

## R2 verdict, per site (record it — PRD acceptance asks for it with its measurement)

| site | input | verdict |
|---|---|---|
| `live-bugs.sh:174` | live Lua (`~/.config/nvim/lua/…`) | the read must be taken over comment-stripped text: anchor AND window both skip `--` lines |
| `wave-status.sh:337` | markdown prose (`prds/06-help/prd.md`) | prose by design — it is norm's own wrapped-link fixture, and markdown has no comment syntax to strip; the bound cannot be anchored, so it is made self-checking: exactly one match, or red |

Measurements 2026-08-24: the FileType autocmd sits at
`~/.config/nvim/lua/plugins/treesitter.lua:31`, the ModeChanged one at
`~/.config/nvim/lua/config/keymaps.lua:58`, neither preceded by a quoting
comment today; `\[tv needs a$` matches exactly one line of
`prds/06-help/prd.md`, line 42.

## Site 1 — tests/live-bugs.sh:172-183, `ungrouped()`

Today: `ln` is the first substring hit of `nvim_create_autocmd("$ev"`, and
`sed -n "${ln},$((ln + 6))p"` is a fixed 7-line span. Two defusals, both in
the passing direction (the assertion is `group =` count `-eq 0`): a quoting
comment above the call moves the window off the code, and a comment inside
the span pushes a real `group =` line out of it.

Rewrite `ungrouped()` in place — one awk pass, keeping its `file, event`
signature and its return codes (0 ungrouped, 1 grouped, 2 call absent):
anchor on the first NON-`--`-comment line containing
`nvim_create_autocmd("$ev"`, collect that line and the next 6 NON-comment
lines, count `group *=` over those 7 code lines.

Constraints:

- `tests/live-bugs.sh` does not source `gates/lib.sh` (its own `chk`, its
  own dialect — `gates/lib.sh:6-10` records the three-script agreement).
  Keep it that way: the helper stays local to `ungrouped()`.
- Conclusions unchanged (PRD R5): treesitter FileType ungrouped,
  keymaps ModeChanged ungrouped, the `autocmds.lua` grouped control still
  passes.

Counterfactual, landed beside the L-8 checks: copy the live
`treesitter.lua` into scratch (`mktemp -d`); insert the comment
`-- vim.api.nvim_create_autocmd("FileType", {` at least 8 lines above the
real call; insert `group = vim.api.nvim_create_augroup("cf_l8", {}),` into
the real call's option table. `ungrouped` on the copy must return non-zero —
`chk` that it does. (The old substring anchor lands on the comment, sees no
`group =` in prose, and returns 0 — the defusal being closed.)

## Site 2 — gates/wave-status.sh:336-345, selftest section 6

Today: `ln` is `grep -n '\[tv needs a$' … | head -1`, the window is
`sed -n "${ln},$((ln + 1))p"`, and the guard is `test -n "$ln"` — presence,
not uniqueness. A second line ending `[tv needs a` moves the window and the
selftest then norms two different lines.

- Factor the lookup into a function over a file argument.
- Before using the position, assert the match count is exactly 1
  (`grep -c '\[tv needs a$'`); a duplicate turns the selftest red instead of
  silently moving the window. The existing `test -n "$ln"` chk becomes the
  uniqueness chk (its label says so — "exactly once").
- Counterfactual, landed in section 6: copy `prds/06-help/prd.md` into `$T`;
  insert one extra line ending `[tv needs a` above the real one; `chk_fail`
  the uniqueness bound on the copy.
- The wrapped-link conclusion itself (norm collapses it; the raw two lines
  do not contain the phrase) is unchanged.

## Acceptance

- [x] `ungrouped()` is one `awk` invocation over the file itself — the
      `/^[[:space:]]*--/ { next }` rule runs before both the anchor rule and
      the window rule, so a `--` line is neither the anchor nor one of the
      seven counted lines; no pipe, no strip-pass, so nothing is renumbered.
      Return codes kept (0 ungrouped, 1 grouped, 2 absent): probed
      2026-08-24 against `~/.config/nvim/lua/config/options.lua NoSuchEvent`
      — "new=2 old=2".
- [x] Reproduced (fixture: the live `~/.config/nvim` tree, 2026-08-24) —
      `bash tests/live-bugs.sh` prints "PASS  treesitter.lua's FileType
      autocmd has no group = in its option table", "PASS  keymaps.lua's
      shift-select ModeChanged autocmd has no group = either", "PASS
      control: config/autocmds.lua DOES group all of its autocmds …".
      Old-vs-new probed side by side on both live files: "plugins/
      treesitter.lua FileType : live old=0 new=0" and "config/keymaps.lua
      ModeChanged : live old=0 new=0" — no conclusion moved (PRD R5).
- [x] Landed beside the L-8 checks; run 2026-08-24: "PASS  counterfactual:
      quoting comment + planted group = reads GROUPED (non-zero) on the
      mutated copy". The defusal it closes is *reproduced* (fixture: the two
      live autocmd files, mutated in scratch) and run twice with a different
      input — mutating `treesitter.lua`/`FileType` and `keymaps.lua`/
      `ModeChanged` the same way gives "mutated old=0 new=1" for both: the
      old substring anchor lands on the planted comment, finds no `group =`
      in the prose window and reports UNGROUPED; the code-line read finds
      the planted group and reports GROUPED.
- [x] `wrapped_link_line` returns the position only when `grep -c` is 1;
      selftest run 2026-08-24: "PASS  norm: the wrapped link is in
      prds/06-help/prd.md exactly once (line 42)" and "PASS  norm: the
      window bound goes red on the duplicated copy instead of silently
      moving". Reproduced twice with a different input (fixture: scratch
      copies of `prds/06-help/prd.md`) — duplicate planted *above* the real
      line and duplicate planted *below* it both give "matches=2 rc=1",
      while the unmutated file gives "matches=1 rc=0 out='42'". Measured
      what the old presence-only bound did on the same copy: it kept line 42
      and read the planted line plus the real line's first half — the window
      moved, silently.
- [x] `tests/live-bugs.sh` carries the comment-stripped-input verdict above
      `ungrouped()` with "the FileType autocmd sits at …/treesitter.lua:31,
      the ModeChanged one at …/keymaps.lua:58, neither preceded by a quoting
      comment today"; `gates/wave-status.sh` carries the prose/self-checking
      verdict above `wrapped_link_line` with "one match, line 42 of
      prds/06-help/prd.md". Both measurements re-taken 2026-08-24 and
      reproduced: `grep -n nvim_create_autocmd` gives `31:` and `58:`,
      `grep -c '\[tv needs a$' prds/06-help/prd.md` gives `1`, at line 42.
- [x] `bash tests/live-bugs.sh` run alone 2026-08-24: 160 PASS, 0 FAIL,
      final line "OK — every live-bug record still matches the config it
      describes, and every row is owned", `EXIT=0`.
- [x] `bash gates/wave-status.sh --selftest` run 2026-08-24: 20 PASS, 0
      FAIL, final line "── selftest rc=0 ──", `EXIT=0`.
- [x] `bash gates/wave-status.sh --run 4` run 2026-08-24 into a `mktemp`
      log (`/var/folders/.../T/wave4-run.Tjfawr`, never a shared name):
      "══ wave 4 — PENDING 17/18 ══", `EXIT=0`, and every one of the 18
      registered gates prints "PASS  wave 4 gate: …" — including this PRD's
      four: `bash tests/wezterm-copy-mode.sh`,
      `bash tests/wezterm-tab-content-state.sh`, plus `bash
      tests/shell-listing.sh` and the nvim set. **One non-gating failure,
      pre-existing and outside this PRD:** "wave 4 gate: bash
      tests/wezterm-launchd-path.sh exited 1 — reported, not gating (wave is
      PENDING)", on "FAIL  spawn/cf2: the copy no longer seeds PATH" (94
      run, 93 passed, 1 failed). Reported to the orchestrator, not fixed
      here — `tests/wezterm-launchd-path.sh` is in no spec's `footprint:`
      and is byte-untouched by this session.

## Verify and Proof

```sh
bash tests/live-bugs.sh; echo "EXIT=$?"
bash gates/wave-status.sh --selftest; echo "EXIT=$?"
LOG="$(mktemp "${TMPDIR:-/tmp}/wave4-run.XXXXXX")"
bash gates/wave-status.sh --run 4 2>&1 | tee "$LOG"; echo "EXIT=${PIPESTATUS[0]} LOG=$LOG"
```
