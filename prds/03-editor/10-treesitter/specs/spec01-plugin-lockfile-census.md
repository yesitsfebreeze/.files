---
est: 1h
footprint:
  - home/dot_config/nvim/lua/plugins/treesitter.lua
  - home/dot_config/nvim/lazy-lock.json
  - tests/nvim-options.sh
---

# spec01 — treesitter.lua, its lockfile row, and keeping E.1 offline

Port `~/.config/nvim/lua/plugins/treesitter.lua` into the repo, grow
`lazy-lock.json` by `nvim-treesitter` from a real network run, and stop the
E.1 gate from acquiring a 16-download network dependency the moment that
lockfile row lands. Covers PRD R1–R4.

Every fact below was measured on 2026-08-23 against nvim 0.12.4 and the live
`nvim-treesitter` clone (`main`, `c9f9ed6c`), in scratch XDG roots. Nothing
here is read off the upstream README.

## The plugin file

**`lua/plugins/treesitter.lua`** — the live file is 42 lines and already
satisfies R1–R4 except for the augroup. Three deviations from a straight
transcription, each named:

1. **2-space indent**, the repo's house style (`completion.lua`, `lsp.lua`).
2. **The `FileType` autocmd gets a cleared augroup** — epic I7 names
   `lua/plugins/treesitter.lua:31` as one of the three live sites that break
   it. Live bug L-8; do not reproduce it.
3. **A header comment carrying the cold-install contract**, because it is
   the expensive knowledge here and nothing else in the tree records it.

Write exactly this:

```lua
-- Treesitter: syntax-tree highlighting and indentation on nvim-treesitter's
-- `main` branch — the new API (setup + install), no `ensure_installed`
-- module config. Neovim 0.12 already compiles seven parsers into the binary
-- (c, lua, markdown, markdown_inline, query, vim, vimdoc) and starts
-- treesitter itself from its own ftplugins for lua, markdown, help and
-- query, so this file's real subject is the OTHER nine languages plus the
-- indentexpr everywhere.
--
-- COLD-INSTALL CONTRACT, and it is the load-bearing constraint here.
-- `install()` compiles each missing parser from source: it needs `curl`
-- (a tarball per language from GitHub) AND the `tree-sitter` CLI, which
-- upstream shells out to for `tree-sitter build`. With either missing the
-- run STILL EXITS 0 — every failure is one `:messages` line, nothing marks
-- the config broken, and the nine non-builtin languages simply have no
-- highlighting. Measured 2026-08-23: with PATH stripped to /usr/bin:/bin,
-- `Error during "tree-sitter build": ENOENT ... 'tree-sitter'` per language
-- and an empty parser dir. `tree-sitter` is NOT in the required package set
-- (05-platform/02 R7), so a freshly provisioned machine lands in exactly
-- that state.
--
-- `install()` is idempotent and offline-safe once warm: it short-circuits on
-- `get_installed()` and makes zero network calls (measured). It is safe to
-- call on every launch, which is why it lives here rather than behind a
-- command.
--
-- HALF-INSTALLED IS A WEDGE. `get_installed()` unions the parser directory
-- with the QUERIES directory under `stdpath("data")/site`, so a language
-- whose queries symlink survived but whose `.so` is gone reads as installed,
-- `install()` skips it forever, and no relaunch heals it (measured: all 16
-- reported installed, 0 downloads, nothing highlighted). Diagnose with
-- `:checkhealth nvim-treesitter`; fix by deleting the stale
-- `site/queries/<lang>` link as well as the parser.
--
-- `build = ":TSUpdate"` keeps ALREADY-INSTALLED parsers in step with the
-- plugin's revision table; it is not what installs them. `:TSUpdate`
-- resolves its language list through `norm_languages("all", { missing =
-- true })`, which is `get_installed()` — empty on a cold machine, so the
-- build step is a no-op there (measured warm: all 16 in subject; the
-- installer is `install()` below).
return {
  "nvim-treesitter/nvim-treesitter",
  branch = "main",
  build = ":TSUpdate",
  event = { "BufReadPost", "BufNewFile" },
  config = function()
    require("nvim-treesitter").setup({})
    require("nvim-treesitter").install({
      "odin",
      "bash",
      "c",
      "lua",
      "luadoc",
      "markdown",
      "markdown_inline",
      "nu",
      "python",
      "query",
      "rust",
      "toml",
      "vim",
      "vimdoc",
      "yaml",
      "json",
    })
    -- pcall is live, not defensive decoration: `vim.treesitter.start` calls
    -- assert() and a filetype with no parser throws `Parser could not be
    -- created for buffer N and language "go"` out of the FileType autocmd.
    -- Measured both ways 2026-08-23 — without the pcall, opening a .go file
    -- prints a Lua traceback.
    local function attach(buf)
      if pcall(vim.treesitter.start, buf) then
        vim.bo[buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
      end
    end
    -- I7: cleared augroup, or a second run of this config registers a second
    -- copy of the callback (measured: FileType count 4 -> 5 ungrouped, 4 -> 4
    -- grouped). Live bug L-8.
    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("treesitter_attach", { clear = true }),
      callback = function(ev)
        attach(ev.buf)
      end,
    })
    -- Buffers that were ALREADY filetyped before this plugin loaded get no
    -- further FileType event, so the autocmd alone never reaches them. Note
    -- what this loop is NOT for: on `nvim x.nu` the triggering buffer's
    -- filetype is still EMPTY when this config runs — FileType fires after
    -- BufReadPost, and the autocmd above is what attaches it (measured
    -- 2026-08-23: `loop:1:ft=` then `au:1:ft=nu`). Deleting the loop leaves
    -- `nvim x.nu` fully highlighted and costs a pre-typed sibling buffer its
    -- indentexpr (measured: ours vs `GetLuaIndent()`).
    for _, buf in ipairs(vim.api.nvim_list_bufs()) do
      if vim.api.nvim_buf_is_loaded(buf) then
        attach(buf)
      end
    end
  end,
}
```

No `vim.keymap.set` (I5 — this node binds nothing), one repo string (I8).

## `lazy-lock.json` — grown from a real run, never by hand

E.2's policy. Stage `home/dot_config/nvim/` into a fresh scratch XDG root,
no seed, and launch with a real PATH that includes `tree-sitter` — on this
machine `/opt/homebrew/bin` — and real network. **Budget minutes, not
seconds:** the launch clones the plugins and then compiles sixteen parsers
from source. Open a file so the plugin actually loads (`event` is
`BufReadPost`/`BufNewFile`; a bare launch leaves it unloaded, measured).

Then **merge, do not copy**: take only the `nvim-treesitter` row from the
scratch lockfile into the repo file and leave every existing row
byte-identical. Lazy rewrites all rows on install, so a wholesale copy would
silently move E.2's `lazy.nvim` pin and E.6's / E.9's rows as a side effect.
Expect `{ "branch": "main", "commit": "<40 hex>" }`.

**Read the repo lockfile immediately before writing it.**
[`09-lsp`](../../09-lsp/prd.md) is claimed on the same file and its rows
(`mason.nvim`, `mason-lspconfig.nvim`, `nvim-lspconfig`) may or may not be
present when this lands — merge into whatever is there, never onto a
remembered key set.

## `tests/nvim-options.sh` — two edits, in the same change

This is a regression on landing, not tidying. Both edits are on E.1's gate;
read the file first, because [`09-lsp`](../../09-lsp/prd.md) is writing it
too.

**1. The `--tree` census.** Line ~201 asserts the exact staged file list.
Read the current string and **insert** `./lua/plugins/treesitter.lua` at its
`LC_ALL=C` position — after `./lua/plugins/lsp.lua`, and after
`./lua/plugins/telescope.lua` if E.10 landed first. Do not transcribe a
remembered list; that is how the node landing second drops the first one's
row.

**2. `seed_lazy` must seed the parser store too.** Measured 2026-08-23: E.1's
`--headless` stage opens real files (the undofile probes at ~314/317 and the
`+200` cursor probes at ~290/340), so once `nvim-treesitter` is a lockfile
key its clone gets seeded, the plugin loads on `BufReadPost`, and
`install()` fires **sixteen `curl` calls to GitHub per launch** — a per-run
network dependency and a `tree-sitter build` storm, in a gate that has no
network shim and no watchdog. Extend `seed_lazy` so each root is warm:

```sh
# nvim-treesitter's install() short-circuits on get_installed(), which reads
# $XDG_DATA_HOME/nvim/site. Seed it or every launch that opens a file
# downloads and compiles 16 parsers (measured 2026-08-23).
seed_parsers() {   # seed_parsers <root>
  local root="$1" src="$HOME/.local/share/nvim/site" l
  mkdir -p "$root/data/nvim/site/parser" "$root/data/nvim/site/queries"
  for l in odin bash c lua luadoc markdown markdown_inline nu python \
           query rust toml vim vimdoc yaml json; do
    if [ ! -f "$src/parser/$l.so" ]; then
      echo "PROBE-ERROR: $src/parser/$l.so is absent — ASSUMPTION MISSING, the seed source is the live parser store" >&2
      exit 127
    fi
    cp "$src/parser/$l.so" "$root/data/nvim/site/parser/$l.so"
    # The LIVE queries entries are absolute symlinks into the live clone, so
    # copying them would point the scratch root outside itself. Re-link into
    # the SEEDED clone instead.
    ln -s "$root/data/nvim/lazy/nvim-treesitter/runtime/queries/$l" \
          "$root/data/nvim/site/queries/$l"
  done
}
```

Call it from `seed_lazy` (after the clone loop) so every existing caller —
the main root and each `cf_stage` copy — is covered, and only when
`nvim-treesitter` is among `LOCK_KEYS`. The vacuity-control root stays
unseeded: its `init.lua` is empty and never reaches lazy.

Leave `tests/nvim-completion.sh` and `tests/nvim-plugin-manager.sh` alone.
Measured: neither opens a file in any hermetic stage (E.6's probes work on
empty buffers and `setfiletype`, so no `BufReadPost` ever fires and the
plugin never loads), and `--network`'s `Lazy! sync` runs `:TSUpdate` against
an empty parser store, which resolves to zero languages.

## Acceptance

- [x] `lua/plugins/treesitter.lua` exists, is the text above, and
      `/usr/bin/grep -c nvim_create_augroup` returns 1.
      Ran: `/usr/bin/grep -c nvim_create_augroup
      home/dot_config/nvim/lua/plugins/treesitter.lua` -> `1`. The two
      comment-strip measurements hold on the landed text:
      `ensure_installed` is 1 hit with comments and 0 stripped; `curl` is
      1 hit with comments and 0 stripped.
- [x] `bash tests/nvim-options.sh` exits 0 on the post-E.8 tree: census
      grown by exactly one entry at the right position, seed warm.
      `exit=0`, 74 PASS, 0 FAIL. The census line reads
      `PASS  tree: home/dot_config/nvim/ holds exactly the post-E.5 census
      — colorscheme.lua included (got: ./init.lua ./lazy-lock.json
      ./lua/config/lazy.lua ./lua/config/options.lua
      ./lua/plugins/colorscheme.lua ./lua/plugins/completion.lua
      ./lua/plugins/init.lua ./lua/plugins/lsp.lua
      ./lua/plugins/telescope.lua ./lua/plugins/treesitter.lua)`. The
      position was read off disk with `find . -type f | LC_ALL=C sort`, not
      transcribed.
- [x] E.1's `--headless` stage makes no parser download.
      Ran `bash tests/nvim-options.sh --headless` with a refusing `curl`
      first on PATH: exit 0, 67 PASS, 0 FAIL, and the shim log holds 4
      lines, all `api.mason-registry.dev` — `/usr/bin/grep -c tree-sitter`
      returns 0.
      **Induced red once**, on a copy of the tree with the `seed_parsers`
      call site removed: the same run logged 68 curl lines, 64 of them
      `tree-sitter` tarballs (16 per file-opening launch, four launches):
      `https://github.com/nushell/tree-sitter-nu/archive/9467420d...gz`
      and fifteen siblings.
- [x] `home/dot_config/nvim/lazy-lock.json` parses, carries
      `nvim-treesitter` with `branch: main` and a 40-hex `commit`, and every
      pre-existing row is byte-identical.
      `python3` reads back `branch` = `main` and `commit` =
      `8b98b4470eb326f1c7b50dae79f8c963568e5720`.
      `diff` against the pre-landing file is exactly one added line:
      `7a8 > "nvim-treesitter": { "branch": "main", "commit": "8b98b44..." },`.
      The row came from a real network run in a scratch XDG root, which also
      moved `lazy.nvim` to `85c7ff37` — that move was **not** taken, which
      is what the row-wise merge is for.
- [x] `bash tests/nvim-completion.sh` and `bash
      tests/nvim-plugin-manager.sh --tree --headless` still exit 0.
      completion: exit 0, 74 PASS, 0 FAIL. plugin-manager `--tree`: exit 0,
      16 PASS. plugin-manager `--headless`: exit 0, 31 PASS, 0 FAIL.
- [x] `bash tests/nvim-treesitter.sh` (spec02) exits 0 against the landed
      file. exit 0, 108 PASS, 0 FAIL.

## Verify

```sh
bash tests/nvim-options.sh
bash tests/nvim-treesitter.sh
bash tests/nvim-completion.sh
bash tests/nvim-plugin-manager.sh --tree
bash tests/nvim-plugin-manager.sh --headless
python3 -c 'import json; d=json.load(open("home/dot_config/nvim/lazy-lock.json")); print(sorted(d)); print(d["nvim-treesitter"])'
```
