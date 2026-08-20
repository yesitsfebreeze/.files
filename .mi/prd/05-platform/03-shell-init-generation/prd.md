---
state: open
mode: afk
deps:
  - .mi/prd/05-platform/02-package-provisioning/packages-installer
verify: ""
---

# Shell-init generation

Parent: [Provisioning epic](../prd.md) · C 3 · U 9 · source: "Shell-init

Purpose: The integration files Nushell only *sources* are generated at apply
time, not shell-start time. This is what lets shell launch do zero setup work
— the requirement [`04-shell/01`](../../04-shell/01-core-config/prd.md) depends on.

## Requirements
- [ ] **R1** — **Runs last.** A `run_after` script, after the package
      installer, so it can use tools installed in the same apply (re-resolving
      brew shellenv and user bins first).
- [ ] **R2** — **Generated files.** starship → `~/.cache/starship/init.nu`;
      zoxide → `~/.zoxide.nu`; television → `~/.cache/television/init.nu`.
      **Note the inconsistency in the live layout**: two live in `~/.cache`,
      one in `$HOME`. Pick one location for all three in the rebuild and
      update the [shell epic's](../../04-shell/prd.md) invariant to match,
      rather than inheriting the split.
- [ ] **R3** — **Never break `source`.** Guarantee each file exists after the
      run — an empty file is a harmless no-op — so `config.nu`'s `source`
      lines cannot fail on a machine where a tool isn't installed yet.
- [ ] **R4** — **Regenerate every apply.** These are derived artifacts; they
      are not committed and are always rewritten, so a tool upgrade's new init
      is picked up.
- [ ] **R5** — **Version-sensitive output.** The generated television init
      defines the `tv_shell_history` command the shell binds to `Alt-R`
      ([`04-shell/05`](../../04-shell/05-history/prd.md)) — so a tv upgrade that
      renames it breaks a keybinding. The gate checks the binding, not just
      the file.

## Acceptance
- [ ] After an apply, all three files exist and are non-empty on a machine
      with the tools installed.
- [ ] On a machine missing starship, the file exists, is empty, and launching
      `nu` produces no error.
- [ ] `Alt-R` resolves to a defined command after a fresh apply.
- [ ] Launching a shell runs no generator: timing a cold `nu` start shows no
      init-generation cost.

## Out of scope
- Anything this node's Requirements do not name. The epic ([`../prd.md`](../prd.md)) owns the shared invariants.
