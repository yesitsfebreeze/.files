---
state: open
priority: 0
est: 0h
kind: epic
mode: afk
needs:
verify: ""
---

# Epic: Capsule — one consolidated dev-container tool

Purpose: The legacy repo reached "drop this directory into a container"
through five loosely coupled pieces: a WezTerm capsule keybinding, the
`mount` shell function, a `justfile`, a standalone Dockerfile, and a
credential-mounting script. None of them is deployed, and the entry path
never ran (findings C-2, C-3) — there is no live implementation to
consolidate from. This epic builds the tool once, informed by that attempt:
the pieces are evidence for the design, not parts of it. `capabilities.md`
asks for the capability to work **flawlessly and consolidated as one tool**;
"consolidated" names the outcome — one name, one image definition, one code
path — not a porting job.

Goal: A single tool — one name, one image definition, one code path — that
takes any directory and puts you in a ready-to-work dev container with your
credentials, in under a second when the container already runs.

## Bindings

The tool's terminal surface is four keys, each owned by the child that
implements its wrapper:

| Key | Runs | Owner |
|---|---|---|
| `Ctrl+Shift+D` | `capsule` on the pane's directory | [`01-container-lifecycle`](01-container-lifecycle/prd.md) R8 |
| `Ctrl+Shift+B` | `capsule --rebuild` | [`01-container-lifecycle`](01-container-lifecycle/prd.md) R4, R8 |
| `Ctrl+Shift+S` | recents picker, current pane | [`04-recent-workspaces`](04-recent-workspaces/prd.md) R2 |
| `Ctrl+Shift+O` | recents picker, new tab | [`04-recent-workspaces`](04-recent-workspaces/prd.md) R2 |

All four are unbound in the deployed `wezterm.lua` and in WezTerm's
defaults (`wezterm -n show-keys`, checked 2026-08-22); `Ctrl+Shift+B` is
free because the wallpaper pipeline is dropped
([decision 5(c)](../00-delivery/corrections/prd.md)). `Ctrl+Shift+T` is not
capsule's: it stays WezTerm's `SpawnTab`, the tab reconciler's manual
new-tab path. The rekey record is in
[`04-recent-workspaces`](04-recent-workspaces/prd.md) `## Decisions`.

## Acceptance
- [ ] One command, `capsule`, is the only entry path: every binding in
      `## Bindings` is a thin wrapper that invokes it, and nothing else
      builds, mounts, or attaches.
- [ ] Reconnecting to a running capsule feels instant; cold start is dominated
      by docker itself, not by the tool.
- [ ] `git push` and SSH work inside the container without any
      re-authentication.

## Out of scope
- Multiple images, or per-project Dockerfile customization by the capsule
  tool: it builds and runs exactly one image definition. A project that needs
  more is free to build its own image `FROM` that base — capsule neither
  manages nor discovers it, which is what keeps "one image definition" true.
- The Odin compiler built from source, and the `pi` agent with its pi-oilrig
  extensions. Dropped from the image 2026-08-21; the decision and its reason
  are recorded in [`02-dev-image`](02-dev-image/prd.md) under `## Decisions`,
  and projects needing them layer them per-project.
- Orchestrating more than one container per directory.
- Porting the old `mount`/`justfile`/keybinding implementations as-is; they
  are inputs to the design, not the design.

## Note on children

The `## Children` table this epic used to carry is gone on purpose. Node
membership is by existence — a child is a subdirectory holding its own
`prd.md` — so a maintained list beside it is a second copy that goes stale
silently (laws.md law 4: "membership by existence, not by a maintained
list"). `find . -name prd.md` is the index.
