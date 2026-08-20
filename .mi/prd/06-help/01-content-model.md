# Feature: Content model

Parent: [Help epic](00-epic.md) · C 4 · U 9 · net-new

## Summary

The manual's single data source: one structured file per surface, holding
every entry a reader needs plus the prose that introspection can't produce.
Every renderer ([02](02-help-command.md), [03](03-browser.md),
[05](05-agent-interface.md)) reads this and nothing else.

## Requirements

1. **Format.** NUON or YAML under version control (NUON preferred — nushell
   opens it natively with no parser). One file per surface:
   `shell.nuon`, `nvim.nuon`, `terminal.nuon`, `capsule.nuon`.
2. **Entry schema.** Every entry carries:
   - `key` or `cmd` — the binding (`ctrl-r`, `F5 <digit>`) or invocation
     (`z <query>`)
   - `title` — one line: what it does
   - `use` — how to use it: the actual gesture, in order, including what to
     press next and what comes back
   - `topic` — the section it belongs to (see below)
   - `mode` — where it applies: `shell`, `nvim:normal`, `nvim:visual`,
     `nvim:insert`, `terminal`, `container`
   - `also` — optional related entries, by key/cmd
   - `why` — optional; the non-obvious reason it works this way. This is
     where the hard-won constraints live (e.g. "`Alt-R`, not `Ctrl-Shift-R`:
     shift is indistinguishable on control+letter without kitty protocol").
   - `verify` — how the drift check confirms it exists
     ([04](04-drift-check.md)): a nushell keybinding `name`, an nvim `lhs`
     + mode, a wezterm key spec, or `prose` for entries with no live
     counterpart.
3. **Topics.** The manual's spine, ordered by how often it's needed:
   `navigate` · `find` · `history` · `edit` · `git` · `containers` ·
   `terminal` · `agents` · `config`.
4. **Coverage — shell.** Keybindings `Ctrl-R` / `Alt-R` / `Up`/`Down` /
   `Shift+Up`/`Down` ([04-shell/05](../04-shell/05-history.md)),
   `Ctrl-Space` + `F1` / `Ctrl-T` / `Ctrl-Q`
   ([04-shell/04](../04-shell/04-television.md),
   [07](../04-shell/07-quicklist.md)), `Esc`; navigation `z` / `zi` / `zz` /
   `zl` / `zc` / `cdi` / bare-word fallback / `cd` auto-create
   ([03](../04-shell/03-zoxide.md), [01](../04-shell/01-core-config.md));
   aliases and utilities ([02](../04-shell/02-aliases-utilities.md));
   `cc` / `cr` ([08](../04-shell/08-claude-launchers.md)); `ls` variants and
   `-D` ([06](../04-shell/06-listing.md)).
5. **Coverage — Neovim.** Leader groups and their maps, window/buffer/move
   maps ([03-editor/02](../03-editor/02-keymaps.md)), telescope incl. the
   mark→quickfix flow ([08](../03-editor/08-telescope.md)), LSP maps —
   **both** our aliases and the Neovim 0.11 defaults we deliberately don't
   re-map ([09](../03-editor/09-lsp.md)), completion keys
   ([05](../03-editor/05-completion.md)), oil
   ([06](../03-editor/06-explorer.md)), formatting
   ([07](../03-editor/07-formatting.md)), shift-select semantics
   ([14](../03-editor/14-shift-select.md)), table mode
   ([15](../03-editor/15-markdown-tables.md)).
6. **Coverage — terminal.** F5 jump mode
   ([02-terminal/03](../02-terminal/03-f5-jump-mode.md)), tab/window/quit
   keys ([02](../02-terminal/02-startup-layout.md)), and the capsule
   bindings ([01-capsule](../01-capsule/00-epic.md)).
7. **Coverage — capsule.** The CLI surface: mount, `--rebuild`, list, clean,
   and the recents picker.
8. **Concept entries.** A small number of prose entries (`verify: prose`)
   for the mental models a list of keys can't convey: the `mkcd` funnel and
   why every navigation route updates start dir and recents; why a bare word
   jumps; what a tv channel is and how to add one; how credentials reach a
   capsule.
9. **Writing rules.** `title` is one line, imperative, no trailing period.
   `use` describes the real gesture ("press `F5`, then a digit 1–9"), never
   restates the key. `why` only where the reason is non-obvious — most
   entries won't have one.

## Acceptance criteria

- Every keybinding defined in the shell, Neovim, and terminal configs has an
  entry, confirmed by [04-drift-check](04-drift-check.md).
- Opening a content file directly is readable as plain text — the data is the
  manual, not a serialization artifact.
- No description text exists anywhere else in the repo; renderers contain
  layout only.
