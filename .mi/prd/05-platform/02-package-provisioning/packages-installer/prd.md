---
state: open
mode: afk
deps:
  - .mi/prd/00-delivery/decisions/fzf
  - .mi/prd/05-platform/01-deploy-mechanism/repo-skeleton
verify: ""
---

# packages.yaml + run_onchange installer

Parent: [`02-package-provisioning`](../prd.md) · source:
[`02-package-provisioning`](../prd.md) requirements R1, R2, R4, R5, R6, R7

## Requirements
- [ ] **R1** — **Tools as data.** `.chezmoidata/packages.yaml` holds the
      package set. The installer is a renderer over it, not a hand-maintained
      script.
- [ ] **R2** — **Re-run only on change.** The installer embeds `include
      ".chezmoidata/packages.yaml" | sha256sum` in a comment so chezmoi's
      `run_onchange` re-runs it when — and only when — the list changes.
- [ ] **R4** — **macOS path is the supported one.** brew for everything
      available there. The Linux ladder (distro package → prebuilt GitHub
      release tarball → cargo) exists for capsule containers; keep it, but
      macOS is what the gates test.
- [ ] **R5** — **Never abort.** A failed package warns and continues (`command
      -v` guards keep it idempotent). A partial machine beats a dead apply.
- [ ] **R6** — **Neovim version gate.** The config requires ≥ 0.11 (native
      `vim.lsp.enable`, blink.cmp) — in practice the live machine runs 0.12.x.
      Distro packages ship too-old builds, so on Linux override with the
      official release tarball when nvim is missing or older than the floor;
      macOS gets a current one from brew. **Record the floor in one place**
      and have [`03-editor`](../../../03-editor/prd.md) reference it rather than
      restating a version.
- [ ] **R7** — **Required set.** At minimum: nushell, television, zoxide,
      starship, neovim, git, ripgrep, fd, bat, eza, fzf, lazygit, chezmoi,
      tinty, docker, burrito/brr, gh. (`fzf` is required whether or not it is
      wanted — see the correction in
      [`00-delivery/04`](../../../00-delivery/corrections/prd.md) about `zi`
      spawning it.)

## Acceptance
- [ ] Every requirement box above is `[x]` against the real thing.

## Out of scope
- The sibling node's requirements. This document held two contracts and was split;
  the parent lists which requirement went where.
