---
state: open
mode: afk
deps:
  - .mi/prd/01-capsule/01-container-lifecycle
  - .mi/prd/06-help/01-content-model
verify: "git push works inside a capsule (wave-4 gate)"
---

# Credential propagation into containers

Parent: [Capsule epic](../prd.md) · C 8 · U 8 · source: "Credential

Purpose: A capsule can pull, push, and SSH exactly like the host, with zero
re-authentication, while keeping secrets read-only and off the image.

## Requirements
- [ ] **R1** — **SSH.** Mount `~/.ssh` read-only; first-run setup copies keys
      to a container-local dir with correct permissions (600/700) and pre-adds
      GitHub host keys to `known_hosts`.
- [ ] **R2** — **Git identity.** Mount `.gitconfig` (read-only) so
      author/committer and aliases match the host.
- [ ] **R3** — **Git HTTPS credentials.** On every mount, refresh `git
      credential fill` output from the host keychain into a cache file
      (`.cache/git-credentials`) mounted into the container and wired as its
      credential store.
- [ ] **R4** — **Agent auth.** Mount Claude Code and OpenCode auth/config
      directories so the preinstalled agents work without a login flow.
- [ ] **R5** — **Hygiene.** No secret is baked into an image layer; everything
      arrives via mounts or container-local copies. Cached credentials are
      refreshed on connect, so a revoked/rotated token heals on the next
      mount.

## Acceptance
- [ ] Inside a fresh capsule for a private repo: `git pull`, `git push` (both
      SSH and HTTPS remotes), and `ssh -T git@github.com` succeed with no
      prompt.
- [ ] `claude` and `opencode` start authenticated.
- [ ] `docker history` of the image shows no credential material; `~/.ssh`
      inside the container is not writable back to the host copy.

## Out of scope
- Anything this node's Requirements do not name. The epic ([`../prd.md`](../prd.md)) owns the shared invariants.
