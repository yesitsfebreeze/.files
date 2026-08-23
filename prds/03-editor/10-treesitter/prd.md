---
state: done
claim: 
priority: 10
est: 3h
actual: 40m
task: E.8
mode: afk
needs:
  - 03-editor/04-plugin-manager
  - 06-help/01-content-model
verify: "bash tests/nvim-treesitter.sh"
---

# Treesitter

Parent: [Neovim epic](../prd.md) · C 5 · U 8 · source: "Treesitter" in
[`capabilities-nvim.md`](../../../docs/capabilities-nvim.md)

Purpose: Syntax-tree highlighting and indentation for the languages actually
used here, on nvim-treesitter's `main` branch (the new API: `setup` +
`install`, no `ensure_installed` module config).

## Requirements
- [x] **R1** — **Plugin.** `nvim-treesitter/nvim-treesitter`, `branch =
      "main"`, `build = ":TSUpdate"`, lazy on `BufReadPost`/`BufNewFile`.
- [x] **R2** — **Parsers.** Explicit install list: odin, bash, c, lua, luadoc,
      markdown, markdown_inline, nu, python, query, rust, toml, vim, vimdoc,
      yaml, json. (`nu` and `odin` are the non-obvious ones — the shell config
      and the Odin work respectively.)
- [x] **R3** — **Attach on FileType.** Start highlighting via
      `vim.treesitter.start` under `pcall` (a missing parser must not error)
      and set `indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"`.
- [x] **R4** — **Catch already-loaded buffers.** Also iterate
      `nvim_list_bufs()` and attach to every loaded one at config time.

      **The requirement stands; its stated reason was wrong.** Corrected
      2026-08-23 by the orchestrator. It read "the FileType autocmd has
      already fired for the triggering buffer" — measured false: on
      `nvim x.nu` the triggering buffer's filetype is still **empty** when
      `config()` runs (`loop:1:ft=` then `au:1:ft=nu`), because FileType
      fires *after* BufReadPost. Deleting the loop leaves `nvim x.nu` fully
      highlighted, so the triggering buffer is not what the loop saves.

      Its real subject is a **sibling** buffer that was filetyped before the
      plugin loaded: that one loses its `indentexpr` to `GetLuaIndent()`
      without the loop. So the loop is load-bearing for a case the old
      rationale did not describe, and the gate must target a sibling buffer
      rather than the one on the command line — otherwise the counterfactual
      passes and the requirement looks decorative.

Checks run 2026-08-23 with `bash tests/nvim-treesitter.sh` (108 PASS, 0
FAIL, exit 0):

- R1 — `PASS  R1: not loaded at startup` / `PASS  R1: loaded after
  doautocmd BufReadPost` / `PASS  R1: :TSUpdate does not exist before the
  load` / `PASS  R1: build names a command the plugin really creates
  (:TSUpdate exists after)` / `PASS  R1: branch readback = main` / `PASS
  R1: event readback = BufReadPost,BufNewFile`.
- R2 — `PASS  R2: get_installed() is exactly the sixteen`, and
  `PASS  tree: the parser list is EXACTLY R2's sixteen, set equality`.
  Counterfactual: dropping `"nu",` turns both red, and the highlighter on
  `x.nu` with it (`PASS  counterfactual: nu dropped from R2 -> no
  highlighter on x.nu, P2's check red`).
- R3 — `PASS  R3: &indentexpr is the treesitter one`; the `pcall` proven
  live by its counterfactual, which prints `Parser could not be created for
  buffer 1 and language "go"` with a traceback.
- R4 — `PASS  PRD acceptance 1 / R4: the SIBLING buffer keeps the
  treesitter indentexpr`, against `PASS  counterfactual: no loop -> the
  sibling buffer falls back to GetLuaIndent(), P5 red`.

## Acceptance
- [x] A **sibling** buffer, filetyped before the plugin loaded, keeps its
      treesitter `indentexpr` — it does not fall back to `GetLuaIndent()`.
      *Rewritten 2026-08-23 by the orchestrator:* the original box was "open
      a `.nu` file directly from the command line (`nvim x.nu`): it is
      highlighted", whose premise R4's correction retires. That case is
      highlighted with **or without** the loop, so the box could not fail
      for the requirement it was written to defend.
- [x] Opening `nvim x.nu` still highlights, as a separate regression check —
      kept because it is worth knowing, and labelled as not proving R4.
- [x] A filetype with no installed parser opens without an error. R3's
      `pcall` is what this defends, and it is live rather than decorative:
      without it, `nvim x.go` throws
      `Parser could not be created for buffer 1 and language "go"` with a
      traceback.
- [x] `=` re-indents a Lua block using the treesitter indentexpr, measured
      with `nosmartindent`. **The config's own `smartindent = true`
      (`01-options`) makes this indistinguishable otherwise** — `gg=G` on a
      Lua block is byte-identical with the treesitter indentexpr cleared. The
      gate isolates it with `nosmartindent`, where lines 4 and 8 differ
      measurably; the with-smartindent case is a manual row, because that is
      the shape the user actually types in.
- [x] The gate's own seeding is honest: the parser store is empty when it
      claims to be. The live `nvim-treesitter` clone carries **untracked
      `parser/` and `parser-info/`** directories (master-era leftovers,
      24 MB) and the plugin root is on the runtimepath, so a scratch root
      seeded with a plain `cp -R` highlighted `x.nu` while `get_installed()`
      was empty and 16 downloads were still in flight. The seed strips them
      and the gate asserts the pair.

Checks executed 2026-08-23, `bash tests/nvim-treesitter.sh` (108 PASS, 0
FAIL, exit 0):

- box 1 — P5, `-c 'setfiletype lua' -c 'new x.nu'`: `buf1_ft=lua`, and
  `buf1_indentexpr` is
  `v:lua.require'nvim-treesitter'.indentexpr()`. The counterfactual with
  the loop deleted reads `buf1_indentexpr=GetLuaIndent()`.
- box 2 — P2, `nvim x.nu`: `ft=nu` · `hl=true` · `lang=nu` · `q_nu=true`
  with the in-probe negative control `q_go=false`. The same loop-deleted
  copy still reads `hl=true`, so the box is recorded as not proving R4.
- box 3 — P3, `nvim x.go`: exit 0 · `errmsg=<empty>` ·
  `messages=<empty>` · `hl=false` · `indentexpr=GoIndent(v:lnum)`.
- box 4 — P4, `nosmartindent`: `get_indent3=2` against `go_indent3=-1`,
  `line11=  :rep(3)`, `line12=  :upper()`. The counterfactual reads
  `line11=:rep(3)`.
- box 5 — the provenance guard is green in all three stages, and the
  false-pass pair is reproduced on a plain `cp -R` root: `hl=true` with
  `installed=` empty.

## Findings

Two corrections, and neither changes a requirement.

**The `=` discriminator is the method chain, not `nosmartindent`.** The spec
attributed the byte-identical `=` output to `01-options`' `smartindent =
true`. Measured 2026-08-23: deleting R3's `indentexpr` assignment does not
leave `indentexpr` empty — nvim's `runtime/indent/lua.vim` re-sets it to
`GetLuaIndent()`, and on a nested Lua block `=` gives the same bytes under
treesitter and under `GetLuaIndent()` with `smartindent` **both on and
off**. So the masking was `GetLuaIndent()` agreeing, not the option. Of
eight shapes tried, a method chain is the only one where the two disagree:
treesitter indents the continuation lines by one shiftwidth,
`GetLuaIndent()` leaves them at column 0. The gate's fixture carries one,
and that is what makes box 4 a check that can fail. `nosmartindent` is kept
because the box names it.

**The `gates/waves.tsv` carve-out blocks two repo gates until it is
applied.** `gates/wave-status.sh --validate` asserts that every script under
`tests/` is named by a wave row, so the new `tests/nvim-treesitter.sh` makes
it red (`unreferenced: nvim-treesitter.sh`) and `gates/selftest.sh` red
through `wave-status.sh --selftest` — 29 PASS / 1 FAIL. Applying the wave-3
segment to a scratch copy of the registry turns `--validate` green on all
seven checks, so the segment reported is correct and sufficient. This lane
does not own `gates/waves.tsv`.

**The lockfile row regressed `tests/nvim-telescope.sh`, and the fix is the
same one spec01 wrote for E.1.** That gate seeds every lockfile key, opens
files in nearly every probe, and carries no `curl` shim — so the moment
`nvim-treesitter` became a key, each launch fired sixteen real GitHub
downloads plus a `tree-sitter build`, and the async picker waits started
missing their budgets. Measured 2026-08-23: 136 PASS / 0 FAIL on the
pre-landing tree, 127 PASS / 9 FAIL after the row landed, failures scattered
across the quickfix and picker probes. Extending its `seed_lazy` with the
same `seed_parsers` helper restored 136 PASS / 0 FAIL. spec01 named
`nvim-completion.sh` and `nvim-plugin-manager.sh` as safe to leave alone;
`nvim-telescope.sh` did not exist when it was written. `E.10` is done, so
that file had no other writer.

**`tests/nvim-lsp.sh` is regressed the same way and was left alone.** Its
probes run `vim.cmd("edit " .. PROBE_FILE)`, so `BufReadPost` fires and the
plugin loads; it seeds from the lockfile, has no `curl` shim and no parser
seeding. Measured 2026-08-23: on the pristine pre-landing tree it is
**exit 0, 125 PASS, 0 FAIL**; on the landed tree it is **exit 1, 60 PASS,
65 FAIL**, with all four of its headless probes recording `TIMEOUT`.
`09-lsp` is claimed on that file, so it has an active writer and this lane
did not touch it. **It needs the same one-line fix before E.9 can close.**
The fix is the `seed_parsers` helper now in `tests/nvim-options.sh` and
`tests/nvim-telescope.sh`, called from `seed_lazy` and gated on
`nvim-treesitter` being among `LOCK_KEYS`. `tests/nvim-colorscheme.sh` is
NOT exposed — no probe opens a file, so the plugin never loads (the same
reason `nvim-completion.sh` is safe).

**`tree-sitter` is a hard dependency and is not provisioned.**
`install()` shells out to `curl` per language and then to `tree-sitter
build`. With `tree-sitter` off PATH every language fails with `Error during
"tree-sitter build": ENOENT ... 'tree-sitter'`, the parser store stays
empty, and the launch still exits 0 — nothing marks the config broken.
`tree-sitter` is not in
[`packages-installer`](../../05-platform/02-package-provisioning/packages-installer/prd.md)
R7's required set, so a freshly provisioned machine lands in exactly that
state. That is a provisioning gap, not this node's: the manual row in
`gates/manual/wave3.md` is where it is exercised, and it is expected to fail
until the correction lands.

## Out of scope
- Anything this node's Requirements do not name. The epic ([`../prd.md`](../prd.md)) owns the shared invariants.
