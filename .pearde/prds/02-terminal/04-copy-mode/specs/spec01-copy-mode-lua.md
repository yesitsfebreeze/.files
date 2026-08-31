# spec01 — copy mode, paste, Ctrl+C and the mouse bindings in `wezterm.lua`

Extends `home/dot_config/wezterm/wezterm.lua` with everything R1–R4 and
R6–R8 put in the terminal config, plus R5's WezTerm half (the user-var
handler; the nushell writer is spec02). The source to port is the deployed
`~/.config/wezterm/wezterm.lua` (epic I4), read-only — minus the `opacity`
arm of the user-var handler, which open decision 5(b)
([`decisions/wallpaper-opacity`](../../../00-delivery/decisions/wallpaper-opacity/prd.md))
drops, and minus the live link-opener comment's mention of a deleted
multiplexer. Every probe anchor below was measured against the pinned build
(`20240203-110809-5046fc22`) before this spec was written.

**Est:** 1h

**Footprint:** `home/dot_config/wezterm/wezterm.lua` (extend — T.3 created
`config.key_tables` and holds the file until its lane closes; land only
after T.3 lands and no other lane holds the file)

## Anchors, not line numbers

- The copy-mode block goes **inside the existing
  `-- ── 03-f5-jump-mode` section's tail**: immediately before the line
  `config.key_tables = { jump_mode = jump_mode_keys }`, under its own
  `-- ── 04-copy-mode` header. It uses `act` and `wezterm`, defined above.
- That assignment line is **edited in place** to
  `config.key_tables = { copy_mode = copy_mode, jump_mode = jump_mode_keys }`.
  One assignment — a second `config.key_tables = …` clobbers the first.
  Rewrite T.3's "later terminal nodes extend this assignment —
  04-copy-mode adds copy_mode to it" comment to describe the done state
  (both tables, one assignment); a stale "will add" reads as current.
- The three key entries are **appended inside the existing
  `config.keys = { … }` table**, after the `F5` entry. Do not create a
  second table or a second assignment.
- `config.mouse_bindings` does not exist in the file yet. Create it once,
  after the `config.keys` table closes and before `return config`.
- The `user-var-changed` handler goes beside `enter_copy_mode`, which both
  entry paths share.

## The code

### The toggle, the entry function, and the handler (R1, R4, R5)

```lua
-- Copy mode: ctrl+shift+x freezes the scrollback and drops a movable
-- cursor. One key drives the whole select-and-copy cycle: first `c`
-- anchors a Cell selection at the cursor, second `c` copies the range and
-- leaves copy mode. The toggle is tracked per PANE ID rather than by
-- reading the selection text back, because a selection that begins over
-- blank cells reads as empty and would desync the toggle. State is reset
-- on ENTRY, so a copy mode exited any other way (q/Esc/y) cannot leave it
-- stale.
local copy_selecting = {}

-- Enter copy mode from a clean state: clear any stale selection and the
-- per-pane toggle flag, so the first `c` always starts (never finishes) a
-- selection. Shared by the ctrl+shift+x keybind and the user-var trigger.
local function enter_copy_mode(window, pane)
    copy_selecting[pane:pane_id()] = nil
    window:perform_action(act.ClearSelection, pane)
    window:perform_action(act.ActivateCopyMode, pane)
end

-- Shell-driven copy mode: a nushell command (copymode.nu) prints an OSC
-- 1337 SetUserVar named `copymode`; WezTerm parses it off the pty and
-- enters copy mode here, ignoring the value. That is how a shell command
-- reaches a GUI-only mode. This handler answers to ONE name: the live
-- config's sibling `opacity` user-var (the background-transparency
-- toggle) is refused by prds/00-delivery/decisions/wallpaper-opacity
-- (2026-08-21) and must not come back with a port of this handler.
wezterm.on("user-var-changed", function(window, pane, name, _value)
    if name == "copymode" then
        enter_copy_mode(window, pane)
    end
end)
```

The reset order is R1's: flag, `ClearSelection`, then `ActivateCopyMode`.
`copy_selecting` stays a module-local, as deployed — the two callbacks
that touch it run in the same context on this build, and the R1 entry
reset is the recovery if it ever desyncs. Do not move it to
`wezterm.GLOBAL`.

### The `c` cycle on the extended default table (R2, R3, R4)

```lua
-- Extend the DEFAULT copy_mode table so every builtin motion survives;
-- only the plain-`c` toggle is added on top. Extension, never
-- replacement.
--
-- The builtin table is 54 rows, and the count is measured, not the
-- printer's: `wezterm show-keys --lua` on a BARE config prints 62
-- copy_mode rows, because the printer shows eight uppercase+SHIFT
-- duplicates (F G H L M O T V) that wezterm.gui.default_key_tables()
-- folds away. The effective table here prints 55 — 54 builtin plus this
-- `c` — and shift+g still reaches `G`. Do not "fix" the count.
--
-- Copy mode has NO search: `/`, NextMatch, PriorMatch, ClearPattern and
-- CycleMatchType all live in the separate 10-row `search_mode` table,
-- reachable from normal mode via WezTerm's default Ctrl+Shift+F — which
-- this config neither sets nor shadows.
local copy_mode = wezterm.gui.default_key_tables().copy_mode
table.insert(copy_mode, {
    key = "c",
    mods = "NONE",
    action = wezterm.action_callback(function(window, pane)
        local id = pane:pane_id()
        if copy_selecting[id] then
            copy_selecting[id] = nil
            window:perform_action(
                act.Multiple({
                    act.CopyTo("ClipboardAndPrimarySelection"),
                    act.CopyMode("Close"),
                }),
                pane
            )
        else
            copy_selecting[id] = true
            window:perform_action(act.CopyMode({ SetSelectionMode = "Cell" }), pane)
        end
    end),
})
```

`wezterm.gui.default_key_tables()` is safe unguarded at config-eval time
on the pinned build: the deployed config calls it and both `ls-fonts` and
`show-keys` load it with rc 0 (measured 2026-08-22).

### The three key entries (R1, R6, R7)

Append to `config.keys`:

```lua
-- CTRL-SHIFT-X: enter copy mode from a clean state (see enter_copy_mode
-- above for why entry is where the reset lives).
{
    key = "x",
    mods = "CTRL|SHIFT",
    action = wezterm.action_callback(enter_copy_mode),
},
-- CTRL-V: native paste. Sends the clipboard as a bracketed paste, which
-- is how text reaches both the shell and a running program (Claude,
-- nvim). No subprocess — and it is what makes clipboard-based dictation
-- land in the terminal.
{ key = "v", mods = "CTRL", action = act.PasteFrom("Clipboard") },
-- CTRL-C copies when a selection exists, otherwise falls through to the
-- pty as a normal interrupt (SIGINT) so the key keeps its terminal
-- meaning. The fallthrough is the point: the platform-native copy
-- shortcut without ever costing an interrupt.
{
    key = "c",
    mods = "CTRL",
    action = wezterm.action_callback(function(window, pane)
        local sel = window:get_selection_text_for_pane(pane)
        if sel and sel ~= "" then
            window:perform_action(act.CopyTo("ClipboardAndPrimarySelection"), pane)
            window:perform_action(act.ClearSelection, pane)
        else
            window:perform_action(act.SendKey({ key = "c", mods = "CTRL" }), pane)
        end
    end),
},
```

### The mouse bindings (R8)

After `config.keys` closes:

```lua
-- CTRL-ALT-SUPER + left-drag moves the whole OS window.
-- window_decorations is "RESIZE" (01-appearance), so StartWindowDrag is
-- the ONLY handle for repositioning; the deliberately heavy modifier
-- combo keeps it from stealing ordinary clicks and selection drags.
-- SUPER is the Cmd key.
config.mouse_bindings = {
    {
        event = { Down = { streak = 1, button = "Left" } },
        mods = "CTRL|ALT|SUPER",
        action = act.StartWindowDrag,
    },
    -- CTRL + left-click opens the hyperlink under the cursor.
    -- mouse_reporting = true keeps it working while an application is
    -- capturing the mouse (DECSET 1002/1006) — nvim and other
    -- full-screen TUIs do — because without the flag WezTerm forwards
    -- the click to the application and nobody opens the URL. Plain
    -- clicks still reach the application.
    {
        event = { Up = { streak = 1, button = "Left" } },
        mods = "CTRL",
        mouse_reporting = true,
        action = act.OpenLinkAtMouseCursor,
    },
}
```

Down for the drag, Up for the click — as deployed. The comment names nvim
and TUIs, never the deleted multiplexer: `burrito` is a refused name the
T.2 gate greps for.

## What must NOT appear

- `opacity` outside a comment, and no second arm in the user-var handler
  (R5; the refusal comment above is the only permitted mention).
- The wallpaper pipeline: `set_background`, `clear_background`,
  `run_bg_script`, `PromptInputLine`, a `b`/`CTRL|SHIFT` key (epic
  non-goals).
- `search_mode` as a config key — the default search table stays
  untouched (R3).
- `PaneSelect`, `burrito`, any `#rrggbb` constant (epic I3, T.2's gate,
  epic acceptance).
- A second `config.key_tables`, `config.keys` or `config.mouse_bindings`
  assignment.

## Acceptance

- [x] `env HOME=$SCRATCH wezterm --config-file
      home/dot_config/wezterm/wezterm.lua ls-fonts --list-system` exits 0
      with stderr free of `not a valid Config field` and of
      `Configuration Error`.
- [x] In `show-keys --lua` from the same file, the `copy_mode` table holds
      exactly **55** rows; exactly one is
      `key = 'c', mods = 'NONE', action = act.EmitEvent` (the callback
      prints as EmitEvent with an unstable number — never match the
      number); the `y` row still carries
      `CopyTo` + `CopyMode` `Close`; and the block contains none of
      `Search`, `NextMatch`, `PriorMatch`, `ClearPattern`,
      `CycleMatchType`.
- [x] The same dump: exactly one `'X'` row
      (`key = 'X', mods = 'CTRL', action = act.EmitEvent` — the binding
      replaces all three default `ActivateCopyMode` rows, so the literal
      `act.ActivateCopyMode` appears **0** times in the dump); exactly one
      `key = 'v', mods = 'CTRL', action = act.PasteFrom 'Clipboard'` row;
      exactly one `key = 'c', mods = 'CTRL', action = act.EmitEvent` row.
- [x] The same dump: `search_mode` still holds its 10 default rows, and
      the default `key = 'F', mods = 'CTRL', action = act.Search` row is
      present and unshadowed (R3's pointer target).
- [x] No regression on T.3: the `jump_mode` table still holds 36 rows,
      `act.Nop` still appears exactly 27 times, the `F5`, `F6` and
      `'Q'`/`'CTRL'` rows still print.
- [ ] `/usr/bin/grep` on the source: `user-var-changed` registered exactly
      once; `copymode` present; `opacity` appears on no non-comment line;
      0 hits for each of `set_background`, `PromptInputLine`, `burrito`,
      `PaneSelect`.
      **Not met as written, and it cannot be.** Measured 2026-08-22:
      `user-var-changed` = 1, `copymode` present, and 0 hits for each of
      the four refused names — but the non-comment `opacity` count is **1**,
      and the hit is `config.window_background_opacity = 0.95`
      (`wezterm.lua:656`), which is `01-appearance`'s own R8 field and
      predates this node. The clause is unsatisfiable without deleting
      another node's landed line. `tests/wezterm-copy-mode.sh` therefore
      asserts R5's actual content: the only non-comment `opacity` is that
      one field, so a second — a revived `opacity` user-var — still fails
      the gate. The spec clause needs the exception written into it.
- [x] `git ls-files home/dot_config/wezterm/` still prints exactly
      `home/dot_config/wezterm/wezterm.lua`;
      `bash tests/wezterm-appearance.sh --static`,
      `bash tests/wezterm-startup-layout.sh --static` and
      `bash tests/wezterm-f5-tab-select.sh --static` stay ALL PASS.

## Verify

```sh
SRC=home/dot_config/wezterm/wezterm.lua
H="$(mktemp -d)"
env HOME="$H" wezterm --config-file "$SRC" ls-fonts --list-system \
  >/dev/null 2>"$H/err"; echo "rc=$?"
env HOME="$H" wezterm --config-file "$SRC" show-keys --lua > "$H/keys.lua"
awk '/^    copy_mode = \{/{f=1} f&&/{ key = /{n++} f&&/^    \},/{f=0} END{print "copy_mode rows: " n}' "$H/keys.lua"   # want 55
/usr/bin/grep -c "key = 'c', mods = 'NONE', action = act.EmitEvent" "$H/keys.lua"   # want 1
/usr/bin/grep -c "act.ActivateCopyMode" "$H/keys.lua"                               # want 0
/usr/bin/grep -c "key = 'v', mods = 'CTRL', action = act.PasteFrom 'Clipboard'" "$H/keys.lua"  # want 1
/usr/bin/grep -c "key = 'c', mods = 'CTRL', action = act.EmitEvent" "$H/keys.lua"   # want 1
/usr/bin/grep -c "'F', mods = 'CTRL', action = act.Search" "$H/keys.lua"            # want 1
/usr/bin/grep -c 'act.Nop' "$H/keys.lua"                                            # want 27
/usr/bin/grep -c 'wezterm.on("user-var-changed"' "$SRC"                             # want 1
/usr/bin/grep -v '^ *--' "$SRC" | /usr/bin/grep -c 'opacity' || true                # want 0
/usr/bin/grep -cE 'set_background|PromptInputLine|burrito|PaneSelect' "$SRC" || true # want 0
bash tests/wezterm-appearance.sh --static
bash tests/wezterm-startup-layout.sh --static
bash tests/wezterm-f5-tab-select.sh --static
```
