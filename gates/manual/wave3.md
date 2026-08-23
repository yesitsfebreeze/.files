# Wave 3 — interactive checklist

Automated half: `just gate 3`.

- [ ] **T.2** — fresh launch shape. Quit WezTerm, launch it clean.
      PASS: one fullscreen window, tabs titled `1`–`9`, focus on tab 1.
      FAIL: 16 tabs (the re-entrancy failure), any order other than `1..9`
      (the `1,0,2,3…` no-op-move failure), a non-fullscreen window, or focus
      elsewhere.
- [ ] **T.2** — a dead slot heals in place. Focus tab 5, close tab 3
      (`exit` in it), wait one `status_update_interval` (5 s).
      PASS: nine tabs, the replacement at position 3, focus still on the tab
      that was focused.
      FAIL: eight tabs, the replacement at the end, renumbered tabs after
      the hole, or focus snapped onto the blank replacement.
- [ ] **T.2** — new windows come up at the floor. Run
      `wezterm cli spawn --new-window` with no key pressed.
      PASS: the new window holds nine tabs at birth, not up to 5 s later.
      FAIL: a lone tab, or nine only after a visible delay.
- [ ] **T.2** — extra tabs are adopted. Open a tenth tab by hand, wait two
      ticks (≥10 s).
      PASS: ten tabs still standing.
      FAIL: the tenth culled — the floor became a target.
- [ ] **T.2** — `Ctrl+Shift+Q` closes for real. Press it in a nine-tab
      window.
      PASS: the whole window closes, no confirmation prompt, no tab refilled
      behind the close.
      FAIL: a prompt per tab, or the window refilling and never dying (the
      reconciler racing the close).
- [ ] **T.2** — two windows stay independent. Hold two windows open across
      several ticks, close a tab in each.
      PASS: each window heals to its own nine; neither spawns into the
      other.
      FAIL: cross-window refill (the shared-slot-map failure R5 exists to
      prevent).
- [ ] **T.3** — the F5 jump landing on the right pane. Press `F5`, then `3`.
      PASS: focus is on tab 3 and the next keystroke types into that tab's
      pane — the mode has popped.
      FAIL: the wrong tab, the next keystroke swallowed (the mode still
      armed), or anything painted on screen.
- [ ] **T.3** — a mistyped letter cancels clean. At a shell prompt press
      `F5` then `x`; repeat in nvim insert mode.
      PASS: no character inserted in either, no bell, next keystroke types
      normally.
      FAIL: a character leaks (the `until_unknown` fall-through R2 exists to
      stop), or any bell.
      (Silence here is the design: the letter's only job is to cancel — L-11
      is unreachable, not fixed.)
- [ ] **T.3** — `Escape` cancels. Press `F5`, then `Escape`.
      PASS: nothing activates, the next keystroke types normally.
      FAIL: a tab switch, or a swallowed next keystroke.
- [ ] **T.3** — the misfire timeout. Press `F5`, wait 6 s, then type.
      PASS: the keystroke types normally — the table expired on its own.
      FAIL: the keystroke swallowed or a tab switch.
- [ ] **T.3** — pane movement is WezTerm's own. Split a tab, press
      `Ctrl+Shift+`arrow in each direction.
      PASS: focus moves between panes.
      FAIL: nothing happens — something this epic binds is shadowing the
      default (R4).
- [ ] **T.3** — no modal, ever. In a split tab and in a single-pane tab, run
      `F5`+digit, `F5`+letter, `F5`+`Escape`.
      PASS: at no point is a modal or overlay on screen.
      FAIL: any overlay, or anything that must be dismissed (epic I3).
- [ ] **E.5** — colorscheme and cursor. Open a file with the colorscheme
      live and look at all six defined highlights (M-12: the acceptance
      criterion said five, the spec defines six).
      PASS: all six render correctly under the base16 theme, and the cursor
      is visible against every one of them — blue in normal, green and thin
      in insert, magenta in visual, a red underline in replace.
      FAIL: any highlight invisible, or the cursor lost against one of them.
- [ ] **E.5** — the background is inherited, not painted (PRD acceptance 1).
      With the editor open, change the terminal's background live.
      PASS: the editor's background is the terminal's, before and after —
      tinty owns the palette and WezTerm is its first reader, so nothing
      below WezTerm holds a colour that can go stale.
      FAIL: a differently coloured field inside the editor, or the old
      background surviving the change — `ui.transparent` is not in effect.
- [ ] **E.5** — `tinty apply` a different base16 scheme with the editor open
      (PRD acceptance 4, and R7's boundary).
      PASS: the background follows the terminal within a reload, and the
      syntax colours do NOT move. Both halves are PASS — the static syntax
      palette is the specified boundary, not a bug.
      FAIL: the background lagging the terminal, or the syntax colours
      changing — the latter means the live-follow selector was switched on
      without a PRD behind it.
- [ ] **C.2** — fresh-directory end-to-end. In a new scratch directory run
      `capsule`.
      PASS: the image builds (first run only), a zsh prompt at `/workspace`,
      `ls` shows the directory's contents. Run it again — back at the prompt
      in well under a second, no build output.
      FAIL: any rebuild on the second run, or landing anywhere but
      `/workspace`.
- [ ] **C.2** — binding and CLI are one path. Remove the scratch capsule,
      press `Ctrl+Shift+D` in a pane cd'd to the directory, `docker inspect`
      the container (Name, Image, Mounts, Labels) to a file; remove it, run
      `capsule` by hand from an unrelated cwd with the path argument, inspect
      again.
      PASS: the diff of the two inspects is empty.
      FAIL: any field differs.
- [ ] **C.2** — `Ctrl+Shift+B` recreates. Note the container id, press it.
      PASS: an image rebuild runs, the new container id differs, the shell
      lands at `/workspace`.
      FAIL: the old container id survives, or no rebuild.
- [ ] **T.8** — font zoom recentres. Press the font-zoom keys up and down a
      few steps, waiting one `status_update_interval` (5 s) after each.
      PASS: no edge gap wider than one cell on any side.
      FAIL: a growing band on the right or the bottom — `update-status` is
      not reaching `center_grid`, and it is the only trigger interactive
      zoom fires.
- [ ] **T.8** — an overlay changes nothing. Open the debug overlay
      (`Ctrl+Shift+L`) and close it again.
      PASS: the padding is unchanged and `wezterm` logs no Lua error.
      FAIL: the grid jumps, or the log carries an error — the tab was
      reached through the active pane, which is detached under an overlay
      (R2).
- [ ] **T.8** — no flicker at the tick. Sit idle for at least four ticks
      (≥20 s) and watch the edges.
      PASS: the grid edges do not move; no column or row appears and
      disappears.
      FAIL: a column or row breathing once per tick — the total gap was not
      floored before halving (R5), or the idempotency guard is missing (R6).
- [ ] **T.8** — no ratchet. Note the edge gaps, zoom the font up three
      steps, back down three, wait a tick.
      PASS: the gaps are exactly what they were before the round trip.
      FAIL: the grid has crept smaller — the padding folded the previous
      padding back in (R8).
- [ ] **T.8** — a denser monitor recentres. Drag the window to a monitor of
      a different pixel density and wait a tick.
      PASS: recentred, with no restart.
      FAIL: stale padding until WezTerm is restarted — `window-resized` is
      not wired (R7).
- [ ] **E.9** — the picker paints. Press `<leader>ff` in a real window and
      type a few characters.
      PASS: prompt, result rows and preview all render; the best match sits
      at the bottom next to the prompt; the list reorders as you type.
      FAIL: an empty or garbled frame, a preview that never fills, or
      results that do not reorder — the headless gate proves the state, not
      the paint.
- [ ] **E.9** — a mark is visible before you commit it. In the picker press
      `<Tab>` three times, look, then press `<CR>`.
      PASS: each of the three rows carries a visible mark while the picker
      is still open, and the quickfix window lists exactly those three.
      FAIL: no visible mark on a marked row — the flow works headless but
      is unusable blind.
- [ ] **E.8** — a cold machine really installs the parsers. In a scratch XDG
      root with no parser store, on a network, with `tree-sitter` on PATH,
      open a `.nu` file and wait for the install to finish; quit and reopen
      it.
      PASS: sixteen `.so` files in `<root>/.local/share/nvim/site/parser`,
      and the reopened file is coloured.
      FAIL: an empty parser store, or `:messages` carrying `Error during
      "tree-sitter build"` — the toolchain, not the config.
      (Automated only offline: `tests/nvim-treesitter.sh --cold` pins the
      no-network shape. This row is the only place the real install is
      exercised, because it needs the network and minutes of compiling.)
- [ ] **E.8** — the toolchain is actually installed. Run `command -v
      tree-sitter` and `command -v curl` on a machine provisioned only by
      `install.sh`.
      PASS: both resolve.
      FAIL: `tree-sitter` missing — then R2 installs nothing on a fresh
      machine and every failure is one `:messages` line while Neovim still
      exits 0. It is NOT in the required package set
      (`05-platform/02-package-provisioning/packages-installer` R7), so this
      is expected to fail until that correction lands. Not gated: a gate
      asserting it would be red on a correctly provisioned machine.
- [ ] **E.8** — the colours actually paint. Open a `.nu` and a `.rs` file in
      the GUI and switch scheme with `tinty apply`.
      PASS: multi-coloured syntax in both, and it re-tints with the scheme.
      FAIL: one flat colour — the highlighter is attached (the gate proves
      that) but nothing is painting, or the palette is not reaching it.
- [ ] **E.8** — `=` re-indents in a real session. With the config's own
      `smartindent` on, flatten a Lua block and a TOML array to column 0 and
      press `=` over each.
      PASS: both re-indent correctly.
      FAIL: either left flat, or indented to the wrong depth.
      (The gate's probe turns smartindent off because PRD acceptance 4 names
      that isolation. Measured 2026-08-23: smartindent does not mask the
      discriminator — nvim's own `GetLuaIndent()` does, giving byte-identical
      output on a nested Lua block whether smartindent is on or off, which is
      why the gate's fixture uses a method chain. This row is the on-config
      half.)
- [ ] **E.4** — the yank flash is visible. In a real WezTerm session open
      any file, press `yy`, then `yiw` on a word.
      PASS: the yanked region briefly takes the `IncSearch` colour and
      clears itself after about a sixth of a second, with the text still
      readable while it is highlighted; and no save prints a hit-enter
      prompt — `keeppatterns %s/\s\+$//e` reports `3 substitutions on 3
      lines` before the write message on every affected save (measured), and
      at `cmdheight = 1` whether that pair needs a keypress is the half
      headless cannot settle.
      FAIL: no visible change — `IncSearch` resolves to something
      indistinguishable from normal text under the base16 palette — or a
      highlight that never clears, or a `Press ENTER` prompt on save.
      (Headless proves the extmark is set and expires:
      `bash tests/nvim-autocmds.sh --headless`. Only an eye settles whether
      the colour reads and whether the message pair overflows the cmdline.)
- [ ] **E.10** — the listing paints, icons included. Press `<leader>e` in a
      real window.
      PASS: one line per entry, directories marked, and every file icon a
      real glyph.
      FAIL: tofu boxes or blank gaps where the icons belong — the headless
      gate proves a non-ASCII glyph is in the buffer text, not that the
      font can draw it.
- [ ] **E.10** — the rename prompt paints. Change a filename on its line,
      press `:w`, read the float, then press `y`.
      PASS: a bordered float over the buffer showing `MOVE <old> -> <new>`
      and `[Y]es  [N]o`; `y` closes it and the listing shows the new name.
      FAIL: a float you cannot read, or one that renders off screen — the
      headless gate reads its lines out of the buffer and never sees where
      it is drawn.
