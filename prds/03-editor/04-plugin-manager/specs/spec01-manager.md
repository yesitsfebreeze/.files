# spec01 — lazy.nvim bootstrap, setup opts, and the spec-import anchor

Port `~/.config/nvim/lua/config/lazy.lua` into the repo with one measured
deviation (the headless-hang guard), add the `lua/plugins/init.lua` import
anchor, and append `require("config.lazy")` to `init.lua` per E.1's seam.
Covers PRD R1–R4 and R6–R8. R5 (lockfile) lands in spec02 — it needs the
network run.

**Est:** 0.75h

**Footprint:** `home/dot_config/nvim/init.lua`,
`home/dot_config/nvim/lua/config/lazy.lua`,
`home/dot_config/nvim/lua/plugins/init.lua`

## The files

**`lua/config/lazy.lua`** — transcribe `~/.config/nvim/lua/config/lazy.lua`
(read it; 38 lines) in the repo's 2-space indent style. Keep everything:
the `fs_stat` bootstrap with `--filter=blob:none --branch=stable`, the
error echo, `os.exit(1)`, the `rtp:prepend`, and the exact `setup` table
(`spec = {{ import = "plugins" }}`, `defaults = { lazy = false, version =
false }`, `rocks = { hererocks = false }`, `install.colorscheme =
{ "base16-gruvbox-dark-hard" }`, `checker = { enabled = true, notify =
false }`, `change_detection = { notify = false }`, and the six
`performance.rtp.disabled_plugins`: gzip, tarPlugin, tohtml, tutor,
zipPlugin, netrwPlugin).

One deviation, measured 2026-08-22 on 0.12.4: the live `vim.fn.getchar()`
on the clone-failure path **blocks forever in `--headless`, even with
stdin at `/dev/null`** — any scripted launch on an offline machine hangs
instead of failing. Guard it:

```lua
if #vim.api.nvim_list_uis() > 0 then vim.fn.getchar() end
os.exit(1)
```

Interactive launch still waits for the keypress (R2's UX); headless gets
the error on stderr and exit 1. Carry this reason as a comment on the
guard — it reads as dead code without it.

**`lua/plugins/init.lua`** — exactly `return {}` plus a comment. Measured
2026-08-22: `{ import = "plugins" }` errors `No specs found for module
"plugins"` at every startup when `lua/plugins/` is **missing or empty**,
and git cannot track an empty directory — so this file is what makes the
config bootable before any plugin node lands. It is permanent: lazy
imports sibling `plugins/*.lua` files alongside it (measured: a local
`dir=` spec in `plugins/demo.lua` loads, plugin count 2). The comment
states both facts and that the file holds zero specs — it is the import
anchor, not the catch-all epic I8 forbids. E.5+ never write into it.

**`init.lua`** — append `require("config.lazy")` as the last line of the
file, after the `vim.filetype.add` block (E.1's seam: "its line goes to
the end of this file"). Rewrite the SEAM comment to the post-E.2 truth:
a require of a missing module aborts startup; 02-keymaps (E.3) and
03-autocmds (E.4, wave 3) INSERT their requires ABOVE the
`require("config.lazy")` line, in I1's order; `config.lazy` stays last.
Do not touch `require("config.options")` or the filetype block —
`tests/nvim-options.sh` checks both.

## Acceptance

All hermetic: stage `home/dot_config/nvim/` into a scratch XDG root and
seed `$root/data/nvim/lazy/lazy.nvim` by copying the live clone from
`~/.local/share/nvim/lazy/lazy.nvim` (read-only). No network.

- [x] Seeded staged launch: `nvim --headless +qa` exits 0 with **no**
      `No specs found` on stderr. 2026-08-22, gate `--headless`: exit 0,
      stderr clean.
- [x] `require("lazy.core.config").options` probe prints
      `checker.enabled=true`, `checker.notify=false`,
      `change_detection.notify=false`, `defaults.lazy=false`,
      `defaults.version=false`, `rocks.hererocks=false`,
      `install.colorscheme[1]=base16-gruvbox-dark-hard`, and
      `disabled_plugins` = exactly the six names (R4, R6, R7, R8).
      2026-08-22, inline runner output: `true false false false false
      false base16-gruvbox-dark-hard
      gzip,tarPlugin,tohtml,tutor,zipPlugin,netrwPlugin`; one `chk` per
      value in the gate, all PASS.
- [x] Clone failure, no hang: unseeded root + a `git` shim exiting 128
      first on PATH → stderr carries `Failed to clone lazy.nvim`, exit 1,
      within a 10s watchdog (R2, and the PRD's offline acceptance box).
      2026-08-22: exit 1, message on stderr; guard counterfactual (bare
      `getchar()`) TIMEOUTs the same watchdog.
- [x] `init.lua` comment-stripped require order is `config.options` then
      `config.lazy`, with `config.lazy` last (R1's E.2 slice; the full
      four-require order closes at E.4). 2026-08-22, gate `--tree` PASS.
- [x] Comment-stripped `lua/plugins/init.lua` is exactly `return {}`.
      2026-08-22, gate `--tree` PASS; spec-in-anchor selftest goes red.

## Verify

```sh
# spec02's gate encodes all of the above; until it exists, run the probes
# inline with this runner shape:
S=$(mktemp -d); mkdir -p "$S/config" "$S/data/nvim/lazy"
cp -R home/dot_config/nvim "$S/config/nvim"
cp -R ~/.local/share/nvim/lazy/lazy.nvim "$S/data/nvim/lazy/lazy.nvim"
env HOME="$S" XDG_CONFIG_HOME="$S/config" XDG_DATA_HOME="$S/data" \
    XDG_STATE_HOME="$S/state" XDG_CACHE_HOME="$S/cache" \
    nvim --headless "+lua local c=require('lazy.core.config').options; \
      io.stderr:write(tostring(c.checker.enabled)..' '..tostring(c.defaults.lazy)..' '..table.concat(c.performance.rtp.disabled_plugins,','))" \
    +qa </dev/null
```
