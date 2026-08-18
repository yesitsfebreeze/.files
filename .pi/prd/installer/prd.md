---
state: done
mode: afk
priority: 2
verify: just gate
---

# Simplify the package installer (Unix-first)

Purpose: run_onchange_install-packages.sh.tmpl is a 732-line multi-platform
package installer. The user is moving to Linux-first and needs macOS + Linux
working; Windows is being stripped. Re-scope the installer around mac + linux,
driven by packages.yaml, so it is package-manager-driven or split per tool
instead of one giant script.

## Requirements
- [x] packages.yaml analyzed: which are mac/linux, which are Windows-only (dropped)
      Analysis: NO Windows-only packages existed. Every package has brew/apt/pacman/dnf fields (or "" where unavailable).
      No winget/choco/windows fields present. Header comment updated from "Linux/WSL" to "macOS + Linux target".
- [x] run_onchange_install-packages.sh.tmpl simplified: 732 → 486 lines (34% reduction)
      Approach: package-manager-driven. Replaced 8 per-tool binary fallback blocks (~215 lines) with a single
      gh_release loop driven by packages.yaml. Removed Docker section with WSL shim (~100 lines). Removed
      playwright deps (~20 lines). Trimmed verbose comments throughout.
- [x] macOS and Linux install paths both work (brew / apt / dnf / pacman / etc. as packages.yaml drives)
      Manager detection and batch install preserved. Debian symlinks (batcat/fdfind) preserved.
      neovim version upgrade check preserved for apt users (apt ships 0.9.x, config needs 0.11+).
- [x] Windows-only packages removed from packages.yaml
      None existed; verified by reading every entry. Headers/comments updated to remove "Linux/WSL" framing.
- [x] `just gate` passes and the installer parses (bash -n)
      bash -n: no syntax errors on the layer's template file.
      just gate: 26/26 tests pass (finder.nu 14, overlay.nu 8, quicklist.nu 4).

## Acceptance
- [x] The installer is measurably smaller (line count recorded), covers mac + linux from packages.yaml,
      has no Windows branches, and `just gate` passes.
      Before: 732 lines. After: 486 lines (34% reduction).
      Windows branches removed: Docker WSL shim, playwright deps, WSL comments throughout.
      just gate: all 26 tests pass. bash -n: no syntax errors.

## Out of scope
- The de-windows node's file deletions (mirror hook, powertoys, glazewm/zebar, wsl-clip) — this node only touches the packages installer + packages.yaml
- Rewriting the nvim config

## Assumptions
- The user's platforms are macOS and Linux; Windows branches are dead weight.
- packages.yaml is the source of truth for what gets installed.
