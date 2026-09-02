---
complexity: 6
footprint:
  - home/dot_config/nushell/help.nu
  - home/dot_config/nushell/config.nu
  - home/dot_config/nvim/lua/config/lazy.lua
  - home/dot_local/bin/executable_tv-all
---

# spec01 — one `help`, no checker, no second picker

Cuts the drift checker and the two extra renderers out of the shell surface,
leaving four shapes: `help`, `help <topic>`, `help <thing>`, `help --json`,
with `?` as the one search. Covers R1's code half, R4 and R5.

**Already stands** (built and applied 2026-09-02): `help-check.nu` deleted;
`--check` and its `source` line gone; `HELP_CHECK` gone from `lazy.lua`;
`help.nu` rewritten 404 → 198 lines with `--all`, `--entry`, `--topic`,
`--delegate`, `--fuzzy`, `--md`, `--mode`, `_help_rows`, `_help_preview`,
`_help_browse`, `_help_host_only` and the eight-branch flag ladder removed,
and the five `chezmoi apply` errors collapsed to `_help_missing`.

**Left to finish**: nothing in this footprint. Two carried decisions to
uphold rather than re-take:

- `lazy.lua`'s `checker.enabled` and `install.missing` were `not checking`,
  which is **true** in normal use. Dropping the guard must leave the checker
  ENABLED and `install.missing` at its default — writing `false` would turn
  off plugin updates as a side effect of deleting a drift check.
- `--mode` goes with the ladder. R5's "what stays" list is exhaustive and its
  only readers were `manual.toml` and `_help_rows`, both deleted.
- `tv-all`'s `manual` lane was a **third** renderer of the corpus, unnamed by
  the PRD. It called `_help_rows` for its rows and `help --entry` for its
  preview and its opener, so both of its dependencies were being deleted; the
  lane, its `_key` helper and its `LANES_FAST` slot are gone. `?`/`docs` is
  the surviving search, which is what R4 asks for.

## Acceptance

- [x] `help.nu` is at most 200 lines and defines exactly **three** public names — `help`, `docs`, and `?` as an alias of `docs` — `wc -l` → **198**; every other `def` is `_help_`-prefixed. **The box as written said "exactly two" and was self-contradicting**: R4 requires `?`, and `help.nu:161` defines it, so a literal reading of the box could only have been closed by deleting the alias the same requirement demands. Corrected to three rather than ticked past.
- [x] `nu -l -c 'help --check'` fails with nushell's own unknown-flag error, not a message of ours — output matches `doesn't have flag`, which is nushell's wording, not ours.
- [x] `nu -l -c 'help'`, `nu -l -c 'help navigate'` and `nu -l -c 'help --json'` all render — all three exit 0; `help --json | from json | get entries | length` → **113**, matching the corpus count the PRD's corrected acceptance names.
- [x] no `HELP_CHECK` in the Neovim config, and `nvim --headless +qa` exits 0 — `rg -c HELP_CHECK lazy.lua` → 0, `nvim --headless +qa` → 0.
- [x] `lazy.lua` keeps `checker = { enabled = true, ... }` — confirmed at `lazy.lua:27`, and `install.missing` is absent, i.e. left at its default of true. Both are asserted in `probe/verify.sh` so a later edit cannot quietly disable plugin updates.
- [x] `tv-all` parses under `sh -n` and names no `manual` lane — `sh -n` exits 0; `_help_rows`, `help --entry` and `_key()` all absent.

## Verify and Proof

```sh
set -e
cd /Users/feb/dev/dotfiles
test "$(wc -l < home/dot_config/nushell/help.nu)" -le 200
if rg -q '_help_rows|_help_browse|_help_preview|_help_md|_help_host_only|--fuzzy|--delegate|--check' home/dot_config/nushell/help.nu; then echo "FAIL: rg -q '_help_rows|_help_browse|_help_preview|_help_md|_hel"; exit 1; fi
if rg -q 'HELP_CHECK' home/dot_config/nvim/lua/config/lazy.lua; then echo "FAIL: rg -q 'HELP_CHECK' home/dot_config/nvim/lua/config/lazy.lu"; exit 1; fi
rg -q 'checker = \{ enabled = true' home/dot_config/nvim/lua/config/lazy.lua
if rg -q 'help-check' home/dot_config/nushell/config.nu; then echo "FAIL: rg -q 'help-check' home/dot_config/nushell/config.nu"; exit 1; fi
if rg -q '_help_rows|help --entry|_key\(\)' home/dot_local/bin/executable_tv-all; then echo "FAIL: rg -q '_help_rows|help --entry|_key\(\)' home/dot_local/bi"; exit 1; fi
sh -n home/dot_local/bin/executable_tv-all
nu -l -c 'help' >/dev/null
nu -l -c 'help navigate' >/dev/null
nu -l -c 'help --json | from json | get entries | length' | grep -qE '^[0-9]+$'
help_check_out=$(nu -l -c 'help --check' 2>&1) || true
echo "$help_check_out" | rg -q "doesn't have flag"
nvim --headless +qa
echo spec01 OK
```
