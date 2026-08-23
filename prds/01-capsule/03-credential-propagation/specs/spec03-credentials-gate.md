---
est: 3h
footprint:
  - tests/capsule-credentials.sh        # new file
  - gates/waves.tsv                     # wave-4 row, gates cell only
  - gates/manual/wave4.md               # appended C.3 items only
---

# spec03 — the standing proof (tests/capsule-credentials.sh) plus registration

Write `tests/capsule-credentials.sh`, the gate for spec01 and spec02, and
register it for wave 4. Three stages: `--tree` over the managed files as
text, `--script` driving spec02's setup script with no mounts present, and
`--hermetic` driving the real CLI under the pinned nushell against recording
shims for `docker`, `git` and `security` — no docker daemon, no network, and
above all **no access to the developer's real keychain or gh token**.

Style and safety follow `tests/capsule-lifecycle.sh` and
`tests/shell-claude.sh`: `gates/lib.sh`, tallying `chk`, `/usr/bin/grep`,
scratch machines under `gates_tmpdir`, `env -i` on every `nu` call,
`snapshot_paths` over the live paths this gate must not touch
(`~/.cache/capsule`, `~/.ssh`, `~/.gitconfig`, `~/.claude`,
`~/.config/capsule`), and a counterfactual for every text assertion.

## Footprint notes

- `gates/waves.tsv`: append `| external bash tests/capsule-credentials.sh`
  to the **gates cell of row `4`** (the row whose tasks include `C.3`).
  Nothing else in the file changes — one cell, so a scheduler can serialise
  on it rather than blocking the file.
- `gates/manual/wave4.md`: **append** the C.3 items at the end of the file.
  No existing entry is edited. `C.3` appears in no other checklist, which
  `gates/manual-coverage.sh` requires.
- If either shared file is held by another lane at implementation time, land
  the test and report the registration as owed (the dev-image spec02
  precedent).

## `--tree` — the files as text

Each check is a function, so the counterfactual (a deliberately broken
scratch copy) runs the identical check and must FAIL.

Over `home/dot_config/nushell/capsule.nu`:

- `_capsule_refresh_creds` and `_capsule_cred_mounts` each defined exactly
  once.
- The creds path is `.cache/capsule/creds` and the string
  `.config/capsule` never appears in a *write* position — the credential
  directory must never sit in the docker build context.
- Every credential mount ends in `:ro`; the count of `:ro` binds equals the
  four sources in spec01's table.
- The run line's workspace bind still precedes the credential mounts, and
  `capsule:latest` is still last.
- `GIT_TERMINAL_PROMPT=0` is set on the `git credential fill` call (without
  it a gate can hang on a terminal prompt), and both credential fields go
  through `url encode --all`.
- The setup exec is `bash /opt/capsule/setup-credentials.sh` with no `-u
  root` and no `sudo` anywhere in the file.
- Counterfactuals, each required to fail its own check: creds path rewritten
  under `.config/capsule`; `:ro` dropped from one mount;
  `GIT_TERMINAL_PROMPT` removed; `-u root` added to the setup exec.

Over `home/dot_config/capsule/executable_setup-credentials.sh`:

- `bash -n` parses it.
- Absences, each with a counterfactual: no `sudo`, no `useradd`, no write or
  `chmod`/`chown` targeting `/opt/capsule`, no copy of the host's
  `~/.ssh/config`, and no `StrictHostKeyChecking no` (only `accept-new`).
- Presences: the per-URL `helper =` reset for both `https://github.com` and
  `https://gist.github.com` followed by the `store --file=` line; the
  `core.pager` and `interactive.diffFilter` overrides; `.credentials.json`
  wired as a **symlink** and `.claude.json` as a **copy**; `chmod`/`install`
  modes `700` on `~/.ssh` and `600` on private keys.

Over `home/dot_config/capsule/Dockerfile` — one cross-check, cheap and worth
it because it is this node's headline failure mode: no `COPY` or `ADD`
instruction exists, so no host file can enter a layer. (C.1's gate owns the
image; this is a single line asserting the property this node depends on.)

## `--script` — spec02's script with nothing mounted

Run the deployed script under `env -i` with `HOME` pointed at a scratch
directory and `/opt/capsule` absent, as a normal (non-root) user:

- exits 0;
- prints one warning per missing source on stderr, each naming the source;
- creates `~/.ssh` mode `700` and writes no ssh `config` (no keys to name);
- writes `~/.gitconfig` mode `600` carrying the include and the credential
  resets — assert with `git config --file … --get-all
  credential.https://github.com.helper`, the parsed value, not a grep,
  because this repo wraps prose at 78 columns and grepping generated config
  has produced false negatives on this board before;
- a second run leaves every file byte-identical (idempotency), and
  `known_hosts` gains no duplicate line when seeded with a github.com entry;
- writes nothing outside the scratch `HOME` — proven by `snapshot_paths`
  over the live paths, not by inspection.

## `--hermetic` — the real CLI against recording shims

Extend `mk_cap` from `tests/capsule-lifecycle.sh` (copy it; do not source
another gate) with three shims in `$M/bin`, which is first on `PATH`:

- `docker` — the recording shim, unchanged in spirit: appends argv to
  `invocations.log`, answers `image inspect` / `container inspect` / `ps`
  from control files, logs and exits 0 for `build`/`run`/`start`/`rm`/`exec`.
- `git` — answers `credential fill` with a canned
  `username=gate-user` / `password=p:a@s/s w` (the punctuation is the point:
  it proves `url encode --all`), increments a call counter file, and defers
  everything else to `/usr/bin/git` so the `--script` stage's `git config
  --file` reads still work.
- `security` — answers `find-generic-password -s "Claude Code-credentials"
  -w` with a canned `{"claudeAiOauth":{"accessToken":"gate-token",…}}` and
  increments its own counter. **The real keychain is never read**; a
  counterfactual run with the shim removed must show the gate refusing to
  proceed rather than falling through to `/usr/bin/security`.

The scratch `HOME` carries fixtures: `.ssh/` with `id_gate` (0600) and
`id_gate.pub`, a `.gitconfig`, a `.claude.json` holding all six kept keys
plus `mcpServers` and `projects`, and
`.local/share/opencode/auth.json`.

Scenarios, each asserting the log and the filesystem:

1. **Fresh create.** `~/.cache/capsule/creds` exists mode `0700`; the four
   files exist mode `0600`; `git-credentials` is exactly
   `https://gate-user:p%3Aa%40s%2Fs%20w@github.com`;
   `claude-credentials.json` is the shim's payload;
   `claude.json` has the six kept keys and **no** `mcpServers` and **no**
   `projects`; `opencode-auth.json` matches the fixture.
2. **Mount flags.** The `run` line is workspace bind first, then the four
   credential binds each ending `:ro`, then `capsule:latest`.
3. **Setup exec, create path only.** `exec … bash
   /opt/capsule/setup-credentials.sh` appears exactly once, before
   `exec -it … zsh`, and carries neither `-u root` nor `sudo`. In a
   warm-attach machine (container running) it appears **zero** times, and
   `exec` totals one.
4. **Missing sources are skipped, not created.** A machine whose `HOME` has
   no `.ssh` and no `.gitconfig`: neither `-v` flag appears, and afterwards
   `$M/home/.gitconfig` still does not exist — docker must never be handed a
   missing bind source, because it materialises one as a directory.
5. **Revocation heals.** Seed all four creds files, then make the `git` and
   `security` shims exit non-zero, and mount: the corresponding creds files
   are **gone** afterwards. A stale token that outlives its source is the
   failure R5 names.
6. **Staleness short-circuit.** Two mounts back to back: the `git` shim's
   counter reads 1, not 2.
7. **Warm path refreshes in the background.** Container running, creds files
   aged past the window: the CLI returns, and the files are refreshed within
   a bounded poll (a few seconds); the counters read 1. The assertion is on
   the *outcome*, polled — never a fixed `sleep` long enough to be a
   flake-in-waiting.
8. **Nothing lands in the build context.** After every scenario,
   `$M/home/.config/capsule` holds no file whose content matches
   `password|accessToken|BEGIN .*PRIVATE KEY`.
9. **No docker.** `PATH` without the shim: non-zero exit naming docker, an
   empty log, **and** no creds directory — the refresh never runs ahead of
   the preconditions.
10. **Selftest controls** (a check that cannot fail proves nothing). Each
    drives a mutated copy of `capsule.nu` through the same harness and must
    FAIL its scenario: creds written under `.config/capsule` fails 8; `:ro`
    dropped fails 2; the stale-file removal deleted fails 5; the setup exec
    moved onto the warm path fails 3.

## Wave 4's manual checklist

Append to `gates/manual/wave4.md`, in the house format (`- [ ] **C.3** — …`
with `PASS:` / `FAIL:` lines, boxes left open — a pre-ticked box is the
failure `gates/manual-coverage.sh` exists to catch). The five checks a
machine cannot make, and this node's `verify` is the first of them:

- **`git push` over both protocols.** In a fresh capsule on a private repo:
  `git pull`, `git push`, then the same against an SSH remote, then
  `ssh -T git@github.com`. PASS: all four succeed with no prompt of any
  kind. FAIL: any password, passphrase or host-key question — and a
  "delta: not found" from the pager counts, because it means the container
  inherited a host-only tool.
- **The agents start authenticated.** Run `claude` and `opencode` inside a
  fresh capsule. PASS: both reach a working prompt with no login flow and no
  onboarding questions. FAIL: a login URL, a theme prompt, or an MCP server
  failing to start (which would mean the unfiltered host `.claude.json` got
  copied).
- **Nothing is in the image, and the host copy is untouchable.**
  `docker history --no-trunc capsule:latest` and, inside the capsule,
  `touch /opt/capsule/host/ssh/probe`. PASS: no credential material anywhere
  in the history, and the write fails read-only; `ls -la ~/.ssh` on the host
  is unchanged. FAIL: any token in a layer, or a write that lands on the
  host.
- **Rotation heals by reconnecting.** Rotate the gh token (`gh auth
  refresh`, or log out and back in), then re-enter the *same, still-running*
  capsule and push. PASS: the push works with no `--rebuild` and no
  container recreation. FAIL: a stale token, or the fix requiring a
  rebuild — that is the whole reason the creds directory is mounted as a
  directory.
- **A capsule created before this node landed.** Enter one and try to push.
  PASS: it fails, and `capsule --rebuild` fixes it — docker cannot add
  mounts to an existing container, so this is the documented answer rather
  than a bug. FAIL: the tool pretends the mounts are there, or `--rebuild`
  does not fix it.

## Acceptance

- [x] `bash tests/capsule-credentials.sh` exits 0 with docker, `gh` and the
      real keychain unreachable for the whole run.
      Ran 2026-08-23: `capsule-credentials: 102 pass, 0 fail`, exit 0.
      Stage totals: `--tree` 31, `--script` 32, `--hermetic` 39.
- [x] Every counterfactual and every selftest control exits non-zero with a
      FAIL line naming the violated rule, on every invocation.
      Eleven counterfactuals in `--tree` and five controls in `--hermetic`,
      each preceded by a check that the mutation really took, all green.
      Two of them caught real defects in this gate's own first draft (a
      comment satisfying a presence check, and a scenario function that
      rebuilt the shim it was supposed to be missing).
- [x] Scenario 1 asserts the percent-encoded credential line literally, so a
      token containing `:`, `@` or `/` cannot regress silently.
      The literal is `https://gate%2Duser:p%3Aa%40s%2Fs%20w@github.com`,
      not the `gate-user` this spec wrote: `url encode --all` encodes every
      non-alphanumeric, the hyphen included, and that `%2D` is the
      fingerprint of `--all` — plain `url encode` leaves the hyphen alone
      AND leaves `:` and `/` alone, which is the corruption the assertion
      exists to catch. Verified separately that `git credential-store`
      round-trips this exact line back to `gate-user` / `p:a@s/s w`.
- [x] Scenario 5 leaves no creds file behind once its source is gone.
      Both `git-credentials` and `claude-credentials.json` are gone after a
      mount whose shims exit non-zero, with a control (the drop calls
      commented out) that must fail it.
- [x] Scenario 9 leaves no `~/.cache/capsule/creds` directory at all.
      With no docker on PATH: non-zero exit naming docker, an empty
      invocation log, and no creds directory — the export never runs ahead
      of the preconditions.
- [x] The gate leaves no scratch state behind and never touches the live
      `~/.cache/capsule`, `~/.ssh`, `~/.gitconfig`, `~/.claude` or
      `~/.config/capsule` — proven by the `snapshot_paths` guard, in the
      same run, before and after.
      One deliberate narrowing, and it is a real finding rather than a
      convenience: `~/.claude` is watched as the single FILE
      `~/.claude/.credentials.json`, not as a tree. Claude Code rewrites
      `~/.claude/projects`, `history.jsonl` and `todos` while any agent
      session is open, so a directory listing there measures the agent and
      not the gate — it produced exactly that false FAIL on the first
      full-suite run. The file is the one thing this node could touch there
      (it is the Linux-layout fallback source), and its absence on macOS is
      the measured fact R4 turns on. `guard_begin`/`guard_end` also confirm
      the live chezmoi config and source-path unchanged in all three
      stages.
- [x] **Closed by the orchestrator on the transition.** Appended
      `| external bash tests/capsule-credentials.sh` to wave 4's gates cell;
      `bash gates/wave-status.sh` now reports `4  PENDING  8/18  9
      registered` (eight before). Original box: Wave 4's gates cell carries
      `external bash tests/capsule-credentials.sh`, or the report records
      the line as owed to the lane holding `gates/waves.tsv`.
      OWED, and it is the orchestrator's: `gates/waves.tsv` is a carve-out
      for this lane and another lane appended to the same row while this
      one ran. The verbatim segment to append to row `4`'s gates cell is in
      the implementation report.
- [x] **Closed by the orchestrator on the transition.** Appended the five
      `**C.3**` rows verbatim; `bash gates/manual-coverage.sh` → exit 0, 0
      FAIL, and `C.3` appears 5 times in `wave4.md` and in no other
      checklist. Original box: `bash gates/manual-coverage.sh` exits 0 with
      the five C.3 items in
      `gates/manual/wave4.md` and every box open.
      OWED, and it is the orchestrator's: `gates/manual/wave4.md` is a
      carve-out and two other nodes are appending to it concurrently. `bash
      gates/manual-coverage.sh` was run and exits 0 as the file stands
      today (no C.3 rows yet, and no rule requires them). The five rows to
      append are in the implementation report.

## Verify and Proof

```sh
# Hermetic throughout: no docker daemon, no network, no real keychain.
bash tests/capsule-credentials.sh
bash tests/capsule-credentials.sh --tree
bash tests/capsule-credentials.sh --script
bash tests/capsule-credentials.sh --hermetic

# Registration and checklist coverage.
bash gates/manual-coverage.sh
grep -n 'capsule-credentials' gates/waves.tsv

# The sibling gate this node's spec01 edits must still be green.
bash tests/capsule-lifecycle.sh
```
