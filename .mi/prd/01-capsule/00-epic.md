# Epic: Capsule — one consolidated dev-container tool

## Problem

The old dotfiles reached "drop this directory into a container" through five
loosely coupled pieces: the WezTerm capsule keybinding, the `mount` shell
function, a `justfile`, a standalone Dockerfile, and a credential-mounting
script. They overlapped (two images, two entry paths) and drifted apart.
`capabilities.md` explicitly asks for this to work **flawlessly and
consolidated as one tool**.

## Goal

A single tool — one name, one image definition, one code path — that takes any
directory and puts you in a ready-to-work dev container with your credentials,
in under a second when the container already runs.

## Non-goals

- Multiple images or per-project Dockerfile customization (later, if ever).
- Orchestrating more than one container per directory.
- Porting the old `mount`/`justfile`/keybinding implementations as-is; they
  are inputs to the design, not the design.

## Children

| # | Feature | C | U | V |
|---|---------|---|---|---|
| 01 | [Container lifecycle](01-container-lifecycle.md) — create/reuse/rebuild/enter | 9 | 9 | 0 |
| 02 | [Dev image](02-dev-image.md) — the single Ubuntu toolbox image | 7 | 8 | 1 |
| 03 | [Credential propagation](03-credential-propagation.md) — git/ssh/agent auth inside | 8 | 8 | 0 |
| 04 | [Recent workspaces](04-recent-workspaces.md) — picker over previously mounted dirs | 5 | 7 | 2 |

## Success criteria

- One command (and one terminal keybinding that calls it) covers everything
  the old `mount`, `Ctrl+Shift+D`, `Ctrl+Shift+B`, and `just run` did.
- Reconnecting to a running capsule feels instant; cold start is dominated by
  docker itself, not by the tool.
- `git push` and SSH work inside the container without any re-authentication.
