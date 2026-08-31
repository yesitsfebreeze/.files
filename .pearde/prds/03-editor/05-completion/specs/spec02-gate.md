# spec02 — the standing gate `tests/nvim-completion.sh`, and the wave-3 cell

Write `tests/nvim-completion.sh` (stages `--tree` / `--headless`) proving
R1–R8 and all three PRD acceptance boxes against a staged, seeded, offline
Neovim, and register the stages in `gates/waves.tsv` wave 3. Every probe
below was measured 2026-08-22 on nvim 0.12.4 with blink.cmp v1.10.2 —
nothing here is hoped.

No `--network` stage: restore-reproducibility for the two new lockfile
rows lives in `tests/nvim-plugin-manager.sh --network`'s lockfile-key loop
(spec01), and duplicating it would give the same fact two owners.

**Est:** 1.5h

**Footprint:** `tests/nvim-completion.sh`, `gates/waves.tsv`
<!-- waves.tsv is taken round-by-round — a one-cell append to the wave-3
     row; hand it to the orchestrator if a lane holds the file -->

## Runner

Source `gates/lib.sh`; `chk`/`chk_ok`/`chk_fail`, `gates_tmpdir`,
`snapshot_paths` over `~/.config/nvim`, `~/.local/share/nvim`,
`~/.local/state/nvim`, `~/.cache/nvim` + `assert_unchanged` at exit.
`/usr/bin/grep` always. Missing nvim is exit 127, the
`tests/nvim-options.sh` shape. Stage `home/dot_config/nvim/` into a scratch
XDG root; seed with spec01's lockfile-driven helper (every lockfile key
copied from `~/.local/share/nvim/lazy/<name>`; absent live clone =
`ASSUMPTION MISSING`, exit 127; `cp -R` to a nonexistent destination —
into an existing dir it nests, measured). Watchdog per nvim run: no
`timeout` on this machine; background the process, poll `kill -0` for 20s
(the menu probe alone may wait 5s), `kill -9` on overrun, record TIMEOUT.

Prepend a **logging git shim** to PATH for the whole stage: append
`"$*"` to `git-calls.log`, exec the real git. Blink's load-time version
check runs local `rev-parse` and `describe` (measured), so "no git calls"
is the wrong assertion — the hermeticity check is that the log holds **no
`clone`, `fetch`, or `ls-remote`**.

Two measured traps, carry both as comments in the runner:

- A probe that does deferred work must **self-quit with `qa!`** and the
  runner must not append `-c qa`: a trailing `-c qa` fires at startup,
  before any `defer_fn` runs — and plain `qa` on a modified scratch buffer
  hangs forever on E37 headless.
- `doautocmd InsertEnter` in a `-c` chain is enough to fire blink's lazy
  load for state/readback probes; only the behavioral probes (menu,
  snippet, fallbacks) need `nvim_feedkeys` + `defer_fn`.

## `--tree` (hermetic, no nvim run)

Text checks over `lua/plugins/completion.lua`, each a function over a path
so counterfactual copies reuse it:

- names `saghen/blink.cmp`; `event = "InsertEnter"`; `version = "1.*"`
  with a comment carrying `prebuilt` (the tagged-release reason — it reads
  as an arbitrary pin without it); `rafamadriz/friendly-snippets`;
  `preset = "super-tab"`; `["<CR>"]` with `"accept"` and `"fallback"`;
  `["<Esc>"]` with `"cancel"` and `"fallback"`;
  `nerd_font_variant = "mono"`; `auto_show_delay_ms = 200`;
  `signature = { enabled = true }`; `prefer_rust_with_warning`;
  `opts_extend` naming `sources.default`; the four sources
  `lsp`, `snippets`, `path`, `buffer`.
- scope guard: no `vim.keymap.set` (I5 — keys live in `opts.keymap`), no
  `nvim_create_autocmd` (I7), no second repo string beyond blink and
  friendly-snippets (I8 — one plugin per file, a dependency is not a
  second concern).
- ban sweep over `home/dot_config/nvim/lua/` (PRD acceptance 3, tree
  half): `/usr/bin/grep -riE 'hrsh7th|luasnip|l3mon4d3'` and
  `/usr/bin/grep -rE '["/]cmp-'` both return 0 hits (`blink.cmp` holds no
  `cmp-`, so the second pattern cannot false-positive on it).
- `lazy-lock.json`: parses (python3), holds keys `blink.cmp` and
  `friendly-snippets`, each `commit` 40 hex chars. Membership, not exact
  equality — the exact key set is nobody's contract here and later plugin
  nodes must not have to edit this gate.
- Selftests, every invocation: a copy with `preset` set to `"default"`
  goes red; a copy with the `version` line deleted goes red; a lockfile
  copy with a truncated `blink.cmp` commit goes red; a copied tree with a
  planted `"hrsh7th/nvim-cmp"` spec goes red under the ban sweep.

## `--headless` (hermetic; seeded; logging git shim)

**Trigger + readback probe** (`-c` chain, self-quits `qa!`), one `chk`
per line, all values measured:

- `lazy.core.config.plugins["blink.cmp"]._.loaded` is falsy at startup,
  truthy after `doautocmd InsertEnter` (R1's `InsertEnter`, observed).
- `blink.cmp.config` readback: `keymap.preset == "super-tab"`;
  `sources.default` exactly `lsp,snippets,path,buffer` (R4);
  `completion.documentation.auto_show == true` and
  `auto_show_delay_ms == 200` (R5); `signature.enabled == true` (R6);
  `appearance.nerd_font_variant == "mono"` (R7);
  `fuzzy.implementation == "prefer_rust_with_warning"` (R8).
- keymap descs after load (`vim.fn.maparg(k, "i", false, true).desc`):
  `<Tab>` contains `Snippet Forward`, `<S-Tab>` contains
  `Snippet Backward`, `<CR>` is `blink.cmp: Accept`, `<Esc>` is
  `blink.cmp: Cancel`, `<C-space>` contains `Show`, `<C-e>` is
  `blink.cmp: Cancel` (all measured verbatim; do not probe `<C-n>`/`<C-p>`
  descs — the preset maps them descless, measured nil).
- `require("blink.cmp").get_lsp_capabilities().textDocument.completion`
  is a table with `completionItem.snippetSupport == true` — R9's seam
  exists for [09-lsp](../../09-lsp/prd.md) to wire; the wiring is not
  this gate's subject.
- plugin-name ban (PRD acceptance 3, state half): no key of
  `lazy.core.config.plugins` equals `nvim-cmp`, starts with `cmp-`, or
  contains `luasnip` case-folded.

**Menu probe** (feedkeys `ialp` into a buffer holding
`alphabet alpine alligator`; `defer_fn` 500ms; self-quits): call
`require("blink.cmp").show()`, then `vim.wait` up to 5s for
`is_visible()` — true; `blink.cmp.completion.list` items include
`alphabet` and `alpine`;
`require("blink.cmp.fuzzy").implementation_type == "rust"` — the
`prefer_rust` side actually taken from the seeded prebuilt library, not
the warning fallback (R8 + R1's tag reason, observed). Auto-show does not
fire from feedkeys-typed text headless (measured) — the explicit `show()`
is what makes this probe deterministic; say so in a comment.

**Snippet probe** (`setfiletype lua`, feedkeys `ifor`, defer, self-quits):
`show()`, items include `for` (friendly-snippets, R2); `list.select` it
and `blink.cmp.accept()`; `vim.wait` up to 3s for
`vim.snippet.active()` — true; first buffer line contains `for` and `do`
(the body expanded); `vim.snippet.active({ direction = 1 })` — true, the
placeholder jump `<Tab>` drives (PRD acceptance 1, snippet half; the
with-LSP half has no subject until [09-lsp](../../09-lsp/prd.md) lands
and closes there).

**Fallback probe** (feedkeys, chained `defer_fn`s, self-quits — PRD
acceptance 2 executed): in insert with `is_visible() == false`, feed
`<Esc>` → mode is `n`; re-enter insert with `o`, feed `<CR>` → buffer
line count grew by one.

**Counterfactuals**, each a `cf_stage` copy of the tree with one sed on
`completion.lua`, each naming the check it turns red (each costs a
watchdogged headless run, deliberately):

- `event` line deleted → blink loaded at startup → trigger check red.
- `preset` → `"default"` → `<Tab>` desc check red.
- `dependencies` line deleted → snippet probe finds no `for` item.
- `["<CR>"]` line deleted → `<CR>` desc check red.
- `"buffer"` dropped from sources → menu probe items check red.
- `opts_extend` line deleted, with a scratch sibling
  `plugins/extra.lua` = `return { { "saghen/blink.cmp", opts = { sources
  = { default = { "omni" } } } } }` staged in the copy → readback is
  `omni` alone (measured: with `opts_extend` the same sibling yields
  `lsp,snippets,path,buffer,omni`) → the merge check red. Run the
  positive half against a scratch sibling in the main staging too — this
  is R4's "a later spec adds rather than replaces", observed. Remove the
  scratch spec after.

**Hermeticity, last check of the stage:** `git-calls.log` holds no
`clone|fetch|ls-remote`.

No-arg runs both stages.

## `gates/waves.tsv`

Append to the wave-3 gates cell:
`| external bash tests/nvim-completion.sh --tree | external bash tests/nvim-completion.sh --headless`.
If a lane holds the file at implementation time, hand the one-cell append
to the orchestrator instead of racing it.

## Acceptance

- [x] `bash tests/nvim-completion.sh --tree` exits 0; all four selftest
      mutations red-then-caught (quoted in the report). Executed
      2026-08-22. The ban sweep strips comment lines first: the header
      comment this node's spec01 orders kept names LuaSnip, and prose is
      not a plugin spec.
- [x] `bash tests/nvim-completion.sh --headless` exits 0; every
      counterfactual quoted naming its red check; no TIMEOUT. Executed
      2026-08-22, 74 PASS across both stages. Two measured refinements:
      the desc readback waits for blink's async keymap.setup (its
      InsertEnter autocmd registering) and fires the event a second time;
      the preset counterfactual's discriminator is super-tab's
      `<Custom Fn>` half — the default preset also maps `snippet_forward`,
      so "contains Snippet Forward" cannot go red on it.
- [x] `git-calls.log` free of `clone|fetch|ls-remote` (quoted). Executed
      2026-08-22 — the shim logged blink's local `rev-parse`/`describe`
      calls and nothing network-shaped.
- [x] `assert_unchanged` green — no write to real `~/.config/nvim`,
      `~/.local/share/nvim`, `~/.local/state/nvim`, `~/.cache/nvim`.
      Executed 2026-08-22, green in every run.
- [x] `gates/waves.tsv` wave-3 row carries both stages. Delegated to the
      C.2 lane (it holds the file); landed 2026-08-22, confirmed by read.

## Verify

```sh
bash tests/nvim-completion.sh              # both stages
bash tests/nvim-plugin-manager.sh --headless   # neighbours still green
bash tests/nvim-options.sh
```
