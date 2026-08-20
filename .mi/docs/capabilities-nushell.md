# Capabilities of the nushell daily driver

Companion to [`capabilities.md`](capabilities.md), same rules: ratings are 1–10
(complexity / usefulness), sorted best-first by value ratio (usefulness minus
complexity). Markers on the ## line say what to do: nothing = take over,
`SIMPLIFY` = take over a reduced version, `DEFER` = not part of the minimal
base, revisit later, `DO NOT PORT` = drop.

Source of truth: the live config in `~/.config/nushell/` (chezmoi-managed) —
`env.nu`, `config.nu`, `dirstack.nu`, `finder.nu`, `quicklist.nu`,
`leadermode.nu`, `overlay.nu`, `pass.nu`, `theme.nu`, `opacity.nu`, plus
`~/.config/television/` (config + ~30 cable channels).

## Core shell config
- `env.nu`/`config.nu` base: PATH repair for nu-as-login-shell (macOS
  path_helper never runs for nu, so homebrew/system dirs are appended
  manually), EDITOR/VISUAL=nvim, sqlite history (100k, shared across panes),
  fuzzy completions, `rm` → trash, no banner, OSC 133/633 off + OSC 7 on
  (WezTerm cwd reporting), `mkcd` — a cd that creates missing dirs (with
  confirm) and acts as the single funnel every move flows through, and the
  start-dir mechanism: every move records `startdir.txt`, new shells open
  where you last navigated.
- 3
- 9
----
## Aliases and small utilities
- `cat`→bat, `grep`→rg, `g`→git, `lg`→lazygit, `nv`/`vi`→nvim, `nn` (notes),
  `q`/`:q`/`/exit`→exit, `rr`→chezmoi update, `bb`/`ba` (burrito sessions),
  `cf` (file → clipboard, picks pbcopy/wl-copy/xclip), `pass` completion from
  the live store.
- 2
- 8
----
## Zoxide navigation suite
- Wrapped `z`/`zi`: `z` opens a file in $EDITOR if the arg resolves to one,
  otherwise jumps; both log into the quicklist recents. `zz` = back-toggle,
  `zl` = jump+list, `zc` = jump+Claude, `cdi`→zi. All jumps flow through
  `mkcd`, so they update start dir and recency like a real cd.
- 4
- 9
----
## Dirstack — directory recency
- `dirs.txt`: recency-ordered stack of every visited dir (pushed by the PWD
  hook, any navigation means), deduped, capped at 100, feeds the
  `recent-dirs` television channel; `startdir.txt` single-line last-dir
  marker read at shell start.
- **Live bug L-3, do not reproduce:** the channel is `recent-dirs`
  (`~/.config/television/cable/recent-dirs.toml`), but `finder.nu`'s
  `_finder_type` types `"files" | "dirs" | "rcwd"`. No cable file is named
  `rcwd`, so recent-dir picks fall through to `Any` and come back as raw
  strings instead of expanded paths. `recent-files` is untyped for the same
  reason. The rebuild types the real channel names.
- 3
- 7
----
## Decorated ls + auto-list on cd
- `ls` shadowed: structured table with a Nerd Font icon column, dirs grouped,
  newest last; `-D` opt-in swaps dir inode sizes for recursive `du` sizes.
  `l`/`ll`/`la` variants. A PWD hook auto-lists after every directory change
  (with `stty sane` first so a crashed TUI can't staircase the output).
- 5
- 8
----
## Directory-scoped history
- Sqlite history records cwd per command: Ctrl-R opens a television picker
  over this directory's commands (inline, prefiltered), Up/Down cycle them
  inline, Alt-R and Shift+Up/Down keep the global equivalents. Menu keys
  fall through so completion menus still work.
- 5
- 8
----
## Television finder stack
- `finder.nu`: typed fuzzy picker over tv — channel selection is itself a
  fuzzy channel; results decode into structured nu data (FileList, GrepList
  {file,line,text}, Commits {hash,subject}, ChtSheet) and open by type
  (file→editor, dir→cd, grep hit→editor@line, commit→git show). ~30 cable
  channels (files, dirs, text, git-*, zoxide, env, recent-dirs, …).
  Ctrl+Space/F1 = act-on-pick remote, Ctrl-T = insert-at-cursor (shell-quoted).
- **Live bug L-2, do not reproduce:** commit→`git show` has never run.
  `git-log.toml` already splits the commit out (`output =
  "{strip_ansi|split: :1}"`, index 1 of the `--graph` line), so tv emits a
  bare hash — but `_finder_decode`'s `Commits` arm splits that hash again
  and reads index 1, which is empty, and the `^[0-9a-f]{7,}$` guard then
  drops every row. The decoder must read the field the channel actually emits.
- 8
- 9
----
## Bare-word zoxide fallback
- A line whose first word is no known command/path/expression is treated as a
  zoxide query: `proj` ⏎ jumps like `z proj`. Implemented via pre_execution
  (where a cd persists) + a screen clear in pre_prompt to bury the doomed
  "command not found"; jumps only on a genuine dir match.
- 7
- 8
----
## Quicklist — cross-channel recents
- Jumps are logged (kind, value, channel, cwd, ts; deduped, capped 200).
  Ctrl-Q opens the recents as a tv channel: enter re-opens by type, ctrl-r
  replays the originating channel in the cwd the pick was made in.
- **Live bug L-4, do not reproduce:** despite `_recents_add` living in
  `finder.nu`, `finder` never calls it. The only call sites are the three
  zoxide wrappers and the bare-word navigation fallback in `config.nu`, all
  tagged channel `zoxide`. The log therefore holds directory jumps only — a
  file opened through the finder never reaches the quicklist, and no entry
  ever carries a channel other than `zoxide`, which leaves the ctrl-r
  "replay the originating channel" path unreachable for every channel but
  that one. The rebuild logs the pick inside `finder`, where the channel
  name is already in hand.
- 6
- 6
----
## Claude launchers  SIMPLIFY
- `cc`/`cr`: Claude with skipped permissions behind a login-profile picker
  (`~/.claude/<profile>` subdirs sharing heavy state via symlinks, own
  credentials/settings); `cl` = goal-loop launcher via cl.py under a pty;
  `jj` = jump to the zoxide-known journal dir and open Claude. Minimal base:
  keep plain `cc`/`cr` (skip-permissions + profile picker only when >1
  profile exists); `cl`/`jj` stay personal add-ons.
- 7
- 6
----
## Theme switcher (tinty + television)  DEFER
- `theme`: tv picker over the base16/base24 catalog with static swatch
  preview + live OSC-11 background retint, A/B slots flipped by F6, recency +
  liked sets, background override ladder/tuner. Works, but is a large surface
  for a cosmetic concern — not part of the minimal base.
- 8
- 5
----
## Opacity picker  DEFER
- `opacity` / tv channel: live WezTerm window opacity via OSC 1337 user-var,
  5% steps. Cosmetic, tiny audience.
- 3
- 3
----
## Leader mode  DO NOT PORT
- **Dead code, not live behaviour (L-5).** `leadermode.nu` describes a
  which-key style leader overlay over `input listen` (reedline has no chord
  trees), but `config.nu` never sources it and its menu entries call
  `finder --resume` / `finder --fresh`, flags the deployed
  `~/.config/nushell/finder.nu` does not define (its only flag is `--start`).
  Nothing in it has ever run. Superseded in practice by the tv remote on
  Ctrl+Space; menu keys are in any case unreliable under `input listen`
  (nu #13891). The `DO NOT PORT` verdict stands, now for the stronger reason
  that there is nothing to port.
- The audit read L-5 as "calls flags that do not exist". The sharper reading:
  those flags exist in the *other* finder — the 345-line
  `~/.local/share/chezmoi/home/dot_config/nushell/finder.nu`, which is a
  different, stack-and-resume design from the 221-line deployed one, and
  which does not ship `leadermode.nu` at all. `leadermode.nu` is an
  unmanaged local leftover from that design. See the escalation on W0.6: the
  chezmoi source and `~/.config` have diverged in both directions, so
  "the live config" needs to name one of them.
- 7
- 3
----
## Overlay finder (WIP)  DO NOT PORT
- `overlay.nu`: nu-native overlay that would use tv only as channel provider.
  Explicitly work-in-progress, not sourced by config.nu. Revisit only if tv's
  query-reporting limitation starts to hurt.
- 8
- 2
----
