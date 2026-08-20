# Feature: Credential propagation into containers

Parent: [Capsule epic](00-epic.md) · C 8 · U 8 · source: "Credential
propagation into containers"

## Summary

A capsule can pull, push, and SSH exactly like the host, with zero
re-authentication, while keeping secrets read-only and off the image.

## Requirements

1. **SSH.** Mount `~/.ssh` read-only; first-run setup copies keys to a
   container-local dir with correct permissions (600/700) and pre-adds GitHub
   host keys to `known_hosts`.
2. **Git identity.** Mount `.gitconfig` (read-only) so author/committer and
   aliases match the host.
3. **Git HTTPS credentials.** On every mount, refresh `git credential fill`
   output from the host keychain into a cache file (`.cache/git-credentials`)
   mounted into the container and wired as its credential store.
4. **Agent auth.** Mount Claude Code and OpenCode auth/config directories so
   the preinstalled agents work without a login flow.
5. **Hygiene.** No secret is baked into an image layer; everything arrives
   via mounts or container-local copies. Cached credentials are refreshed on
   connect, so a revoked/rotated token heals on the next mount.

## Acceptance criteria

- Inside a fresh capsule for a private repo: `git pull`, `git push` (both SSH
  and HTTPS remotes), and `ssh -T git@github.com` succeed with no prompt.
- `claude` and `opencode` start authenticated.
- `docker history` of the image shows no credential material; `~/.ssh` inside
  the container is not writable back to the host copy.
