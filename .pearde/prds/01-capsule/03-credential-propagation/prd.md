---
state: done
claim: 
priority: 12
est: 7h
actual: 35m
task: C.3
mode: afk
needs:
  - 01-capsule/01-container-lifecycle
  - 06-help/01-content-model
verify: ""
---

# Credential propagation into containers

Parent: [Capsule epic](../prd.md) · C 8 · U 8 · source: "Credential propagation into containers" (C 8 / U 8)

Purpose: A capsule can pull, push, and SSH exactly like the host, with zero
re-authentication, while keeping secrets read-only and off the image.

## Requirements
- [x] **R1** — **SSH.** Mount `~/.ssh` read-only; first-run setup copies keys
      to a container-local dir with the modes each file actually needs — 700
      on the directory, 600 on private keys and generated config, **644 on
      `*.pub`** — and pre-adds
      GitHub host keys to `known_hosts`.
      Proven by `tests/capsule-credentials.sh --script`: 700 on `~/.ssh`, 600
      on the private key, 644 on the `.pub`, a generated `config` at 600, and
      `known_hosts` seeded from the host copy with exactly one github.com
      line. One half is text-proven only: the `ssh-keyscan` fallback needs
      network AND a host with no github.com line already, so the gate asserts
      it structurally and `StrictHostKeyChecking accept-new` is the backstop
      that makes its absence non-fatal.

      *Amended 2026-08-23 by the orchestrator.* This box read "correct
      permissions (600/700)", and only its proof note recorded the 644 on
      public keys. The shorthand was then **copied into the manual**, where
      `capsule-creds-doc-accuracy`'s analyst caught it — so the imprecise
      requirement propagated before anyone read the code. The code is right:
      `install -d -m 700` (`setup-credentials.sh:59`), `install -m 644` for
      `*.pub` (`:67`), `install -m 600` for private keys (`:68`), and
      `tests/capsule-credentials.sh:469-470` asserts the 644 deliberately.
      Nothing to change in the script.
- [x] **R2** — **Git identity.** Mount `.gitconfig` (read-only) so
      author/committer and aliases match the host.
      Proven with the real `git` reading the generated container config:
      `user.email` resolves through the `[include]` to the mounted host
      value. Note for anyone re-checking it: `git config --file … --get` does
      not follow includes unless `--includes` is passed, so the naive check
      reads as a failure when the include works.
- [x] **R3** — **Git HTTPS credentials.** On every mount, refresh `git
      credential fill` output from the host keychain into a cache file
      (`.cache/git-credentials`) mounted into the container and wired as its
      credential store.
      The file is `~/.cache/capsule/creds/git-credentials`, and the container
      reads it straight from the read-only mount rather than copying it —
      which is what lets a rotated token heal a running capsule. Proven
      end to end on the real host: handing the exported file to `git
      credential-store` returns the same username and password as the host's
      own `gh` helper (sha256 of both outputs equal), so the `url encode
      --all` round-trip is right on the actual token. No value was printed.
- [~] **R4** — **Agent auth.** The preinstalled agents work without a login
      flow. **Rewritten 2026-08-23 by the orchestrator**, because the original
      wording — "mount Claude Code and OpenCode auth/config directories" —
      names a mechanism that propagates no credential on this host. Measured:
      `~/.claude/.credentials.json` does not exist on macOS; Claude Code keeps
      its tokens in the login keychain, where
      `security find-generic-password -s "Claude Code-credentials" -w`
      returns exactly the `claudeAiOauth` payload that file would have held,
      non-interactively. Mounting `~/.claude` would therefore have satisfied
      the letter of R4 and delivered an unauthenticated agent.

      What lands instead: auth is **exported** from the keychain into the
      credentials directory and arrives in the container as four files. The
      directories the original wording named are deliberately **not** mounted,
      each for a measured reason — `~/.claude` carries host transcripts,
      `~/.claude.json` carries 671 KB of `mcpServers`/`projects` and
      host-path settings that fail once per prompt, and
      `~/.local/share/opencode` is a 94 MB live SQLite WAL over a Docker
      Desktop bind. R4's purpose is met in full; only its mechanism changed.
      Widening it later is one `-v … :ro` plus a symlink — a decision to take
      deliberately, not a default to drift into.

      **The exported agent tokens are symlinked into the read-only mount, and
      that is the point.** A container-local writable copy would let a capsule
      run its own OAuth refresh, and Claude's refresh **rotates** the refresh
      token — which would invalidate the host's login. The container borrows
      and fails closed. The documented failure mode (idle capsule, expired
      token, re-mount heals it) is on the manual checklist rather than
      hidden.

      **Marked `[~]`, not `[x]`, and the line is where the proof stops.** The
      export is proven against the REAL login keychain: the written file is
      byte-identical to the keychain payload and carries
      `claudeAiOauth.accessToken`, and `claude.json` is the six-key
      projection with no `mcpServers` and no `projects`. The wiring inside
      the container — symlink for the credential, copy for `.claude.json` —
      is proven against a real mount tree on the host. What is NOT proven is
      the requirement's own sentence, "the preinstalled agents work without a
      login flow": that needs a built image and a running container, and it
      is the second wave-4 manual C.3 row.
- [x] **R5** — **Hygiene.** No secret is baked into an image layer; everything
      arrives via mounts or container-local copies. Cached credentials are
      refreshed on connect, so a revoked/rotated token heals on the next
      mount.
      Three separate proofs: the Dockerfile carries no `COPY` and no `ADD`
      (with a counterfactual that must fail); no file under the build context
      `~/.config/capsule` holds credential-shaped content after any of eight
      scenario machines, with a control that rewrites the export path into
      that directory and must fail it; and a source that stops answering has
      its exported file DELETED rather than left stale. The heal is better
      than "next mount" — because the creds path is a directory bind, a warm
      attach's background refresh lands inside the already-running session.

## Acceptance

All three need a built image and a running container, so all three are the
wave-4 manual C.3 rows and none is ticked here. What a machine can prove is
proven and green: `bash tests/capsule-credentials.sh` — 102 pass, 0 fail —
plus the sibling `bash tests/capsule-lifecycle.sh` — 49 pass, 0 fail.

- [ ] Inside a fresh capsule for a private repo: `git pull`, `git push` (both
      SSH and HTTPS remotes), and `ssh -T git@github.com` succeed with no
      prompt.
      Manual. The HTTPS credential path is separately proven on the host (see
      R3); what is unproven is that it works from inside the container.
      *(b) — a manual check; the host half is proven, the in-container half
      is not.*
- [ ] `claude` and `opencode` start authenticated.
      Manual. The exported material and its in-container wiring are proven;
      the agents starting is not.
      *(b) — a manual check; the wiring is proven, the agents starting is
      not.*
- [ ] `docker history` of the image shows no credential material; `~/.ssh`
      inside the container is not writable back to the host copy.
      Manual. The two properties it rests on are proven without an image: the
      Dockerfile has no `COPY`/`ADD`, and every credential bind carries
      `:ro`.
      *(b) — a manual check; the two resting properties are proven, the
      image-level observation is not.*

## Out of scope
- Anything this node's Requirements do not name. The epic ([`../prd.md`](../prd.md)) owns the shared invariants.
