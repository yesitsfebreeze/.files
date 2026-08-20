---
state: open
mode: afk
deps:
  - .mi/prd/00-delivery/corrections/w0-4-s2-corrections
  - .mi/prd/00-delivery/decisions/tinty
  - .mi/prd/05-platform/03-shell-init-generation
  - .mi/prd/06-help/01-content-model
verify: ""
---

# Core config

Parent: [Nushell epic](../prd.md) · C 3 · U 9 · source: "Core shell config"

Purpose: The foundation every other feature assumes: a nushell that works as a
login shell on macOS, remembers where you were, and funnels all navigation
through one place.

## Requirements
- [ ] **R1** — **PATH repair.** Nushell never runs macOS `path_helper`, so
      `env.nu` prepends `~/.local/bin` + `~/.cargo/bin` and appends homebrew +
      system dirs (with `uniq` so it's a no-op when the parent shell provided
      them).
- [ ] **R2** — **Environment.** `EDITOR`/`VISUAL` = nvim, `SHELL` = nu,
      `XDG_CONFIG_HOME`, `RIPGREP_CONFIG_PATH` (shared ignore rules with fd).
- [ ] **R3** — **Shell behavior.** No banner, emacs edit mode, `rm` → trash,
      fuzzy case-insensitive completions, binary filesize units.
- [ ] **R4** — **History store.** Sqlite, 100k entries, `isolation: false` so
      all panes/sessions share one merged history (required by
      [05-history](../05-history/prd.md)).
- [ ] **R5** — **Terminal integration.** OSC 133/633 off (phantom-blank-line
      fix with starship two-line prompt under WezTerm), OSC 7 on (cwd →
      WezTerm status). `use_kitty_protocol` stays off (leaks `^[[?0u` through
      the WezTerm pty).
- [ ] **R6** — **`mkcd` funnel.** `cd` aliased to a wrapper that: passes `` /
      `-` through, offers to `mkdir` a non-existent target (single-key
      confirm), and records every successful move to `startdir.txt`. All
      navigation — zoxide, pickers, fallback — must reach the shell through
      this funnel or the PWD hook.
- [ ] **R7** — **Start dir.** New interactive shells open in the last
      directory navigated to by any means (read from `startdir.txt`, fall back
      to `~/dev`); non-interactive `nu -c` keeps its caller's cwd.
- [ ] **R8** — **Dirstack.** The PWD hook pushes every move onto `dirs.txt`
      (newest first, deduped, cap 100); the list drops dead paths on read.
      Feeds the `rcwd` tv channel and anything else that wants "recent dirs".
- [ ] **R9** — **Zero-work startup.** Generated integrations (starship, zoxide
      init, tv init) are produced at chezmoi-apply time and only sourced at
      launch.

## Acceptance
- [ ] `chsh` to nu + GUI-launched WezTerm: `bat`, `rg`, `tv`, `starship` all
      resolve.
- [ ] `cd some/new/nested/dir` + Enter creates and enters it after confirm.
- [ ] Navigate anywhere by any means, open a new pane: it starts in that dir.
- [ ] `nu -c 'pwd'` from another dir prints that dir, not the start dir.

## Out of scope
- Anything this node's Requirements do not name. The epic ([`../prd.md`](../prd.md)) owns the shared invariants.
