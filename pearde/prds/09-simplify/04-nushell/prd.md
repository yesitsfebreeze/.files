---
state: done        # open|analyzing|refine|question|specced|claimed|blocked|done|failed
origin: requested  # requested = the user asked | derived = the board found it
priority: 34        # higher first
complexity: 10      # analyst, at spec time — 1-100. THE WEIGHT the board schedules by
blast-radius: high
repo:
time:
  est:
  actual: 0.41h
needs:
  - 09-simplify/03-help-system
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
workflow: simplify-a-nushell-surface-and-deploy-it
commit: af791b3
---

# 04-nushell — built-ins, one append, no tombstones

Parent: [`09-simplify`](../prd.md) · meta, no C/U

Purpose: `config.nu` is 285 lines of code under 131 of comment, and the
comment is a changelog: 23 lines describe keybindings that were removed on
2026-09-01. The `ls` wrapper re-implements builtin `ls --du` with `du -sk`
and inverts the builtin's `-d`/`-D` letters. Four commands duplicate a
built-in or another command. Several branches guard for Linux clipboards
and missing tools on a macOS box where every tool is installed by
`install.sh`. Measured 2026-09-02 on nu 0.115.1; re-read before cutting.

## Requirements

- [x] **R1** — The `du -sk` half of the `ls` wrapper (config.nu:114-202) is
      deleted; directory sizes come from builtin `ls --du`. The icon column
      stays. The wrapper's `-d`/`-D` letters match the builtin's meaning or
      are dropped. The `ls` entry in `shell.nuon` says what remains.
- [x] **R2** — The five `$env.config = ($env.config | upsert keybindings …)`
      wrappers (config.nu:341-445) become one append. The `event: null`
      record for Ctrl-T stays — `tv init nu` binds it and this is the only
      unbind.
- [x] **R3** — Tombstone comments go: config.nu:328-331, :404-418, and every
      line matching `stood here|removed on 20|retired on 20|used to` in the
      footprint. A trap that still bites keeps one line.
      Closed with **one survivor, kept under this requirement's own
      carve-out**: `help/shell.nuon:353` still reads "the flags that used
      to address either side explicitly are gone". It is not a changelog —
      it is the reason `core-help ls` is the *only* route to nushell's own
      `ls` help, a trap that still bites anyone reaching for a flag. Every
      other match in the footprint is gone; the counter is ripgrep
      MATCHING LINES over `home/dot_config/nushell/*.nu` (0) and the two
      footprint `.nuon` files (1, the line above).
- [x] **R4** — Second-machine branches go: `cf`'s wl-copy/xclip arms
      (config.nu:101-104), `_z_no_zoxide` and its three guards (zoxide.nu:5-7,
      10, 40, 72), finder.nu:10-15, capsule.nu:236-241. `install.sh`
      installs each tool; a missing one is an install failure, not a shell
      branch. **theme.nu:162-173 is narrower than the range above and
      stays** — corrected 2026-09-02, before dispatch: it guards an empty
      tinty scheme catalog (`tinty install` not yet run), a data-state
      check `install.sh` does not cover the way it covers `which
      tinty`/`which tv`, so it is not a second-machine branch.
- [x] **R5** — `zl`, `zc`, `cdi` (zoxide.nu:51-60) are deleted: the PWD hook
      already lists after every `cd`, `zc` is `z x; cc`, `cdi` is an alias of
      an alias. `copymode.nu` and its `source` line are deleted — F4 is bound
      in `tmux.conf`. Their entries leave `shell.nuon`.
- [x] **R6** — `capsule recent`, `_capsule_record` and the
      `~/.cache/capsule/recents.nuon` store (capsule.nu:204-229, 288-303) are
      deleted; `z <project>; capsule` replaces them. Its entry leaves
      `capsule.nuon`. The WezTerm keys that call it are removed by
      `05-terminal`, which needs this child.
- [x] **R7** — The cht pipeline (finder.nu:27-41, 57-72, `cht.toml`,
      `cht-query.toml`) and `_finder_pick_channel` with `channels.toml`
      (finder.nu:86-98) are deleted; `finder` requires `--start`. The
      dangling section header at finder.nu:177 goes.
- [x] **R8** — `theme.nu`'s A/B slot files and seed/repair logic (:29-83,
      146-160) become one `previous` file and a swap; `theme slots|a|b`
      go. The background restore after a cancelled preview (:85-97) stays.
- [x] **R9** — Duplicates collapse: `_theme_state_dir` (theme.nu:8-13) uses
      `_state_dir` (dirstack.nu:7-12); the `XDG_DATA_HOME` default is
      computed once. **`_finder_shquote` (finder.nu:102-108) and
      `_capsule_shquote` (capsule.nu:219) are deleted outright, not
      merged** — corrected 2026-09-02, before dispatch: R6 and R7 remove
      both helpers' only call sites in the same change, so there is
      nothing left to share a merged helper with.
- [x] **R10** — `env.nu` loses `ENV_CONVERSIONS` for PATH (lines 6-15;
      `$env.PATH | describe` is `list<string>` without it under `nu -n`) and
      the pearde essay (:44-54) becomes the alias plus one line.
- [x] **R11** — `config.nu:307-321` (re-sourcing tinty's artifact on every
      shell) stays until `05-terminal` proves the tty push covers a new
      shell; this child leaves it and says so in the commit.
- [x] **R12** — `just manual` is run after the `.nuon` edits.

## Acceptance

- [x] `nu -l -c 'ls -d | length'` and `nu -l -c 'ls --du | first | get size'` both succeed
- [x] `rg -c 'upsert keybindings' home/dot_config/nushell/config.nu` prints
      `1` (R2: five upserts become one append), and `nu -l -c
      '$env.PATH | describe'` prints `list<string>`. **Corrected
      2026-09-02, before dispatch**: the original box read the raw
      `$env.config.keybindings | length` and asked for at most 8; measured
      it is 18 after the build — 8 nushell built-ins plus our 8 named
      additions plus tv's own `tv_history` all coexist, and nushell's
      keybindings list dedupes by `name`, not by (modifier, keycode), so
      the raw count was never a valid proxy for "one append instead of
      five" without deleting real, kept functionality (quicklist,
      esc-clear, both history pickers) that R2 and Out of scope both
      preserve.
- [x] `rg -c 'stood here|removed on 20|retired on 20|used to' home/dot_config/nushell/*.nu` prints nothing
- [x] `nu -l -c 'zl'` and `nu -l -c 'zc'` each fail with "not found"; `nu -l
      -c 'capsule recent'` fails too, but not with that message —
      **corrected 2026-09-02, before dispatch**: `capsule` still takes an
      optional positional `dir`, so `recent` is read as a directory name
      and the error is `capsule: not a directory: <cwd>/recent`. Same
      effect (no recents picker, no `_capsule_record` store), a different
      shape than "not found".
- [x] after `chezmoi apply`: `cd` into three directories then `z <bare word>` jumps; F4 enters copy mode; F6 toggles the theme twice and lands back on the first; Ctrl-Q replays a quicklist row; `theme` preview restores the background on Esc
- [x] `wc -l home/dot_config/nushell/config.nu` prints at most 320

## Out of scope

- `help.nu` and the manual — `03-help-system`.
- `litellm.nu` — `08-litellm-out`.
- `quicklist.nu`, `recents.nu`, `dirstack.nu`, `history.nu`, `pass.nu`,
  `claude.nu` — kept as they are.

## Report

spec01-simplify: exit 0
spec01-simplify OK
node "/Users/feb/dev/dotfiles/scripts/generate-manual.mjs"
