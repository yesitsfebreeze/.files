---
est: 1h
footprint:
  - home/dot_config/nvim/lua/plugins/lsp.lua
  - home/dot_config/nvim/lazy-lock.json
  - tests/nvim-options.sh
---

# spec01 — `lsp.lua`, three lockfile rows, and the census

Port `~/.config/nvim/lua/plugins/lsp.lua` into the repo, grow
`lazy-lock.json` by `nvim-lspconfig`, `mason.nvim` and
`mason-lspconfig.nvim` from a real network run, and widen the E.1 census so
`tests/nvim-options.sh` stays exact. Covers PRD R1–R6. The gate that proves
them is [spec02](spec02-gate.md).

This node also closes two boxes another node parked on it:
[05-completion](../../05-completion/prd.md) R9 and its first acceptance box
are `[~]` pending the capability wiring landing here. Report their new
wording; the orchestrator makes that edit, not you — one writer per file.

## The plugin file

**`lua/plugins/lsp.lua`** — transcribe
`~/.config/nvim/lua/plugins/lsp.lua` (read it; 59 lines) in the repo's
2-space indent style. The live file already satisfies R1–R6 exactly, and
every value below was read back out of a running Neovim on 2026-08-23:

- `"neovim/nvim-lspconfig"`, `event = { "BufReadPre", "BufNewFile" }`,
  `dependencies = { { "mason-org/mason.nvim", opts = {} },
  "mason-org/mason-lspconfig.nvim", "saghen/blink.cmp" }` (R1).
- `vim.diagnostic.config({ virtual_text = { prefix = "●" },
  severity_sort = true, float = { border = "rounded", source = true } })`
  (R6).
- the `LspAttach` autocmd in `augroup("lsp_attach", { clear = true })`
  (epic I7), mapping `gd`, `gI`, `<leader>rn`, `<leader>ca` buffer-local
  with descs `LSP: Goto definition`, `LSP: Goto implementation`,
  `LSP: Rename`, `LSP: Code action` (R5).
- `vim.lsp.config("*", { capabilities =
  require("blink.cmp").get_lsp_capabilities() })` (R3).
- `vim.lsp.config("lua_ls", …)` with `diagnostics.globals = { "vim" }`,
  `workspace.checkThirdParty = false`, `telemetry.enable = false` (R4).
- `require("mason-lspconfig").setup({ ensure_installed = { "lua_ls",
  "bashls", "pyright", "rust_analyzer", "tailwindcss" } })` (R2).

Keep all four live comments. Add one more, at the top, and it is a
constraint rather than a note:

> The LSP log kill-switch is not here. `vim.lsp.log.set_level(OFF)` lives
> in `lua/config/options.lua` ([01-options](../../01-options/prd.md) R11)
> and this file must never raise the level: Neovim mirrors every LSP
> stderr line into `~/.local/state/nvim/lsp.log` with **no rotation**, and
> a chatty rust-analyzer once grew it to 17 GB. `rust_analyzer` is in R2's
> `ensure_installed`, so this is exactly the file where turning logging up
> to debug a server is tempting.

Write it as a comment in the file. spec02's `--tree` stage asserts both
halves: the reason is present, and `lsp.lua` calls
`vim.lsp.log.set_level` nowhere.

Order the `config` body as the live file does — diagnostics, then the
`LspAttach` autocmd, then `vim.lsp.config("*")`, then
`vim.lsp.config("lua_ls")`, then `mason-lspconfig.setup`. The last position
is load-bearing and the live comments say why: `setup` enables the
installed servers synchronously, so a `vim.lsp.config` call after it would
not be merged into the config the first attach reads.

## Why all three plugins are load-bearing, so none gets "simplified" out

Measured 2026-08-23 against a seeded, offline Neovim, one distinct
observable each:

| plugin | what it alone supplies |
|---|---|
| `nvim-lspconfig` | the bundled `lsp/lua_ls.lua` — the reason `vim.lsp.config["lua_ls"].cmd` reads `{ "lua-language-server" }` when nothing in our config sets `cmd` |
| `mason.nvim` | the server binaries, and prepending `<data>/mason/bin` to `PATH` (`PATH = "prepend"` is its default) so that bare `cmd` resolves |
| `mason-lspconfig.nvim` | `ensure_installed`, and `automatic_enable` calling `vim.lsp.enable()` for every installed package |

## `lazy-lock.json` — grown from a real run, never by hand

E.2's policy, and [05-completion](../../05-completion/prd.md)'s spec01 is
the worked precedent. Network flow: stage `home/dot_config/nvim/` into a
fresh scratch root, no seed, launch, open a `.lua` file so the
`BufReadPre` event fires and lazy installs the three new plugins.

Then **merge, do not copy**: take only the `nvim-lspconfig`, `mason.nvim`
and `mason-lspconfig.nvim` rows from the scratch lockfile and keep every
pre-existing row byte-identical (python3). Lazy rewrites every row after an
install and records the bootstrap clone's stable HEAD for `lazy.nvim`,
which can sit past E.2's pinned commit — a wholesale copy would move E.2's
pin as a side effect of this node.

None of the three carries a `version` pin, so no tag assertion applies
here; that check belongs to blink alone.

## The census in `tests/nvim-options.sh`

Its `--tree` stage asserts the staged file list by exact equality, so a new
file makes it red. **Read the current census and insert
`./lua/plugins/lsp.lua` at its `LC_ALL=C` position — do not transcribe a
fixed list.** [11-colorscheme](../../11-colorscheme/prd.md) is specced
against the same line and may land first; a hardcoded list would silently
drop its entry.

Nothing else in that file changes. Its seed helper is already
lockfile-driven, so the three new plugins seed themselves, and
`tests/nvim-plugin-manager.sh --network` already loops over the lockfile's
keys, so its restore check widens on its own.

## The manual entries — read-only check, and one correction to file

`home/dot_config/nushell/help/nvim.nuon` already carries this node's three
entries (`gd and gI`, `<leader>rn and <leader>ca`, `Neovim's own LSP keys`,
all with `source: prds/03-editor/09-lsp/prd.md`). This node owes no help
edit, and must not make one: `home/dot_config/nushell/` is another lane's
footprint and H.2 is claimed on it.

Confirm the entries still describe what landed. One mismatch is already
known and is a **correction to report, never an edit here**: the four
`nvim-map` targets on `gd and gI` and `<leader>rn and <leader>ca` carry no
`desc` field, and `help/README.md` says an absent `desc` means "compare
against this entry's `title`". The titles are
`Jump to a definition or an implementation` and
`Rename a symbol or take a code action`; the live descs are
`LSP: Goto definition`, `LSP: Goto implementation`, `LSP: Rename`,
`LSP: Code action`. Each entry documents two maps with two different descs,
so no single title can ever match both — the fix is an explicit `desc` per
target, in the help lane. H.4's drift check is what would go red on it.
Report the four values; do not touch the file.

## Acceptance

- [x] `home/dot_config/nvim/lua/plugins/lsp.lua` exists and, comments
      stripped, carries every value R1–R6 names (spec02's `--tree` stage
      runs the checks; run them inline until it exists).
- [x] `lsp.lua` contains the 17 GB / no-rotation reason and calls
      `vim.lsp.log.set_level` nowhere.
- [x] `home/dot_config/nvim/lazy-lock.json` parses, holds
      `nvim-lspconfig`, `mason.nvim` and `mason-lspconfig.nvim` with 40-hex
      commits, and every row that existed before this node is
      byte-identical (quote the pre-landing and post-landing rows).
- [x] `bash tests/nvim-options.sh` exits 0 with the census grown by
      `./lua/plugins/lsp.lua`.
- [x] `bash tests/nvim-plugin-manager.sh` exits 0 on all three stages; the
      `--network` restore loop prints one commit equality per lockfile key,
      six of them.
- [x] `bash tests/nvim-completion.sh` exits 0 — the neighbour that shares
      the seed helper and the lockfile.
- [x] `assert_unchanged` green in every gate run: no write to real
      `~/.config/nvim`, `~/.local/share/nvim`, `~/.local/state/nvim`,
      `~/.cache/nvim`.

## Verify and Proof

```sh
bash tests/nvim-options.sh
bash tests/nvim-plugin-manager.sh
bash tests/nvim-completion.sh
python3 -c 'import json; d=json.load(open("home/dot_config/nvim/lazy-lock.json")); print(sorted(d)); [print(k, v["commit"], len(v["commit"])) for k,v in sorted(d.items())]'
/usr/bin/grep -c 'set_level' home/dot_config/nvim/lua/plugins/lsp.lua   # expect 0 matches, exit 1
/usr/bin/grep -n '17 GB' home/dot_config/nvim/lua/plugins/lsp.lua
```
