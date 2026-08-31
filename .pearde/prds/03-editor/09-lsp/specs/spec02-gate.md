---
est: 2.5h
footprint:
  - tests/nvim-lsp.sh
  - gates/waves.tsv
  - gates/manual/wave4.md
---

# spec02 — the standing gate `tests/nvim-lsp.sh`, its wave-4 cell, and two manual rows

Write `tests/nvim-lsp.sh` (stages `--tree` / `--headless`) proving R1–R6 and
the first two PRD acceptance boxes against a staged, seeded, **offline**
Neovim with a real `lua_ls` attached, register the stages in
`gates/waves.tsv` wave 4, and add the two clauses no headless run can reach
to `gates/manual/wave4.md`.

Every value quoted below was measured on 2026-08-23 against nvim 0.12.4,
mason.nvim v2.3.1, mason-lspconfig at the live commit, and the live
`lua-language-server` mason package. Nothing here is hoped.

No `--network` stage: restore-reproducibility for the three new lockfile
rows lives in `tests/nvim-plugin-manager.sh --network`'s lockfile-key loop,
and duplicating it would give the same fact two owners.

## Runner

Take the shape of `tests/nvim-completion.sh` — it is the closest sibling and
its rules are measured, not stylistic. Reuse verbatim: `gates/lib.sh` with
`chk`/`chk_ok`/`chk_fail`, `gates_tmpdir`, `snapshot_paths` over
`~/.config/nvim`, `~/.local/share/nvim`, `~/.local/state/nvim`,
`~/.cache/nvim` with `assert_unchanged` at exit, `/usr/bin/grep` always, a
missing binary as exit 127 (`PROBE-ERROR: … ASSUMPTION MISSING`), the
lockfile-driven `seed_lazy`, the `nv_watch` watchdog, and the two traps:
results go to **stderr**, and a probe **self-quits with `qa!`** while the
runner never appends `-c qa`.

Watchdog budget 60 s per nvim run. A `lua_ls` attach settles in about two
seconds; the margin covers a cold seed copy.

### Seeding mason — the part that is new

The gate seeds the mason **install directory** as well as the lazy clones,
so servers attach with no network and no installer:

```
<root>/data/nvim/mason/registries   <- cp -R from ~/.local/share/nvim/mason/registries   (536K)
<root>/data/nvim/mason/packages/<p> <- cp -R from ~/.local/share/nvim/mason/packages/<p>
<root>/data/nvim/mason/bin/<b>      <- cp -R from ~/.local/share/nvim/mason/bin/<b>
```

Three measured details the seed depends on:

- `mason/bin/<b>` is a **relative** symlink into `../packages/…`. `cp -R`
  copies it as a symlink, so it resolves inside the copied tree. Do not
  dereference it.
- mason.nvim prepends `<data>/mason/bin` to `PATH` (`PATH = "prepend"`, its
  default), which is what makes `nvim-lspconfig`'s bare
  `cmd = { "lua-language-server" }` resolve.
- an absent live package is `PROBE-ERROR: … ASSUMPTION MISSING`, exit 127 —
  never a skip. `cp -R` must target a **nonexistent** destination path; into
  an existing directory it nests the source inside it.

Two seed sizes, so the cost is a decision and not a surprise: the main
staging seeds `lua-language-server` only (27 MB, plus 31 MB of lazy clones,
about 1.5 s), and **one** extra root seeds all five (about 123 MB). Every
counterfactual root reuses the one-package seed.

### Blocking the network — and why "no network calls" is the wrong assertion

`mason-lspconfig.setup()` calls `mason-registry.refresh()`, which reaches
`api.github.com` and `api.mason-registry.dev` **on every launch that loads
this plugin file**. Measured: four attempts per run, curl and wget against
both endpoints. So put a logging-and-refusing shim for `curl`, `wget` and
`git` at the head of `PATH` (append `"$*"` to a log, then `exit 66` for
curl/wget; the git shim logs and execs the real git, because blink runs
local `rev-parse` and `describe`).

The assertion is then in three parts:

1. every network binary on `PATH` is a poisoned shim — the run cannot have
   fetched anything;
2. with all four refresh attempts failing, the run **still** enables the
   servers and attaches `lua_ls`, and nvim exits 0. The registry is read
   from the seeded local copy; a failed refresh is not fatal;
3. the log holds no `clone`, `fetch` or `ls-remote`, and no package-download
   URL — nothing pointing at a release asset, npm, or crates.io.

Part 2 is the one that matters: it is the proof that a machine with no
network still gets a working editor.

### Why no install can happen by accident

`mason-lspconfig`'s `setup()` guards `ensure_installed` with
`not platform.is_headless`. **A headless run never installs.** That is why
this gate is safe to run offline — and it is also why PRD acceptance box 3
("a fresh machine installs all five servers unattended") cannot be
automated here and goes to the manual checklist below.

## `--tree` (hermetic, no nvim run)

Text checks over `home/dot_config/nvim/lua/plugins/lsp.lua`, each written as
a function over a path so the counterfactual copies reuse it:

- R1: names `neovim/nvim-lspconfig`; `event` naming both `BufReadPre` and
  `BufNewFile`; `mason-org/mason.nvim` with `opts = {}`;
  `mason-org/mason-lspconfig.nvim`; `saghen/blink.cmp`; all three inside a
  `dependencies` block.
- R2: `ensure_installed` listing exactly `lua_ls`, `bashls`, `pyright`,
  `rust_analyzer`, `tailwindcss` — and `mason-lspconfig` `setup` is the
  **last** statement of the `config` body, after both `vim.lsp.config`
  calls.
- R3: `vim.lsp.config("*"` with `capabilities` and
  `require("blink.cmp").get_lsp_capabilities()`.
- R4: `vim.lsp.config("lua_ls"` with `globals` naming `vim`,
  `checkThirdParty = false`, `telemetry` with `enable = false`.
- R5: the four aliases `gd`, `gI`, `<leader>rn`, `<leader>ca` with descs
  `LSP: Goto definition`, `LSP: Goto implementation`, `LSP: Rename`,
  `LSP: Code action`, all inside the `LspAttach` callback and all passing
  `buffer = `. And the negative half, which is the requirement's point: the
  file maps **none** of `grn`, `gra`, `grr`, `gri`, `gO`, `K`, `]d`, `[d`.
- R6: `virtual_text` with prefix `●`, `severity_sort = true`, `float` with
  `border = "rounded"` and `source = true`.
- Epic I7: every `nvim_create_autocmd` call in the file passes a `group`
  built by `nvim_create_augroup(…, { clear = true })`. Check per call site,
  not per file — a file-level grep for `augroup` passes falsely, which is
  how L-8 survived.
- The log constraint (spec01): the file carries the 17 GB / no-rotation
  reason, and `vim.lsp.log.set_level` appears in it **zero** times.
- Selftests, every invocation: a copy with the `●` prefix changed goes red;
  a copy with `"tailwindcss"` dropped from `ensure_installed` goes red; a
  copy with `clear = true` removed goes red; a copy that adds a
  `vim.keymap.set("n", "grn", …)` line goes red under R5's negative half; a
  copy adding `vim.lsp.log.set_level(vim.lsp.log.levels.DEBUG)` goes red.

## `--headless` (hermetic; lazy + mason seeded; network shims)

The probe opens a `.lua` file in the scratch work dir (give the work dir a
`.git` so `lua_ls`'s root marker resolves — the attach itself does not
depend on it, the resolved `root_dir` does), waits for a client, and reads
back. Every value below was observed:

**Lazy trigger (R1).**
`lazy.core.config.plugins["nvim-lspconfig"]._.loaded` is falsy before the
`:edit` and truthy after it — `BufReadPre` fired, and this is what makes the
event list a claim rather than a comment.

**Config readback (R1, R3, R4).** `vim.lsp.config[<name>]` returns the
merged view, `"*"` folded in:

- `vim.lsp.config["lua_ls"].cmd` is `{ "lua-language-server" }` — a value
  nothing in our config sets. It comes from `nvim-lspconfig`'s bundled
  `lsp/lua_ls.lua`, so this single check is what proves R1's reason for
  depending on that plugin at all.
- `vim.lsp.config["lua_ls"].settings.Lua.diagnostics.globals` is
  `{ "vim" }`; `.workspace.checkThirdParty` is `false`;
  `.telemetry.enable` is `false`.
- `vim.lsp.config["lua_ls"].capabilities.textDocument.completion
  .completionItem.snippetSupport` is `true`, and
  `vim.lsp.config["*"].capabilities` is non-nil — blink's capabilities
  reached a named server through the `"*"` merge.

**Diagnostics (R6).** `vim.diagnostic.config()` reads back
`virtual_text = { prefix = "●" }`, `severity_sort = true`,
`float = { border = "rounded", source = true }`.

**A real server, offline (R2, and PRD acceptance box 1's attach clause).**
After the `:edit`, `#vim.lsp.get_clients({ bufnr = 0 })` is 1 and that
client's `name` is `lua_ls`.

**Auto-enable for all five (R2).** In the five-package root:
`vim.lsp.is_enabled(s)` is true for each of `lua_ls`, `bashls`, `pyright`,
`rust_analyzer`, `tailwindcss`, and
`require("mason-lspconfig").get_installed_servers()` sorted is
`bashls,lua_ls,pyright,rust_analyzer,tailwindcss`. Also
`require("mason-lspconfig.settings").current.ensure_installed` is the five
in R2's order — the list as *received*, not as written in the file.

**The aliases, and core's keys (R5, PRD acceptance box 2).** With `lua_ls`
attached, `vim.fn.maparg(k, "n", false, true)`:

| key | `buffer` | `desc` |
|---|---|---|
| `gd` | 1 | `LSP: Goto definition` |
| `gI` | 1 | `LSP: Goto implementation` |
| `<leader>rn` | 1 | `LSP: Rename` |
| `<leader>ca` | 1 | `LSP: Code action` |
| `K` | 1 | `vim.lsp.buf.hover()` |
| `grn` `gra` `grr` `gri` `gO` `]d` `[d` | 0 | — |

`K` is core's, attached per buffer on `LspAttach`; the other seven are
global. The check that carries R5 is the pairing: our four exist **and**
carry our descs, while the eight core keys exist with `buffer` and desc that
are not ours. `<leader>` normalizes to a literal space in `maparg` — look up
`" rn"` and `" ca"`, or the check reads as a regression on a correct
config.

**R4 end to end — the setting reaches the server.** Raise the log level
inside the probe (`vim.lsp.log.set_level(vim.lsp.log.levels.DEBUG)`), then
grep the **scratch** `state/nvim/lsp.log` for the
`workspace/didChangeConfiguration` notification. Measured: its params carry
`diagnostics = { globals = { "vim" } }`, `workspace = { checkThirdParty =
false }` and `telemetry = { enable = false }`. Also assert
`vim.lsp.get_clients({ bufnr = 0 })[1].settings.Lua.diagnostics.globals` is
`{ "vim" }`.

The override is the probe's, and the gate says so with a check rather than a
comment: the staged `lsp.lua` calls `set_level` nowhere, and
`lua/config/options.lua` still sets it to `OFF`. Raising it for one scratch
run is how the notification becomes readable; raising it in the config is
the 17 GB failure.

**Counterfactuals**, each a `cf_stage` copy with one `sed` on `lsp.lua`,
each naming the check it turns red. Each costs a watchdogged run,
deliberately:

- the `event` line deleted → loaded at startup → the trigger check red.
- `"neovim/nvim-lspconfig"` swapped for a bare `{ "mason-org/mason.nvim" }`
  root spec → `vim.lsp.config["lua_ls"].cmd` is nil and no client attaches
  → the bundled-defaults check and the attach check red.
- the `vim.lsp.config("*", …)` block deleted → `snippetSupport` nil → the
  capability check red.
- `globals = { "vim" }` emptied → the readback check red **and** the
  `didChangeConfiguration` grep red.
- the `●` prefix changed → the diagnostics check red.
- the `bmap("gd", …)` line deleted → `gd` no longer buffer-local with our
  desc → R5's positive half red.
- the whole `LspAttach` block deleted → all four aliases red while the eight
  core keys stay green — the shape that shows the core-provided half is not
  ours.
- the mason seed withheld (no `sed`; stage without the mason packages) →
  `is_enabled("lua_ls")` false and no client attaches → the auto-enable
  check red. This is the control that proves the enable comes from the
  installed package set and not from `ensure_installed` being written down.

**Hermeticity, last checks of the stage:** the shim log holds no
`clone|fetch|ls-remote` and no download URL; the four mason refresh attempts
are present and all failed; the run exited 0 anyway.

No-arg runs both stages.

## `gates/waves.tsv`

Append to the **wave-4** gates cell:
`| external bash tests/nvim-lsp.sh --tree | external bash tests/nvim-lsp.sh --headless`.
If a lane holds the file at implementation time, hand the one-cell append to
the orchestrator instead of racing it.

## `gates/manual/wave4.md`

Add two rows, in the file's existing shape (`- [ ] **E.7** — …` with PASS
and FAIL lines, boxes left unticked — `gates/manual-coverage.sh` fails on a
pre-ticked box). These are the two clauses a headless run provably cannot
reach, and each row carries the measured reason:

- **E.7** — the unattended install on a fresh machine. Launch a real
  interactive `nvim` on a machine with an empty `<data>/mason`, open a Lua
  file, and wait.
  PASS: mason installs `lua_ls`, `bashls`, `pyright`, `rust_analyzer` and
  `tailwindcss` with no prompt, and `lua_ls` attaches.
  FAIL: any prompt, any server missing afterwards.
  Why a human: `mason-lspconfig.setup()` guards `ensure_installed` with
  `not platform.is_headless`, so no scripted run can ever trigger an
  install (measured 2026-08-23).
- **E.7** — completion offers Neovim API members. In a real `nvim`, in a Lua
  file, type `vim.` and look at the blink menu.
  PASS: server-provided members (`fn`, `api`, `lsp`, …) appear, and `vim`
  is not underlined as an undefined global.
  FAIL: an empty menu, or `vim` flagged.
  Why a human: `lua_ls` publishes no diagnostics and returns zero
  completion items under a headless run with a scratch `HOME` — measured
  2026-08-23, 40 s of waiting for `publishDiagnostics` and twelve
  five-second completion retries, all empty, with `diagnosticProvider`
  false so there is no pull path either. The gate must not use the real
  `HOME` (W0.9), so this stays a human check rather than a hermetic one.

The second row is also what closes
[05-completion](../../05-completion/prd.md)'s first acceptance box, which is
`[~]` waiting on an attached LSP. Report the wording; the orchestrator makes
that edit.

## Acceptance

- [x] `bash tests/nvim-lsp.sh --tree` exits 0, and all five selftest
      mutations are caught red (quote each).
- [x] `bash tests/nvim-lsp.sh --headless` exits 0; every readback in the
      tables above quoted; no TIMEOUT.
- [x] `bash tests/nvim-lsp.sh --headless` shows a real `lua_ls` client
      attached to a Lua buffer with every network binary poisoned, and the
      run exits 0 (quote the client name and the refused refresh attempts).
- [x] All eight counterfactuals quoted, each naming the check it turned
      red — including the withheld-mason-seed control.
- [x] The `workspace/didChangeConfiguration` params from the scratch
      `lsp.log` quoted, carrying `globals = { "vim" }`,
      `checkThirdParty = false` and `telemetry = { enable = false }`.
- [x] The shim log holds no `clone|fetch|ls-remote` and no download URL
      (quote the log).
- [x] `assert_unchanged` green — no write to real `~/.config/nvim`,
      `~/.local/share/nvim`, `~/.local/state/nvim`, `~/.cache/nvim`.
- [x] **Closed by the orchestrator on the transition.** Appended
      `| external bash tests/nvim-lsp.sh --tree | external bash
      tests/nvim-lsp.sh --headless` to the wave-4 gates cell, then verified:
      `bash gates/wave-status.sh --validate` →
      `registry: every script under tests/ is named by a row
      (unreferenced: none)` — it had read
      `unreferenced: capsule-credentials.sh nvim-lsp.sh` before this and the
      sibling lane's append — and `bash gates/selftest.sh` is green again,
      `5 script(s) held to the contract · 31 external, reported not failed`.
      Original box: `gates/waves.tsv` wave-4 row carries both stages, and `bash
      gates/manual-coverage.sh` exits 0 with the two new E.7 rows in
      `gates/manual/wave4.md`.
- [x] The neighbours stay green: `bash tests/nvim-completion.sh`, `bash
      tests/nvim-plugin-manager.sh`, `bash tests/nvim-options.sh`.

## Verify and Proof

```sh
bash tests/nvim-lsp.sh                  # both stages
bash gates/manual-coverage.sh           # the two new E.7 rows
bash tests/nvim-completion.sh           # neighbours
bash tests/nvim-plugin-manager.sh
bash tests/nvim-options.sh
```
