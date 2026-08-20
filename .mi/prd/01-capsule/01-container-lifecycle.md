# Feature: Container lifecycle (consolidates capsule + `mount` + justfile)

Parent: [Capsule epic](00-epic.md) · C 9 · U 9 · sources: "Capsule" (CONSOLIDATE, C9 U9 — dominant),
"`mount` — drop the current dir into a container", "Just task runner"

## Summary

One CLI entry point, e.g. `capsule [dir]`, that mounts a directory (default:
cwd) into a per-directory dev container and attaches an interactive shell.
The terminal keybinding (`Ctrl+Shift+D`) and any task-runner recipe become
thin wrappers over this one command — no parallel implementations.

## Requirements

1. **Naming.** Container name derived from the directory (`capsule-<dirname>`),
   stable across invocations, with collision handling for same-named dirs in
   different parents (e.g. short path hash suffix).
2. **Reuse.** If the container is running, exec into it — target well under
   one second. If it exists but is stopped, start and attach.
3. **Rebuild detection.** Rebuild the image automatically when the image
   definition changed (mtime or content hash of the Dockerfile/context);
   otherwise never rebuild implicitly.
4. **Forced rebuild.** An explicit flag (`capsule --rebuild`, bound to
   `Ctrl+Shift+B` in the terminal) that rebuilds the image and recreates the
   container.
5. **Mounting.** The target directory is mounted at `/workspace` and is the
   shell's initial cwd. Credential mounts per
   [03-credential-propagation](03-credential-propagation.md).
6. **Cleanup.** A subcommand to list capsules and remove stopped/all ones
   (absorbs the old `dk` force-remove alias for capsule containers).
7. **Recency hook.** Every successful mount records the directory for the
   [recent-workspaces picker](04-recent-workspaces.md).

## Acceptance criteria

- `capsule` in a fresh directory: builds image if needed, creates container,
  lands in zsh at `/workspace` with the directory contents visible.
- Second `capsule` in the same directory attaches to the running container
  without rebuild or recreate.
- Editing the Dockerfile then running `capsule` triggers exactly one rebuild.
- The WezTerm binding and the CLI produce identical containers (same name,
  image, mounts) — verified by `docker inspect` diff.
