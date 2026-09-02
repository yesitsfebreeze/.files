# Provisioning

> `brew bundle` then `chezmoi apply`. Everything else is a trap that was paid
> for once.

`install.sh` is the whole of it, and it does four things in one order that is
load-bearing: bootstrap Homebrew, `brew bundle install --file Brewfile`, fetch
the two things no package manager carries, then `chezmoi apply` **last** —
because the apply's `run_after` scripts generate shell init by *running* the
tools, and a tool installed after the apply is a tool the generated init does
not know about.

The package set lives in one file, `Brewfile` at the repo root. Adding a tool
is a line there; nothing else in the tree names the set.

## Homebrew will not load a third-party tap until you trust it

Measured 2026-09-02 on Homebrew 6.0.21. `tinty` is not in core — it comes from
`tinted-theming/tinted`, and a `brew "tinted-theming/tinted/tinty"` line in the
Brewfile is **not enough**:

```
Error: Refusing to load formula tinted-theming/tinted/tinty from untrusted
tap tinted-theming/tinted. Run `brew trust ...`
```

`brew bundle` will not trust a tap for you, and it does not fail the run — it
prints the error and carries on, so a fresh machine finishes green with no
tinty and therefore no palette. `install.sh` runs `brew trust --tap
tinted-theming/tinted` before the bundle for exactly this reason. Trust is
machine state (`~/.homebrew/trust.json`), not repo state, so every machine
needs the line.

## A release-rung binary in ~/.local/bin outlives the reason for it

`~/.local/bin` is ahead of the Homebrew prefix on PATH — that order follows the
shell, deliberately. So when a tool moves from a GitHub-release fetch to a
Brewfile line, the old binary in `~/.local/bin` keeps winning and the Brewfile
entry is invisible. Homebrew says so at install time and it is easy to scroll
past:

```
tinty (shadowed by /Users/feb/.local/bin/tinty)
```

Moving a tool to the Brewfile means deleting its `~/.local/bin` copy in the
same change. Two tools are still on the release rung on purpose, because
neither is in any package manager: `tmux-mcp`, and nothing else.

## `brew bundle check` reports the machine, not the Brewfile

It is red when a formula is merely *outdated*, when a keg is unlinked, and when
a cask's artifacts are already on disk from another source — none of which says
anything about whether the Brewfile is right. Measured 2026-09-02: `docker`
cannot link because something else owns `etc/bash_completion.d/docker`, and the
CaskaydiaCove fonts in `~/Library/Fonts` differ byte-wise from the cask's own
3.5.1, so `--adopt` refuses them.

To check the *file*, use `brew bundle list --file Brewfile --all` and resolve
the names. To check the *machine*, `brew bundle check --no-upgrade`, and read
the remainder as a to-do rather than a failure.

## The generated shell init

`config.nu` only `source`s three files out of `~/.cache/nushell/init`, so
launching a shell does no setup work; `run_after_generate-shell-init.sh`
writes them once per apply. Three things in that script look odd and are not:

1. **The directory is a literal `$HOME/.cache/nushell/init`, and
   `XDG_CACHE_HOME` is deliberately not honoured.** Nushell resolves `source`
   at *parse* time and cannot read `$env`, so `config.nu` physically cannot
   write `source ($env.XDG_CACHE_HOME | path join ...)`. A generator that
   honoured the variable while the shell could not would write to one
   directory and source from another — three failing `source` lines at every
   shell start. One hardcoded path on both sides cannot diverge.

2. **PATH order follows the shell, not the installer.** Homebrew's shellenv is
   evaluated first and `~/.local/bin:~/.cargo/bin` is prepended over it, which
   is the order a login shell gets. The generated init must describe the binary
   the shell will actually launch. Measured 2026-08-21: `~/.local/bin/zoxide`
   was 0.9.9 and `/opt/homebrew/bin/zoxide` 0.10.0, and their `init nushell`
   output differed by 32 bytes.

3. **It ends in an explicit `exit 0` and carries no `set -e`.** Measured: a
   `run_after` script exiting 3 makes `chezmoi apply` print
   `chezmoi: <script>: exit status 3` and exit 1. A missing tool must be a
   warning, never a dead apply. Every `run_after` here ends the same way for
   the same reason.

`gen_init` writes to a temp file in the same directory and `mv -f`s it into
place (a same-directory rename, therefore atomic) only when the tool exited 0.
On any failure it truncates the target instead: an empty file is a harmless
no-op, a missing one is a `source` error at every shell start, and a
half-written one is a parse error in every shell.

## Registering the MCP server

`run_after_register-mcp.sh` writes top-level `mcpServers` in `~/.claude.json`,
not `~/.claude/settings.json`. The upstream README says settings.json and it is
wrong: a block there is ignored and `claude mcp list` reports no servers.
`env -u CLAUDE_CONFIG_DIR` is load-bearing — the multi-login profile model sets
that variable, and letting it through registers the server into whatever
profile was last used. The path is absolute because the apply's PATH is not the
login shell's.
