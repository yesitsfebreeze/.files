---
kind: knowledge
description: install.sh is one order that is load-bearing — brew bootstrap, trust the tinty tap, bundle, MasonUpdate, chezmoi apply last
read_when: "touching provisioning, or a fresh machine that came up half-configured"
---

# install-sh-is-four-things-in-one-order

`install.sh` does four things in one order, and the order is load-bearing:

1. bootstrap Homebrew,
2. `brew trust --tap tinted-theming/tinted` then `brew bundle install --file
   Brewfile` — the trust line first, because `brew bundle` will not trust a
   tap for you and **does not fail the run**: it prints the error and carries
   on, so a fresh machine finishes green with no tinty and therefore no
   palette. Trust is machine state (`~/.homebrew/trust.json`), so every
   machine needs the line.
3. fetch the two things no package manager carries,
4. `chezmoi apply` **last** — the apply's `run_after` scripts generate shell
   init by *running* the tools, and a tool installed after the apply is a tool
   the generated init does not know about.

Three traps the provisioning layer already paid for:

- **`~/.local/bin` outlives the reason for it**: it is ahead of the Homebrew
  prefix on PATH, so when a tool moves from a GitHub-release fetch to a
  Brewfile line the old binary keeps winning and the Brewfile entry is
  invisible. Moving a tool to the Brewfile means deleting its `~/.local/bin`
  copy in the same change.
- **`brew bundle check` reports the machine, not the Brewfile** — red on
  outdated formulas, unlinked kegs, artifacts already on disk from another
  source. To check the file: `brew bundle list --file Brewfile --all`. To
  check the machine: `brew bundle check --no-upgrade`, read as a to-do.
- **Every `run_after` ends in an explicit `exit 0` and carries no `set -e`**:
  measured, a script exiting 3 makes `chezmoi apply` print the status and exit
  1 — a missing tool must be a warning, never a dead apply. The generated
  shell-init writes to a same-directory temp file and `mv -f`s it into place
  only when the tool exited 0; on any failure it truncates the target instead
  — an empty file is a harmless no-op, a half-written one is a parse error in
  every shell.

The generated init's PATH order follows the shell, not the installer:
`~/.local/bin:~/.cargo/bin` prepended over the Homebrew shellenv — the order a
login shell gets — because a release-rung binary in `~/.local/bin` (zoxide
0.9.9 vs 0.10.0, measured) has different `init` output.