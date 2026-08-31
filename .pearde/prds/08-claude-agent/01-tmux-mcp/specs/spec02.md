---
complexity: 6
footprint:
  - home/run_after_register-mcp.sh
---

# spec02 — the run_after script that registers tmux-mcp with Claude Code

`home/run_after_register-mcp.sh`, a chezmoi `run_after` script in the
pattern of the two the source already carries: it runs once per
`chezmoi apply`, it does one idempotent thing, a failure of the tool it
needs is a WARNING and never a dead apply (epic I4 — a run_after exiting
non-zero fails the whole apply; end in an explicit `exit 0`, carry no
`set -e`), and it owns no file under `home/` — `~/.claude`-anything is
not chezmoi-managed, which is exactly why the mechanism is a script the
apply executes rather than a file chezmoi renders.

The one thing it does:

```sh
env -u CLAUDE_CONFIG_DIR claude mcp add --scope user tmux-mcp -- \
    "$HOME/.local/bin/tmux-mcp" -shell-type bash -scope agentic
```

The measured facts it encodes — an implementer who "simplifies" any of
these away reinstates a defect:

- **The destination is `~/.claude.json` (user scope), NOT
  `~/.claude/settings.json`.** The PRD body and the upstream README both
  say settings.json; measured 2026-08-31 on Claude Code 2.1.251, a
  `mcpServers` block in settings.json is ignored — `claude mcp list`
  reports no servers — while `claude mcp add --scope user` writes
  `mcpServers` at the top level of `~/.claude.json` and `claude mcp
  list` then sees it. Follow the measurement; the PRD's wording is filed
  as a correction, not obeyed.
- **`env -u CLAUDE_CONFIG_DIR` is load-bearing.** The multi-login
  profile model (04-shell/08) writes that variable from `cc`'s picker;
  this agent's own harness sets it too. A run_after that lets it
  through registers the server into whatever profile happened to be
  last-used and the user's default `cc` launch never sees it.
- **The server name is `tmux-mcp`** and the command is the ABSOLUTE
  `~/.local/bin/tmux-mcp` — the apply's PATH is not the login shell's
  and must not be relied on to carry `~/.local/bin`.
- **`claude mcp add` is itself the idempotency guard.** Re-running
  overwrites the entry in place (exits 0, same config). Do not pre-check
  with `claude mcp get` — that spawns a health check (a real connection
  attempt per apply) for information the overwrite makes stale anyway.
  A missing `claude` binary warns and skips, per R5.

What already stands from pass one (2026-08-31): the binary is installed
(spec01), the registration is LIVE in `~/.claude.json` on this machine —
name `tmux-mcp`, command `~/.local/bin/tmux-mcp`, args `-shell-type bash
-scope agentic`, status ✔ Connected — and the script's job is to make
that property reproducible from a fresh clone rather than a hand-run
command. What is left is only the script and its idempotence.

## Acceptance

- [x] Running the script twice in a row exits 0 both times and
      `env -u CLAUDE_CONFIG_DIR claude mcp get tmux-mcp` afterwards
      reports Status ✔ Connected with the three args intact. Measured
      2026-08-31: run 1 rc=0, run 2 rc=0; `claude mcp get tmux-mcp` →
      `Status: ✔ Connected`, `Command: /Users/feb/.local/bin/tmux-mcp`,
      `Args: -shell-type bash -scope agentic`.
      One measured behaviour the spec predicted wrong and the script
      handles: a `claude mcp add` onto an EXISTING entry exits NON-ZERO
      ("MCP server tmux-mcp already exists in user config") — it does not
      "overwrite the entry in place (exits 0)" as this spec says. The
      overwrite happens by value, not by tool exit code: the existing entry
      with the three args is unchanged and Connected. So the script wraps
      the call in `|| warn` — the warning line on an already-registered
      machine is the by-design R5 line, the apply survives, and the idempotent
      state holds. Re-proven from the empty state too: after
      `claude mcp remove tmux-mcp -s user`, the script's add printed
      `Added stdio MCP server tmux-mcp with command: /Users/feb/.local/bin/tmux-mcp -shell-type bash -scope agentic to user config` and
      `claude mcp get` then reported ✔ Connected with the args intact.
- [x] With `claude` absent from PATH, the script prints a warning line
      naming tmux-mcp and still exits 0 (the apply survives; epic I4).
      Measured 2026-08-31 with a claude stub exiting 127 shadowing PATH:
      `!! mcp: claude is not on PATH — tmux-mcp stays unregistered`, rc=0
      (and with a poison stub: rc=0, the add failure warned, no abort).
- [x] With `CLAUDE_CONFIG_DIR` set to a scratch directory, the
      registration lands in the user's real `~/.claude.json` (the script
      must unset the variable, not inherit it) — verify by parsing the
      real file's top-level `mcpServers.tmux-mcp.args`. Measured 2026-08-31
      (this harness runs with `CLAUDE_CONFIG_DIR=/Users/feb/.claude/litellm`
      set, which is exactly the hazard): with the variable pointing at a
      scratch dir, the script ran rc=0 and the REAL `~/.claude.json` still
      carries `mcpServers.tmux-mcp` =
      `command /Users/feb/.local/bin/tmux-mcp, args ['-shell-type','bash','-scope','agentic']`.
      The `env -u` is what makes box 1's `claude mcp add` write the real
      file from inside this harness at all: with the variable inherited, the
      earlier remove measured `File modified: /Users/feb/.claude/litellm/.claude.json`.
- [x] The script creates nothing under `home/` that chezmoi would then
      manage (it is a `run_after_` script, not an `exact_` file), and
      `chezmoi apply` with the script staged ends exit 0. Measured 2026-08-31
      by the deploy-skeleton isolation shape (HOME pinned to --destination,
      all five flags): the repo's `home/` copied to a scratch source, `init
      --force` rc=0, `apply --force` rc=0, and the apply log ends with the
      script's own line —
      `Added stdio MCP server tmux-mcp with command: <scratch>/dest/.local/bin/tmux-mcp … to user config`,
      writing `<scratch>/dest/.claude.json`. No `run_after_register-mcp.sh`
      appears in the target tree (nothing to manage), and the REAL
      `~/.claude.json` entry still reads the absolute `~/.local/bin` command
      afterwards.

## Verify and Proof

```sh
cd /Users/feb/dev/dotfiles
bash home/run_after_register-mcp.sh && bash home/run_after_register-mcp.sh
env -u CLAUDE_CONFIG_DIR claude mcp get tmux-mcp
python3 -c "import json,os;d=json.load(open(os.path.expanduser('~/.claude.json')));print(d['mcpServers']['tmux-mcp'])"
```