# Simplification plan — week of 2026-08-26 to 2026-09-02

Working document. Delete it when the phases below are done; git keeps it.
Bias for every item: **smaller and more straightforward wins.** An item
stays only if removing it loses something the daily driver needs.

## The shape of the problem

| Thing | Size | Note |
|---|---|---|
| Configuration in `home/` | ~120 files, 1.3 MB, ~10,800 lines | the deliverable |
| Board in `.pearde/prds/` | 639 files, 7.2 MB | 195 of 198 nodes `done`; specs alone 3.6 MB |
| Manual shipped with the shell | 6,185 lines of markdown | 4,359 of them hand-written `internals/` |
| `AGENTS.md` | 389 lines | 17 dated self-corrections; three counts already wrong again |
| Week's commits | 78 | 58 board-only, 19 mixed, **1** touched only `home/` |
| Week's churn | ~90k lines | 52k board, 47k tests (deleted), 14k docs-site (created and deleted same day), 8k gates (deleted) |

Built and torn down inside the same week: 53 test scripts, 26 gate files, the
fumadocs site, the patched tmux binary, the WezTerm tab bar and key tables.
35 board nodes, 15 memos and ~220 spec files still describe the deleted test
suite.

The configs themselves are drifting back toward prose. `tmux.conf` is 161
lines of configuration under 429 lines of comment, one day after the memo
that stripped it for being 108 under 537. `tv-all`, added 09-01, is 664
lines. `home/` mentions a date 350 times; the configs are carrying a
changelog that git already holds.

## Overly complicated

1. **`help --check` drift checker** — `help-check.nu` (497 lines) spawns a
   headless nvim with an embedded Lua probe, a second tmux server on its own
   socket with a poll loop, parses `wezterm show-keys`, and dumps Neovim's
   defaults in a second spawn. It exists so 191 `verify:` records in the
   `.nuon` files stay true. It drags `HELP_CHECK` into `nvim/lazy.lua`, two
   env vars whose only caller was a deleted test, and a three-state `desc`
   rule in the README. One person does not need CI for their own manual.
2. **Five renderers of one corpus** — nuon → `help` tables → `help --md` →
   `help --fuzzy` via the `manual` tv channel → `generate-manual.mjs` →
   `?`/`docs` channel. Two pickers and two markdown emitters over the same
   data. Keep nuon → generated markdown → `?`, and plain `help <thing>`.
3. **`use-review.nuon` / `why-review.nuon`** (382 lines) — digest rows with
   session-id provenance whose only reader was `tests/help-content-model.nu`,
   deleted 08-31. Nothing opens them.
4. **`tmux.conf`** — hand-written F5 tables (27 near-identical binds), the
   pane-letter border chip built on an undocumented `#[align=right]`
   behaviour, 600-character status formats that count Claude panes and busy
   windows on every redraw, a copy-mode `c` cycle that duplicates `v`/`V`,
   and portability scaffolding (`infocmp` probe, OSC 52 branch, ssh host arm)
   for machines that do not exist.
5. **`tv-all`** (664 lines) — a two-popup dance with a raw-mode byte reader
   and a pending-file handoff because tmux allows one popup per client.
   `tmux command-prompt` is the built-in that does the prompt half.
6. **`install.sh`** (493 lines) — half of it is a dry-run seam, Linux
   package managers, a Neovim version floor and release rungs. What it does
   on this machine: brew a list, brew a cask, fetch two GitHub releases,
   clone two tmux plugins, `chezmoi apply`. That is a `Brewfile` and ~60
   lines.
7. **The litellm / `cll` stack** — ~980 lines across six scripts plus a
   committed generated YAML, driven by another tool's credential store, with
   19 hardcoded Claude Code state directories. A separate product living in
   a dotfiles repo.
8. **The board audited itself** — 83 of 118 `00-delivery` nodes are about
   gates, claims, box ticks, counts and phrasing; three-deep chains like
   `retired-phrase-sweep` → `retired-phrases-mention-vs-use` →
   `phrase-sweep-selftest-inversion` are about a grep for forbidden
   sentences. 15 of 20 memos are about test machinery that lived six days.
9. **`AGENTS.md`** — ~250 of 389 lines are board-process instructions; the
   rest is a changelog of its own errors ("Corrected 2026-08-2x: this
   paragraph used to say…").
10. **Palette re-assertion, three ways** — tinted-shell's OSC emit,
    `config.nu` re-sourcing the artifact on every shell, and
    `tmux-colors.sh` pushing OSC to every client tty plus a `client-attached`
    hook. The tty push makes the other two redundant.
11. **Small custom mechanisms with a one-line built-in**: `shift-select.lua`
    (81 lines) vs `vim.o.keymodel = "startsel,stopsel"`; `statusline.lua`
    (60 lines of hand-built theme) vs `theme = "tinted"`; the `ls` wrapper's
    `du -sk` half (config.nu:114-202) vs builtin `ls --du`; `theme.nu` A/B
    slot files vs one `previous` file; five keybinding `upsert` wrappers vs
    one append; `ENV_CONVERSIONS` for a PATH nushell already lists.

## Not needed — delete

Config and scripts:

- `install` at the repo root — byte-identical duplicate of `install.sh`.
- `home/dot_config/litellm/create_config.yaml` — a generated artifact, its
  header names a generator script that does not exist.
- `use-review.nuon`, `why-review.nuon`, `help-check.nu`, `manual.toml`,
  `copymode.nu` (F4 is bound in tmux.conf).
- `help` flags `--md --all --fuzzy --entry --topic --delegate --check` and
  `_help_host_only`; the eight-branch flag-combination error ladder.
- `zl`, `zc`, `cdi`, `_z_no_zoxide` (zoxide.nu); `capsule recent` and its
  fourth recency store; the cht pipeline (finder.nu + `cht.toml`,
  `cht-query.toml`); `_finder_pick_channel` + `channels.toml`.
- tv cable channels `git-files`, `git-branch`, `zoxide`, `alias`, `env`,
  `channels`; `nvim/lua/plugins/init.lua` (`return {}`).
- `wezterm.lua`: `is_mac` branches and Linux font sizes, `TAB_BAR_RESERVE`,
  `inactive_pane_hsb`, `scrollback_lines`, the Ctrl+C selection callback,
  Ctrl+Shift+O (spawns a shell outside tmux), the paragraph about deleted
  machinery.
- `tmux.conf`: the no-tmux fallback ladder in `tmux-main`, the double
  `colors.conf` source, `allow-passthrough` (verify first), the `c` cycle,
  the Claude counter and busy-window loop in the status formats.
- `tmux-colors.sh`: base24 fallbacks, `display-panes-*` colours (nothing
  binds `display-panes`), `@scheme` (nothing reads it).
- `lsp.lua:27-30` maps that duplicate Neovim 0.11 built-ins; six
  `options.lua` lines set to their defaults; `border_type = "rounded"` three
  times in television `config.toml` (it is the default).
- `justfile` `cutover` recipe (it has run; its own comment says one-time).
- `.gitignore` entries for `.pi/kern/`, `vicky/`, `board`, `__pycache__/`;
  `.graphifyignore`'s `docs-site/`.

Board and docs:

- `specs/` directories under every `done` node (~355 files, 3.5 MB).
- ~83 process nodes under `00-delivery/` (gate and board-hygiene classes).
- 15 process memos (everything except `tmux-owns-multiplexing…`,
  `tests-and-gates-retire…`, `the-manual-is-markdown…`,
  `mason-refresh-off…`, and arguably `every-abort-measurement…`).
- ~~`.pearde/workflows/` (empty).~~ **Struck 2026-09-02** — it holds two
  workflows and eight atomics, tracked, and every worker brief this board
  dispatches names one. It was empty when this plan was written.
- ~330 lines of `AGENTS.md`.
- `internals/help.md` lines 333-691 (the checker's own design) and the ~30
  `tests/`/`gates/` citations across `internals/`.

## Good — keep as-is

- **The tmux decision and its memo.** Right call, well argued, and it
  deleted the most expensive machinery on the board instead of porting it.
- `mkcd` as the single navigation funnel; the PWD hook with dirstack first
  and the width hang guard; `_z_fallback` bare-word jump with its metachar
  guard — the best feature in the shell.
- `history.nu` (cwd-scoped history over the sqlite store, 35 lines);
  `dirstack.nu` / `recents.nu` / `quicklist.nu`; `pass.nu`.
- `docs.toml` + `?`: the right replacement for the site. `generate-manual.mjs`
  with no dependency beyond `nu`.
- `tmux-git`, the `@cwd`-via-OSC-7 block, the copy-sink option with
  `send -FX`, window dimming that keeps blur, `tmux-colors.sh`'s OSC push to
  every client tty and its `$'…'` escape trap.
- `dot_gitconfig.tmpl`'s empty-helper reset; `register-mcp.sh`'s
  `~/.claude.json` vs `settings.json` finding; capsule's credential refresh
  (atomic write, chmod 600, background job).
- `autocmds.lua`, `keymaps.lua`, the mode-coloured cursor in
  `colorscheme.lua`, telescope multi-select to quickfix, the
  `registry_cache.refresh = false` line and its memo.
- `.chezmoiignore`; the `nu-history` and `git-log` channels with their
  recorded fixtures.
- `decisions/` (6 real forks) and `docs/capabilities-*.md` as the record of
  what was rated and why.
- The 08-31 judgement to retire tests, gates and the site. Right; just late.

## Bad — fix

- Nine shipped config files cite `tests/` or `gates/` as their proof:
  `install.sh`, both `run_after_*` seams, `capsule/Dockerfile`,
  `help/README.md`, both review files, `manual.toml`, `seed-mason-registry`.
  Also `AGENTS.md`, `justfile`, 6 `internals/` pages, 15 memos.
- Stale claims: `tinty/config.toml` and `tmux-colors.sh` still describe the
  deleted `colors.lua` generator; `help.nu:281` says cutover has not run;
  `tasks.nuon:92` says "this site" and generates it into the guide;
  `help/README.md:359` says the deployed config "does not exist yet";
  `topics.nuon:37-38` says WezTerm owns jump mode; `shell.nuon:5-13` lists
  four "not yet live" behaviours that are all live.
- The `ls` wrapper inverts the builtin's `-d`/`-D` letters.
- ~~`.pearde/graphify/` is 3.8 MB, 628 files, untracked and **not ignored**~~
  — **overtaken 2026-09-02.** The user answered that the vault is worth
  versioning: it is tracked as of `c49b5fe`, and only
  `.pearde/graphify/cache/` is ignored. The credential is the finding that
  held: `wiki/.obsidian-api-key` was reachable from four commits on `main`,
  which were rebuilt without it before anything was pushed.
- Duplicated helpers: `_finder_shquote` / `_capsule_shquote`;
  `_theme_state_dir` / `_state_dir`; the XDG default computed three times;
  the nu-launch ladder in `tmux.conf:88`, `tmux-main` and `tv-all`; the edit
  action copied into five channels with two different fallbacks.
- `recent-files.toml` uses `find` against the repo's own fd rule, and
  "recent" means the last 10 commits.
- Tombstone comments: "`tv_finder` and `tv_remote` stood here and were
  removed on 2026-09-01…" (config.nu:404-418 and :328-331 are 23 lines about
  code that no longer exists). Git holds this.

## The plan

Do it in this order. Each phase is one or two commits and leaves the tree
usable. Estimated removals are from the four audits and are rough.

**Phase 0 — hygiene, before anything else (30 min)**

1. Commit the current 204-file working tree as it is, so every later step
   is a clean diff against a known state.
2. ~~Add `.pearde/graphify/` to `.gitignore`; delete `.pearde/workflows/`.~~
   Both struck 2026-09-02 — see the two entries above. Nothing is left of
   this step.
3. Delete `install`, `create_config.yaml`, the stale `.gitignore` entries,
   the `cutover` recipe.

**Phase 1 — the board (largest byte win, ~7 MB → ~2 MB)**

Decided 2026-09-02: **the PRDs are the record of what was done.** Every
`prd.md` stays, including the ones about scaffolding that no longer exists;
they record that it was built and why it was removed. What goes is the
machinery around them.

4. `AGENTS.md` → ~60 lines: what the repo is, the where-things-live table,
   the chezmoi stale-clone trap, the scope decisions one line each, the
   hard-won constraints list, "read `?` before suggesting a workflow", one
   pointer to the pearde README. No dated corrections.
5. `git rm -r` every `specs/` directory (~358 files, 3.6 MB). They are
   worker briefs, not the record; the `prd.md` beside each one is. Before
   that, grep the four specs with real knowledge (television `nu-history`
   path, status-bar options) into `internals/` if not already there.
6. Set `verify: ""` everywhere it still names a deleted script, and stop
   filing new nodes about the board itself.
7. Move the 15 process memos to `memos/archive/`. Keep the 4–5 about the
   dotfiles.
8. The three open nodes stay on the board; two of them are about pearde and
   can be closed as out of scope for this repo.

**Phase 2 — the help system (largest code win, ~2,100 lines)**

9. Delete `use-review.nuon`, `why-review.nuon`, `help-check.nu`, the
   `--check` flag, `verify:` from all four `.nuon` files, `HELP_CHECK` from
   `nvim/lazy.lua`, and `internals/help.md:333-691`.
10. Delete `manual.toml`, `_help_rows/_help_preview/_help_browse`,
    `--fuzzy`, `--md`, `--all`, `--entry`, `--topic`, `--delegate`, the
    flag ladder; merge the five "run chezmoi apply" errors into one.
11. `help/README.md` → the schema table plus "edit the nuon, run
    `just manual`". Fix `topics.nuon`, `tasks.nuon`, `shell.nuon` headers;
    regenerate; sweep the 30 `tests/`/`gates/` refs from `internals/`.
    Check: `help`, `help navigate`, `help --json | from json`, `?`.

**Phase 3 — shell and terminal configs (~1,500 lines)**

12. `config.nu`: builtin `ls --du` replaces the `du -sk` half of the
    wrapper (fix the `-d`/`-D` inversion while there); one keybinding
    append; delete the tombstone comments and the wl-copy/xclip branches.
13. `zoxide.nu`, `finder.nu`, `capsule.nu`, `theme.nu`, `env.nu`,
    `copymode.nu` per the delete list; dedupe `_shquote` and `_state_dir`.
14. `tmux.conf` → ~250 lines: comments cut to one-line traps with a pointer
    to `internals/tmux.md`; F5 tables generated by one `run-shell` loop;
    the `c` cycle, the counters, the double source, the portability arms
    out. Check F3/F4/F5/F6 once each, drag-copy reaches `pbpaste`, `theme`
    retints every pane.
15. `tv-all`: replace the ask popup with `tmux command-prompt`; remove
    `ask_line`, the pending file, the `if-shell` halves of both bindings
    (~140 lines).
16. `wezterm.lua`, `tmux-main`, `tinty/config.toml`, `tmux-colors.sh` per
    the delete list. Then drop `config.nu`'s artifact re-source if the tty
    push and `client-attached` hook already cover a new shell.

**Phase 4 — Neovim and television (~430 lines)**

17. Delete the six unused cable channels and `plugins/init.lua`; unify the
    edit action on `nvim`; `recent-files` → `fd --changed-within 7d`;
    `theme.toml.tmpl` → `theme.toml`.
18. `statusline.lua` → `theme = "tinted"`; `claude.lua` drop the 38-line
    profile resolver (`cll` already does it) and the dead explorer list;
    `lsp.lua` and `options.lua` defaults out; `config.toml` to 7 lines.
19. `shift-select.lua` → `keymodel = "startsel,stopsel"` plus the
    `<C-c>`/`<C-v>` maps. This re-takes the 08-21 fork, so record it in
    `decisions/shift-select-scope` rather than swapping silently.
20. Mason hook: drop `ensure_installed` and install the five servers once
    by hand, deleting the hook; or cut it to its 30 mechanism lines with
    the correct memo path. Trim `theme-preview.sh` to the OSC 11 retint and
    the swatch grid.
21. Decide cht: delete both channels and `finder.nu:27-71`, or bind a key.
    Nothing reaches it today.

**Phase 5 — provisioning (~650 lines)**

22. `install.sh` → `Brewfile` + ~60 lines (tinty via its Homebrew tap,
    tmux-mcp fetch, two plugin clones, `chezmoi apply`). Drop the dry-run
    seam and every Linux branch; drop `rust` if `rustfmt` is the only reason.
23. The three `run_after_*` scripts → their commands plus a three-line
    header; the `SHELL_INIT_BREW_PREFIXES` and `MASON_SEED` seams out.

**Phase 6 — decide, not delete**

24. The litellm / `cll` / `llm-quota` stack: move it to its own repo or an
    opt-in subtree. It is the one thing here that is not a dotfile.
25. `docs/capabilities-*.md` (1,681 lines): the rating record that drove
    the rebuild. Keep, but stop editing them; they are history now.

## Three rules so it does not grow back

- **No changelog in configs.** A comment says what a line does or the one
  trap that breaks it. Never "used to", "removed on", "Corrected". Git blame
  is the history.
- **A board node only when `home/` changes.** Anything else is a commit
  message. `port-first-over-derived-findings` said this on 08-23 and was not
  enforced.
- **No counts in prose.** A number in a paragraph is stale the day after.
  Run the command instead.

## Expected result

| | Before | After |
|---|---|---|
| `home/` config + scripts | ~10,800 lines | ~6,300 |
| `internals/` manual | 4,359 lines | ~3,300 |
| `.pearde/` tracked | 639 files, 7.2 MB | ~280 files, ~2 MB (every `prd.md` kept, specs gone) |
| `AGENTS.md` | 389 lines | ~60 |
| Gestures lost | | `capsule recent`, `zl`/`zc`, `help --fuzzy`, cheat-sheet lookup |
