# Feature: Verification gates

Parent: [Delivery epic](00-epic.md) · net-new

## Summary

What must actually *run* before a wave counts as done. The tree's acceptance
criteria are already written as observable checks; this turns them into gates
that an agent can execute without a human watching.

## Requirements

1. **Definition of done, per task.** A task is done when: its PRD's
   acceptance criteria have been executed and passed; its `help` entries
   exist; and it introduced no regression in an earlier wave's gate. Reading
   the criteria is not executing them.
2. **Headless checks where possible.** The three surfaces are all scriptable,
   which is what makes automated gates realistic:
   - shell — `nu -c '<expr>'` for commands and pipelines;
     `$env.config.keybindings` for bindings. Note the constraint: a bare
     `nu -c` loads no config, so gate scripts must launch a *configured*
     shell.
   - editor — `nvim --headless -c '<lua>' -c 'qa'`, plus `nvim_get_keymap`
     for maps and `:checkhealth` for plugin state.
     Also `:Lazy! sync` exit status for install integrity.
   - terminal — `wezterm show-keys --lua`, diffed against the intended set.
3. **Interactive checks, listed explicitly.** Some criteria genuinely need a
   human at a terminal: the F5 jump landing on the right pane, the smear of a
   cursor, whether the bare-word jump *feels* instant, the shift-select
   collapse under real keyboard timing. These are enumerated per wave as a
   short manual checklist rather than pretended to be automated.
4. **Wave gates.**

| Wave | Gate |
|---|---|
| 0 | Every audit finding is either fixed or recorded as accepted, with a reason. Tree link check passes. |
| 1 | `chezmoi apply` on a scratch target succeeds and is idempotent (second apply is a no-op). `nvim --headless` starts with the new options and no error. |
| 2 | Shell-init files are generated and non-empty; `nvim --headless '+Lazy! sync' +qa` exits 0; the dev image builds; WezTerm launches with the intended appearance. |
| 3 | A configured `nu` starts, `cd` funnels correctly (start dir written), and each Track E task's own criteria pass headlessly. Capsule mounts a directory and lands in `/workspace`. |
| 4 | `tv` channels return data through `finder`; `git push` works inside a capsule (credential propagation); the editor's full acceptance sweep passes. |
| 5 | Directory-scoped history returns only this dir's commands; quicklist round-trips a pick; `help <topic>` renders. |
| 6 | `help --check` exits 0. `ls --help` still behaves. Full fresh-machine run: clone → apply → working daily driver. |

5. **Regression sweep at every gate.** Re-run the previous wave's gate, not
   just the current one. The cheap version: keep every gate as a script so the
   whole set is one command.
6. **The final gate is the manual.** `help --check` exiting zero means every
   binding that exists is documented and every documented binding exists —
   which is the closest thing this build has to a completeness proof
   ([`06-help/04`](../06-help/04-drift-check.md)).
7. **Fresh-machine test is non-negotiable.** The last gate runs on a machine
   (or VM/container) that has never seen this config. Everything else can pass
   on a developer box that already has the tools installed and prove nothing.

## Acceptance criteria

- Each gate is a script that exits non-zero on failure, runnable in one
  command.
- Interactive-only checks are listed per wave, and no gate silently depends on
  a human having looked.
- Running all gates from scratch on a clean machine passes end to end.
