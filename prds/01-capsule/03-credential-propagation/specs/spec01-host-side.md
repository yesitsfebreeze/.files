---
est: 2h
footprint:
  - home/dot_config/nushell/capsule.nu
  - tests/capsule-lifecycle.sh   # three edits — see "Footprint notes"
---

# spec01 — the host side: refresh the credential material, mount it in

Extend `home/dot_config/nushell/capsule.nu` (C.2's module, `done`) with the
host half of this node: a refresh step that exports the host's credential
material into one state directory, the bind mounts that hand that directory
and the host's `.ssh`/`.gitconfig` to the container read-only, and the
first-run `docker exec` that runs spec02's setup script. No new command and
no new key: `capsule` gains behaviour, not surface.

## Footprint notes

`tests/capsule-lifecycle.sh` is C.2's gate. C.2 is `done`, so the lane is
free; if a corrections lane holds the file at implementation time, land the
module and report the three edits as owed (the dev-image spec02 precedent).
The edits are:

1. `mk_cap`: add a `security` shim and a `git` shim to `$M/bin`, and a
   scratch `$M/home/.config/capsule/setup-credentials.sh`. Without the two
   shims the new refresh reaches the developer's **real** keychain and real
   `gh` token from inside a gate — the shims keep that gate hermetic, which
   is its own stated contract.
2. Scenario 1's run-line assertion (`^run -d --name … -v $dir:/workspace
   capsule:latest$`): the `$` anchor now fails, because the credential
   mounts sit between the workspace bind and the image name. Relax it to
   require the workspace bind **first** and `capsule:latest` last, e.g.
   `^run -d --name $name --label capsule\.dir=$dir -v $dir:/workspace .*
   capsule:latest$`.
3. Nothing else. Scenarios 2, 3 and 4 assert `exec` occurs exactly once, and
   they stay green *only* because the setup exec fires on the create path
   alone (see step 7 below) — do not "fix" them by raising the count.

## Design

### Where the material lives, and where it must never live

One state directory: `~/.cache/capsule/creds`, mode `0700`, files `0600`.
It sits beside C.4's `recents.nuon` under `~/.cache/capsule` because it is
runtime state, not configuration — `chezmoi apply` never touches it and it is
outside the repo, so no token can be committed.

It is **not** under `~/.config/capsule`, and that is a hard rule with a
reason: `~/.config/capsule` is the docker **build context** (`_capsule_build`
passes it as the context path). A credential file there would be one `COPY .`
away from a layer, which is the exact failure this node exists to prevent.
The legacy attempt made the mirror-image mistake — it wrote the plaintext
token to `~/.files/user/.config/WezTerm/.cache/git-credentials`, i.e. inside
the dotfiles tree itself.

`~/.cache/capsule/creds` is mounted as a **directory**, never as individual
files. A file bind mount pins an inode: the refresh writes each file to a
temp name and renames it into place, which is atomic but replaces the inode,
and a file bind would keep showing the container the old content forever. A
directory bind shows the rename immediately — that is what lets a refresh
reach an **already running** capsule, which is R5's "heals on the next
mount".

### `_capsule_refresh_creds` — the exporter

Four files, each written only when its host source is available, and each
**removed** when the source is gone (a revoked credential must disappear, not
linger):

- `git-credentials` — from
  `printf 'protocol=https\nhost=github.com\n' | git credential fill`, run
  with `GIT_TERMINAL_PROMPT=0` in the environment and stdin closed, through
  `complete`. On a non-zero exit or missing `username=`/`password=` lines:
  skip, no file, no error. Written in credential-store format, one line:
  `https://<user>:<pass>@github.com`, with both fields through
  `url encode --all` — a token containing `:`, `@` or `/` silently corrupts
  the line otherwise. `GIT_TERMINAL_PROMPT=0` is load-bearing: with no
  helper reachable, `git credential fill` otherwise blocks on a terminal
  prompt, and a gate that runs it would hang rather than fail (verified
  2026-08-23: with an empty `HOME` it exits 128 with "terminal prompts
  disabled").
- `claude-credentials.json` — from
  `security find-generic-password -s "Claude Code-credentials" -w`. This is
  the macOS-only fact that R4's wording does not cover: on this host Claude
  Code keeps its OAuth tokens in the **login keychain**, and
  `~/.claude/.credentials.json` does **not exist** (verified 2026-08-23), so
  mounting `~/.claude` would propagate no credential at all. The keychain
  item's payload is exactly the file's format —
  `{"claudeAiOauth": {"accessToken", "refreshToken", "expiresAt", "scopes",
  …}, "mcpOAuth": {…}}` — so it is written through unchanged. Fall back to
  copying `~/.claude/.credentials.json` when the keychain item is absent
  (the Linux-style layout). Parse-check it (`from json`) before writing:
  never publish a truncated credential file.
- `claude.json` — a **filtered** projection of `~/.claude.json`, not a copy:
  keep `hasCompletedOnboarding`, `theme`, `installMethod`, `userID`,
  `firstStartTime` and `oauthAccount`, drop everything else. It exists only
  so the agent skips onboarding. The host file is 671 KB and its
  `mcpServers` and `projects` keys name host paths and every project the
  user has ever opened; copying it would drag phantom MCP servers and the
  whole project history into every container. Nushell parses JSON natively,
  so this is `open ~/.claude.json | select …` with optional access, not a
  text edit.
- `opencode-auth.json` — a copy of `~/.local/share/opencode/auth.json` when
  present (184 bytes on this host).

Notably absent: the whole of `~/.claude`, `~/.claude.json` and
`~/.local/share/opencode`. This is a deliberate narrowing of R4's letter
("mount … auth/config directories"), and R4's purpose — the preinstalled
agents work without a login flow — is met by the four files above. The
reasons, so nobody re-widens it by accident:

- `~/.claude` holds `history.jsonl` and `projects/` — every transcript from
  every project. A capsule is where third-party project code runs; handing
  that container the user's whole agent history buys nothing.
- host agent *settings* encode host paths (statusline scripts, hooks,
  plugin marketplaces under `/Users/…`). Inside the container they fail on
  every prompt, so inheriting them is worse than not having them.
- `~/.local/share/opencode` holds a 94 MB SQLite database with WAL
  sidecars. A Docker Desktop bind mount is the wrong medium for a live
  SQLite WAL, and the container has no reason to share the host's session
  store.

If the user later wants the host's full agent configuration inside capsules,
it is one more `-v … :ro` line plus a symlink in spec02 — but it is a
decision, not a default.

### Cost, and why the warm path refreshes in the background

Measured on this host, 2026-08-23: `git credential fill` through the host's
`!gh auth git-credential` helper takes **0.75–1.16 s**, and the keychain read
**0.34–0.50 s**. Done synchronously on every mount that is ~1.5 s added to
the warm attach, which breaks C.2 R2 ("well under one second") and the epic's
"reconnecting to a running capsule feels instant". So:

- **create path** (no container, or `--rebuild`): refresh **synchronously**.
  The mount source must exist before `docker run`, and a cold start is
  dominated by docker anyway.
- **attach path** (container exists, running or stopped): refresh in a
  background job (`job spawn { _capsule_refresh_creds }`, available in the
  pinned nu 0.114.1). The parent then blocks in `docker exec` for the whole
  session, so the job finishes long before anything inside reads a
  credential — and because the creds directory is a directory mount, the
  fresh token appears **inside the running session**, which is strictly
  better than "on the next mount".
- **staleness short-circuit**: skip the refresh entirely, foreground or
  background, when every file in the creds directory is younger than 60 s.
  A burst of mounts must not fire a burst of `gh` calls.

### `_capsule_cred_mounts` — the flag list

Returns a flat list of `-v` arguments, in this order, **after** the workspace
bind and before the image name:

| Host source | Container path | Mode |
|---|---|---|
| `~/.ssh` | `/opt/capsule/host/ssh` | `ro` |
| `~/.gitconfig` | `/opt/capsule/host/gitconfig` | `ro` |
| `~/.cache/capsule/creds` | `/opt/capsule/creds` | `ro` |
| `~/.config/capsule/setup-credentials.sh` | `/opt/capsule/setup-credentials.sh` | `ro` |

Every source that does not exist is **skipped**, not passed: docker
materialises a missing bind source as an empty *directory* on the host, and a
`~/.gitconfig` turned into a directory is real damage. `:ro` on all four is
not decoration — nothing the container does can write back to the host's keys
or config, and the SSH keys in particular are copied inside the container
precisely because they must be modified (permissions) without touching the
host copy.

The creds directory is created by the refresh, so it always exists by the
time the mounts are computed; the other three are genuinely optional.

Two staleness notes to carry into the code as comments: `~/.gitconfig` and
the setup script are **file** binds, so a host edit that replaces the file
(`git config` writes via rename) is invisible to containers that already
exist — `capsule --rebuild` is the fix, and that is acceptable for identity
and aliases. And a capsule created **before** this node landed has no
credential mounts at all, because docker cannot add mounts to an existing
container: `capsule --rebuild` is again the fix, and the manual gate says so.

### The flow, as edited

Numbering follows C.2's spec01 so the diff reads against it:

1–2. unchanged (target resolution; docker and Dockerfile preconditions).
3. **new, after the preconditions and before the build:** if the container
   does not exist yet (or `--rebuild` was passed), `_capsule_refresh_creds`
   synchronously; otherwise `job spawn { _capsule_refresh_creds }`. Never
   before the docker precondition — C.2's gate asserts that a missing docker
   means *nothing happened*, and that stays true.
4–7. unchanged (build; name; foreign-container refusal; `rm -f` only under
   `--rebuild`).
8. `docker run` gains `_capsule_cred_mounts` between the workspace bind and
   the image name.
9. **new, create path only:** when the container was just created and
   `~/.config/capsule/setup-credentials.sh` exists,
   `^docker exec $name bash /opt/capsule/setup-credentials.sh`. As `dev`, not
   root: the image already creates the user (C.1 R5) and the script writes
   only inside `$HOME`, so no `-u root` and no `sudo` anywhere — the legacy
   script ran as root and created users, and none of that survives the
   consolidation. A non-zero exit prints one stderr line naming the script
   and **continues to the attach**, so a broken setup leaves a usable
   container to debug in rather than no container at all.
10–11. unchanged (`_capsule_record`, then `docker exec -it $name zsh`).

## Acceptance

- [x] `nu -n -c 'source home/dot_config/nushell/capsule.nu'` exits 0.
      Ran 2026-08-23: exit 0, no output.
- [~] With a real host: `capsule` in a fresh directory creates
      `~/.cache/capsule/creds` mode `0700` holding `git-credentials` mode
      `0600` whose single line matches
      `^https://[^:]+:[^@]+@github\.com$`, and
      `claude-credentials.json` mode `0600` that parses as JSON and has a
      `claudeAiOauth.accessToken` key.
      `capsule` itself was NOT run: that needs the managed tree deployed to
      the live home plus a real image build, which is the wave-4 manual row.
      What was executed instead, against the REAL keychain and the REAL `gh`
      helper with `HOME` pointed at a scratch directory (read sources
      symlinked in, so every write landed in the scratch tree and the live
      `~/.cache/capsule` listing was unchanged): `_capsule_refresh_creds`
      produced the creds directory at `700` and all four files at `600`;
      `git-credentials` was one line matching
      `^https://[^:]+:[^@]+@github\.com$`; `claude-credentials.json` was
      byte-identical to the keychain payload and carried
      `claudeAiOauth.accessToken`. Also proven there and not asked for:
      handing that exported file to `git credential-store` returns the same
      username and password as the host helper (sha256 of both outputs
      equal), so the `url encode --all` round-trip is correct on the real
      token. No credential value was printed at any point.
- [x] `claude.json` in the creds directory has exactly the six filtered keys
      and **no** `mcpServers` and **no** `projects` key.
      Proven twice: against the real 671 KB `~/.claude.json`
      (the six keys in order, and
      `mcpServers present=false projects present=false`), and hermetically
      against a fixture carrying both forbidden keys
      (`tests/capsule-credentials.sh --hermetic`, scenario 1).
- [~] `docker inspect --format '{{json .Mounts}}' <name>` on a fresh capsule
      shows the workspace bind plus every existing credential source, and
      every credential mount reports `"RW": false`.
      `docker inspect` was not run — no container was created. Hermetic
      scenario 2 asserts the whole `run` line instead: workspace bind first,
      then the four credential binds each ending `:ro`, then
      `capsule:latest`, with a selftest control proving a dropped `:ro`
      fails it.
- [~] Nothing under `~/.config/capsule` holds credential material:
      `grep -rl -e 'password' -e 'accessToken' ~/.config/capsule` finds
      nothing.
      Ran it: clean — but VACUOUSLY, because `~/.config/capsule` does not
      exist on this host yet (nothing is deployed). The substantive proof is
      hermetic scenario 8, which runs the same grep over the deployed-shape
      build context of eight scenario machines and has a selftest control
      (creds path rewritten under `.config/capsule`) that must fail it.
- [~] Warm attach cost is unchanged: with the container already running,
      `capsule` reaches the container's prompt in well under a second, and
      the creds files are refreshed by the time the session is usable.
      The felt latency needs a real container and a human, so it stays on
      the manual list. Hermetic scenario 7 proves the mechanism: a warm
      attach asks docker for the attach only (no build, no run, no rm), the
      refresh runs in the background, and a stale exported token is replaced
      inside the already-running session — polled, never slept on.
- [~] Temporarily move `~/.gitconfig` aside and run `capsule` in a fresh
      directory: it succeeds, the run line carries no gitconfig mount, and
      `~/.gitconfig` has **not** been recreated as a directory.
      Done against the recording shim rather than the live `~/.gitconfig`,
      which a gate must not move: hermetic scenario 4 uses a HOME with
      neither `.ssh` nor `.gitconfig`, asserts neither bind is passed, and
      asserts afterwards that neither path was created.
- [x] `bash tests/capsule-lifecycle.sh` exits 0 after the three edits, with
      no docker, no `gh` and no real keychain reachable from the run.
      Ran 2026-08-23: `capsule-lifecycle: 49 pass, 0 fail`, exit 0.

## Verify and Proof

```sh
# Parse (hermetic).
nu -n -c 'source home/dot_config/nushell/capsule.nu'

# C.2's gate, with the three edits in place: still fully hermetic.
bash tests/capsule-lifecycle.sh

# Real host, from a scratch directory (Docker Desktop running):
#   capsule            # cold: sync refresh, create, setup exec, attach
ls -le ~/.cache/capsule/creds
sed -E 's#//[^@]*@#//<REDACTED>@#' ~/.cache/capsule/creds/git-credentials
nu -c 'open ~/.cache/capsule/creds/claude.json | columns'
docker inspect --format '{{json .Mounts}}' <name> \
  | nu -c 'from json | select Source Destination RW'
grep -rl -e password -e accessToken ~/.config/capsule || echo "clean"
```
