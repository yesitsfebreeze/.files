---
state: done        # open|analyzing|refine|question|specced|claimed|blocked|done|failed
origin: requested  # requested = the user asked | derived = the board found it
# from:            # derived only — the PRD whose work surfaced this one
priority: 15        # higher first
complexity: 24      # analyst, at spec time — 1-100. THE WEIGHT the board schedules by
blast-radius: mid
repo:              # the sub-repo the code lands in; delete if n/a
# workflow:        # OPTIONAL — how this kind of job is done: a slug in
#                  #   prds/workflows/. @references/workflow.md.
#                  #   Absent = the brief alone, as before workflows
time:              # OPTIONAL. See @references/parts/order.md
  est:             # the weight, only when complexity is absent. Not a duration
  actual: 0.69h
  # claim: <worker> <started>   # orchestrator-only, present while a worker holds this PRD
needs:
commit: 185585e
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

# 01-tmux-mcp — the tmux MCP server

The tmux MCP server that gives Claude Code structured control over tmux
panes and windows. `tmux-mcp` (MadAppGang) is installed and registered as an
MCP server in `~/.claude/settings.json` with `--shell-type bash --scope
agentic`, so Claude can create sessions, split panes, send keys, run commands
and watch for readiness patterns through 20 structured tools instead of
parsing `tmux list-panes` output itself.

The nushell exit-code caveat is a constraint, not a bug to fix: `--shell-type`
supports `bash|zsh|fish`, the panes this environment spawns run nushell, so
`execute-command` exit codes are unreliable and agent workflows rely on
output-pattern monitoring (`start-and-watch` matches readiness patterns in
output, not exit codes).

## Constraints

- **`--shell-type` cannot be nushell.** The panes run nushell
  (`default-command`, 07-multiplexer). Exit codes from `execute-command` are
  unreliable; `start-and-watch` readiness patterns are the honest path. No
  box may claim exit codes work.
- **`~/.claude` is not chezmoi-managed.** The MCP entry lands in
  `~/.claude/settings.json` by a run_after script or a documented manual
  step — never by editing a file in `home/`.
- **The binary needs a home.** `go install` requires Go; a pre-built release
  binary is the alternative. The `install.sh` obligation names which, in the
  same place 05-platform/01-deploy-mechanism already carries its obligations.

## Non-goals

- No nushell support in tmux-mcp — out of our control.
- No changes to the `cc`/`cr` launchers or the profile model
  (04-shell/08, done).

## Pointers

- `home/dot_config/nushell/claude.nu` — the launchers and profile model.
- `install.sh` — where the install obligation lands.
- MadAppGang/tmux-mcp README — the tool list, `--shell-type`/`--scope` flags,
  and the exit-code caveat.

## Report

spec01: exit 0
DRY chezmoi apply
PASS  precondition: /usr/bin/sed exists (the one read the script makes)
PASS  precondition: install.sh is present at /Users/feb/dev/dotfiles/install.sh
── stage: shape
      guard[shape] watching /Users/feb/.config/chezmoi/chezmoi.toml
      guard[shape] sha256 in       = 02d5d4ee50b5d37955ffe7778938ddee82f4da24cbaf552b4dba3810d3c850a1
      guard[shape] source-path in  = /Users/feb/dev/.files/home
PASS  shape: install.sh exists at the repo root
PASS  shape: install.sh is executable
PASS  shape: bash -n install.sh parses
PASS  shape: set line has u and o pipefail
PASS  shape: set line does NOT contain e (R5: never abort, deliberately no -e)
PASS  shape: no bare `eval "$(` anywhere — the incident line shape
PASS  shape: exports a PATH naming $HOME/.local/bin
PASS  shape: exports a PATH naming $HOME/.cargo/bin
PASS  shape: export PATH (line 141) precedes install section 1 (line 284)
PASS  shape: hash -r after the shellenv eval (bash caches resolved paths)
PASS  shape: structural lint finds no unwrapped mutating command
PASS  shape: the lint DOES fire on an appended bare `brew install foo`
PASS  shape: PKGS parses to a non-empty binary set (25) — the precondition for the pairing check below
PASS  shape: every PKGS binary is provided to the provisioned bin (missing: <none>) — PROV_BINS plus the named exceptions, so the lists cannot silently disagree
PASS  shape: the pairing check DOES fire on a PKGS row with no declared binary (caught: nosuchbinary)
PASS  shape/fresh: no REAL-INVOCATION — the seam held
PASS  shape/fresh: exits 0
PASS  shape/fresh: the Homebrew-installer line is present
PASS  shape/fresh: the shellenv seam line is present
PASS  shape/fresh: a batch brew install line is present
PASS  shape/fresh: order installer(1) < shellenv(3) < brew install(4)
PASS  shape/fresh: 'DRY chezmoi apply' is the LAST DRY line (epic I1)
PASS  shape/provisioned: no REAL-INVOCATION — the seam held
PASS  shape/prov: exits 0
PASS  shape/prov: NO Homebrew-installer line (R8: guards, not a hash gate)
PASS  shape/prov: NO per-package brew install line (got 0)
PASS  shape/prov: the batch line still runs
PASS  shape/prov: chezmoi apply still runs
PASS  shape/fail: no REAL-INVOCATION — the seam held
PASS  shape/fail: with INSTALL_DRY_FAIL=install the run still exits 0 (R5)
PASS  shape/fail: at least one !! warn line (got 29)
PASS  shape/fail: still reaches chezmoi apply
      guard[shape] sha256 out      = 02d5d4ee50b5d37955ffe7778938ddee82f4da24cbaf552b4dba3810d3c850a1
      guard[shape] source-path out = /Users/feb/dev/.files/home
PASS  shape: LIVE chezmoi.toml unchanged (02d5d4ee50b5d37955ffe7778938ddee82f4da24cbaf552b4dba3810d3c850a1)
PASS  shape: LIVE chezmoi source-path unchanged (/Users/feb/dev/.files/home)
── stage: packages
      guard[packages] watching /Users/feb/.config/chezmoi/chezmoi.toml
      guard[packages] sha256 in       = 02d5d4ee50b5d37955ffe7778938ddee82f4da24cbaf552b4dba3810d3c850a1
      guard[packages] source-path in  = /Users/feb/dev/.files/home
PASS  packages: install.sh exists
PASS  packages: the formula=binary list carries gnupg=gpg
PASS  packages: it does NOT carry gnupg=gnupg
PASS  packages: it carries git-delta=delta
PASS  packages: it carries tmux=tmux (07-multiplexer's host dependency)
PASS  packages/fresh: no REAL-INVOCATION — the seam held
PASS  packages/fresh: exits 0
PASS  packages/fresh: batch set is a superset of R7's required set (R7)
PASS  packages/fresh: tinty is satisfied on the RELEASE rung (in no package manager)
PASS  packages/fresh: the cask is installed when its Caskroom entry is absent
PASS  packages/prov: no REAL-INVOCATION — the seam held
PASS  packages/prov: the cask line is absent once the Caskroom entry exists
PASS  packages/prov: no tinty release line once tinty resolves on PATH
PASS  packages/retry: no REAL-INVOCATION — the seam held
PASS  packages/retry: exits 0
PASS  packages/retry: one single-package brew install per PKGS entry (25 of 25) — a bare batch aborts on the first unknown formula and never attempts the rest
PASS  packages/retry: at least one !! warn line per retried package (29 >= 25)
PASS  packages/retry: the retries follow the failed batch (4 < 6)
PASS  packages/linux: no REAL-INVOCATION — the seam held
PASS  packages/linux: exits 0
PASS  packages/linux: takes the apt branch
PASS  packages/linux: does not touch pacman
PASS  packages/linux: does not touch dnf
PASS  packages/linux: batcat -> bat symlink
PASS  packages/linux: fdfind -> fd symlink
PASS  packages/linux: release rung installs tv
PASS  packages/linux: release rung installs nu
PASS  packages/linux: release rung installs gh
PASS  packages/linux: release rung installs lazygit
PASS  packages/linux: release rung installs starship
PASS  packages/linux: release rung installs tinty
PASS  packages/linux: apt carries tmux
PASS  packages/linux: no brew on Linux
PASS  packages/nopkgmgr: no REAL-INVOCATION — the seam held
PASS  packages/nopkgmgr: exits 0 with no package manager present (R5)
PASS  packages/nopkgmgr: warns that no package manager was found
PASS  packages/notag: no REAL-INVOCATION — the seam held
PASS  packages/notag: exits 0
PASS  packages/notag: an unresolvable tag WARNS and names the repo
PASS  packages/notag: and installs nothing from the bad tag
      guard[packages] sha256 out      = 02d5d4ee50b5d37955ffe7778938ddee82f4da24cbaf552b4dba3810d3c850a1
      guard[packages] source-path out = /Users/feb/dev/.files/home
PASS  packages: LIVE chezmoi.toml unchanged (02d5d4ee50b5d37955ffe7778938ddee82f4da24cbaf552b4dba3810d3c850a1)
PASS  packages: LIVE chezmoi source-path unchanged (/Users/feb/dev/.files/home)
── stage: nvim
      guard[nvim] watching /Users/feb/.config/chezmoi/chezmoi.toml
      guard[nvim] sha256 in       = 02d5d4ee50b5d37955ffe7778938ddee82f4da24cbaf552b4dba3810d3c850a1
      guard[nvim] source-path in  = /Users/feb/dev/.files/home
PASS  nvim: install.sh exists
PASS  nvim: NVIM_MIN_MINOR=11 declared exactly once (got 1)
PASS  nvim: the number appears nowhere else in the file — messages interpolate the constant
PASS  nvim/absent: no REAL-INVOCATION — the seam held
PASS  nvim/absent: exits 0
PASS  nvim/absent: the release override is taken
PASS  nvim/absent: the message names 0.11, interpolated from the constant
PASS  nvim/NVIM v0.9.5: no REAL-INVOCATION — the seam held
PASS  nvim/'NVIM v0.9.5': exits 0
PASS  nvim/'NVIM v0.9.5': override TAKEN
PASS  nvim/'NVIM v0.9.5': no 'integer expression expected' anywhere
PASS  nvim/NVIM v0.11.0: no REAL-INVOCATION — the seam held
PASS  nvim/'NVIM v0.11.0': exits 0
PASS  nvim/'NVIM v0.11.0': override NOT taken
PASS  nvim/'NVIM v0.11.0': no 'integer expression expected' anywhere
PASS  nvim/NVIM v0.12.4: no REAL-INVOCATION — the seam held
PASS  nvim/'NVIM v0.12.4': exits 0
PASS  nvim/'NVIM v0.12.4': override NOT taken
PASS  nvim/'NVIM v0.12.4': no 'integer expression expected' anywhere
PASS  nvim/NVIM v1.0.0: no REAL-INVOCATION — the seam held
PASS  nvim/'NVIM v1.0.0': exits 0
PASS  nvim/'NVIM v1.0.0': override NOT taken
PASS  nvim/'NVIM v1.0.0': no 'integer expression expected' anywhere
PASS  nvim/NVIM banana: no REAL-INVOCATION — the seam held
PASS  nvim/'NVIM banana': exits 0
PASS  nvim/'NVIM banana': override TAKEN
PASS  nvim/'NVIM banana': no 'integer expression expected' anywhere
PASS  nvim/os-Darwin: no REAL-INVOCATION — the seam held
PASS  nvim/Darwin: 0.9.5 takes the override on Darwin too — the floor is not OS-gated
PASS  nvim/os-Linux: no REAL-INVOCATION — the seam held
PASS  nvim/Linux: 0.9.5 takes the override on Linux too — the floor is not OS-gated
PASS  nvim/shadow: no REAL-INVOCATION — the seam held
PASS  nvim/shadow: exits 0 with the override forced to fail (R5)
PASS  nvim/shadow: warns that nvim is below the 0.11 floor
PASS  nvim/shadow: still reaches chezmoi apply
      guard[nvim] sha256 out      = 02d5d4ee50b5d37955ffe7778938ddee82f4da24cbaf552b4dba3810d3c850a1
      guard[nvim] source-path out = /Users/feb/dev/.files/home
PASS  nvim: LIVE chezmoi.toml unchanged (02d5d4ee50b5d37955ffe7778938ddee82f4da24cbaf552b4dba3810d3c850a1)
PASS  nvim: LIVE chezmoi source-path unchanged (/Users/feb/dev/.files/home)
── counterfactuals
PASS  counterfactual: --shape goes red with install.sh missing
PASS  counterfactual: --packages goes red with one R7 name deleted from PKGS
PASS  counterfactual: --nvim goes red with the floor lowered to 9
PASS  the gate wrote nothing outside its scratch (sha256 over prds, docs, gates, tests, home, install.sh)
PASS  the gate added no file to the repo root
1.7.1

spec02: exit 0
tmux-mcp:
  Scope: User config (available in all your projects)
  Status: ✔ Connected
  Type: stdio
  Command: /Users/feb/.local/bin/tmux-mcp
  Args: -shell-type bash -scope agentic
  Environment:

To remove this server, run: claude mcp remove tmux-mcp -s user
{'type': 'stdio', 'command': '/Users/feb/.local/bin/tmux-mcp', 'args': ['-shell-type', 'bash', '-scope', 'agentic'], 'env': {}}
[1;34m::[0m mcp: registering tmux-mcp (user scope, shell-type bash, scope agentic)
MCP server tmux-mcp already exists in user config
[1;33m!![0m mcp: claude mcp add failed — tmux-mcp stays unregistered
[1;34m::[0m mcp: registering tmux-mcp (user scope, shell-type bash, scope agentic)
MCP server tmux-mcp already exists in user config
[1;33m!![0m mcp: claude mcp add failed — tmux-mcp stays unregistered

spec03: exit 0
PASS  precondition: /Users/feb/.local/bin/tmux-mcp is installed (spec01's rung or pass one)
PASS  precondition: the real nu exists at /opt/homebrew/bin/nu
PASS  precondition: python3 on PATH (the stdio client needs it)
── stage 1: tools/list
      guard[tools] watching /Users/feb/.config/chezmoi/chezmoi.toml
      guard[tools] sha256 in       = 02d5d4ee50b5d37955ffe7778938ddee82f4da24cbaf552b4dba3810d3c850a1
      guard[tools] source-path in  = /Users/feb/dev/.files/home
PASS  tools: the gate tmux server boots (session tmux-mcp-gate)
PASS  tools: the fixture pane runs the real nu (pane %0)
PASS  tools: tools/list answers 20 tools with -scope agentic (got 20 — the scope flag working; {"count": 20, "names": ["capture-pane", "close-pane", "create-headless", "create-session", "display-message", "execute-command", "kill-headless-server", "kill-pane", "kill-session", "list-panes", "list-sessions", "list-windows", "pane-state", "run-in-repl", "screenshot-pane", "send-keys", "split-pane", "start-and-watch", "watch-pane", "write-to-display"]})
PASS  tools: every Layer 2 name present — all 7
      guard[tools] sha256 out      = 02d5d4ee50b5d37955ffe7778938ddee82f4da24cbaf552b4dba3810d3c850a1
      guard[tools] source-path out = /Users/feb/dev/.files/home
PASS  tools: LIVE chezmoi.toml unchanged (02d5d4ee50b5d37955ffe7778938ddee82f4da24cbaf552b4dba3810d3c850a1)
PASS  tools: LIVE chezmoi source-path unchanged (/Users/feb/dev/.files/home)
── stage 2: start-and-watch in a nushell pane
      guard[readiness] watching /Users/feb/.config/chezmoi/chezmoi.toml
      guard[readiness] sha256 in       = 02d5d4ee50b5d37955ffe7778938ddee82f4da24cbaf552b4dba3810d3c850a1
      guard[readiness] source-path in  = /Users/feb/dev/.files/home
PASS  readiness: the gate tmux server boots (session tmux-mcp-gate)
PASS  readiness: the fixture pane runs the real nu (pane %0)
PASS  readiness: start-and-watch fired pattern:42 in a nushell pane (got 'pattern:42') — send-keys plus the watch tools WORK
PASS  readiness: pane-state says the foreground command is nu (got 'nu' — state: {"foregroundCmd": "nu", "foregroundPid": 75351, "isAlive": true, "paneId": "%0", "panePid": 75351, "waitingForInput": true})
PASS  readiness: pane-state says waitingForInput true — back at the prompt (got True)
      guard[readiness] sha256 out      = 02d5d4ee50b5d37955ffe7778938ddee82f4da24cbaf552b4dba3810d3c850a1
      guard[readiness] source-path out = /Users/feb/dev/.files/home
PASS  readiness: LIVE chezmoi.toml unchanged (02d5d4ee50b5d37955ffe7778938ddee82f4da24cbaf552b4dba3810d3c850a1)
PASS  readiness: LIVE chezmoi source-path unchanged (/Users/feb/dev/.files/home)
── stage 3: execute-command never answers
      guard[hang] watching /Users/feb/.config/chezmoi/chezmoi.toml
      guard[hang] sha256 in       = 02d5d4ee50b5d37955ffe7778938ddee82f4da24cbaf552b4dba3810d3c850a1
      guard[hang] source-path in  = /Users/feb/dev/.files/home
PASS  hang: the gate tmux server boots (session tmux-mcp-gate)
PASS  hang: the fixture pane runs the real nu (pane %0)
PASS  hang/attached: execute-command got NO response in the 10s window on the nushell pane ({"response": false, "isError": null, "text": "", "sc": {}})
PASS  hang/headless: execute-command got NO response on a headless pane either — headless sessions run nu too
PASS  hang/wrapper: the pane shows the bash wrapper parsed as a nushell ERROR (nu::parser::shell_outerr) — the tool cannot answer, not merely miscarry
PASS  hang/wrapper: the error names the nushell spelling ('out+err>' instead of '2>&1')
PASS  hang/sentinel: no .exit sentinel exists after the window () — nothing signalled
      guard[hang] sha256 out      = 02d5d4ee50b5d37955ffe7778938ddee82f4da24cbaf552b4dba3810d3c850a1
      guard[hang] source-path out = /Users/feb/dev/.files/home
PASS  hang: LIVE chezmoi.toml unchanged (02d5d4ee50b5d37955ffe7778938ddee82f4da24cbaf552b4dba3810d3c850a1)
PASS  hang: LIVE chezmoi source-path unchanged (/Users/feb/dev/.files/home)
── stage 4: the registration is live
      guard[registration] watching /Users/feb/.config/chezmoi/chezmoi.toml
      guard[registration] sha256 in       = 02d5d4ee50b5d37955ffe7778938ddee82f4da24cbaf552b4dba3810d3c850a1
      guard[registration] source-path in  = /Users/feb/dev/.files/home
PASS  registration: user-scope command is the ABSOLUTE $HOME/.local/bin/tmux-mcp (got '/Users/feb/.local/bin/tmux-mcp')
PASS  registration: the three args read back intact ('-shell-type bash -scope agentic' in /Users/feb/.claude.json, top-level mcpServers — spec02's measured destination)
      guard[registration] sha256 out      = 02d5d4ee50b5d37955ffe7778938ddee82f4da24cbaf552b4dba3810d3c850a1
      guard[registration] source-path out = /Users/feb/dev/.files/home
PASS  registration: LIVE chezmoi.toml unchanged (02d5d4ee50b5d37955ffe7778938ddee82f4da24cbaf552b4dba3810d3c850a1)
PASS  registration: LIVE chezmoi source-path unchanged (/Users/feb/dev/.files/home)
PASS  no gate tmux server survives on the gate's own sockets (TMUX_TMPDIR default + mcp-headless)
PASS  no server answers on a tmux-mcp-gate label socket either
PASS  no tmux wait-for child left running
PASS  precondition: /Users/feb/.local/bin/tmux-mcp is installed (spec01's rung or pass one)
PASS  precondition: the real nu exists at /opt/homebrew/bin/nu
PASS  precondition: python3 on PATH (the stdio client needs it)
── stage --selftest: every stage proven by breaking it ─────
PASS  selftest M1: the count expectation was mutated
PASS  selftest M1: the mutated gate goes red (rc 1)
PASS  selftest M1: it went red on ITSELF (a FAIL line exists)
PASS  selftest M1: no server on the tmux-mcp-gate socket after its run
PASS  selftest M1: no tmux wait-for child left running
PASS  selftest M2: the mutated gate goes red (rc 1)
PASS  selftest M2: it went red on ITSELF (a FAIL line exists)
PASS  selftest M2: no server on the tmux-mcp-gate socket after its run
PASS  selftest M2: no tmux wait-for child left running
PASS  selftest M3: the pane shell was mutated to bash
PASS  selftest M3: the mutated gate goes red (rc 1)
PASS  selftest M3: it went red on ITSELF (a FAIL line exists)
PASS  selftest M3: no server on the tmux-mcp-gate socket after its run
PASS  selftest M3: no tmux wait-for child left running
PASS  selftest M4: the mangled registration goes red
PASS  selftest M4: the failure names the args it read
PASS  no gate tmux server survives on the gate's own sockets (TMUX_TMPDIR default + mcp-headless)
PASS  no server answers on a tmux-mcp-gate label socket either
PASS  no tmux wait-for child left running
