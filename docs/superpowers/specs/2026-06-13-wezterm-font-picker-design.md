# WezTerm Nerd-Font Picker — Design Spec

**Date:** 2026-06-13
**Status:** Approved, in implementation
**Trigger:** `CTRL+SHIFT+F` in WezTerm

## Overview

A WezTerm keybind opens an `fzf` overlay listing the full live Nerd Fonts
catalog. Hovering a font (debounced ~400 ms) downloads and OS-installs it, then
live-previews it in the real WezTerm window via `window:set_config_overrides`.
Pressing Enter keeps the font (persisted across restarts); Esc reverts to the
previous font.

This feature is **interactive runtime tooling**, distinct from the
`packages.yaml`-driven provisioning. `packages.yaml` still owns the guaranteed
default font (JetBrainsMono Nerd Font); the picker adds extra fonts on top as
runtime user state.

## Decisions (from brainstorming)

| Question | Decision |
|----------|----------|
| Core interaction | Browse-and-try a catalog; download/install + apply on selection |
| Catalog size | Full Nerd Fonts catalog (~60+), fetched live from GitHub release |
| Preview style | Download-on-hover live preview, debounced ~400 ms |
| Picker UI | `fzf` overlay pane + watched state-file bridge + `set_config_overrides` |
| Install scope | OS-level install on all three platforms (available to every app) |
| Helper language | Per-OS scripts (`sh` + `ps1`), selected at runtime via `target_triple` |

## Components

### 1. `wezterm.lua` additions (shipped verbatim by chezmoi)

- **Startup font resolution.** Read `~/.config/wezterm/active-font.txt` if it
  exists; use its value as the primary entry in the existing
  `font_with_fallback` list. Absent → current JetBrainsMono default. This file
  is runtime user state, **not** chezmoi-tracked.
- **`config.font_dirs`** includes the per-user OS font directories so WezTerm can
  render a freshly-installed font without a full restart once config reloads:
  - macOS: `~/Library/Fonts`
  - Linux: `~/.local/share/fonts`
  - Windows: `%LOCALAPPDATA%\Microsoft\Windows\Fonts`
- **Keybind** `CTRL+SHIFT+F` → spawn the picker in a new tab running the
  platform helper (selected via `target_triple`).
- **Preview bridge.** A `wezterm.time.call_after` poll loop (active only while
  the picker runs) watches `~/.config/wezterm/preview-font.txt`; on change it
  calls `window:set_config_overrides{ font = … }` to swap the live font
  instantly. When the picker tab closes, the loop stops; if no `active-font.txt`
  was written (Esc), overrides are cleared back to the prior font.

### 2. Per-OS helper scripts (shipped by chezmoi into `~/.config/wezterm/`)

- `executable_fontpicker.sh` (macOS + Linux) and `fontpicker.ps1` (Windows).
- **Catalog.** Fetch the nerd-fonts latest-release asset list from the GitHub
  API (`curl` / `Invoke-RestMethod`), cache to
  `~/.config/wezterm/font-catalog.txt` so reopening is instant and
  offline-tolerant after first run.
- **Picker.** `fzf` over the catalog with
  `--bind 'focus:execute-silent(<helper> --install {})'` (debounced) and a
  header showing keys. Requires `fzf` ≥ 0.30 (already in the manifest).
- **`--install <name>`.** If not already downloaded, fetch `<name>.zip` from the
  release, extract `.ttf`s (`unzip`/`tar` on unix, `Expand-Archive` on Windows),
  copy into the per-user font dir, register:
  - Linux: `fc-cache -f`
  - macOS: copy only (FontBook picks it up)
  - Windows: copy + per-user `HKCU\…\Fonts` registry value (no admin)
  Then write the font name to `preview-font.txt` for the live bridge.
- **Enter.** fzf returns the choice → helper writes it to `active-font.txt`
  (persisted) and clears `preview-font.txt`.
- **Esc / cancel.** Helper clears `preview-font.txt`; the bridge restores the
  previous font. Hovered-but-unkept fonts stay installed (acts as a cache; no
  churn-uninstall).

## Data flow

`CTRL+SHIFT+F` → tab runs helper → fzf list → hover → `--install` →
download/install + write `preview-font.txt` → wezterm poll →
`set_config_overrides` live preview → Enter writes `active-font.txt` / Esc clears
→ picker tab closes → font persists on next launch via startup resolution.

## Cross-platform parity (project-law #2)

Three font-install paths fully covered: macOS (copy), Linux (copy + `fc-cache`),
Windows (copy + `HKCU` registry, no admin). `curl`/unzip availability handled
per-OS. These helpers are **runtime** configs shipped to all platforms (not
`run_onchange_` installers); WezTerm picks the right one at runtime, so they do
not need `.chezmoiignore` gating.

## Manifest boundary (project-law #1)

`packages.yaml` still owns the guaranteed default (JetBrainsMono Nerd Font).
Picker-installed fonts are explicitly **runtime user state**, documented in a
comment in `wezterm.lua` and the helper header so it reads as a deliberate
boundary, not manifest drift.

## State files (runtime, untracked, under `~/.config/wezterm/`)

| File | Writer | Reader | Purpose |
|------|--------|--------|---------|
| `font-catalog.txt` | helper (cached) | helper/fzf | catalog list |
| `preview-font.txt` | helper (`--install`) | wezterm poll loop | live hover preview |
| `active-font.txt` | helper (on Enter) | wezterm startup | persisted choice |

## Testing / verification

- `chezmoi execute-template` / `chezmoi cat` renders the new files cleanly
  (helpers are verbatim, not templated).
- WezTerm Lua loads without parse error.
- Manual: open picker, hover → font installs + previews; Enter persists across
  restart; Esc reverts; offline reopen uses cache.

## Out of scope (YAGNI)

Uninstalling fonts, font-size/weight tuning in the picker, non-Nerd fonts,
syncing picks back into `packages.yaml`.
