# Feature: Package provisioning

Parent: [Provisioning epic](00-epic.md) · C 8 · U 9 · sources: "Package
installer" (C8 U9 — dominant), "Declarative package set" (C2 U9), "Homebrew
bootstrap" (C2 U8), "Neovim version gating" (C4 U8) in
capabilities-provisioning.md

## Summary

Every tool the other epics assume, installed from a declarative list, exactly
once, without ever aborting the apply.

## Requirements

1. **Tools as data.** `.chezmoidata/packages.yaml` holds the package set. The
   installer is a renderer over it, not a hand-maintained script.
2. **Re-run only on change.** The installer embeds
   `include ".chezmoidata/packages.yaml" | sha256sum` in a comment so
   chezmoi's `run_onchange` re-runs it when — and only when — the list
   changes.
3. **Homebrew first.** `run_once_before` installs Homebrew on a fresh macOS
   machine; later stages must re-`eval "$(brew shellenv)"` because the new
   brew is not yet on PATH in the same apply.
4. **macOS path is the supported one.** brew for everything available there.
   The Linux ladder (distro package → prebuilt GitHub release tarball → cargo)
   exists for capsule containers; keep it, but macOS is what the gates test.
5. **Never abort.** A failed package warns and continues (`command -v`
   guards keep it idempotent). A partial machine beats a dead apply.
6. **Neovim version gate.** The config requires ≥ 0.11 (native
   `vim.lsp.enable`, blink.cmp) — in practice the live machine runs 0.12.x.
   Distro packages ship too-old builds, so on Linux override with the official
   release tarball when nvim is missing or older than the floor; macOS gets a
   current one from brew. **Record the floor in one place** and have
   [`03-editor`](../03-editor/00-epic.md) reference it rather than restating a
   version.
7. **Required set.** At minimum: nushell, television, zoxide, starship,
   neovim, git, ripgrep, fd, bat, eza, fzf, lazygit, chezmoi, tinty, docker,
   burrito/brr, gh. (`fzf` is required whether or not it is wanted — see the
   correction in
   [`00-delivery/04`](../00-delivery/04-corrections-backlog.md) about
   `zi` spawning it.)

## Acceptance criteria

- Fresh macOS machine: one apply installs every tool in the required set.
- Editing `packages.yaml` triggers exactly one installer re-run; touching
  anything else triggers none.
- Removing a package from the list does not uninstall it (documented
  non-behavior, so nobody expects convergence).
- Simulating one failed package still completes the apply, with a warning.
