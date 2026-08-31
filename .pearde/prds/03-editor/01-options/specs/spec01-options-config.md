# spec01 — `home/dot_config/nvim/`: init.lua + options.lua, the epic's root

Delivers R1–R12 as the repo's first managed Neovim files and establishes
the layout every later editor node extends. Two files: `init.lua` (load
order, the `.jd` filetype, the require seam for E.2–E.4) and
`lua/config/options.lua` (the full options baseline, the whitespace
rendering, the LSP log kill-switch). The live files at `~/.config/nvim/`
are the model and match the PRD line for line; the port is verbatim in
content, with the comments' reasons carried and one comment corrected.

**Est:** 1h

**Footprint:** `home/dot_config/nvim/init.lua` (create),
`home/dot_config/nvim/lua/config/options.lua` (create)

## Layout — this spec sets it for the whole epic

- chezmoi maps `home/dot_config/nvim/<path>` → `~/.config/nvim/<path>`.
  Only the top-level `dot_config` carries a chezmoi prefix; everything
  below it is named verbatim. No `.tmpl`, no `executable_`, no
  `private_` — these are plain Lua files.
- The tree therefore mirrors the live config exactly:
  `init.lua` at the nvim root, modules under `lua/config/`, plugin specs
  later under `lua/plugins/` (epic I8 — one file per plugin; not this
  node's to create).
- **No wave-1 platform gate needs editing.** `nvim` is already in
  `tests/managed-config.sh`'s declared `SURFACE`, and its census is
  one-directional (no undeclared entry, never all-declared-present), so
  the new directory passes `--surface` as-is. `tests/deploy-skeleton.sh`
  proves the managed tree deploys byte-identical; these files ride that
  path the way `pass.nu` and `claude.nu` did. Touch neither script.

## Exact files

- **create** `home/dot_config/nvim/init.lua`, in this order:
  1. A header comment naming the load-order invariant (epic I1:
     `options` → `keymaps` → `autocmds` → `lazy`; leader before any
     plugin spec) **and the seam**: this file starts with only the
     `config.options` require, because the other three modules do not
     exist yet and a `require` of a missing module aborts startup.
     `04-plugin-manager` (E.2, wave 2) appends `require("config.lazy")`
     LAST; `02-keymaps` (E.3, wave 3) and `03-autocmds` (E.4, wave 3)
     insert their requires ABOVE it, in I1's order. Say in the comment
     that E.2 lands before E.3/E.4, so its line goes to the end of the
     file and the wave-3 nodes insert, not append. Without this comment
     the wave-2 implementer has no warning that requiring all four (its
     own R1's wording) breaks a config that has two of them.
  2. `require("config.options")`.
  3. `vim.filetype.add({ extension = { jd = "markdown" } })` (R12 — the
     PRD places it in `init.lua`, matching live).
- **create** `home/dot_config/nvim/lua/config/options.lua` — the live
  `~/.config/nvim/lua/config/options.lua` (53 lines) carried whole:
  leader first (R1), then the option groups R2–R10 exactly as the PRD
  enumerates them, then `vim.lsp.log.set_level(vim.log.levels.OFF)`
  (R11). Three comments are load-bearing and must survive the port with
  their reasons:
  1. Leader: "must be set before lazy/plugins load" (R1, epic I1).
  2. `scrolloff = 999` — **correct the live comment** ("keep the cursor
     line vertically centered") to the M-1 wording: `scrolloff` is a
     minimum distance from the window edge, so the line is centered
     everywhere except the first and last half-screen, where the cursor
     necessarily walks to the edge. The uncorrected comment is the
     overclaim M-1 was filed against; porting it verbatim re-plants it.
  3. `listchars` — the VS Code `renderWhitespace=boundary` parity
     comment: `multispace` (not `space`) is why dots appear only on runs
     of 2+ spaces. A later reader who "simplifies" `multispace` to
     `space` reverses the verdict the rating was based on.
  4. The kill-switch: nvim mirrors every LSP stderr line into
     `~/.local/state/nvim/lsp.log` with no rotation; rust-analyzer once
     grew it to 17 GB. This is the constraint the PRD says lives here —
     one line, prevents a disk-filling failure.

  Value changes from live: **none.** Every option and every value in
  R1–R11 matches the live file already (verified line by line
  2026-08-22, including `cmdheight=1`, recorded by R2 as bookkeeping).

## Hands off

- `hlsearch = false` stays, and no `<Esc>` → `nohlsearch` map is added
  anywhere — R6 carries the L-6 decision, and the map half belongs to
  `02-keymaps` R1 as a *negative* requirement. Nothing in this node's
  files may bind a key: options only.
- No entry in `home/dot_config/nushell/help/nvim.nuon` carries
  `source: prds/03-editor/01-options/prd.md` (checked 2026-08-22), so
  this spec adds no manual entry and invalidates no review digest.
  Options bind no keys and add no commands; `help --check` has nothing
  to see here.

## Acceptance

- [x] Both files exist at the exact paths above; nothing else is created
      under `home/dot_config/nvim/`. 2026-08-22: gate tree check `PASS
      tree: home/dot_config/nvim/ holds exactly init.lua +
      lua/config/options.lua`.
- [x] `require("config.options")` is the first (and currently only)
      require in `init.lua`, above the `vim.filetype.add` block.
      2026-08-22: gate tree check, comment lines stripped first (the seam
      comment names the later requires as prose).
- [x] `/usr/bin/grep -cE 'vim\.keymap\.set|nvim_create_autocmd|require\("lazy"' home/dot_config/nvim/lua/config/options.lua`
      is 0 — options only; keymaps are E.3, autocmds E.4, the plugin
      manager E.2. 2026-08-22: ran verbatim, printed `0`.
- [x] The scrolloff comment states the edge exemption; the kill-switch
      comment states the no-rotation/17 GB reason; the listchars comment
      states the multispace-not-space reason. 2026-08-22: three keyword
      chks in the gate's `--tree` stage, all PASS.
- [x] `bash tests/nvim-options.sh` (spec02) exits 0 — it holds every
      behavioral box: the twelve requirement checks, the mid-file
      centering with the `gg` exemption, the two-session undo
      persistence, the zero-growth log proof. 2026-08-22: exit 0, no
      FAIL line, in `--all`, `--tree` and `--headless` modes.
- [ ] `bash tests/managed-config.sh` and `bash tests/deploy-skeleton.sh`
      still exit 0, unedited.
  - 2026-08-22, neither script edited: deploy-skeleton exits 0.
    managed-config exits 1 on a cause OUTSIDE this node:
    `home/dot_config/television/cable/theme.toml.tmpl` (another lane's
    untracked work-in-flight) trips its one-template and
    no-template-under-dot_config checks. Proven external: a scratch copy
    with `home/dot_config/nvim/` REMOVED fails identically. The
    nvim-relevant checks (surface census) pass. Re-run when the
    television lane lands.

## Verify

```sh
cd /Users/feb/dev/dotfiles
bash tests/nvim-options.sh          # spec02's gate; covers the behavior
bash tests/managed-config.sh        # surface census admits nvim/, unedited
bash tests/deploy-skeleton.sh
/usr/bin/grep -n 'require' home/dot_config/nvim/init.lua
```
