---
state: claimed
mode: afk
priority: 2
verify: just gate
claim: 01a01605-6d60-7e7e-adc5-36557224f3f4
---

# Simplify the package installer (Unix-first)

Purpose: run_onchange_install-packages.sh.tmpl is a 732-line multi-platform
package installer. The user is moving to Linux-first and needs macOS + Linux
working; Windows is being stripped. Re-scope the installer around mac + linux,
driven by packages.yaml, so it is package-manager-driven or split per tool
instead of one giant script.

## Requirements
- [ ] packages.yaml analyzed: which packages are mac/linux, which are Windows-only (dropped)
- [ ] run_onchange_install-packages.sh.tmpl simplified (732 lines → measurably smaller): package-manager-driven or per-tool split, Windows branches removed
- [ ] macOS and Linux install paths both work (brew / apt / dnf / pacman / etc. as packages.yaml drives)
- [ ] Windows-only packages removed from packages.yaml
- [ ] `just gate` passes and the installer still parses (bash -n)

## Acceptance
- [ ] The installer is measurably smaller (line count recorded), covers mac + linux from packages.yaml, has no Windows branches, and `just gate` passes.

## Out of scope
- The de-windows node's file deletions (mirror hook, powertoys, glazewm/zebar, wsl-clip) — this node only touches the packages installer + packages.yaml
- Rewriting the nvim config

## Assumptions
- The user's platforms are macOS and Linux; Windows branches are dead weight.
- packages.yaml is the source of truth for what gets installed.
