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
`prds/00-delivery/corrections/prd.md`, 2026-08-21), and the chezmoi
source is **not a port target**: the capabilities rated below are what
`05-platform` rebuilds from scratch — not the legacy `~/.files` symlink
deployer, and not the legacy `conf/bootstrap.lua`.

**Which tree this rates, and the one it does not.** The live chezmoi source
is `/Users/feb/dev/.files` (`home/` + `justfile` + `install.sh` + `docs/`):
`chezmoi source-path` prints `/Users/feb/dev/.files/home`, and
`~/.config/chezmoi/chezmoi.toml` sets `sourceDir = "/Users/feb/dev/.files"`.
It is not abandoned — it is where the deployed config comes from, last
committed 2026-08-19. `~/.local/share/chezmoi` is a **stale** checkout of
the same GitHub repo, last commit 2026-06-20, whose HEAD `a2544e4` is a git
**ancestor** of the live source's `8e99f58` — two months behind, not
divergent. That stale clone produced the L-12 and L-13 findings corrected
below, and no document may cite it as the chezmoi source again; the only
permitted mention is as the stale clone that produced wrong findings,
labelled as such (Decision 4(a), as replaced).

**Correction it forces.** `capabilities.md`'s "Cross-platform dependency
bootstrap" (the WezTerm-Lua checker that installs zoxide/docker and stamps
`.cache/.bootstrap`) is **superseded** by the entries below. It should not be
ported; see [`05-platform`](../.pearde/prds/05-platform/prd.md).

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
## Idempotent apply + push workflow
- `chezmoi apply` is the single deploy step, and it is idempotent: every
  script it runs is guarded by `command -v`, so a re-apply is a no-op. `rr`
  (`chezmoi update --force`) is the daily pull-and-apply. Since `8fe3a71`,
  `install.sh` §7 ends in `chezmoi apply` as well, so the installer is
  itself a deploy path.
- **`just push` is git only** — stage, commit, push — and must not deploy,
  init or repoint anything. The cutover moved to its own named recipe,
  `just cutover`, because a recipe typed daily for its git half was silently
  repointing the machine's chezmoi source. Decided by the user 2026-08-21;
  the settled contract is
  [`repo-skeleton`](../.pearde/prds/05-platform/01-deploy-mechanism/repo-skeleton/prd.md)
  R5. What it replaced — a `push` recipe that also ran `chezmoi init
  --source` and `chezmoi apply --force` before committing — is the shape the
  user rejected, and is what the live `justfile` still does.
- R7 is why that is enforced by mechanism rather than by comment:
  **`HOME` does not isolate chezmoi.** A scratch-`HOME` `chezmoi init
  --force` once rewrote the real `~/.config/chezmoi/chezmoi.toml` and
  repointed the live machine at a throwaway repo, so a gate has to assert
  `chezmoi source-path` is unchanged on exit.
- 3
- 9
----
## Managed config surface (`home/dot_config/`)
- One source of truth for every tool's config: nushell, nvim, wezterm,
  television, starship.toml, bat, gh, lazygit, tinted-theming,
  wp-stat-overlay. Templated where it must differ per machine
  (`dot_gitconfig.tmpl`).
- **What burrito is doing missing from that list.** The live chezmoi source
  still carries `home/dot_config/burrito/burrito.toml` — verified
  2026-08-21 — so the omission above is a decision, not an oversight. It
  used to carry a second thing, a `burrito` `cargo_git` entry in
  `home/.chezmoidata/packages.yaml`; `8fe3a71` deleted that file with the
  rest of the data-driven machinery, and `install.sh` §3 builds burrito from
  a git clone instead. burrito is `DO NOT PORT`, decided 2026-08-20 because
  it is no longer used and WezTerm's nine-tab floor owns panes and tabs; see
  the exclusion list in [the board README](../.pearde/prds/README.md). Neither the
  config dir nor the build carries into the rebuilt surface.
- **Live bug L-12 is corrected, not confirmed — and the reading that
  produced it is the thing not to reproduce.** Five of its six files are
  artefacts of the stale clone: the four
  `solo-window.{applescript,sh,ps1,vbs}` files are absent from the live
  source, which has zero `solo_window()` references (the three references
  exist only in the clone, and the deployed `~/.config/wezterm/wezterm.lua`
  has none either), and `wsl-clip-prime.sh` is in neither tree. One is real —
  `home/dot_config/wezterm/background.png` is in the live source — and it is
  dropped by decision 5(a) along with the wallpaper pipeline.
- **L-13 is corrected too: measured against the live source, the divergence
  is zero.** The claim that the source and `~/.config` had diverged in both
  directions was a reading of the stale clone. Measured 2026-08-21 against
  `/Users/feb/dev/.files`, `wezterm/wezterm.lua`, `nushell/config.nu`,
  `nushell/finder.nu` and `nushell/theme.nu` are **byte-identical** to their
  deployed `~/.config` counterparts — source vs deployed line counts
  `1149 vs 1149`, `715 vs 715` and `221 vs 221`. There is no separate
  stack-and-resume `finder.nu` outside the clone, and `chezmoi apply` from
  the live source is a no-op on those files rather than a hazard. Which
  artifact is canonical was decided 2026-08-21 all the same (Decision 4):
  the deployed tree is canonical, which — source and deployed being the same
  content — costs nothing. See the resolution on
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
- **`tinted-theming` is the one place the two trees genuinely differ, and
  the capability is the live half.** `8fe3a71` deleted all of
  `home/dot_config/tinted-theming/` from the source — `tinty/config.toml`,
  the base16/base24 schemes, and the generator scripts including the
  102-line `executable_wezterm-colors.sh`. It is absent from the live source
  at HEAD, in git and on disk. The **deployed** tree still has it:
  `~/.config/tinted-theming/tinty/` holds the schemes and generators, `tinty`
  is installed at `~/.local/bin/tinty`, and `~/.config/wezterm/colors.lua` —
  the artifact WezTerm `dofile`s — exists and is gitignored in the source.
  By Decision 4 the capability is therefore live and canonical; only its
  chezmoi management lapsed. tinty stays the palette owner
  ([`decisions/tinty`](../.pearde/prds/00-delivery/decisions/tinty/prd.md), settled
  2026-08-21), and re-managing the directory is forward-looking scope in
  [`managed-config`](../.pearde/prds/05-platform/01-deploy-mechanism/managed-config/prd.md)
  R2.
- 2
- 7
----
## Tool installation (install.sh)
- One script installs every tool the other epics assume: `install.sh`, 233
  lines at the root of the chezmoi repo (`/Users/feb/dev/.files`, whose
  `home/` is what `chezmoi source-path` prints). Idempotent and non-fatal by
  construction: every step is `command -v`-guarded, so a re-run on a
  provisioned machine is a no-op, and every failure path calls `warn` and
  continues, so a partial machine beats an aborted one.
- **1 — package-manager batch install.** macOS bootstraps Homebrew itself
  when `brew` is missing (the official installer under `NONINTERACTIVE=1`,
  then `eval "$(brew shellenv)"`, because the new brew is not yet on PATH),
  then runs one `brew install` list plus a nerd-font cask. Linux takes apt,
  pacman or dnf, whichever exists, and warns rather than failing when none
  does. Debian names two tools differently, so `batcat` and `fdfind` are
  symlinked into `~/.local/bin` as `bat` and `fd`; `build-essential` /
  `base-devel` is pulled in when `make` is missing, because lazy.nvim `build`
  steps and cargo need it.
- **2 — a GitHub-release ladder for what the distros do not carry.**
  `latest_tag()` reads `tag_name` from the GitHub releases API, and
  `fetch_release()` downloads, extracts and installs one named binary into
  `~/.local/bin`, skipping when it is already on PATH. It covers `kern` on
  both platforms and, on Linux only, `wt`, `tv`, `gh`, `nu`, `lazygit`,
  `starship` and `delta` — macOS gets all of those from brew.
- **3 — a few source builds.** `cargo install --git` for `keydr`, a shallow
  clone plus `just install` for burrito (lines 155–165), and nvm +
  `npm install -g` for the pi coding agent and its extensions. **burrito is
  `DO NOT PORT`, decided 2026-08-20** — the live script still builds it and
  the rebuild does not, so this bullet records what the script does and is
  never an instruction to install it.
- **What this entry replaces, and why none of it is to be restored.** It
  folds three entries that rated machinery commit `8fe3a71` (2026-08-19,
  *"Simplify dotfiles: drop theme/pi/data-driven machinery, minimal chezmoi,
  one plain install.sh"*, 2490 deletions) **deleted**: `Package installer`
  (C 8 / U 9, the dominant source), `Declarative package set` (C 2 / U 9)
  and `Homebrew bootstrap` (C 2 / U 8). That commit removed the 214-line
  `.chezmoidata/packages.yaml`, the 486-line `run_onchange` installer
  template (559 lines rendered), the `run_once_before` Homebrew template,
  and the `sha256` re-run gate with them. They are recorded here only so a
  later reader knows the files are gone; they are **not** to be restored
  from this inventory. Re-rated 2026-08-21, **C 8 → C 4**: U stays 9 because
  every epic still depends on its tools existing, and C falls to 4 because
  what is rated now is a guarded shell script with three mechanisms, not a
  559-line template rendering a YAML model behind a sha256 gate.
- 4
- 9
----
## Neovim version gating
- apt/dnf ship a stale Neovim (Ubuntu 0.9.x) that the config cannot run:
  nvim-lspconfig needs 0.11.3+, and native `vim.lsp.enable` + blink.cmp
  expect 0.11+. `install.sh` parses `nvim --version` for the minor number
  and, when nvim is missing or the minor is `< 11`, installs the official
  release tarball into `~/.local/opt/neovim` and symlinks it into
  `~/.local/bin` (Linux only; macOS gets a current one from brew).
- The capability **survived** `8fe3a71`; only its host moved, from the
  deleted package-installer template to `install.sh`.
- 4
- 8
----
## Published docs site (`docs/`)  DEFER
- `docs/build.py` + `index.html` generate a static page from the repo's docs.
  Real, but orthogonal to the daily driver — and overlapping in purpose with
  [`06-help`](../.pearde/prds/06-help/prd.md), which should be built first and then
  reconsidered as the source for any published page.
- 4
- 4
----
## wp-stat-overlay installer  DEFER
- `run_onchange_after_install-wp-stat-overlay.sh.tmpl`, 148 lines installing a
  project-specific app. Not part of a dotfiles daily-driver base; keep it in
  the live repo, out of the minimal cut.
- 4
- 3
----
## Windows config mirroring (`run_after_mirror-config-to-windows.sh`)  DO NOT PORT
- 42 lines mirroring `~/.config` into a Windows-side location. Confirms the
  live setup was dual-platform; the rebuild is macOS-only, so this is dropped
  along with the rest of the Windows surface.
- 3
- 1
----
