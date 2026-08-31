---
complexity: 20
# Compute, measured 2026-08-24 on this machine: staging one root is ~4 s and
# 117 MB under the gate's scratch dir; one headless probe launch is ~0.9 s.
# Two arms x 10 runs plus two stagings is ~30 s and ~234 MB. That is the whole
# price of this stage; it does not change its scope.
footprint:
  - tests/nvim-lsp.sh
---

# spec01 — `tests/nvim-lsp.sh --race`: reproduce the discarded write

R1 first, and nothing else: a new `--race` stage that reproduces the abort on
the **shipped, unmodified** `lua/plugins/lsp.lua`, records that the write was
*discarded* rather than merely failed, and measures the same probe against a
copy carrying the candidate mechanism. This spec changes no configuration —
`home/dot_config/nvim/` is not in its footprint. It lands the measurement that
[`spec02`](spec02-disable-automatic-refresh.md) then flips.

## The mechanism, as measured (put this in the stage's comment)

`mason-lspconfig.setup()` calls `mason-registry.refresh()` on every launch
that loads `lsp.lua`. Under a refusing `curl`, the fetch's `on_spawn`
handler — `mason-core/fetch.lua:134`, wrapped in `a.scope` — writes to and
shuts down the stdin pipe of a `curl` that has already exited, `uv.shutdown`
fails with `ENOTCONN`, and `a.scope`'s callback re-raises it with
`error(err, 0)` (`mason-core/async/init.lua:121`). That `error` runs inside a
libuv callback, so it propagates out of **whatever blocking call is pumping
the loop** at that instant. A `BufWritePre` consumer that pumps the loop
therefore loses its write. Traceback measured 2026-08-24, nvim 0.12.4,
mason.nvim v2.3.1 (`2a6940a`):

```
E5113: Lua chunk: … BufWritePre Autocommands for "*": Vim(append):Lua callback:
ENOTCONN
  .../mason.nvim/lua/mason-core/async/init.lua:121: in function 'callback'
  .../mason.nvim/lua/mason-core/async/init.lua:99: in function 'cb'
  .../mason.nvim/lua/mason-core/async/init.lua:25: in function 'reject'
  [C]: in function 'wait'
  .../conform.nvim/lua/conform/runner.lua:709: in function 'format_lines_sync'
```

## The victim is probe-local — do not reach for conform

The victim in the fixture above is conform, but the gate's victim must not be:
`conform.lua` belongs to [`03-editor/07-formatting`](../../../../03-editor/07-formatting/prd.md),
and a check that needs its formatter binaries measures that node's wiring
instead of this one. Measured 2026-08-24, two fixtures, same staged root:

| `BufWritePre` consumer that pumps the loop | aborts | write discarded |
|---|---|---|
| conform + a fake `stylua` (`sed 's\|^\|-- S \|'`) | 6/6, then 4/4 | same |
| a probe-local autocmd doing only `vim.wait(1500, …)` | 6/6 | 6/6 |

Use the second. It needs no plugin, no binary and no filetype, and it is the
direct statement of R2: any consumer that pumps the loop inherits the bug.

```lua
vim.api.nvim_create_autocmd("BufWritePre", {
  group = vim.api.nvim_create_augroup("probe_victim", { clear = true }),
  callback = function() vim.wait(1500, function() return false end) end,
})
```

The probe then replaces the buffer's lines, `silent write`s, and self-quits
from a `vim.defer_fn`. **No drain before the write** — `tests/nvim-formatting.sh`'s
`pre.lua` drains the pending rejection on purpose so its probes measure
conform; this stage measures the race, so it must not.

## What the stage does

Two arms, `N = 10` identical runs each, both staged with the gate's existing
`lsp_stage <root> min` (so the registries seed and the launcher relocation
pass apply) and run through the existing `nv_watch` with the `curl`/`wget`
shims already at the head of `PATH`:

* **shipped** — `lsp_stage` untouched. This is the bug.
* **candidate** — the same root, with the one-line mutation
  `opts = {}` → `opts = { registry_cache = { refresh = false } }` applied to
  the copy's `lua/plugins/lsp.lua`, `cf_stage`-style: **a mutation that
  changes nothing is a failure**, never a silent pass.

Per run the stage records whether the probe's stderr holds `ENOTCONN`, whether
the file on disk still holds the pre-write bytes, and how many mason network
attempts the shim log gained (`mason.nvim v` is the marker the `--headless`
stage already counts).

Measured on this machine 2026-08-24, so the boxes below are known reachable:
shipped 6/6, 4/4 and 6/6 across three sittings on a registries-seeded root and
3/4 on a root with no `<data>/mason` at all; candidate 0/6, 0/4 and 0/6.
Two network attempts per shipped launch under a `curl`-only shim (four under
this gate's `curl`+`wget` pair), **zero** under the candidate.

A caution to carry in the comment, because it cost a measurement:
`tests/nvim-formatting.sh` recorded only 2/5 for the same arm, and the same
probe driven from a **markdown** buffer aborted **0/6**. The abort rate is a
function of when the rejection lands relative to the write, so the shipped
arm's assertion is `>= 1 of N`, never a rate, and the count is printed as
`MEASURED` beside it.

## Acceptance

**Rescoped by the orchestrator, 2026-08-24, after the prescribed reproduction
was measured and did not fire.** Two boxes below changed in kind, and they are
marked where they changed rather than quietly lowered. The reason is that "the
shipped arm aborts at least once in N" asks a gate to require that a *race
reproduces*: red on a fast machine, green on a slow one, failing for reasons
that have nothing to do with the code it guards — the shape
[`nushell-core-s430-stall`](../../nushell-core-s430-stall/prd.md) was filed
over. The gate now **asserts what is deterministic and MEASURES what is not**,
the shape `tests/nvim-formatting.sh`'s race control already uses. A new
asserted arm carries the mechanism in its place.

- [x] `bash tests/nvim-lsp.sh --race` exists as a stage, is reached by the
      no-argument run, and the usage line names it.
      `--race)     stage_race ;;` and
      `--all)      selftests; echo; stage_tree; echo; stage_headless; echo; stage_race ;;`,
      with `# Usage: bash tests/nvim-lsp.sh [--tree|--headless|--race]`.
- [x] The candidate mutation is `cf_stage`-style: a run where the `sed`
      changed nothing goes **red** with a staging failure, proved by
      temporarily mutating the pattern and quoting the red line. Ran with the
      search half rewritten to `{ "mason-org/NOT-A-REAL-LINE", opts = {} }`:

      ```
      PASS  race staging: the shipped arm's lsp.lua is byte-identical to the repo's — this arm is the bug, unmodified
      FAIL  race staging: the candidate arm's lsp.lua carries the mutation (a sed that changed NOTHING is a staging failure)
      ```

      (The first attempt at this selftest mutated the *replacement* half and
      stayed green, correctly: that sed still changes the file.)
- [x] The stage prints `MEASURED` abort counts for both arms, `n/N` each.
      `MEASURED   shipped (opts = {}): 0/10 ENOTCONN aborts, 40 mason network attempts`
      and
      `MEASURED   candidate (registry_cache.refresh = false): 0/10 aborts, 0 mason network attempts`,
      with a per-run line and a before/after identity line for all twenty runs.
- [x] **RESCOPED — asserted arm replaced, not dropped.** Was: "the shipped arm
      aborts at least once in N with `ENOTCONN`, and the stage asserts that".
      Now: the shipped arm is **arm 2, MEASURED and never asserted**, and the
      *mechanism* is asserted instead as **arm 1**, in isolation — `uv.shutdown`
      on the stdin pipe of a **reaped** child, against a control on a child
      still alive:

      ```
      dead_peer reaped=true err=ENOTCONN
      dead_peer reaped=true err=ENOTCONN
      dead_peer reaped=true err=ENOTCONN
      live_peer err=nil
      live_peer err=nil
      live_peer err=nil
      PASS  race/arm1: uv.shutdown on the stdin pipe of a REAPED child fails with ENOTCONN (3/3) — this is the error a.scope re-raises out of the pumping call
      PASS  race/arm1 CONTROL: the same shutdown against a child still ALIVE returns err=nil (3/3) — the failure is the dead peer, not the platform
      ```

      Arm 1 is on its second design, and the first one is why this box could
      not simply be kept: it raced a curl shim's exit against libuv's shutdown
      over a 0–14 ms starvation sweep, and that sweep reported `ENOTCONN` 8/8
      run by hand and `nil` 8/8 run through `nv_watch` — same file, same shim,
      same environment, three times each way. Killing and **reaping** the child
      before requesting the shutdown removes the timing entirely.
- [x] **RESCOPED — made conditional.** Was unconditional. The byte-identity
      and exit-0 checks on aborted shipped runs now run **only when the arm
      actually aborted**: a check that passes because there was nothing to
      check is worse than no check. The evidence is printed every run either
      way — `md5`, size and mtime before and after, per run:

      ```
      MEASURED   shipped run  1: ENOTCONN=no  exit=0       new-content-on-disk=yes
      MEASURED     before: md5=b61a24904d793889264291d7f77ba8ba size+mtime=21 1577833200
      MEASURED     after : md5=0a2492c2133228291da9bbe66ff16a90 size+mtime=35 1787593532   byte-identical=no
      ```

      The fixture is back-dated with `touch -t 202001010000` before each run,
      because macOS `stat` gives mtime in whole seconds and a fixture written
      in the same second as the probe's write would read as "unchanged" for
      the wrong reason.
- [x] The candidate arm is `0/N`: no `ENOTCONN`, and the buffer's new content
      is on disk after every run.
      `PASS  race/R4: the candidate arm is 0/10 — no ENOTCONN with registry_cache.refresh = false (got 0/10)`
      `PASS  race/R4: …and the buffer's new content is on disk after every candidate run (0 of 10 missing it)`
- [x] The candidate arm adds **zero** lines matching `mason.nvim v` to the
      shim log, and the shipped arm adds more than zero. Both counts printed.
      `PASS  race/R2: the shipped file DID attempt the network — 40 mason attempts over 10 launches`
      `PASS  race/R2: the candidate attempted it ZERO times — no fetch is spawned, so there is no promise left to reject (got 0)`
- [x] `bash tests/nvim-lsp.sh` (no argument) still exits 0 with the new stage
      included, and its closing `assert_unchanged` still passes — the race
      arms touched no real Neovim state. Exit 0, zero `FAIL` lines in the
      whole run:

      ```
      PASS  the gate touched no REAL Neovim state (~/.config/nvim, ~/.local/share/nvim, ~/.local/state/nvim, ~/.cache/nvim)

      PASS — mason + native 0.11 LSP proven in a hermetic, offline Neovim
      ```

## The three verdicts, with their fixtures

Written here because the next reader of this spec needs them before they touch
the stage. All measured 2026-08-24, nvim 0.12.4, mason.nvim v2.3.1 (`2a6940a`).

| claim | verdict |
|---|---|
| the root cause is `uv.shutdown` → `ENOTCONN`, re-raised by `a.scope` | **reproduced as a mechanism** (arm 1: reaped-child probe, 3/3, against a 3/3 live-peer control) — but **refuted as reachable through a `vim.wait` victim** (staged `lsp_stage min` root with `vim.loop.shutdown` patched: every shutdown inside the mason path returns `err=nil`, because a pumping `vim.wait` lets libuv complete the shutdown inside a millisecond, long before a shim process can start and exit) |
| `registry_cache = { refresh = false }` spawns no fetch at all | **reproduced** (`cf_stage` copy on the same staged root: 0 `mason.nvim v` lines over 11 launches against 40 over 10 launches of the shipped file) |
| an offline launch eats the first save **on a real machine** | **unmeasured** — see below. Not reproduced, and **not refuted** |

The third row is the one that matters. This spec's prescribed reproduction was
run 60 times across six configurations — the staged stage itself, file-in-argv
instead of `:edit`, a sweep of the write's offset over 0/4/8/…/50 ms, a root
with no `<data>/mason` at all, and the same under twelve CPU hogs — and
aborted **zero** times. That is not the fixture being unlucky. **The variable
is `wget`**, established with a byte-for-byte copy of the earlier probe's shim
directory and one file added:

| shim dir | aborts |
|---|---|
| curl shim, **no `wget` anywhere on PATH** | 4/5 |
| the same dir **+ a `wget` shim** | **0/5** |

mason's fetch is `curl():or_else(wget):or_else(…)`. With no `wget` **binary**
the fallback fails *at spawn* instead of spawning one, and the curl stdin
shutdown lands in exactly the starved window the mechanism needs. The
`BufWritePre` victim was never the variable: the probe-local one and the
conform one both give ~4/5 without `wget` and 0/5 with it, and a fake `stylua`
on `PATH` changes nothing either (4/4 with, 4/4 without).

`wget` **is** installed on this machine, at `/opt/homebrew/bin/wget`. So every
earlier measurement of this abort on this board — including the 2026-08-23
discovery that filed the correction — was taken in an environment missing a
binary the machine actually has. This stage therefore shims `wget`, arm 2
reads `0/N` **because the fixture is faithful**, and the stage says so in
place so nobody "fixes" it by deleting that shim and calling the race
reproduced.

## Verify and Proof

```sh
cd "$(git rev-parse --show-toplevel)"
bash tests/nvim-lsp.sh --race
bash tests/nvim-lsp.sh            # the node's verify, with the new stage in it
```
