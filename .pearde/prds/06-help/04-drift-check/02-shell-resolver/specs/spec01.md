---
complexity: 14
footprint:
  - home/dot_config/nushell/help-check.nu
  - tests/help-drift-check.sh
---

# spec01 — the shell surface, and the four wrong-kind defects

R1 resolves `keybinding`, `alias` and `command` targets against a CONFIGURED
shell — by construction, not by spawning one: `help-check.nu` is sourced by
the config it reads, so `$env.config.keybindings` and `scope aliases` are the
live ones. A spawned `nu -c` would report none of this config's bindings and
call the whole manual stale.

## The four wrong-kind defects, named and corrected

Found by running the resolver rather than by reading the corpus:

- `z <query>`, `zi`, `zz` carried `{kind: "command"}`. All three are
  **aliases** — measured, `scope aliases` has them and `scope commands` does
  not — so all three resolved to nothing and reported stale.
- `pass <tab>` carried `{kind: "command", name: "pass"}`. `pass` is an
  external binary and nushell reports no handle for it at all; what this
  config adds is the completer. The target now names `nu-complete pass`,
  which fixes the entry in **both** directions at once — it was stale, and
  the completer it should have named was in the undocumented list.

## Acceptance

- [x] `bash tests/help-drift-check.sh --shell` exits 0.
- [x] Zero stale shell targets against the live configured shell.
- [x] A bare `nu -c` sees **none** of this config's keybindings — the reason
      the check is not spawned. (It sees eight: nushell's own, which is why
      they are on the allowlist. The gate's earlier claim of "zero" was
      wrong and is corrected in place.)
- [x] The mutation — an entry for `ghostcmd`, a command that does not
      exist — is reported STALE, and the gate asserts the mutation was really
      written into the staged corpus first.

## Verify and Proof

```sh
cd "$(git rev-parse --show-toplevel)"
bash tests/help-drift-check.sh --shell
```

Run 2026-08-30: rc 0. `help --check` reports 0 stale, 0 mismatched,
0 undocumented.
