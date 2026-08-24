---
est: 1h
footprint:
  - home/dot_config/wezterm/wezterm.lua
---

# spec01 — the occupied/empty tab tint in `wezterm.lua`

Everything R1–R6 put in the terminal config: a per-pane baseline learned on
the status tick, an OR over a tab's panes, and one tint applied from
`format-tab-title`. No shell name, no prompt marker and no palette constant
appears. Land after T.4 and while no other lane holds the file — this spec
edits the `format-tab-title` handler `01-appearance` R5 wrote, in place.

Every accessor named below was measured against the pinned build
(`20240203-110809-5046fc22`) before this spec was written; the measurements
are recorded where they are used, because each one is a thing the next
reader would otherwise assume.

## What was measured, and what it rules out

- **`colors.tab_bar` has no occupancy state.** Its keys are
  `background`, `active_tab`, `inactive_tab`, `inactive_tab_hover`,
  `new_tab`, `new_tab_hover` — focus and hover, nothing else — and it is
  WezTerm-wide. So a *per-tab* colour is reachable from exactly one place:
  the value `format-tab-title` returns. This is what R3's "the derivation
  lives in `01-appearance` R4 and this node consumes it" means in code —
  `01-appearance`'s `inactive_tab` **is** the empty colour, consumed by
  returning a bare string for an empty tab and leaving the bar in charge.
  Add no key to `colors.tab_bar`.
- **`PaneInformation.foreground_process_name` exists on this build.** The
  `TabInformation`/`PaneInformation` field block in `wezterm-gui` reads
  `tab_index is_active active_pane panes tab_title window_title pane_index
  is_zoomed has_unseen_output left top user_vars foreground_process_name
  tty_name current_working_dir domain_name` — so `tab.panes` and the field
  are both real.
- **`pane:get_foreground_process_name()` exists** (R5). `strings` on
  `wezterm-gui` finds it 4 times, and finds
  `get_current_working_directory` — the method this build does **not** have,
  which is `01-appearance` R10's finding — 0 times. The probe reports a
  known absence correctly, which is what makes the positive result worth
  trusting. Re-run it rather than trusting this line.
- **`wezterm.mux` has no `all_panes` and no `get_pane` on this build.** Its
  function list is `get_active_workspace get_workspace_names
  set_active_workspace get_window get_tab spawn_window all_windows
  get_domain all_domains set_default_domain`. Reach panes through
  `all_windows()` → `w:tabs()` → `t:panes()`; `MuxTab` carries `panes`,
  `panes_with_info`, `active_pane`.
- **`os.getenv("SHELL")` is not available to a GUI-launched WezTerm.**
  `launchctl print gui/$(id -u)` exports `SSH_AUTH_SOCK` and nothing else on
  this machine. Any design that reads the shell out of the environment is
  dead on arrival, which is half of why the baseline below is learned.
- **This build emits no pane-created and no pane-closed event.** Same fact
  the tab floor above already records for tab close: the periodic
  `update-status` tick is the guarantee, and `pane-focus-changed` is inert on
  `20240203`.

## Anchors, not line numbers

- The new block goes **immediately before** the
  `-- ── R5: the tab title is the digit and nothing else` header, under its
  own `-- ── 05-tab-content-state` header. It needs `wezterm` and the mux,
  both available there; it needs nothing from `theme`.
- The `format-tab-title` handler in that R5 block is **edited in place**.
  One registration only: with two handlers registered for this event the
  first non-nil return wins and the second is dead code that reads live.
- Rewrite the R5 block's comment to describe the done state — the label is
  still the digit and nothing else, and the digit's *colour* now carries
  occupancy. A comment that still says the title carries no other
  information reads as current and is false.

## The code

### The learned baseline (R1, R4, R5, R6)

```lua
-- ── 05-tab-content-state: the occupied/empty tab tint ───────────────────────

-- A tab is `occupied` when at least one of its panes has something running,
-- and `empty` only when every pane sits at the program it was spawned with.
-- The test is the pane's FOREGROUND PROCESS, never a prompt marker: OSC
-- 133/633 is off on purpose (prds/04-shell/01-core-config R5 — it
-- double-marks starship's two-line prompt under WezTerm and leaves a
-- phantom blank line), so a prompt signal is one the shell is deliberately
-- not sending. The foreground process needs no cooperation from any shell
-- at all, which is the requirement prompt markers were only approximating.
--
-- What counts as "the program it was spawned with" is LEARNED, never named.
-- The first foreground process WezTerm reports for a pane is what WezTerm
-- spawned into it; anything in the foreground later is a descendant. So no
-- shell name appears in this config, and the classification survives
-- prds/02-terminal/06-launchd-path landing default_prog and changing the
-- spawned program from the login shell to `nu`. Reading the shell out of the
-- environment was not an option: measured 2026-08-23, launchd's GUI
-- environment on this machine exports SSH_AUTH_SOCK and nothing else, so
-- os.getenv("SHELL") is nil in a GUI-launched WezTerm.
--
-- The baselines live in wezterm.GLOBAL for the reason the slot map above
-- records, and it is a LIFETIME reason: a module-local starts nil in every
-- new Lua context, and every config reload makes new ones (every `tinty
-- apply` is a reload), so a baseline map parked in a local would be emptied
-- on each -- and an empty baseline map re-learns against whatever is running
-- RIGHT NOW, which would record `htop` as a pane's own program and read that
-- tab as empty for as long as it ran. Not "whichever context is free":
-- measured, one context serves at a time -- see the slot map comment.
-- JSON-shaped, as GLOBAL requires: pane id as a string key, the executable
-- path as the value.
local function pane_programs()
    return wezterm.GLOBAL.tab_pane_program or {}
end

-- Learn on the tick, paint on the repaint. This is the ONLY place
-- get_foreground_process_name is called, and only for a pane that has no
-- baseline yet -- WezTerm documents it as a relatively expensive call
-- (it walks the OS process table), so it is bounded to once per pane rather
-- than once per repaint. pcall for the same reason 01-appearance R6 wraps
-- inject_output: a pane can die mid-iteration.
local function learn_pane_programs()
    local known = pane_programs()
    -- Rebuilt rather than mutated: a value read back out of wezterm.GLOBAL
    -- is a copy, so assigning into it does not write through (the set_slots
    -- rule above). Rebuilding from the live pane set is also what drops
    -- entries for panes that are gone, which is the only thing that keeps
    -- the map from growing for the life of the session.
    local out = {}
    local changed = false
    for _, w in ipairs(wezterm.mux.all_windows()) do
        for _, t in ipairs(w:tabs()) do
            for _, p in ipairs(t:panes()) do
                local key = tostring(p:pane_id())
                if known[key] then
                    out[key] = known[key]
                else
                    local ok, name = pcall(function()
                        return p:get_foreground_process_name()
                    end)
                    if ok and type(name) == "string" and name ~= "" then
                        out[key] = name
                        changed = true
                    end
                end
            end
        end
    end
    for k in pairs(known) do
        if out[k] == nil then
            changed = true
        end
    end
    if changed then
        wezterm.GLOBAL.tab_pane_program = out
    end
end

-- The trigger list reconcile_tabs carries, for the same reasons: this build
-- emits no pane-created and no pane-closed event, so the periodic
-- update-status tick (status_update_interval = 5000) is the guarantee -- a
-- pane that appears, exits, or is killed from outside WezTerm is reflected
-- within one interval, which is R6's stale-state decay. pane-focus-changed
-- is inert on 20240203 and is registered anyway because it costs nothing and
-- starts working by itself on a build that emits it.
wezterm.on("update-status", learn_pane_programs)
wezterm.on("window-config-reloaded", learn_pane_programs)
wezterm.on("pane-focus-changed", learn_pane_programs)
wezterm.on("window-focus-changed", learn_pane_programs)
```

### The OR over a tab's panes (R1, R6)

```lua
-- Occupied when ANY pane's current foreground process differs from that
-- pane's own baseline; empty only when every one of them matches. Read from
-- the PaneInformation the tab bar already hands us, so the paint path calls
-- no mux method at all.
--
-- Three cases fail to EMPTY on purpose, and dim is the safe direction for
-- all three: a pane created since the last tick has no baseline yet and is
-- idle anyway; a pane whose foreground process cannot be read (it died, or
-- it is not a local pane) has nothing to compare; and a pane that is gone is
-- not in tab.panes at all, so no dead pane can keep a tab lit.
local function tab_is_occupied(tab)
    local known = pane_programs()
    for _, p in ipairs(tab.panes or {}) do
        local id = p.pane_id
        local fg = p.foreground_process_name
        if id ~= nil and type(fg) == "string" and fg ~= "" then
            local base = known[tostring(id)]
            if base ~= nil and fg ~= base then
                return true
            end
        end
    end
    return false
end
```

### The tint (R2, R3)

Replace the R5 handler with this one:

```lua
wezterm.on("format-tab-title", function(tab)
    local label = string.format("  %d  ", tab.tab_index + 1)
    -- The bare string leaves colors.tab_bar in charge, which is how both the
    -- focused tab and an empty one keep the colours 01-appearance R4 derived
    -- -- base02 + bold base05 for the focused tab, base03 for an inactive
    -- one. The focused tab is never repainted here: the tab BACKGROUND says
    -- which tab has focus and the tab FOREGROUND says which tabs are busy,
    -- so the two signals never compete for one channel.
    if tab.is_active or not tab_is_occupied(tab) then
        return label
    end
    -- `Silver` is ANSI 7, the slot colors.lua fills with base05 -- the
    -- palette's own foreground, and the same slot the clock uses. An ANSI
    -- NAME rather than a colour value is what makes tinty's next apply
    -- retint this with everything else (epic I2): lit against the inactive
    -- tab's base03, without taking the focused tab's background or its bold.
    return wezterm.format({
        { Foreground = { AnsiColor = "Silver" } },
        { Text = label },
    })
end)
```

## What must NOT appear

- A shell name used as a classification constant — `nu`, `zsh`, `bash`,
  `fish`, `sh` — anywhere in this block (R4). The baseline is learned; a
  name list would re-introduce the dependency R4 refuses.
- `OSC 133`, `633`, `SetUserVar` or any other prompt marker as this
  feature's signal (R4).
- `os.getenv("SHELL")`, `/etc/shells`, `dscl`, `getent` — the environment
  route, measured dead above.
- `wezterm.mux.all_panes`, `wezterm.mux.get_pane` — neither exists on this
  build. Grep for `mux.all_panes`, never the bare substring:
  `retint_all_panes` (`01-appearance` R6) is a landed line that matches it.
- `get_current_working_directory` on a non-comment line. R10's comment
  already carries it twice, recording that the method does not exist.
- A second `wezterm.on("format-tab-title"` registration.
- A module-local table holding the baselines (the multi-context rule).
- A new key on `colors.tab_bar` (R3 — `01-appearance` R4 owns that table).
- `#rrggbb`, any scheme name, `PaneSelect`, `burrito` (epic acceptance,
  epic I3).

## Acceptance

- [x] `env HOME=$SCRATCH wezterm --config-file
      home/dot_config/wezterm/wezterm.lua ls-fonts --list-system` exits 0
      with stderr free of `not a valid Config field` and of
      `Configuration Error`. Ran: `rc=0`, stderr empty (the `cat` of the
      captured stderr printed nothing). Also re-proved inside the gate's
      `--probe` stage against `wezterm 20240203-110809-5046fc22`.
- [x] Exactly one `wezterm.on("format-tab-title"` in the file, and its body
      contains both `AnsiColor = "Silver"` and a bare-`label` return for the
      `tab.is_active` case. Ran:
      `grep -c 'wezterm.on("format-tab-title"'` → `1`; the handler
      extracted with `awk` carries
      `if tab.is_active or not tab_is_occupied(tab) then` / `return label`
      and `AnsiColor = "Silver"`.
- [x] `wezterm.GLOBAL.tab_pane_program` is assigned exactly once and read
      only through `pane_programs()`; no `local` table holds baselines. Ran:
      `grep -c 'wezterm.GLOBAL.tab_pane_program ='` → `1`, and
      `grep -c 'wezterm.GLOBAL.tab_pane_program'` → `2` (the write plus the
      single read inside `pane_programs`). No `^local <name> = {` in the
      block → `0`.
- [x] `get_foreground_process_name` appears exactly once in the file, inside
      `learn_pane_programs`, wrapped in `pcall`. Ran:
      `grep -n 'get_foreground_process_name'` → one hit, line 786,
      `return p:get_foreground_process_name()`, and the enclosing `pcall`
      opens one line above it. **The spec's own code block would have made
      this 2**, because its comment spelled the accessor out; the comment
      was reworded to "The accessor below is called in this one place and
      nowhere else", which keeps the reason and makes the assertion the
      spec actually states satisfiable.
- [x] `learn_pane_programs` is registered on all four of `update-status`,
      `window-config-reloaded`, `pane-focus-changed`,
      `window-focus-changed`. Ran: `1` each.
- [x] No shell name inside the new block. Ran the block extraction the box
      names, piped into
      `/usr/bin/grep -cE '"(nu|zsh|bash|fish|sh)"'` → `0`. File-wide was
      not asserted, for the reason the box gives.
- [x] `/usr/bin/grep -cE '#[0-9a-fA-F]{6}'` over the whole file is still 0.
      Ran: `0`.
- [x] `colors.tab_bar` still carries exactly the six keys `01-appearance` R4
      wrote — `background`, `active_tab`, `inactive_tab`,
      `inactive_tab_hover`, `new_tab`, `new_tab_hover`. Ran, extracted from
      the `local tab_bar = {` table: exactly those six, in that order.
- [x] No regression on T.1–T.4: `show-keys --lua` from the same file still
      prints `jump_mode` at 36 rows, `act.Nop` exactly 27 times and
      `copy_mode` at 55 rows; `bash tests/wezterm-appearance.sh`,
      `bash tests/wezterm-startup-layout.sh`,
      `bash tests/wezterm-f5-tab-select.sh` and
      `bash tests/wezterm-copy-mode.sh` all stay ALL PASS. Ran: 36, 27, 55;
      all four gates ALL PASS, and `bash tests/wezterm-grid-centering.sh`
      (T.7, which landed into this file earlier in the session) is ALL PASS
      too.
- [x] `git ls-files home/dot_config/wezterm/` still prints exactly
      `home/dot_config/wezterm/wezterm.lua`. Ran: that one line.

The five behavioural boxes of the PRD need a live GUI and are the T.6 rows
spec02 writes into `gates/manual/wave4.md`. Do not tick a PRD acceptance box
off this spec.

## Verify and Proof

```sh
SRC=home/dot_config/wezterm/wezterm.lua
H="$(mktemp -d)"
env HOME="$H" wezterm --config-file "$SRC" ls-fonts --list-system \
  >/dev/null 2>"$H/err"; echo "rc=$?"; cat "$H/err"
/usr/bin/grep -c 'wezterm.on("format-tab-title"' "$SRC"          # want 1
/usr/bin/grep -c 'AnsiColor = "Silver"' "$SRC"                   # want 2 (clock + tint)
/usr/bin/grep -c 'wezterm.GLOBAL.tab_pane_program =' "$SRC"      # want 1
/usr/bin/grep -c 'get_foreground_process_name' "$SRC"            # want 1
/usr/bin/grep -c 'wezterm.on("update-status", learn_pane_programs)' "$SRC"          # want 1
/usr/bin/grep -c 'wezterm.on("window-config-reloaded", learn_pane_programs)' "$SRC" # want 1
/usr/bin/grep -c 'wezterm.on("pane-focus-changed", learn_pane_programs)' "$SRC"     # want 1
/usr/bin/grep -c 'wezterm.on("window-focus-changed", learn_pane_programs)' "$SRC"   # want 1
/usr/bin/grep -cE '#[0-9a-fA-F]{6}' "$SRC" || true               # want 0
# mux.all_panes, not all_panes: `retint_all_panes` (01-appearance R6) makes the
# bare substring 3 hits and a bare pattern would fail on a landed line.
/usr/bin/grep -cE 'mux\.all_panes|mux\.get_pane|PaneSelect|burrito' "$SRC" || true  # want 0
# get_current_working_directory appears twice, both in R10's comment recording
# that it does NOT exist. Assert the non-comment count.
/usr/bin/grep -v '^ *--' "$SRC" | /usr/bin/grep -c 'get_current_working_directory' || true   # want 0
sed -n '/── 05-tab-content-state/,/── R5: the tab title/p' "$SRC" \
  | /usr/bin/grep -cE '"(nu|zsh|bash|fish|sh)"' || true          # want 0
env HOME="$H" wezterm --config-file "$SRC" show-keys --lua > "$H/keys.lua"
/usr/bin/grep -c 'act.Nop' "$H/keys.lua"                         # want 27
bash tests/wezterm-appearance.sh
bash tests/wezterm-startup-layout.sh
bash tests/wezterm-f5-tab-select.sh
bash tests/wezterm-copy-mode.sh
git ls-files home/dot_config/wezterm/
```
