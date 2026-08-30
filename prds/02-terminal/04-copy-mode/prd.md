---
state: done
claim:
priority: 16
est: 2.5h
task: T.4
mode: afk
needs:
  - 02-terminal/03-f5-jump-mode
  - 06-help/01-content-model
verify: "bash tests/tmux-copy-and-clipboard.sh"  # AMENDED 2026-08-30: the c-cycle moved to tmux copy-mode-vi
---

# Copy mode, paste, and the loose bindings

Parent: [Terminal epic](../prd.md) · C 4 · U 9 · source: Copy mode:
`Ctrl+Shift+X` plus a single-key `c` cycle

This node merges five inventory entries and carries the dominant entry's
numbers, listing each source with its own: *Copy mode: `Ctrl+Shift+X` plus a
single-key `c` cycle* **C 4 / U 9** (dominant) · *`Ctrl+V` native paste*
C 1 / U 8 · *`Ctrl+C` copy-or-SIGINT* C 3 / U 9 · *`StartWindowDrag` on
`Ctrl+Alt+Super`+left-drag* C 1 / U 7 · *`Ctrl`+left-click opens the link
under the cursor* C 1 / U 7 · *OSC 1337 `SetUserVar` triggers* C 3 / U 7. All
are in
[`capabilities-terminal.md`](../../../docs/capabilities-terminal.md). The
header this replaced read `C2 • U3 • V3`, which is invented — no inventory
entry carries it.

Purpose: get text out of the terminal and into it. Copy mode as WezTerm
actually implements it, plus the four bindings the audit found uncovered:
paste, copy-or-interrupt, the window drag handle, and the link opener.

## Status after the tmux cutover

**AMENDED 2026-08-30: the gesture survives on a different mechanism**
([`07-multiplexer/05-copy-and-clipboard`](../../07-multiplexer/05-copy-and-clipboard/prd.md)).
`Ctrl+Shift+X` enters copy mode with the selection cleared, `c` cycles
cell → word → line per pane, `y` copies — now as `copy-mode-vi` bindings
and an `after-copy-mode` hook, with the clipboard sink chosen once at
parse time (`pbcopy` where it exists, OSC 52 where it does not, which is
the half that follows an ssh). `tests/wezterm-copy-mode.sh` is retired.

**Mouse selection stays WezTerm's** — tmux's `mouse` option is
deliberately off — which is what keeps the `Ctrl+C`
copy-or-interrupt binding in `wezterm.lua` meaningful.

Filed by the epic and still true: this node was `done` with every
requirement box unticked. That is a separate correction and this
amendment does not close it.

## Requirements

- [ ] **R1** — **Entry from a clean state.** `Ctrl+Shift+X` clears any stale
      selection, clears the per-pane toggle flag, and then
      `ActivateCopyMode`. Resetting **on entry** is what makes an exit by
      `q`, `Esc` or `y` unable to leave the toggle stale.
- [ ] **R2** — **The default table is extended, never replaced.** All **54**
      builtin copy-mode motions survive, and exactly one binding is added.
- [ ] **R3** — **No search is promised, because copy mode has none.** The
      inventory said the "55 builtin motions and searches" survive. Measured
      against `wezterm show-keys --lua` on `20240203-110809-5046fc22`: the
      effective `copy_mode` table has **55 rows in total, one of which is
      this config's own `c`** — so 54 are builtin, not 55 — and it contains
      **no search facility whatsoever**: no `/`, and none of `NextMatch`,
      `PriorMatch`, `ClearPattern` or `CycleMatchType` either. Every one of
      those lives in a **separate 10-row `search_mode` table**, reachable
      only from normal mode via WezTerm's default `Ctrl+Shift+F` / `Cmd+F` —
      bindings this config neither sets nor shadows. Requirements say "54
      builtin **motions**", and the manual entry sends a user looking for
      search to `Ctrl+Shift+F` rather than into copy mode. Re-speccing from
      the inventory's old line would have reproduced the `02-terminal`
      failure exactly, which is why this node's parent routed it here; the
      same correction is landed at source in
      [`capabilities-terminal.md`](../../../docs/capabilities-terminal.md),
      so the two are one correction in two places.
- [ ] **R4** — **The single-key `c` cycle, tracked per pane id.** First press
      anchors a `Cell` selection at the cursor; second press
      `CopyTo("ClipboardAndPrimarySelection")` followed by
      `CopyMode("Close")`. Tracked by **pane id** rather than by reading the
      selection text back, because a selection that begins over blank cells
      reads as empty and would desync the toggle.
- [ ] **R5** — **The shell-driven entry, and only that one.** A nushell
      command prints an OSC 1337 `SetUserVar` named `copymode`; WezTerm
      parses it off the pty and enters copy mode, ignoring the value. That is
      how a shell command reaches a GUI-only mode. The sibling user-var —
      the live background-transparency toggle — is **out**: open decision
      5(b) drops it, so the handler answers to one name, not two. Say so
      explicitly, or a lane porting the handler carries the dropped feature
      back in with it.
- [ ] **R6** — **`Ctrl+V` is a bracketed paste.** `PasteFrom("Clipboard")`,
      with no subprocess: it is how text reaches both the shell and a running
      program (Claude, nvim), and it is what makes clipboard-based dictation
      land in the terminal.
- [ ] **R7** — **`Ctrl+C` copies or interrupts, never both.** If
      `window:get_selection_text_for_pane` returns a non-empty selection,
      copy it to `ClipboardAndPrimarySelection` and clear the selection;
      **otherwise** `SendKey{ key = "c", mods = "CTRL" }`, so the key keeps
      its terminal meaning. The fallthrough is the requirement: it gives the
      platform-native copy shortcut without ever costing an interrupt.
- [ ] **R8** — **The two mouse bindings, with their reasons.**
      `Ctrl+Alt+Super`+left-drag → `StartWindowDrag`, which is the **only**
      handle for repositioning the OS window, because
      `window_decorations = "RESIZE"` leaves no titlebar; the deliberately
      heavy modifier combo is what keeps it from stealing ordinary clicks and
      selection drags. `Ctrl`+left-click → `OpenLinkAtMouseCursor` with
      `mouse_reporting = true`, which is what keeps it working while an
      application is capturing the mouse (DECSET 1002/1006) — without the
      flag WezTerm forwards the click to the application and nobody opens the
      URL. Plain clicks still reach the application. The live comment
      justifies the flag by naming a multiplexer that has since been deleted;
      the flag still earns its place, because nvim and other TUIs capture the
      mouse the same way.

## Acceptance
- [ ] `Ctrl+Shift+X` enters copy mode with no selection carried in from
      before, and `h`/`j`/`k`/`l`, `w`/`b`, `g`/`G` and the other builtin
      motions all still work.
- [ ] `c` then `c` copies the anchored selection to both the clipboard and
      the primary selection and closes copy mode; a selection begun over
      blank cells does not desync the toggle.
- [ ] Pressing `/` inside copy mode does nothing, and `Ctrl+Shift+F` from
      normal mode opens the search prompt — the manual entry says exactly
      this.
- [ ] The nushell command that prints the `copymode` user-var drops the
      focused pane into copy mode; no other user-var name is handled.
- [ ] `Ctrl+V` pastes into a shell prompt and into nvim's insert mode as a
      bracketed paste.
- [ ] `Ctrl+C` with a selection copies and clears it; `Ctrl+C` with no
      selection interrupts the foreground process.
- [ ] `Ctrl+Alt+Super`+left-drag moves the OS window; an ordinary left-drag
      still selects text.
- [ ] `Ctrl`+left-click opens a URL while a full-screen TUI is capturing the
      mouse.

## Out of scope
- Grid centering, which the `T.4` plan row bundles with this node but which
  Q3 gave its own node,
  [`07-grid-centering`](../07-grid-centering/prd.md).
- The background-transparency user-var and the wallpaper pipeline, both
  refused in the epic's non-goals.
- Anything this node's Requirements do not name. The epic
  ([`../prd.md`](../prd.md)) owns the shared invariants.

## Deviations

Recorded on the `claimed → done` transition, 2026-08-22, because all three
outlive the run and two are defects in the specs rather than in the code.

- **spec01 acceptance box 6 is left `[ ]` and cannot be met as written.** It
  demands `opacity` appear on no non-comment line of `wezterm.lua`. The single
  non-comment hit is `config.window_background_opacity = 0.95`
  (`wezterm.lua:396`), which is [`01-appearance`](../01-appearance/prd.md) R7's
  own field — verified independently by the orchestrator. The clause's *intent*
  (no `opacity` user-var arm survives the wallpaper-opacity decision) is met and
  is asserted by the gate in the stronger form: the only non-comment `opacity`
  is that one field, so a revived user-var still fails it. The spec wording is
  the defect; the implementation is correct. Because a box is open, this run is
  not clean and carries no `actual:`.
- **spec02's footprint was incomplete.** `tests/nushell-core.sh` needed a
  seventh `cp` line in `mk_machine`, which stages every module `config.nu`
  sources; without it the hermetic stage fails 27 checks on a parse error. The
  implementer added it in the declared pattern and disclosed it. **This is a
  trap for every future node that adds a nushell module** — the module and its
  staging line are one change, not two.
- **`also: []` is gate-illegal** (`bad-string-list` rejects an empty list), so
  R8's two mouse entries landed as a mutual cross-link, which is what they are.

One correction the implementer's own review caught: spec04 claimed the
`Ctrl+Shift+X` why-review row stood, but that digest keys on the `use`/`why`
pair and editing `use` staled it. Re-digested with the reading recorded.
