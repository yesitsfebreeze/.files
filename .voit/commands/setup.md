---
description: Bootstrap VOIT in this project — voit-memory worktree, .gitignore, settings wiring (default agent + statusLine), then offer the plugin library. Idempotent; safe to re-run.
---

Run VOIT's one-time project bootstrap, confirm what it wired, then offer the plugin library.

1. Run the bootstrap from your project root. `.voit/` always holds the plugin —
   vendored in the dev repo, synced there from the install cache by the SessionStart
   hook everywhere else — so this resolves regardless of layout:
   ```sh
   bash .voit/scripts/setup.sh
   ```
   If `.voit/scripts` is absent (the SessionStart hook has not run yet), start a
   fresh session first, or pass the plugin path explicitly: `bash <plugin>/scripts/setup.sh`.
2. Report what it wired: the voit-memory worktree at `.voit/memory`, the `.gitignore`
   entries, the `.claude/settings.json` keys (`agent: voit:vision` + `statusLine`), and
   the `jd` binary (installed if missing — best-effort, skipped offline). Setup only
   fills missing keys — it never clobbers your own. In this repo (which ships a
   justfile) `just setup` runs the same script; a consumer project has no justfile, so
   the `bash` invocation above is the portable entry.
3. Offer the **plugin library** — VOIT's curated list of Claude Code plugins. Read the
   registry at `.voit/plugins.json` (each entry is `{id, repo, description}`, where
   `id` is `plugin@marketplace`). Read the project's current state with
   `claude plugin list --json` (the `installed` entries whose `projectPath` is this repo
   carry their `enabled` flag). Present each registry entry — id, description, and whether
   it's already installed here — and ask which to install or update (multi-select; none is
   a fine answer). For each chosen entry (marketplace = the part of `id` after `@`):
   ```sh
   claude plugin marketplace add  <repo>        --scope project
   claude plugin marketplace update <marketplace>
   claude plugin install <id> --scope project
   claude plugin update  <id> --scope project
   ```
   All four are idempotent: `marketplace/plugin update` refresh an already-installed plugin
   to latest, `install` is a no-op when current. Everything lands in `.claude/settings.json`
   at **project scope** only — never user scope. Report which plugins are now installed and
   note that newly enabled plugins apply after a restart. If the registry is empty, say so
   and point at `.voit/plugins.json` as the place to add repos.
