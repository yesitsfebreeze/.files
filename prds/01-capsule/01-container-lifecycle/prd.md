---
state: done
claim:
priority: 20
est: 8h
task: C.2
mode: afk
needs:
  - 01-capsule/02-dev-image
  - 00-delivery/corrections/w0-4-s2-corrections
  - 00-delivery/corrections/w0-5-capsule-rebase
  - 00-delivery/decisions/wallpaper-opacity
  - 06-help/01-content-model
verify: ""
---

# Container lifecycle

Parent: [Capsule epic](../prd.md) · C 9 · U 9 · sources: "Capsule"
(CONSOLIDATE, C 9 / U 9 — dominant), "`mount` — drop the current dir into
a container" (C 3 / U 7), "Just task runner" (C 3 / U 6)

Purpose: One CLI entry point, `capsule [dir]`, that mounts a directory
(default: cwd) into a per-directory dev container and attaches an interactive
shell. The terminal keybinding (`Ctrl+Shift+D`) and any task-runner recipe
become thin wrappers over this one command — no parallel implementations.

## Requirements
- [x] **R1** — **Naming.** Container name derived from the directory
      (`capsule-<dirname>`), stable across invocations, with collision
      handling for same-named dirs in different parents (e.g. short path hash
      suffix).
- [~] **R2** — **Reuse.** If the container is running, exec into it — target
      well under one second. If it exists but is stopped, start and attach.
- [~] **R3** — **Rebuild detection.** Rebuild the image automatically when the
      image definition changed (mtime or content hash of the
      Dockerfile/context); otherwise never rebuild implicitly.
- [~] **R4** — **Forced rebuild.** An explicit flag (`capsule --rebuild`,
      bound to `Ctrl+Shift+B` in the terminal) that rebuilds the image and
      recreates the container. The key is settled and needs no rekey
      despite finding C-1 — see `## Decisions` below before changing it.
- [~] **R5** — **Mounting.** The target directory *itself* is mounted at
      `/workspace` and is the shell's initial cwd — never a `workspace/`
      subdirectory of it, and never a path derived from where the tool
      happened to be started: `capsule /some/path` behaves identically from
      any directory, and the tool has no working directory of its own. Both
      clauses are constraints rather than detail, because the legacy
      attempt failed on exactly them (finding **C-3**: `mount` `cd`s to a
      non-existent `~/docker`, then calls `just run "$PWD"` on a recipe
      that takes zero parameters and mounts `./workspace`). Credential
      mounts per
      [03-credential-propagation](../03-credential-propagation/prd.md).
- [~] **R6** — **Cleanup.** Two subcommands over the same set.
      `capsule list` prints every capsule this tool owns — one row per
      container, with its name, the directory it was made from, and
      whether it is running or stopped. `capsule clean` removes the
      **stopped** ones; a bare invocation never kills a running container,
      because the cheap mistake has to be the safe one. `capsule clean
      --all` additionally stops and removes the running ones. Both only
      ever touch containers this tool created — the guard is the
      `capsule.dir` label key **and** the `capsule-` name prefix, applied
      via `_capsule_owned` (`capsule.nu:138-153`); a hand-rolled container
      named `capsule-*` but lacking the label is still never touched, and
      a label-only renamed container never reaches either command. The
      imitator seam (a `capsule-*` container labelled with an *empty*
      `capsule.dir`) is recorded on
      [`capsule-rm-guard-attribution`](../../00-delivery/corrections/capsule-rm-guard-attribution/prd.md)
      and is **not** closed by this node.
- [~] **R7** — **Recency hook.** Every successful mount records the directory
      for the [recent-workspaces picker](../04-recent-workspaces/prd.md).
- [x] **R8** — **Terminal bindings.** This node delivers the WezTerm
      bindings that wrap the CLI: `Ctrl+Shift+D` runs `capsule` on the
      active pane's directory; `Ctrl+Shift+B` runs `capsule --rebuild`
      (R4). Thin wrappers only — binding and CLI take the one code path,
      which is what the `docker inspect` diff in Acceptance checks.

## Acceptance
- [~] `capsule` in a fresh directory: builds image if needed, creates
      container, lands in zsh at `/workspace` with the directory contents
      visible.
- [~] Second `capsule` in the same directory attaches to the running container
      without rebuild or recreate.
- [~] Editing the Dockerfile then running `capsule` triggers exactly one
      rebuild.
- [x] The WezTerm binding and the CLI produce identical containers (same name,
      image, mounts) — verified by `docker inspect` diff.
      *(a) — R8's design makes the diff a tautology: "Thin wrappers only —
      binding and CLI take the one code path, which is what the `docker
      inspect` diff in Acceptance checks." The binding is a `SendString` that
      invokes the CLI; there is no second code path to diverge.*
- [~] `capsule /some/path` run from an unrelated cwd produces a container
      whose `docker inspect --format '{{json .Mounts}}'` shows the
      workspace bind with `Source` exactly `/some/path` — not the cwd, and
      not `/some/path/workspace/`.

## Out of scope
- Anything this node's Requirements do not name. The epic ([`../prd.md`](../prd.md)) owns the shared invariants.
- Preserving the semantics of the legacy `mount` function or the `just
  run` recipe. They never worked (finding **C-3**), so there is no
  behaviour to stay compatible with; they are inputs to the design, not
  the specification. The related framing question — that this node's title
  says "consolidates" of pieces that never ran (C-2) — belongs to
  [`w0-5-capsule-rebase`](../../00-delivery/corrections/w0-5-capsule-rebase/prd.md),
  which rebases the epic on "build once".

## Decisions

**Decided 2026-08-21 (user): `Ctrl+Shift+B` is capsule's.** R4 keeps it and
needs no rekey. Recorded from
[`00-delivery/decisions/wallpaper-opacity`](../../00-delivery/decisions/wallpaper-opacity/prd.md),
where the fork was put to the human.

Why this needs saying at all: the audit's finding C-1 found `Ctrl+Shift+B`
already taken in the live config — by the WezTerm wallpaper pipeline — and
instructed the capsule PRDs to "pick new bindings". That instruction is now
void. The incumbent is dropped (`DO NOT PORT`, C 8 / U 3), so the collision is
**dissolved rather than resolved** and the key comes free with the port.
Anyone re-reading C-1, or
[`w0-5-capsule-rebase`](../../00-delivery/corrections/w0-5-capsule-rebase/prd.md)
R2, should stop here rather than invent a replacement key — a rekey now
would cost the muscle memory the port exists to keep.

`Ctrl+Shift+T` was the separate collision: WezTerm's default `SpawnTab`,
the tab reconciler's manual new-tab path. Resolved 2026-08-22 by
[`w0-5-capsule-rebase`](../../00-delivery/corrections/w0-5-capsule-rebase/prd.md)
R2: `SpawnTab` keeps the key, and the recents picker's new-tab variant
moves to `Ctrl+Shift+O` — record in
[`04-recent-workspaces`](../04-recent-workspaces/prd.md) `## Decisions`.
