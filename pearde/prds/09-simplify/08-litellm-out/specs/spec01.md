---
complexity: 18
footprint:
  - home/dot_local/bin/executable_cll
  - home/dot_local/bin/executable_litellm-env
  - home/dot_local/bin/executable_litellm-gen-config
  - home/dot_local/bin/executable_litellm-up
  - home/dot_local/bin/executable_llm-quota
  - home/dot_config/nushell/litellm.nu
  - home/dot_config/nushell/config.nu
  - home/dot_config/nushell/help/shell.nuon
  - home/dot_config/nushell/help/nvim.nuon
  - home/dot_config/nushell/help/manual/guide/agents.md
  - home/dot_config/nushell/help/manual/reference/agents.md
  - home/dot_config/nushell/help/manual/internals/nushell-modules.md
  - home/dot_config/nushell/help/manual/internals/neovim.md
  - home/dot_config/nvim/lua/plugins/claude.lua
  - home/.chezmoiremove
---

# spec01 — cut the router out of `home/` and off every reader

Six files leave the managed tree — the five `~/.local/bin` scripts and the
nushell module — and every surface that reads them is cut in the same pass:
the `source` line, four `help` rows, two dangling `also` links, one manual
section, and two comments that cite a path the router no longer has.

`cll` itself survives, on PATH from its own project (spec02), so the two
places that describe the editor's Claude pane keep describing it — they are
re-pointed, not deleted.

**This spec is already built, uncommitted, in the lane
`.pearde/.lanes/09-simplify-08-litellm-out`.** Fifteen files are modified or
deleted there and both probes are green. The same change is saved as
`probe/spec01-built.patch` (`git apply` it) in case that lane is gone. What
is left is the deploy-and-use gate at the bottom, which needs the real
machine and must run after spec02.

## What already stands

- The six sources are `git rm`'d.
- `config.nu` no longer sources `~/.config/nushell/litellm.nu`.
- `shell.nuon` lost all four router rows — `cll [model]`, `llm`, `llm quota`,
  `llm regen`. 38 rows remain and the file parses.
- `nvim.nuon` lost the two `also:` links that pointed at those rows. Its prose
  still describes the pane spawning through `cll`, which is still true.
- `claude.lua` keeps `terminal_cmd = "cll"` (R3, answer (a)); the comment that
  cited `~/.local/bin/cll:212-221` now says the tool ships from its own
  project, and names the fallback if it is not installed.
- `internals/nushell-modules.md` lost its `## litellm.nu` section;
  `internals/neovim.md` gained the same one-line re-pointing.
- `home/.chezmoiremove` gained `.config/nushell/litellm.nu` — and **nothing
  under `.local/bin/`**, deliberately. See the trap below.
- `node scripts/generate-manual.mjs` has been run and is stable across a
  second run.

## What is left

- Run the deploy-and-use gate on the real machine, scoped, after spec02 has
  installed the router.
- Remove this machine's five deployed orphans once, by hand:
  `rm -f ~/.local/bin/{cll,litellm-env,litellm-gen-config,litellm-up,llm-quota}`
  — or let spec02's install overwrite them at the same names.

## TRAP: `.chezmoiremove` is not a one-shot cleanup

It fires on **every** apply and deletes whatever sits at the named target
path — a regular file or a symlink alike. Measured on chezmoi v2.72.1 by
`probe/chezmoiremove-vs-external-install.sh`: a foreign file written at the
path after the first apply was deleted on the second and again on the third,
and a symlink pointing outside the destination went the same way.

So the five `.local/bin/` names must NOT be listed: spec02's project installs
at exactly those names, and an entry there would uninstall it on every
`chezmoi apply`, forever. `.config/nushell/litellm.nu` is listed because
nothing ever reinstalls it.

## Acceptance

- [ ] No file under `home/` is a router source: `home/dot_config/nushell/litellm.nu` and the five `home/dot_local/bin/executable_{cll,litellm-env,litellm-gen-config,litellm-up,llm-quota}` are gone
- [ ] `home/dot_config/nushell/config.nu` has no `litellm` line
- [ ] `home/dot_config/nushell/help/shell.nuon` parses and holds no row whose `cmd` starts `cll` or `llm`
- [ ] `home/dot_config/nushell/help/nvim.nuon` parses and no `also:` list names `cll [model]`
- [ ] `home/.chezmoiremove` names `.config/nushell/litellm.nu` and no path under `.local/bin/`
- [ ] Exactly four files under `home/` still name `cll` or `litellm`, and each one describes the editor pane that still spawns through it: `dot_config/nvim/lua/plugins/claude.lua`, `dot_config/nushell/help/nvim.nuon`, `dot_config/nushell/help/manual/guide/agents.md`, `dot_config/nushell/help/manual/internals/neovim.md`
- [ ] `node scripts/generate-manual.mjs` leaves the manual byte-identical on a second run
- [ ] `probe/deploy-into-a-throwaway-home.sh` exits 0 twice in a row
- [ ] After `chezmoi apply` and a fresh terminal, `<leader>xc` in nvim opens Claude Code and `cc` in the shell opens Claude Code

## Verify and Proof

```sh
set -eu
cd "$(git rev-parse --show-toplevel)"

# the sources are gone
for f in home/dot_config/nushell/litellm.nu \
         home/dot_local/bin/executable_cll \
         home/dot_local/bin/executable_litellm-env \
         home/dot_local/bin/executable_litellm-gen-config \
         home/dot_local/bin/executable_litellm-up \
         home/dot_local/bin/executable_llm-quota; do
  if [ -e "$f" ]; then echo "FAIL: $f still here"; exit 1; fi
done

# the readers are cut
if grep -q litellm home/dot_config/nushell/config.nu; then echo "FAIL: config.nu"; exit 1; fi
# TRAP: `where cmd =~ '...'` answers 6 on this surface — some rows carry no
# `cmd`. Default the cell first; this is the form that answers an empty list.
n=$(nu -c "open home/dot_config/nushell/help/shell.nuon \
  | where (\$in.cmd? | default '') =~ '^(cll|llm)\b' | length")
if [ "$n" != 0 ]; then echo "FAIL: $n router rows in shell.nuon"; exit 1; fi
if grep -q '"cll \[model\]"' home/dot_config/nushell/help/nvim.nuon; then
  echo "FAIL: dangling also link"; exit 1; fi
if grep -q '^\.local/bin/' home/.chezmoiremove; then
  echo "FAIL: .chezmoiremove would uninstall the router project"; exit 1; fi
grep -qx '.config/nushell/litellm.nu' home/.chezmoiremove

# exactly the four files that describe the pane still name it
got=$(rg -l 'litellm|cll' home/ | sort | tr '\n' ' ')
want='home/dot_config/nushell/help/manual/guide/agents.md home/dot_config/nushell/help/manual/internals/neovim.md home/dot_config/nushell/help/nvim.nuon home/dot_config/nvim/lua/plugins/claude.lua '
if [ "$got" != "$want" ]; then echo "FAIL: expected 4 files, got: $got"; exit 1; fi

# the manual and its sources agree
a=$(find home/dot_config/nushell/help/manual/guide home/dot_config/nushell/help/manual/reference -type f | sort | xargs shasum -a 256 | shasum -a 256)
node scripts/generate-manual.mjs >/dev/null
b=$(find home/dot_config/nushell/help/manual/guide home/dot_config/nushell/help/manual/reference -type f | sort | xargs shasum -a 256 | shasum -a 256)
if [ "$a" != "$b" ]; then echo "FAIL: manual drifted from its sources"; exit 1; fi

# the deployed post-state, in a throwaway home. TRAP: a lane's own .pearde is
# a stale checkout of the branch point — the probe lives on the LIVE board, so
# take its path from there and skip rather than fail if this is not that repo.
P=.pearde/prds/09-simplify/08-litellm-out/probe/deploy-into-a-throwaway-home.sh
if [ -f "$P" ]; then bash "$P"; bash "$P"
else echo "skip: probe not in this checkout — run it from the live board"; fi

echo OK
```
