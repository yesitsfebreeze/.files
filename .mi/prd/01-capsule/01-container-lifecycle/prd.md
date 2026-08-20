---
state: open
mode: afk
deps:
  - .mi/prd/00-delivery/corrections/w0-4-s2-corrections
  - .mi/prd/00-delivery/corrections/w0-5-capsule-rebase
  - .mi/prd/00-delivery/decisions/wallpaper-opacity
  - .mi/prd/01-capsule/02-dev-image
  - .mi/prd/06-help/01-content-model
verify: ""
---

# Container lifecycle (consolidates capsule + `mount` + justfile)

Parent: [Capsule epic](../prd.md) · C 9 · U 9 · sources: "Capsule" (CONSOLIDATE, C9 U9 — dominant),

Purpose: One CLI entry point, e.g. `capsule [dir]`, that mounts a directory
(default: cwd) into a per-directory dev container and attaches an interactive
shell. The terminal keybinding (`Ctrl+Shift+D`) and any task-runner recipe
become thin wrappers over this one command — no parallel implementations.

## Requirements
- [ ] **R1** — **Naming.** Container name derived from the directory
      (`capsule-<dirname>`), stable across invocations, with collision
      handling for same-named dirs in different parents (e.g. short path hash
      suffix).
- [ ] **R2** — **Reuse.** If the container is running, exec into it — target
      well under one second. If it exists but is stopped, start and attach.
- [ ] **R3** — **Rebuild detection.** Rebuild the image automatically when the
      image definition changed (mtime or content hash of the
      Dockerfile/context); otherwise never rebuild implicitly.
- [ ] **R4** — **Forced rebuild.** An explicit flag (`capsule --rebuild`,
      bound to `Ctrl+Shift+B` in the terminal) that rebuilds the image and
      recreates the container.
- [ ] **R5** — **Mounting.** The target directory is mounted at `/workspace`
      and is the shell's initial cwd. Credential mounts per
      [03-credential-propagation](../03-credential-propagation/prd.md).
- [ ] **R6** — **Cleanup.** A subcommand to list capsules and remove
      stopped/all ones (absorbs the old `dk` force-remove alias for capsule
      containers).
- [ ] **R7** — **Recency hook.** Every successful mount records the directory
      for the [recent-workspaces picker](../04-recent-workspaces/prd.md).

## Acceptance
- [ ] `capsule` in a fresh directory: builds image if needed, creates
      container, lands in zsh at `/workspace` with the directory contents
      visible.
- [ ] Second `capsule` in the same directory attaches to the running container
      without rebuild or recreate.
- [ ] Editing the Dockerfile then running `capsule` triggers exactly one
      rebuild.
- [ ] The WezTerm binding and the CLI produce identical containers (same name,
      image, mounts) — verified by `docker inspect` diff.

## Out of scope
- Anything this node's Requirements do not name. The epic ([`../prd.md`](../prd.md)) owns the shared invariants.
