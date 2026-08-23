---
state: done
claim: 
priority: 10
est: 2.5h
actual: 30m
task: E.9
mode: afk
needs:
  - 03-editor/04-plugin-manager
  - 06-help/01-content-model
verify: "bash tests/nvim-telescope.sh"
---

# Fuzzy finder (telescope)

Parent: [Neovim epic](../prd.md) · C 5 · U 9 · source: "Fuzzy finder
(telescope)" in [`capabilities-nvim.md`](../../../docs/capabilities-nvim.md)

Purpose: In-editor fuzzy finding over files, grep, buffers, and help — with a
multiselect flow that lands marked entries in the quickfix list. Note: this is
the editor's finder. The shell has its own, television-based
([04-shell/04](../../04-shell/04-television/prd.md)); they are deliberately separate
tools and should not be unified.

## Requirements
- [x] **R1** — **Plugins.** `nvim-telescope/telescope.nvim` with
      `plenary.nvim` and `telescope-fzf-native.nvim` (`build = "make"`); load
      the `fzf` extension under `pcall` so a failed native build degrades to
      the Lua sorter instead of breaking the finder.

      Proven 2026-08-23 by `bash tests/nvim-telescope.sh`: the `--tree`
      stage matches all three repo strings, `build = "make"` and the
      `pcall`; probe A reads all three plugins as unloaded at startup and
      loaded after `<leader>ff`; probe G, on a root with `build/libfzf.so`
      deleted, reads the scoring function out of
      `telescope.nvim/lua/telescope/sorters.lua` — the Lua fallback,
      positively identified.
- [x] **R2** — **Lazy.** On `cmd = "Telescope"` plus the keys below.
      Proven: probe A reads `vim.fn.exists(":Telescope")` = 2, lazy's cmd
      stub, and the counterfactual that deletes the line reads 0.
- [x] **R3** — **Keymaps.** `<leader>ff` and `<leader><space>` find_files,
      `<leader>fg` live_grep, `<leader>fb` buffers, `<leader>fh` help_tags.
      Proven: probe A reads the five descs back before telescope loads
      (`Find files`, `Find files`, `Live grep`, `Buffers`, `Help tags`),
      probe F drives every one to its picker (`Find Files`/4,
      `Find Files`/4, `Live Grep`/0, `Buffers`/2, `Help`/11296), and a
      `needle` query returns 1 result on `ddd.txt` — which is also what
      proves `rg` is reached rather than an empty picker passing for a
      working one.
- [x] **R4** — **Multiselect → quickfix.** `<Tab>` / `<S-Tab>` toggle a mark
      and move (worse/better). `<CR>` is custom: if any entries are marked,
      send them all to the quickfix list and open it; otherwise perform the
      normal single-entry open.

      **Only the `<CR>` clause is ours.** Measured 2026-08-23: the
      `<Tab>`/`<S-Tab>` rows restate telescope's own defaults
      (`mappings.lua:167` for insert, `:201` for normal), and deleting both
      leaves the flow byte-identical — so no behavioural check can defend
      them and no counterfactual on them can go red. They stay because the
      manual documents them as this environment's flow and an explicit table
      is what makes `<CR>` legible beside them, but **do not let anyone write
      a gate check that claims to prove them**; it would pass on an empty
      table. Noted by the orchestrator so the next reader does not mistake a
      restated default for a verified behaviour.

      Proven, `<CR>` clause only: probe B marks three entries and reads
      `getqflist()` = 3 with a `buftype=quickfix` window; the counterfactual
      that deletes the `<CR>` row still marks three and reads `qf_len=0`,
      `qf_win_open=false`. The direction half is probe D — one `<Tab>` moves
      the selection row by −1 onto the next entry, one `<S-Tab>` returns it
      (`rows=249,248,249`) — and no counterfactual deletes the `<Tab>` rows,
      because with both gone the flow is unchanged. The gate carries that
      instruction in a comment beside the counterfactual list.
- [x] **R5** — **Same maps in both modes.** The mapping table is shared
      between insert and normal mode (it's read-only, so one table is safe).

      **The discriminator is `<CR>`, not `<Tab>`.** Measured: with the
      normal-mode half dropped, normal-mode `<Tab>` still marks two entries
      — only `getqflist()` falls to 0. A counterfactual built on `<Tab>`
      therefore proves nothing; it must be built on the quickfix result.
      And "one shared table" is **not** provable by callback identity:
      telescope wraps per mode, so
      `maparg(k,"i").callback ~= maparg(k,"n").callback` even when one table
      is passed twice. Both corrections added by the orchestrator from E.9's
      analyst round.

      Proven on the quickfix result: probe E stops insert mode inside the
      picker (`mode=n`), finds all three keys buffer-local in both `i` and
      `n`, marks two entries and reads `getqflist()` = 2. The
      counterfactual that reduces the table to `{ i = maps }` still marks
      two in normal mode and reads `qf_len=0` — exactly the discriminator
      the note calls for. `cb_identical=false` is reported by the probe and
      asserted nowhere, so nobody mistakes the per-mode wrap for a defect.

## Acceptance
- [x] `<leader>ff`, mark three files with `<Tab>`, `<CR>`: the quickfix list
      opens containing exactly those three. Automated — measured headless:
      three marks yield `getqflist()` = 3 and a `buftype=quickfix` window.

      Closed by probe B of `tests/nvim-telescope.sh --headless`:
      `num_results=4`, `multi=3`, `marked=aaa.txt,bbb.txt,ddd.txt`,
      `qf_len=3`, `qf_names=aaa.txt,bbb.txt,ddd.txt`,
      `qf_equals_marks=true`, `qf_win_open=true`. The comparison is set
      equality against the labels captured before `<CR>`, so it does not
      depend on the sorter's order.
- [x] `<CR>` with nothing marked opens the highlighted entry, and the
      quickfix list stays empty.

      Closed by probe C: `multi=0`, `sel=aaa.txt`, `opened=aaa.txt`,
      `opened_is_sel=true`, `qf_len=0`, `qf_win_open=false`.
- [x] **Reworded 2026-08-23 by the orchestrator, because the original could
      not fail.** It read: "Deleting the compiled fzf-native artifact still
      leaves a working finder." Measured — with `build/libfzf.so` deleted
      *and* the `pcall` removed, the finder still works completely: 4
      results, 3 marks, quickfix opens, exit 0. `telescope.setup()` runs
      before the failing `load_extension`, so the `pcall` buys a **clean
      startup**, not a working finder. The box splits in two:
      - the finder still works with the artifact deleted, **and**
      - `:messages` is clean — without the `pcall` it carries
        `Failed to run \`config\` for telescope.nvim`.

      Both halves closed by probe G, which runs against a second staged root
      with `build/libfzf.so` deleted after the seed: `num_results=4`,
      `multi=3`, `qf_len=3`, `qf_win_open=true` — the finder is whole —
      and `msgs_has_failed_config=false`, with the stage's stderr carrying
      no such line either. Counterfactual 5 removes the `pcall` on that same
      root and turns *only* the second half red
      (`msgs_has_failed_config=true`, `msgs_len=1834`, the line on stderr)
      while all four behavioural values stay identical.
- [x] The extension is positively asserted to have loaded, because a machine
      where `make` never ran is silent about it: lazy exits 0, writes no
      `build/` dir, and prints nothing to stderr. So
      `telescope._extensions.manager` must carry the key `fzf`, and
      `debug.getinfo(picker.sorter.scoring_function,"S").short_src` must
      name `telescope-fzf-native` rather than
      `telescope.nvim/lua/telescope/sorters.lua`.

      Closed by probe A: `ext_fzf=true` — read with `rawget`, because
      `telescope._extensions.manager` carries an `__index` that tries to
      *load* a missing extension, and a plain `manager.fzf` on a root
      without the artifact raises inside the probe's own callback (measured:
      the probe hung to the watchdog) — and
      `sorter_short_src` reading
      `...escope-fzf-native.nvim/lua/telescope/_extensions/fzf.lua`.
      Note the assertion matches `fzf-native`, not `telescope-fzf-native`:
      `short_src` truncates at 60 characters and eats the leading `tel`, so
      the untruncated `debug.getinfo(...).source` is asserted beside it.
      Probe G is the other side of the same fact: with the artifact gone,
      `ext_fzf=false` and the scoring function comes from
      `telescope.nvim/lua/telescope/sorters.lua`.

## Out of scope
- Anything this node's Requirements do not name. The epic ([`../prd.md`](../prd.md)) owns the shared invariants.
