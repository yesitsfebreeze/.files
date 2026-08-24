verify: `bash -c 'cd "$(git rev-parse --show-toplevel)"; f=prds/02-terminal/02-startup-layout/prd.md; rc=0; T="$(tr "\n" " " < "$f" | tr -s " ")"; has() { echo "$T" | grep -qF "$1" || { echo "FAIL: missing: $1"; rc=1; }; }; no() { echo "$T" | grep -qiF "$1" && { echo "FAIL: still asserts: $1"; rc=1; }; }; has "floor, not a target"; has "MoveTab"; has "tab_id"; has "wezterm.GLOBAL"; has "re-entrancy"; has "pcall"; has "toggle_fullscreen"; has "mark_closing"; has "confirm = false"; has "window-config-reloaded"; has "pane-focus-changed"; has "SpawnWindow"; has "however opened"; has "C 10"; has "U 7"; no "gui-attached"; no "maximize"; no "Cmd+N spawns"; S=$(echo "$T" | grep -o "source:" | wc -l | tr -d " "); [ "$S" -ge 1 ] || { echo "FAIL: header cites no inventory source"; rc=1; }; echo "$T" | grep -qF "source: \"Nine-tab maximized" && { echo "FAIL: still cites the legacy capabilities.md entry, which spec08 marks DO NOT PORT"; rc=1; }; [ $rc -eq 0 ] && echo OK; exit $rc'`

est: 1h30m

# spec03 — `02-startup-layout`: the self-healing nine-tab floor

Goal: replace three requirements built on machinery that does not exist
(`gui-attached`, a `Cmd+N` binding, `maximize()`) with the model the user
chose in **Q1(a)** — the full reconciler, nine tabs always present *and*
each digit a stable address.

Files: `.mi/prds/02-terminal/02-startup-layout/prd.md` — and nothing else.

**Proved RED 2026-08-21 — 17 failures.** The current file contains
`gui-attached` and `maximize`, cites the legacy `capabilities.md` source
`"Nine-tab maximized` (which spec08 marks `DO NOT PORT`), and contains none
of `floor, not a target`, `MoveTab`, `tab_id`, `wezterm.GLOBAL`,
`re-entrancy`, `pcall`, `toggle_fullscreen`, `mark_closing`, `confirm =
false`, `window-config-reloaded`, `pane-focus-changed`, `SpawnWindow`,
`however opened`, or the `C 10` header.

**Rating: C 10 / U 7**, source `Self-healing nine-tab floor`. The inventory's
`SIMPLIFY` marker is **withdrawn by Q1** — the human chose the full shape.
Following the D.1b precedent, the marker moves and the C/U numbers do not:
ratings measure intricacy and daily value, the marker records membership, and
it is the marker that was overridden. Note this in the header so a later
reader does not "restore" the marker from the inventory.

**Why the full shape, recorded so it is not re-litigated.** The capability is
not "nine tabs", it is "a digit is a stable address". Both cheaper shapes
keep the tabs and delete the address, which is the only thing the complexity
buys. Live evidence at re-spec time: `wezterm cli list` showed one window
with exactly nine tabs whose ids were `22, 24, 26, 28, 29, 30, 34, 36, 37` —
nine live tabs scattered across a 16-wide id range, i.e. tabs had died and
been refilled *and repositioned* repeatedly within one session.

## Boxes

- [x] **B1 — a floor, not a target.** `TAB_COUNT = 9` on **every** window —
      the startup window, a new window, and `wezterm cli spawn --new-window`
      alike. Extra hand-opened tabs are adopted, never closed; a dead slot
      *past* the floor is dropped rather than refilled.
- [x] **B2 — reconcile, do not intercept, and say why.** WezTerm emits **no
      tab-close event**, so the model compares the live tab list against a
      per-window slot map and rebuilds the holes. That one mechanism covers
      `CloseCurrentTab`, `exit` in a tab's last pane, a crashed shell and
      `wezterm cli kill-pane`. Closing a pane in a split tab needs nothing:
      the tab survives.
- [x] **B3 — position is restored, not just the count.** A plain `spawn_tab`
      appends, so the replacement for a dead slot 3 would land at the end and
      silently renumber everything after the hole — F5+4 would then reach the
      old tab 5. Spawn, then `MoveTab` into the dead slot's index.
- [x] **B4 — slots are tracked by `tab_id`, never by index**, because indices
      are exactly what shift when a tab dies.
- [x] **B5 — per-window slot maps in `wezterm.GLOBAL`, with both reasons.**
      `GLOBAL` because the map must **survive a config reload**: every
      evaluation of the config makes fresh Lua contexts and a module-local
      starts `nil` in each, so a local `slots` table is emptied by every
      reload — every `tinty apply` is one — and each pass then re-adopts the
      current tab order as gospel, destroying the one piece of state that has
      to survive. The reason is desired **lifetime**, not context count:
      measured 2026-08-24, one context serves every trigger at a time and a
      module-local read back `nil` 5 times in 2770 fires, always a fresh
      context's first fire. **Per window** because a single shared list had
      two windows reading each other's ids as dead slots and refilling
      forever. Values stay JSON-shaped (array of integer ids, string keys),
      and a value read back out is a **copy**, so the map is rebuilt as a
      plain table and reassigned rather than mutated in place.
- [x] **B6 — `set_slots` drops entries for dead windows**, the only thing
      keeping the map from growing for the life of the session.
- [x] **B7 — a re-entrancy guard, with its failure.** `spawn_tab` and
      `perform_action` pump the event loop; a nested pass saw a half-built
      window, concluded seven slots were missing and filled them while the
      outer pass was still filling its own — **startup produced 16 tabs
      instead of 9**. Deliberately module-local, not `GLOBAL`, for two
      reasons: it only has to hold across a synchronous re-entry, which by
      definition happens in the same Lua context; and `GLOBAL` survives the
      config reload that resets every local in the file, so a guard parked
      there would outlive the one event measured to clear a stuck one.
- [x] **B8 — `pcall` around the repair**, so a spawn failure (out of ptys, a
      bad `default_prog`) cannot leave the guard latched. Measured
      2026-08-23: exactly one Lua context serves every trigger of a config
      generation, so a latched guard is read as latched by every later fire
      in every window, and only re-evaluating the file clears it — a
      successful reload does, an unparseable one does not. A `false` left in
      the map is harmless: the next pass reads it as a dead slot and
      retries.
- [x] **B9 — activate before any real move, and skip the no-op.** `MoveTab`
      acts on whatever the GUI *believes* is the active tab, which right
      after a `spawn_tab` can still be the previous one — so a "harmless"
      no-op move shoved the old tab one slot along and startup came out
      `1,0,2,3…`. Skip the move when the slot being filled is already the end
      of the list, and activate explicitly before every other move.
- [x] **B10 — focus is re-asserted by id.** After the rebuild, return to the
      tab you were on **by tab id**, not by index, and fall back to the fresh
      tab only if that one is dead too. Closing a tab should move you on, not
      snap you onto a blank replacement.
- [x] **B11 — the four repair triggers, with which one is the guarantee.**
      `update-status` (the 5 s tick — this is what actually heals, focused or
      not); `window-config-reloaded` (fills a new window at birth instead of
      up to 5 s later); `window-focus-changed`; and `pane-focus-changed`,
      which is **inert on 20240203** — verified never to fire on a pane
      switch, kept because it costs nothing and starts working by itself on a
      build that emits it. The no-hole path is a tab-list walk, so idle ticks
      stay cheap.
- [x] **B12 — startup: fullscreen, not maximized (T-5).** `gui-startup`
      spawns one window, hands the CLI's `cmd` to the **first tab only** (so
      `wezterm start -- nvim foo` does not open nine editors), clears the
      stale `GLOBAL` slot maps a config reload would leave behind, fills the
      floor, activates slot 1, and calls `toggle_fullscreen()`. There is no
      `gui-attached` hook and no `maximize()`; both are legacy fiction.
- [x] **B13 — new windows, worded by cause (T-7 corrected).** "Any new
      window, **however opened**, comes up at the floor." The mechanism is
      `reconcile_tabs` on `window-config-reloaded`, which fires once per
      newly created window — **not** a binding. Record the correction
      explicitly: T-7 says "no `Cmd+N` binding exists", which is true of
      `config.keys` but false of the effective key set, where `Cmd+N` and
      `Ctrl+Shift+N` resolve to `SpawnWindow` as WezTerm **defaults**
      (`wezterm show-keys --lua` rows 111–112). The old R2 was accidentally
      right in behaviour and wrong in cause, and the wording above is right
      in both — it also covers `wezterm cli spawn --new-window`.
- [x] **B14 — `Ctrl+Shift+Q`, and why it exists at all (T-6).**
      `mark_closing(window_id)` **first** — that is what stops the reconciler
      racing the close — then one `CloseCurrentTab{ confirm = false }` per
      live tab. `confirm = false` because the prompt would otherwise appear
      once per tab; a loop because WezTerm exposes no "close window" action;
      needed at all because the floor applies to every window, so closing
      tabs one at a time can never empty a window whose slots refill, and
      `window_decorations = "RESIZE"` leaves no titlebar close button. Record
      that it is **conditional on the floor** — Q1(a) is what keeps it alive,
      and this is how T-6 is disposed.

## Out of scope

- The tab *title* (spec02's B5) and tab-bar colours (spec02's B4).
- Tab content-state colouring, which is
  [`05-tab-content-state`](../../../../02-terminal/05-tab-content-state/prd.md).
