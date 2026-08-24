# Wave 4 — interactive checklist

Automated half: `just gate 4`.

- [ ] **S.4** — the bare-word fallback must never hijack a real command.
      Adversarial verify: a second agent's only job is to break it. Try at
      least `ls | something-unknown`, `./x`, a typo'd real command, and a bare
      word that is also a directory.
      PASS: only a bare word that is unambiguously a jump target jumps.
      FAIL: any real command, pipeline or path swallowed by the fallback.
- [ ] **S.4** — whether the bare-word jump *feels* instant. Type a bare
      word and jump, ten times, in a real session.
      PASS: no perceptible pause between Enter and the new prompt.
      FAIL: a hitch you can notice — a stopwatch cannot settle this and a
      benchmark on a warm cache will lie about it.
- [ ] **E.14** — the shift-select collapse under real keyboard timing.
      Adversarial verify: a second agent tries to break the collapse
      semantics against the PRD's acceptance criteria before the wave gate.
      Hold shift and sweep; release; type. Repeat fast enough to race the
      mapping.
      PASS: the selection collapses exactly as the PRD says, every time.
      FAIL: an off-by-one (M-2 records two live ones: `S-Right` already
      selects two chars via `v<Right>`, and `S-Left` from insert selects two
      via `yz`) or a collapse that depends on how fast you typed.
- [x] **D.3** — decision: the shift-to-select full port with tests, or the
      conscious downgrade? Pick a path and record it in
      [`03-editor/14`](../../prds/03-editor/14-shift-select/prd.md).
      PASS: the PRD names the chosen path. If the downgrade is taken, the C/U
      header is updated to roughly C 3 / U 5 and the inventory entry with it.
      FAIL: the code lands before the choice is written down.
      **Closed 2026-08-24 from the record, not by a fresh decision.** This is
      the one box on this page a human does not have to re-run: its PASS
      criterion is "the PRD names the chosen path", which is a document to
      read rather than a screen to watch. It does.
      `prds/03-editor/14-shift-select/prd.md` carries
      `## Simplification option — DECLINED 2026-08-21` — "Declined on
      2026-08-21 by the human, in `shift-select-scope` (task D.3). The full
      port is the path: R1-R8 in full, with the tests." The header stays
      `C 7 · U 7` and the inventory entry is unchanged, which is what the
      PASS clause requires of the branch taken.
      The FAIL clause is also satisfied in order: the decision is dated
      2026-08-21 and the code landed 2026-08-24 at `f9cb54b` — the choice was
      written down first.
- [ ] **T.4** — copy mode enters clean. Select some text with the mouse,
      then press `Ctrl+Shift+X`.
      PASS: copy mode opens with no selection carried in, and `h`/`j`/`k`/`l`,
      `w`/`b`, `g`/`G` all move the cursor.
      FAIL: a stale selection visible on entry, or any builtin motion dead.
- [ ] **T.4** — the `c` cycle, including the blank-cell start. Press `c` on
      a blank region, move onto text, press `c` again; paste elsewhere. Then
      re-enter and run one `c`-`c` cycle starting on text.
      PASS: both cycles copy the swept range to the clipboard and close copy
      mode; the second press never re-anchors.
      FAIL: a desynced toggle (the second `c` starts a new selection), or
      nothing on the clipboard.
- [ ] **T.4** — copy mode has no search, and normal mode does. In copy mode
      press `/`. Leave, press `Ctrl+Shift+F`.
      PASS: `/` does nothing at all; `Ctrl+Shift+F` opens the search prompt
      over the pane.
      FAIL: `/` opens anything, or the search prompt fails to appear
      (something shadowed the default).
- [ ] **T.4** — the shell entry. Run `copymode` at a host prompt.
      PASS: that pane drops into copy mode exactly as `Ctrl+Shift+X` does.
      FAIL: escape bytes printed as text, or nothing happens.
- [ ] **T.4** — `Ctrl+V` is a bracketed paste. Copy a two-line snippet;
      paste at a shell prompt, then into nvim insert mode.
      PASS: both receive it in one piece, nvim without auto-reindenting it.
      FAIL: the second line executes at the prompt, or nvim staircases the
      indent.
- [ ] **T.4** — `Ctrl+C` copies or interrupts, never both. With text
      selected, press `Ctrl+C`, paste elsewhere; then run `sleep 100` and
      press `Ctrl+C` with nothing selected.
      PASS: the selection lands on the clipboard and clears; the sleep dies
      to SIGINT.
      FAIL: an interrupt fired while a selection existed, or a copy eaten
      with nothing selected.
- [ ] **T.4** — the window drag handle. Hold `Ctrl+Alt+Cmd` and drag with
      the left button; then do an ordinary left-drag.
      PASS: the OS window moves; the plain drag still selects text.
      FAIL: the window stays put, or plain drags stop selecting.
- [ ] **T.4** — the link opener under a mouse-capturing TUI. Open nvim with
      its mouse enabled, display a URL, `Ctrl`+left-click it; then
      plain-click elsewhere.
      PASS: the browser opens the URL, and the plain click still reaches
      nvim.
      FAIL: the click is swallowed by nvim (the `mouse_reporting` flag
      missing), or plain clicks stop reaching the app.
- [ ] **T.6** — every tab starts dim. Launch WezTerm from the Dock and look
      at the bar without touching anything.
      PASS: all nine digits render in the inactive-tab colour, and tab 1
      differs from the rest only by having focus.
      FAIL: any background tab lit at startup, which means a baseline was
      learned against something other than the spawned shell.
- [ ] **T.6** — a command lights its tab, and exiting dims it again. In tab
      3 run `htop` (or `sleep 120`), switch to tab 1, wait. Then quit the
      command and wait again.
      PASS: tab 3's digit brightens within one `status_update_interval`
      (5 s) and returns to the dim colour within one interval of the command
      exiting.
      FAIL: no change, a change that needs a keystroke in tab 3, or a tab
      that stays lit after the command is gone.
- [ ] **T.6** — the OR over panes. In tab 4, split the pane with WezTerm's
      own default `Ctrl+Alt+Shift+"` (measured from `show-keys --lua`; this
      config binds no split key of its own), run `sleep 120` in the new
      pane, leave the sibling at its prompt, and switch away.
      PASS: tab 4 is lit while one of its two panes is idle.
      FAIL: the tab stays dim, which means the classification read only the
      active pane.
- [ ] **T.6** — occupancy does not repaint the focused tab. With a long
      command running in the focused tab, compare it against the same tab
      focused and idle.
      PASS: the focused tab looks identical either way — background says
      focus, foreground says busy, and the two never fight.
      FAIL: the focused tab changes appearance, which is R3's
      separate-signal clause broken.
- [ ] **T.6** — an outside kill decays to dim. In tab 5 run `sleep 300`,
      find the process from another tab and `kill -9` it; wait one interval.
      Then repeat against the pane's *shell* PID.
      PASS: both end dim within one interval — the killed command hands the
      foreground back to the shell, and the killed shell closes its pane,
      whereupon the nine-tab floor refills the slot with a fresh one.
      FAIL: either case leaves a lit tab.
- [ ] **T.6** — a theme switch recolours both states. With one tab lit and
      the rest dim, press `F6`, then press it back.
      PASS: both the dim and the lit digits change with the scheme, in every
      open window, with no edit to any file.
      FAIL: either state keeps its old colour, or only one window retints.
      Judgement row: also say whether the lit digit is legible against the
      bar and does not out-shout the focused tab (R3). If it does not read
      well, the fix is the ANSI slot in `format-tab-title`, not a hex value.
- [ ] **E.7** — the unattended install on a fresh machine. Launch a real
      interactive `nvim` on a machine with an empty `<data>/mason`, open a
      Lua file, and wait.
      PASS: mason installs `lua_ls`, `bashls`, `pyright`, `rust_analyzer`
      and `tailwindcss` with no prompt, and `lua_ls` attaches.
      FAIL: any prompt, any server missing afterwards.
      Why a human: `mason-lspconfig.setup()` guards `ensure_installed` with
      `not platform.is_headless`, so no scripted run can ever trigger an
      install (measured 2026-08-23).
- [ ] **E.7** — completion offers Neovim API members. In a real `nvim`, in
      a Lua file, type `vim.` and look at the blink menu.
      PASS: server-provided members (`fn`, `api`, `lsp`, …) appear, and
      `vim` is not underlined as an undefined global.
      FAIL: an empty menu, or `vim` flagged.
      Why a human: measured 2026-08-23 inside this node's own hermetic gate
      root. `lua_ls` answers `textDocument/completion` after `vim.` with
      three items — `undefined_global_xyz`, `vim`, `api`, every one of them
      a word already in the buffer — and no API member at all, across
      twelve five-second retries. The `vim`-not-flagged half is vacuous
      headless for a second reason: the only diagnostic published in 40 s
      is a syntax error, and a planted `undefined_global_xyz` is not
      flagged either, so the check cannot tell a working
      `globals = { "vim" }` from a broken one. A gate must not fall back on
      the real `HOME` (W0.9), so this stays a human check.
- [ ] **C.3** — `git push` over both protocols. In a fresh capsule on a
      private repo: `git pull`, `git push`, then the same against an SSH
      remote, then `ssh -T git@github.com`.
      PASS: all four succeed with no prompt of any kind.
      FAIL: any password, passphrase or host-key question — and a
      "delta: not found" from the pager counts, because it means the
      container inherited a host-only tool.
- [ ] **C.3** — the agents start authenticated. Run `claude` and `opencode`
      inside a fresh capsule.
      PASS: both reach a working prompt with no login flow and no onboarding
      questions.
      FAIL: a login URL, a theme prompt, or an MCP server failing to start —
      the last would mean the unfiltered host `.claude.json` got copied.
- [ ] **C.3** — nothing is in the image, and the host copy is untouchable.
      Run `docker history --no-trunc capsule:latest`, then inside the
      capsule `touch /opt/capsule/host/ssh/probe`.
      PASS: no credential material anywhere in the history, the write fails
      read-only, and `ls -la ~/.ssh` on the host is unchanged.
      FAIL: any token in a layer, or a write that lands on the host.
- [ ] **C.3** — rotation heals by reconnecting. Rotate the gh token
      (`gh auth refresh`, or log out and back in), then re-enter the *same,
      still-running* capsule and push.
      PASS: the push works with no `--rebuild` and no container recreation.
      FAIL: a stale token, or the fix requiring a rebuild — that is the whole
      reason the creds directory is mounted as a directory rather than as
      individual files.
- [ ] **C.3** — a capsule created before this node landed. Enter one and try
      to push.
      PASS: it fails, and `capsule --rebuild` fixes it — docker cannot add
      mounts to an existing container, so this is the documented answer
      rather than a bug.
      FAIL: the tool pretends the mounts are there, or `--rebuild` does not
      fix it.
- [ ] **T.7** — a real GUI launch comes up as nine working nushell prompts.
      Launch WezTerm from the Dock or Spotlight (not from a terminal) and
      type `$nu.default-config-dir` in three different tabs.
      PASS: every tab has a nushell prompt and answers
      `~/.config/nushell`.
      FAIL: any tab showing `Unable to spawn nu because: No viable
      candidates found in PATH`, a `%` shell prompt (the passwd login shell,
      `/bin/zsh` — R6 absent), or an answer under `~/Library/Application
      Support`.
      Why a human: `tests/wezterm-launchd-path.sh --spawn` covers the spawn
      through `wezterm-mux-server`, but measured 2026-08-23 `wezterm.gui` is
      nil there — the config's `wezterm.gui.default_key_tables()` raises and
      WezTerm silently falls back to its defaults — so the probe loads the
      file through a `wezterm.gui` shim, and `window-config-reloaded` is a
      GUI event the mux server never emits, so the nine-tab floor never runs
      and the probe only ever sees one pane.
- [ ] **T.7** — F6 flips the theme from a GUI-launched window. In that same
      Dock-launched window press `F6`, wait, press it again.
      PASS: every window retints both times.
      FAIL: nothing happens — the inline prefix in the F6 `sh -lc` is what
      puts `~/.local/bin` on that subprocess's PATH.
      Why a human: `tinty` is the binary the prefix earns (measured: `sh -lc`
      recovers `/opt/homebrew/bin` on its own through `path_helper` and
      `/etc/paths.d/homebrew`, so `nu` resolves without it while `tinty` does
      not), and the observable is a colour change in a live GUI window.
      The automated stage proves only that the directory reaches the
      subprocess's PATH.
- [ ] **T.7** — a GUI launch and a terminal launch resolve the same
      binaries. In the Dock-launched window run `which -a nu nvim tv zoxide
      node npm`; then run `wezterm` from an existing terminal and run the
      same thing there.
      PASS: each name resolves to the same absolute path in both windows.
      FAIL: any name resolving differently — the launch prefix's order has
      leaked past `env.nu`'s repair.
      Why a human: two differently *launched* real windows is the whole
      subject, and it cannot be staged. Worth running on the listed names
      rather than a favourite: measured 2026-08-23, six basenames exist in
      more than one of the four seeded directories (`burrito`, `node`,
      `npm`, `npx`, `tree-sitter`, `zoxide`), so those are where a reorder
      would actually show.
- [ ] **E.13** — the Nerd Font glyphs. The rendered line emits four
      private-use codepoints — the branch glyph, the fileformat glyph, the
      devicon for the filetype, and the diagnostic signs. Open a file in a
      real WezTerm window and look at the statusline.
      PASS: every glyph is an icon.
      FAIL: any tofu box or double-width smear.
      Why a human: headless proves the codepoints are *emitted* and can never
      prove they *display*. The font is `font-caskaydia-cove-nerd-font` from
      `install.sh`, owned by 02-terminal.
- [ ] **E.13** — legibility of the derived colours. Cycle normal, insert,
      visual, replace and command in a real window.
      PASS: `base00` text is readable on each of `base0D`/`base0B`/`base0E`/
      `base08`/`base0A`, and the `b` and `c` sections are readable too.
      FAIL: any section where the text disappears into its background.
      Why a human: no headless check can settle contrast. The palette is not
      this node's to change — a failure here is a correction against
      03-editor/11-colorscheme, not a hex value added to `statusline.lua`.
- [ ] **E.13** — one statusline across real splits, at a real width. Open
      three splits and a vertical split in a real window.
      PASS: exactly one line at the bottom of the terminal, the `%=` split
      puts progress and location hard right, and nothing is truncated at a
      normal window width.
      FAIL: a per-window line, a second line, or a section clipped away.
      Why a human: the headless probe proves `laststatus == 3` and that no
      window carries a local statusline; it cannot see truncation at a real
      terminal width.
- [ ] **E.15** — the idle realign, and whether it helps or fights you. In a
      real window open a markdown file, type a ragged table row, then stop
      moving for a second without leaving insert mode.
      PASS: the row realigns on its own and the cursor stays in the cell you
      were typing in.
      FAIL: the buffer rewrites itself under the cursor, or nothing happens
      at all.
      Why a human: `CursorHold` never fires headless. Measured 2026-08-23 —
      the plugin's `TableModeAutoAlign` `CursorHold` autocmd is registered
      (the automated stage asserts that), and after 2.5 s of deferred time
      on a modified buffer it had fired 0 times. It needs real idle input.
      Note while you are there: table mode raises the session-global
      `updatetime` from E.1's 250 to 500 and does not put it back when you
      leave the buffer (measured). That half-second is this row's subject.
- [ ] **E.15** — the table paints as a table. Look at an aligned table in a
      real window.
      PASS: the `|` separators and any `:` alignment markers are visibly
      distinct from the cell text, and the `-` border row reads as a border.
      FAIL: a uniform wall of text — the headless gate proves
      `TableSeparator` links to `Delimiter`, not that the link renders
      against the tinted palette.
- [ ] **C.4** — the picker, after a restart. Mount three directories, quit
      WezTerm, reopen it, press `Ctrl+Shift+S`.
      PASS: a list titled `Recent` opens with all three, newest first; typing
      narrows it; Enter attaches to that directory's capsule at `/workspace`.
      FAIL: no list, a title that is not `Recent`, the wrong order, or
      `No viable candidates found in PATH`.
      Why a human: the picker needs a TTY — `capsule recent` refuses under
      `nu -c` on purpose (`$nu.is-interactive` is false there), so the
      automated gate proves the guard and the argv against a recording `tv`
      shim and never the screen.
- [ ] **C.4** — the new-tab variant. With something running in the current
      pane, press `Ctrl+Shift+O`.
      PASS: a new tab opens, the picker is in that tab, the pick attaches
      there, and the pane you came from is untouched.
      FAIL: the picker appears in the old pane, or the new tab dies at once.
      Why a human: the binding is `SpawnCommandInNewTab` rather than
      spawn-then-type precisely because a pane created this instant has no
      shell reading its pty; only a real spawn shows whether that holds.
- [ ] **C.4** — aborting costs nothing. Press `Ctrl+Shift+O`, then `Esc`.
      PASS: the tab stays, with a usable nushell prompt in the directory you
      picked from.
      FAIL: the tab closes, or the shell exits.
      Why a human: `nu --execute` is what leaves an interactive shell behind
      an aborted pick, so an abort should be indistinguishable from the plain
      tab `Ctrl+Shift+T` would have given.
- [ ] **C.4** — `Ctrl+Shift+T` is still a plain tab. Press it.
      PASS: a plain new tab, no picker.
      FAIL: a picker, or nothing.
      Why a human: the automated gate reads `show-keys --lua` and sees `'T'`
      still bound to `SpawnTab`; that is the declaration, not the behaviour.
- [ ] **C.4** — a deleted directory. Delete a directory you mounted, then
      open the picker twice.
      PASS: it is absent the first time, and `~/.cache/capsule/recents.nuon`
      no longer names it.
      FAIL: still listed, or listed once more.
      Why a human: prune-on-read is proven hermetically, but only a real
      round trip shows the rewrite surviving the pick that follows it.
- [ ] **E.11** — prettier on a hand-wrapped PRD file. Open any
      `prds/**/prd.md` in nvim and save it, then read the diff.
      PASS: the churn is acceptable as it stands.
      FAIL: it is not — file a correction proposing a `.prettierrc`, and do
      **not** tune this node's `formatters_by_ft`.
      Why a human: the measurement is done and the verdict is taste. Measured
      2026-08-23 on a real PRD file: 23−/34+ across 8 hunks, and **no
      paragraph line break moved** — proved by stripping blank lines and
      leading space and diffing, so a reflow would have shown as merged or
      split lines and did not. What does change: (a) the YAML frontmatter's
      `footprint:` flow sequence explodes into a block sequence with a
      trailing comma — **prettier rewrites frontmatter, which implementers
      are forbidden to edit** — while `deps:` survives only because it fits
      80 columns; (b) a blank line is inserted after every `##` heading; (c)
      list-continuation paragraphs re-indent 6→10 spaces and gain a blank
      line before the next item; (d) `*emphasis*` becomes `_emphasis_`, three
      places. Cold start 79–89 ms, well inside the 500 ms budget, so the
      timeout is not what saves you here. Hunk (a) is the one to weigh: this
      board's contract says a worker never edits frontmatter, and a save
      would.
- [ ] **E.11** — stylua on this repo's Neovim lua. Save any file under
      `home/dot_config/nvim/lua/` and read the diff.
      PASS: the retab is acceptable.
      FAIL: it is not — file a correction proposing a `.stylua.toml`, and do
      not add one inside this node.
      Why a human: **StyLua's default `indent_type` is Tabs** and this repo
      writes 2-space Neovim lua, with no `.stylua.toml` anywhere in the tree.
      Measured 2026-08-23: `conform.lua` itself is 56−/56+ in a single hunk,
      and it is repo-wide rather than one file's problem — **12 of the 15**
      lua files under `home/dot_config/nvim/` get retabbed on save; only
      `keymaps.lua`, `options.lua` and `plugins/init.lua` are already clean.
      Whichever way this goes, it is one config file's worth of work, and
      nobody should discover it by watching a save reindent their editor.
- [ ] **E.12** — the which-key overlay actually draws. In a real terminal open
      a file with a language server attached, press `<leader>` and pause.
      PASS: the popup appears and lists the groups with their names.
      FAIL: no popup, or a group whose name is missing or wrong.
      Why a human: `require("which-key").show()` never returns under
      `--headless` — the session hangs to the watchdog with no output — so the
      rendering cannot be executed there. The gate proves the five
      declarations and the pruned/seeded tree; only a human can see the
      window. Expect `r` to be absent outside an LSP-attached buffer and `t`
      to be absent outside a markdown buffer (vim-table-mode builds its
      `<leader>t` maps at plugin load time): that is `tree:fix()` pruning an
      empty group, and it is a PASS.
- [ ] **E.12** — the deleted-hunk sign is legible, not merely present. Open a
      tracked file in a real terminal, delete a line, write, and look at the
      sign column.
      PASS: the caret glyph is visible in the gutter and plainly different
      from the bar used for add and change.
      FAIL: a blank cell (live bug L-10), a box or tofu, or a glyph you cannot
      tell from the bar.
      Why a human: the gate proves the string is placed as an extmark and that
      the font covers the codepoint; what it cannot prove is that the cell is
      readable against the active palette at the configured font size.
