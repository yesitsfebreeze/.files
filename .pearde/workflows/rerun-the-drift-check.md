---
atomic: rerun-the-drift-check
subject: "`help --check` is the one command that says the configuration and its manual still agree"
date: 2026-09-02
updated: 2026-09-02
runs: 3
---

## Do

1. `help --check` in a shell that loaded the config.

## Done when

- It exits 0 and reports `undocumented: 0` — the new surface is documented,
  not added to the allowlist.

## Fails when

- The check is piped — `help --check | tail`, `| grep` — and `$?` is then the
  PIPE's exit code, not nushell's. It reads as a clean 0 no matter what the
  check did. Run it as `nu ... -c 'help --check' >/dev/null; echo $?` when the
  exit status is what you are claiming.
- It exits 0 while reporting a non-zero `unresolved:` count. `unresolved` does
  NOT fail the check — measured 2026-09-02, `unresolved: 3` alongside
  `help --check: clean` and exit 0. Read the `undocumented:` line for your own
  surface; do not read a clean exit as "no findings".
- It reports `undocumented: 0` because the surface was added to `HC_ALLOW`
  rather than documented. Grep the allowlist and confirm it is unchanged — a
  passing check and a hidden surface look identical from the exit code.
