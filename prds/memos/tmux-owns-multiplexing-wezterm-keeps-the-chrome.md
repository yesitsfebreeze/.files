---
memo: tmux-owns-multiplexing-wezterm-keeps-the-chrome
kind: decision
status: decided
subject: tmux takes windows, panes, addressing and scrollback so the config survives a restart and follows an ssh; WezTerm keeps only what is local to this machine, and invariants I1 and I2 are reversed to allow it
date: 2026-08-29
prds:
  - 02-terminal
  - 02-terminal/01-appearance
  - 02-terminal/02-startup-layout
  - 02-terminal/03-f5-jump-mode
  - 02-terminal/04-copy-mode
  - 02-terminal/05-tab-content-state
  - 02-terminal/06-launchd-path
  - 04-shell/09-theme-switcher
  - 06-help/04-drift-check
---

# tmux-owns-multiplexing-wezterm-keeps-the-chrome — the multiplexer is portable, the chrome is not

## Decision

tmux owns windows, panes, addressing, splits, scrollback and the status bar.
WezTerm keeps font, grid centering, window opacity and blur, the launchd PATH
seeding, and the capsule `SendString` keys — everything that is true of *this
machine* and false of an ssh session.

The two invariants that forbade this are reversed, both on the record:

- **[`02-terminal`](../02-terminal/prd.md) I1** — "the self-healing nine-tab
  floor owns tabs and panes … there is no second multiplexer" — is withdrawn.
  tmux is now the *first* multiplexer, and WezTerm binds no tab or pane key
  at all. There is still exactly one, which is what I1 was protecting.
- **I2** — "tinty owns the palette; WezTerm is its first reader" — keeps its
  first clause and loses its second. tinty still owns the palette. Its first
  reader becomes the attached terminal, over OSC 4/10/11, plus a file tmux
  sources for its own status colours. `~/.config/wezterm/colors.lua` and the
  `dofile`-never-`require` rule go with it.

The three keys are `F4` split (arrow gives the direction, new pane inherits
the active pane's cwd), `F5` switch (digit selects a window, letter selects a
pane), `F6` theme toggle — all three bound in tmux, none in WezTerm.

## Why

Two forces, and the second is the larger one.

**Sessions must survive the terminal.** WezTerm's local domain dies with the
GUI process. Nine tabs of work, each with a cwd and a running program, are
reconstructed by hand after every restart. `new-session -A -s main` makes the
attach idempotent: the session outlives the window, and one terminal is
enough because reattaching is the same gesture as opening.

**The config is worth more when it is not WezTerm's.** `wezterm.lua` is 1297
lines that exactly one program can read. The same nine windows, the same two
key tables and the same status bar are roughly 80 lines of `tmux.conf` that
run under Ghostty, iTerm2, Terminal.app, the Linux console, or a host reached
by ssh ten minutes ago. That is not a saving in lines, it is a change in what
the artifact *is*: the part of the environment worth carrying stops being
tied to the emulator that happened to render it.

The move also deletes the most expensive machinery on the board rather than
porting it. `reconcile_tabs` and its slot ledger — about 320 lines, its own
214-line test, and the whole reason
[`02-startup-layout`](../02-terminal/02-startup-layout/prd.md) is rated C 10 —
exist because WezTerm tab indices shift when a tab closes, so a digit is not
a stable address without being made one. tmux window indices are stable
natively under `renumber-windows off`; the mechanism has no job. The
occupied/empty tint that
[`05-tab-content-state`](../02-terminal/05-tab-content-state/prd.md) builds
by peeking at pane foreground processes through the mux API (~120 lines, a
543-line test) is `#{pane_current_command}` in a format string.

One capability arrives that WezTerm refused. The pane half of `F5` was
dropped on 2026-08-21 (Q2) because **I3** forbids `PaneSelect` — a bound key
never reaches the modal, an unbound one is eaten by it — so letter addressing
meant self-painting an overlay. All 26 letters are bound as bare cancels
today, holding the space for an action that could not be built. In tmux it is
nine `select-pane -t` binds. I3 itself stands: it is a fact about WezTerm's
key dispatch and stays true whether or not anything depends on it.

## Alternatives considered

**Bind F4/F5/F6 in WezTerm and keep everything as it is.** This was costed
first and is genuinely cheap — about 2h. `SplitPane` with
`domain = 'CurrentPaneDomain'` inherits the cwd already, because
`config.nu` sets `osc7: true`; F5 and F6 are built and passing. It loses on
both forces at once: nothing survives a restart, nothing follows an ssh, and
pane letters stay unbuildable behind I3. The keys were never the point — they
were how the point got noticed.

**tmux for persistence only, WezTerm keeping tabs and the tab bar.** Lost on
coherence. Two multiplexers stacked is the arrangement I1 was written against
and it was right about that: a digit would address a WezTerm tab and a letter
a tmux pane, scrollback would be split between two scrollers, and copy mode
would depend on which layer had focus.

**Keep the palette on `colors.lua` and accept that themes only work locally.**
Lost on the claim it would falsify. `config.colors` is WezTerm-wide, which is
exactly why one `tinty apply` retints every window at once — but you cannot
rewrite a remote's or a third-party emulator's config file, so F6 would be a
key that works at this desk and silently does nothing anywhere else. A
portable config with a local-only theme toggle is not portable, it is
portable-shaped.

**Zellij instead of tmux.** Not seriously weighed, and that is the finding
rather than a comparison: tmux is on every machine worth reaching, its
terminfo story is the one every other tool already accommodates, and the
decisive property here is ubiquity on the far end, which is precisely where a
newer multiplexer is weakest.

## Consequences

- Four `done` children of a `done` epic stop describing what ships.
  [`02-startup-layout`](../02-terminal/02-startup-layout/prd.md) and
  [`05-tab-content-state`](../02-terminal/05-tab-content-state/prd.md) are
  superseded outright;
  [`03-f5-jump-mode`](../02-terminal/03-f5-jump-mode/prd.md) and
  [`04-copy-mode`](../02-terminal/04-copy-mode/prd.md) survive as behaviour
  and are re-implemented on a different mechanism. They are amended in place,
  not re-specced: the epic is not invalid the way it was in the `w0-2` round,
  it narrows.
- Three WezTerm tests are retired (`wezterm-startup-layout.sh`,
  `wezterm-tab-content-state.sh`, `wezterm-f5-tab-select.sh` — 1058 lines) and
  the `default_prog` assertions inside the 1104-line
  `wezterm-launchd-path.sh` change. Testing gets cheaper, not dearer: a
  headless `tmux -L test -f <conf> new-session -d` plus `list-keys -T jump`
  reads a real binding table, where the WezTerm equivalent needs the
  `config_builder()` probe discipline of **I5**.
- **I5 survives untouched and still binds** whatever stays in `wezterm.lua`.
  A shrinking file does not make an invalid config field valid, and
  `gates/wezterm-config-fields.sh` keeps running.
- `help` gains no fifth `--mode`. tmux entries stay on the existing `terminal`
  surface — from the user's seat it *is* the terminal — which leaves the
  closed four-surface list, and the `--mode tmux` exits-1 acceptance asserted
  in `06-help/01-content-model`, `02-help-command` and `05-agent-interface`,
  entirely alone.
- `home/dot_config/nushell/help/terminal.nuon` carries 42 entries, about 20 of
  them verified by `kind: "wezterm-key"` through `wezterm show-keys --lua`.
  Those become `kind: "tmux-key"`, which no reader resolves yet:
  [`06-help/04-drift-check`](../06-help/04-drift-check/prd.md) owes the
  resolver, against `tmux -L … list-keys`. That node is `open` and parse-
  erroring today, so this adds a requirement to unbuilt work rather than
  breaking built work — but until it lands, those entries are documented and
  unverified, and no box may claim otherwise.
- Clipboard moves to OSC 52 (`set-clipboard on`), because `pbcopy` is reachable
  only from this machine. Terminal.app does not honour OSC 52; on that
  emulator copy will fail, and it fails silently. Local `pbcopy` stays as the
  fallback where the pane is not remote.
- tmux is now a hard dependency on the far end, and `tmux-256color` terminfo is
  absent on plenty of minimal hosts. The conf needs a `screen-256color`
  fallback or the portability this memo is *for* delivers a colourless,
  undercurl-free session on exactly the machine it was meant to improve.
- This does **not** give persistence across a reboot. The tmux server dies with
  the machine; `new-session -A` restores nothing it did not keep. Surviving a
  reboot needs tmux-resurrect and continuum, or a launchd agent, and that is
  deliberately left to a later call.
- Two documents outside `prds/` assert the reversed invariants and go stale the
  moment this lands: `AGENTS.md`'s scope decisions ("the terminal owns the
  palette" correction, and the one-container-tool paragraph's neighbours), and
  `prds/README.md`'s exclusion list, where the 2026-08-20 shell-side
  multiplexer carries `DO NOT PORT`. That exclusion is not reinstated — the
  thing deleted then was a *second* multiplexer under a WezTerm that already
  was one. It stays excluded, for a reason that now needs restating rather
  than repeating.
