# spec03 — the lifecycle gate (tests/capsule-lifecycle.sh)

Write `tests/capsule-lifecycle.sh`, the standing proof for spec01 and
spec02: a `--tree` stage over the managed files as text and a `--hermetic`
stage that drives the real CLI under a real nushell against a recording
`docker` shim — no docker daemon, no network. Register it as a wave-3 gate.
Style and safety rules follow `tests/shell-claude.sh`: `gates/lib.sh`,
tallying `chk`, `/usr/bin/grep`, scratch machines under `gates_tmpdir`,
`env -i` on every `nu` call, live tree untouched, and a counterfactual for
every text assertion.

**Est:** 3h

**Footprint:** `tests/capsule-lifecycle.sh`, `gates/waves.tsv` (one line —
**held by the T.2 lane**: if still held at implementation, land the test
and report the registration as owed, the dev-image spec02 precedent)

## Design

`bash tests/capsule-lifecycle.sh [--tree|--hermetic]`; no argument runs both.

**`--tree` — the files as text.** Checks as functions so each
counterfactual (a deliberately broken scratch copy) runs the same check and
must FAIL:

- capsule.nu exists; its defs appear exactly once each, in spec01's parse
  order, helpers before `def capsule` before the two subcommand defs.
- config.nu: `source ~/.config/nushell/capsule.nu` exactly once, after the
  MODULES anchor, after the zoxide.nu line, before PALETTE; the ten anchors
  present once each, strictly increasing (shell-claude.sh's `anchors_ok`).
- `tests/nushell-core.sh` `mk_machine` carries the capsule.nu `cp` line —
  the sibling gate must not be left to parse-fail.
- wezterm.lua: the `d` and `b` `CTRL|SHIFT` entries with `SendString` of
  `capsule\r` and `capsule --rebuild\r`; the `F6` and `q` entries still
  present. (Skip with a named SKIP line, not a PASS, while spec02's edit is
  owed to the T.2 lane.)
- C-3 regression absences in capsule.nu: no `~/docker`, no `just `, no
  `workspace/` in the mount target — the bind is `($target):/workspace`
  with the interpolated variable; and capsule.nu never calls `cd ` (the
  tool has no working directory of its own).
- Counterfactuals: source line moved below PALETTE; def order swapped;
  SendString payload altered; mount target rewritten to
  `($target)/workspace`. Each must exit the check non-zero, every run.

**`--hermetic` — the CLI against a recording shim.** A scratch HOME holds
`.config/capsule/Dockerfile` (any content — only its sha256 matters) and a
bin dir first on PATH with a `docker` sh script that appends its argv to
`invocations.log` and answers from control files: `image inspect` prints
the contents of `image-hash` or exits 1 when absent; `container inspect`
answers from a per-name state file (absent / running / stopped, with the
`capsule.dir` label); `ps` prints the canned owned-set rows; `build`,
`run`, `start`, `rm`, `exec` log and exit 0. Every scenario runs
`nu -n -c 'source <capsule.nu>; ...'` via `env -i` with the scratch HOME,
then asserts the log:

1. **Fresh create.** No image, no container: log shows `build` (with
   `-t capsule:latest`, `--label capsule.dockerfile=<sha256 of the scratch
   Dockerfile>`, `-f`), then `run -d` with `--name capsule-<san>-<hash8>`,
   `--label capsule.dir=<dir>`, `-v <dir>:/workspace`, then `exec` — in
   that order.
2. **Warm attach (R2/R3).** Hash matches, container running: log shows
   `exec` and no `build`, no `run`, no `rm`.
3. **Stopped (R2).** `start` then `exec`; no `build`, no `rm`.
4. **Auto rebuild (R3).** Changed Dockerfile, container running: exactly
   one `build`; no `rm`, no `run` — attach to the existing container.
5. **Forced (R4).** Matching hash, `--rebuild`: `build`, `rm -f`, `run`,
   `exec`.
6. **Mount source (R5).** `capsule /scratch/some/path` run from an
   unrelated cwd: the `run` line carries `-v /scratch/some/path:/workspace`
   — not the cwd, not a `workspace/` subpath.
7. **Naming (R1).** Same dir twice → identical `--name`; two dirs both
   named `api` under different parents → different names.
8. **List (R6).** Canned `ps` rows: one running capsule, one stopped
   capsule, one foreign container. Output holds exactly the two capsule
   rows with dir and running/stopped; the foreign name appears nowhere.
9. **Clean (R6).** `capsule clean`: `rm` of the stopped name only.
   `capsule clean --all`: the running one too. The foreign name never
   appears after `rm` in the log, in either mode.
10. **Recents (R7).** After scenario 1, `recents.nuon` holds the dir; seed
    20 entries plus a duplicate of the target, mount: head is the target,
    length is 20, duplicate gone. Make `~/.cache/capsule` unwritable,
    mount: `exec` still reached, one stderr line, exit 0.
11. **No docker.** PATH without the shim: non-zero exit, an error naming
    docker, empty log.
12. **Selftest controls** (a check that cannot fail proves nothing), each
    against a mutated scratch copy of capsule.nu and each required to FAIL
    its scenario: mount target `($target)/workspace` fails 6; `rm` moved
    outside the owned set (drop the label filter) fails 9; recording before
    the container check fails 11's empty-log assertion.

**Wave registry.** Append `external bash tests/capsule-lifecycle.sh` to
wave 3's gates cell in `gates/waves.tsv` — both stages are hermetic, so the
full run is wave-safe. See the footprint's collision note.

## Acceptance

- [x] `bash tests/capsule-lifecycle.sh` exits 0 with docker absent from
      PATH for the whole run.
- [x] Every counterfactual and selftest control exits non-zero with a FAIL
      line naming the violated rule, on every invocation.
- [x] Scenario 4's log shows one `build` and zero `rm` — the auto path
      proven non-destructive, not asserted.
- [x] Scenario 9 leaves the foreign container name out of every `rm` line.
- [x] The gate leaves no scratch state behind and never touches the live
      `~/.config/nushell` or `~/.cache/capsule`.
- [x] Wave 3's gates cell carries
      `external bash tests/capsule-lifecycle.sh`, or the report records the
      line as owed to the lane holding `gates/waves.tsv`.

## Verify

```sh
# Hermetic throughout: no docker daemon, no network.
bash tests/capsule-lifecycle.sh
bash tests/capsule-lifecycle.sh --tree
bash tests/capsule-lifecycle.sh --hermetic
```
