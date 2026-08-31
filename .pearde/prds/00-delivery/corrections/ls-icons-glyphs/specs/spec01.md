---
spec: 01
node: 00-delivery/corrections/ls-icons-glyphs
covers: R1
complexity: 35
footprint:
  - home/dot_config/nushell/config.nu
verify: "python3 <the script below> home/dot_config/nushell/config.nu $HOME/.local/share/nvim/lazy/nvim-web-devicons/lua --check && bash tests/shell-listing.sh && bash tests/nushell-core.sh"
---

# spec01 — machine-copy real glyphs into `LS_ICONS`

Delivers R1: `LS_ICONS`'s ~80 extension→glyph values, currently all `""`,
become real Nerd Font codepoints — copied by a script from this repo's own
pinned `nvim-web-devicons` dependency, never retyped by a human or an agent.
The user's answer to Q1 named this source explicitly, specifically to avoid
repeating how the map went empty in the first place: private-use codepoints
corrupt silently under manual retyping, and did, somewhere in this file's
history, with no parse error and no diff anyone caught.

## Why a script, and why this source

`~/.local/share/nvim/lazy/nvim-web-devicons/lua/nvim-web-devicons/default/
icons_by_file_extension.lua` is a plain Lua table, `{ icon = "…", color =
"…", ... }` per extension, vendored on this machine and pinned at commit
`2ae6958df7ced50baac5035cec0c15799eedfbf7` in
`home/dot_config/nvim/lazy-lock.json` (the `"nvim-web-devicons"` key — this
repo already depends on it for the same purpose elsewhere: `explorer.lua`
and `statusline.lua` both load it to paint file-type glyphs). Measured
2026-08-25: **81 of the 82 keys already in `LS_ICONS`** have a direct
extension match in that table. The one that doesn't, `tar`, is genuinely
absent — not a parsing miss (checked `icons_by_filename.lua` too, and
`filetypes.lua`; no `tar` anywhere) — and falls back to the same generic
glyph any wholly-unmapped extension gets (R1's "generic fallback";
`LS_ICON_DEFAULT` below).

**Directories are the other half of R1's "dir … fallback" language, and they
stay unmarked, on purpose.** Neither `nvim-web-devicons` (extension/filename/
OS/desktop-environment/window-manager tables only — no directory concept)
nor `oil.nvim`, the explorer this repo actually uses, vendors a directory
glyph: `oil.nvim/lua/oil/util.lua`'s `get_icon_provider()` returns `conf and
conf.directory or ""` for `type == "directory"` when falling back to
devicons — no built-in folder glyph, just an empty default. Checked both
vendored plugins on this machine, 2026-08-25; neither has one. Hand-picking
a folder codepoint from somewhere else would be exactly the retyping risk
this correction exists to remove, for a part of R1's own language that
turns out to have no sourceable answer. So `decorate-ls`'s `if $row.type ==
"dir" { "" }` branch is UNCHANGED by this spec — still literal `""` — and
the comment landing in config.nu says why, so the next reader does not
mistake it for the empty-map bug recurring.

## The script

Run exactly this, unmodified, with `python3`. It is the entire mechanism —
no glyph byte in this spec file, no glyph byte typed by hand anywhere in
this change. It reads the vendored Lua table and writes `config.nu`
directly; the bytes never pass through a human, an editor buffer typed by
hand, or a markdown file.

```python
#!/usr/bin/env python3
"""Regenerate LS_ICONS glyph values in config.nu from nvim-web-devicons's
vendored extension table, byte-for-byte, with zero hand-typed glyphs.

Usage:
    python3 gen_ls_icons.py <config.nu path> <devicons plugin lua dir> --write
    python3 gen_ls_icons.py <config.nu path> <devicons plugin lua dir> --check
"""
import re
import sys


def load_ext_table(devicons_lua_dir):
    path = f"{devicons_lua_dir}/nvim-web-devicons/default/icons_by_file_extension.lua"
    src = open(path, encoding="utf-8").read()
    pairs = dict(re.findall(r'\["([^"]+)"\]\s*=\s*\{\s*icon\s*=\s*"([^"]*)"', src))
    if len(pairs) < 400:  # sanity floor; the real table has ~490 entries
        raise SystemExit(f"parsed suspiciously few entries ({len(pairs)}) from {path}")
    return pairs


def load_default_icon(devicons_lua_dir):
    path = f"{devicons_lua_dir}/nvim-web-devicons.lua"
    src = open(path, encoding="utf-8").read()
    m = re.search(r'local default_icon = \{\s*icon = "([^"]*)"', src)
    if not m:
        raise SystemExit(f"could not find default_icon in {path}")
    return m.group(1)


def load_config_keys(config_nu):
    src = open(config_nu, encoding="utf-8").read()
    m = re.search(r'const LS_ICONS = \{(.*?)\n\}', src, re.S)
    if not m:
        raise SystemExit("could not find const LS_ICONS block in config.nu")
    body = m.group(1)
    keys = re.findall(r'(?:"([\w]+)"|(\b[a-zA-Z_][\w]*))\s*:\s*""', body)
    keys = [a or b for a, b in keys]
    return src, keys


def build_glyph_map(keys, ext_table, default_glyph):
    glyphs, unmatched = {}, []
    for k in keys:
        if k in ext_table:
            glyphs[k] = ext_table[k]
        else:
            glyphs[k] = default_glyph
            unmatched.append(k)
    return glyphs, unmatched


def patch_config(src, glyphs, default_glyph):
    def repl_block(m):
        body = m.group(1)
        def repl_kv(km):
            key = km.group(1) or km.group(2)
            quoted_key = km.group(0).split(":")[0]
            return f'{quoted_key}: "{glyphs[key]}"'
        new_body = re.sub(r'(?:"([\w]+)"|(\b[a-zA-Z_][\w]*))\s*:\s*""', repl_kv, body)
        return f"const LS_ICONS = {{{new_body}\n}}"

    new_src = re.sub(r'const LS_ICONS = \{(.*?)\n\}', repl_block, src, count=1, flags=re.S)
    if 'const LS_ICON_DEFAULT' not in new_src:
        new_src = new_src.replace(
            "\nalias core-ls = ls",
            f'\nconst LS_ICON_DEFAULT = "{default_glyph}"\n\nalias core-ls = ls',
            1,
        )
    new_src = new_src.replace(
        '| get --optional ($row.name | path parse | get extension | str lowercase)\n            | default ""',
        '| get --optional ($row.name | path parse | get extension | str lowercase)\n            | default $LS_ICON_DEFAULT',
    )
    return new_src


def verify(config_nu, devicons_lua_dir):
    ext_table = load_ext_table(devicons_lua_dir)
    default_glyph = load_default_icon(devicons_lua_dir)
    src = open(config_nu, encoding="utf-8").read()
    m = re.search(r'const LS_ICONS = \{(.*?)\n\}', src, re.S)
    body = m.group(1)
    kv = re.findall(r'(?:"([\w]+)"|(\b[a-zA-Z_][\w]*))\s*:\s*"([^"]*)"', body)
    ok = True
    for a, b, glyph in kv:
        key = a or b
        expected = ext_table.get(key, default_glyph)
        if glyph != expected:
            ok = False
            print(f"MISMATCH {key}: config={glyph!r} expected={expected!r}")
    dm = re.search(r'const LS_ICON_DEFAULT = "([^"]*)"', src)
    if not dm or dm.group(1) != default_glyph:
        ok = False
        print(f"MISMATCH LS_ICON_DEFAULT: config={dm.group(1) if dm else None!r} expected={default_glyph!r}")
    print("VERIFY", "PASS" if ok else "FAIL", f"({len(kv)} keys checked)")
    return 0 if ok else 1


if __name__ == "__main__":
    config_nu, devicons_dir = sys.argv[1], sys.argv[2]
    mode = sys.argv[3] if len(sys.argv) > 3 else "--check"
    if mode == "--write":
        ext_table = load_ext_table(devicons_dir)
        default_glyph = load_default_icon(devicons_dir)
        src, keys = load_config_keys(config_nu)
        glyphs, unmatched = build_glyph_map(keys, ext_table, default_glyph)
        print(f"{len(keys)} keys, {len(unmatched)} fell back to the generic glyph: {unmatched}")
        new_src = patch_config(src, glyphs, default_glyph)
        open(config_nu, "w", encoding="utf-8").write(new_src)
        print("wrote", config_nu)
    else:
        sys.exit(verify(config_nu, devicons_dir))
```

Run:

```sh
D="$HOME/.local/share/nvim/lazy/nvim-web-devicons/lua"
[ -d "$D" ] || { echo "PROBE-ERROR: $D is absent — ASSUMPTION MISSING, the seed source is the live nvim-web-devicons clone"; exit 127; }
python3 gen_ls_icons.py home/dot_config/nushell/config.nu "$D" --write
```

Expect the tool to print `82 keys, 1 fell back to the generic glyph: ['tar']`
— confirmed by the analyst on this exact tree, 2026-08-25. A different count
or a different unmatched list means either `LS_ICONS`'s key set drifted
since this spec was written (stop, this spec no longer applies unmodified)
or the vendored plugin was updated past the pinned commit (stop, re-check
`lazy-lock.json` before proceeding).

## The independent cross-check

The regex parse above is one reader. Before trusting its output, run a
second, differently-implemented reader — a real Neovim loading the actual
Lua module through `require`, not a text scan — and diff the two. Both must
agree on every one of the 82 keys plus the default glyph; disagreement means
the regex missed an escape or edge case the interpreter didn't.

```sh
cat > /tmp/dump_devicons.lua <<'LUA'
package.path = "$HOME/.local/share/nvim/lazy/nvim-web-devicons/lua/?.lua;" .. package.path
local ext = require("nvim-web-devicons.default.icons_by_file_extension")
local devicons = require("nvim-web-devicons")
local out = {}
for k, v in pairs(ext) do out[#out + 1] = k .. "\t" .. v.icon end
table.sort(out)
out[#out + 1] = "\t__default__\t" .. devicons.get_default_icon().icon
local f = io.open("/tmp/devicons_dump.tsv", "w")
f:write(table.concat(out, "\n"))
f:close()
LUA
nvim --headless --noplugin -u NONE -l /tmp/dump_devicons.lua
```

Then confirm every key the regex script used for `LS_ICONS` appears in
`/tmp/devicons_dump.tsv` with the identical byte sequence (`grep -F` each
key, compare against what landed in `config.nu`). The analyst ran this exact
pair on this tree, 2026-08-25 (script text identical to what is embedded
above, run end to end, not eyeballed): the regex reader and the
headless-nvim `require` reader parsed **493 entries each** (492 extensions
plus the default icon), agreed on all 493 byte-for-byte with zero
mismatches in either direction, including `md` = `U+F48A` (`ef 92 8a`) and
the default icon = `U+F0F6` (`ef 83 b6`) for both readers; all 82 `LS_ICONS`
keys were individually re-checked against both dumps with zero diffs; and
the write-then-check round trip against a scratch copy of `config.nu`
printed `82 keys, 1 fell back to the generic glyph: ['tar']` then `VERIFY
PASS (82 keys checked)`.

## The comment (hand-edit; plain ASCII, no glyph risk)

Replace the existing comment above `const LS_ICONS = {` (the block starting
"The builtin `ls` already returns a structured table…" and ending "…
Restoring real glyphs is a correction against the live source, not
something to invent here.") with:

```
# The builtin `ls` already returns a structured table (name/type/size/
# modified); the shadow below adds an `icon` column from this extension→glyph
# map and a `sort-by type modified` — dirs grouped, newest last, freshest
# rows nearest the prompt.
#
# THE GLYPHS ARE MACHINE-COPIED FROM nvim-web-devicons, NEVER HAND-TYPED.
# Measured 2026-08-22, hexdump over every revision of the live repo's
# config.nu: the map's values were EMPTY in every version that ever existed —
# despite an earlier comment here claiming the map was carried "verbatim"
# from a live source, that source itself had nothing to carry. Corrected
# 2026-08-25 (prds/00-delivery/corrections/ls-icons-glyphs/): every value
# below was read straight out of this repo's own pinned dependency —
# nvim-web-devicons, commit 2ae6958d (home/dot_config/nvim/lazy-lock.json) —
# by a script (ls-icons-glyphs/specs/spec01.md) that copies the exact UTF-8
# bytes of each `icon` field, never retypes one, cross-checked against a
# second, independently-implemented reader (a real headless-nvim `require`
# of the same module) before this file was written. `tar` has no entry in
# that table (checked, genuinely absent) and falls back to
# `LS_ICON_DEFAULT` below, same as any extension this map has no key for.
#
# DIRECTORIES CARRY NO ICON — checked and deliberate, not the empty-map bug
# recurring. Neither nvim-web-devicons (extension/filename/OS/DE/WM tables
# only) nor oil.nvim, the explorer this repo uses
# (oil/util.lua:get_icon_provider, `conf.directory or ""`, no built-in
# folder glyph), vendors a directory glyph anywhere in this repo's
# dependency tree. Hand-picking one from elsewhere would reintroduce the
# exact retyping risk this correction removes, so the `if type == "dir"`
# branch below stays literal `""` until a vendored source for one exists.
```

## Out of scope

- Adding, removing, or renaming any `LS_ICONS` key. This spec fills the 82
  values already there.
- The `if $row.type == "dir"` branch's behavior — unchanged, see above.
- `help/shell.nuon` and `tests/shell-listing.sh` — spec02 and spec03.

## Acceptance

- [ ] `python3 gen_ls_icons.py home/dot_config/nushell/config.nu "$D" --write`
      runs clean, prints `82 keys, 1 fell back to the generic glyph:
      ['tar']`.
- [ ] The independent headless-nvim cross-check agrees with the regex
      reader on every key; quote the comparison in the report.
- [ ] `python3 gen_ls_icons.py home/dot_config/nushell/config.nu "$D" --check`
      prints `VERIFY PASS (82 keys checked)`.
- [ ] The comment above `const LS_ICONS` is replaced as specified.
- [ ] `nu -c 'source home/dot_config/nushell/config.nu'` parses with no
      `nu::parser` errors (config.nu cannot be sourced standalone outside
      the staged fixture other specs use — run it inside
      `tests/shell-listing.sh`'s own hermetic harness, not bare).
- [ ] `bash tests/shell-listing.sh` and `bash tests/nushell-core.sh` both
      exit 0 (spec03's new/changed checks land separately, but this spec
      must not regress the existing suite).
- [ ] `git diff home/dot_config/nushell/config.nu` shows changes confined to
      the `LS_ICONS` block's values, the new `LS_ICON_DEFAULT` constant, the
      `default ""` → `default $LS_ICON_DEFAULT` line, and the replaced
      comment — nothing else in the file moves.

## Verify and Proof

```sh
cd "$(git rev-parse --show-toplevel)"
D="$HOME/.local/share/nvim/lazy/nvim-web-devicons/lua"
[ -d "$D" ] || { echo "PROBE-ERROR: $D absent"; exit 127; }
python3 /path/to/gen_ls_icons.py home/dot_config/nushell/config.nu "$D" --write
python3 /path/to/gen_ls_icons.py home/dot_config/nushell/config.nu "$D" --check
git diff home/dot_config/nushell/config.nu
bash tests/shell-listing.sh
bash tests/nushell-core.sh
```
