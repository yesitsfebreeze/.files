# Capabilities of the provisioning layer (chezmoi)

Companion to [`capabilities.md`](capabilities.md),
[`capabilities-nushell.md`](capabilities-nushell.md) and
[`capabilities-nvim.md`](capabilities-nvim.md); same rules. Ratings are 1–10
(complexity / usefulness), sorted best-first by value ratio. Markers: nothing
= take over, `SIMPLIFY` = reduced version, `DEFER` = not in the minimal base,
`DO NOT PORT` = drop.

**Why this inventory exists.** It was missing, and its absence was a hole in
the plan: the PRD tree referenced "generated at chezmoi-apply time" and
"installed by the bootstrap" without ever rating or speccing the layer that
does it. The deployed `~/.config` tree is canonical (Decision 4,
`.mi/prd/00-delivery/corrections/prd.md`, 2026-08-21); the chezmoi source at
`~/.local/share/chezmoi` (`home/` + `justfile` + `docs/`) is not a port
target, and the capabilities rated below are what `05-platform` rebuilds from
scratch — not the legacy `~/.files` symlink deployer, and not the legacy
`conf/bootstrap.lua`.

**Correction it forces.** `capabilities.md`'s "Cross-platform dependency
bootstrap" (the WezTerm-Lua checker that installs zoxide/docker and stamps
`.cache/.bootstrap`) is **superseded** by the entries below. It should not be
ported; see [`05-platform`](../prd/05-platform/prd.md).

## Shell-init generation (`run_after_generate-shell-init.sh`)
- Regenerates the integration files Nushell only *sources*: starship →
  `~/.cache/starship/init.nu`, zoxide → `~/.zoxide.nu`, television →
  `~/.cache/television/init.nu`. Runs last on every apply, after the package
  installer, picking up tools installed in the same apply (brew shellenv +
  user bins). Guarantees each file exists (empty = harmless no-op) so
  `source` never fails when a tool isn't installed yet.
- 3
- 9
----
## Declarative package set (`.chezmoidata/packages.yaml`)
- The tool list as data, not script. The installer embeds
  `include ".chezmoidata/packages.yaml" | sha256sum` in a comment, so
  chezmoi's `run_onchange` re-runs the installer automatically whenever the
  list changes — and only then.
- 2
- 9
----
## Idempotent apply + push workflow
- `chezmoi apply` is the single deploy step; `rr` (`chezmoi update --force`)
  is the daily pull-and-apply. The repo `justfile` has one `push` recipe:
  init from this source, apply, commit, push, then `chezmoi update --force`.
  Every script is guarded by `command -v` so a re-apply is a no-op.
- 3
- 9
----
## Package installer (`run_onchange_install-packages.sh.tmpl`)
- 559 lines, macOS + Linux: brew on macOS; apt/dnf on Linux with a documented
  fallback ladder — prebuilt GitHub release tarball first (nushell and `tv`
  aren't packaged, cargo-building them is heavy), cargo as last resort.
  Resolves latest release tags from the GitHub API, installs into
  `~/.local/bin`, warns and continues so one failure can't abort the apply.
  Symlinks Debian's `batcat`/`fdfind` to `bat`/`fd`.
- 8
- 9
----
## Neovim version gating
- apt/dnf ship a stale Neovim (Ubuntu 0.9.x) that the config cannot run:
  nvim-lspconfig needs 0.11.3+, and native `vim.lsp.enable` + blink.cmp
  expect 0.11+. The installer overrides the package version with the official
  release tarball into `~/.local` when nvim is missing or < 0.11 (Linux only;
  macOS gets a current one from brew).
- 4
- 8
----
## Homebrew bootstrap (`run_once_before_install-homebrew.sh.tmpl`)
- `run_once_before` installs Homebrew on a fresh macOS machine, ahead of
  everything that needs it. The package installer then re-evaluates
  `brew shellenv` because the new brew isn't on PATH yet in the same apply.
- 2
- 8
----
## Managed config surface (`home/dot_config/`)
- One source of truth for every tool's config: nushell, nvim, wezterm,
  television, burrito, starship.toml, bat, gh, lazygit, tinted-theming,
  wp-stat-overlay. Templated where it must differ per machine
  (`dot_gitconfig.tmpl`).
- **Live bug L-12, corrected and do not reproduce:** the source tree ships
  `solo-window.{applescript,sh,ps1,vbs}`. The audit called them unreferenced;
  measured, that is only half right — the *deployed*
  `~/.config/wezterm/wezterm.lua` never mentions solo-window, but the
  *source* `home/dot_config/wezterm/wezterm.lua` defines `solo_window()` and
  calls it from two places. They are dead relative to what runs, live
  relative to what would be applied, which is the divergence below. The other
  two files the audit listed, `wsl-clip-prime.sh` and a wezterm
  `background.png`, are not in the source tree at all — that half of L-12 is
  stale. None is ported: three of the four are Windows-only and the rebuild
  is macOS-host-only.
- **New finding (L-13), the ground the corrections epic stands on:** the
  chezmoi source and `~/.config` have diverged, in both directions, and
  `chezmoi apply` from the current source would destroy the config every
  inventory in this repo was written from. Measured 2026-08-20, source vs
  deployed line counts: `wezterm/wezterm.lua` 339 vs 1149 · `nushell/config.nu`
  380 vs 715 · `nushell/finder.nu` 345 vs 221 (the source one is a different,
  stack-and-resume design) · `television/config.toml` 16 vs 15 ·
  `nvim/lua/config/keymaps.lua` identical. `leadermode.nu`, `dirstack.nu`,
  `quicklist.nu`, `overlay.nu` and `opacity.nu` exist only under `~/.config`
  and are not in the source at all. So "chezmoi-managed", written at the head
  of these inventories, is not true of the files they rate. Which artifact is
  canonical was decided 2026-08-21 (Decision 4): the deployed tree is
  canonical — see the resolution on
  `00-delivery/corrections/w0-6-live-bugs`.
- 3
- 9
----
## Starship prompt
- `starship.toml` (~2 KB) defines the two-line prompt. Note the coupling: it
  is *why* the shell disables OSC 133/633 — the two-line prompt re-emits the
  prompt-start mark on every reedline repaint, which WezTerm renders as a
  phantom blank line (see the nushell core-config entry).
- 2
- 8
----
## Small tool configs
- `bat` (theme/paging), `gh`, `lazygit`, `ripgrep/config` (shares the global
  ignore set with `fd`'s native `~/.config/fd/ignore`), `tinted-theming`
  (tinty state + artifacts).
- 2
- 7
----
## Windows config mirroring (`run_after_mirror-config-to-windows.sh`)  DO NOT PORT
- 42 lines mirroring `~/.config` into a Windows-side location. Confirms the
  live setup was dual-platform; the rebuild is macOS-only, so this is dropped
  along with the rest of the Windows surface.
- 3
- 1
----
## wp-stat-overlay installer  DEFER
- `run_onchange_after_install-wp-stat-overlay.sh.tmpl`, 148 lines installing a
  project-specific app. Not part of a dotfiles daily-driver base; keep it in
  the live repo, out of the minimal cut.
- 4
- 3
----
## Published docs site (`docs/`)  DEFER
- `docs/build.py` + `index.html` generate a static page from the repo's docs.
  Real, but orthogonal to the daily driver — and overlapping in purpose with
  [`06-help`](../prd/06-help/prd.md), which should be built first and then
  reconsidered as the source for any published page.
- 4
- 4
----
