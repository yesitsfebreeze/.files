# Feature: Deploy mechanism

Parent: [Provisioning epic](00-epic.md) · C 3 · U 9 · sources: "Idempotent
apply + push workflow" (C3 U9 — dominant), "Managed config surface" (C3 U9) in
capabilities-provisioning.md

## Summary

The chezmoi source layout and the two commands that move config between the
repo and a machine. One deploy path, idempotent, with every tool's config
under one root.

## Requirements

1. **Source layout.** `home/` holds the managed tree (`dot_config/`,
   `dot_gitconfig.tmpl`, `run_*` scripts, `.chezmoidata/`), with the repo root
   carrying the `justfile` and docs.
2. **Managed config surface.** One source of truth per tool under
   `home/dot_config/`: nushell, nvim, wezterm, television, burrito,
   `starship.toml`, bat, gh, lazygit, tinted-theming. Templated only where it
   must differ per machine (`dot_gitconfig.tmpl`).
3. **Apply.** `chezmoi apply` is the single deploy step and must be idempotent
   — a second apply changes nothing.
4. **Daily pull.** `rr` = `chezmoi update --force` (see
   [`04-shell/02`](../04-shell/02-aliases-utilities.md)).
5. **Push recipe.** One `just push`: init from this source, apply, commit,
   push, then update. Mirrors the live workflow so muscle memory carries over.
6. **Script ordering contract.** chezmoi runs `run_once_before` → package
   installer (`run_onchange`) → `run_after`. Anything depending on an
   installed tool must live in a later stage than the install, and stages must
   re-resolve PATH because a tool installed this run isn't on it yet.

## Acceptance criteria

- Fresh clone + `chezmoi apply` on a scratch target produces the full
  `~/.config` tree; a second apply reports no changes.
- `just push` round-trips a local edit to the remote and back.
- Editing one tool's config touches exactly one path under `home/dot_config/`.
