---
complexity: 6
footprint:
  - home/dot_local/bin/executable_tmux-main
---

# spec02 — `tmux-main`: the idempotent attach, and Q14's `~`

One entry point into the session, deployed as `~/.local/bin/tmux-main`, so the
spelling of the attach lives in exactly one place: WezTerm's `default_prog`
(08-wezterm-reduction), an ssh login, and anything else that wants the session
all say `tmux-main` instead of repeating flags that then drift.

It is `exec tmux new-session -A -s main -c "$HOME" "$@"`, POSIX sh.

**Why the script exists rather than a literal in `default_prog`**: `-c "$HOME"`
is the entire mechanism behind Q14. Measured on tmux 3.7c (`../probe/notes.md`
F14, which corrects a first reading that could not tell two of the cases
apart): `new-window` with no `-c` resolves its cwd from WHO ran it — the
pane's cwd when typed in a shell, the client's when run from outside tmux, and
**the session's working directory when it comes from a key binding**. The
fourth is the only one a person triggers, since `F5 <digit>` is a binding.
tmux has had no `default-path` option since 1.9, so "a lazily created window
starts at `~`" is a property of how the session was CREATED. A conf file
cannot deliver it. `-c` is read only at creation and
ignored on an attach, which is correct — the session keeps the directory it
was born with.

**What already stands**: the file is in the tree, uncommitted, 46 lines,
`sh -n` clean. Create path, session path, and the no-tmux arm all measured
(F11). The no-tmux arm prints two lines naming tmux as a hard dependency and
then execs nu — repeating tmux.conf's `XDG_CONFIG_HOME` export on purpose,
because that arm runs when `tmux.conf` is never read at all.

**What is left**: the attach path needs a pty to exercise (see the box), and
`chmod +x` must survive — chezmoi takes the mode from the `executable_` source
prefix, so the bit is not something to set by hand on the target.

## Acceptance

- [x] `sh -n home/dot_local/bin/executable_tmux-main` exits 0
- [x] the file contains `new-session -A -s main` and `-c "$HOME"`, and the exec is `exec tmux …` — one process, not a wrapper left in the tree
- [x] the source file is mode 0755 in the repo, so chezmoi deploys `~/.local/bin/tmux-main` executable
- [x] run against a scratch `-L` socket it creates session `main` with `#{session_path}` = `$HOME`
- [x] a `new-window` fired **from a key binding** in that session lands at `$HOME` — Q14, and the box spec01 cannot close because it is not a property of the conf. It must be driven through real key dispatch (an outer tmux whose pane runs `tmux -L <inner> attach`, then `send-keys` to the OUTER pane); `send-keys` to the inner pane tests the shell, not the binding, and gives the pane's cwd instead
- [x] run a second time it does not create a second session: `list-sessions` still shows exactly one `main`
- [x] driven through a pty (`script -q /dev/null`), the second run attaches rather than printing `open terminal failed: not a terminal`
- [x] with `tmux` off PATH it prints a message naming tmux as a required dependency on stderr and execs a working shell — never exits into nothing, because an emulator whose spawn dies leaves a pane you cannot type into
- [x] the no-tmux arm exports `XDG_CONFIG_HOME` before exec'ing nu, and passes `--config`/`--env-config`
- [x] it names no absolute path to `nu` or `tmux` — both are resolved on PATH, because on a remote they are somewhere else

## Verify and Proof

```sh
cd "$(git rev-parse --show-toplevel)"
L="$PWD/home/dot_local/bin/executable_tmux-main"
sh -n "$L" && echo "sh -n OK"
ls -l "$L" | cut -c1-10          # expect -rwxr-xr-x
grep -n 'new-session -A -s main' "$L"; grep -n 'c "\$HOME"' "$L"
env TMUX= tmux_main_socket=m1 sh -c "exec tmux -L m1 new-session -A -s main -c \"\$HOME\" -d"
tmux -L m1 display -p '#{session_path}'
tmux -L m1 new-window; tmux -L m1 display -p '#{pane_current_path}'   # expect $HOME
tmux -L m1 list-sessions | wc -l                                      # expect 1
tmux -L m1 kill-server
D=$(mktemp -d); mkdir -p "$D/bin"; ln -sf "$(command -v sh)" "$D/bin/sh"
env PATH="$D/bin" SHELL=/bin/sh sh "$L" 2>&1 | head -3   # the no-tmux arm
```

## Proof — run 2026-08-29

Closed by `bash tests/tmux-session-and-windows.sh --session` (spec03), rc 0:

```
PASS  session: sh -n on the launcher exits 0
PASS  session: it spells the idempotent attach, new-session -A -s main
PASS  session: it passes -c "$HOME" — the whole mechanism behind Q14
PASS  session: the tmux call is an exec — one process, not a wrapper left in the tree
PASS  session: the source file is mode 0755 (got 755), so chezmoi deploys it executable
PASS  session: it names no absolute path to nu or tmux — both resolve on PATH
PASS  session: the no-tmux arm exports XDG_CONFIG_HOME
PASS  session: the no-tmux arm passes --config/--env-config to nu
PASS  session: the launcher creates the session (rc 0)
PASS  session: #{session_path} is $HOME (got /Users/feb)
PASS  session: a second run creates no second session (list-sessions = 1)
PASS  session: through a pty the second run attaches, no 'open terminal failed'
PASS  session: the pty run is an attached client (list-clients = 1)
PASS  session: still exactly one session after the attach (got 1)
PASS  session: the nested fixture's inner session was created by the launcher
PASS  session: fixture — the ACTIVE pane sits in a third directory (got <scratch>/sess/pane)
PASS  session: fixture — an outer tmux is attached to the inner one
PASS  session: Q14 — a new-window from a REAL KEY BINDING lands at $HOME (got /Users/feb), not the pane's <scratch>/sess/pane nor the client's <scratch>/sess/client
PASS  session: with tmux off PATH it names tmux on stderr
PASS  session: the message says tmux is a required dependency
PASS  session: the no-tmux arm exec'd a shell that runs commands — never exits into nothing
```

Q14 is the seventeenth line: a `new-window` from a REAL KEY BINDING, driven
through a nested tmux, lands at `$HOME` while the active pane sits in one
scratch directory and the client in another — the three-way fixture F14
requires. Its counterfactual is under `--selftest`: with `-c "$HOME"`
removed from the launcher the same keystroke lands in the CLIENT's directory.

One measurement the spec did not have (probe `F17`): `script -q /dev/null`
with `< /dev/null` forwards a `^D` into the pty, which kills the pane's
shell and takes the server with it, and a fifo on stdin is refused outright by
macOS `script`. The attach is measured under `remain-on-exit on` instead.
