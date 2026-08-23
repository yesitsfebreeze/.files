# spec01 — the television surface: config.toml + the curated cable set

Create the managed television config and the fifteen cable channels R5 keeps.
Every file is carried from the live `~/.config/television/` (read only, never
edited) with the local overrides the PRD records; the drop set is not copied.
This spec is pure static surface — no nushell code.

**Est:** 2h

**Footprint:** `home/dot_config/television/config.toml`,
`home/dot_config/television/cable/` (15 new `.toml` files)

## Files

`config.toml` — carry the live file: `theme = "default"` under `[ui]`, plus
the three rounded-border blocks. Keep the live header comment's reason and
sharpen it to the epic's I5 wording: `default` is the builtin theme whose
colors are ANSI names with no fixed background, so tv inherits the terminal's
16 slots from tinty; the hex themes bake a palette and never follow the
terminal (R6).

Cable files, each from its live counterpart:

| file | carry, with the load-bearing part named |
|---|---|
| `files.toml` | two-entry source (`fd -t f` / `-H`), bat preview with `BAT_THEME = "ansi"`, `shortcut = "f1"`, f12 edit action |
| `dirs.toml` | two-entry `fd -t d` source, `ls -la` preview, `shortcut = "f2"` |
| `text.toml` | **local override, not stock** (R1, M-9): two-entry `rg` source, `ansi = true`, `output = "{strip_ansi\|split:\\::..2}"`, offset preview, enter → `actions:edit`. The `\\:` spelling is the escaping trap: `\\:` in TOML reaches tv as `\:`, the escaped delimiter its template engine splits on |
| `zoxide.toml` | `zoxide query -l`, `no_sort`/`frecency` off, enter → `actions:cd` (the nested-`$SHELL` hijack R1 un-hijacks), ctrl-d remove |
| `env.toml` | `printenv`, value output, portrait layout, `shortcut = "f3"` |
| `git-log.toml` | `output = "{strip_ansi\|split: :1}"` — **the channel owns the hash extraction** (R2b); the same template in preview and the three actions (cherry-pick, revert, checkout). The decoder never re-splits |
| `git-files.toml` | `git ls-files`, bat preview, f12 edit |
| `git-branch.toml` | branch list, `output = "{split: :0}"`, enter → checkout plus delete/merge/rebase actions |
| `recent-dirs.toml` | source is `nu -n -c 'source ~/.config/nushell/dirstack.nu; _dirstack_list \| str join (char nl)'` — fed by S.1 R8's dirstack, format/dedup/cap single-sourced there. The channel name is `recent-dirs`; `rcwd` is bug L-3's id and is never a channel name |
| `recent-files.toml` | two-entry bash-delegated source (nu parses neither `2>/dev/null` nor `\|\|`), bat preview, enter → `actions:edit` (the third hijack R1 covers) |
| `alias.toml` | `nu -n -c 'source ~/.config/nushell/config.nu; scope aliases …'` source + expansion preview |
| `cht.toml` | the curated offline language list (offline on purpose — the global `:list` is ~14k noisy entries), live `:list` preview, `shortcut = "f5"`, ctrl-e `:learn` action. Dropping the sessions channel dissolved the in-tv f5 collision, so no rekey |
| `cht-query.toml` | hint-only default source (the real list is injected by `finder` per language, spec02), sheet preview |
| `channels.toml` | default source `tv list-channels`; `finder` overrides it per call with `--source-command` |
| `nu-history.toml` | the sqlite-aware override of tv's builtin (R5): `nu -n` (no config load — the builtin cold-starts a full shell per keypress) querying the sqlite history directly, `GROUP BY command_line ORDER BY MAX(id) DESC`, `no_sort`/`frecency` off. **Do not carry the live literal db path** — see below |

**The nu-history db path is derived, never the live literal.** The live
source hardcodes `~/.config/nushell/history.sqlite3`, which resolves
correctly only because the LIVE wezterm exports `XDG_CONFIG_HOME` — a line
the repo's `wezterm.lua` deliberately omits (measured by S.6, recorded in
`home/dot_config/nushell/history.nu`'s header). Reedline's actual db is
`$nu.history-path`'s directory. Inside the channel's `nu -n` the loaded
config's `file_format` is not in effect, so measure first, then encode:

1. Measure `nu -n -c '$nu.history-path'` on the pinned 0.114.1, with and
   without `XDG_CONFIG_HOME` set.
2. Point the source at
   `($nu.history-path | path dirname | path join history.sqlite3)` — the
   directory resolution honours the launch env exactly as reedline does,
   independent of the `-n` default format.
3. Guard the missing-db case: a fresh machine has no sqlite yet, and an
   unguarded `open` is a red error inside the picker. Return nothing instead.

Record the measurement in the file's header comment.

**Not copied, on the record** (R5 drop + Non-cable assets): the sessions
channels `burrito-sessions.toml` and `opencode-sessions.toml` (`DO NOT
PORT`); the git tail `git-diff`, `git-stash`, `git-reflog`, `git-worktrees`,
`git-deletions`, `git-remotes`, `git-submodules`, `git-tags`, `git-repos`
(migrate on demand); `bg.toml`, `opacity.toml`, `bg-preview.sh`,
`theme-preview-sample.ts` (wallpaper-opacity decision). `quicklist.toml` is
**deferred to 04-shell/07**: its source calls `_recents_lines`, which does
not exist until that node lands its logger — shipping the cable now puts an
erroring channel in the remote. `theme.toml.tmpl` and
`executable_theme-preview.sh` are S.9's, already landed — do not touch.

## Acceptance

- [x] `home/dot_config/television/cable/` holds exactly the 15 files above
      plus `theme.toml.tmpl`; none of the drop-set names is present.
      `ls` returns exactly those 16 names, and the gate's census check —
      which also asserts every drop-set name absent — is green:
      `PASS  tree: cable census — the 15 curated channels + theme.toml.tmpl,
      nothing else, no drop-set name`.
- [x] `config.toml` sets `theme = "default"` and no cable or config file in
      the managed television tree contains a hex color value.
      `PASS  tree: config.toml sets theme = "default"` and
      `PASS  tree: no hex color value in config.toml or any cable file (R6)`.
      The only `#RRGGBB` under `home/dot_config/television/` is a comment in
      S.9's `executable_theme-preview.sh:141`, which is neither a cable nor a
      config file and is not this node's.
- [x] `git-log.toml` uses `{strip_ansi|split: :1}` in `output`, preview and
      all three actions — one extraction, owned by the channel.
      `/usr/bin/grep -c "strip_ansi|split: :1" …/git-log.toml` → `5`
      (output + preview + cherry-pick + revert + checkout), and
      `PASS  tree: git-log.toml carries {strip_ansi|split: :1} in output,
      preview and all three actions — one extraction, owned by the channel`.
- [x] `nu-history.toml` contains no literal `history.sqlite3` path rooted in
      `.config/nushell`, and its source returns rows against a scratch
      sqlite db seeded at a measured `$nu.history-path`-derived location.
      `PASS  tree: nu-history.toml derives the db from $nu.history-path's
      directory; the live literal spelling has 0 hits`, its executed
      counterfactual `PASS  tree: counterfactual live-literal-db-path FAILS
      the path check`, and hermetically
      `PASS  hermetic: the source returns rows from the
      $nu.history-path-derived db, newest-first, deduped (got: first cmd|second
      cmd)` plus `PASS  hermetic: a missing db yields empty output and no error
      (rc=0, err=0 bytes)`. The measurement is recorded in the file's header.
- [x] `recent-dirs.toml`'s source calls `_dirstack_list`; the string `rcwd`
      appears nowhere under `home/dot_config/television/`.
      `PASS  tree: recent-dirs.toml's source calls _dirstack_list (fed by S.1
      R8's dirstack)` and `PASS  tree: the L-3 bug id appears nowhere under the
      managed television tree`;
      `/usr/bin/grep -rn "rcwd" home/dot_config/television/` exits 1 with no
      output.
- [x] `bash tests/managed-config.sh` reports no NEW failure against the
      state before this spec (the pre-existing theme.toml.tmpl census red is
      filed as a correction and is not this spec's to fix or extend).
      Run 2026-08-23: `EXIT=0`, 65 PASS, 0 FAIL — no failure at all, new or
      pre-existing.

## Verify

```sh
ls home/dot_config/television/cable/
/usr/bin/grep -rn "rcwd" home/dot_config/television/ ; test $? -eq 1
/usr/bin/grep -c "strip_ansi|split: :1" home/dot_config/television/cable/git-log.toml
bash tests/managed-config.sh
bash tests/shell-television.sh --tree   # once spec04 lands
```
