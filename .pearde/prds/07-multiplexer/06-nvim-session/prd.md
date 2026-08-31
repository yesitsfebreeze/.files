---
state: done        # open|analyzing|refine|question|specced|claimed|blocked|done|failed
origin: requested  # requested = the user asked | derived = the board found it
# from:            # derived only — the PRD whose work surfaced this one
priority: 20        # higher first
complexity: 27      # analyst, at spec time — 1-100. THE WEIGHT the board schedules by
blast-radius: mid
repo:              # the sub-repo the code lands in; delete if n/a
# workflow:        # OPTIONAL — how this kind of job is done: a slug in
#                  #   prds/workflows/. @references/workflow.md.
#                  #   Absent = the brief alone, as before workflows
time:              # OPTIONAL. See @references/parts/order.md
  est:             # the weight, only when complexity is absent. Not a duration
  actual: 10.92h
  # claim: <worker> <started>   # orchestrator-only, present while a worker holds this PRD
commit: 7d48eb2
---
<!-- Ordering reads three axes and no clock: dependency (needs + footprint),
     vision importance (priority), and complexity/blast-radius. Add your own
     keys freely, at any nesting. Nothing outside state, origin, from,
     priority, complexity, blast-radius, claim, repo, workflow, needs and
     footprint is read, and nothing you add is ever dropped.
       needs:     — PRD dir names this one depends on. A hard gate in `plan`
       footprint: — paths this PRD touches. The overlap check
       workflow:  — the route a worker is handed, expanded into its brief

     One sitting is the limit: specs summing `complexity` above `split-above`
     or counting above `specs-above` (both in prds/settings.md, default 40 and
     6) make the analyst's verdict REFINE, and `pearde refine` lands the split
     under `## Children` here — the contract above it stays as written.

     A derived PRD states, in the body, which requested PRD it would otherwise
     get wrong. If it cannot, it is filed `state: deferred` — and if fixing it
     would change only how loudly the board notices, it is a memo, not a PRD.
     See @references/parts/derived.md. -->

# 06-nvim-session — Neovim writes and restores a session so there is something for resurrect to bring back (Q12, Q13). A session plugin owns it; **which plugin is the analyst's call to recommend, not to assume** — persistence.nvim is smaller and lazy-loadable, auto-session is branch-aware and brings a picker. This is work inside the `done` `03-editor` epic and its footprint is that epic's files, so it takes the single-writer rule with it and amends `03-editor` where the plugin list is stated.

Neovim writes and restores a session so there is something for resurrect to bring back (Q12, Q13). A session plugin owns it; **which plugin is the analyst's call to recommend, not to assume** — persistence.nvim is smaller and lazy-loadable, auto-session is branch-aware and brings a picker. This is work inside the `done` `03-editor` epic and its footprint is that epic's files, so it takes the single-writer rule with it and amends `03-editor` where the plugin list is stated.

<!-- Three more headings exist, and none of them is a slot to copy down. Each
     is a claim about the state of this PRD, so an empty copy of it is a false
     one: an empty `## Questions` stops the board on nothing, an empty
     `## Answers` reads as answered, an empty `## Failure` reads as a failed
     attempt. Write the heading when it has content; until then it is absent,
     which is the honest state. @resources/questions.py reports the empty
     ones, and `doctor`'s `questions` row runs it. -->

<!-- `## Questions` — analyst-only, when blocked on the user: one round in the
     format of drill.md — `### Q1: <title>`, the fork in 1-3 sentences ending
     in "?", then exactly three prepared answers, each a complete decision,
     one `(recommended)`. Only real forks the user must settle (naming, scope,
     cost) — never facts a worker could look up, never the PRD restated. A PRD
     parked on the user with no such round never says what it is asking. -->

<!-- `## Answers` — orchestrator-only (or the view), written after asking the
     user: `**Q1** — <the picked answer verbatim, or the user's own words>`,
     numbers matching the round above it. Analysts read these before speccing.
     An `## Answers` with no `## Questions` above it answers nothing. -->

<!-- `## Failure` — implementer-only, after a FAILED attempt: what broke, what
     was tried. `retry` moves this into the body as history and reopens the
     PRD. -->

## Report

spec01-persistence-plugin: exit 0
PASS  precondition: /Users/feb/dev/dotfiles/home/dot_config/nvim/lua/plugins/session.lua exists
PASS  precondition: /Users/feb/dev/dotfiles/home/dot_config/nvim/lazy-lock.json exists
── tree ──
PASS  tree: the spec is folke/persistence.nvim
PASS  tree: lazy = false in code, not only in the comment
PASS  tree: a comment explains why the spec is eager
PASS  tree: opts = {} — setup is called
PASS  tree: `need` is NOT overridden, so the default 1 stands
PASS  tree: a comment says why `need = 1` is kept
PASS  tree: <leader>ss restores this directory's session
PASS  tree: <leader>sl restores the last session
PASS  tree: <leader>sd stops the save on exit
PASS  tree: the published restore command is written down
PASS  tree: it names @resurrect-processes, so 07-persistence finds it
PASS  tree: I8 — exactly one spec in this file
PASS  tree: I7 — no ungrouped autocmd registered here
PASS  tree: lazy-lock.json pins persistence.nvim to a 40-hex commit
PASS  selftest: a copy with `lazy = false` deleted goes red
PASS  selftest: a copy overriding `need` goes red
PASS  selftest: a copy naming another plugin goes red
PASS  precondition: /Users/feb/dev/dotfiles/home/dot_config/nvim/lua/plugins/gitsigns.lua exists
PASS  precondition: /Users/feb/dev/dotfiles/home/dot_config/nvim/lua/plugins/which-key.lua exists
PASS  precondition: /Users/feb/dev/dotfiles/home/dot_config/nvim/lua/plugins/autopairs.lua exists
PASS  precondition: /Users/feb/dev/dotfiles/home/dot_config/nvim/lazy-lock.json exists
── selftests: each mutation must move its named check ───────────────
PASS  selftest staging: delete's glyph emptied in the COPY (L-10 reproduced)
PASS  selftest: L-10 reproduced goes red on non-empty / one-codepoint / disjointness
PASS  selftest staging: delete's glyph set to the add/change glyph in the COPY
PASS  selftest: the collapsed glyph goes red on the delete-vs-add disjointness ALONE
PASS  selftest staging: topdelete's glyph doubled to two codepoints in the COPY
PASS  selftest: a two-codepoint glyph goes red on exactly-one-codepoint
PASS  selftest staging: the whole topdelete line deleted from the COPY
PASS  selftest: a missing topdelete key goes red on all-five-keys-present
PASS  selftest staging: R1's sanctioned fallback set substituted in the COPY
PASS  selftest: the fallback set stays GREEN — the check is not over-fitted to U+F0DA
PASS  selftest staging: config = true deleted from the autopairs COPY
PASS  selftest: the comment-stripped config = true check goes red
PASS  selftest: a RAW grep for 'config = true' still matches the COMMENT — the false PASS the strip closes
PASS  selftest staging: group = "code" renamed to "codes" in the COPY
PASS  selftest: a renamed group goes red on the per-line group check
PASS  selftest staging: a second owner\/repo string planted in the autopairs COPY
PASS  selftest: a second plugin string goes red on the I8 scope guard
PASS  selftest: a copy whose COMMENT alone adds a second repo string stays green (the strip works)
PASS  selftest staging: gitsigns.nvim's commit truncated in the lockfile COPY
PASS  selftest: a truncated commit goes red on the lockfile check

── stage --tree: the three plugin files as text ─────────────────────
PASS  tree/R1: gitsigns.lua names lewis6991/gitsigns.nvim
PASS  tree/R1: its event names BOTH BufReadPre and BufNewFile
      sign add           = [▎]  U+258E
      sign change        = [▎]  U+258E
      sign delete        = []  U+F0DA
      sign topdelete     = []  U+F0DA
      sign changedelete  = [▎]  U+258E
PASS  tree/R1: five sign keys, each one codepoint, add=change=changedelete, delete and topdelete disjoint from it
PASS  tree/R2: which-key.lua names folke/which-key.nvim
PASS  tree/R2: event = "VeryLazy"
PASS  tree/R2: all five leader groups, each on its own line with its name
PASS  tree/R2: and in R2's declared order f < b < c < r < t
PASS  tree/R3: autopairs.lua names windwp/nvim-autopairs
PASS  tree/R3: event = "InsertEnter"
PASS  tree/R3: config = true, comment-stripped
PASS  tree/R3: and NO opts table — R3's "default config" as a checkable fact
PASS  tree/I5: gitsigns.lua binds no key
PASS  tree/I7: gitsigns.lua adds no autocmd
PASS  tree: gitsigns.lua is 2-space indented
PASS  tree/I5: which-key.lua binds no key
PASS  tree/I7: which-key.lua adds no autocmd
PASS  tree: which-key.lua is 2-space indented
PASS  tree/I5: autopairs.lua binds no key
PASS  tree/I7: autopairs.lua adds no autocmd
PASS  tree: autopairs.lua is 2-space indented
PASS  tree/I8: gitsigns.lua declares exactly one owner/repo string
PASS  tree/I8: which-key.lua declares one plugin string plus the slashed group NAME rename/refactor
PASS  tree/I8: autopairs.lua declares exactly one owner/repo string
PASS  tree/R4: lua/plugins/editor.lua does NOT exist — no shared catch-all (I8)
PASS  tree: lazy-lock.json parses and pins all three, 40-hex, one line each
── glyph coverage: every declared glyph, through wezterm ls-fonts ───
      [▎]  0 ▎ \u{258e} drawn by wezterm because custom_block_glyphs=true: Edges([Left(2)])
PASS  glyph coverage: the declared glyph [▎] resolves to a real glyph, no placeholder
      []  0  \u{f0da} x_adv=7 cells=1 glyph=fa-caret_right,4446 wezterm.font("CaskaydiaCove Nerd Font", {weight="Regular", stretch="Normal", style="Normal"})
PASS  glyph coverage: the declared glyph [] resolves to a real glyph, no placeholder
      [U+F0000 control] Placeholder glyphs are being displayed instead.  0 󰀀 \u{f0000} x_adv=7 cells=1 glyph=.notdef,0 wezterm.font("CaskaydiaCove Nerd Font", {weight="Regular", stretch="Normal", style="Normal"})
PASS  glyph coverage: the U+F0000 negative control DOES report Placeholder glyphs — the check discriminates

PASS  the gate touched no REAL Neovim state (~/.config/nvim, ~/.local/share/nvim, ~/.local/state/nvim, ~/.cache/nvim)

PASS — git signs, discovery and autopairs proven warm and offline
PASS  precondition: /Users/feb/dev/dotfiles/home/dot_config/nvim/init.lua exists
PASS  precondition: /Users/feb/dev/dotfiles/home/dot_config/nvim/lua/config/options.lua exists
── vacuity control: an empty config must report the default ─────────
      empty init.lua -> scrolloff=0 (staged config must differ)
PASS  vacuity: empty-config scrolloff reports 0 — the probe reads the config, not defaults

── stage --tree: the files as text ──────────────────────────────────
PASS  tree: home/dot_config/nvim/ holds exactly the post-E.14 census plus lua/plugins/session.lua, added by 07-multiplexer/06-nvim-session (got: ./init.lua ./lazy-lock.json ./lua/config/autocmds.lua ./lua/config/keymaps.lua ./lua/config/lazy.lua ./lua/config/options.lua ./lua/config/shift-select.lua ./lua/plugins/autopairs.lua ./lua/plugins/colorscheme.lua ./lua/plugins/completion.lua ./lua/plugins/conform.lua ./lua/plugins/explorer.lua ./lua/plugins/gitsigns.lua ./lua/plugins/init.lua ./lua/plugins/lsp.lua ./lua/plugins/session.lua ./lua/plugins/statusline.lua ./lua/plugins/table-mode.lua ./lua/plugins/telescope.lua ./lua/plugins/treesitter.lua ./lua/plugins/which-key.lua)
PASS  tree: the first require in init.lua is config.options (got: require("config.options"))
PASS  tree: init.lua registers the .jd filetype (R12)
PASS  tree: options.lua binds no keys, adds no autocmds, loads no plugin manager (hits: 0)
PASS  tree: scrolloff comment states the edge exemption, not the M-1 overclaim
PASS  tree: kill-switch comment carries the no-rotation / 17 GB reason
PASS  tree: listchars comment carries the multispace-not-space parity reason

PASS  the gate touched no REAL Neovim state (~/.config/nvim, ~/.local/share/nvim, ~/.local/state/nvim, ~/.cache/nvim)

PASS — the options baseline is the live baseline, proven in a hermetic Neovim

spec02-gate: exit 0
PASS  precondition: /Users/feb/dev/dotfiles/home/dot_config/nvim/lua/plugins/session.lua exists
PASS  precondition: /Users/feb/dev/dotfiles/home/dot_config/nvim/lazy-lock.json exists
── tree ──
PASS  tree: the spec is folke/persistence.nvim
PASS  tree: lazy = false in code, not only in the comment
PASS  tree: a comment explains why the spec is eager
PASS  tree: opts = {} — setup is called
PASS  tree: `need` is NOT overridden, so the default 1 stands
PASS  tree: a comment says why `need = 1` is kept
PASS  tree: <leader>ss restores this directory's session
PASS  tree: <leader>sl restores the last session
PASS  tree: <leader>sd stops the save on exit
PASS  tree: the published restore command is written down
PASS  tree: it names @resurrect-processes, so 07-persistence finds it
PASS  tree: I8 — exactly one spec in this file
PASS  tree: I7 — no ungrouped autocmd registered here
PASS  tree: lazy-lock.json pins persistence.nvim to a 40-hex commit
PASS  selftest: a copy with `lazy = false` deleted goes red
PASS  selftest: a copy overriding `need` goes red
PASS  selftest: a copy naming another plugin goes red
── headless ──
PASS  headless: persistence.nvim is eager — plugins[...].lazy = false
PASS  headless: persistence.nvim is loaded at startup
PASS  headless: the VimLeavePre save autocmd is registered at startup
PASS  headless: setup() created the session directory
PASS  headless: exiting with two files writes one session (got 1)
PASS  headless: no Session.vim is written into the work tree
PASS  headless: the published restore command reopens alpha.txt
PASS  headless: the published restore command reopens beta.txt
PASS  headless: a bare nvim restores nothing (restore is explicit)
PASS  headless: exiting an empty nvim leaves the session untouched
PASS  headless: a non-default git branch gets its own session file
--- staged nvim stderr (should be empty) ---
PASS  headless: the staged runs wrote nothing to stderr
nvim parser-seed registry — /Users/feb/dev/dotfiles
PASS  scope: /Users/feb/dev/dotfiles/tests exists
PASS  guard: treesitter.lua is where this gate expects it
── the derived registry: gate | verdict | evidence ──────────────────
      nvim-autocmds          seeded                   seed_parsers call + site/parser store write
      nvim-colorscheme       immune                   marker: immune (qa-only)
      nvim-completion        immune                   marker: immune (no-buffer-open)
      nvim-explorer          seeded                   seed_parsers call + site/parser store write
      nvim-formatting        seeded                   seed_parsers call + site/parser store write
      nvim-keymaps           seeded                   inline site/parser store write
      nvim-lsp               seeded                   seed_parsers call + site/parser store write
      nvim-markdown-tables   seeded                   seed_parsers call + site/parser store write
      nvim-options           seeded                   seed_parsers call + site/parser store write
      nvim-plugin-manager    immune                   marker: immune (qa-only)
      nvim-session           seeded                   seed_parsers call + site/parser store write
      nvim-shift-select      seeded                   inline site/parser store write
      nvim-small-plugins     seeded                   seed_parsers call + site/parser store write
      nvim-statusline        immune                   marker: immune (noautocmd-edit)
      nvim-telescope         seeded                   seed_parsers call + site/parser store write
      nvim-treesitter        seeded                   seed_parsers call + site/parser store write
PASS  launchers: at least fifteen tests/ gates launch nvim (got 16)
PASS  launchers: tests/nvim-autocmds.sh is still selected by the launch predicate
PASS  launchers: tests/nvim-colorscheme.sh is still selected by the launch predicate
PASS  launchers: tests/nvim-completion.sh is still selected by the launch predicate
PASS  launchers: tests/nvim-explorer.sh is still selected by the launch predicate
PASS  launchers: tests/nvim-formatting.sh is still selected by the launch predicate
PASS  launchers: tests/nvim-keymaps.sh is still selected by the launch predicate
PASS  launchers: tests/nvim-lsp.sh is still selected by the launch predicate
PASS  launchers: tests/nvim-markdown-tables.sh is still selected by the launch predicate
PASS  launchers: tests/nvim-options.sh is still selected by the launch predicate
PASS  launchers: tests/nvim-plugin-manager.sh is still selected by the launch predicate
PASS  launchers: tests/nvim-shift-select.sh is still selected by the launch predicate
PASS  launchers: tests/nvim-small-plugins.sh is still selected by the launch predicate
PASS  launchers: tests/nvim-statusline.sh is still selected by the launch predicate
PASS  launchers: tests/nvim-telescope.sh is still selected by the launch predicate
PASS  launchers: tests/nvim-treesitter.sh is still selected by the launch predicate
PASS  registry: launchers set-equal accounted gates (16 gates)
── immunity claims, cross-checked ───────────────────────────────────
PASS  claims: tests/nvim-colorscheme.sh reason (qa-only) is in the closed vocabulary
PASS  claims: tests/nvim-colorscheme.sh has no greppable autocmd-firing open — consistent with immune (qa-only)
PASS  claims: tests/nvim-completion.sh reason (no-buffer-open) is in the closed vocabulary
PASS  claims: tests/nvim-completion.sh has no greppable autocmd-firing open — consistent with immune (no-buffer-open)
PASS  claims: tests/nvim-plugin-manager.sh reason (qa-only) is in the closed vocabulary
PASS  claims: tests/nvim-plugin-manager.sh has no greppable autocmd-firing open — consistent with immune (qa-only)
PASS  claims: tests/nvim-statusline.sh reason (noautocmd-edit) is in the closed vocabulary
PASS  claims: tests/nvim-statusline.sh has no greppable autocmd-firing open — consistent with immune (noautocmd-edit)
PASS  claims: tests/nvim-statusline.sh names noautocmd edit as its mechanism, and the mechanism exists
PASS  guard: treesitter.lua still declares 'event = { "BufReadPost", "BufNewFile" }' (line 44; 44 at spec time) — if the trigger set moves, every immunity reason above is stale
PASS  isolation: tests/ and the treesitter plugin spec are byte-identical — this gate only reads

spec03-manual-entry: exit 0
entry <leader>ss <leader>sl <leader>sd topic=edit mode=nvim:normal
descs Restore session for this directory / Restore last session / Stop session save on exit
use-digest entry=b3919ace8b0a107e row=b3919ace8b0a107e | why-digest entry=a3d233b599fb26ea row=a3d233b599fb26ea
reviewer=reader-07-06-nvim-session author=analyst-07-06-nvim-session
ok - scoped
help content model: 97 entries across 4 files, 9 topics, 16 prose-only
╭───┬────────────┬─────────╮
│ # │   topic    │ entries │
├───┼────────────┼─────────┤
│ 0 │ navigate   │      12 │
│ 1 │ find       │      12 │
│ 2 │ history    │       4 │
│ 3 │ edit       │      30 │
│ 4 │ git        │       2 │
│ 5 │ terminal   │      13 │
│ 6 │ agents     │       6 │
│ 7 │ config     │       8 │
│ 8 │ containers │      10 │
╰───┴────────────┴─────────╯
ok

spec04-live-clone: exit 0
PASS  precondition: /Users/feb/dev/dotfiles/home/dot_config/nvim/lua/plugins/session.lua exists
PASS  precondition: /Users/feb/dev/dotfiles/home/dot_config/nvim/lazy-lock.json exists
── tree ──
PASS  tree: the spec is folke/persistence.nvim
PASS  tree: lazy = false in code, not only in the comment
PASS  tree: a comment explains why the spec is eager
PASS  tree: opts = {} — setup is called
PASS  tree: `need` is NOT overridden, so the default 1 stands
PASS  tree: a comment says why `need = 1` is kept
PASS  tree: <leader>ss restores this directory's session
PASS  tree: <leader>sl restores the last session
PASS  tree: <leader>sd stops the save on exit
PASS  tree: the published restore command is written down
PASS  tree: it names @resurrect-processes, so 07-persistence finds it
PASS  tree: I8 — exactly one spec in this file
PASS  tree: I7 — no ungrouped autocmd registered here
PASS  tree: lazy-lock.json pins persistence.nvim to a 40-hex commit
PASS  selftest: a copy with `lazy = false` deleted goes red
PASS  selftest: a copy overriding `need` goes red
PASS  selftest: a copy naming another plugin goes red
── headless ──
PASS  headless: persistence.nvim is eager — plugins[...].lazy = false
PASS  headless: persistence.nvim is loaded at startup
PASS  headless: the VimLeavePre save autocmd is registered at startup
PASS  headless: setup() created the session directory
PASS  headless: exiting with two files writes one session (got 1)
PASS  headless: no Session.vim is written into the work tree
PASS  headless: the published restore command reopens alpha.txt
PASS  headless: the published restore command reopens beta.txt
PASS  headless: a bare nvim restores nothing (restore is explicit)
PASS  headless: exiting an empty nvim leaves the session untouched
PASS  headless: a non-default git branch gets its own session file
--- staged nvim stderr (should be empty) ---
PASS  headless: the staged runs wrote nothing to stderr
PASS  precondition: /Users/feb/dev/dotfiles/home/dot_config/nvim/init.lua exists
PASS  precondition: /Users/feb/dev/dotfiles/home/dot_config/nvim/lua/config/options.lua exists
── vacuity control: an empty config must report the default ─────────
      empty init.lua -> scrolloff=0 (staged config must differ)
PASS  vacuity: empty-config scrolloff reports 0 — the probe reads the config, not defaults

── stage --tree: the files as text ──────────────────────────────────
PASS  tree: home/dot_config/nvim/ holds exactly the post-E.14 census plus lua/plugins/session.lua, added by 07-multiplexer/06-nvim-session (got: ./init.lua ./lazy-lock.json ./lua/config/autocmds.lua ./lua/config/keymaps.lua ./lua/config/lazy.lua ./lua/config/options.lua ./lua/config/shift-select.lua ./lua/plugins/autopairs.lua ./lua/plugins/colorscheme.lua ./lua/plugins/completion.lua ./lua/plugins/conform.lua ./lua/plugins/explorer.lua ./lua/plugins/gitsigns.lua ./lua/plugins/init.lua ./lua/plugins/lsp.lua ./lua/plugins/session.lua ./lua/plugins/statusline.lua ./lua/plugins/table-mode.lua ./lua/plugins/telescope.lua ./lua/plugins/treesitter.lua ./lua/plugins/which-key.lua)
PASS  tree: the first require in init.lua is config.options (got: require("config.options"))
PASS  tree: init.lua registers the .jd filetype (R12)
PASS  tree: options.lua binds no keys, adds no autocmds, loads no plugin manager (hits: 0)
PASS  tree: scrolloff comment states the edge exemption, not the M-1 overclaim
PASS  tree: kill-switch comment carries the no-rotation / 17 GB reason
PASS  tree: listchars comment carries the multispace-not-space parity reason

── stage --headless: the staged config in a real Neovim ─────────────
PASS  R1: mapleader = " "
PASS  R1: maplocalleader = " "
PASS  R2: number
PASS  R2: relativenumber
PASS  R2: cursorline
PASS  R2: signcolumn = yes
PASS  R2: termguicolors
PASS  R2: showmode = false
PASS  R2: laststatus = 3
PASS  R2: pumheight = 10
PASS  R2: fillchars.eob = " "
PASS  R2: cmdheight = 1
PASS  R3: scrolloff = 999
PASS  R3: sidescrolloff = 8
PASS  R3: wrap = false
PASS  R4: splitright
PASS  R4: splitbelow
PASS  R5: expandtab
PASS  R5: shiftwidth = 2
PASS  R5: tabstop = 2
PASS  R5: softtabstop = 2
PASS  R5: smartindent
PASS  R5: breakindent
PASS  R6: ignorecase
PASS  R6: smartcase
PASS  R6: incsearch
PASS  R6: hlsearch = false — the surviving half of L-6
PASS  R7: swapfile = false
PASS  R7: backup = false
PASS  R7: undofile
PASS  R8: updatetime = 250
PASS  R8: timeoutlen = 400
PASS  R9: clipboard = unnamedplus
PASS  R9: mouse = a
PASS  R9: completeopt = menu,menuone,noselect
PASS  R9: virtualedit = block
PASS  R10: list on
PASS  R10: listchars.eol = ↵
PASS  R10: listchars.tab = "→ "
PASS  R10: listchars.multispace = · (dots on 2+ space runs)
PASS  R10: listchars.trail = · (dots on trailing spaces)
PASS  R10: listchars.nbsp = ␣
PASS  R10: listchars holds exactly those five keys
PASS  R10: listchars.space is nil — single interior spaces stay clean (VS Code parity)
PASS  R11: LSP log level is OFF
PASS  R12: x.jd resolves to markdown
      centering: +200 -> winline=11 at winheight=22 (mid 11) · after 20j -> winline=11 · after gg -> winline=1
PASS  centering: mid-file cursor line sits within 1 of window centre
PASS  centering: it STAYS centred while moving (20j)
PASS  centering: gg walks the cursor to the top edge — M-1's exemption, not a defect
PASS  undo: session 1 wrote the edit
PASS  undo: session 2 (same XDG_STATE_HOME) undid it — history survived the restart
PASS  undo: the undo file landed under $S/state/nvim/undo
PASS  undo: no swap or backup litter in the work dir
      kill-switch: plain-session log delta 51B · error-call-session delta 51B
PASS  kill-switch: a forced vim.lsp.log.error adds NOTHING beyond session noise (R11)
── counterfactuals: each mutation must turn its check red ───────────
PASS  counterfactual staging: scrolloff line deleted from the COPY
      no scrolloff: +200 then 20j -> winline=22 at winheight=22 (mid 11)
PASS  counterfactual: without scrolloff the stays-centred check FAILS (cursor walks to the edge)
PASS  counterfactual staging: multispace changed to space in the COPY
PASS  counterfactual: with space-not-multispace the listchars equality FAILS
PASS  counterfactual: with space-not-multispace the space-is-nil check FAILS
PASS  counterfactual staging: set_level line deleted from the COPY
      no kill-switch: plain-session log delta 0B · error-call-session delta 157B
PASS  counterfactual: without set_level the same call GROWS the log
PASS  counterfactual: the growth is the probe's own [ERROR] line

PASS  the gate touched no REAL Neovim state (~/.config/nvim, ~/.local/share/nvim, ~/.local/state/nvim, ~/.cache/nvim)

PASS — the options baseline is the live baseline, proven in a hermetic Neovim
PASS  precondition: /Users/feb/dev/dotfiles/home/dot_config/nvim/lua/plugins/gitsigns.lua exists
PASS  precondition: /Users/feb/dev/dotfiles/home/dot_config/nvim/lua/plugins/which-key.lua exists
PASS  precondition: /Users/feb/dev/dotfiles/home/dot_config/nvim/lua/plugins/autopairs.lua exists
PASS  precondition: /Users/feb/dev/dotfiles/home/dot_config/nvim/lazy-lock.json exists
── selftests: each mutation must move its named check ───────────────
PASS  selftest staging: delete's glyph emptied in the COPY (L-10 reproduced)
PASS  selftest: L-10 reproduced goes red on non-empty / one-codepoint / disjointness
PASS  selftest staging: delete's glyph set to the add/change glyph in the COPY
PASS  selftest: the collapsed glyph goes red on the delete-vs-add disjointness ALONE
PASS  selftest staging: topdelete's glyph doubled to two codepoints in the COPY
PASS  selftest: a two-codepoint glyph goes red on exactly-one-codepoint
PASS  selftest staging: the whole topdelete line deleted from the COPY
PASS  selftest: a missing topdelete key goes red on all-five-keys-present
PASS  selftest staging: R1's sanctioned fallback set substituted in the COPY
PASS  selftest: the fallback set stays GREEN — the check is not over-fitted to U+F0DA
PASS  selftest staging: config = true deleted from the autopairs COPY
PASS  selftest: the comment-stripped config = true check goes red
PASS  selftest: a RAW grep for 'config = true' still matches the COMMENT — the false PASS the strip closes
PASS  selftest staging: group = "code" renamed to "codes" in the COPY
PASS  selftest: a renamed group goes red on the per-line group check
PASS  selftest staging: a second owner\/repo string planted in the autopairs COPY
PASS  selftest: a second plugin string goes red on the I8 scope guard
PASS  selftest: a copy whose COMMENT alone adds a second repo string stays green (the strip works)
PASS  selftest staging: gitsigns.nvim's commit truncated in the lockfile COPY
PASS  selftest: a truncated commit goes red on the lockfile check

── stage --tree: the three plugin files as text ─────────────────────
PASS  tree/R1: gitsigns.lua names lewis6991/gitsigns.nvim
PASS  tree/R1: its event names BOTH BufReadPre and BufNewFile
      sign add           = [▎]  U+258E
      sign change        = [▎]  U+258E
      sign delete        = []  U+F0DA
      sign topdelete     = []  U+F0DA
      sign changedelete  = [▎]  U+258E
PASS  tree/R1: five sign keys, each one codepoint, add=change=changedelete, delete and topdelete disjoint from it
PASS  tree/R2: which-key.lua names folke/which-key.nvim
PASS  tree/R2: event = "VeryLazy"
PASS  tree/R2: all five leader groups, each on its own line with its name
PASS  tree/R2: and in R2's declared order f < b < c < r < t
PASS  tree/R3: autopairs.lua names windwp/nvim-autopairs
PASS  tree/R3: event = "InsertEnter"
PASS  tree/R3: config = true, comment-stripped
PASS  tree/R3: and NO opts table — R3's "default config" as a checkable fact
PASS  tree/I5: gitsigns.lua binds no key
PASS  tree/I7: gitsigns.lua adds no autocmd
PASS  tree: gitsigns.lua is 2-space indented
PASS  tree/I5: which-key.lua binds no key
PASS  tree/I7: which-key.lua adds no autocmd
PASS  tree: which-key.lua is 2-space indented
PASS  tree/I5: autopairs.lua binds no key
PASS  tree/I7: autopairs.lua adds no autocmd
PASS  tree: autopairs.lua is 2-space indented
PASS  tree/I8: gitsigns.lua declares exactly one owner/repo string
PASS  tree/I8: which-key.lua declares one plugin string plus the slashed group NAME rename/refactor
PASS  tree/I8: autopairs.lua declares exactly one owner/repo string
PASS  tree/R4: lua/plugins/editor.lua does NOT exist — no shared catch-all (I8)
PASS  tree: lazy-lock.json parses and pins all three, 40-hex, one line each
── glyph coverage: every declared glyph, through wezterm ls-fonts ───
      [▎]  0 ▎ \u{258e} drawn by wezterm because custom_block_glyphs=true: Edges([Left(2)])
PASS  glyph coverage: the declared glyph [▎] resolves to a real glyph, no placeholder
      []  0  \u{f0da} x_adv=7 cells=1 glyph=fa-caret_right,4446 wezterm.font("CaskaydiaCove Nerd Font", {weight="Regular", stretch="Normal", style="Normal"})
PASS  glyph coverage: the declared glyph [] resolves to a real glyph, no placeholder
      [U+F0000 control] Placeholder glyphs are being displayed instead.  0 󰀀 \u{f0000} x_adv=7 cells=1 glyph=.notdef,0 wezterm.font("CaskaydiaCove Nerd Font", {weight="Regular", stretch="Normal", style="Normal"})
PASS  glyph coverage: the U+F0000 negative control DOES report Placeholder glyphs — the check discriminates

── stage --headless: the staged config in a real Neovim ─────────────
PASS  probe A: exits 0, no TIMEOUT (got: 0)
      present:gitsigns.nvim=true
      loaded:gitsigns.nvim=false
      present:which-key.nvim=true
      loaded:which-key.nvim=false
      present:nvim-autopairs=true
      loaded:nvim-autopairs=false
      uis=0
      probe_ok=true
PASS  A: gitsigns.nvim is a registered spec
PASS  A: which-key.nvim is a registered spec
PASS  A: nvim-autopairs is a registered spec
PASS  A/R1: gitsigns is NOT loaded at startup
PASS  A/R2: which-key is NOT loaded at startup
PASS  A/R3: autopairs is NOT loaded at startup
PASS  A: no UI — recorded, and the reason the VeryLazy fire below is needed
PASS  A: the probe body did not throw
PASS  probe B1: exits 0, no TIMEOUT (got: 0)
      gs_loaded=true
      gs_attached=true
      gs_head=main
      gs_root_is_fixture=true
      cfg_add=[▎]
      cfglen_add=1
      cfg_change=[▎]
      cfglen_change=1
      cfg_delete=[]
      cfglen_delete=1
      cfg_topdelete=[]
      cfglen_topdelete=1
      cfg_changedelete=[▎]
      cfglen_changedelete=1
      ns_found=true
      mark_count=3
      mark_GitSignsChange_row=0
      mark_GitSignsChange_text=[▎ ]
      mark_GitSignsChange_blank=false
      mark_GitSignsChange_cp=U+258E
      mark_GitSignsDelete_row=1
      mark_GitSignsDelete_text=[ ]
      mark_GitSignsDelete_blank=false
      mark_GitSignsDelete_cp=U+F0DA
      mark_GitSignsAdd_row=4
      mark_GitSignsAdd_text=[▎ ]
      mark_GitSignsAdd_blank=false
      mark_GitSignsAdd_cp=U+258E
      del_ne_change=true
      topdel_ne_addglyph=false
      probe_ok=true
PASS  B1/R1: gitsigns LOADED after opening a file — BufReadPre
PASS  B1: it attached to the buffer
PASS  B1: vim.b.gitsigns_head is the fixture's branch
PASS  B1: and the status dict root is the fixture repo
PASS  B1: config readback: signs.add.text is exactly one codepoint (PRD acceptance 2's readback half)
PASS  B1: config readback: signs.change.text is exactly one codepoint (PRD acceptance 2's readback half)
PASS  B1: config readback: signs.delete.text is exactly one codepoint (PRD acceptance 2's readback half)
PASS  B1: config readback: signs.topdelete.text is exactly one codepoint (PRD acceptance 2's readback half)
PASS  B1: config readback: signs.changedelete.text is exactly one codepoint (PRD acceptance 2's readback half)
PASS  B1: the gitsigns_signs_ namespace exists
PASS  B1: three extmarks on f.txt
PASS  B1: the change hunk is at row 0
PASS  B1: the delete hunk is at row 1
PASS  B1: the add hunk is at row 4
PASS  B1: the CHANGE mark's sign_text is non-blank
PASS  B1: the DELETE mark's sign_text is non-blank — the half L-10 fails
PASS  B1: the ADD mark's sign_text is non-blank
PASS  B1: and the delete family's first codepoint DIFFERS from the change family's
PASS  B1: the probe body did not throw
PASS  probe B2: exits 0, no TIMEOUT (got: 0)
      gs_attached=true
      mark_count=1
      mark_GitSignsTopdelete_row=0
      mark_GitSignsTopdelete_text=[ ]
      mark_GitSignsTopdelete_blank=false
      mark_GitSignsTopdelete_cp=U+F0DA
      topdel_ne_addglyph=true
      probe_ok=true
PASS  B2/R1: exactly one extmark on g.txt
PASS  B2/R1: and it is GitSignsTopdelete at row 0
PASS  B2/R1: its sign_text is non-blank
PASS  B2/R1: and differs from the configured add/change glyph
PASS  B2: the probe body did not throw
PASS  probe B3: exits 0, no TIMEOUT (got: 0)
      gs_loaded=true
      probe_ok=true
PASS  B3/R1: opening a path that does NOT exist in the worktree also loads gitsigns — BufNewFile is not decoration
PASS  probe C: exits 0, no TIMEOUT (got: 0)
      wk_loaded=true
      wk_version=3.17.0
      wk_mappings_total=303
      wk_decl_n=6
      wk_decl=<leader>f=find | <leader>b=buffer | <leader>c=code | <leader>r=rename/refactor | <leader>t=table | <leader>s=session
      kids_before=-=Split below <Space>=Find files b=buffer c=code e=Open file explorer f=find q=Quit s=session w=Save |=Split right
      sync_detail=f:live=4,rendered=true b:live=1,rendered=true c:live=1,rendered=true r:live=0,rendered=false t:live=0,rendered=false
      sync_ok=true
      kids_after=-=Split below <Space>=Find files b=buffer c=code e=Open file explorer f=find q=Quit r=rename/refactor s=session t=table w=Save |=Split right
      all_five_after_seeding=true
      probe_ok=true
PASS  C/R2: Config.loaded reached — the VeryLazy fire plus the deferred-setup wait
PASS  C/R2: six leader groups declared
PASS  C/R2: in R2's order, with their names
PASS  C/R2: the RENDERED tree is exactly the declared groups with a live keymap — tree:fix() pruning, executed
PASS  C/R2: and with the missing keymaps seeded, ALL SIX groups render with their names
PASS  C: the probe body did not throw
PASS  probe D: exits 0, no TIMEOUT (got: 0)
      ap_loaded=true
      ap_map_cr=true
      ap_map_bs=true
      ap_check_ts=false
      ap_disable_ft_has_telescope=true
      pair_paren=[()]
      pair_quote=[""]
      au_wait=true
      map_cr_desc=blink.cmp: Accept
      map_bs_desc=autopairs delete
      ap_insertenter_autocmds=0
      probe_ok=true
PASS  D/R3: autopairs LOADED after doautocmd InsertEnter
PASS  D/R3: map_cr is on (the plugin's own default)
PASS  D/R3: map_bs is on (the plugin's own default)
PASS  D/R3: check_ts is false — no treesitter dependency
PASS  D/R3: disable_filetype already excludes TelescopePrompt
PASS  D/R3: typing i( leaves the line ()
PASS  D/R3: typing i" leaves the line ""
PASS  D: the InsertEnter autocmd wait succeeded
PASS  D: insert <CR> belongs to blink, not autopairs — pumvisible() is 0 for blink's float, so an autopairs win would break accept-on-Enter
PASS  D: insert <BS> belongs to autopairs
PASS  D: autopairs registers NO InsertEnter autocmd — it cannot defeat the neighbour gate's wait predicate
PASS  D: the probe body did not throw
PASS  probe E: exits 0, no TIMEOUT (got: 0)
      gcc_exists=true
      gcc_sid=-8
      gcc_desc=Toggle comment line
      gcc_1=[-- local x = 1]
      gcc_back=[local x = 1]
      gcj_1=[-- local x = 1]
      gcj_2=[-- local y = 2]
      comment_plugins=[]
      probe_ok=true
PASS  E: gcc exists as a normal-mode map
PASS  E: with sid -8 — a BUILT-IN, not a plugin map
PASS  E: and Neovim's own description
PASS  E: gcc comments the line
PASS  E: a second gcc restores it
PASS  E: gcj comments the first of two lines
PASS  E: and the second
PASS  E: NO commenting plugin is registered — epic I2, executed
── counterfactuals: each mutation must turn its named check red ─────
PASS  cf1 staging: gitsigns.lua's event line deleted from the COPY
      loaded:gitsigns.nvim=true
PASS  cf1: gitsigns loads EAGERLY (defaults.lazy = false) and probe A goes red
PASS  cf2 staging: which-key.lua's event line deleted from the COPY
      loaded:which-key.nvim=true
PASS  cf2: which-key loads eagerly and probe A goes red
PASS  cf3 staging: autopairs.lua's event line deleted from the COPY
      loaded:nvim-autopairs=true
PASS  cf3: autopairs loads eagerly and probe A goes red
PASS  cf4 staging: delete's glyph emptied in the COPY — live bug L-10
      cfg_delete=[]
      cfglen_delete=0
      mark_count=3
      mark_GitSignsDelete_row=1
      mark_GitSignsDelete_text=[nil]
      mark_GitSignsDelete_blank=true
      mark_GitSignsDelete_cp=<none>
      del_ne_change=false
PASS  cf4: the config readback is the empty string
PASS  cf4: the extmark is STILL PLACED — three marks, nothing errored
PASS  cf4: and the delete mark's sign_text is nil — the blank cell, invisible
PASS  cf4: so the non-blank assertion goes red
PASS  cf4: and the disjointness assertion with it
PASS  cf5 staging: delete's glyph set to the add/change glyph in the COPY
      cfglen_delete=1
      mark_GitSignsDelete_blank=false
      mark_GitSignsDelete_cp=U+258E
      del_ne_change=false
PASS  cf5: the non-empty checks stay GREEN — one codepoint, non-blank
PASS  cf5: the mark is still painted
PASS  cf5: and ONLY the disjointness check goes red — which is why it exists
PASS  cf6 staging: group = "code" renamed to "codes" in the COPY
      wk_decl_n=6
      wk_decl=<leader>f=find | <leader>b=buffer | <leader>c=codes | <leader>r=rename/refactor | <leader>t=table | <leader>s=session
      sync_detail=f:live=4,rendered=true b:live=1,rendered=true c:live=1,rendered=false r:live=0,rendered=false t:live=0,rendered=false
      sync_ok=false
PASS  cf6: the ordered six-group readback goes red
PASS  cf6: which is NOT the expected declaration line
PASS  cf7 staging: the <leader>b group line deleted from the COPY
      wk_decl_n=5
      kids_before=-=Split below <Space>=Find files b=nil c=code e=Open file explorer f=find q=Quit s=session w=Save |=Split right
      sync_detail=f:live=4,rendered=true b:live=1,rendered=false c:live=1,rendered=true r:live=0,rendered=false t:live=0,rendered=false
      sync_ok=false
      kids_after=-=Split below <Space>=Find files b=nil c=code e=Open file explorer f=find q=Quit r=rename/refactor s=session t=table w=Save |=Split right
      all_five_after_seeding=false
PASS  cf7: five declared groups, not six
PASS  cf7: and the seeded rendered-tree check goes red too
PASS  cf8 staging: config = true replaced by an empty function in the COPY
      ap_loaded=true
      pair_paren=[(]
      pair_quote=["]
      map_bs_desc=<none>
PASS  cf8: the plugin still reports LOADED — which is why a load check defends nothing
PASS  cf8: but i( inserts a bare paren
PASS  cf8: and i" a bare quote
── hermeticity ──────────────────────────────────────────────────────
      command -v git under the probe PATH = /private/var/folders/_p/tzmzw3m10kg7sg9hc7_mkm7w0000gn/T/gates.jkwLWd/e12/bin/git
PASS  hermeticity: the shim WAS in force — git resolves to the gate's shim, so an absent log means zero calls
      git-calls.log: 56 lines
        git --git-dir /private/var/folders/_p/tzmzw3m10kg7sg9hc7_mkm7w0000gn/T/gates.jkwLWd/e12/cf4-l10/data/nvim/lazy/blink.cmp/.git --work-tree /private/var/folders/_p/tzmzw3m10kg7sg9hc7_mkm7w0000gn/T/gates.jkwLWd/e12/cf4-l10/data/nvim/lazy/blink.cmp describe --tags --exact-match
        git --git-dir /private/var/folders/_p/tzmzw3m10kg7sg9hc7_mkm7w0000gn/T/gates.jkwLWd/e12/cf4-l10/data/nvim/lazy/blink.cmp/.git --work-tree /private/var/folders/_p/tzmzw3m10kg7sg9hc7_mkm7w0000gn/T/gates.jkwLWd/e12/cf4-l10/data/nvim/lazy/blink.cmp rev-parse HEAD
        git --git-dir /private/var/folders/_p/tzmzw3m10kg7sg9hc7_mkm7w0000gn/T/gates.jkwLWd/e12/cf5-collapse/data/nvim/lazy/blink.cmp/.git --work-tree /private/var/folders/_p/tzmzw3m10kg7sg9hc7_mkm7w0000gn/T/gates.jkwLWd/e12/cf5-collapse/data/nvim/lazy/blink.cmp describe --tags --exact-match
        git --git-dir /private/var/folders/_p/tzmzw3m10kg7sg9hc7_mkm7w0000gn/T/gates.jkwLWd/e12/cf5-collapse/data/nvim/lazy/blink.cmp/.git --work-tree /private/var/folders/_p/tzmzw3m10kg7sg9hc7_mkm7w0000gn/T/gates.jkwLWd/e12/cf5-collapse/data/nvim/lazy/blink.cmp rev-parse HEAD
        git --git-dir /private/var/folders/_p/tzmzw3m10kg7sg9hc7_mkm7w0000gn/T/gates.jkwLWd/e12/cf8-ap-noop/data/nvim/lazy/blink.cmp/.git --work-tree /private/var/folders/_p/tzmzw3m10kg7sg9hc7_mkm7w0000gn/T/gates.jkwLWd/e12/cf8-ap-noop/data/nvim/lazy/blink.cmp describe --tags --exact-match
        git --git-dir /private/var/folders/_p/tzmzw3m10kg7sg9hc7_mkm7w0000gn/T/gates.jkwLWd/e12/cf8-ap-noop/data/nvim/lazy/blink.cmp/.git --work-tree /private/var/folders/_p/tzmzw3m10kg7sg9hc7_mkm7w0000gn/T/gates.jkwLWd/e12/cf8-ap-noop/data/nvim/lazy/blink.cmp rev-parse HEAD
        git --git-dir /private/var/folders/_p/tzmzw3m10kg7sg9hc7_mkm7w0000gn/T/gates.jkwLWd/e12/head/data/nvim/lazy/blink.cmp/.git --work-tree /private/var/folders/_p/tzmzw3m10kg7sg9hc7_mkm7w0000gn/T/gates.jkwLWd/e12/head/data/nvim/lazy/blink.cmp describe --tags --exact-match
        git --git-dir /private/var/folders/_p/tzmzw3m10kg7sg9hc7_mkm7w0000gn/T/gates.jkwLWd/e12/head/data/nvim/lazy/blink.cmp/.git --work-tree /private/var/folders/_p/tzmzw3m10kg7sg9hc7_mkm7w0000gn/T/gates.jkwLWd/e12/head/data/nvim/lazy/blink.cmp rev-parse HEAD
        git --no-pager --no-optional-locks --literal-pathspecs -c gc.auto=0 -c core.quotepath=off -c color.ui=false -c color.diff=false --git-dir /private/var/folders/_p/tzmzw3m10kg7sg9hc7_mkm7w0000gn/T/gates.jkwLWd/e12/fixture/.git check-attr diff --stdin
        git --no-pager --no-optional-locks --literal-pathspecs -c gc.auto=0 -c core.quotepath=off -c color.ui=false -c color.diff=false --git-dir /private/var/folders/_p/tzmzw3m10kg7sg9hc7_mkm7w0000gn/T/gates.jkwLWd/e12/fixture/.git config user.name
        git --no-pager --no-optional-locks --literal-pathspecs -c gc.auto=0 -c core.quotepath=off -c color.ui=false -c color.diff=false --git-dir /private/var/folders/_p/tzmzw3m10kg7sg9hc7_mkm7w0000gn/T/gates.jkwLWd/e12/fixture/.git ls-files --stage --others --exclude-standard --eol /private/var/folders/_p/tzmzw3m10kg7sg9hc7_mkm7w0000gn/T/gates.jkwLWd/e12/fixture/f.txt
        git --no-pager --no-optional-locks --literal-pathspecs -c gc.auto=0 -c core.quotepath=off -c color.ui=false -c color.diff=false --git-dir /private/var/folders/_p/tzmzw3m10kg7sg9hc7_mkm7w0000gn/T/gates.jkwLWd/e12/fixture/.git ls-files --stage --others --exclude-standard --eol /private/var/folders/_p/tzmzw3m10kg7sg9hc7_mkm7w0000gn/T/gates.jkwLWd/e12/fixture/g.txt
        git --no-pager --no-optional-locks --literal-pathspecs -c gc.auto=0 -c core.quotepath=off -c color.ui=false -c color.diff=false --git-dir /private/var/folders/_p/tzmzw3m10kg7sg9hc7_mkm7w0000gn/T/gates.jkwLWd/e12/fixture/.git ls-files --stage --others --exclude-standard --eol /private/var/folders/_p/tzmzw3m10kg7sg9hc7_mkm7w0000gn/T/gates.jkwLWd/e12/fixture/not-created-yet.txt
        git --no-pager --no-optional-locks --literal-pathspecs -c gc.auto=0 -c core.quotepath=off -c color.ui=false -c color.diff=false --git-dir /private/var/folders/_p/tzmzw3m10kg7sg9hc7_mkm7w0000gn/T/gates.jkwLWd/e12/fixture/.git show 35fbd83349cf5962cbef75d9f6340f48be890382
        git --no-pager --no-optional-locks --literal-pathspecs -c gc.auto=0 -c core.quotepath=off -c color.ui=false -c color.diff=false --git-dir /private/var/folders/_p/tzmzw3m10kg7sg9hc7_mkm7w0000gn/T/gates.jkwLWd/e12/fixture/.git show HEAD:f.txt
        git --no-pager --no-optional-locks --literal-pathspecs -c gc.auto=0 -c core.quotepath=off -c color.ui=false -c color.diff=false --git-dir /private/var/folders/_p/tzmzw3m10kg7sg9hc7_mkm7w0000gn/T/gates.jkwLWd/e12/fixture/.git show HEAD:g.txt
        git --no-pager --no-optional-locks --literal-pathspecs -c gc.auto=0 -c core.quotepath=off -c color.ui=false -c color.diff=false --git-dir /private/var/folders/_p/tzmzw3m10kg7sg9hc7_mkm7w0000gn/T/gates.jkwLWd/e12/fixture/.git show b2f931a67315c95c5daab3aac6de62e534808476
        git --no-pager --no-optional-locks --literal-pathspecs -c gc.auto=0 -c core.quotepath=off -c color.ui=false -c color.diff=false rev-parse --show-toplevel --absolute-git-dir --abbrev-ref HEAD
        git --version
        git branch --show-current
PASS  hermeticity: no clone, fetch or ls-remote in the git log
PASS  hermeticity: and no git line naming a remote host at all
      net-calls.log: 0 lines
PASS  hermeticity: every curl/wget REQUEST TARGET is one of mason's two hosts (github.com appears only in mason's User-Agent)
PASS  hermeticity: no package-download URL — no release asset, npm or crates.io

PASS  the gate touched no REAL Neovim state (~/.config/nvim, ~/.local/share/nvim, ~/.local/state/nvim, ~/.cache/nvim)

PASS — git signs, discovery and autopairs proven warm and offline
PASS  precondition: /Users/feb/dev/dotfiles/home/dot_config/nvim/lua/plugins/explorer.lua exists
PASS  precondition: /Users/feb/dev/dotfiles/home/dot_config/nvim/lazy-lock.json exists
── selftests: each mutation must turn its text check red ────────────
PASS  selftest: a copy with `lazy = false` deleted goes red (R1)
PASS  selftest: a copy with show_hidden flipped to false goes red (R2)
PASS  selftest: a copy with the <leader>e key row deleted goes red (R3)
PASS  selftest: a copy with every netrw comment line deleted goes red (R4)
PASS  selftest: a copy with a telescope repo string planted goes red under the two-finders check
PASS  selftest: a lockfile copy with a truncated oil.nvim commit goes red

── stage --tree: the files as text ──────────────────────────────────
PASS  tree: names stevearc/oil.nvim (R1)
PASS  tree: nvim-tree/nvim-web-devicons is a dependency (R1)
PASS  tree: lazy = false — the L-7 correction (R1)
PASS  tree: view_options.show_hidden = true (R2)
PASS  tree: the <leader>e -> <cmd>Oil<CR> key row (R3)
PASS  tree: a comment explains lazy = false (R4)
PASS  tree: a comment names netrw, scoped to this file (R4)
PASS  tree: no vim.keymap.set (I5), no nvim_create_autocmd (I7)
PASS  tree: no repo string beyond oil and devicons (I8)
PASS  tree: names neither television nor telescope (two finders)
PASS  tree: lazy-lock.json parses and pins oil.nvim + nvim-web-devicons to 40-hex commits

── stage --headless: the staged config in a real Neovim ─────────────
PASS  headless: probe A exits 0, no TIMEOUT (got: 0)
PASS  R1: plugins[oil.nvim].lazy = false — the L-7 correction, direct
PASS  R1: oil is LOADED at startup with no key pressed
PASS  R1: nvim-web-devicons is loaded at startup too (the dependency)
PASS  R1: :Oil exists at startup — 2 (no cmd= declared, so 0 when lazy)
PASS  R1: loaded_netrwPlugin is EXACTLY 1 — oil's hijack is installed
PASS  R3: <leader>e desc = Open file explorer
PASS  R3: <leader>e rhs = <cmd>Oil<CR> — the REAL mapping, not the stub
PASS  R3: <leader>e expr = 0 — lazy's loader stub reads expr = 1
PASS  R2: oil.config.view_options.show_hidden = true
PASS  R1: oil.config.default_file_explorer = true
PASS  ASSUMPTION (owned by E.2, not E.10): :Explore does not exist
PASS  R4: oil's eager load costs under 20 ms (measured 2821166 ns)
PASS  headless: probe B exits 0, no TIMEOUT (got: 0)
PASS  PRD acceptance 3: :e some/dir lands on filetype = oil, no key pressed
PASS  PRD acceptance 3: and the buffer is oil://<work>/sub/
PASS  PRD acceptance 3: oil was already loaded when :e ran
PASS  headless: probe C exits 0, no TIMEOUT (got: 0)
PASS  PRD acceptance 1: <leader>e on sub/inner.txt opens oil://<work>/sub/
PASS  PRD acceptance 1: and NOT the cwd — the manual's wording, not the PRD's
PASS  PRD acceptance 1: sub/ renders 2 lines (../, inner.txt)
PASS  headless: probe C2 exits 0, no TIMEOUT (got: 0)
PASS  PRD acceptance 1: with NO file loaded, <leader>e opens the cwd
PASS  PRD acceptance 1: and the cwd listing is 4 lines
PASS  headless: probe D exits 0, no TIMEOUT (got: 0)
PASS  PRD acceptance 1: the top directory renders 4 lines
PASS  R2 / PRD acceptance 1: the listing carries .hidden
PASS  PRD acceptance 1: the listing carries ../ (also a dotfile)
PASS  PRD acceptance 1: the listing carries sub/
PASS  PRD acceptance 4: the visible.txt line is present
PASS  PRD acceptance 4: the visible.txt line carries a byte outside ASCII — the icon renders
PASS  PRD acceptance 1: the oil buffer is modifiable — directories AS EDITABLE BUFFERS
PASS  PRD acceptance 1: filetype = oil
PASS  headless: probe E exits 0, no TIMEOUT (got: 0)
PASS  smoke: the visible.txt line was found to edit
PASS  smoke: :w opens a second window — the confirmation float
PASS  smoke: the float's filetype is oil_preview
PASS  smoke: the float shows MOVE visible.txt -> renamed.txt
PASS  smoke: the float shows the [Y]es / [N]o prompt
PASS  TRAP: :w CLEARED modified — the write looks done and is not
PASS  TRAP: :w alone left visible.txt on disk
PASS  TRAP: :w alone created no renamed.txt
PASS  smoke: y is a buffer-local confirm key
PASS  smoke: <CR> is NOT a confirm key — a probe omitting the y reads a healthy rename as broken
PASS  PRD acceptance 2 (smoke only): after y, visible.txt is gone from disk
PASS  PRD acceptance 2 (smoke only): after y, renamed.txt is present
PASS  PRD acceptance 2 (smoke only): .hidden was untouched
PASS  PRD acceptance 2 (smoke only): the float closed — one window left
PASS  PRD acceptance 2 (smoke only): filetype back to oil
PASS  headless: probe F exits 0, no TIMEOUT (got: 0)
PASS  probe F: :messages is empty across a full open — no plugin complained
PASS  probe F: the stage's stderr is byte-empty (       0 bytes)
── counterfactuals: each mutation must turn its check red ───────────
PASS  CF1 staging: `lazy = false` deleted from the COPY
PASS  CF1: without lazy = false, plugins[oil.nvim].lazy reads true
PASS  CF1: and oil is NOT loaded at startup
PASS  CF1: and :Oil does not exist at all (0 — no cmd= is declared)
PASS  CF1: and loaded_netrwPlugin is nil — the hijack is NOT installed
PASS  CF1: and <leader>e is lazy's loader STUB — rhs = nil
PASS  CF1: and expr = 1, while the desc is unchanged — why desc alone cannot tell them apart
PASS  CF1: the desc IS unchanged, proving the desc-only check is blind
PASS  CF1: probe B goes RED — :e some/dir has empty filetype
PASS  CF1: probe B goes RED — the buffer is not an oil:// URL
PASS  CF1: probe B goes RED — oil still unloaded after :e some/dir
PASS  CF1 ASYMMETRY: probe D stays GREEN on the broken shape — 4 lines
PASS  CF1 ASYMMETRY: probe D stays GREEN — .hidden still listed
PASS  CF1 ASYMMETRY: probe D stays GREEN — the icon still renders
PASS  CF1 ASYMMETRY: probe E stays GREEN — the rename still works
PASS  CF2 staging: show_hidden flipped to false in the COPY
PASS  CF2: with show_hidden = false the listing drops to 2 lines
PASS  CF2: and .hidden is gone — R2's check goes red
PASS  CF2: and ../ is gone too, because it also starts with a dot
PASS  CF3 staging: oil's dependencies line deleted from the COPY
PASS  CF3 staging: E.13's devicons dependency ALSO deleted — one line alone is inert here
PASS  CF3: with no devicons anywhere the icon column renders EMPTY — the icon check goes red
PASS  CF3: and nothing else moves — the listing is still 4 lines
PASS  CF3: and .hidden is still there
PASS  CF4 staging: the keys block deleted from the COPY
PASS  CF4: without the keys block the <leader>e desc reads nil
PASS  CF4: and the rhs reads nil
PASS  CF4: and the expr reads nil
PASS  CF4: oil still loads eagerly — the keys row is a BINDING, not the loader
PASS  CF5 staging: every netrw comment line deleted from the COPY
PASS  CF5: the --tree R4 netrw check goes red on that copy
PASS  CF5: and no behavioural check moves — the file still names oil and loads eagerly
PASS  hermeticity: the git shim logged calls (plugins run local git)
PASS  hermeticity: git-calls.log holds no clone, fetch, or ls-remote

PASS  the gate touched no REAL Neovim state (~/.config/nvim, ~/.local/share/nvim, ~/.local/state/nvim, ~/.cache/nvim)

PASS — oil.nvim loads eagerly and hijacks directories, proven in a hermetic Neovim
