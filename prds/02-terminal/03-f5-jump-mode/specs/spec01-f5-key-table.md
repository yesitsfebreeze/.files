# spec01 — the F5 key table in `wezterm.lua`

Extends `home/dot_config/wezterm/wezterm.lua` with the digits-only F5
one-shot tab select: the `jump_mode` key table and the `F5` binding that
pushes it. Covers R1, R2, R5 and R6. The source to port is the deployed
`~/.config/wezterm/wezterm.lua` (epic I4), read-only — but the port is
**smaller than the source**: Q2 dropped the pane-letter overlay, so every
callback in the live table existed only to unpaint labels and none of it
comes over. What survives is plain actions, verified to load clean on the
pinned build (`20240203-110809-5046fc22`) before this spec was written.

**Est:** 1h

**Footprint:** `home/dot_config/wezterm/wezterm.lua` (extend — T.1 created
it, T.2 extended it; T.2 is `done`, so land any time no other lane holds the
file)

## Anchors, not line numbers

- The table-builder block goes **after the floor block's trigger
  registrations** (the line
  `wezterm.on("window-config-reloaded", reconcile_tabs)`) and before the
  `-- ── R1: font` section. It uses `TAB_COUNT` and `act`, both defined
  above it.
- The `F5` entry is **appended inside the existing `config.keys = { … }`
  table**, beside T.1's F6 entry and T.2's `Ctrl+Shift+Q` entry. Do not
  create a second table or a second assignment.
- `config.key_tables` does not exist in the file yet. Create it **once**,
  beside the builder block, as an assignment later nodes extend —
  [`04-copy-mode`](../../04-copy-mode/prd.md) adds `copy_mode` to it. Say so
  in a comment, mirroring T.1's note on `config.keys`.

## The table name stays `jump_mode`

The manual's `wezterm-key` verify targets
(`home/dot_config/nushell/help/terminal.nuon`) and its README name the
table `jump_mode`, as `wezterm show-keys --lua` prints it. Rename it and
every `table: "jump_mode"` target goes dangling silently — the drift check
would resolve against a table that no longer exists.

## The code

### Timeout constant (R1)

```lua
local JUMP_TIMEOUT_MS = 5000
```

Comment: every key bound in the table exits the mode, so the timeout only
matters when `F5` was a misfire and nothing at all is pressed after it.

### The table builder (R1, R2)

```lua
local jump_mode_keys = {
    { key = "Escape", mods = "NONE", action = act.Nop },
}

for i = 1, TAB_COUNT do
    table.insert(jump_mode_keys, {
        key = tostring(i),
        mods = "NONE",
        action = act.ActivateTab(i - 1),
    })
end

for i = 1, 26 do
    table.insert(jump_mode_keys, {
        key = string.char(96 + i),
        mods = "NONE",
        action = act.Nop,
    })
end

config.key_tables = { jump_mode = jump_mode_keys }
```

Plain actions, no `action_callback`: the live callbacks existed only to
unpaint the overlay, and there is no overlay. `act.Nop` plus
`one_shot = true` is the whole exit — the Nop does nothing and the pop ends
the mode.

The digit loop runs over `TAB_COUNT`, not a literal 9: the digit set IS the
floor's address space (epic I1), and the two must not drift apart.

Comments to carry, each a requirement's reason:

- **On the digit loop (R1, and the PRD's R3 by pointer):** the tab bar
  already prints each tab's digit and nothing else (T.1's
  `format-tab-title`, its R5), so the addressing needs no overlay, no
  legend, and nothing painted into a pane — the status legend existed and
  was removed as noise, and the clock's corner is unconditional precisely
  so nothing can displace it.
- **On the letter loop (R2):** `until_unknown` pops the key table
  **without eating the keystroke**, so an unbound letter would fall through
  and type itself into whatever is running — nvim, Claude. The letters do
  nothing on purpose (the pane-letter half is dropped, Q2 2026-08-21);
  they are bound so a mistyped letter cancels the mode instead of leaking
  a character.
- **On the miss path (R5):** no BEL. Live bug **L-11** — a missed letter
  rang BEL into `audible_bell = "Disabled"` with no `visual_bell`, so the
  miss was silent and indistinguishable from the table having failed to
  open — only ever rang on the letter path, and removing the ring makes it
  **unreachable, not fixed**. Write exactly that word; do not add a
  `visual_bell`, and do not touch `audible_bell = "Disabled"` (T.1's R7).
- **Near the table (R4 by pointer):** pane switching is WezTerm's own
  unshadowed defaults, `Ctrl+Shift+`arrow → `ActivatePaneDirection`;
  nothing here binds panes.

Do not restate epic I3 (`PaneSelect` forbidden) in a comment — the epic
owns it; the gate checks the absence.

### The `F5` entry (R1)

Append to `config.keys`:

```lua
{
    key = "F5",
    mods = "NONE",
    action = act.ActivateKeyTable({
        name = "jump_mode",
        one_shot = true,
        until_unknown = true,
        timeout_milliseconds = JUMP_TIMEOUT_MS,
    }),
},
```

A direct action, not a callback — the live callback existed to call
`paint_labels` first. Comment: `one_shot` resolves the mode on the first
bound key; `until_unknown` is the backstop for keys the table does not name
(Enter, arrows, a ctrl combo) — the mode ends there too, it just cannot
swallow the keystroke on the way out. Binding `F5` means it no longer
reaches the shell or a running app; nothing in this setup uses it, but that
is the trade.

## What must NOT appear

The dropped half stays dropped — the PRD's "What was dropped" section is a
record, not a backlog. None of: `PaneSelect` (epic I3), `paint_labels`,
`unpaint_labels`, `PANE_ALPHABET`, `pane_labels`, `get_lines_as_text`,
`"\a"`, `visual_bell` as a setting. No second `set_right_status` writer
(R3 — the clock stays the only one). No hex constant.

## Acceptance

- [x] `env HOME=$SCRATCH wezterm --config-file
      home/dot_config/wezterm/wezterm.lua ls-fonts --list-system` exits 0
      with stderr free of `not a valid Config field` and of
      `Configuration Error`.
- [x] `show-keys --lua` from the same file lists the F5 row carrying
      `one_shot = true`, `until_unknown = true`,
      `timeout_milliseconds = (5000)` and the name `'jump_mode'` (the
      printer puts two spaces after `name =` — match the pieces, not the
      whole row).
- [x] The printed `jump_mode` table holds exactly 36 rows: `Escape`,
      digits `1`–`9` as `act.ActivateTab(0)`–`(8)` with `mods = 'NONE'`,
      and 26 letters; `act.Nop` appears exactly 27 times in the whole dump
      (Escape + 26 — no default binding uses `Nop` on this build, measured).
- [x] The same dump still lists `ActivatePaneDirection` on all four
      `SHIFT|CTRL` arrow rows (R4 — present and unshadowed), the `F6` row,
      and the `Q`/`CTRL` row — no regression on T.1's or T.2's tables.
- [x] `/usr/bin/grep -cE
      'PaneSelect|paint_labels|PANE_ALPHABET|pane_labels|get_lines_as_text'`
      on the file returns 0; `visual_bell` appears at most in a comment;
      `audible_bell = "Disabled"` still appears exactly once.
- [x] `git ls-files home/dot_config/wezterm/` still prints exactly
      `home/dot_config/wezterm/wezterm.lua`, and
      `bash tests/wezterm-appearance.sh --static` and
      `bash tests/wezterm-startup-layout.sh --static` stay ALL PASS.

## Verify

```sh
SRC=home/dot_config/wezterm/wezterm.lua
H="$(mktemp -d)"
env HOME="$H" wezterm --config-file "$SRC" ls-fonts --list-system \
  >/dev/null 2>"$H/err"; echo "rc=$?"
/usr/bin/grep -c 'not a valid Config field' "$H/err" || true      # want 0
env HOME="$H" wezterm --config-file "$SRC" show-keys --lua > "$H/keys.lua"
/usr/bin/grep -c 'one_shot = true' "$H/keys.lua"                  # want 1
/usr/bin/grep -c 'until_unknown = true' "$H/keys.lua"             # want 1
/usr/bin/grep -c 'timeout_milliseconds = (5000)' "$H/keys.lua"    # want 1
/usr/bin/grep -c 'act.Nop' "$H/keys.lua"                          # want 27
/usr/bin/grep -c "action = act.ActivatePaneDirection" "$H/keys.lua"  # want 4
/usr/bin/grep -cE 'PaneSelect|paint_labels|PANE_ALPHABET' "$SRC" || true  # want 0
bash tests/wezterm-appearance.sh --static
bash tests/wezterm-startup-layout.sh --static
```
