---
kind: knowledge
description: nvim's mason never refreshes its registry at launch — the offline fetch can discard a save, and the bootstrap moves to install.sh
read_when: "touching lsp.lua, mason, or the fresh-machine editor path"
---

# mason-never-refreshes-at-launch

`lua/plugins/lsp.lua` carries `registry_cache = { refresh = false }` (mason
v2.3.1's own setting, `@since 2.3.0`): mason-registry's refresh returns
without touching the installer and **no curl is spawned at all** at launch —
measured zero network attempts on a launch that loads the file, against four
on the default.

The reason is a **discarded write**, not politeness. mason-lspconfig's setup
refreshes on every launch; when the fetch's `on_spawn` handler
(`mason-core/fetch.lua:134`, wrapped in `a.scope`) shuts down the stdin pipe
of a curl that has **already exited**, `uv.shutdown` fails with ENOTCONN and
`a.scope` re-raises from inside a libuv callback — which propagates out of
whatever blocking call is pumping the loop at that instant. A BufWritePre
consumer that pumps the loop (conform's `format_lines_sync` is one) loses its
write: the buffer is not written, the file stays byte-identical, nvim exits 0.
A lost save presented as nothing at all, on a laptop that woke up on a train.

Two other candidates were tried first and both failed, which is why this is a
setting and not a pcall: seeding `<data>/mason/registries` still aborted 5/5,
4/4 and 6/6; draining pending work under pcall aborted 1/6 then 3/6. A pcall
at one call site fixes one victim at a time — any BufWritePre consumer that
pumps the loop inherits this.

What it costs, measured and real: a machine with an empty `<data>/mason` never
bootstraps its catalogue on its own (online with the default, a 536 KB
registry.json appears; with this, nothing is created), so `ensure_installed`
cannot resolve a server — which is what `install.sh`'s explicit `:MasonUpdate`
run, after the tools are on PATH, is for. `:MasonUpdate` is the deliberate
refresh; check the **pair** (attempts rise to 2 offline, the registry installs
online and `has_package` turns true) if you check it at all — a zero-attempt
count alone passes just as well on a mason that is entirely broken.