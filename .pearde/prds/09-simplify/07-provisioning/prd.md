---
state: done        # open|analyzing|refine|question|specced|claimed|blocked|done|failed
origin: requested  # requested = the user asked | derived = the board found it
priority: 28        # higher first
complexity: 30      # analyst, at spec time — 1-100. THE WEIGHT the board schedules by
blast-radius: mid
repo:
time:
  est:
  actual: 0.17h
needs:
  - 09-simplify/01-hygiene
footprint:
  - install.sh
  - Brewfile
  - home/run_after_generate-shell-init.sh
  - home/run_after_register-mcp.sh
  - home/dot_config/capsule/Dockerfile
  # spec03 also carries the manual half of R6 and the stale citation R2's
  # cut created — added by the orchestrator 2026-09-02 from the analyst's
  # report footprint union
  - home/dot_config/nushell/help/manual/internals/provisioning.md
  - home/dot_config/nushell/help/manual/internals/index.md
  - home/dot_config/nushell/help/manual/internals/neovim.md
workflow: replace-a-hand-rolled-mechanism
---

# 07-provisioning — a Brewfile and sixty lines

Parent: [`09-simplify`](../prd.md) · meta, no C/U

Purpose: `install.sh` is 493 lines, about 250 of them a dry-run seam, Linux
package managers, a Neovim version floor and release rungs — for gates that
were deleted and machines that do not exist. What it does on this machine:
brew a list, brew a cask, fetch two GitHub releases, clone two tmux plugins,
`chezmoi apply`. The three `run_after` scripts carry test-only seams whose
tests are gone. Measured 2026-09-02; re-read before cutting.

## Requirements

- [x] **R1** — A `Brewfile` at the repo root lists every formula and cask
      `install.sh` installs today, including `tinty` from its Homebrew tap
      (`tinted-theming/tinted`). `rust` is dropped if `rustfmt` was its only
      reason; the analyst checks. — 28 entries (1 tap, 26 formulae, 1 cask),
      every name resolving. **`rust` stays**: the offer's premise did not
      reproduce — `lua/plugins/conform.lua:21` still reads
      `rust = { "rustfmt" }`, and `rustfmt` has no formula of its own.
- [x] **R2** — `install.sh` becomes about 60 lines: `brew bundle`, the
      `tmux-mcp` release fetch, the resurrect and continuum clones, `chezmoi
      apply`. The dry-run seam (`run()`, `INSTALL_DRY_FAIL`, `DRY_TAG`,
      :46-68, 153-157, 187-192), the APT/PACMAN/DNF lists and Linux branches
      (:119-123, 312-344, 380-399), the Neovim floor (:260-282, 401-432) and
      the `MASON_SEED` export (:482) go. Lines 9, 23, 447, 477 cite deleted
      tests and go. — 493 → **78 lines**, `bash -n` clean, branch keywords
      51 → 10.
- [x] **R3** — `run_after_generate-shell-init.sh` becomes its three
      `tool init > file` commands, `gen_init`'s tmp-and-`mv` (:91-101, kept
      verbatim) and a three-line header. `SHELL_INIT_BREW_PREFIXES`
      (:27-35, 44-61) and lines 75, 108 go; brew is
      `eval "$(/opt/homebrew/bin/brew shellenv)"`. — 112 → **35 lines**, and
      the three generated files come out at the same 2280/1966/1809 bytes the
      original produced.
- [x] **R4** — `run_after_register-mcp.sh` keeps the `~/.claude.json` vs
      `settings.json` finding (:16-22) and loses the rest of its prose. —
      65 → 29 lines; the finding is at `:4` and `:8`.
- [x] **R5** — `capsule/Dockerfile` lines 6 and 10 stop citing tests. — the
      two `tests/dev-image.sh` citations are gone; the layer-order and
      no-`COPY`/`ADD` rules stay.
- [x] **R6** — The `internals/` page that describes provisioning says
      "`brew bundle` then `chezmoi apply`" and nothing about waves or gates. —
      `internals/provisioning.md`, net-new (there was no such page), linked
      from `internals/index.md:21` and deployed.

## Acceptance

- [x] `brew bundle list --file Brewfile --all` names every entry the
      Brewfile declares, and `brew info` over those names exits 0 for each.
      Ran 2026-09-02: 28 names out, `ok every formula resolves`,
      `ok every cask resolves`.
      Corrected 2026-09-02 by the orchestrator: `brew bundle check` reports
      the *machine's* state, not the file's, and is red here for four causes
      this PRD does not own (`gh`/`gnupg` outdated, `docker` link owned by
      Docker Desktop, the CaskaydiaCove cask differing from fonts already
      installed) — a verify asserting it would go red again for nothing.
- [x] `wc -l install.sh` prints at most 80; `bash -n install.sh` exits 0 —
      78, and it parses.
- [x] `rg -l 'tests/|gates/|INSTALL_DRY|SHELL_INIT_BREW_PREFIXES|MASON_SEED' install.sh home/run_after_generate-shell-init.sh home/run_after_register-mcp.sh home/dot_config/capsule/Dockerfile` prints
      nothing (negate with `!`, since no match is success and `rg` exits 1
      on it). Corrected 2026-09-02 by the orchestrator: the prior
      `home/run_after_*.sh` glob also caught
      `run_after_seed-mason-registry.sh`, which `06-neovim-television` owns
      and this PRD does not touch; scoped to the two scripts R3 and R4 name.
- [x] `chezmoi apply` exits 0 and `ls ~/.cache/nushell/init/*.nu` lists three
      non-empty files — `starship.nu 2280`, `zoxide.nu 1966`,
      `television.nu 1809`. **The apply was scoped, never bare**, per the
      workflow's `apply-scoped-not-bare`: a bare apply also runs
      `run_after_seed-mason-registry.sh`, which `06-neovim-television` owns.
      What was run instead: `chezmoi apply --dry-run` (exit 0),
      `chezmoi apply ~/.config/nushell/help/manual/internals/neovim.md`
      (exit 0), and the generator itself by hand. `chezmoi status` afterwards
      leaves no file target pending — only the three ` R ` run-scripts, which
      were pending before this pass too.
- [x] with one tool renamed off PATH, `chezmoi apply` still exits 0 and the
      missing tool's init file is empty — `probe/shell-init-missing-tool.sh`
      exits 0: `PASS: exit 0, zoxide.nu empty, other two intact`. It shims a
      failing `zoxide` first on PATH rather than renaming, because the script
      evaluates `/opt/homebrew/bin/brew shellenv` by absolute path and that
      prepends the real prefix back over any scratch PATH.

## Out of scope

- `run_after_seed-mason-registry.sh` — `06-neovim-television` decides it.
- `dot_gitconfig.tmpl`, `.chezmoiignore`, `.chezmoi.toml.tmpl` — kept.

## Report

spec01-brewfile-and-installer: exit 0
  ok   Brewfile lists 28 entries
  ok   every formula resolves
  ok   every cask resolves
  ok   tinty is in the Brewfile
  ok   brew owns tinty
  ok   no ~/.local/bin/tinty shadow
  ok   install.sh is 78 lines
  ok   install.sh parses
  ok   install.sh runs brew bundle
  ok   install.sh trusts the tinted tap
  ok   chezmoi apply comes after brew bundle
  ok   no deleted-test or seam citations
  ok   three non-empty init files
  ok   a failing tool yields an empty file, exit 0
  ok   the ~/.claude.json finding survives
  ok   the empty-build-context rule survives
  ok   the internals page says brew bundle
  ok   the internals page names no wave or gate
  ok   the page is deployed
  ok   no file target of this PRD left undeployed
PASS

spec02-run-after-and-dockerfile: exit 0
  ok   Brewfile lists 28 entries
  ok   every formula resolves
  ok   every cask resolves
  ok   tinty is in the Brewfile
  ok   brew owns tinty
  ok   no ~/.local/bin/tinty shadow
  ok   install.sh is 78 lines
  ok   install.sh parses
  ok   install.sh runs brew bundle
  ok   install.sh trusts the tinted tap
  ok   chezmoi apply comes after brew bundle
  ok   no deleted-test or seam citations
  ok   three non-empty init files
  ok   a failing tool yields an empty file, exit 0
  ok   the ~/.claude.json finding survives
  ok   the empty-build-context rule survives
  ok   the internals page says brew bundle
  ok   the internals page names no wave or gate
  ok   the page is deployed
  ok   no file target of this PRD left undeployed
PASS
-rw-r--r--@ 1 feb  staff  2280 Sep  2 13:00 starship.nu
-rw-r--r--@ 1 feb  staff  1809 Sep  2 13:00 television.nu
-rw-r--r--@ 1 feb  staff     0 Sep  2 13:00 zoxide.nu
PASS: exit 0, zoxide.nu empty, other two intact

spec03-internals-provisioning-page: exit 0
  ok   Brewfile lists 28 entries
  ok   every formula resolves
  ok   every cask resolves
  ok   tinty is in the Brewfile
  ok   brew owns tinty
  ok   no ~/.local/bin/tinty shadow
  ok   install.sh is 78 lines
  ok   install.sh parses
  ok   install.sh runs brew bundle
  ok   install.sh trusts the tinted tap
  ok   chezmoi apply comes after brew bundle
  ok   no deleted-test or seam citations
  ok   three non-empty init files
  ok   a failing tool yields an empty file, exit 0
  ok   the ~/.claude.json finding survives
  ok   the empty-build-context rule survives
  ok   the internals page says brew bundle
  ok   the internals page names no wave or gate
  ok   the page is deployed
  ok   no file target of this PRD left undeployed
PASS
