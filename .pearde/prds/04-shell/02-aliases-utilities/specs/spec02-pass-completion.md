# spec02 — `pass.nu`: extern completion for the password store

Covers **R6** of [`../prd.md`](../prd.md). Creates the module, sources it at
config.nu's MODULES anchor, and makes the one cross-node edit that keeps the
S.1 gate alive — said loudly below, not buried.

**Est:** 1h

**Footprint:** `home/dot_config/nushell/pass.nu` (create),
`home/dot_config/nushell/config.nu` (MODULES anchor: one `source` line),
`tests/nushell-core.sh` (one line in `mk_machine`)

## Exact files touched

- **create** `home/dot_config/nushell/pass.nu` → deploys to
  `~/.config/nushell/pass.nu`. The live file, ported: a
  `def "nu-complete pass" []` that resolves the store from
  `$env.PASSWORD_STORE_DIR?` defaulted to `~/.password-store`, globs
  `**/*.gpg`, strips the store prefix and the `.gpg` suffix
  (`email/personal.gpg` → `email/personal`), returns `[]` when the store
  does not exist, and appends the entries to the subcommand list
  (`init ls find grep show insert edit generate rm mv cp git help version`);
  then `extern "pass" [...args: string@"nu-complete pass"]`.
- **edit** `config.nu`: `source ~/.config/nushell/pass.nu` under
  `# ── MODULES ──`, replacing that anchor's "must stay EMPTY" sentence with
  a reservation note for the modules still to come (finder.nu, quicklist.nu).
    A `source` of a missing file is a parse error that discards the whole of
  `config.nu` — the definitions above the failing line as well as those
  below. Interactively the shell still reaches a prompt, so the result is a
  working but naked REPL; `nu -c` prints the error, never runs the command,
  and exits 1. The GENERATED anchor in `config.nu` carries the measurement.
  That is why the line could not pre-exist; chezmoi deploys both files in
  the same apply, so the pair is atomic on a real machine.
- **edit** `tests/nushell-core.sh`, `mk_machine` only: `cp` the repo's
  `pass.nu` into the scratch machine beside `dirstack.nu`.

## Decisions

**D1 — the `mk_machine` edit is a cross-node edit, and it is unavoidable.**
`mk_machine` stages only `dirstack.nu` plus the three generated-init stubs;
the moment config.nu sources `pass.nu`, every hermetic and apply check in
S.1's gate dies with `nu::parser::sourced_file_not_found`. The MODULES
anchor was designed for later nodes to fill, so the gate's machine has to
learn the module in the same change. One `cp` line, with a comment naming
this node; nothing else in that file is touched, and
`bash tests/nushell-core.sh` green after the edit is an acceptance box.

**D2 — `PASSWORD_STORE_DIR` is not set in `env.nu`.** The live `env.nu`
sets it to exactly the documented default, `~/.password-store`, so the
completer's `default` branch lands on the same path and `env.nu` —
[`01-core-config`](../../01-core-config/prd.md)'s closed lane — stays
untouched. The live module's comment claims "PASSWORD_STORE_DIR is set in
env.nu"; that sentence does not survive the port. The var is still honoured
when the environment provides one, which is what R6 asks.

**D3 — `extern` adds completion and nothing else, measured.** Run on this
machine's nushell 0.114.1 against a stub binary: `pass generate -n -c foo 12`
arrives as `generate -n -c foo 12` — undeclared flags pass straight through
the rest-arg. The completer is also directly callable
(`nu-complete pass`), which is what lets the gate test it without a pty.

## Acceptance

- [x] `pass.nu` exists in the managed tree; sourcing config.nu in a scratch
      machine parses — no `sourced_file_not_found`.
- [x] With `PASSWORD_STORE_DIR` pointing at a scratch store holding
      `email/personal.gpg` and `site.gpg`, `nu-complete pass` returns the 13
      verbs plus `email/personal` and `site` — no `.gpg` anywhere in the
      output.
- [x] With `PASSWORD_STORE_DIR` pointing at a path that does not exist,
      `nu-complete pass` returns exactly the verbs.
- [x] With a stub `pass` binary first in `PATH`,
      `pass generate -n -c foo 12` reaches the stub with all four arguments
      intact.
- [x] `/usr/bin/grep -qF 'string@"nu-complete pass"' home/dot_config/nushell/pass.nu`
      — the completer is bound to the extern's rest-arg, so `pass <tab>`
      offers verbs and entries.
- [x] `bash tests/nushell-core.sh` exits 0 after the `mk_machine` edit.

## Verify

```sh
bash tests/nushell-aliases.sh    # spec03's gate; covers every box above
bash tests/nushell-core.sh
```
