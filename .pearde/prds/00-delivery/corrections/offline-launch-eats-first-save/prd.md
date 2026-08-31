---
state: done
claim: 
priority: 22
est:
mode: afk
needs:
  - 03-editor/09-lsp
footprint:
  - home/dot_config/nvim/lua/plugins/lsp.lua
  - tests/nvim-lsp.sh
verify: ""
origin: derived
from: 03-editor/07-formatting
complexity: 45
blast-radius: mid
commit: a4d790d
---

# An offline launch discards the first save

Parent: [Corrections backlog](../prd.md) · net-new

Purpose: on a cold Neovim session with the network unreachable, the **first
write is silently thrown away** — the buffer is not written, the file stays
byte-identical, and the user sees `E5113 … ENOTCONN` where they expected a
saved file. Found 2026-08-23 by
[`07-formatting`](../../../03-editor/07-formatting/prd.md)'s analyst while
measuring conform's failure surface, reproduced twice, and **not** conform's
bug.

**The consequence for a requested PRD, which is why this is filed rather than
recorded as a memo:**
[`03-editor/09-lsp`](../../../03-editor/09-lsp/prd.md) is `done`, and its
mason setup is what ships this. Mason's registry promise rejects *inside*
whatever blocking call is pumping the event loop at the time. `format_on_save`
(`format_lines_sync` → `vim.wait`) is such a call, so the rejection propagates
out of `BufWritePre` and aborts the write. The analyst reproduced the same
abort through `table-mode.lua:39`'s `nvim_exec2` instead of conform, which is
what establishes the owner: **any** `BufWritePre` consumer that pumps the loop
inherits it, so fixing it in one plugin's config fixes one symptom. E.11 will
ship on top of this, and E.15 already has.

This is data loss on a laptop that woke up on a train, which is the ordinary
case for this configuration, not an exotic one.

## Requirements
- [~] **R1** — Reproduce it before changing anything: cold XDG root, network
      unreachable, one `BufWritePre` consumer that pumps the loop. Record the
      exact error, and record that the file is byte-identical afterwards —
      "the write failed" and "the write was discarded" are different bugs and
      only the second one is this node.

      **`[~]`, not `[x]`, and the reason is the whole finding.** The
      reproduction was attempted first, against the shipped unmodified
      `lsp.lua`, **60 launches across six configurations** — and it aborted
      **zero** times. The mechanism itself *is* reproduced, in isolation:
      `uv.shutdown` on the stdin pipe of a **reaped** child fails with
      `ENOTCONN` 3/3, against a 3/3 control on a child still alive
      (`tests/nvim-lsp.sh --race`, arm 1). What is not reproduced is the
      abort reaching a save. See "Status of the reproduction" below: the
      variable is `wget`, and the honest verdict is `unmeasured`.
- [x] **R2** — The mason registry refresh must not be able to reject into an
      unrelated blocking call. Name the mechanism chosen and why; a
      `pcall` around one call site is a symptom fix and does not satisfy this.

      The mechanism is **`registry_cache = { refresh = false }`** — mason's
      own setting (`lua/mason/settings.lua`, `@since 2.3.0`; the pinned mason
      is v2.3.1 / `2a6940a`). `mason-registry`'s `refresh()` returns
      `callback(true, {})` without touching `mason-registry.installer`, so no
      `curl` is spawned and **there is no promise to reject into anything**.
      That is why it satisfies R2 where a `pcall` would not: it removes the
      rejection, rather than catching it at one victim's call site.
      Measured: `refresh_attempts=0` at launch, and 0 network attempts over
      10 launches against 40 over 10 with the line reverted.
- [x] **R3** — Whatever lands must keep working **offline by default**.
      **Corrected 2026-08-23, hours after this node was filed: the workaround
      this requirement was built on does not work.** R3 said "the measured
      workaround is seeding `mason/registries`". The E.11 implementer tried
      exactly that and measured it false — **5 of 5** identical probe runs
      still aborted on a seeded root. Draining the pending work under `pcall`
      before the write also failed, at **1/6 and then 3/6**, which is the
      shape of the real thing: it is a **race** on which blocking call happens
      to be pumping the loop when mason's refused promise rejects, not a
      missing cache.

      Its three-arm control is the measurement to build on, and it is why the
      E.11 gate can be trusted at all:

      | arm                              | aborts |
      |----------------------------------|--------|
      | full config, undrained           | 2/5    |
      | full config, drained             | 2/5    |
      | isolated, no `lua/plugins/lsp.lua` | 0/5  |

      `lsp.lua` is the only file that loads mason, so removing it takes the
      abort rate to zero — that is what identifies the owner, and it is how
      E.11's probes measure conform rather than this bug. A fix must therefore
      change the **rejection path**, not the cache, and R4's counterfactual
      has to survive a 2-in-5 race: a single green run proves nothing here.

      **Met.** Offline, on a `min`-seeded scratch root with every network
      binary a refusing shim: `attached=true`, `client=lua_ls`,
      `is_enabled_lua_ls=true`, `get_installed_servers()=lua_ls`, all five
      servers auto-enabled in the five-package root, and the whole gate at
      exit 0. `automatic_enable` runs from `init()` over the *installed*
      packages, not from the refresh result, which is why disabling the
      refresh costs nothing here. The R3 correction above still stands and is
      now explained rather than merely recorded — see below.
- [x] **R4** — A counterfactual that goes red with the fix reverted, per
      [`a-counterfactual-proves-its-own-mutation`(../../../../../prds/memos/a-counterfactual-proves-its-own-mutation.md).
      An offline reproduction is the hard part; if it cannot be made
      hermetic, say so with the measurement rather than shipping a check that
      cannot fail.

      **Both halves of this were needed.** The counterfactual that goes red
      on revert is the **deterministic** one: stripping
      `registry_cache = { refresh = false }` from a `cf_stage` copy brings the
      network attempts back, 40 over 10 launches against 0 on the shipped
      file, and the staging itself fails loudly if the `sed` changed nothing.
      The abort half **could not be made hermetic**, so this requirement's own
      escape clause applies and the measurement is recorded instead of a
      check that cannot fail.

## Acceptance
- [x] A cold offline launch writes the first save: the file's mtime and
      content change, quoted before and after. Ten runs, of which the first:

      ```
      MEASURED   shipped run  1: ENOTCONN=no  exit=0       new-content-on-disk=yes
      MEASURED     before: md5=b61a24904d793889264291d7f77ba8ba size+mtime=21 1577833200
      MEASURED     after : md5=0a2492c2133228291da9bbe66ff16a90 size+mtime=35 1787596576   byte-identical=no
      PASS  race/R4 + PRD acceptance 1: …and the buffer's new content is on disk after every run, md5 size and mtime all changed (0 of 10 missing it)
      ```
- [~] The reproduction from R1 is quoted in full, including the
      byte-identical evidence. **`[~]` for the same reason R1 is**: the
      per-run identity evidence is printed for all twenty runs of the race
      stage (`md5`, size and mtime before and after, and whether the run
      aborted), and the mechanism is quoted in full from arm 1 — but no run
      aborted, so there is no *discarded* write to quote. The abort's own
      byte-identity check is kept and made conditional on an abort having
      happened, rather than passing vacuously.
- [x] `bash tests/nvim-lsp.sh` passes with the new counterfactual, output
      quoted. 140 `PASS`, zero `FAIL`, exit 0:

      ```
      PASS  race/R4 COUNTERFACTUAL: reverting the one line brings the network attempts BACK — 40 over 10 launches, against 0 on the shipped file. The fix is what does it

      PASS  the gate touched no REAL Neovim state (~/.config/nvim, ~/.local/share/nvim, ~/.local/state/nvim, ~/.cache/nvim)

      PASS — mason + native 0.11 LSP proven in a hermetic, offline Neovim
      ```

## Status of the reproduction — `unmeasured`, and why

Measured 2026-08-24 (nvim 0.12.4, mason.nvim v2.3.1 `2a6940a`). Three claims,
three verdicts, each with its fixture:

| claim | verdict |
|---|---|
| the root cause is `uv.shutdown` → `ENOTCONN`, re-raised by `a.scope` from inside a libuv callback | **reproduced as a mechanism** — reaped-child probe 3/3, live-peer control 3/3 — but **refuted as reachable through a `vim.wait` victim**: with `vim.loop.shutdown` patched on a staged root, every shutdown in the mason path returns `err=nil`, because a pumping `vim.wait` lets libuv complete the shutdown inside a millisecond, long before a child can exit |
| `registry_cache = { refresh = false }` spawns no fetch at all | **reproduced** — 0 `mason.nvim v` lines over 10 launches against 40 over 10 with the line reverted |
| an offline launch eats the first save **on a real machine** | **unmeasured** — not reproduced, and **not refuted** |

**The variable is `wget`.** A byte-for-byte copy of the earlier probe's shim
directory, with one file added:

| shim dir | aborts |
|---|---|
| curl shim, **no `wget` anywhere on `PATH`** | 4/5 |
| the same dir **+ a `wget` shim** | **0/5** |

mason's fetch is `curl():or_else(wget):or_else(…)`. With no `wget` **binary**
the fallback fails *at spawn* instead of spawning one, and the curl stdin
shutdown lands in exactly the starved window the mechanism needs. The
`BufWritePre` victim was never the variable: the probe-local one and the
conform one both give ~4/5 without `wget` and 0/5 with it, and a fake `stylua`
on `PATH` changes nothing either (4/4 with, 4/4 without).

`wget` **is** installed on this machine, at `/opt/homebrew/bin/wget`. So every
measurement of this abort on this board — including the 2026-08-23 discovery
that filed this correction, and `tests/nvim-formatting.sh`'s 2/5 race control,
which shims `curl` only — was taken in an environment missing a binary the
machine actually has. `tests/nvim-lsp.sh --race` shims `wget`, its race arm
therefore reads `0/N` **because the fixture is faithful**, and it says so in
place: deleting that shim to make the arm go red would re-measure the
artefact.

None of this touches the fix. Not fetching a catalogue at launch is right
whether or not the abort is reachable, and it is measured either way.

## Out of scope
- conform.nvim's own configuration. It is one victim of this, not the cause,
  and [`07-formatting`](../../../03-editor/07-formatting/prd.md) ships
  independently of the fix.
- Making mason work offline in general — only that its failure must not eat
  an unrelated write.
