---
complexity: 11
footprint:
  - tests/tmux-mcp.sh
  - gates/waves.tsv
---

# spec03 — the gate: 20 tools, the nushell readiness path, the hang, on the record

`tests/tmux-mcp.sh`, a bash gate in the shape of its siblings
(`--selftest`, stages, scratch-only fixtures, and everything it boots
killed on every exit path), that proves the property the PRD is ABOUT —
Claude's MCP handle on tmux works from this environment — and pins the
one upstream interaction that shaped the PRD's constraint. The harness
mechanism is already standing: `prds/08-claude-agent/01-tmux-mcp/probe/drive.py`
left uncommitted by pass one is the working client (stdlib-only Python,
speaks JSON-RPC stdio to the server); the gate ports that harness into
itself, and the probe directory stays as the pass-one record.

Fixture discipline, both measured hard ways: an ISOLATED tmux server per
run (`TMUX_TMPDIR=$(mktemp -d)`, `-f /dev/null`, session named for the
gate) so the gate never touches the user's `main` session, and `SHELL`
pointed at the real `/opt/homebrew/bin/nu` — the gate must exercise the
shell the real panes run (a scratch `/bin/sh` proves nothing about the
caveat). Kill the gate's tmux server and any `tmux wait-for` child in the
trap. The `mcp-headless` socket the server creates for headless tools
belongs to the server, dies with the trap's `tmux kill-server` on both
sockets.

The stages, each failable:

1. **20 tools.** `initialize` + `tools/list` over stdio with `-scope
   agentic` answers 20 tool names; the 7 Layer 2 names
   (start-and-watch, watch-pane, pane-state, run-in-repl,
   write-to-display, display-message, close-pane) are all present. This
   is the scope flag working, measured 2026-08-31.
2. **The readiness path WORKS in nushell panes.** `start-and-watch` with
   a `pattern` on a command the pane's nu executes (`let probev = 41 +
   1; print $probev`, pattern `42`) fires `pattern:42` and reports
   `foregroundCmd: "nu"`, `waitingForInput: true` in `pane-state`
   afterward. PRD constraint "start-and-watch is the honest path" —
   proven, not asserted.
3. **execute-command HANGS, it does not miscarry.** On a nushell pane,
   the bash wrapper the server composes — `{ cmd; } 2>&1 | tee …; echo
   ${PIPESTATUS[0]} > …exit; tmux wait-for -S …` — is a nushell PARSE
   ERROR (`nu::parser::shell_outerr`, "use 'out+err>' instead") and the
   pane therefore never writes the `.exit` sentinel nor signals
   `tmux wait-for`: the tool blocks until its caller's deadline, on
   attached AND on headless panes (headless sessions run nushell too —
   they are spawned with no command override). The stage sends
   `execute-command` under a bounded request, proves no response and no
   `.exit` file inside a fixed window, and records the fact. This is the
   PRD's caveat upgraded from "exit codes are unreliable" to the sharp
   claim a reader can act on: the tool never answers, so agent workflows
   must not call it here at all — send-keys plus the watch tools are the
   interface.
4. **The registration is live** (spec02's property, from the same gate
   run): the user-scope `mcpServers` entry exists with the three args,
   skipping the stage cleanly with a distinct message when the run_after
   has not run yet — so the gate can land before spec02 without going
   red on another node's work.

Register the gate in `gates/waves.tsv` beside the other wave-4 test
lines (the wave number is the orchestrator's to confirm — the epic's
other nodes are not yet registered), in the same change as the script.

## Acceptance

- [x] `bash tests/tmux-mcp.sh` exits 0 with all four stages passing,
      quoting the 20-tool list, the fired pattern event, and the
      execute-command hang measurement. Ran 2026-08-31, exit 0. Stage 1:
      `tools/list answers 20 tools with -scope agentic (got 20 …` with
      the full name list through `write-to-display`; stage 2:
      `start-and-watch fired pattern:42 in a nushell pane (got
      'pattern:42')` plus `foregroundCmd: "nu"` / `waitingForInput: true`
      in pane-state; stage 3: `execute-command got NO response in the
      10s window on the nushell pane ({"response": false …})` on the
      attached pane AND on a headless pane, with the `shell_outerr`
      wrapper visible on the pane and no `.exit` sentinel written.
      Stage 4 read the live `~/.claude.json` top-level mcpServers entry.
- [x] `bash tests/tmux-mcp.sh --selftest` exits 0 — each stage proven by
      breaking it (a wrong tool count, a pattern that never matches, an
      execute-command that DOES return, a mangled registration). Ran
      2026-08-31, exit 0: M1 (EXPECT_TOOLS=19), M2 (PAT="ZZZ-NEVER-42"),
      M3 (NU_BIN=/bin/bash — went red on exactly the counterfactual:
      `FAIL  hang/attached: execute-command got NO response … ({"response":
      true … "exitCode": 0}` — the tool ANSWERS on a bash pane), M4 (a
      mangled `~/.claude.json` via `TMUX_MCP_CLAUDE_JSON` went red and
      named the args it read).
- [x] With the gate interrupted mid-run (selftest does this), no gate
      tmux server survives: `tmux -L <gate label> list-sessions` finds
      nothing afterward, and no `tmux wait-for` child is left running.
      Proven inside the run above: after every mutated copy,
      `PASS  selftest M<n>: no server on the tmux-mcp-gate socket after
      its run` and `no tmux wait-for child left running`; the clean run
      also ends `no gate tmux server survives on the gate's own sockets`.
- [x] The gate creates every fixture under `mktemp -d` (stages under
      `${TMPDIR:-/tmp}/gates.XXXXXX/tmux-mcp`, the tmux sockets under a
      /tmp `mktemp -d` TMUX_TMPDIR) and nothing under `prds/` or the
      user's `~/.config` — checked 2026-08-31: no `M?.out`, `mcp.py` or
      scratch `NU_CONFIG_DIR` under `prds/`; the nushell history the
      pane writes goes to the scratch `NU_CONFIG_DIR`, not the live
      `~/.config/nushell`; the LIVE chezmoi.toml and source-path guards
      read identical sha256s in and out of every stage.

## Verify and Proof

```sh
cd /Users/feb/dev/dotfiles
bash tests/tmux-mcp.sh
bash tests/tmux-mcp.sh --selftest
```