# Capabilities of `~/.files`

Markers on the `##` line say what to do with a capability: nothing = take
over as-is, `SIMPLIFY` = take over a reduced version, `CONSOLIDATE` = merge
with overlapping capabilities into one tool, `DEFER` = not part of the
minimal base, `DO NOT PORT` = drop entirely. For example the docker dev mount
is `CONSOLIDATE` — it should work flawlessly, as one tool — and nothing
marked `DO NOT PORT` is created or ported at all.

The WezTerm entries below describe the **legacy** `~/.files` config, not the
one that is live. The live terminal setup (WezTerm and burrito) is rated in
[`capabilities-terminal.md`](capabilities-terminal.md), and `02-terminal` is
specced from that file. Where an entry here carries `DO NOT PORT` for that
reason, what is dropped is this *description*, not necessarily the capability.

What this dotfiles repo can actually do, one capability per section.
Ratings are 1–10 (complexity = how intricate the implementation is,
usefulness = how much day-to-day value it delivers).

Sorted best-first by value ratio (usefulness minus complexity): low effort,
high payoff at the top; expensive or niche machinery at the bottom.

## Shell shortcuts and navigation helpers
- Aliases (`ls`→eza, `e`→nvim, `c`/`..`, `dk` = force-remove all containers, `cl` = Claude with skipped permissions, `oc` = opencode), a `cd` override that lists after every jump, and `di`/`dc` jump functions into the DIW installer/sources customer trees.
- 2
- 8
----
## WezTerm terminal configuration  DO NOT PORT
- `wezterm.lua`: Departure Mono font shipped in-repo, Gruvbox Material colors with a custom green cursor, transparent minimal tab bar (numeric titles), inactive-pane dimming, no bell, RESIZE-only decorations, platform-aware padding.
- 4
- 9
----
## Zsh environment (oh-my-zsh)  DO NOT PORT
- `user/.zshrc` sets theme `nanotech`, git plugin, correction, history stamps, PATH for `~/.local/bin`, bun, nvm, opencode; deliberately Linux/Docker-safe (no macOS-only tooling).
- 3
- 8
----
## `reload` — one-command dotfiles sync  DO NOT PORT
- Commits everything in `$HOME`, pulls with rebase, pushes, and re-sources `.zshrc` without losing the current directory.
- 2
- 7
----
## Symlink-based dotfile deployment  DO NOT PORT
- Reads `index` (`source:dest` pairs) and `deleted`, then symlinks `user/<source>` into `$HOME/<dest>`, recreating parent dirs and purging entries listed for removal. Currently shipped as `deploy.disabled`, so it must be renamed/invoked manually.
- 5
- 9
----
## Claude Code context-routing policy  DO NOT PORT
- `CLAUDE.md` enforces context-mode MCP routing: curl/wget/WebFetch and inline HTTP are blocked, big Bash/Read/Grep work is redirected into the sandbox, subagents inherit the routing block, and responses are capped at 500 words with artifacts written to files.
- 4
- 8
----
## `mount` — drop the current dir into a container  CONSOLIDATE
- Shell function that runs `just run "$PWD"` from `~/docker`, building the dev image and dropping into it with the workspace mounted.
- 3
- 7
----
## Nine-tab maximized startup windows  DO NOT PORT
- `gui-startup`/`gui-attached` hooks spawn a window pre-filled with 9 tabs and maximize it; `Cmd+N` / `Ctrl+Shift+N` spawn more of the same, `Ctrl+Shift+Q` closes every tab at once. Superseded entry-for-entry by `capabilities-terminal.md`, which was written from the live config; this description is what is dropped.
- 3
- 7
----
## Three-pane split layout with cycling and zoom  DO NOT PORT
- `conf/split.lua` builds a 33/33/33 layout on demand, `Shift+Tab` cycles panes (unzooming first), `Ctrl+Shift+Tab` toggles zoom.
- 5
- 8
----
## Neovim: self-bootstrapping config  DO NOT PORT
- `init.lua` clones `mini.nvim` on first run and installs its plugin set (vague theme, startify, noice/notify/nui, oil, lualine, devicons, go-up) through `mini.deps` — no lockfile, no external plugin manager.
- 5
- 8
----
## OpenCode configuration  DO NOT PORT
- `opencode.json` registers a local Ollama provider (`qwen3.5:27b` over `127.0.0.1:11434`, auto-launched) and the local `shard` MCP server; three custom themes (`feb`, `blink`, `poimandres`) ship alongside a bun-pinned `@opencode-ai/plugin` dependency.
- 4
- 7
----
## Just task runner  CONSOLIDATE
- `justfile` with cross-platform (`[unix]`/`[windows]`) mkdir recipes and a `run` recipe that creates `workspace/`, builds `devzsh`, and starts an interactive zsh container.
- 3
- 6
----
## F5 one-shot jump mode  DO NOT PORT
- A one-shot key table where digits 1–9 activate tabs and letters a.. activate panes left-to-right, auto-popping after a single key. Deliberately avoids `PaneSelect` because a Lua-opened modal cannot be dismissed across a tab switch. Superseded entry-for-entry by `capabilities-terminal.md`, which was written from the live config; this description is what is dropped.
- 6
- 8
----
## Cross-platform dependency bootstrap  DO NOT PORT
- `conf/bootstrap.lua` detects OS, checks for `zoxide` and `docker`, installs the missing ones via winget/brew/curl-installer, and stamps `.cache/.bootstrap` so it runs once per version bump.
- 5
- 7
----
## Recent-workspace picker
- `.cache/recent` keeps the last 20 mounted directories; `Ctrl+Shift+S` picks one into the current pane, `Ctrl+Shift+T` opens it in a new tab, with a "Recent:" indicator in the status bar while active.
- 5
- 7
----
## Neovim: shared theme + desktop-style keys  DO NOT PORT
- Colors come from a `theme_colors` module exported by WezTerm (with a full hardcoded fallback) and populate the vague theme plus terminal ANSI colors; Ctrl+C/V/Z/Shift+Z, Shift+Del, and `rlc` config reload behave like a mainstream editor.
- 5
- 7
----
## Standalone dev container image
- `user/docker/dockerfile`: Ubuntu 24.04 with ripgrep, fd, fzf, tmux, neovim, bat, eza, build tooling, Python, the Odin compiler built from source, Node 22, the `pi` coding agent plus ~20 pi-oilrig extensions, and OpenCode — running as an unprivileged `dev` user on `/workspace`.
- 7
- 8
----
## Quake-style dropdown pane  DO NOT PORT
- `Ctrl+\`` opens a 30% pane at the top inheriting the current cwd, then hides/reveals it via zoom tricks, per tab, and self-heals if the pane was closed externally.
- 6
- 7
----
## Karabiner: system-level launcher shortcuts  DO NOT PORT
- Cmd+1..9 open the corresponding pinned Dock app, Ctrl+Space maps to Spotlight, Ctrl+Tab is an app switcher inside terminals, Win+L / Alt+Ctrl+L lock or sleep, Alt+F4 closes windows; two device profiles plus dated automatic backups are versioned.
- 6
- 7
----
## Container-aware status bar  DO NOT PORT
- The left status shows `D`/`L` (docker vs local), the real path — the container workdir when inside docker, the pane cwd otherwise, with Windows drive-path fixups; right status shows the clock.
- 5
- 6
----
## Obsidian vault with Dataview dashboards  DO NOT PORT
- `.obsidian/` pins the Dataview plugin and core plugin set; `Dashboard.md` and the two `_index.md` files run DQL queries for type counts, 14-day recency, and hub ranking by inbound-link count.
- 5
- 6
----
## Background image cycling and opacity toggle  DO NOT PORT
- ~50 wallpapers in `images/`; `Ctrl+Shift+P` cycles them, `Ctrl+Shift+O` toggles the layered background off. Selection persists in `.cache/.image` and `.cache/opacity_off` across restarts.
- 4
- 5
----
## "Capsule" — per-directory Docker dev containers from the terminal  CONSOLIDATE
- `Ctrl+Shift+D` mounts the current pane's cwd into a `capsule-<dirname>` container (Ubuntu + zsh + oh-my-zsh + Node + Claude Code + OpenCode + eza), reusing a running container for fast connect and rebuilding only when the Dockerfile mtime changed; `Ctrl+Shift+B` forces a rebuild.
- 9
- 9
----
## Karabiner: Windows keyboard behaviour on macOS  DO NOT PORT
- ~70 complex-modification rules mapping Cmd→Ctrl, real Home/End/Insert semantics with shift/ctrl variants, word-wise arrows and deletes, and the whole Ctrl+A/C/V/Z/S/T/W/F set — with per-app exclusions for terminals, IDEs, remote desktops, and browsers.
- 9
- 9
----
## Credential propagation into containers
- Mounts `.ssh` read-only, `.gitconfig`, Claude and OpenCode auth/config dirs, and refreshes `git credential fill` output into `.cache/git-credentials` so containers can push without re-auth. `setup-user.sh` copies SSH keys to correct permissions, adds GitHub host keys, and creates a passwordless-sudo user.
- 8
- 8
----
## Vicky knowledge-base vault  DO NOT PORT
- `vicky/` holds a research KB: `WORKFLOW.md` (focus, rules, min-sources, routing, and the default/deep-dive/triage workflows), `sources/` and `conclusions/` corpora with `.absorbed/` for crystallized material, and `.graphifyignore` to bound graph extraction.
- 7
- 7
----
## Cross-platform Lua/shell/PowerShell parity  DO NOT PORT
- `conf/process.lua` abstracts `cmd.exe` vs `sh`, and every path/cache/mount helper handles both separators; container builds ship as both `scripts/build.sh` and `scripts/build.ps1`.
- 6
- 6
----
## kern local store and pi surface index  DO NOT PORT
- `.kern/` carries an LMDB store (`data.mdb`), a JSONL event journal, and an auto-maintained `intake/pi-surface-index.md` cataloguing ~30 pi agent tools (crew, gantt, launch, until, watch, trunk, walkie-talkie messaging, rigor, …).
- 7
- 6
----
## OpenCode theme generation from terminal colors  DO NOT PORT
- `conf/opencode_theme.lua` reads the active WezTerm scheme, generates a 12-step grayscale ramp preserving the background hue, and writes `~/.config/opencode/themes/feb.json`; a djb2 hash of `theme.lua` in `.cache/theme_hash` avoids needless rewrites. Exists to work around ConPTY stripping OSC color queries on Windows.
- 8
- 6
----
## Neovim: insert-mode-first modal inversion  DO NOT PORT
- Autocmds keep the editor in insert mode by default, `<Esc>` is disabled in insert and re-enters insert from normal, `<F24>` (remapped in hardware via Karabiner) switches to normal, tapping it twice opens the command line, and relative numbers appear only in normal mode.
- 8
- 6
----
