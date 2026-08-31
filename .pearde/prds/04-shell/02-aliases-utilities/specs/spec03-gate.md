# spec03 — the gate: `tests/nushell-aliases.sh`

The node's `verify:` command. Proves spec01 and spec02 and the PRD's two
acceptance lines against a real nushell in an isolated HOME, following
`tests/nushell-core.sh`'s conventions rather than re-deriving them.

**Est:** 2h

**Footprint:** `tests/nushell-aliases.sh` (create)

## Shape

Bash, `set -u`, sources `gates/lib.sh` for `chk`/`chk_ok`. Reuses
`tests/nushell-core.sh`'s hard-won safety rules by reference, not paraphrase:
`/usr/bin/grep` always (plain `grep` resolves to ugrep in this environment);
scratch machines under the gate's own `mktemp -d`, never the live
`~/.config/nushell`; `env -i` with an explicit PATH on every `nu`
invocation; nothing installed, nothing written outside the scratch tree.
Machine setup mirrors `mk_machine` — `env.nu`, `config.nu`, `dirstack.nu`,
`pass.nu` staged at the literal paths config.nu sources, generated-init
stubs, poison bins.

Two stages, `--tree` and `--hermetic`, both by default.

## Checks

**tree** — the managed files as text:

- The eleven names of spec01 each defined once under the ALIASES anchor,
  with their exact expansions (`bat --paging=never`, `rg`, `git`, `lazygit`,
  `nvim`, `nvim ~/notes.md`, `exit` ×3, `chezmoi update --force`).
- `def cf [file: path]` present; the display-var guards
  (`WAYLAND_DISPLAY`, `DISPLAY`) present with their headless-hang comment.
- Absence: `alias bb`, `alias ba`, `burrito` nowhere in config.nu; `cdi`
  not in the ALIASES anchor.
- `source ~/.config/nushell/pass.nu` sits under the MODULES anchor; the ten
  anchors still present once each, in order (the `anchors_ok` predicate,
  lifted).
- Counterfactual: a scratch copy with `alias grep = rg` deleted FAILS the
  alias check, so the check can fail.
- The four `shell.nuon` entries this node's code must keep true are read,
  not rewritten: `verify:` targets `cat`, `cf`, `q`/`:q`/`/exit`, `rr`,
  `pass` name aliases/commands this change defines. The gate only READS the
  `.nuon` (the S4.18 precedent) and asserts its own sha over it is unchanged
  at exit.

**hermetic** — a real `nu` against the staged machine:

- `scope aliases` lists all eleven names; spot-check two expansions.
- `cf`: missing file → non-zero, `cf: no such file`; real file through a
  recording `pbcopy` stub first in PATH → exit 0, payload byte-identical
  (`cmp`); `$env.PATH` narrowed in-session so `which pbcopy` misses, stub
  `wl-copy` on PATH, `WAYLAND_DISPLAY`/`DISPLAY` hidden → `no clipboard
  tool found`, and the stub's invocation marker was NOT written — the guard,
  not the tool, made the decision.
- `nu-complete pass` with `PASSWORD_STORE_DIR` at a scratch store
  (`email/personal.gpg`, `site.gpg`) → verbs + `email/personal` + `site`,
  zero `.gpg` suffixes; with the var at a missing path → verbs only. This
  drives the PRD's "`pass <tab>` lists both verbs and store entries" through
  the same completer reedline calls, without a flaky pty tab dance —
  the extern→completer binding is the tree grep above.
- Stub `pass` binary: `pass generate -n -c foo 12` arrives intact.

## Acceptance

- [x] `bash tests/nushell-aliases.sh` exits 0 on the finished tree, with
      every check above printed and counted.
- [x] The counterfactual copy fails its check (shown in the run log), so a
      regressed config.nu cannot pass.
- [x] `bash tests/nushell-aliases.sh` run three consecutive times: same
      pass count, exit 0 each time — no sleep-driven flake.
- [x] `~/.cache/nushell` does not exist when the gate finishes, and the
      shas of the four managed nushell files and `shell.nuon` are unchanged
      by the run.

## Verify

```sh
bash tests/nushell-aliases.sh
```
