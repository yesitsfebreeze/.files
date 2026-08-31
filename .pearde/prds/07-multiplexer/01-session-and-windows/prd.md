---
state: done        # open|analyzing|refine|question|specced|claimed|blocked|done|failed
origin: requested  # requested = the user asked | derived = the board found it
# from:            # derived only — the PRD whose work surfaced this one
priority: 20        # higher first
complexity: 32      # analyst, at spec time — 1-100. THE WEIGHT the board schedules by
blast-radius: high
repo:              # the sub-repo the code lands in; delete if n/a
# workflow:        # OPTIONAL — how this kind of job is done: a slug in
#                  #   prds/workflows/. @references/workflow.md.
#                  #   Absent = the brief alone, as before workflows
time:              # OPTIONAL. See @references/parts/order.md
  est:             # the weight, only when complexity is absent. Not a duration
  actual: 11.62h
  # claim: <worker> <started>   # orchestrator-only, present while a worker holds this PRD
commit: 910c35b
---
<!-- Ordering reads three axes and no clock: dependency (needs + footprint),
     vision importance (priority), and complexity/blast-radius. Add your own
     keys freely, at any nesting. Nothing outside state, origin, from,
     priority, complexity, blast-radius, claim, repo, workflow, needs and
     footprint is read, and nothing you add is ever dropped.
       needs:     — PRD dir names this one depends on. A hard gate in `plan`
       footprint: — paths this PRD touches. The overlap check
       workflow:  — the route a worker is handed, expanded into its brief

     One sitting is the limit: specs summing `complexity` above `split-above`
     or counting above `specs-above` (both in prds/settings.md, default 40 and
     6) make the analyst's verdict REFINE, and `pearde refine` lands the split
     under `## Children` here — the contract above it stays as written.

     A derived PRD states, in the body, which requested PRD it would otherwise
     get wrong. If it cannot, it is filed `state: deferred` — and if fixing it
     would change only how loudly the board notices, it is a memo, not a PRD.
     See @references/parts/derived.md. -->

# 01-session-and-windows — The tmux base: one session `main` reached by an idempotent `new-session -A -s main`, stable window indices (`base-index 1`, `renumber-windows off`), and the terminal-integration floor every other child sits on — `tmux-256color` with a `screen-256color` fallback for minimal hosts, `*:RGB` and undercurl overrides, `escape-time 10` so Esc does not lag in nvim, `focus-events on`, OSC passthrough. `default-command` starts nushell resolved on PATH with a fallback, never the absolute launchd-era path, because a remote's nu is somewhere else. Lazily created windows start at `~` (Q14).

The tmux base: one session `main` reached by an idempotent `new-session -A -s main`, stable window indices (`base-index 1`, `renumber-windows off`), and the terminal-integration floor every other child sits on — `tmux-256color` with a `screen-256color` fallback for minimal hosts, `*:RGB` and undercurl overrides, `escape-time 10` so Esc does not lag in nvim, `focus-events on`, OSC passthrough. `default-command` starts nushell resolved on PATH with a fallback, never the absolute launchd-era path, because a remote's nu is somewhere else. Lazily created windows start at `~` (Q14).

<!-- Three more headings exist, and none of them is a slot to copy down. Each
     is a claim about the state of this PRD, so an empty copy of it is a false
     one: an empty `## Questions` stops the board on nothing, an empty
     `## Answers` reads as answered, an empty `## Failure` reads as a failed
     attempt. Write the heading when it has content; until then it is absent,
     which is the honest state. @resources/questions.py reports the empty
     ones, and `doctor`'s `questions` row runs it. -->

<!-- `## Questions` — analyst-only, when blocked on the user: one round in the
     format of drill.md — `### Q1: <title>`, the fork in 1-3 sentences ending
     in "?", then exactly three prepared answers, each a complete decision,
     one `(recommended)`. Only real forks the user must settle (naming, scope,
     cost) — never facts a worker could look up, never the PRD restated. A PRD
     parked on the user with no such round never says what it is asking. -->

<!-- `## Answers` — orchestrator-only (or the view), written after asking the
     user: `**Q1** — <the picked answer verbatim, or the user's own words>`,
     numbers matching the round above it. Analysts read these before speccing.
     An `## Answers` with no `## Questions` above it answers nothing. -->

<!-- `## Failure` — implementer-only, after a FAILED attempt: what broke, what
     was tried. `retry` moves this into the body as history and reopens the
     PRD. -->

## Report

spec01: exit 0
default-terminal tmux-256color
escape-time 10
focus-events on
terminal-features[0] xterm*:clipboard:ccolour:cstyle:focus:title
terminal-features[1] screen*:title
terminal-features[2] rxvt*:ignorefkeys
terminal-features[3] *:RGB
terminal-overrides[0] linux*:AX@
terminal-overrides[1] "*:Smulx=\\E[4::%p1%dm"
terminal-overrides[2] "*:Setulc=\\E[58::2::%p1%{65536}/%d::%p1%{256}/%%{256}/%d::%p1%{256}%%{256}%d%;m"
base-index 1
renumber-windows off
update-environment[0] DISPLAY
update-environment[1] KRB5CCNAME
update-environment[2] MSYSTEM
update-environment[3] SSH_ASKPASS
update-environment[4] SSH_AUTH_SOCK
update-environment[5] SSH_AGENT_PID
update-environment[6] SSH_CONNECTION
update-environment[7] WAYLAND_DISPLAY
update-environment[8] WINDOWID
update-environment[9] XAUTHORITY
update-environment[10] XDG_CURRENT_DESKTOP
update-environment[11] XDG_SESSION_DESKTOP
update-environment[12] XDG_SESSION_TYPE
update-environment[13] XDG_CONFIG_HOME
allow-passthrough on
pane-base-index 1
/Users/feb nu 1 1
default-terminal screen-256color

spec02: exit 0
sh -n OK
-rwxr-xr-x
10:# `new-session -A -s main` is idempotent by construction: it attaches to
46:exec tmux new-session -A -s main -c "$HOME" "$@"
15:# `-c "$HOME"` is Q14, and it is NOT decoration. Measured on tmux 3.7c: a
46:exec tmux new-session -A -s main -c "$HOME" "$@"
/Users/feb
/Users/feb/dev/dotfiles
       1
tmux-main: tmux is not installed; falling back to a plain shell.
tmux-main: install it — tmux is a hard dependency of this config.

spec03: exit 0
PASS  precondition: home/dot_config/tmux/tmux.conf exists
PASS  precondition: home/dot_local/bin/executable_tmux-main exists
PASS  lint: every tmux call in this script is -L-labelled
PASS  lint: no byte match of Smulx/Setulc against the conf source
PASS  lint: no chk label runs a command substitution beside a bare $?
── stage --load: the conf loads and every option reads back ─────────
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
── stage --fallback: both arms, on stub PATHs ───────────────────────
PASS  fallback A: the conf loads with infocmp off PATH
PASS  fallback A: nothing on stderr ()
PASS  fallback A: default-terminal falls back to screen-256color (got screen-256color)
PASS  fallback A: the pane's $env.TERM is screen-256color (got screen-256color) — the fallback reached the program
PASS  fallback B: the conf loads with nu off PATH
PASS  fallback B: the pane is alive (#{pane_dead} = 0) — it did not open and close
PASS  fallback B: the pane accepts input — the arm landed in a working shell
── stage --session: the launcher, and Q14 through real key dispatch ──
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
── stage --deploy: chezmoi maps both files to their targets ──────────
      guard[deploy] watching /Users/feb/.config/chezmoi/chezmoi.toml
      guard[deploy] sha256 in       = 02d5d4ee50b5d37955ffe7778938ddee82f4da24cbaf552b4dba3810d3c850a1
      guard[deploy] source-path in  = /Users/feb/dev/.files/home
PASS  deploy: the isolated apply exits 0
PASS  deploy: home/dot_config/tmux/tmux.conf -> ~/.config/tmux/tmux.conf
PASS  deploy: home/dot_local/bin/executable_tmux-main -> ~/.local/bin/tmux-main
PASS  deploy: the deployed tmux-main is mode 0755 (got 755) — the executable_ prefix carries it
PASS  deploy: the deployed conf is byte-identical to the source — it is not a template
PASS  deploy: chezmoi target-path agrees, so the launcher's bare tmux reads it (got <scratch>/deploy/dest/.config/tmux/tmux.conf)
PASS  deploy: the developer's real ~/.config/tmux and ~/.local/bin/tmux-main untouched
PASS  deploy: no bare chezmoi call in this script
      guard[deploy] sha256 out      = 02d5d4ee50b5d37955ffe7778938ddee82f4da24cbaf552b4dba3810d3c850a1
      guard[deploy] source-path out = /Users/feb/dev/.files/home
PASS  deploy: LIVE chezmoi.toml unchanged (02d5d4ee50b5d37955ffe7778938ddee82f4da24cbaf552b4dba3810d3c850a1)
PASS  deploy: LIVE chezmoi source-path unchanged (/Users/feb/dev/.files/home)
PASS  precondition: home/dot_config/tmux/tmux.conf exists
PASS  precondition: home/dot_local/bin/executable_tmux-main exists
PASS  lint: every tmux call in this script is -L-labelled
PASS  lint: no byte match of Smulx/Setulc against the conf source
PASS  lint: no chk label runs a command substitution beside a bare $?
── stage --load: the conf loads and every option reads back ─────────
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
PASS  precondition: home/dot_config/tmux/tmux.conf exists
PASS  precondition: home/dot_local/bin/executable_tmux-main exists
── stage --fallback: both arms, on stub PATHs ───────────────────────
PASS  fallback A: the conf loads with infocmp off PATH
PASS  fallback A: nothing on stderr ()
PASS  fallback A: default-terminal falls back to screen-256color (got screen-256color)
PASS  fallback A: the pane's $env.TERM is screen-256color (got screen-256color) — the fallback reached the program
PASS  fallback B: the conf loads with nu off PATH
PASS  fallback B: the pane is alive (#{pane_dead} = 0) — it did not open and close
PASS  fallback B: the pane accepts input — the arm landed in a working shell
PASS  precondition: home/dot_config/tmux/tmux.conf exists
PASS  precondition: home/dot_local/bin/executable_tmux-main exists
── stage --session: the launcher, and Q14 through real key dispatch ──
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
PASS  precondition: home/dot_config/tmux/tmux.conf exists
PASS  precondition: home/dot_local/bin/executable_tmux-main exists
── stage --deploy: chezmoi maps both files to their targets ──────────
      guard[deploy] watching /Users/feb/.config/chezmoi/chezmoi.toml
      guard[deploy] sha256 in       = 02d5d4ee50b5d37955ffe7778938ddee82f4da24cbaf552b4dba3810d3c850a1
      guard[deploy] source-path in  = /Users/feb/dev/.files/home
PASS  deploy: the isolated apply exits 0
PASS  deploy: home/dot_config/tmux/tmux.conf -> ~/.config/tmux/tmux.conf
PASS  deploy: home/dot_local/bin/executable_tmux-main -> ~/.local/bin/tmux-main
PASS  deploy: the deployed tmux-main is mode 0755 (got 755) — the executable_ prefix carries it
PASS  deploy: the deployed conf is byte-identical to the source — it is not a template
PASS  deploy: chezmoi target-path agrees, so the launcher's bare tmux reads it (got <scratch>/deploy/dest/.config/tmux/tmux.conf)
PASS  deploy: the developer's real ~/.config/tmux and ~/.local/bin/tmux-main untouched
PASS  deploy: no bare chezmoi call in this script
      guard[deploy] sha256 out      = 02d5d4ee50b5d37955ffe7778938ddee82f4da24cbaf552b4dba3810d3c850a1
      guard[deploy] source-path out = /Users/feb/dev/.files/home
PASS  deploy: LIVE chezmoi.toml unchanged (02d5d4ee50b5d37955ffe7778938ddee82f4da24cbaf552b4dba3810d3c850a1)
PASS  deploy: LIVE chezmoi source-path unchanged (/Users/feb/dev/.files/home)
PASS  precondition: home/dot_config/tmux/tmux.conf exists
PASS  precondition: home/dot_local/bin/executable_tmux-main exists
── stage --selftest: every stage proven by breaking it ──────────────
MUTATION HOST: /private/var/folders/_p/tzmzw3m10kg7sg9hc7_mkm7w0000gn/T/gates.39rBmI/st
PASS  selftest GREEN: an unmutated copy still reads tmux-256color (got tmux-256color)
PASS  selftest GREEN: an unmutated copy still reads escape-time 10 (got 10)
MUTATION: /private/var/folders/_p/tzmzw3m10kg7sg9hc7_mkm7w0000gn/T/gates.39rBmI/st/hardcoded.conf — the if-shell collapsed to an unconditional tmux-256color
PASS  selftest: the TERM-floor mutation actually changed the file
PASS  selftest: the mutated conf has no if-shell left
PASS  selftest RED: a hardcoded arm does NOT fall back with infocmp off PATH (got tmux-256color) — the if-shell is what does
MUTATION: /private/var/folders/_p/tzmzw3m10kg7sg9hc7_mkm7w0000gn/T/gates.39rBmI/st/slow.conf — escape-time set to 500
PASS  selftest: the escape-time mutation actually changed the file
PASS  selftest RED: a conf with escape-time 500 does not read 10 (got 500)
MUTATION: /private/var/folders/_p/tzmzw3m10kg7sg9hc7_mkm7w0000gn/T/gates.39rBmI/st/nopass.conf — allow-passthrough set to off
PASS  selftest: the allow-passthrough mutation actually changed the file
PASS  selftest RED: a conf with allow-passthrough off does not read on (got off)
MUTATION: /private/var/folders/_p/tzmzw3m10kg7sg9hc7_mkm7w0000gn/T/gates.39rBmI/st/renum.conf — renumber-windows set to on
PASS  selftest: the renumber-windows mutation actually changed the file
PASS  selftest RED: with renumber-windows on the indices slide (got '1 2', not '1 4')
MUTATION: /private/var/folders/_p/tzmzw3m10kg7sg9hc7_mkm7w0000gn/T/gates.39rBmI/st/nocmd.conf — the default-command line deleted
PASS  selftest: the default-command mutation actually changed the file
PASS  selftest RED: without default-command the pane does not run nu (got zsh)
MUTATION: /private/var/folders/_p/tzmzw3m10kg7sg9hc7_mkm7w0000gn/T/gates.39rBmI/st/noxdg.conf — the XDG_CONFIG_HOME export dropped from default-command
PASS  selftest: the XDG export mutation actually changed the file
PASS  selftest RED: a conf exporting a different XDG_CONFIG_HOME is seen in the pane (got /tmp/t1sw-not-config)
MUTATION: /private/var/folders/_p/tzmzw3m10kg7sg9hc7_mkm7w0000gn/T/gates.39rBmI/st/tmux-main-noc — the launcher's -c "$HOME" removed
PASS  selftest: the launcher mutation actually changed the file
PASS  selftest: the mutated launcher no longer passes -c "$HOME" in code
PASS  selftest RED: without -c "$HOME" the key-bound new-window misses $HOME (got <scratch>/st/client)
MUTATION: /private/var/folders/_p/tzmzw3m10kg7sg9hc7_mkm7w0000gn/T/gates.39rBmI/st/unlabelled.sh — a copy of this gate with an unlabelled tmux call
PASS  selftest RED: a copy with a bare 'tmux kill-server' fails the -L lint
PASS  selftest GREEN: this script itself passes the -L lint
MUTATION: /private/var/folders/_p/tzmzw3m10kg7sg9hc7_mkm7w0000gn/T/gates.39rBmI/st/falsepass.sh — a copy with a $( ) in a chk label beside $?
PASS  selftest RED: a copy with a command substitution in a chk label is caught
PASS  selftest GREEN: this script itself passes the status lint
MUTATION: /private/var/folders/_p/tzmzw3m10kg7sg9hc7_mkm7w0000gn/T/gates.39rBmI/st/bytematch.sh — a copy grepping Smulx out of the source
PASS  selftest RED: a copy byte-matching Smulx against the conf is caught
PASS  selftest: no mutation landed in the repo — every one is under the scratch root
PASS  selftest: the real tmux.conf is unchanged after every mutation
FAIL  contract: tree-links.sh accepts --selftest and exits 0 (rc 1)
FAIL  contract: manual-coverage.sh accepts --selftest and exits 0 (rc 1)
FAIL  contract: wave-status.sh accepts --selftest and exits 0 (rc 1)
delta ok: this script causes no selftest failure
default socket clean
