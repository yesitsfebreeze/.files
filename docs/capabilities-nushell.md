# Capabilities of the nushell daily driver

Companion to [`capabilities.md`](capabilities.md), same rules: ratings are 1–10
(complexity / usefulness), sorted best-first by value ratio (usefulness minus
complexity). Markers on the ## line say what to do: nothing = take over,
`SIMPLIFY` = take over a reduced version, `DEFER` = not part of the minimal
base, revisit later, `DO NOT PORT` = drop.

Source of truth: the deployed tree at `~/.config/nushell/` — `env.nu`,
`config.nu`, `dirstack.nu`, `finder.nu`, `quicklist.nu`, `leadermode.nu`,
`overlay.nu`, `pass.nu`, `theme.nu`, `opacity.nu`, plus
`~/.config/television/` (config + ~30 cable channels).

**Decision 4 (2026-08-21) makes the deployed tree canonical** and the chezmoi
source abandoned — see
[the corrections backlog](../prds/00-delivery/corrections/prd.md). That is not
a formality for this file: the chezmoi source at
`~/.local/share/chezmoi/home/dot_config/nushell/` holds only `cl.py`,
`config.nu`, `env.nu`, `finder.nu`, `pass.nu` and `theme.nu` — so
`dirstack.nu`, `quicklist.nu`, `leadermode.nu`, `overlay.nu` and `opacity.nu`
are not in it at all — and its `config.nu` (380 lines) and `finder.nu` (345
lines) are different programs from the deployed ones (715 and 221). Verified
live on 2026-08-21. Everything rated below is the deployed artifact.

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
  `y`→yazi, `q`/`:q`/`/exit`→exit, `rr`→chezmoi update, `cf` (file →
  clipboard, picks pbcopy/wl-copy/xclip), `pass` completion from the live
  store.
- **`bb`/`ba` are excluded, not overlooked.** The live `config.nu` defines
  `alias bb = brr` and `alias ba = brr --attach`; both invoke **`brr`**, not
  `burrito` (M-7 — both binaries exist, so a search for "burrito" misses
  them). burrito is `DO NOT PORT`, decided 2026-08-20: it is no longer used,
  and WezTerm's nine-tab floor owns panes and tabs. The `burrito-sessions`
  television channel comes out with the two aliases.
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
## Opacity picker  DEFER
- `opacity` / tv channel: live WezTerm window opacity via OSC 1337 user-var,
  5% steps. Cosmetic, tiny audience.
- 3
- 3
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
## Theme switcher (tinty + television)  SIMPLIFY
- `theme`: tv picker over the base16/base24 catalog with static swatch
  preview + live OSC-11 background retint, A/B slots flipped by F6, recency +
  liked sets, background override ladder/tuner.
  **Decided 2026-08-21 (user): tinty stays as palette owner and the `DEFER`
  "cosmetic" verdict is withdrawn** — see open decision 2 in
  [the corrections backlog](../prds/00-delivery/corrections/prd.md). It is
  infrastructure: `tinty apply` is what writes both the WezTerm palette
  (`~/.config/wezterm/colors.lua`) and the tinted-shell artifact a new shell
  re-asserts, so dropping it would leave WezTerm, Neovim, tv and the shell
  with no palette source. Minimal base is the palette-owning core: `tinty
  apply`, its `current_scheme`, the tinted-shell re-assert at shell start
  (`04-shell/01-core-config` R10), the A/B slots with `_theme_toggle` behind
  F6, and the tv scheme picker — the node that builds it is
  `04-shell/09-theme-switcher` (S.9). **Dropped by the `SIMPLIFY`:** the
  background override ladder and its R/G/B tuner, and the liked/recency
  sets — those are the cosmetic part, and the background override overlaps
  the still-open `wallpaper-opacity` decision (D.1d). The ratio stays −3 and
  the entry stays where it is: the numbers were never wrong, the membership
  was.
- 8
- 5
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
  unmanaged local leftover from that design. **Decision 4 (2026-08-21) settles
  which tree "the live config" means:** the deployed `~/.config` tree is
  canonical and the chezmoi source abandoned, so the 345-line source
  `finder.nu` and its `--resume`/`--fresh` design are not ported, and
  `leadermode.nu` is a leftover of an abandoned design that nothing manages.
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
