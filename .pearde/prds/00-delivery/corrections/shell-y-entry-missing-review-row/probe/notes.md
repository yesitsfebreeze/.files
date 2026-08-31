# probe — analyst-shell-y-row, 2026-08-31

Pass one: the fix stands in the tree, uncommitted. All commands run from the
repo root.

## The finding re-verified before building

- `nu tests/help-content-model.nu` → exit 1,
  `1 violation(s): shell.nuon [y]: has no row in use-review.nuon — read the
  `use` against prds/04-shell/02-aliases-utilities/prd.md and the live route,
  then record the reading with digest b88bef74e7a115cc`. Same shape as the
  PRD records.
- The PRD's corrected attribution still holds: `git show HEAD:home/dot_config/
  nushell/help/shell.nuon | grep -c 'cmd: "y"'` → `0`; `git log --all -S
  'cmd: "y"' -- home/dot_config/nushell/help/shell.nuon` → empty. The entry is
  working-tree only, as corrected 2026-08-31.

## The digest, independently derived (not copied off the gate)

```
nu -c 'let e = (open home/dot_config/nushell/help/shell.nuon | where cmd == "y" | first)
       $"($e.use)\n--\n($e.source)" | hash sha256 | str substring 0..15'
```
→ `b88bef74e7a115cc`. Reproduces the gate's printed digest; the sha256-first-16
formula is help-content-model.nu's `use-digest`.

## The reading that backs the row

- Source side: `prds/04-shell/02-aliases-utilities/prd.md:23-27` — R1 lists
  `y`→yazi among the tool aliases; the PRD carries no gesture text of its own.
- Live route: `alias y = yazi` at `home/dot_config/nushell/config.nu:114`
  (uncommitted, 2026-08-31 — other work's, read not touched). Also present
  (uncommitted, same lane) in `tests/nushell-aliases.sh`'s twelve-alias contract
  and its hermetic `scope aliases` check (name `y` among all twelve resolved).
- `yazi --version` → 26.8.15 at /opt/homebrew/bin/yazi. `~/.config/yazi`
  absent, so no keymap override.
- Driven in a tmux scratch session (`tmux -L <label> new-session -d … nu -c
  'yazi'` on a mktemp dir, never under prds/): `l` descends into a directory
  (cwd line changes to the subdir); `q` quits — the pane process exits and the
  session dies. Arrows/hjkl movement and Enter-to-open are yazi's stock
  defaults and were not separately driven; the row's note says so.

## What was NOT done

- No census of other review-row gaps — the gate itself is that census and it
  reported exactly one violation (this entry) before the row, zero after.
- The `y` alias in config.nu, its lines in tests/nushell-aliases.sh and the
  wezterm.lua rewrite are the concurrent lane's; untouched.
- No yazi config, wrapper or quit-cd integration was added — the entry
  describes the bare alias as it is.