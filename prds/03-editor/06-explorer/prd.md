---
state: done
claim: 
priority: 8
est: 1.75h
actual: 45m
task: E.10
mode: afk
needs:
  - 03-editor/04-plugin-manager
  - 06-help/01-content-model
verify: ""
---

# File explorer (oil.nvim)

Parent: [Neovim epic](../prd.md) · C 2 · U 8 · source: "File explorer
(oil.nvim)" in
[`capabilities-nvim.md`](../../../docs/capabilities-nvim.md)

Purpose: Directories as editable buffers: rename, create, and delete files
with normal editing commands instead of a bespoke tree UI. Replaces netrw
(disabled in [04-plugin-manager](../04-plugin-manager/prd.md)).

## Requirements
- [x] **R1** — **Plugin, loaded eagerly.** `stevearc/oil.nvim` with
      `nvim-tree/nvim-web-devicons`, `lazy = false`. **Not lazy on `keys`**,
      which is what the live config does and is live bug L-7: oil installs
      its `default_file_explorer` hijack in `setup()`, so while it is
      unloaded it hijacks nothing — and with netrw disabled by
      [`04-plugin-manager`](../04-plugin-manager/prd.md), `:e some/dir`
      opens neither, a dead end stock Neovim does not have. `<leader>e`
      (R3) is unaffected; it stops being a *loader* and stays a binding.
- [x] **R2** — **Hidden files.** `view_options.show_hidden = true` — a
      dotfiles user needs dotfiles visible by default.
- [x] **R3** — **Keymap.** `<leader>e` → `:Oil`, declared in the spec's
      `keys` as a **binding, not a loader**.

      *Parenthetical corrected 2026-08-23 by the orchestrator: it read "so it
      lazy-loads", which contradicts R1.* Measured mechanism —
      `Handler.setup()` runs before `Loader.startup()`, so lazy first
      registers a loader stub for the key; loading oil eagerly then calls
      `Handler.disable` → `keys:_del` → `keys:_set`, replacing the stub with
      the real `<cmd>Oil<CR>` mapping. The two shapes are distinguishable:
      eager gives `rhs = "<cmd>Oil<CR>"` and `expr = 0`, lazy gives
      `rhs = nil` and `expr = 1`. A `desc`-only check cannot tell them
      apart — both report `desc = "Open file explorer"` — so no gate may
      claim to prove this from the description alone.
- [x] **R4** — **Why oil is not lazy.** Recorded so it is not "optimised"
      back: live bug L-7 offered two corrections — make oil eager, or drop
      the `:e some/dir` acceptance check. The first was taken
      (2026-08-21, afk, under
      [`w0-4-s2-corrections/editor`](../../00-delivery/corrections/w0-4-s2-corrections/editor/prd.md)
      R6). Dropping the check would have made this node self-consistent by
      abandoning the capability its Purpose names — replacing netrw — and
      left `:e some/dir` worse than stock. The cost is one C-2 plugin at
      startup, the same trade
      [`11-colorscheme`](../11-colorscheme/prd.md) R1 already makes for
      tinted-nvim: a thing that must be in place before the user's first
      action cannot be lazy on that action.

## Acceptance
- [x] `<leader>e` opens **the directory of the current file** as a buffer
      showing dotfiles — the cwd only when no file is loaded.
      *Corrected 2026-08-23 by the orchestrator:* the box said "the current
      directory", and measured behaviour is the file's directory. From
      `sub/inner.txt` it opens `oil://…/sub/`, not the cwd. The manual
      entry's wording was already the right one.
      **This box defends R2 and R3, not R1.** It passes identically on the
      lazy shape, so it cannot be cited as proof that oil loads eagerly. It
      *is* falsifiable for the dotfile clause: with `show_hidden = false` the
      listing drops from 4 lines to 2, since `../` also starts with a dot.
- [x] Renaming a line and `:w` renames the file on disk — **and this is an
      integration smoke check, not proof of any requirement.** Measured: it
      works byte-identically on the lazy shape, with `show_hidden = false`,
      and with `dependencies` deleted. Its only discriminator is the file
      being absent. Nobody may cite it for R1-R4.
      Also, `:w` alone does not rename: it opens oil's confirmation float
      (`filetype = oil_preview`, `MOVE visible.txt -> renamed.txt`,
      `[Y]es [N]o`), clears `modified`, and leaves the disk untouched. The
      confirm keys are `y Y o O`; **`<CR>` is not one of them.** A probe that
      omits the `y` reads a healthy rename as broken.
- [x] `:e some/dir` opens oil, not netrw. **This is the box the L-7
      correction defends, and the only one.** With `lazy = false` removed,
      `:e sub` yields an ordinary empty buffer named for the directory,
      `filetype` empty, oil unloaded — red as required.
- [x] The icon column actually renders an icon: the `visible.txt` line
      contains a byte outside ASCII. Good run `/002 󰈙  visible.txt`, broken
      run `/002 visible.txt`.

      **Rationale corrected 2026-08-23 by the orchestrator — I added this box
      claiming it isolates R1's `dependencies` clause, and it does not.**
      Measured on the landed shape: deleting **oil's** `dependencies` line
      alone changes nothing, because `statusline.lua:74` (E.13) already
      declares `nvim-web-devicons`. Only deleting **both** empties the
      column, and it does so silently — stderr empty, `messages` empty, exit
      0. So the counterfactual has to mutate two files, and it does, with that
      reason in its comment. The box is ticked for what it proves — the icon
      renders, behind a real red counterfactual — and the *isolating* check of
      R1's clause is the `--tree` text assertion, not this one.

## Out of scope
- Anything this node's Requirements do not name. The epic ([`../prd.md`](../prd.md)) owns the shared invariants.

## Implementation record

Landed 2026-08-23 (task E.10, implementer lane). Four files:
`home/dot_config/nvim/lua/plugins/explorer.lua` (new),
`home/dot_config/nvim/lazy-lock.json` (one row), `tests/nvim-explorer.sh`
(new), `tests/nvim-options.sh` (the census string). `gates/` untouched —
`waves.tsv` and `gates/manual/wave3.md` are the orchestrator's, and their
two boxes in [spec02](specs/spec02-gate.md) stay open by that carve-out.

`bash tests/nvim-explorer.sh` — 107 PASS, 0 FAIL, exit 0. Which probe
closed which acceptance box: **C + C2 + D** box 1, **E** box 2 (smoke
only), **B** box 3, **D** box 4.

Five findings the specs did not have right. None changed what was built;
all five changed how it is *proven*, so they are recorded here rather than
lost in a lane report.

1. **The `dependencies` clause has no behavioural defence, and the fourth
   acceptance box's stated rationale is stale.** The box was added on the
   measurement that deleting `dependencies` makes the icon column render
   empty. Re-measured on the tree as it stands: deleting *oil's* line alone
   changes **nothing** — the listing still renders `/002 󰈙  visible.txt` —
   because [`13-statusline`](../13-statusline/prd.md) already declares
   `dependencies = { "nvim-tree/nvim-web-devicons" }`, so devicons is on
   the rtp either way. Only deleting **both** lines empties the column
   (`/002 visible.txt`), and then nothing complains: stderr empty,
   `:messages` empty, exit 0. The gate's counterfactual 3 therefore mutates
   two files, with that reason in a comment. The box is ticked for what it
   actually proves — the icon renders, with a real red counterfactual — and
   **may not be cited as an isolating check of R1's `dependencies`
   clause**. What defends that clause is the `--tree` text check, whose
   selftest is a deleted line.
2. **`lazy = false` is the same unfalsifiable-grep trap the spec flagged
   for netrw, and the spec missed it.** R4 *requires* a comment naming
   `lazy = false`, so an unscoped `grep -qF 'lazy = false'` matches the
   comment and cannot fail — the selftest that deletes the code line stayed
   green until the check was scoped. The gate now strips comment lines for
   every code check (`nocode`) and greps *only* comment lines for the two
   R4 checks, so each half is falsifiable alone.
3. **The negative control returns 2, not 0.** spec02 expects
   `/usr/bin/grep -rniE 'oil|explorer|devicon'` over
   `home/dot_config/nvim/` to be zero before this node lands, and told the
   next reader to find out why if it is not. It is 2:
   `lua/plugins/statusline.lua:74` and the `nvim-web-devicons` row in
   `lazy-lock.json`, both E.13's. Neither can make an assertion here pass
   vacuously — every tree check is scoped to `lua/plugins/explorer.lua`,
   and the lockfile check is membership — but the expectation itself is
   stale and the count is quoted rather than assumed.
4. **One lockfile row, not two.** spec01 plans for `oil.nvim` *and*
   `nvim-web-devicons`; devicons was already pinned by E.13, so the merge
   added exactly one line. The rewrite trap spec01 warns about is real and
   was observed: the resolve run moved `nvim-lspconfig`,
   `mason-lspconfig.nvim`, `nvim-treesitter` and `telescope.nvim` off their
   repo pins, four rows other nodes own. Only the `oil.nvim` line was
   merged, textually, in lazy's one-line-per-plugin shape.
5. **The work dir's realpath, not its path.** `$TMPDIR` on this machine is
   `/var/folders/…` while its realpath is `/private/var/folders/…`, and oil
   normalises the buffer name to the resolved path. Comparing an `oil://`
   URL against the raw env value failed three checks at once and read like
   a broken hijack. Every probe resolves with `vim.uv.fs_realpath`.

Two corrections to file, neither in this lane's footprint:

- `home/dot_config/nushell/help/nvim.nuon`'s `<leader>e` entry has a stale
  `why`: it says oil "is lazy on that key, so its file-explorer hijack is
  not installed until the first time you press it". That describes the
  pre-correction shape this node removes. Measured under the landed shape:
  `:e some/dir` opens oil (`filetype = oil`, buffer `oil://…`) with no key
  pressed. The `verify` target is correct and was left alone; the S.5 lane
  holds that file.
- `gates/selftest.sh` is red on exactly one check —
  `registry: every script under tests/ is named by a row (unreferenced:
  nvim-explorer.sh)`. It clears the moment the orchestrator appends this
  node's two stages to the wave-3 row; proven by running
  `gates/wave-status.sh --validate` against a scratch registry with those
  segments appended, which reports `unreferenced: none`.
