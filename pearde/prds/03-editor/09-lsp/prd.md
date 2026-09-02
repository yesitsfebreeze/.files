---
state: done
claim: 
priority: 12
est: 3.5h
actual: 50m
task: E.7
mode: afk
needs:
  - 03-editor/05-completion
  - 06-help/01-content-model
verify: ""
---

# LSP (mason + native 0.11)

Parent: [Neovim epic](../prd.md) · C 6 · U 9 · source: "LSP (mason + native
0.11)" in [`capabilities-nvim.md`(../../../../docs/capabilities-nvim.md)

Purpose: Language servers install themselves and enable themselves;
configuration goes through Neovim 0.11's native `vim.lsp.config()` API rather
than a lspconfig-specific setup path.

## Requirements

Executed 2026-08-23 by `bash tests/nvim-lsp.sh` (both stages, exit 0, 125
PASS) on nvim 0.12.4, mason.nvim v2.3.1, mason-lspconfig at
`9d28935`, blink v1.10.2: text checks in `--tree`, the merged
`vim.lsp.config` view and a real `lua_ls` client in `--headless` with every
network binary poisoned, eight counterfactuals each turning its check red.

- [x] **R1** — **Plugins.** `neovim/nvim-lspconfig` (for its bundled
      per-server `lsp/*.lua` defaults), lazy on `BufReadPre`/`BufNewFile`,
      with `mason-org/mason.nvim` (v2), `mason-org/mason-lspconfig.nvim`, and
      `saghen/blink.cmp` as dependencies. Proven: `pre_loaded=false` at
      startup, `post_loaded=true` after the `:edit`; the bundled default
      reaching us as `cmd=lua-language-server`, a value nothing in our config
      sets; counterfactuals — the `event` line deleted loads it at startup,
      and swapping the `nvim-lspconfig` root spec for a bare `mason.nvim`
      one empties `cmd` and attaches no client.
- [x] **R2** — **Install + enable.** `mason-lspconfig.setup({ ensure_installed
      = … })` with lua_ls, bashls, pyright, rust_analyzer, tailwindcss — it
      auto-installs and auto-enables them via `vim.lsp.enable()`. Proven: the
      list as *received* is `ensure=lua_ls,bashls,pyright,rust_analyzer,
      tailwindcss`; in the five-package root `vim.lsp.is_enabled` is true for
      all five and `get_installed_servers()` sorted is
      `bashls,lua_ls,pyright,rust_analyzer,tailwindcss`; the `setup` call is
      the last statement of the `config` body. The control that makes this a
      claim: withhold the mason seed and `is_enabled("lua_ls")` is false with
      no client, while `ensure_installed` is still written down — the enable
      follows the installed packages, not the list.
- [x] **R3** — **Capabilities.** `vim.lsp.config("*", { capabilities =
      require("blink.cmp").get_lsp_capabilities() })` — completion
      capabilities applied to every server in one place. Proven:
      `vim.lsp.config["lua_ls"].capabilities` carries
      `completionItem.snippetSupport=true` and two blink-only markers core
      never sets — `resolveSupport.properties = documentation, detail,
      additionalTextEdits, command, data` and `insertTextModeSupport`;
      putting a sentinel in our `"*"` call flips lua_ls to
      `snippetSupport=false`, so this call is what named servers read.
      Recorded, because it is a trap for the next reader: blink v1.10.2 ships
      `plugin/blink-cmp.lua`, which registers the same `"*"` entry itself, so
      **deleting** our call changes nothing observable. The gate asserts that
      too. R3 is explicit rather than load-bearing on this blink version, and
      is worth keeping explicit — it is what keeps the capability wiring
      out of a plugin's private startup file.
- [x] **R4** — **Per-server settings.** Through `vim.lsp.config(<name>, …)`,
      merged over nvim-lspconfig's bundled config. lua_ls: `vim` as a known
      global, `checkThirdParty = false`, telemetry off. The other four run on
      defaults. Proven: readback `globals=vim`, `thirdparty=false`,
      `telemetry=false`; end to end, the scratch `lsp.log` holds
      `workspace/didChangeConfiguration` with `params = { settings = { Lua =
      { codeLens = { enable = true }, diagnostics = { globals = { "vim" } },
      hint = { enable = true, semicolon = "Disable" }, telemetry = { enable =
      false }, workspace = { checkThirdParty = false } } } }` — the
      `codeLens` and `hint` keys are nvim-lspconfig's bundled defaults, which
      is the merge itself, observed. Counterfactual: emptying `globals` turns
      both the readback and the notification grep red.
- [x] **R5** — **Don't re-map what core provides.** Neovim 0.11 ships `grn`
      (rename), `gra` (code action), `grr` (references), `gri`
      (implementation), `gO` (symbols), `K` (hover), and `]d`/`[d`
      (diagnostics). Add only the familiar aliases, buffer-local on
      `LspAttach`: `gd` definition, `gI` implementation, `<leader>rn` rename,
      `<leader>ca` code action. Proven with `lua_ls` attached: our four are
      `buffer=1` with descs `LSP: Goto definition`, `LSP: Goto
      implementation`, `LSP: Rename`, `LSP: Code action`, while `grn`/`gra`/
      `grr`/`gri`/`gO`/`]d`/`[d` are `buffer=0` with core's own descs and `K`
      is core's `vim.lsp.buf.hover()` attached per buffer. The negative half
      is a tree check: the file maps none of the eight. Counterfactuals —
      deleting `bmap("gd")` loses only `gd`; deleting the whole `LspAttach`
      block loses all four while every core key stays.
- [x] **R6** — **Diagnostics.** Virtual text with a `●` prefix,
      `severity_sort` on, float with a rounded border showing the source.
      Proven: `vim.diagnostic.config()` reads back `vt_prefix=●`,
      `sev_sort=true`, `float_border=rounded`, `float_source=true`; changing
      the prefix in a copy turns the check red.

## Acceptance
- [~] Open a Lua file in this config: lua_ls attaches, `vim` is not flagged
      undefined, and completion offers Neovim API members. Attach half
      executed 2026-08-23: with curl and wget refusing (exit 66) and all four
      mason registry refreshes failed, `#vim.lsp.get_clients({ bufnr = 0 })`
      is 1 and the client is `lua_ls`, from the seeded mason package. The
      other two halves cannot be reached headless and are wave-4 manual rows:
      measured in the gate's own root, `textDocument/completion` after `vim.`
      returns three items, all words already in the buffer and no API member,
      across twelve five-second retries; and the `vim`-not-flagged half is
      vacuous there, because a planted `undefined_global_xyz` is not flagged
      either.
- [x] `gd` jumps to a definition; `K` shows hover without any local mapping
      for it. Executed 2026-08-23 by keypress, not by readback: with `lua_ls`
      attached to a fixture whose `target_fn` is defined on line 1 and called
      on line 5, `gd` from line 5 lands on line 1 with `local function
      target_fn()` under the cursor; `K`, for which this config sets no
      mapping, opens a floating window where none was open before.
- [ ] A fresh machine installs all five servers unattended on first relevant
      buffer. Not automatable and deliberately not faked: `mason-lspconfig`'s
      `setup()` guards `ensure_installed` with `not platform.is_headless`
      (`lua/mason-lspconfig/init.lua:31`), so no scripted run can ever
      trigger an install. It is a wave-4 manual row in
      [`gates/manual/wave4.md`](../../../gates/manual/wave4.md).
      *(b) — genuinely unmet: a manual wave-4 row, not automatable by design,
      and no human has run it on a fresh machine.*

## Out of scope
- Anything this node's Requirements do not name. The epic ([`../prd.md`](../prd.md)) owns the shared invariants.
