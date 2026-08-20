# Feature: Aliases and small utilities

Parent: [Nushell epic](00-epic.md) · C 2 · U 8 · source: "Aliases and small
utilities" in capabilities-nushell.md

## Summary

The finger-memory layer: modern-tool aliases, quit shortcuts, and the few
tiny utilities that earn their keep.

## Requirements

1. **Tool aliases.** `cat`→`bat --paging=never`, `grep`→`rg`, `g`→git,
   `lg`→lazygit, `nv`/`vi`→nvim, `nn`→nvim ~/notes.md, `cdi`→`zi`.
2. **Quit muscle memory.** `q`, `:q`, `/exit` → exit.
3. **Dotfiles sync.** `rr` → `chezmoi update --force`.
4. **Sessions.** `bb`/`ba` → burrito spawn-or-attach / attach.
5. **`cf <file>`.** Copy file contents to the system clipboard; picks
   pbcopy/wl-copy/xclip by session type, guards on display vars so it never
   hangs headless; `path`-typed arg gives free tab completion.
6. **`pass` completion.** Extern signature completing subcommands + live
   entry names from `$PASSWORD_STORE_DIR` (nushell has no shipped completion);
   undeclared flags still pass through to the real binary.

## Acceptance criteria

- Each alias resolves in a fresh shell; `cf` errors cleanly on a missing
  file and copies on a real one.
- `pass <tab>` lists both verbs and store entries without the `.gpg` suffix.
