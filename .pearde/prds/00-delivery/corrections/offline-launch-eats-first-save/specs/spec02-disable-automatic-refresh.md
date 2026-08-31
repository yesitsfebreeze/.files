---
complexity: 25
# Compute: the same ~30 s / ~234 MB as spec01's stage, re-run. Nothing here
# changes scope on cost.
footprint:
  - home/dot_config/nvim/lua/plugins/lsp.lua
  - tests/nvim-lsp.sh
---

# spec02 — mason never refreshes its registry on its own

Lands the mechanism R2 asks for: mason's **automatic** registry refresh is
turned off, so the rejecting fetch is never spawned during an ordinary launch
and there is no promise left to reject into anyone's blocking call. Then it
flips [`spec01`](spec01-reproduction-stage.md)'s race stage from "the
candidate is clean" to "reverting the fix brings the abort back", and repairs
the four assertions in `tests/nvim-lsp.sh` that the change inverts. Needs
spec01 landed first: both edit the same gate.

## The change

In `lua/plugins/lsp.lua`, the `mason-org/mason.nvim` dependency entry:

```lua
{ "mason-org/mason.nvim", opts = { registry_cache = { refresh = false } } },
```

`registry_cache.refresh` is mason's own setting (`lua/mason/settings.lua`,
`@since 2.3.0`; the pinned mason is v2.3.1 / `2a6940a`, so the key is live).
With it false, `mason-registry`'s `refresh()` returns `callback(true, {})`
without touching `mason-registry.installer`, and **no `curl` is spawned at
all** — measured: zero shim invocations on a launch that loads `lsp.lua`,
against two (four with `wget` shimmed too) on the shipped file.

Why this and not the alternatives, all measured, all on the record:

| candidate | verdict |
|---|---|
| seed `mason/registries` | **refuted** — 5/5 aborts (E.11), 4/4 and 6/6 here |
| drain the loop under `pcall` before the write | **refuted** — 1/6, then 3/6 |
| `pcall` at one call site | excluded by R2: a symptom fix, one victim at a time |
| `registry_cache.refresh = false` | **reproduced clean** — 0/6, 0/4, 0/6, and no fetch to reject |

## What it costs, and this must be in the comment

Two consequences, both measured 2026-08-24, both real:

1. **A machine with an empty `<data>/mason` never bootstraps its catalogue.**
   Online, cold root, shipped file: `registries/github/mason-org/mason-registry/registry.json`
   appears (536 KB). Same root with this change: it does not, and nothing
   under `<data>/mason` is created. `ensure_installed` cannot resolve a
   server it cannot look up, so
   [`gates/manual/wave4.md`](../../../../../gates/manual/wave4.md)'s E.7
   "unattended install on a fresh machine" box needs a `:MasonUpdate` (or
   `:Mason`) before it, or it fails. That box is `03-editor/09-lsp`'s, not
   this node's — **do not edit it here**; report it, and let the orchestrator
   route the correction.
2. **The catalogue goes stale until `:MasonUpdate`.** Package definitions and
   versions stop updating by themselves. That is the trade: a stale catalogue
   is recoverable with one command, a discarded save is not.

The explicit path still works, which is what stops the change from being
"mason's networking is broken": measured offline with this change on a cold
root, `:MasonUpdate` raised the shim count from 0 to 2; measured **online** on
a cold root, it installed the registry and `has_package("pyright")` came back
true afterwards. Say so in the comment — someone will otherwise read
`refresh = false` as "mason cannot install anything any more".

What does **not** change, measured on a `min`-seeded offline root, shipped
against changed, identical both ways: `attached=true`, `client=lua_ls`,
`is_enabled_lua_ls=true`, `get_installed_servers()=lua_ls`. `automatic_enable`
runs from `init()` over the installed packages, not from the refresh result.

## The four assertions this inverts

All in `tests/nvim-lsp.sh`, all currently green **because** mason phones home:

* `f_mason` (line ~306) greps the literal `{ "mason-org/mason.nvim", opts = {} }`.
* `py_check … deps` (line ~367) fails when `opts = {}` is absent from the
  dependencies block.
* `ok "hermeticity: all four mason refresh attempts landed" 'refresh_settled=true'`
* `ok "hermeticity: the count is four (curl+wget against both endpoints)" 'refresh_attempts=4'`

The last two must become their opposite — **zero** attempts, with no
30-second `vim.wait` left waiting for four that never come — and the header
comment at the top of the file that states "NO NETWORK CALLS IS THE WRONG
ASSERTION" must be rewritten to say what is now true and why.

A zero-attempt assertion passes just as well on a mason that is entirely
broken, so it does not stand alone: pair it with an `:MasonUpdate` probe in
the same root that drives the count **above** zero. That pair is the
discriminating check.

## Acceptance

- [x] `lua/plugins/lsp.lua` carries `registry_cache = { refresh = false }` on
      the mason dependency, and a comment giving the mechanism, both refuted
      candidates with their counts, the fresh-machine cost, and
      `:MasonUpdate` as the deliberate refresh.
      `      { "mason-org/mason.nvim", opts = { registry_cache = { refresh = false } } },`
      at line 63, under a comment carrying all five: the ENOTCONN path out of
      `on_spawn`, seeding `<data>/mason/registries` (5/5, 4/4, 6/6), the
      `pcall` drain (1/6 then 3/6), the empty-`<data>/mason` bootstrap cost,
      and the `:MasonUpdate` pair.
- [x] `bash tests/nvim-lsp.sh --tree` passes: the two `opts = {}` checks now
      assert the new text, and a selftest mutation that strips
      `registry_cache` from a copy turns the check **red**. `f_mason` greps
      the new literal and `py_check … deps` requires
      `registry_cache = { refresh = false }` inside the dependencies block;
      both are exercised against a stripped copy every invocation:

      ```
      PASS  selftest: a copy with registry_cache stripped back to opts = {} goes red (the offline-launch fix)
      PASS  selftest: …and the dependencies-block parser goes red on the same copy
      PASS  tree: mason-org/mason.nvim with registry_cache = { refresh = false } (R1 + the offline-launch fix)
      PASS — mason + native 0.11 LSP proven in a hermetic, offline Neovim
      ```
- [x] `bash tests/nvim-lsp.sh --headless` passes with the refresh assertions
      inverted: `refresh_attempts=0`, no `vim.wait` for attempts that cannot
      arrive, and `lua_ls` still attaches and is still auto-enabled. Exit 0,
      zero `FAIL` lines. The 30 s `vim.wait(… attempts() >= 4 …)` is gone —
      with none coming it could only ever burn its full budget — replaced by
      a fixed 750 ms grace window, long enough for a late attempt to reach
      the shim log if one were ever spawned:

      ```
      PASS  hermeticity + the offline-launch fix: ZERO mason network attempts at launch — registry_cache.refresh = false spawns no fetch, so there is no promise left to reject into a save
      PASS  R2 + PRD acceptance 1 (attach clause): a client attached
      PASS  R2 + PRD acceptance 1: the client is lua_ls, offline, from the seeded mason package
      PASS  R2: vim.lsp.is_enabled("lua_ls") — mason-lspconfig auto-enabled it
      PASS  R2: get_installed_servers() is the seeded package set
      ```

      The header comment that read "NO NETWORK CALLS IS THE WRONG ASSERTION"
      is rewritten in place to say what is now true and why, including that
      the zero does not stand alone.
- [x] The `:MasonUpdate` probe in the same offline root drives the shim count
      from 0 to more than 0, quoted — the disable is scoped to the automatic
      refresh, not to mason's networking. Same root `$H`, straight after the
      main probe:

      ```
      before=0
      has_command=true
      settled=true
      after=4
      delta_positive=true
      PASS  R2: :MasonUpdate exists as a command — the deliberate refresh is still there
      PASS  R2 + the offline-launch fix: an EXPLICIT :MasonUpdate drives the network-attempt count ABOVE zero in the same offline root — the disable is scoped to the AUTOMATIC refresh, not to mason's networking
      ```

      The two endpoint checks that used to assert the *launch* reached
      api.mason-registry.dev and api.github.com are repaired rather than
      deleted: they now assert the `:MasonUpdate` probe's calls, and still
      that both were refused.

      ```
      PASS  hermeticity: the :MasonUpdate refresh hit api.mason-registry.dev and was refused
      PASS  hermeticity: the :MasonUpdate refresh hit api.github.com and was refused
      ```
- [x] **RESCOPED, same ruling as spec01's.** The revert half stands; the
      "aborts at least once in N" half does not, and it is replaced rather
      than dropped. Asserting that a race reproduces is a check that goes red
      on a fast machine and green on a slow one. So the revert arm asserts its
      **deterministic** half — reverting the line brings the network attempts
      back — and MEASURES the abort count:

      ```
      PASS  race staging: the revert arm's lsp.lua had the fix STRIPPED (a sed that changed NOTHING is a staging failure)
      PASS  race staging: …and the copy is back to the pre-fix { "mason-org/mason.nvim", opts = {} }
      MEASURED   reverted (opts = {}): 0/10 ENOTCONN aborts, 40 mason network attempts
      PASS  race/R4 COUNTERFACTUAL: reverting the one line brings the network attempts BACK — 40 over 10 launches, against 0 on the shipped file. The fix is what does it
      ```

      The byte-identity and exit-0 checks on aborted runs are kept but made
      **conditional** on the arm having aborted, and the identity evidence is
      printed for every run either way. **Why the abort count reads 0/10 is
      itself a finding, and it is in the stage in place**: the variable is
      `wget`. mason's fetch is `curl():or_else(wget):or_else(…)`, and with no
      `wget` **binary** on `PATH` the fallback fails *at spawn* — 4/5 aborts
      without a `wget` shim, **0/5** with one, same shim dir otherwise.
      `wget` is installed on this machine at `/opt/homebrew/bin/wget`, so
      this gate shims it and the arm reads 0/N **because the fixture is
      faithful**. The status of the real-machine abort is `unmeasured`, and
      the stage says so, so nobody deletes that shim to make the arm go red.
- [x] The unmutated arm — the shipped file, with the fix in it — is `0/N`
      aborts and `0` mason network attempts, counts printed.

      ```
      MEASURED   shipped (registry_cache.refresh = false): 0/10 ENOTCONN aborts, 0 mason network attempts
      PASS  race/R4 + PRD acceptance 1: the SHIPPED file is 0/10 — a cold offline launch writes the first save, no ENOTCONN (got 0/10)
      PASS  race/R2: the shipped file attempts the network ZERO times at launch — no fetch is spawned, so there is no promise left to reject (got 0)
      ```
- [x] PRD acceptance 1, quoted end to end: on a cold offline launch the first
      save lands. `md5`, size and mtime of the work file before and after,
      all three changed. Run 1 of the shipped arm, and the other nine are in
      the stage's output beside it:

      ```
      MEASURED   shipped run  1: ENOTCONN=no  exit=0       new-content-on-disk=yes
      MEASURED     before: md5=b61a24904d793889264291d7f77ba8ba size+mtime=21 1577833200
      MEASURED     after : md5=0a2492c2133228291da9bbe66ff16a90 size+mtime=35 1787596576   byte-identical=no
      PASS  race/R4 + PRD acceptance 1: …and the buffer's new content is on disk after every run, md5 size and mtime all changed (0 of 10 missing it)
      ```

      md5 `b61a24…` → `0a2492…`, size 21 → 35, mtime 1577833200 → 1787596576.
      The fixture is back-dated with `touch -t 202001010000` before each run,
      because macOS `stat` reports mtime in whole seconds and a fixture
      written in the same second as the probe's write would read as
      "unchanged" for the wrong reason.
- [x] `bash tests/nvim-lsp.sh` exits 0, `assert_unchanged` included, output
      quoted. 140 `PASS`, zero `FAIL`, exit 0:

      ```
      PASS  race/R4 COUNTERFACTUAL: reverting the one line brings the network attempts BACK — 40 over 10 launches, against 0 on the shipped file. The fix is what does it

      PASS  the gate touched no REAL Neovim state (~/.config/nvim, ~/.local/share/nvim, ~/.local/state/nvim, ~/.cache/nvim)

      PASS — mason + native 0.11 LSP proven in a hermetic, offline Neovim
      ```

## Verify and Proof

```sh
cd "$(git rev-parse --show-toplevel)"
bash tests/nvim-lsp.sh --tree
bash tests/nvim-lsp.sh --headless
bash tests/nvim-lsp.sh --race
bash tests/nvim-lsp.sh            # the node's verify

# the fix is what does it: revert the one line in a scratch copy and the
# race stage's shipped arm goes red again
```
