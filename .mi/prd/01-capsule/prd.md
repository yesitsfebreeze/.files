---
state: open
mode: afk
deps: []
verify: ""
---

# Epic: Capsule — one consolidated dev-container tool

Purpose: The old dotfiles reached "drop this directory into a container"
through five loosely coupled pieces: the WezTerm capsule keybinding, the
`mount` shell function, a `justfile`, a standalone Dockerfile, and a
credential-mounting script. They overlapped (two images, two entry paths) and
drifted apart. `capabilities.md` explicitly asks for this to work **flawlessly
and consolidated as one tool**.

Goal: A single tool — one name, one image definition, one code path — that
takes any directory and puts you in a ready-to-work dev container with your
credentials, in under a second when the container already runs.

## Acceptance
- [ ] One command (and one terminal keybinding that calls it) covers
      everything the old `mount`, `Ctrl+Shift+D`, `Ctrl+Shift+B`, and `just
      run` did.
- [ ] Reconnecting to a running capsule feels instant; cold start is dominated
      by docker itself, not by the tool.
- [ ] `git push` and SSH work inside the container without any
      re-authentication.

## Out of scope
- Multiple images or per-project Dockerfile customization (later, if ever).
- Orchestrating more than one container per directory.
- Porting the old `mount`/`justfile`/keybinding implementations as-is; they
  are inputs to the design, not the design.

## Note on children

The `## Children` table this epic used to carry is gone on purpose. Node
membership is by existence — a child is a subdirectory holding its own
`prd.md` — so a maintained list beside it is a second copy that goes stale
silently (laws.md law 4: "membership by existence, not by a maintained
list"). `find . -name prd.md` is the index.
