# Feature: Drift check

Parent: [Help epic](00-epic.md) · C 5 · U 8 · net-new

## Summary

The feature that makes this manual trustworthy instead of aspirational:
`help --check` diffs the documented entries against the live configuration,
in both directions. Undocumented bindings and stale documentation are both
failures.

## Requirements

1. **Introspect the shell.** `$env.config.keybindings` — match documented
   entries by keybinding `name` (which is why every binding in the config
   carries a meaningful one). `scope aliases` and `scope commands` for
   aliases and custom commands. Constraint: introspection must run in a
   *configured* shell — a bare `nu -c` has no config loaded and reports no
   aliases.
2. **Introspect Neovim.** `nvim --headless` + `nvim_get_keymap` per mode,
   emitted as JSON. Our maps carry `desc`, so the check can compare
   descriptions as well as existence, and flag a map whose `desc` no longer
   matches its documented `title`.
3. **Introspect the terminal.** `wezterm show-keys --lua`, plus
   `--key-table` for the F5 jump table
   ([02-terminal/03](../02-terminal/03-f5-jump-mode.md)).
4. **Report both directions.**
   - *Undocumented*: exists live, no manual entry. The common failure.
   - *Stale*: documented, no longer live. The dangerous failure — it sends a
     reader (or an agent) to a key that does nothing.
   - *Mismatched*: exists in both, but `desc` and `title` disagree.
5. **Exempt prose.** Entries with `verify: prose` are skipped by existence
   checks and counted separately, so concept entries don't need a fake
   binding.
6. **Allowlist noise.** Plugin- and core-provided maps (Neovim 0.11
   defaults, plugin internals) are not ours to document. Keep an explicit
   allowlist rather than silently ignoring — with one exception: the LSP
   defaults we *chose* not to re-map (`grn`, `gra`, `grr`, `gri`, `gO`, `K`,
   `]d`, `[d`) ARE documented, because they're part of how you use this
   editor ([03-editor/09](../03-editor/09-lsp.md)).
7. **Exit code.** Non-zero when anything is undocumented, stale, or
   mismatched — so it can gate a commit or run in CI.
8. **Not on the hot path.** `--check` spawns nvim and wezterm; plain `help`
   never does ([02](02-help-command.md), requirement 8).

## Acceptance criteria

- Add a keybinding to the nushell config without a manual entry:
  `help --check` reports it as undocumented and exits non-zero.
- Delete a documented Neovim map: reported as stale.
- Change a map's `desc` but not the manual: reported as mismatched.
- A clean tree: exits zero and prints per-surface counts (documented,
  prose-only, allowlisted).
