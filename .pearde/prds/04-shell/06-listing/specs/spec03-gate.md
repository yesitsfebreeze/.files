# spec03 — the listing gate: tests/shell-listing.sh, registered

Delivers this node's standing proof: a gate script that holds spec01 and
spec02's acceptance to executable checks, plus its registration in the wave
registry. New file — `tests/nushell-core.sh` belongs to 04-shell/01 and is not
edited (one writer per file); its harness patterns are followed, not forked
into it.

**Est:** 1.5h

**Footprint:** `tests/shell-listing.sh`, `gates/waves.tsv`

## Shape

`bash tests/shell-listing.sh [--tree|--hermetic]`, no argument runs both.
Source `gates/lib.sh`. Follow `tests/nushell-core.sh`'s safety rules — they
are measured failures, not style: `/usr/bin/grep` always (bare `grep` is
ugrep here); every nu run under `env -i HOME="$S"` with a scratch HOME;
never snapshot `~/.config/nushell` wholesale; `~/.cache/nushell` must not
exist when the gate finishes; nothing installed, live tree untouched. The pty
runner precedent is `tests/nushell-core.sh:125` (`write_pty_runner`) and
`:276` (`nu_pty`) — copy the pattern into this script.

No `--apply` stage, and say so in the header: S.1's gate already proves
`config.nu` deploys byte-identical through a real `chezmoi apply`, and this
node adds content to that same file, not a new deploy path.

## --tree: the managed file as text

Each ordering or absence claim carries a counterfactual — a deliberately
broken copy in scratch that must FAIL the same check (the house style; see
`nushell-core.sh` S4.10/S4.11).

- `alias core-ls = ls` parses before `def ls`; `def ls` before `def la`;
  `def la` before the second `$env.config.hooks.env_change.PWD = (` block
  (first-match `line_of` comparisons).
- Zero hits for `du -sb` in `config.nu`; the du spawn line contains `-sk`,
  `* 1024` and pipes through `complete`; no `e> /dev/null` on the du spawn.
  Counterfactual: a copy with the spawn reverted to
  `^du -sb ...$dirs e> /dev/null` fails.
- The auto-list closure guards on `$nu.is-interactive` and contains
  `^stty sane` before `la` and the `$env._NAV?` read. Counterfactual: a copy
  guarding on `(is-terminal --stdout)` fails.
- Exactly two PWD append blocks, dirstack's first.
- All ten S.1 anchors still present once each, in order (own grep — do not
  call into `nushell-core.sh`).

## --hermetic: a real nushell in a scratch HOME

Fixtures: `$S/fix` with a subdir holding a 2 MiB file (`dd`), a dotfile, a
plain file with a known extension, and a `node_modules`-shaped subdir. Stubs
dir first on PATH where a check needs one.

- `ls | columns` puts `icon` immediately before `name`; rows sorted
  `type, modified`.
- Poison `du` stub (the `mk_poison` pattern): plain `ls` never invokes it,
  `ls -D` invokes it exactly once — one spawn for the whole listing.
- `ls -D` reports the 2 MiB fixture dir ≥ 2097152 bytes; plain `ls` reports
  it < 1048576. Real `/usr/bin/du` on the PATH for this check.
- Failing `du` stub (usage banner on stderr, exit 64): `ls -D` emits exactly
  one notice on stderr and the fixture dir shows its inode size — the L-1
  acceptance, both halves.
- `l`/`ll`/`la` resolve; `la` lists the dotfile `l` omits; `ll | columns` is
  a superset of `l | columns`.
- Pty: `cd` into the fixture dir prints its known filename exactly once;
  startup output contains no listing of the start dir.
- Pty: `stty -onlcr` then `cd` — the raw capture's listing region returns to
  column 0 (`\r\n` line endings), proving `stty sane` ran first.
- Pty: `$env._NAV = "x"` then `cd` prints no listing.
- `nu -c 'cd /tmp'` prints nothing (non-interactive guard).

## Registration

Append `external bash tests/shell-listing.sh` to the wave 4 `gates` cell of
`gates/waves.tsv`, `|`-separated after the existing entry. `external` because
the script lives in `tests/` and the `--selftest` contract is not imposed on
external gates — `gates/selftest.sh` reports it unverified-by-contract rather
than failing; the counterfactuals above are this script's own falsification.

## Acceptance

- [x] `bash tests/shell-listing.sh` exits 0 on the finished spec01+spec02
      work, printing one `chk` line per check above. — EXIT=0, 2026-08-22;
      T1–T5 and H1–H10 all PASS.
- [x] Every counterfactual copy fails its check — shown in the gate's own
      output, not asserted in prose. — five counterfactual PASS lines
      (core-ls order, reverted du spawn, is-terminal guard, second append
      removed, LISTING-below-FUNNEL).
- [x] Breaking the real file breaks the gate: reverting the du line to
      `du -sb` in a scratch copy of the repo (or via `GATES_*` mutation)
      makes `--tree` exit non-zero. — `SHELL_LISTING_CONFIG=<reverted copy>
      bash tests/shell-listing.sh --tree` exited 1, failing exactly T2.
- [ ] `gates/waves.tsv` wave 4 names the gate; `bash gates/selftest.sh` still
      exits 0. — HALF MET: the wave 4 gates cell names
      `external bash tests/shell-listing.sh` (registered 2026-08-22), and
      selftest reports it external/unverified-by-contract as specced. But
      `gates/selftest.sh` exits 1 on `gates/wave-status.sh --selftest`, which
      still reads the retired `.mi/prds/` paths
      (`sed: .mi/prds/06-help/prd.md: No such file or directory`). Measured
      pre-existing: the selftest FAIL set is byte-identical with this node's
      registration removed. wave-status.sh belongs to the gates node — needs
      a correction there, not a fix from this lane.
- [x] `~/.cache/nushell` does not exist after a full run;
      `shasum` of `home/dot_config/nushell/{config,env,dirstack}.nu` is
      unchanged by running the gate. — the gate's own closing checks, both
      PASS on every run.
- [x] `bash tests/nushell-core.sh` and `nu tests/help-content-model.nu` still
      exit 0. — EXIT=0 and `ok`, 2026-08-22.

## Verify

```sh
cd /Users/feb/dev/dotfiles
bash tests/shell-listing.sh
bash tests/nushell-core.sh
nu tests/help-content-model.nu
bash gates/selftest.sh
/usr/bin/grep -n 'shell-listing' gates/waves.tsv   # wave 4 row
```
