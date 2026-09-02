---
atomic: prove-in-a-shell-that-loaded-the-config
subject: "`nu -c` loads no config and reports a correct change as absent — this is the step that catches the false negative"
date: 2026-09-02
updated: 2026-09-02
runs: 2
---

## Do

1. Never test with `nu -c` alone: it loads neither `env.nu` nor `config.nu`,
   and inherited variables make it look as though it did.
2. `nu --env-config ~/.config/nushell/env.nu --config ~/.config/nushell/config.nu -c '<check>'`
3. Then the shell nobody handed a path to: `tmux new-session -d -s probe nu`,
   `send-keys` the check, `capture-pane`, kill the session.

## Done when

- Both forms answer, and the check names a variable or alias that did not
  exist before this change.

## Fails when

- The tmux probe is read before the shell has finished starting, and
  `capture-pane` returns an empty or half-drawn pane that greps as a failure.
  nushell's startup is not instant: allow ~6s after `new-session` and ~8s
  after `send-keys` before capturing, as `probe/verify.sh` does.
- The check names a variable that already existed. Then both forms answer and
  neither proves anything about this change. Pick a name that did not exist
  before the change — that is what makes the check falsifiable.
- The probe enumerates the FAILURE strings and defaults to success. nushell
  0.115.1 answers an unresolved alias with "Command `x` not found" under a
  nu::shell::external_command banner — not "unknown command", not "executable
  was not found" — so a probe written against those two strings grades a
  missing alias OK. Match the SUCCESS shape positively and make the default
  arm fail; measured 2026-09-02.
- The bare-shell step is skipped when `tmux` is absent and the probe still
  exits 0. That step is the only one proving the shell you actually get loads
  the config; every other check names both config paths explicitly. A skipped
  bare-shell check must FAIL the probe, not pass it quietly.
