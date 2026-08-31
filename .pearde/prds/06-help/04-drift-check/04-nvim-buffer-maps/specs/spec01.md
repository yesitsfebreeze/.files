---
complexity: 18
footprint:
  - home/dot_config/nushell/help-check.nu
  - tests/help-drift-check.sh
---

# spec01 — the buffer-local targets, five resolved and three declared

Eight targets carry `scope: "buffer"` and are invisible to a global keymap
dump. The node's contract allowed either resolving them or declaring them
unresolvable **with the measurement**. Five resolve; three are declared, and
the declaration carries its numbers.

## What made five of them resolvable

The dump now opens a REAL FILE with a real extension (a `.lua` probe written
by the checker and handed over by env), so `BufEnter` and `FileType` have
fired by the time `nvim_buf_get_keymap(0, …)` is read. It rides along in the
existing spawn — no second process.

Three things were measured getting there:

- **`silent edit`, not `edit`.** A headless Neovim writing the "N lines"
  message to a stdout nushell was capturing died on SIGPIPE, exit -13, every
  run.
- **The output goes to a file, never through a pipe.** Same signal, from the
  same cause: the spawn now lives long enough (it waits for a language server)
  to write something. `out+err> $log` has no reader to go away. `complete`
  cannot wrap a redirection, so the status comes from `$env.LAST_EXIT_CODE`.
- **Wait on a condition, not a duration.** `vim.wait(2000, || #maps > 0)`
  rather than a fixed sleep: the event being waited for is a map arriving.

A language server really did attach in that window, which is why `gd`, `gI`,
`<leader>rn`, `<leader>ca` and `K` resolve.

## The three that are declared, with the measurement

`n q` and the autopairs `i <BS>` / `i <CR>` attach on events this dump does
not fire — `InsertEnter`, or a filetype other than lua. They are reported
UNRESOLVED, never stale, and the finding carries the numbers: how many LSP
clients attached and how many buffer maps the probe buffer had. A check that
cannot see a surface says so with evidence rather than guessing.

**Not done, deliberately:** starting a server for every filetype the manual
mentions. That is a mason install and seconds of wall clock inside a check
meant to run before every commit, and it would make the manual's correctness
depend on a network.

## Acceptance

- [x] `bash tests/help-drift-check.sh --nvim` exits 0.
- [x] Buffer-local targets are reported UNRESOLVED and **never** stale.
- [x] Five of the eight now resolve against the probe buffer; three are
      declared with the measurement in the finding text.
- [x] `help --check` reports `unresolved: 3`, and unresolved does not fail
      the run — the exit code counts stale, mismatched and undocumented only.
- [x] The mutation — a documented map at an lhs nothing binds — is STALE, and
      the report shows the NORMALIZED lhs, quoted, so a leading space is
      visible.

## Verify and Proof

```sh
cd "$(git rev-parse --show-toplevel)"
bash tests/help-drift-check.sh --nvim
```

Run 2026-08-30: rc 0, `unresolved: 3`, no stale nvim finding.
