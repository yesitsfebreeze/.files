---
state: open
mode: afk
deps:
  - .mi/prd/04-shell/01-core-config
  - .mi/prd/06-help/01-content-model
verify: ""
---

# Aliases and small utilities

Parent: [Nushell epic](../prd.md) · C 2 · U 8 · source: "Aliases and small

Purpose: The finger-memory layer: modern-tool aliases, quit shortcuts, and the
few tiny utilities that earn their keep.

## Requirements
- [ ] **R1** — **Tool aliases.** `cat`→`bat --paging=never`, `grep`→`rg`,
      `g`→git, `lg`→lazygit, `nv`/`vi`→nvim, `nn`→nvim ~/notes.md, `cdi`→`zi`.
- [ ] **R2** — **Quit muscle memory.** `q`, `:q`, `/exit` → exit.
- [ ] **R3** — **Dotfiles sync.** `rr` → `chezmoi update --force`.
- [ ] **R4** — **Sessions.** `bb`/`ba` → burrito spawn-or-attach / attach.
- [ ] **R5** — **`cf <file>`.** Copy file contents to the system clipboard;
      picks pbcopy/wl-copy/xclip by session type, guards on display vars so it
      never hangs headless; `path`-typed arg gives free tab completion.
- [ ] **R6** — **`pass` completion.** Extern signature completing subcommands
      + live entry names from `$PASSWORD_STORE_DIR` (nushell has no shipped
      completion); undeclared flags still pass through to the real binary.

- [ ] **R4 (from `05-platform/01` req 4)** — `rr` = `chezmoi update --force`.
      Stated by the deploy-mechanism PRD but implemented in this node's
      `config.nu`, so the box lives where the work happens.

## Acceptance
- [ ] Each alias resolves in a fresh shell; `cf` errors cleanly on a missing
      file and copies on a real one.
- [ ] `pass <tab>` lists both verbs and store entries without the `.gpg`
      suffix.

## Out of scope
- Anything this node's Requirements do not name. The epic ([`../prd.md`](../prd.md)) owns the shared invariants.
