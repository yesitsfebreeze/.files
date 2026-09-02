---
state: open        # open|analyzing|refine|question|specced|claimed|blocked|done|failed
origin: requested  # requested = the user asked | derived = the board found it
priority: 28        # higher first
complexity: 0      # analyst, at spec time — 1-100. THE WEIGHT the board schedules by
blast-radius: mid
repo:
time:
  est:
  actual:
needs:
  - 09-simplify/01-hygiene
footprint:
  - install.sh
  - Brewfile
  - home/run_after_generate-shell-init.sh
  - home/run_after_register-mcp.sh
  - home/dot_config/capsule/Dockerfile
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

- [ ] **R1** — A `Brewfile` at the repo root lists every formula and cask
      `install.sh` installs today, including `tinty` from its Homebrew tap
      (`tinted-theming/tinted`). `rust` is dropped if `rustfmt` was its only
      reason; the analyst checks.
- [ ] **R2** — `install.sh` becomes about 60 lines: `brew bundle`, the
      `tmux-mcp` release fetch, the resurrect and continuum clones, `chezmoi
      apply`. The dry-run seam (`run()`, `INSTALL_DRY_FAIL`, `DRY_TAG`,
      :46-68, 153-157, 187-192), the APT/PACMAN/DNF lists and Linux branches
      (:119-123, 312-344, 380-399), the Neovim floor (:260-282, 401-432) and
      the `MASON_SEED` export (:482) go. Lines 9, 23, 447, 477 cite deleted
      tests and go.
- [ ] **R3** — `run_after_generate-shell-init.sh` becomes its three
      `tool init > file` commands, `gen_init`'s tmp-and-`mv` (:91-101, kept
      verbatim) and a three-line header. `SHELL_INIT_BREW_PREFIXES`
      (:27-35, 44-61) and lines 75, 108 go; brew is
      `eval "$(/opt/homebrew/bin/brew shellenv)"`.
- [ ] **R4** — `run_after_register-mcp.sh` keeps the `~/.claude.json` vs
      `settings.json` finding (:16-22) and loses the rest of its prose.
- [ ] **R5** — `capsule/Dockerfile` lines 6 and 10 stop citing tests.
- [ ] **R6** — The `internals/` page that describes provisioning says
      "`brew bundle` then `chezmoi apply`" and nothing about waves or gates.

## Acceptance

- [ ] `brew bundle check --file Brewfile` exits 0
- [ ] `wc -l install.sh` prints at most 80; `bash -n install.sh` exits 0
- [ ] `rg -l 'tests/|gates/|INSTALL_DRY|SHELL_INIT_BREW_PREFIXES|MASON_SEED' install.sh home/run_after_*.sh home/dot_config/capsule/Dockerfile` prints nothing
- [ ] `chezmoi apply` exits 0 and `ls ~/.cache/nushell/init/*.nu` lists three non-empty files
- [ ] with one tool renamed off PATH, `chezmoi apply` still exits 0 and the missing tool's init file is empty

## Out of scope

- `run_after_seed-mason-registry.sh` — `06-neovim-television` decides it.
- `dot_gitconfig.tmpl`, `.chezmoiignore`, `.chezmoi.toml.tmpl` — kept.
