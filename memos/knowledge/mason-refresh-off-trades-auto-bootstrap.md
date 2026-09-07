---
kind: knowledge
description: mason's registry refresh is off — launching Neovim offline discarded the first save; the fresh-machine bootstrap moves to install.sh
read_when: "touching nvim's lsp.lua, mason, or the fresh-machine install path"
---

# mason-refresh-off-trades-auto-bootstrap

`home/dot_config/nvim/lua/plugins/lsp.lua` carries
`registry_cache = { refresh = false }`, so mason never fetches its catalogue
on launch. The fresh-machine bootstrap that refresh performed implicitly
becomes an explicit obligation of `install.sh`: run `:MasonUpdate` once,
after the tools are on PATH, before anything depends on a server being
installable.

Measured 2026-08-24 (nvim 0.12.4, mason.nvim v2.3.1, scratch XDG root with a
refusing `curl` shim): a `BufWritePre` handler that merely waits aborted 6 of
6 runs on the shipped config, the file's md5 and mtime unchanged, while the
formatter had in fact run and nvim still exited 0 — a lost save presented as
nothing at all. The cause is mason's `mason-core/fetch.lua:134` wrapping
curl's `on_spawn` in `a.scope`: it `uv.shutdown`s the stdin pipe of a curl
that has already exited, gets `ENOTCONN`, and re-raises it inside a libuv
callback, which surfaces out of whatever blocking call is pumping the loop.
With `refresh = false` the fetch never happens: 0 aborts across 17 runs,
seeded and cold, zero curl spawns per launch.

The cost is real and measured: online, on an empty mason data dir, the
shipped file downloads a 536 KB `registry.json`; with refresh off nothing is
created, so `ensure_installed` has no catalogue to resolve a server name
against — which is what `install.sh`'s `:MasonUpdate` run is for. The abort
rate is a property of the fixture, not of the bug: 6/6 from one buffer type,
0/6 from another. Any assertion counts aborts over N runs and states no rate.

See [[every-abort-measurement-was-missing-wget]] — the faithful-PATH caveat
on every number above.