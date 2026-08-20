---
state: open
mode: afk
deps:
  - .mi/prd/04-shell/05-history
  - .mi/prd/05-platform/01-deploy-mechanism/managed-config
  - .mi/prd/06-help/01-content-model
verify: ""
---

# Television finder

Parent: [Nushell epic](../prd.md) · C 8 · U 9 · source: "Television finder

Purpose: television (`tv`) owns every picker screen — no hand-coded TUIs.
`finder` runs a channel and returns **typed nushell data**; channel selection
is itself a fuzzy channel; selections open by type.

## Requirements
- [ ] **R1** — **`finder [--start <channel>]`.** Runs a tv channel (or the
      channels remote first), un-hijacks enter (`--keybindings
      'enter="confirm_selection"'` — the stock `text` channel binds enter to
      edit), tab = multi-select, returns structured data.
- [ ] **R2** — **Typed decode.** Channel → produced type → decoder:
      `files`/`dirs`/`rcwd` → FileList (expanded, existing paths); `text` →
      GrepList `{file, line, text}`; `git-log` → Commits `{hash, subject}`;
      `cht-query` → ChtSheet; unknown channels pass raw strings.
- [ ] **R3** — **Open-by-type.** GrepList → `$EDITOR +line file`; Commits →
      `git show`; ChtSheet → cht.sh via pager; path → cd if dir, edit if file.
      `--env` so a cd reaches the shell.
- [ ] **R4** — **Keybindings.**
  - [ ] `Ctrl+Space` / `F1` → `tv_remote`: pick a channel, run it, ACT on the
        result (quicklist and opacity channels dispatch to their own runners).
  - [ ] `Ctrl+T` → `tv_finder`: same picker but INSERT the selection at the
        cursor, shell-quoted (fzf-style).
- [ ] **R5** — **Cable channels.** Curate the channel set for the minimal
      base: keep files, dirs, text (grep), zoxide, recent-dirs (`rcwd`,
      sourced from the dirstack), git-log/git-files/git-branch, env,
      quicklist; the long tail of git-* channels and app-specific ones
      (burrito/opencode sessions, bg, theme, opacity) migrate only on demand.
- [ ] **R6** — **Theming.** tv uses the `default` ANSI theme so it inherits
      the terminal's palette rather than baking hex values.
- [ ] **R7** — **Known tv limitations (encode as guards/tests).** tv panics
      without a TTY → all entry points are interactive-only; the CLI
      `--keybindings` grammar is `key="action"` (inverse of the config-file
      form); with `--expect`, stdout line 1 is the pressed key (empty = plain
      enter).

## Acceptance
- [ ] `Ctrl+Space`, type `fil`, enter, pick a file → it opens in nvim; pick a
      dir via `dirs` → shell cds (and auto-lists).
- [ ] `Ctrl+T` on a path with spaces inserts it quoted; esc leaves the line
      untouched.
- [ ] A grep pick from `text` opens the editor at the matching line.
- [ ] `finder` in a non-tty context returns/errors cleanly, no panic.

## Out of scope
- Anything this node's Requirements do not name. The epic ([`../prd.md`](../prd.md)) owns the shared invariants.
