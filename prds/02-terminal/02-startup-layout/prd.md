---
state: done
claim:
priority: 24
est: 4.75h
task: T.2
mode: afk
needs:
  - 02-terminal/01-appearance
verify: "bash tests/tmux-key-tables.sh --keys"   # SUPERSEDED 2026-08-30: the nine-tab floor and its gate retired with the WezTerm mux; a digit is a tmux window now
---

# Startup layout — the self-healing nine-tab floor

Parent: [Terminal epic](../prd.md) · C 10 · U 7 · source: Self-healing
nine-tab floor

**Marker note.** The inventory entry carries `SIMPLIFY`, and that marker is
**withdrawn** by the answer to this re-spec's Q1 (2026-08-21, user): the full
reconciler is kept. Following the D.1b precedent the marker moves and the
`C`/`U` numbers do not — ratings measure intricacy and daily value, the marker
records membership, and it is the marker that was overridden. Recorded here so
a later reader does not "restore" the `SIMPLIFY` from
[`capabilities-terminal.md`](../../../docs/capabilities-terminal.md), which
still shows it.

Purpose: nine terminals, always ready, on every window — and, more precisely,
the guarantee that **a digit is a stable address**. That guarantee is what the
F5 digit half is worth, and it is the only thing the complexity buys.

**Why the full shape, recorded so it is not re-litigated.** The capability
being ported is not "nine tabs"; it is "F5 plus a digit always lands on the
same slot, and there is no tab-7-doesn't-exist-yet case". The two cheaper
shapes the inventory offers — spawn nine once with no reconciler, or reconcile
the count without repositioning — both keep the tabs and delete the address.
Live evidence at re-spec time: `wezterm cli list` showed one window with
exactly nine tabs whose ids were `22, 24, 26, 28, 29, 30, 34, 36, 37` — nine
live tabs scattered across a 16-wide id range, i.e. tabs had died and been
refilled *and* repositioned repeatedly inside a single session.

## Status after the tmux cutover

**SUPERSEDED 2026-08-30 by [`07-multiplexer/01-session-and-windows`](../../07-multiplexer/01-session-and-windows/prd.md)
and [`02-key-tables`](../../07-multiplexer/02-key-tables/prd.md).**
The self-healing nine-tab floor — `reconcile_tabs`, the slot map, the
closing marker, the four event registrations, roughly 320 lines — is
deleted from `wezterm.lua`, and `tests/wezterm-startup-layout.sh` is
retired with it.

The floor existed because WezTerm renumbers tabs on close, so a digit was
not a stable address without one. **tmux indices do not renumber**
(`renumber-windows off`), so the entire mechanism is unnecessary rather
than reimplemented: Q2 chose lazy creation — `F5 <digit>` selects window
N or creates it there — and startup is one window, not nine. The
capability this node was for is intact; the machinery is gone.

## Requirements

Proven 2026-08-22 by `bash tests/wezterm-startup-layout.sh` (both stages,
ALL PASS, wezterm 20240203-110809-5046fc22): the R-numbered PASS lines map
each box, and `bash tests/wezterm-appearance.sh` stayed ALL PASS after the
extension.

- [x] **R1** — **A floor, not a target.** `TAB_COUNT = 9` on **every**
      window: the startup window, a window spawned by a key, and
      `wezterm cli spawn --new-window` alike. Extra hand-opened tabs are
      adopted, never closed; a dead slot *past* the floor is dropped rather
      than refilled.
- [x] **R2** — **Reconcile, do not intercept — and say why.** WezTerm emits
      **no tab-close event**, so the model compares the live tab list against
      a per-window slot map and rebuilds the holes. That one mechanism covers
      `CloseCurrentTab`, `exit` in a tab's last pane, a crashed shell and
      `wezterm cli kill-pane`. Closing a pane inside a split tab needs
      nothing at all: the tab survives.
- [x] **R3** — **Position is restored, not just the count.** A plain
      `spawn_tab` appends, so the replacement for a dead slot 3 would land at
      the end and silently renumber everything after the hole — F5 followed
      by `4` would then reach the old tab 5. Spawn, then `MoveTab` into the
      dead slot's index.
- [x] **R4** — **Slots are tracked by `tab_id`, never by index**, because
      indices are exactly what shift when a tab dies.
- [x] **R5** — **Per-window slot maps in `wezterm.GLOBAL`, with both
      reasons.** `wezterm.GLOBAL` because the map must **survive a config
      reload**, which is a lifetime reason rather than a context-count one.
      Every evaluation of the config creates fresh Lua contexts (measured: 2
      per evaluation) and a module-local starts `nil` in each, so a local
      `slots` table is emptied by every reload — and every `tinty apply` is
      one, because `colors.lua` is on the reload watch list — leaving each
      pass to re-adopt the current tab order as gospel and destroying the one
      piece of state that has to survive. Measured 2026-08-24 on `20240203`
      against an instrumented copy of the live config in two isolated GUIs:
      exactly one context serves events at a time, dispatch never returns to
      an older one, and a module-local read back `nil` **5 times in 2770
      fires**, every one of them a freshly evaluated context's first fire.
      **Per window** because a single shared list had two windows reading
      each other's ids as dead slots and refilling forever. Values stay
      JSON-shaped (an array of integer ids under string keys), and a value
      read back out is a **copy** — assigning into it does not write through
      — so the map is rebuilt as a plain table and reassigned rather than
      mutated in place.
- [x] **R6** — **`set_slots` drops entries for dead windows**, which is the
      only thing keeping the map from growing for the life of the session.
- [x] **R7** — **A re-entrancy guard, with the failure it prevents.**
      `spawn_tab` and `perform_action` pump the event loop, so a nested pass
      saw a half-built window, concluded seven slots were missing, and filled
      them while the outer pass was still filling its own — **startup
      produced 16 tabs instead of 9**. The guard is deliberately
      module-local, not `wezterm.GLOBAL`, for two reasons. It only has to
      hold across a synchronous re-entry, which by definition happens in the
      same Lua context. And `wezterm.GLOBAL` survives the config reload that
      resets every local in this file, so a guard parked there would outlive
      the one event measured to clear a stuck one (R8).
- [x] **R8** — **`pcall` around the repair**, so a spawn failure (out of
      ptys, a bad `default_prog`) cannot leave the guard latched. Measured
      2026-08-23 on `20240203`: one evaluation of the config creates 2 Lua
      contexts (4 with three windows) and exactly one of them serves every
      trigger of that generation — 0 of 268 fires across 10 generations
      reached a sibling context — so a latched guard is read as latched by
      every later fire, in every window, including windows opened after it
      latched. Only re-evaluating the file clears it: a successful reload
      does, and every `tinty apply` is one because `colors.lua` is on the
      reload watch list; a config that fails to parse does not, because the
      body never runs. A `false` left in the map is harmless: the next pass
      reads it as a dead slot and retries.
- [x] **R9** — **Activate before any real move, and skip the no-op.**
      `MoveTab` acts on whatever the GUI *believes* is the active tab, which
      right after a `spawn_tab` can still be the previous one — so a
      "harmless" no-op move shoved the old tab one slot along and startup
      came out `1,0,2,3…`. Skip the move when the slot being filled is
      already the end of the list, and activate explicitly before every other
      move.
- [x] **R10** — **Focus is re-asserted by id.** After the rebuild, return to
      the tab you were on **by tab id**, not by index, falling back to the
      fresh tab only if that one is dead too. Closing a tab should move you
      on, not snap you onto a blank replacement.
- [x] **R11** — **The four repair triggers, and which one is the
      guarantee.** `update-status` — the 5 s tick, and the one that actually
      heals whether or not the tab is focused; `window-config-reloaded`,
      which fills a new window at birth instead of up to 5 s later;
      `window-focus-changed`; and `pane-focus-changed`, which is **inert on
      20240203** — verified never to fire on a pane switch, kept because it
      costs nothing and starts working by itself on a build that emits it.
      The no-hole path is a tab-list walk, so idle ticks stay cheap.
- [x] **R12** — **Startup is fullscreen (finding T-5).** `gui-startup` spawns
      one window, hands the CLI's `cmd` to the **first tab only** (so
      `wezterm start -- nvim foo` does not open nine editors), clears the
      stale `wezterm.GLOBAL` slot maps a config reload would leave behind,
      fills the floor, activates slot 1, and calls `toggle_fullscreen()`.
      There is no attach-time GUI hook and no window-enlarging call: the two
      the old text named are legacy fiction, and neither exists in the live
      config or in this build's event set.
- [x] **R13** — **New windows, worded by cause (finding T-7, corrected).**
      *Any new window, **however opened**, comes up at the floor.* The
      mechanism is the reconciler firing on `window-config-reloaded`, which
      WezTerm emits once per newly created window — **not** a binding. The
      correction is worth recording: T-7 says no new-window binding exists,
      which is true of `config.keys` but false of the *effective* key set,
      where `Cmd+N` and `Ctrl+Shift+N` resolve to `SpawnWindow` as WezTerm
      **defaults** (`wezterm show-keys --lua` rows 111–112). The old R2 was
      accidentally right in behaviour and wrong in cause; the wording above
      is right in both, and it also covers `wezterm cli spawn --new-window`.
- [x] **R14** — **`Ctrl+Shift+Q`, and why it exists at all (finding T-6).**
      `mark_closing(window_id)` **first** — that is what stops the reconciler
      racing the close — then one `CloseCurrentTab{ confirm = false }` per
      live tab. `confirm = false` because the prompt would otherwise appear
      once per tab; a loop because WezTerm exposes no "close window" action;
      needed at all because the floor applies to every window, so closing
      tabs one at a time can never empty a window whose slots refill, and
      `window_decorations = "RESIZE"` leaves no titlebar close button. It is
      **conditional on the floor** — the answer to Q1 is what keeps it alive,
      and that is how T-6 is disposed.

## Acceptance

GUI-only: each box below is a `**T.2**` row in `gates/manual/wave3.md`, run
by a human at the wave-3 gate. A box here ticks when its row passes.

- [ ] A fresh launch yields one fullscreen window with tabs titled `1`–`9`
      and focus on tab 1 — never 16 tabs, and never the `1,0,2,3…` order.
- [ ] Closing tab 3 and waiting one `status_update_interval` leaves nine
      tabs, with the replacement **at position 3**, and focus on the tab that
      was focused before rather than on the replacement.
- [ ] `wezterm cli spawn --new-window` produces a window with nine tabs
      without any key being pressed.
- [ ] Opening a tenth tab by hand leaves ten tabs standing across at least
      two ticks: extra tabs are adopted, not culled.
- [ ] `Ctrl+Shift+Q` closes the whole window with no confirmation prompt and
      no tab refilling behind it.
- [ ] Two windows open simultaneously each hold nine tabs and neither one
      spawns tabs into the other.

## Out of scope
- The tab *title*, which is [`01-appearance`](../01-appearance/prd.md) R5,
  and the tab-bar colours, which are that node's R4.
- Tab content-state colouring, which is
  [`05-tab-content-state`](../05-tab-content-state/prd.md).
- Anything this node's Requirements do not name. The epic
  ([`../prd.md`](../prd.md)) owns the shared invariants.
