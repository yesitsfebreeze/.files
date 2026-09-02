---
complexity: 15
footprint:
  - home/dot_config/nvim/lua/plugins/statusline.lua
  - home/dot_config/nvim/lua/plugins/claude.lua
  - home/dot_config/nvim/lua/plugins/lsp.lua
  - home/dot_config/nvim/lua/config/options.lua
  - home/dot_config/nvim/lua/config/shift-select.lua
  - home/dot_config/television/config.toml
  - home/dot_config/television/cable/files.toml
  - home/dot_config/television/cable/text.toml
  - home/dot_config/television/cable/recent-files.toml
  - home/dot_config/television/cable/theme.toml
  - home/dot_config/television/executable_theme-preview.sh
  - .pearde/prds/00-delivery/decisions/shift-select-scope/prd.md
---

# spec01-channels-and-lua — R1-R6, R8-R9, built and headless-verified

R1-R6, R8, R9 are implemented in the working tree, built by the prior
analyst pass and re-confirmed intact by this one (not rebuilt — the source
files were read back and match this spec's citations byte for byte).

**Channels (R1, R2, R8).** `git-files.toml`, `git-branch.toml`,
`zoxide.toml`, `alias.toml`, `env.toml` and
`nvim/lua/plugins/init.lua` are deleted from the tree; `cable/` holds 10
files. `files.toml`/`text.toml`/`recent-files.toml`'s edit action is one
`${EDITOR:-nvim} '...'` string; `recent-files.toml`'s source is
`fd -t f --changed-within 7d`; `theme.toml.tmpl` is `theme.toml` with a
bare `~` (proven by `manual.toml:32`'s own precedent, not just asserted);
`config.toml` carries no `border_type = "rounded"` line (the default it
restated). `git-log.toml` is untouched — it has no `[actions.edit]` to
unify, confirmed by direct read (see the report's Findings, this spec does
not repeat the reasoning). `theme-preview.sh` is 91 lines: the header line,
OSC 11 retint and swatch grid stayed, the banner box, the fake code card
and the bash-3.2 `eval`-array indirection are gone (re-tested on
`/bin/bash 3.2.57` against a base16 and a base24 scheme, both exit 0).

**Lua (R3-R6).** `statusline.lua` is 20 lines: `theme = "tinted"` (reads
tinted-nvim's own `lualine/themes/tinted.lua`, group-name based — no
`ColorScheme` autocmd needed) with `filename path = 1` kept; the hand-built
theme table and the old re-setup autocmd are gone. `claude.lua` is 71
lines: no profile resolver (`cll` already does the same lookup),
no `provider = "auto"`, and the `keys`/`ft` table lists only the two
explorers actually installed (`oil`, `snacks_picker_list`). `lsp.lua` has
no `LspAttach` block binding `gd`/`gI`/`<leader>rn`/`<leader>ca` — the
Neovim 0.11 built-ins (`grn`, `gra`, `gri`, `grr`, `gO`) cover them and
`nvim.nuon` documents them as built-ins, not this config's bindings.
`options.lua` carries no `incsearch`, `backup`, `cmdheight`,
`termguicolors`, `completeopt` or `mouse` line — each is the Neovim
default or (`completeopt`) unread by blink.cmp's own completion source.
`shift-select.lua` is 8 lines: `vim.o.keymodel = "startsel,stopsel"` plus
the `<C-c>`/`<C-v>` clipboard maps.
`decisions/shift-select-scope/prd.md` carries a dated
`## Re-take, 2026-09-02` paragraph naming exactly what the built-in
reproduces (arrow-key collapse, the insert-mode quirk) and what it does not
(no collapse on `hjkl`; a new `v`-then-arrow collapse regression the port
did not have) — measured inside a real pty (tmux), because `nvim --headless
-u NONE` under-reports both `termguicolors` and `keymodel`.

**R9.** `just manual` was run after the `nvim.nuon` edits that came with
R6; `guide/code.md`, `guide/editing.md` and `reference/edit.md` are the
only pages that changed, matching the `.nuon` edits exactly.

Two boxes from the PRD's own Acceptance section do not reproduce as
literally written and are not this spec's to fix — see the report's
Findings: `git-log.toml`'s edit action (R2 names it, it has none) and the
`tv list-channels ≤ 15` line (`tv` 0.15.9 bakes in 10 channel names before
the cable directory is even read, so 16 is the floor for this footprint,
not 15 — the `ls cable ≤ 15` half of that box does hold, at 10).

## Acceptance

- [x] `ls home/dot_config/television/cable | wc -l` prints at most 15 —
      `10`
- [x] `rg -l "border_type = .rounded." home/dot_config/television/config.toml`
      finds nothing
- [x] `rg -c "EDITOR:-nvim" home/dot_config/television/cable/files.toml
      home/dot_config/television/cable/text.toml
      home/dot_config/television/cable/recent-files.toml` prints `1` for
      each
- [x] `wc -l home/dot_config/nvim/lua/config/shift-select.lua
      home/dot_config/nvim/lua/plugins/statusline.lua
      home/dot_config/nvim/lua/plugins/claude.lua` prints at most 12, 20,
      75 — `8 20 71`
- [x] `rg -l "provider = .auto.|LspAttach|termguicolors|completeopt"
      home/dot_config/nvim/lua/plugins/claude.lua
      home/dot_config/nvim/lua/plugins/lsp.lua
      home/dot_config/nvim/lua/config/options.lua` finds nothing
- [x] `nvim --headless "+Lazy! sync" +qa` and `nvim --headless +qa` both
      exit 0
- [x] `rg -q "Re-take, 2026-09-02"
      .pearde/prds/00-delivery/decisions/shift-select-scope/prd.md`
      succeeds

## Verify and Proof

```sh
set -eu
cd /Users/feb/dev/dotfiles
fail() { echo "FAIL: $*"; exit 1; }

test "$(ls home/dot_config/television/cable | wc -l | tr -d ' ')" -le 15 \
    || fail "cable directory has more than 15 files"

if rg -q 'border_type = "rounded"' home/dot_config/television/config.toml
then fail "config.toml still restates the border_type default"; fi

for f in files.toml text.toml recent-files.toml; do
    test "$(rg -c 'EDITOR:-nvim' home/dot_config/television/cable/$f)" = "1" \
        || fail "$f's edit action is not one \${EDITOR:-nvim} string"
done

test -f home/dot_config/television/cable/theme.toml || fail "theme.toml.tmpl was not renamed"
test ! -f home/dot_config/television/cable/theme.toml.tmpl || fail "theme.toml.tmpl still present"

for pair in "shift-select.lua:12" "statusline.lua:20" "claude.lua:75"; do
    f="${pair%%:*}"; max="${pair##*:}"
    luafile=$(find home/dot_config/nvim/lua -name "$f")
    n=$(wc -l < "$luafile" | tr -d ' ')
    test "$n" -le "$max" || fail "$f is $n lines, over $max"
done

if rg -l 'provider = "auto"|LspAttach' home/dot_config/nvim/lua/plugins/claude.lua home/dot_config/nvim/lua/plugins/lsp.lua | grep -q .
then fail "a deleted symbol survives in claude.lua/lsp.lua"; fi
if rg -q 'termguicolors|completeopt|incsearch|cmdheight' home/dot_config/nvim/lua/config/options.lua
then fail "options.lua still sets a default/ignored option"; fi

nvim --headless "+Lazy! sync" +qa
nvim --headless +qa

rg -q "Re-take, 2026-09-02" .pearde/prds/00-delivery/decisions/shift-select-scope/prd.md \
    || fail "the re-take paragraph is missing from decisions/shift-select-scope"

echo "spec01-channels-and-lua OK"
```
