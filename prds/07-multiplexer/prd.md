---
state: open        # open|analyzing|refine|question|specced|claimed|blocked|done|failed
origin: requested  # requested = the user asked | derived = the board found it
# from:            # derived only — the PRD whose work surfaced this one
priority: 20        # higher first
complexity: 0      # analyst, at spec time — 1-100. THE WEIGHT the board schedules by
blast-radius:      # analyst, at spec time — high|mid|low. What breaks if this is wrong
repo:              # the sub-repo the code lands in; delete if n/a
# workflow:        # OPTIONAL — how this kind of job is done: a slug in
#                  #   prds/workflows/. @references/workflow.md.
#                  #   Absent = the brief alone, as before workflows
time:              # OPTIONAL. See @references/parts/order.md
  est:             # the weight, only when complexity is absent. Not a duration
  actual:          # a record. Nothing reads it
  # claim: <worker> <started>   # orchestrator-only, present while a worker holds this PRD
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

# Epic: Multiplexer (tmux)

Parent: the board root · net-new · C 7 · U 9

Purpose: the part of this environment worth carrying stops being tied to the
emulator that happens to render it. tmux owns windows, panes, addressing,
splits, scrollback and the status bar; WezTerm keeps only what is true of this
machine. Governed by
[`tmux-owns-multiplexing-wezterm-keeps-the-chrome`](../memos/tmux-owns-multiplexing-wezterm-keeps-the-chrome.md),
which reverses [`02-terminal`](../02-terminal/prd.md) **I1** and the second
clause of **I2** and carries the argument. Do not re-take that decision here.

**When this is done:** `wezterm` (or Ghostty, or Terminal.app, or an ssh into
a box provisioned an hour ago) comes up attached to one tmux session called
`main`. `F5` then a digit is a window; `F5` then a letter is a pane, and the
pane borders print the letters so the label always matches the key. `F4` then
an arrow splits the view in that direction, the new pane starting in the
active pane's cwd. `F6` toggles the theme, and it works on any terminal that
honours OSC 11 rather than only on this desk. The session survives quitting
the terminal, and — through resurrect and continuum — a reboot, coming back
with its layout, its cwds and its editors' buffers. WezTerm binds no tab or
pane key at all and `wezterm.lua` is roughly 470 lines shorter.

## The split this epic exists to make

- **Portable layer (this epic)** — windows, panes, addressing, splits, copy
  and scrollback, the status bar, palette delivery, persistence. It follows
  you.
- **Local chrome ([`02-terminal`](../02-terminal/prd.md))** — font, grid
  centering, `window_background_opacity` and blur, the launchd PATH seeding,
  the capsule `SendString` keys. It stays, correctly, and stops pretending to
  be architecture.

## Constraints

- **Invariant I3 stands.** WezTerm's `PaneSelect` remains forbidden and the
  reason remains true — it is a fact about WezTerm's key dispatch, not a
  dependency of anything here. What changes is that pane-letter addressing no
  longer needs it, because tmux does it natively. The 26 letters bound as bare
  cancels in `jump_mode` were holding this space.
- **Invariant I5 stands and still binds whatever stays in `wezterm.lua`.** A
  shrinking file does not make an invalid config field valid;
  `gates/wezterm-config-fields.sh` keeps running.
- **`help` gains no fifth `--mode`.** tmux entries stay on the existing
  `terminal` surface — from the user's seat it *is* the terminal — which
  leaves the closed four-surface list and the `--mode tmux` exits-1 acceptance
  in `06-help/01-content-model`, `02-help-command` and `05-agent-interface`
  entirely alone.
- **A `tmux-key` verify kind does not exist yet.** Entries that name a tmux
  binding carry `kind: "tmux-key"` and no reader resolves it;
  [`06-help/04-drift-check`](../06-help/04-drift-check/prd.md) — `open` and
  parse-erroring today — owes the resolver against `tmux -L … list-keys`.
  Until it lands those entries are documented and unverified, and no box may
  claim otherwise.
- **`tmux-256color` terminfo is absent on plenty of minimal hosts.** Every
  conf needs a `screen-256color` fallback, or the portability this epic is
  *for* delivers a colourless, undercurl-free session on exactly the machine
  it was meant to improve.
- **Preserve the hard-won why.** The reasons carried into `02-terminal` were
  expensive: OSC 133 double-marking causes phantom prompt lines (`config.nu`
  keeps `osc133: false` and `osc7: true`, and F4's cwd inheritance depends on
  the latter); `use_kitty_protocol` leaks an escape through the WezTerm pty;
  an unrotated LSP log once hit 17 GB. A constraint that moves to tmux moves
  with its reason attached.
- **tmux is now a hard dependency on the far end.** That is the one thing
  that must be installed for any of this to follow you, and it is the reason
  tmux was chosen over a newer multiplexer.

## Non-goals

- **No second multiplexer.** WezTerm binds nothing that addresses a tab or a
  pane after the cutover. The old **I1** was right about the hazard and wrong
  only about which program should be the one — two live key schemes is the
  arrangement it existed to prevent.
- **No `--mode tmux` in `help`.** See the constraint above.
- **No session-per-project.** Settled at Q1: one session, `main`. A picker
  over sessions is a later question with real usage behind it, not this epic's.
- **No wallpaper, opacity toggle, or background cycling walks back in.**
  Refused by [`decisions/wallpaper-opacity`](../00-delivery/decisions/wallpaper-opacity/prd.md)
  and finding T-11; a rebuild in tmux form is still a rebuild.

## Pointers

- `home/dot_config/wezterm/wezterm.lua` — 1297 lines. Roughly 470 come out:
  the `reconcile_tabs` floor (~320), the occupied/empty tint (~120), the F5
  table (~50), and the derived tab bar and clock.
- `home/dot_config/tinted-theming/tinty/config.toml` — the hook already
  sources tinted-shell (which emits OSC) *and* runs `wezterm-colors.sh`. Its
  own comment says the OSC half "only ever reach[es] the ONE pane the hook ran
  in", which is exactly why `colors.lua` exists. Under tmux there is one
  client terminal, so that limitation disappears rather than needing solving.
- `home/dot_config/nushell/help/terminal.nuon` — 42 entries, about 20 verified
  by `kind: "wezterm-key"` through `wezterm show-keys --lua`.
- `tests/wezterm-startup-layout.sh`, `wezterm-tab-content-state.sh`,
  `wezterm-f5-tab-select.sh` (1058 lines) retire; `wezterm-launchd-path.sh`
  (1104) keeps everything but its `default_prog` assertions.
- Testing gets cheaper, not dearer: `tmux -L test -f <conf> new-session -d`
  plus `list-keys -T jump` reads a real binding table, where the WezTerm
  equivalent needs the `config_builder()` probe discipline of **I5**.
- `docs/capabilities-terminal.md` is ground truth for what the live config
  does. The entries this epic supersedes need pointing at it, per the
  split-entry rating rule in `AGENTS.md`.

## Consequences the tree must carry

Recorded here because they are cross-cutting and no single child owns them:

- `prds/README.md`'s tree, exclusion list and build order, and `AGENTS.md`'s
  scope decisions and epic table, all assert the reversed invariants. The
  2026-08-20 shell-side multiplexer stays excluded — what was deleted then was
  a *second* multiplexer under a WezTerm that already was one — but for a
  reason that now needs restating rather than repeating.
- `02-terminal` returns from `done`. Two of its children are superseded
  outright (`02-startup-layout`, `05-tab-content-state`); two survive as
  behaviour on a different mechanism (`03-f5-jump-mode`, `04-copy-mode`); two
  are amended (`01-appearance`, `06-launchd-path`); one is untouched
  (`07-grid-centering`). They are amended in place, not re-specced: the epic
  is not invalid the way it was in the `w0-2` round, it narrows.
- **Filed in passing, not this epic's to fix:**
  `prds/02-terminal/04-copy-mode/prd.md` is `state: done` with every one of
  its requirement boxes still `- [ ]`. That is either a false `done` or an
  unrecorded run, and it wants a correction of its own.

## Questions (round 1, answered)

### Q1: Session model

A single tmux session means a second WezTerm window mirrors the first — same
windows, same focus. Grouped sessions share the window set but let each
terminal sit on a different window. Which?

1. **One session, `main`** — `new-session -A -s main`; every attach lands on
   the same session and a second window mirrors the first exactly (recommended)
2. **Grouped sessions** — `new-session -t main` per attach, sharing windows
   but keeping an independent current-window
3. **Session per project** — sessions named by project, nine windows each,
   television switching between them

### Q2: The nine-window floor

tmux indices are stable, so the reconciler dies — but killing window 4 leaves
a hole and `F5 4` then does nothing. How is a digit kept a valid address?

1. **Lazy — create on press** — `F5 <digit>` selects the window if it exists
   and creates it at that index if not; startup is one window, not nine
   (recommended)
2. **Hard floor of nine** — seed nine and respawn any that is killed; today's
   self-healing floor reproduced, nine shells always resident
3. **Nine at start, holes allowed** — seed nine, and a killed digit is dead
   until you make a window there

### Q3: Pane letters

tmux renumbers panes when one is killed, so a letter bound to index 2 can point
at different content after a close. How do letters address panes?

1. **Index, with border labels** — `a`–`i` map to pane index 1–9 and
   `pane-border-format` prints the letter, so the label always matches the key
   (recommended)
2. **Stable pane ids** — letters map to `%N` ids through a per-window lookup,
   so a letter keeps its pane for life
3. **Spatial order** — letters address panes left-to-right, top-to-bottom by
   screen position, computed at press time

### Q4: Palette delivery

`tinty apply` writes `colors.lua` and WezTerm retints every pane at once — a
path that does not exist on a remote or another emulator. How is the palette
delivered?

1. **OSC plus a tmux file** — the hook emits OSC 4/10/11 through tmux to the
   attached terminal and writes `~/.config/tmux/colors.conf`, then
   `source-file`s it; `colors.lua` and the reload watch are deleted
   (recommended)
2. **Keep `colors.lua` too** — write both, so WezTerm retints from the file
   here and OSC carries it elsewhere
3. **tmux-only colours** — retint tmux's own surfaces and leave the outer
   terminal's ANSI palette as launched

### Q5: The status bar

WezTerm's bar prints the digit and nothing else, tints occupied vs empty, and
holds an unconditional top-right clock — a shape arrived at by removing things
(T-9: the legend existed and was cut as noise). Reproduce it, or change it?

1. **Faithful port** — digit-only labels, occupied/empty tint from
   `#{pane_current_command}`, clock top right (recommended)
2. **Port plus session context** — the same, plus a left segment and the
   active pane's cwd, which one-terminal working hides from you
3. **Minimal** — window digits only; no clock, no tint, no left segment

### Q6: Copy mode

`Ctrl+Shift+X` plus the per-pane `c` cycle is a WezTerm gesture built on its 54
builtin motions; tmux's `copy-mode-vi` ships its own motions and `v`/`V`/`C-v`
selection. Which gesture survives?

1. **Port the c-cycle** — `Ctrl+Shift+X` enters `copy-mode-vi` with the
   selection cleared, `c` cycles cell→word→line per pane, `y` copies
   (recommended)
2. **tmux-native vi** — adopt `v`/`V`/`C-v`/`y` as shipped, retire the c-cycle,
   rewrite the manual entries
3. **Mouse-first** — drag-select copies straight to the clipboard; keyboard
   copy mode stays as tmux ships it

### Q7: Reboot persistence

`new-session -A` survives the terminal quitting but not the machine
restarting — the server dies with it. How far does resurrection go?

1. **resurrect + continuum** — session, windows, cwds and declared programs
   come back after a reboot, autosaved every 15 minutes (recommended)
2. **Seed at login, no restore** — a launchd agent starts the server with the
   session seeded; nothing running is restored
3. **Attach only, defer** — `new-session -A -s main` and nothing more

### Q8: Rollout

The tmux layer and the WezTerm reduction can land together or apart, and apart
means two multiplexers for a while — the arrangement I1 was written against.
Which?

1. **Cutover in one node** — `default_prog` attaches tmux and the WezTerm mux
   code is deleted in the same change; no period where a digit means two
   things (recommended)
2. **Portable-first** — the conf lands and is proven over ssh into a capsule
   before WezTerm is touched
3. **Opt-in transition** — tmux by command while WezTerm keeps its tabs,
   deleted after a week of real use

### Q9: The status bar's left segment

Q1 settled a single session named `main`, so a session-name segment would be a
constant string. Once the config is portable, what actually varies is which
machine the pane is on. What goes on the left?

1. **Host and cwd** — hostname on the left, dimmed or blank when local; the
   active pane's cwd joins the clock on the right (recommended)
2. **Session and cwd as asked** — keep the session name, ready for a
   session-per-project future, reading `main` until then
3. **cwd only** — no left segment; nothing constant is drawn

### Q10: Nesting

`F4`/`F5`/`F6` are bound without a prefix, so the outer tmux eats them always.
ssh into a host running its own tmux and `F5` addresses your local windows —
the portability case biting itself. How is nesting handled?

1. **A toggle suspends the outer** — `F12` flips the outer key table off and
   marks it in the status bar; `F12` again takes it back (recommended)
2. **Double-tap forwards** — `F5 F5` sends a literal `F5` inward while a single
   `F5` stays local; no mode, at the cost of a timing-sensitive gesture
3. **Never nest** — ssh panes run a bare remote shell and the remote never runs
   tmux

### Q11: Plugin delivery

resurrect and continuum would be the first plugins in a repo with no plugin
manager, whose contract says prefer built-ins over plugins and whose
`install.sh` already does provisioning. How do they arrive?

1. **`install.sh` clones them** — cloned to a fixed path and `run-shell`d
   directly; no tpm, because tpm exists to install and update plugins and
   chezmoi plus `install.sh` already do that job here (recommended)
2. **tpm, managed by `install.sh`** — the conventional arrangement, one more
   layer, an update path nothing else in this repo uses
3. **Vendor into `home/`** — the plugins' scripts committed and deployed by
   chezmoi; nothing to clone, updates are a manual re-vendor

### Q12: What comes back

resurrect always restores layout and cwds, re-executes programs only from an
allowlist, and restoring an editor with its buffers is a separate opt-in. How much comes
back after a reboot?

1. **Layout, cwds, nvim sessions** — the default allowlist plus an nvim session
   strategy, at the cost of new work in the `done` `03-editor` epic
   (recommended)
2. **Layout and cwds only** — every pane a fresh shell in the right directory;
   nothing can be resurrected into a broken state
3. **Default allowlist as shipped** — nvim back but bare, no session, no
   strategy to maintain

### Q13: What writes `Session.vim`

resurrect runs `nvim -S Session.vim` if one exists in the pane's cwd, and
nothing writes one today. What writes it?

1. **An autocmd on exit** — `03-editor` writes `Session.vim` on `VimLeave`
   when the buffer list is non-trivial; no plugin, one file (recommended)
2. **A session plugin** — persistence.nvim or auto-session owns save and
   restore; more capable, and a new dependency in a `done` epic
3. **resurrect triggers `mksession`** — the save hook sends `:mksession!` to
   each live nvim, keeping the coupling entirely in tmux config

### Q14: A lazily created window's cwd, and where a copy lands

Two small ones. When `F5 <digit>` creates a missing window, where does it
start? And `pbcopy` exists only on this machine while OSC 52 works only on
terminals that honour it.

1. **cwd of the current pane, and pbcopy local / OSC 52 remote** — creation
   gestures agree with F4, and the copy binding picks by where the pane is
   (recommended)
2. **Home directory, and OSC 52 always** — a digit is a clean slate; one copy
   path everywhere, failing silently where it is ignored
3. **Last cwd that index had, and pbcopy always** — window 4 keeps being where
   window 4 was; remote panes reach pbcopy over a forwarding channel that does
   not exist yet

## Answers

**Q1** — One session, `main`. `new-session -A -s main`; every attach lands on
the same session, and a second WezTerm window mirrors the first exactly. One
terminal is the point, and the attach is idempotent.

**Q2** — Lazy, create on press. `F5 <digit>` selects the window if it exists
and creates it at that index if it does not. A digit is always a valid address,
nothing is respawned in the background, and startup is one window rather than
nine.

**Q3** — Index, with border labels. `a`–`i` map to pane index 1–9, and
`pane-border-format` prints the letter so the label always matches what the key
does, even right after a renumber.

**Q4** — OSC plus a tmux file. tinty's hook emits OSC 4/10/11 through tmux to
the attached terminal and writes `~/.config/tmux/colors.conf`, which it then
`source-file`s. `colors.lua` and the WezTerm reload watch are deleted; F6 works
on any terminal honouring OSC 11.

**Q5** — Port plus session context. The faithful bar, plus a left segment and
the active pane's cwd — the two things one-terminal working actually hides from
you. **Q9 narrows what the left segment holds.**

**Q6** — Port the c-cycle. `Ctrl+Shift+X` enters `copy-mode-vi` with the
selection cleared, `c` cycles cell→word→line per pane, `y` copies. The muscle
memory in `02-terminal/04-copy-mode` survives on a new mechanism.

**Q7** — resurrect + continuum. Session, windows, cwds and declared running
programs come back after a reboot, autosaved every 15 minutes.

**Q8** — Cutover in one node. `default_prog` attaches tmux and the WezTerm mux
code is deleted in the same change. One state, and no period where a digit
means two different things.

**Q9** — Host and cwd. The hostname on the left, dimmed or blank when local;
the active pane's cwd joins the clock on the right. Locally it reads almost
like today's bar; over ssh it tells you where you are.

**Q10** — Double-tap forwards. `F5 F5` sends a literal `F5` inward while a
single `F5` stays local. This falls out of the design already chosen: `F5`
pushes a key table, so `bind -T jump F5 send-keys F5` is the whole mechanism,
and the same for `F4`. **F6 is not forwarded, and needs no question:** the
palette belongs to the outermost terminal, so an inward F6 could only retint a
session that does not own the colours.

**Q11** — `install.sh` clones them. `05-platform/01-deploy-mechanism` clones
the two repos to a fixed path and `tmux.conf` `run-shell`s each directly. No
tpm: it exists to install and update plugins, and chezmoi plus `install.sh`
already do that job here.

**Q12** — Layout, cwds and nvim sessions. The editor returns with its buffers.
This pulls the `done` `03-editor` epic back in; that cost was named when the
answer was given.

**Q13** — A session plugin. persistence.nvim or auto-session owns save and
restore, with resurrect just re-launching nvim. **Which of the two is not
settled** — it is the one sub-decision this drill left to the analyst, who
should recommend in the spec rather than assume. persistence.nvim is the
smaller and lazy-loadable one; auto-session is branch-aware and brings a picker.

**Q14** — Home directory, and pbcopy local / OSC 52 remote. A lazily created
window starts at `~`, so a digit is a clean slate and never carries context you
did not mean to bring — deliberately *not* the same rule as an F4 split, which
does inherit. The copy binding checks whether the pane is on this machine and
picks its sink accordingly.

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

## Children

| child | contract | needs |
|---|---|---|
| `01-session-and-windows` | The tmux base: one session `main` reached by an idempotent `new-session -A -s main`, stable window indices (`base-index 1`, `renumber-windows off`), and the terminal-integration floor every other child sits on — `tmux-256color` with a `screen-256color` fallback for minimal hosts, `*:RGB` and undercurl overrides, `escape-time 10` so Esc does not lag in nvim, `focus-events on`, OSC passthrough. `default-command` starts nushell resolved on PATH with a fallback, never the absolute launchd-era path, because a remote's nu is somewhere else. Lazily created windows start at `~` (Q14). | — |
| `02-key-tables` | F4, F5 and F6 as tmux bindings and nothing in WezTerm. F4 pushes a table where an arrow splits in that direction with `-c "#{pane_current_path}"`; F5 pushes a table where a digit selects window N or creates it at that index when absent (Q2), and `a`–`i` select pane index 1–9 (Q3). Every letter stays bound so a mistyped one cancels rather than leaking a character — the reason `02-terminal/03-f5-jump-mode` R2 gives still holds on the new mechanism. `bind -T jump F5 send-keys F5` and its F4 twin are the double-tap that forwards a key to a nested session (Q10); F6 is never forwarded, because the palette belongs to the outermost terminal. | 01-session-and-windows |
| `03-status-bar` | The bar as tmux draws it: digit-only window labels, occupied vs empty tinted from `#{pane_current_command}`, the hostname on the left dimmed or blank when local, and the active pane's cwd beside the clock on the right (Q5, Q9). `pane-border-format` prints each pane's letter, which is what makes Q3's index addressing honest after a renumber. Finding T-9 still binds: the F5 legend was removed as noise and does not return. | 01-session-and-windows |
| `04-palette-delivery` | tinty's hook emits OSC 4/10/11 through tmux to the attached terminal and writes `~/.config/tmux/colors.conf`, then `source-file`s it, so one apply retints the terminal, tmux's own surfaces and every pane at once (Q4). `wezterm-colors.sh`, `~/.config/wezterm/colors.lua` and WezTerm's reload watch are deleted, and `02-terminal` I2's second clause is amended where it is written. The `dofile`-never-`require` trap is retired into the memo as history rather than deleted. | 01-session-and-windows |
| `05-copy-and-clipboard` | Copy mode on `copy-mode-vi`: `Ctrl+Shift+X` enters with the selection and the per-pane toggle cleared, `c` cycles cell→word→line per pane, `y` copies (Q6). The sink is pbcopy when the pane is on this machine and OSC 52 when it is not (Q14), which is the only arrangement where copying works both at this desk and over ssh. Terminal.app ignores OSC 52 and will fail silently there; say so in the manual entry rather than papering over it. | 01-session-and-windows |
| `06-nvim-session` | Neovim writes and restores a session so there is something for resurrect to bring back (Q12, Q13). A session plugin owns it; **which plugin is the analyst's call to recommend, not to assume** — persistence.nvim is smaller and lazy-loadable, auto-session is branch-aware and brings a picker. This is work inside the `done` `03-editor` epic and its footprint is that epic's files, so it takes the single-writer rule with it and amends `03-editor` where the plugin list is stated. | — |
| `07-persistence` | tmux-resurrect and tmux-continuum, cloned by `install.sh` to a fixed path and `run-shell`d directly from `tmux.conf` — no tpm, because chezmoi and `install.sh` already do what tpm exists for (Q11). Restores layout, cwds and nvim sessions after a reboot, autosaving every 15 minutes (Q12). `05-platform/01-deploy-mechanism` gains the clone as an obligation, in the same place its `:MasonUpdate` obligation already lives. | 01-session-and-windows, 06-nvim-session |
| `08-wezterm-reduction` | The cutover, in one change (Q8): `default_prog` attaches tmux, `enable_tab_bar = false`, F5 and F6 unbound, and roughly 470 lines go — the `reconcile_tabs` floor, the occupied/empty tint, the F5 table, the derived tab bar and the clock. What stays is the local chrome: font, grid centering, opacity and blur, the launchd PATH seeding, the capsule `SendString` keys. Three tests retire and `wezterm-launchd-path.sh` keeps everything but its `default_prog` assertions. I5 still binds what remains, and `gates/wezterm-config-fields.sh` keeps running. Also lands the cross-cutting edits: I1 and I2 amended in `02-terminal`, the six children marked superseded or amended, and `prds/README.md` and `AGENTS.md` brought in line — the 2026-08-20 shell-side multiplexer stays excluded, for a reason that now needs restating rather than repeating. | 02-key-tables, 03-status-bar, 04-palette-delivery, 05-copy-and-clipboard |
| `09-manual-entries` | home/dot_config/nushell/help/terminal.nuon` rewritten for the new bindings: the roughly 20 `kind: "wezterm-key"` verifications become `kind: "tmux-key"`, entries for F4 and the pane letters are added, and the ones describing the WezTerm floor go. tmux stays on the existing `terminal` surface and `help` gains no fifth `--mode`. The `tmux-key` resolver does not exist — file it as a requirement on `06-help/04-drift-check` against `tmux -L … list-keys`, and until it lands say plainly that those entries are documented and unverified rather than ticking a box that has not run. | 02-key-tables, 05-copy-and-clipboard |
