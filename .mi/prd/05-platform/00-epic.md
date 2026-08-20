# Epic: Provisioning — how the config reaches a machine

## Problem

This epic used to be "platform foundation", specced from `capabilities.md`'s
"Cross-platform dependency bootstrap" — a WezTerm-Lua checker that installed
zoxide/docker via brew or winget and stamped `.cache/.bootstrap`. That was
wrong twice over: winget is Windows-only (out of scope), and the mechanism has
already been **superseded** on the live machine.

The real deployment layer is chezmoi, inventoried in
[`capabilities-provisioning.md`](../../docs/capabilities-provisioning.md):
`run_once_before` installs Homebrew, a 559-line `run_onchange` installer
renders a declarative `packages.yaml` (re-running only when its sha256
changes, with a documented fallback ladder on Linux), and a `run_after` script
generates the starship/zoxide/television init files that the shell merely
sources. That last piece is load-bearing for
[`04-shell/01`](../04-shell/01-core-config.md), which requires shell launch to
do zero setup work.

## Goal

One deploy path: clone, `chezmoi apply`, working machine — idempotent, so a
re-apply is a no-op, and data-driven, so adding a tool means editing a YAML
list rather than a script.

## Non-goals

- The legacy `conf/bootstrap.lua` checker and its `.cache/.bootstrap` stamp.
  Superseded; not ported.
- The legacy `~/.files` symlink deployer (`deploy.disabled`, `index`,
  `deleted`) — already `DO NOT PORT`.
- Windows of any kind, including the live
  `run_after_mirror-config-to-windows.sh`.
- `wp-stat-overlay` provisioning and the published docs site (`DEFER`).

## Children

| # | Feature | C | U | V |
|---|---------|---|---|---|
| 01 | [Deploy mechanism](01-deploy-mechanism.md) — source layout, apply/push, managed configs | 3 | 9 | 6 |
| 02 | [Package provisioning](02-package-provisioning.md) — packages.yaml, installer, homebrew, nvim gating | 8 | 9 | 1 |
| 03 | [Shell-init generation](03-shell-init-generation.md) — starship/zoxide/tv init files | 3 | 9 | 6 |

## Architecture invariants

1. **Apply-time, not launch-time.** Anything that costs milliseconds at shell
   start is generated during `chezmoi apply` instead. The shell only
   `source`s.
2. **Idempotent by construction.** Every script is guarded (`command -v`,
   `run_once`, `run_onchange` hashes) so re-applying is safe and cheap.
3. **Tools are data.** The package set lives in `.chezmoidata/packages.yaml`;
   the installer is a renderer over it.
4. **Never fail the whole apply.** One unavailable package warns and
   continues; a partial machine beats an aborted one.

## Success criteria

A fresh macOS machine: clone the repo, `chezmoi apply`, and every tool the
other five epics assume is present. A second apply changes nothing.
