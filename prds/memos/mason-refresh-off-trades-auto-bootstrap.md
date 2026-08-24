---
memo: mason-refresh-off-trades-auto-bootstrap
kind: decision
status: decided
subject: Turning mason's registry refresh off buys back the discarded first save and costs the automatic fresh-machine bootstrap, which install.sh now owes
date: 2026-08-24
prds:
  - 00-delivery/corrections/offline-launch-eats-first-save
  - 05-platform/01-deploy-mechanism
  - 03-editor/09-lsp
---

# mason-refresh-off-trades-auto-bootstrap — the first save wins, and the bootstrap moves to install.sh

## Decision

`home/dot_config/nvim/lua/plugins/lsp.lua` carries
`registry_cache = { refresh = false }`, so mason never fetches its catalogue
on launch. The registry bootstrap that setting used to perform implicitly
becomes an explicit obligation of the provisioning layer:
[`05-platform/01-deploy-mechanism`](../05-platform/01-deploy-mechanism/prd.md)
R7 requires `install.sh` to run `:MasonUpdate` once, after the tools are on
PATH, before any node depends on a server being installable.

Nothing else changes. `ensure_installed` and `automatic_enable` keep working
on a machine whose registry is already seeded, and `:MasonUpdate` remains the
way to refresh it by hand.

## Why

Launching Neovim offline discarded the first buffer write. Measured
2026-08-24 (nvim 0.12.4, mason.nvim v2.3.1 `2a6940a`, scratch XDG root with a
refusing `curl` shim): a `BufWritePre` handler that merely waits aborts 6 of
6 runs on the shipped config, the file's md5 and mtime unchanged, while the
formatter had in fact run and nvim still exited 0. Silent, and the loudest
possible symptom — losing a save — presented as nothing at all.

The cause is not a cache. `mason-core/fetch.lua:134` wraps curl's `on_spawn`
in `a.scope`; it `uv.shutdown`s the stdin pipe of a curl that has already
exited, gets `ENOTCONN`, and `a.scope` re-raises it with `error(err, 0)`
inside a libuv callback — which surfaces out of whatever blocking call
happens to be pumping the loop at the time. That is why the victim is
whatever was running, and why the abort rate is a property of the fixture
rather than of the bug: the same probe aborts 6/6 from one buffer type and
0/6 from a markdown buffer. Any assertion here counts aborts over N runs and
never states a rate.

With `refresh = false` the fetch never happens: 0 aborts across 6, 4 and 6
runs, seeded and cold, on both fixtures, with zero curl spawns per launch.

The cost is real and was measured, not assumed. Online, on an empty
`<data>/mason`, the shipped file downloads a 536 KB `registry.json`; with
refresh off nothing is created, so `ensure_installed` has no catalogue to
resolve a server name against. That is the fresh-machine path, and it is
exactly what `gates/manual/wave4.md`'s still-open E.7 box ("the unattended
install on a fresh machine") checks. Moving the bootstrap to `install.sh`
puts it where the same contract already lives: R6 of that node is
*install before use, and re-resolve PATH* — one more thing that must run
after the install, in the run that performed it.

## Alternatives considered

**Leave `refresh = true` and treat the lost save as a known hazard.** Lost on
severity: the failure destroys user data with no error, and the board's own
gate had been asserting the cause as a feature (`refresh_settled=true`,
`refresh_attempts=4`), so nothing was scheduled to notice it.

**Keep the automatic refresh and make it non-fatal** — wrap mason's fetch, or
pcall the raise away. Lost on where the seam is: the throw crosses a libuv
callback boundary inside a vendored plugin, so the wrap would have to live in
mason's own source and would be reverted by the next plugin update. A one-line
supported setting (`@since 2.3.0`) beats patching a dependency.

**Fold the bootstrap into this correction's own specs.** Lost on ownership:
the correction's footprint is `lsp.lua` and `tests/nvim-lsp.sh`, and
provisioning is a different node with a requested-work owner. Widening a
derived correction into the deploy path is how a corrections backlog stops
being bounded.

**File the bootstrap gap as a new derived PRD.** Lost on the board's own
rule: this correction is itself `origin: derived`, and a derived PRD filed
against a derived PRD is the loop feeding on itself — fold it into the first
or write the memo. The obligation folds onto a *requested* node that already
owns the contract, and this memo is the record.

## Consequences

- `install.sh` owes a `:MasonUpdate` run. Until that lands, a genuinely fresh
  machine gets no servers installed, and E.7 in `gates/manual/wave4.md` fails
  if it is attempted before it.
- E.7 must be re-run after R7 lands. Its current wording assumes the
  bootstrap is implicit in launching `nvim`; the human running it should
  expect `install.sh` to have done it.
- A "0 network attempts" assertion is not, on its own, evidence the fix
  works — it also passes on a mason that is entirely broken. Every check of
  this behaviour pairs it with a `:MasonUpdate` probe in the same root that
  drives the count above zero.
- Prose in `03-editor/09-lsp`'s specs still names `opts = {}` as the
  contract. It is not a requirement and no gate reads it, but it is stale as
  of this memo.
- This does **not** address why `mason-lspconfig.setup()` guards
  `ensure_installed` with `not platform.is_headless`, which is the reason E.7
  needs a human at all. That constraint is untouched.
