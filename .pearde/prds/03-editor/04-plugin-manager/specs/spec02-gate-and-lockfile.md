# spec02 — the standing gate, the lockfile, and the E.1 gate seed

Write `tests/nvim-plugin-manager.sh` (stages `--tree` / `--headless` /
`--network`), commit `home/dot_config/nvim/lazy-lock.json` (R5), keep
`tests/nvim-options.sh` green now that `init.lua` requires `config.lazy`,
and register the hermetic stages in `gates/waves.tsv` wave 2.

**Est:** 1.75h

**Footprint:** `tests/nvim-plugin-manager.sh`, `tests/nvim-options.sh`,
`home/dot_config/nvim/lazy-lock.json`, `gates/waves.tsv`
<!-- waves.tsv is currently held by the T.3 lane — one-cell append to the
     wave-2 row; the orchestrator serializes if the lane is still open -->

## The E.1 gate seed — do this first, it is a regression on landing

The moment spec01's `require("config.lazy")` lands, every `nv_in` call in
`tests/nvim-options.sh` hits the bootstrap with an empty scratch data dir
and clones from the network — or, offline, exits 1 and turns every E.1
check red. Two edits to `tests/nvim-options.sh`:

1. Add a seed helper: copy `~/.local/share/nvim/lazy/lazy.nvim` into
   `<root>/data/nvim/lazy/lazy.nvim` for the main staging `$S` and inside
   `cf_stage`. A missing live clone is
   `PROBE-ERROR: … ASSUMPTION MISSING` and exit 127, never a skip — the
   same shape as the missing-nvim check above it. The vacuity-control
   root stays unseeded: its `init.lua` is empty and never reaches lazy.
2. Grow the `--tree` census to the post-E.2 list, LC_ALL=C order:
   `./init.lua ./lazy-lock.json ./lua/config/lazy.lua
   ./lua/config/options.lua ./lua/plugins/init.lua`. The census stays
   exact-equality — it is E.1's scope guard; each editor node extends it.

Checker note, so nobody chases it: `checker.enabled=true` cannot fire in
these gates — every session quits via `-c qa` / `+qa` during startup,
before lazy's deferred checker runs; and its writes would be
scratch-bound anyway. Put this in a comment near the seed helper.

## `tests/nvim-plugin-manager.sh`

Source `gates/lib.sh`; use `chk`/`chk_ok`/`chk_fail`, `gates_tmpdir`,
`snapshot_paths` over `~/.config/nvim`, `~/.local/share/nvim`,
`~/.local/state/nvim`, `~/.cache/nvim` + `assert_unchanged` at exit
(the seed READS `~/.local/share/nvim` — listing mode proves read-only).
`/usr/bin/grep` always. Runner: the same `nv_in` scratch-XDG shape as
`tests/nvim-options.sh`, plus a seed helper and a watchdog —
`timeout` does not exist on this machine; run nvim backgrounded, poll
`kill -0` for 10s, `kill -9` on overrun and record TIMEOUT.

**`--tree`** (hermetic, no nvim run) — text checks, each written as a
function over a path so counterfactual copies reuse it:

- `lua/config/lazy.lua`: carries `--filter=blob:none`, `--branch=stable`,
  `rtp:prepend`, `os.exit(1)`, and the `nvim_list_uis` guard around
  `getchar` with its measured-hang comment (the guard reads as dead code
  without the reason).
- `init.lua`: comment-stripped, first require is `config.options`, last
  require is `config.lazy` (R1's slice).
- `lua/plugins/init.lua`: comment-stripped content exactly `return {}`.
- `lazy-lock.json`: parses as JSON (python3), holds key `lazy.nvim` whose
  `commit` is 40 hex chars (R5).
- Selftests, every invocation (a check that cannot fail proves nothing):
  a copy with `--branch=stable` deleted goes red; a copy of the lockfile
  with a truncated commit goes red; a copy of `plugins/init.lua` holding
  a real spec string goes red.

**`--headless`** (hermetic; seeds from `~/.local/share/nvim/lazy/lazy.nvim`,
assumption-FAIL if absent):

- Seeded staged launch exits 0, stderr free of `No specs found`.
- The `lazy.core.config` opts probe from spec01, one `chk` per value:
  R4 defaults + hererocks, R6 checker/change_detection, R7 colorscheme,
  R8 the six disabled plugins exactly.
- `exists(':Lazy') == 2` — the manager's command is registered.
- Lazy-loading proof (the PRD's third acceptance box, at state level —
  no plugin exists yet to watch in the `:Lazy` TUI, and headless cannot
  render it; `lazy.core.config.plugins[name]._.loaded` is the same data
  the TUI shows): write a scratch `plugins/demo.lua` naming a local
  `dir=` fake plugin with `cmd = "FakeplugPing"`; assert not loaded
  after startup, loaded after invoking the command; remove the scratch
  spec file. Also assert a triggerless `dir=` spec IS loaded at startup —
  that is `defaults.lazy=false` observed, not read back.
- Clone failure (R2 + the offline acceptance box): unseeded root, `git`
  shim exiting 128 first on PATH, watchdog — expect
  `Failed to clone lazy.nvim` on stderr, exit 1, no timeout.
- Counterfactuals, each a `cf_stage` copy: import module renamed →
  `No specs found` appears (the import is load-bearing);
  `plugins/init.lua` deleted from the copy → `No specs found` appears
  (the anchor is load-bearing — measured: missing AND empty dir both
  error); `checker enabled` flipped false → opts check red; `netrwPlugin`
  dropped from disabled list → opts check red; the `nvim_list_uis` guard
  sed'd back to bare `vim.fn.getchar()` → the watchdog fires (the guard
  is load-bearing — this one costs its 10s deliberately).

**`--network`** (real; declared assumption, FAIL not skip — the
`tests/dev-image.sh --build` shape):

- Assumption probe: `git ls-remote https://github.com/folke/lazy.nvim.git HEAD`
  succeeds, else `ASSUMPTION MISSING — network` and stop.
- Fresh root, **no seed**: staged launch bootstraps for real. Assert the
  clone exists, HEAD sits at the `stable` tag's commit, and
  `git config remote.origin.partialclonefilter` is `blob:none` — the
  flags took effect, not just appear in the text. Measured 2026-08-22:
  lazy.nvim's `stable` is a TAG, so `--branch=stable` detaches HEAD at
  the tag commit and `rev-parse --abbrev-ref HEAD` says `HEAD` — the
  commit comparison is the flag's observable effect.
- Reproducibility (R5, the PRD's first acceptance box):
  `nvim --headless '+Lazy! restore' +qa` exits 0, then
  `git -C <clone> rev-parse HEAD` equals the repo lockfile's `lazy.nvim`
  commit. The subject set is lazy.nvim alone — the only plugin at E.2;
  the check widens as E.5+ land, say so in a comment. Restore, not
  install, is the comparison point: the bootstrap clones stable HEAD,
  which may sit past the locked commit.
- `nvim --headless '+Lazy! sync' +qa` exits 0 — the frontmatter `verify:`
  in its staged form. Run it AFTER the restore comparison: sync moves
  HEAD and rewrites the scratch lockfile. The repo lockfile is never
  compared against post-sync scratch state — upstream moving must not
  redden the gate.

No-arg runs all three stages.

## `home/dot_config/nvim/lazy-lock.json` (R5)

Generate it from a real run, never by hand: run the `--network` flow once
and copy the scratch config's `lazy-lock.json` into
`home/dot_config/nvim/`. Expected content: the single `lazy.nvim` entry.
Lockfile policy, as a comment in `lua/config/lazy.lua` (the lockfile
itself cannot carry comments — JSON): the lockfile lives beside `init.lua`
and is committed; lazy rewrites the deployed copy on sync/update, and the
change is carried back to the repo in the same commit as the spec change
that caused it; every plugin node (E.5+) commits its lockfile delta with
its spec.

## `gates/waves.tsv`

Append to the wave-2 gates cell:
`| external bash tests/nvim-plugin-manager.sh --tree | external bash tests/nvim-plugin-manager.sh --headless`.
The hermetic stages only — `--network` stays out of the wave row, the
`tests/dev-image.sh --static` precedent. T.3's lane holds this file; if
it is still open at implementation time, hand the one-line append to the
orchestrator instead of racing it.

## Acceptance

- [x] `bash tests/nvim-plugin-manager.sh --tree` exits 0; all selftest
      mutations red-then-caught. 2026-08-22: exit 0; `--branch=stable`
      deleted, truncated commit, spec-in-anchor — each selftest PASS
      (i.e. the mutated copy went red).
- [x] `bash tests/nvim-plugin-manager.sh --headless` exits 0 with the
      clone-failure probe under 10s and every counterfactual naming its
      red check. 2026-08-22: exit 0; clone failure exit 1 in <10s;
      import-rename and anchor-delete → `No specs found`, checker-off and
      netrw-drop → opts check red, guard-removed → watchdog TIMEOUT.
- [x] `bash tests/nvim-plugin-manager.sh --network` exits 0: real
      bootstrap, restore-to-lockfile commit equality, `Lazy! sync` exit 0.
      2026-08-22: restored HEAD `306a05526ada86a7b30af95c5cc81ffba93fef97`
      == repo lockfile commit; sync exit 0.
- [x] `bash tests/nvim-options.sh` exits 0 on the post-E.2 tree — seeded,
      census grown, no network touched by its hermetic stages. 2026-08-22:
      exit 0, 0 FAIL lines.
- [x] `assert_unchanged` green in both gates: no write to real
      `~/.config/nvim`, `~/.local/share/nvim`, `~/.local/state/nvim`,
      `~/.cache/nvim`. 2026-08-22: PASS in every run quoted above.
- [ ] `git show :home/dot_config/nvim/lazy-lock.json` parses and carries
      the `lazy.nvim` commit the restore check pinned. Open until the
      orchestrator commits: the working-tree lockfile carries
      `306a05526ada86a7b30af95c5cc81ffba93fef97` (verified by the gate's
      `lock_ok` + the restore equality); the lane does not commit.

## Verify

```sh
bash tests/nvim-plugin-manager.sh          # all three stages
bash tests/nvim-options.sh                 # E.1 still green post-seam
```
