---
state: done
claim: 
priority: 14
est: 2.25h
actual: 15m
task: T.6
mode: afk
needs:
  - 02-terminal/04-copy-mode
verify: "bash tests/tmux-status-bar.sh --render" # SUPERSEDED 2026-08-30: the occupied/empty tint is a tmux status format now
---

# Tab content-state colouring

Parent: [Terminal epic](../prd.md) · C 4 · U 7 · source: net-new

Purpose: tabs whose panes are all idle render in a dim "empty" colour; any tab
with at least one pane running a command renders in a lit "occupied" colour.
The distinction is computed when a pane appears and rechecked on the status
tick, so a tab that was empty and then ran `htop` flips to occupied without a
keystroke. This is the one terminal node with no inventory entry, because it
is not live anywhere — hence `net-new`, with the rating carried in this header
as `AGENTS.md` requires.

## Status after the tmux cutover

**SUPERSEDED 2026-08-30 by [`07-multiplexer/03-status-bar`](../../07-multiplexer/03-status-bar/prd.md).**
The occupied/empty tint — the learned per-pane baseline map, its four
event registrations, `tab_is_occupied`, roughly 120 lines — is deleted,
and `tests/wezterm-tab-content-state.sh` is retired with it.

The *capability* is ported and the port is smaller by an order of
magnitude, because tmux exposes what WezTerm made this node infer. A
window is occupied when any of its panes runs something that is not a
shell, written as one format: `#{P:…}` over the panes emitting a marker
for each non-shell command, and `#{m:*X*,…}` asking whether any did. No
baseline to learn, nothing to re-learn on reload. The design split this
node made — background says focus, foreground says busy — is carried
over deliberately.

## Requirements

- [x] **R1** — **Classification by foreground process.** A pane is
      `occupied` when its foreground process is **not** the shell, and
      `empty` when it is. A tab's colour is the OR of its panes: occupied if
      any pane is occupied, empty only when every pane is empty.
      Implemented as a *learned* baseline rather than a shell test, which is
      the same rule without naming a shell: `tab_is_occupied` compares each
      pane's live `foreground_process_name` against the first one WezTerm
      ever reported for that pane, and returns `true` from inside the loop /
      `false` after it. Proved by `bash tests/wezterm-tab-content-state.sh
      --static` (the `return true` line precedes `return false`, and
      `ipairs(tab.panes or {})` is the iteration).
- [x] **R2** — **Recheck triggers.** Reclassify on pane creation, on pane
      exit, and on the `update-status` tick that R5 already relies on. "The
      first prompt emission from a shell" is **not** a trigger — see R4 for
      why it cannot be one. `learn_pane_programs` is registered once each on
      `update-status`, `window-config-reloaded`, `pane-focus-changed` and
      `window-focus-changed`; this build emits no pane-created/pane-closed
      event, so the 5 s tick is the guarantee. Proved: `1` hit for each of
      the four registrations.
- [x] **R3** — **Colour mapping.** Two tab-bar colours, derived from the
      active scheme and never hardcoded:
  - [x] `empty` — the inactive-tab colour already used for background tabs.
        Consumed by returning a bare string, which leaves
        `colors.tab_bar.inactive_tab` in charge; no key was added to that
        table (still exactly its six).
  - [x] `occupied` — a distinct tint, so an occupied tab is legible against
        the bar without outshining the focused tab. The focused tab keeps its
        own colour: occupied/inactive is a separate signal from
        focused/inactive. Implemented as `AnsiColor = "Silver"` (ANSI 7,
        base05) over the same label, with `tab.is_active` returning the bare
        label first, so the focused tab is never repainted. **Whether the lit
        digit reads well against the bar is a judgement the static gate
        cannot make** — it is the last of the six T.6 manual rows.
  - [x] The derivation itself is not restated here. It lives in
        [`01-appearance`](../01-appearance/prd.md) R4, which already owns
        `colors.tab_bar`; this node consumes it. Proved: no `#rrggbb` and no
        scheme name anywhere in the file (0 hits).
- [x] **R4** — **No shell-side dependency, and no prompt markers.** The
      classification must not require the shell to cooperate, because the
      same config runs with any `$SHELL`. The obvious terminal-side prompt
      signal is **`OSC 133`** — and it is unavailable on purpose:
      [`04-shell/01-core-config`](../../04-shell/01-core-config/prd.md) R5
      turns `OSC 133`/633 **off** deliberately, as the phantom-blank-line fix
      for the starship two-line prompt under WezTerm. A requirement written
      against prompt emission would therefore ask for a signal the shell is
      deliberately not sending. The foreground-process check in R1 meets this
      requirement's actual intent more completely than prompt markers ever
      did, since it needs no cooperation from any shell at all. Proved: 0
      hits for a quoted `nu`/`zsh`/`bash`/`fish`/`sh` inside this node's
      block, and 0 hits on any *code* line of the block for `os.getenv`,
      `/etc/shells`, `dscl`, `getent`, `SetUserVar`, `OSC 133` or `633` —
      each of those is carried in the block's *comments* on purpose, with
      its reason, which the gate also asserts.
- [x] **R5** — **The accessor is verified, not assumed.**
      `pane:get_foreground_process_name()` must exist on the installed build
      before it is relied on — this is the same build on which
      `pane:get_current_working_directory()` is nil and raised on every
      status tick. Checked read-only for the 2026-08-21 re-spec: `strings` on
      the `20240203` binary finds `get_foreground_process_name` **4 times**
      and `get_current_working_directory` **0 times**. The probe correctly
      reports the known-absent method as absent, which is what makes the
      positive result trustworthy. Repeat the check rather than trusting this
      line. **Repeated 2026-08-23** against
      `/Applications/WezTerm.app/Contents/MacOS/wezterm-gui` (the sibling of
      `readlink -f $(command -v wezterm)`, version
      `20240203-110809-5046fc22`): **4** and **0**, unchanged. It is no
      longer only a sentence — the `--probe` stage of
      `tests/wezterm-tab-content-state.sh` asserts both numbers on every run,
      the second as the negative control.
- [x] **R6** — **Stale-state safety.** A pane that dies without WezTerm
      learning about it (crash, `kill -9`) must not keep its tab lit forever.
      The periodic `update-status` tick reclassifies every tab against the
      live pane set, so a dead pane's occupancy decays within one tick
      interval. Two mechanisms carry this and both are gated: a gone pane is
      not in `tab.panes` at all, so the paint path cannot see it; and
      `learn_pane_programs` **rebuilds** its map from the live pane set
      instead of mutating the copy read out of `wezterm.GLOBAL`, which is
      what drops the dead pane's baseline. Proved: exactly one
      `wezterm.GLOBAL.tab_pane_program =` write and one read, `local out =
      {}` inside the function, and 0 `known[...] =` assignments. **The
      observable decay itself needs a live GUI** — it is T.6 manual row 5.

## Acceptance

All five need a live GUI: occupancy is a live-session property, so none of
them is decidable from the source tree or from `wezterm ls-fonts` /
`show-keys`. They are the six **T.6** rows in `gates/manual/wave4.md` (five
plus one judgement row for R3's legibility clause), and they stay `[ ]` here
until that checklist is walked on the machine. Ticking any of them off the
static gate would be a false record — the gate proves the code shape, not
what the bar looks like.

**Every box below is class (c) — OBSOLETE, classified 2026-08-30 by
[`done-nodes-with-unticked-boxes`](../../00-delivery/corrections/done-nodes-with-unticked-boxes/prd.md).**
This node is SUPERSEDED by
[`07-multiplexer/03-status-bar`](../../07-multiplexer/03-status-bar/prd.md).
The CAPABILITY is ported and is an order of magnitude smaller — tmux exposes
what this node had to infer, so the learned per-pane baseline map, its four
event registrations and `tab_is_occupied` are all deleted in favour of one
format string. It is proven behaviourally by
`bash tests/tmux-status-bar.sh --render`: an idle window's digit is dimmed,
the same window running `sleep` lights, and a second idle pane does not
un-light a window whose other pane is busy.

They stay `- [ ]` rather than ticked: every one names a tab, and there are no
tabs.

- [ ] *(c)* Launching WezTerm: all nine tabs render in the `empty` colour, no
      command having run in any of them yet.
- [ ] *(c)* Running a long-lived command in tab 3 flips tab 3 to `occupied` within
      one `status_update_interval`, and it returns to `empty` within one
      interval of the command exiting.
- [ ] *(c)* Splitting a tab and running a command in the new pane flips the *tab*
      to occupied even though the sibling pane is still idle.
- [ ] *(c)* Killing a pane's process from outside WezTerm (`kill -9` on the shell
      PID) flips the tab back to `empty` within one `status_update_interval`.
- [ ] *(c)* Switching the active theme recolours both states with no edit to this
      feature's code.

## Out of scope
- The tab-bar colour derivation itself, which is
  [`01-appearance`](../01-appearance/prd.md) R4.
- Anything this node's Requirements do not name. The epic
  ([`../prd.md`](../prd.md)) owns the shared invariants.
