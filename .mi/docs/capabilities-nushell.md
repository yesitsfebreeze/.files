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
  hook, any navigation means), deduped, capped at 100, feeds the `rcwd`
  television channel; `startdir.txt` single-line last-dir marker read at
  shell start.
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
- Every pick/jump (finder, zoxide, fallback) is logged (kind, value, channel,
  cwd, ts; deduped, capped 200). Ctrl-Q opens the recents as a tv channel:
  enter re-opens by type, ctrl-r replays the originating channel in the cwd
  the pick was made in.
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
- which-key style leader overlay over `input listen` (reedline has no chord
  trees). Superseded in practice by the tv remote on Ctrl+Space; menu keys
  are unreliable under `input listen` (nu #13891).
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
