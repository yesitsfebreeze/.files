---
state: done
claim:
priority: 15
est: 2.5h
task: E.6
mode: afk
needs:
  - 03-editor/04-plugin-manager
  - 06-help/01-content-model
verify: ""
---

# Completion (blink.cmp)

Parent: [Neovim epic](../prd.md) · C 4 · U 9 · source: "Completion
(blink.cmp)" in [`capabilities-nvim.md`(../../../../docs/capabilities-nvim.md)

Purpose: One batteries-included completion engine — LSP, snippets, path,
buffer, signature help, and fuzzy matching — replacing the nvim-cmp + LuaSnip
+ cmp-* constellation. Fewer plugins, faster per keystroke.

## Requirements

Executed 2026-08-22 by `bash tests/nvim-completion.sh` (both stages, exit 0,
74 PASS) on nvim 0.12.4 + blink v1.10.2: text checks in `--tree`, the config
introspected from `blink.cmp.config` and the behavior driven by feedkeys in
`--headless`, six counterfactuals each turning its check red.

- [x] **R1** — **Plugin.** `saghen/blink.cmp`, lazy on `InsertEnter`, version
      pinned to `1.*`. The tag matters: a tagged release ships the prebuilt
      Rust fuzzy library, so no local Rust toolchain is needed. Proven:
      `pre_loaded=false` at startup, `post_loaded=true` after `doautocmd
      InsertEnter`; the lockfile-generation clone sat on tag `v1.10.2`
      (`describe --tags --exact-match`); event-deleted counterfactual loads
      at startup and goes red.
- [x] **R2** — **Snippets.** `rafamadriz/friendly-snippets` as a dependency.
      Proven: the snippet probe's menu holds a `for` item that expands;
      deps-deleted counterfactual loses it.
- [x] **R3** — **Keymap.** `super-tab` preset (`<Tab>` selects/accepts and
      jumps snippet placeholders, `<S-Tab>` reverses, `<C-n>`/`<C-p>` cycle,
      `<C-Space>` toggles, `<C-e>` hides) plus `<CR>` = accept-or-fallback and
      `<Esc>` = cancel-or-fallback. The fallbacks are load-bearing: with no
      menu open, both keys must behave normally. Proven: desc readback after
      load (`<Tab>` = `blink.cmp: <Custom Fn>, Snippet Forward` — the
      `<Custom Fn>` half is super-tab's discriminator, the default preset
      maps `snippet_forward` too; `<CR>` = `blink.cmp: Accept`, `<Esc>` =
      `blink.cmp: Cancel`); fallbacks executed under Acceptance.
- [x] **R4** — **Sources.** `lsp`, `snippets`, `path`, `buffer`; declared with
      `opts_extend` on `sources.default` so a later spec can add to the list
      rather than replace it. Proven: readback exactly
      `lsp,snippets,path,buffer`; a sibling `{ "omni" }` spec MERGES to
      `lsp,snippets,path,buffer,omni`, and with `opts_extend` deleted the
      same sibling REPLACES to `omni` alone.
- [x] **R5** — **Docs.** Auto-show after 200 ms. Proven:
      `doc_auto_show=true`, `doc_delay=200` introspected.
- [x] **R6** — **Signature help.** Enabled (replaces a separate signature
      plugin). Proven: `sig_enabled=true` introspected.
- [x] **R7** — **Appearance.** `nerd_font_variant = "mono"`. Proven:
      `nerd=mono` introspected.
- [x] **R8** — **Fuzzy.** `prefer_rust_with_warning` — use the Rust matcher,
      warn (don't fail) if it's unavailable. Proven: config readback plus
      `implementation_type=rust` in the live menu probe — the rust side
      actually taken from the seeded prebuilt library, not the fallback.
- [x] **R9** — **LSP capabilities.** Exported to the LSP layer via
      `require("blink.cmp").get_lsp_capabilities()` — wired in
      [09-lsp](../09-lsp/prd.md), not here. Met at the E.6 slice: the seam
      returns a `textDocument.completion` table with `snippetSupport=true`
      (executed).

      **Closed 2026-08-23 by E.7**, and written by the orchestrator on that
      node's transition since a worker may not edit a sibling's body.
      `vim.lsp.config["lua_ls"].capabilities.textDocument.completion.completionItem.snippetSupport`
      reads back `true` through the `"*"` merge, with blink's own markers
      present — `resolveSupport.properties = documentation, detail,
      additionalTextEdits, command, data`, and `insertTextModeSupport` set.
      Proven by `bash tests/nvim-lsp.sh --headless`, 125 PASS / 0 FAIL.

## Acceptance
- [~] Typing in a file with an attached LSP shows completions; `<Tab>` accepts
      and jumps through a snippet's placeholders. Snippet half executed
      2026-08-22: `for` accepted from the menu starts a snippet session, the
      body expands (`for … do`), and a forward placeholder jump remains —
      what `<Tab>` drives.

      **With-LSP attach half closed 2026-08-23 by E.7**, orchestrator's edit:
      a real `lua_ls` client attaches offline to a Lua buffer (`nclients=1`,
      `client=lua_ls`) and blink's capabilities reach it. The box stays `[~]`
      deliberately — *menu content with a server behind it* is a wave-4
      manual row, because `lua_ls` returns no API members under a scratch
      `HOME`: E.7 measured three completion items across twelve five-second
      retries, all of them words already in the buffer.
- [x] `<CR>` on an empty line with no menu inserts a newline; `<Esc>` with no
      menu leaves insert mode. Executed 2026-08-22 via feedkeys:
      `menu_pre=false`, `<Esc>` → mode `n`; `<CR>` → line count +1.
- [x] No nvim-cmp, LuaSnip, or `cmp-*` plugin appears in `:Lazy`. Proven at
      state level (headless cannot render the TUI): no key of
      `lazy.core.config.plugins` is `nvim-cmp`, starts `cmp-`, or contains
      `luasnip` case-folded; plus the comment-stripped ban sweep over
      `lua/`, with a planted `hrsh7th/nvim-cmp` spec caught every run.

## Out of scope
- Anything this node's Requirements do not name. The epic ([`../prd.md`](../prd.md)) owns the shared invariants.
