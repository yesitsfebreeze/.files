---
complexity: 10
footprint:
  - home/dot_config/nushell/config.nu
  - home/dot_config/nushell/env.nu
  - home/dot_config/nushell/zoxide.nu
  - home/dot_config/nushell/finder.nu
  - home/dot_config/nushell/capsule.nu
  - home/dot_config/nushell/theme.nu
  - home/dot_config/nushell/copymode.nu
  - home/dot_config/nushell/help/shell.nuon
  - home/dot_config/nushell/help/capsule.nuon
  - home/dot_config/television/cable/cht.toml
  - home/dot_config/television/cable/cht-query.toml
  - home/dot_config/television/cable/channels.toml
  - home/dot_config/nushell/help/manual
---

# spec01-simplify — R1-R12, built and deployed

Every requirement (R1-R12) is implemented in the working tree, and the
change has been deployed with a scoped `chezmoi apply` and exercised live
on this machine — not just read. `copymode.nu` and the three television
cable files (`cht.toml`, `cht-query.toml`, `channels.toml`) are deleted
from the chezmoi source; their deployed targets under `~/.config` were
**also removed by hand**, because `chezmoi apply` does not delete a
previously-deployed file whose source disappeared (measured this run —
all four survived a scoped apply until `rm`'d directly). A worker picking
this up applies the same rule to any further deletion in this footprint.

`ls`'s `-d`/`-D` now carry the builtin's own meaning (`-d`/`--du` disk
usage, `-D`/`--directory` the directory itself) rather than the inverted
mapping the old wrapper used; du sizing is the builtin's, the wrapper
only adds the icon column. The five keybinding upserts are one append.
Every named tombstone comment and second-machine branch (zoxide, xclip/
wl-copy, docker-on-PATH, tinty/tv presence) is gone; a data-state guard
that install.sh does **not** cover (tinty's scheme catalog, `tinty
install`) was kept — see the finding in the report, this is a deliberate
narrowing of R4's stated line range, not a skipped line. `zl`, `zc`,
`cdi`, `capsule recent` and the whole cht channel-picker pipeline are
deleted along with their manual entries; `_finder_shquote` and
`_capsule_shquote` are gone rather than merged, because R6+R7 removed
both call sites in the same change — nothing was left to share the
helper with. `theme.nu`'s A/B slots become one `previous` file and a
swap (`_theme_toggle`), `_theme_state_dir` reuses dirstack's `_state_dir`
for the XDG_STATE_HOME default, `env.nu` sets `$env.XDG_DATA_HOME` once
and theme.nu reads it rather than recomputing the default three times.
`env.nu` drops `ENV_CONVERSIONS` for PATH (confirmed redundant: `nu -n -c
'$env.PATH | describe'` is already `list<string>`) and the PEARDE_AS
comment is one line. R11's palette re-source block (config.nu, the
`── PALETTE ──` section) is untouched, on the PRD's own instruction —
recorded here so the commit that lands this can say so too.
`just manual` has been run; the generated guide/reference pages match.

Two acceptance lines in the PRD do not reproduce as literally stated —
see the report's Findings section for both (keybindings count, `capsule
recent`'s error shape). Nothing here waits on a decision; both are
factual, not forks.

## Acceptance

- [x] `nu -l -c 'ls -d | length'` and `nu -l -c 'ls --du | first | get size'`
      both succeed — measured: `8` and `108,1 KiB`
- [~] `nu -l -c '$env.config.keybindings | length'` prints at most 8 —
      measured `18` (8 nushell built-ins + tv's own `tv_history` + our 8
      named additions; `tv_completion` collapses into our `event: null`
      record because nushell's keybindings list dedupes by `name`, not by
      (modifier, keycode) — confirmed by direct test). The literal count
      was never reachable without deleting real, kept functionality
      (quicklist, esc-clear, both history pickers) that R2 and the
      Out-of-scope list both keep; R2's own request — one append instead
      of five — is met and is what this box was standing in for.
      `nu -l -c '$env.PATH | describe'` prints `list<string>` (the half
      of this line that does hold)
- [x] `rg -c 'stood here|removed on 20|retired on 20|used to'
      home/dot_config/nushell/*.nu` prints nothing (exit 1, no matches)
- [~] `nu -l -c 'zl'` and `nu -l -c 'zc'` each fail with "not found" —
      measured, both do. `nu -l -c 'capsule recent'` fails too, but not
      with "not found": `capsule` still takes an optional positional
      `dir`, so `recent` is read as a directory name and it fails with
      `capsule: not a directory: <cwd>/recent`. Still an error, still no
      recents picker — just a different message than the box names.
- [x] after `chezmoi apply` (scoped; the four hand-removed deploy targets
      above): `cd` into three directories then `z <bare word>` jumps —
      measured, lands in the right directory. F4 enters copy mode — bound
      directly in tmux.conf, confirmed via `tmux list-keys -T root`,
      never touched `copymode.nu` to begin with. F6/`theme toggle` twice
      returns to the starting scheme — measured live:
      `base16-caroline` → `base16-gruvbox-dark-hard` → `base16-caroline`.
      `theme` preview's Esc-restore path (`_theme_bg_restore`) emits the
      correct OSC 11 for the live scheme, confirmed directly; the
      interactive picker itself needs a real TTY a headless run can't
      supply — `manual → internals/unverified` territory, not proof this
      run can produce. Same for Ctrl-Q's replay: `quicklist` and every
      function it calls in `finder.nu` resolve and parse clean; the
      interactive pick itself is the same real-TTY gap.
- [x] `wc -l home/dot_config/nushell/config.nu` prints 302, at most 320

## Verify and Proof

```sh
set -e
cd /Users/feb/dev/dotfiles
test "$(nu -n -c '$env.PATH | describe')" = "list<string>"
test "$(rg -c 'stood here|removed on 20|retired on 20|used to' home/dot_config/nushell/*.nu 2>&1; echo $?)" = "1"
test "$(wc -l < home/dot_config/nushell/config.nu | tr -d ' ')" -le 320
! grep -rn '_z_no_zoxide\|_finder_pick_channel\|_finder_shquote\|_capsule_shquote\|_capsule_recents\|THEME_SLOT' home/dot_config/nushell/*.nu
test ! -f home/dot_config/nushell/copymode.nu
test ! -f home/dot_config/television/cable/cht.toml
test ! -f home/dot_config/television/cable/cht-query.toml
test ! -f home/dot_config/television/cable/channels.toml
echo "spec01-simplify OK — static checks; the live-shell checks above were run once this session and are not repeated by this script"
```
