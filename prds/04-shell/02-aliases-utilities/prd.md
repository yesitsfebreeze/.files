---
state: done
priority: 32
est: 4h
task: S.2
mode: afk
needs:
  - 04-shell/01-core-config
  - 06-help/01-content-model
verify: "bash tests/nushell-aliases.sh"
---

# Aliases and small utilities

Parent: [Nushell epic](../prd.md) · C 2 · U 8 · source: "Aliases and small
utilities" in
[`capabilities-nushell.md`](../../../docs/capabilities-nushell.md)

Purpose: The finger-memory layer: modern-tool aliases, quit shortcuts, and the
few tiny utilities that earn their keep.

## Requirements
- [x] **R1** — **Tool aliases.** `cat`→`bat --paging=never`, `grep`→`rg`,
      `g`→git, `lg`→lazygit, `nv`/`vi`→nvim, `nn`→nvim ~/notes.md. The
      interactive zoxide picker and its alias are **not** listed here:
      [`03-zoxide`](../03-zoxide/prd.md) R2 owns that pair, and stating it
      twice is the duplication the tree's own rule forbids.
- [x] **R2** — **Quit muscle memory.** `q`, `:q`, `/exit` → exit.
- [x] **R3** — **Dotfiles sync.** `rr` → `chezmoi update --force`. Stated as
      requirement 4 of
      [`05-platform/01`](../../05-platform/01-deploy-mechanism/prd.md), the
      deploy-mechanism PRD, but implemented in this node's `config.nu` — so
      the box lives where the work happens, and there is exactly one of it.
- [x] **R5** — **`cf <file>`.** Copy file contents to the system clipboard;
      picks pbcopy/wl-copy/xclip by session type, guards on display vars so it
      never hangs headless; `path`-typed arg gives free tab completion.
- [x] **R6** — **`pass` completion.** Extern signature completing subcommands
      + live entry names from `$PASSWORD_STORE_DIR` (nushell has no shipped
      completion); undeclared flags still pass through to the real binary.

## Acceptance
- [x] Each alias resolves in a fresh shell; `cf` errors cleanly on a missing
      file and copies on a real one.
- [x] `pass <tab>` lists both verbs and store entries without the `.gpg`
      suffix.

## Out of scope
- **The session aliases `bb`/`ba` — `DO NOT PORT`.** They were R4; the box is
  gone and R4 is left as a deliberate gap, because the tree cites
  requirements by number and a renumbered R5 would break those citations.
  Two corrections in one: they invoke **`brr`**, not `burrito` (backlog
  **M-7** — both binaries exist, so the name is load-bearing), and `burrito`
  itself was dropped on 2026-08-20, which takes the aliases with it (see the
  `DO NOT PORT — burrito` entry in the
  [README exclusion list](../../README.md)).
- Anything this node's Requirements do not name. The epic ([`../prd.md`](../prd.md)) owns the shared invariants.
