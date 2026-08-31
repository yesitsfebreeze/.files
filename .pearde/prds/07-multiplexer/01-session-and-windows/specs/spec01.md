---
complexity: 12
footprint:
  - home/dot_config/tmux/tmux.conf
---

# spec01 — `tmux.conf`: the terminal-integration floor

The base `~/.config/tmux/tmux.conf` every other child of 07-multiplexer
appends to: stable window and pane indices, the TERM/colour/undercurl floor
with a `screen-256color` fallback for minimal hosts, `escape-time`,
`focus-events`, OSC passthrough, and a `default-command` that starts nushell
resolved on PATH.

**What already stands** (built and measured in pass one; file is in the tree,
uncommitted): the whole file, 142 lines, loading rc 0 on tmux 3.7c with every
option reading back as intended. See `../probe/notes.md` F1, F2, F6, F7, F8,
F9, F10 for the measurements behind each line.

**What is left:** re-run the readbacks after any edit, and confirm the two
lines a reader is most likely to "tidy" are still there —
`set -g renumber-windows off` and the `if-shell` fallback both state a
DEFAULT or a conditional and both look redundant until the host without
`tmux-256color` arrives.

Do **not** add key bindings, `status-*`, `copy-mode-vi`, `set-clipboard` or
`run-shell` here: those belong to 02, 03, 04, 05 and 07 of this epic, which
append their own sections to this file.

## Acceptance

- [x] `home/dot_config/tmux/tmux.conf` exists and `tmux -L <label> -f <it> new-session -d` exits 0 with no diagnostic on stderr
- [x] `show -s default-terminal` reads `tmux-256color` when `infocmp tmux-256color` succeeds, and `screen-256color` when it does not — both arms exercised, the second by running tmux with `infocmp` off PATH
- [x] a pane's `$env.TERM` under the fallback arm reads `screen-256color`, so the fallback reaches the program and not just the option table
- [x] `show -s terminal-features` contains `*:RGB`
- [x] `show -s terminal-overrides` contains both a `*:Smulx=` and a `*:Setulc=` entry
- [x] `show -s escape-time` reads `10` and `show -s focus-events` reads `on`
- [x] `show -gw allow-passthrough` reads `on`
- [x] `show -g base-index` reads `1` and `show -gw pane-base-index` reads `1`
- [x] `show -g renumber-windows` reads `off`, and creating windows 1 and 4, adding 2, then killing 2 leaves `list-windows` reading `1:` and `4:` — indices do not slide
- [x] `show -g update-environment` contains `XDG_CONFIG_HOME`
- [x] a pane spawned by the conf reports `#{pane_current_command}` = `nu` (the `exec` in `default-command` is what makes this true, and 03-status-bar's occupied/empty tint is a format over this value)
- [x] inside that pane, `$env.XDG_CONFIG_HOME` is `$HOME/.config` and `$nu.history-path` is under it — proving the export happens BEFORE the exec, since `$nu.default-config-dir` is a launch-time constant
- [x] with `nu` off PATH the pane is still alive (`#{pane_dead}` = 0) and accepts input — the fallback arm lands in a working shell rather than a pane that opens and closes
- [x] every `-L` label the check uses is `kill-server`ed at the end, and no run touches the default tmux socket

## Verify and Proof

```sh
cd "$(git rev-parse --show-toplevel)"
C="$PWD/home/dot_config/tmux/tmux.conf"
tmux -L s1 -f "$C" new-session -d -s main -c "$HOME"
tmux -L s1 show -s | grep -E 'default-terminal|escape-time|focus-events'
tmux -L s1 show -s terminal-features; tmux -L s1 show -s terminal-overrides
tmux -L s1 show -g | grep -E '^base-index|^renumber-windows|update-environment'
tmux -L s1 show -gw | grep -E 'allow-passthrough|pane-base-index'
tmux -L s1 display -p '#{session_path} #{pane_current_command} #{window_index} #{pane_index}'
tmux -L s1 kill-server
# the two fallback arms, each on a stub PATH
D=$(mktemp -d); mkdir -p "$D/bin"
for b in sh nu tmux; do ln -sf "$(command -v $b)" "$D/bin/$b"; done   # no infocmp
env PATH="$D/bin" tmux -L s2 -f "$C" new-session -d -s main -c "$HOME"
env PATH="$D/bin" tmux -L s2 show -s default-terminal   # expect screen-256color
tmux -L s2 kill-server
```

## Proof — run 2026-08-29

Every box above is closed by `bash tests/tmux-session-and-windows.sh --load`
and `--fallback` (spec03), which run tmux rather than reading the file:

```
PASS  lint: every tmux call in this script is -L-labelled
PASS  lint: no byte match of Smulx/Setulc against the conf source
PASS  lint: no chk label runs a command substitution beside a bare $?
PASS  load: new-session -d exits 0
PASS  load: nothing on stderr ()
PASS  load: default-terminal = tmux-256color (got tmux-256color), infocmp present
PASS  load: terminal-features carries *:RGB
PASS  load: terminal-overrides carries a *:Smulx= entry (loaded value, not file bytes)
PASS  load: terminal-overrides carries a *:Setulc= entry (loaded value, not file bytes)
PASS  load: escape-time = 10 (got 10)
PASS  load: focus-events = on (got on)
PASS  load: allow-passthrough = on (got on)
PASS  load: base-index = 1 (got 1)
PASS  load: pane-base-index = 1 (got 1)
PASS  load: renumber-windows = off (got off)
PASS  load: update-environment names XDG_CONFIG_HOME, so a reattach carries it
PASS  load: after creating 1,4 then adding and killing 2, indices read '1 4' (got '1 4') — they do not slide
PASS  load: the conf-spawned pane runs nu (#{pane_current_command} = nu)
PASS  load: the pane's $env.XDG_CONFIG_HOME is $HOME/.config (got /Users/feb/.config)
PASS  load: the pane's $nu.history-path is under $HOME/.config (got /Users/feb/.config/nushell/history.sqlite3) — the export beat the exec
PASS  load: the label is killed at the end of the stage
PASS  fallback A: the conf loads with infocmp off PATH
PASS  fallback A: nothing on stderr ()
PASS  fallback A: default-terminal falls back to screen-256color (got screen-256color)
PASS  fallback A: the pane's $env.TERM is screen-256color (got screen-256color) — the fallback reached the program
PASS  fallback B: the conf loads with nu off PATH
PASS  fallback B: the pane is alive (#{pane_dead} = 0) — it did not open and close
PASS  fallback B: the pane accepts input — the arm landed in a working shell
```

`--load` rc 0, `--fallback` rc 0, and `tmux ls` after the run reads
`no server running on /private/tmp/tmux-501/default` — no label leaked onto
the default socket.

One correction to the spec's own reasoning, measured while writing the gate
(probe `F16`): **tmux 3.7c's built-in default for `default-terminal` is
already `tmux-256color`**, so deleting the `if-shell` is not a falsifying
mutation. The line earns its place on the OTHER arm — a hardcoded
`tmux-256color` does not fall back with `infocmp` off PATH, and that is the
red the gate now runs.
