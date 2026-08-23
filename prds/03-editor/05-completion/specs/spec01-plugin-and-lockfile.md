# spec01 — completion.lua, the lockfile growth, and keeping the standing gates green

Port `~/.config/nvim/lua/plugins/completion.lua` into the repo, grow
`lazy-lock.json` by `blink.cmp` and `friendly-snippets` from a real network
run, and widen the two E.2-era gates so they stay hermetic now that the
config names plugins beyond lazy.nvim. Covers PRD R1–R8. R9 is
[09-lsp](../../09-lsp/prd.md)'s wiring — add no capability code here.

**Est:** 1h

**Footprint:** `home/dot_config/nvim/lua/plugins/completion.lua`,
`home/dot_config/nvim/lazy-lock.json`, `tests/nvim-options.sh`,
`tests/nvim-plugin-manager.sh`
<!-- the first three are E.2-lane paths and both tests/ files are E.2's
     gates; E.2's lane must be closed before this dispatches -->

## The plugin file

**`lua/plugins/completion.lua`** — transcribe
`~/.config/nvim/lua/plugins/completion.lua` (read it; 29 lines) in the
repo's 2-space indent style. The live file already satisfies R1–R8 exactly:
`saghen/blink.cmp`, `event = "InsertEnter"`, `version = "1.*"`,
`dependencies = { "rafamadriz/friendly-snippets" }`, the `super-tab` preset
plus `["<CR>"] = { "accept", "fallback" }` and
`["<Esc>"] = { "cancel", "fallback" }`,
`appearance = { nerd_font_variant = "mono" }`, documentation
`auto_show = true, auto_show_delay_ms = 200`,
`sources.default = { "lsp", "snippets", "path", "buffer" }`,
`signature = { enabled = true }`,
`fuzzy = { implementation = "prefer_rust_with_warning" }`, and
`opts_extend = { "sources.default" }`. Keep all three comments — the header,
the tagged-release reason on `version` (the tag is what ships the prebuilt
Rust fuzzy library; without it a local Rust toolchain builds it), and the
super-tab note. No `vim.keymap.set`, no `nvim_create_autocmd` — the keys
live in `opts.keymap` (epic I5) and the file registers no autocmd (I7).

## The two gates — do this in the same change, it is a regression on landing

Measured 2026-08-22 on 0.12.4: with `completion.lua` present and only
lazy.nvim seeded, every staged launch tries to **install blink.cmp from the
network at startup** (`install.missing` is lazy's default). With git refused
it errors `Too many rounds of missing plugins` — **and still exits 0**, so
nothing goes loudly red: the hermetic stages silently acquire a per-run
network dependency instead. Both gates' seed helpers must widen with the
config.

Make both seed helpers **lockfile-driven** so no later plugin node edits
them again: read the key list from `home/dot_config/nvim/lazy-lock.json`
(python3, the spec02-E.2 precedent) and copy each
`~/.local/share/nvim/lazy/<name>` into `<root>/data/nvim/lazy/<name>`. Any
absent live clone is `PROBE-ERROR: … ASSUMPTION MISSING`, exit 127, never a
skip. Copy each to a **nonexistent** destination path — `cp -R` into an
existing directory nests the source inside it (measured 2026-08-22; it
produced a false "Plugin blink.cmp is not installed").

**`tests/nvim-options.sh`** — two edits:

1. `seed_lazy` becomes the lockfile-driven loop above. The vacuity-control
   root stays unseeded — its `init.lua` is empty and never reaches lazy.
2. Grow the `--tree` census to the post-E.6 list, LC_ALL=C order:
   `./init.lua ./lazy-lock.json ./lua/config/lazy.lua
   ./lua/config/options.lua ./lua/plugins/completion.lua
   ./lua/plugins/init.lua`. Exact equality stays — each editor node
   extends it.

**`tests/nvim-plugin-manager.sh`** — two edits:

1. Its seed helper becomes the same lockfile-driven loop. The
   clone-failure probe's root and the `--network` fresh root stay
   unseeded — unchanged.
2. The `--network` restore-reproducibility comparison stops hardcoding
   `lazy.nvim`: after `nvim --headless '+Lazy! restore' +qa` exits 0, loop
   over the repo lockfile's keys and assert
   `git -C <root>/data/nvim/lazy/<name> rev-parse HEAD` equals that key's
   locked commit, one `chk` per key. Rewrite the widening comment: the
   subject set is now the lockfile itself and widens automatically as
   plugin nodes land. The restore-before-sync ordering stands — sync moves
   HEAD and rewrites the scratch lockfile.

## `lazy-lock.json` (R2 of E.2's policy: grown from a real run, never by hand)

Network flow: stage `home/dot_config/nvim/` into a fresh scratch root, no
seed, launch — the bootstrap clones lazy.nvim and lazy installs blink.cmp
and friendly-snippets. Before touching the repo file, assert in the scratch
clone: `git -C <root>/data/nvim/lazy/blink.cmp describe --tags --exact-match`
prints a `v1.*` tag — the `version = "1.*"` pin observed, not read back.

Then **merge, do not copy**: keep the repo lockfile's `lazy.nvim` row
byte-identical and take only the `blink.cmp` and `friendly-snippets` rows
from the scratch lockfile (python3). Lazy rewrites every row after install,
recording the bootstrap clone's stable-HEAD commit for lazy.nvim — which
can sit past E.2's pinned commit, so a wholesale copy could silently move
E.2's pin as a side effect of this node.

## The manual entry — read-only check

`home/dot_config/nushell/help/nvim.nuon` already carries the completion
entry (`key: "<Tab> <S-Tab> <C-n> <C-p> <C-Space> <C-e>"`, `verify:
[{kind: "prose"}]`, `source: prds/03-editor/05-completion/prd.md`) and its
`use`/`why` state exactly R3's keymap and fallbacks. This node owes no help
edit. Confirm the entry still matches what landed; a mismatch is a
correction to file, never an edit — the S.5 lane holds
`home/dot_config/nushell/`.

## Acceptance

- [x] `bash tests/nvim-options.sh` exits 0 on the post-E.6 tree: census
      grown, seeds lockfile-driven. Executed 2026-08-22: exit 0, 74 PASS.
- [x] `bash tests/nvim-plugin-manager.sh --tree` and `--headless` exit 0.
      Executed 2026-08-22, both exit 0. The anchor-delete counterfactual
      widened with the config: since E.6 deleting the anchor alone no
      longer empties the import module, so the mutation now empties
      `lua/plugins/` entirely.
- [x] `bash tests/nvim-plugin-manager.sh --network` exits 0, and the
      restore loop prints three commit equalities — `lazy.nvim`,
      `blink.cmp`, `friendly-snippets` (quoted in the report). Executed
      2026-08-22. One measured addition: the install on the fresh launch
      REWRITES the scratch lockfile (lazy.nvim moved to stable HEAD), so
      the gate re-copies the repo lockfile into the staged config before
      `Lazy! restore`.
- [x] `home/dot_config/nvim/lazy-lock.json` parses (python3), holds exactly
      the keys `lazy.nvim`, `blink.cmp`, `friendly-snippets`, each `commit`
      40 hex chars, and the `lazy.nvim` row is byte-identical to the
      pre-landing repo row. Executed 2026-08-22: sorted keys quoted in the
      report; the merge reused the pre-landing row verbatim
      (`306a05526ada86a7b30af95c5cc81ffba93fef97`).
- [x] The generation root's blink clone sits on a `v1.*` tag
      (`describe --tags --exact-match` output quoted). Executed 2026-08-22:
      `v1.10.2`.
- [x] Comment-stripped `completion.lua` carries every value R1–R8 names
      (the greps land as spec02's `--tree` stage; run them inline until it
      exists). Landed as spec02's `--tree`: exit 0, all thirteen value
      checks PASS.
- [x] `assert_unchanged` green in both gates — no write to real
      `~/.config/nvim`, `~/.local/share/nvim`, `~/.local/state/nvim`,
      `~/.cache/nvim`. Executed 2026-08-22, green in every run quoted
      above.

## Verify

```sh
bash tests/nvim-options.sh                 # E.1 green post-census
bash tests/nvim-plugin-manager.sh          # all three stages, restore loop widened
python3 -c 'import json; d=json.load(open("home/dot_config/nvim/lazy-lock.json")); print(sorted(d))'
```
