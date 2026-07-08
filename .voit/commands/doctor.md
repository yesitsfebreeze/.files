---
description: Whole-repo health pass — regenerate the project overview, fold learnings into voit-memory, and ready the base for the next session.
---

Run the VOIT doctor over the repo (`$ARGUMENTS` narrows the focus; empty = whole repo).

1. Read the doctrine: `jd get voit/doctor` (or `.voit/.jd/library/voit/doctor.jd`).
2. SURVEY the live state: git (branch, status, recent commits, `git worktree list`,
   `git branch`), the bus roster (`python3 .voit/scripts/bus.py roster`), voit-memory
   (decisions + slice plans), and the plugin surface (commands/agents/hooks/jd).
3. OVERVIEW: regenerate `.voit/memory/overview.jd` from reality (replace, don't append) —
   what the project is, architecture, current state, slices done vs in-flight, the
   load-bearing decisions/conventions, and entry points.
4. FOLD IN learnings: consolidate voit-memory — capture new decisions, merge overlap,
   prune impl notes for slices merged to `main`, correct stale nits, mark superseded
   entries.
5. SYNC the base: if `.voit/` is a synced copy of a cache-installed plugin (not this
   repo's vendored source), refresh the plugin first — `claude plugin update voit@voit` (best-effort;
   offline is fine, vendored setups skip). `jd build --recursive` rebuilds the graph store; re-run
   `bash .voit/scripts/setup.sh` (idempotent — ensures voit-memory, `.gitignore`, and
   the `.claude/settings.json` wiring: default `agent` + `statusLine`); then
   `bash .voit/scripts/test.sh` MUST be green. If a plugin promise/behavior mismatch
   surfaces, name it and recommend `/dogfood` — do not fix it here.
6. HANDOFF: if a tracked `handoff.md` exists, refresh it to the current structure and
   point at voit-memory / `.voit/memory/overview.jd` as canonical.

Report what changed, the current state in one paragraph, and what the next session
should pick up first.
