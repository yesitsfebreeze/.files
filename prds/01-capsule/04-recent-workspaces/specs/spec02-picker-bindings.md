---
est: 0.25h
footprint:
  - home/dot_config/wezterm/wezterm.lua
---

# spec02 — `Ctrl+Shift+S` and `Ctrl+Shift+O`

Append the two picker keys to `wezterm.lua`'s `config.keys`, immediately after
the `Ctrl+Shift+D` / `Ctrl+Shift+B` pair, so the four capsule keys the epic's
`## Bindings` table owns sit together. Both reach the one CLI. Neither knows
what a recent workspace is.

Both keys are free on the record and re-checked here: `wezterm -n show-keys
--lua` binds `Ctrl+Shift+O` to nothing, and the PRD's `## Decisions` settled
`Ctrl+Shift+O` over `Ctrl+Shift+T` on 2026-08-22. `Ctrl+Shift+T` is untouched.

## Design

```lua
    -- prds/01-capsule/04-recent-workspaces R2: the recents picker, in this
    -- pane and in a new tab. Both keys are thin wrappers over the one CLI
    -- (the epic's one-entry-path acceptance); `capsule recent` owns the
    -- store, the picker screen and the mount.
    --
    -- Ctrl+Shift+S is the Ctrl+Shift+D shape: SendString into this pane,
    -- whose shell has the TTY tv needs.
    --
    -- Ctrl+Shift+O is SpawnCommandInNewTab, and deliberately NOT "spawn a
    -- tab, then send text into it": a pane that was created this instant has
    -- no shell reading its pty yet, so typed input would race the shell's
    -- startup. Making the picker the tab's PROGRAM removes the race. nushell
    -- --execute runs the command and then stays interactive, so an aborted
    -- pick leaves exactly the plain tab Ctrl+Shift+T would have given, and
    -- $nu.is-interactive is TRUE while --execute runs (measured on nushell
    -- 0.114.1, 2026-08-23; it is false under -c) so the picker's own TTY
    -- guard passes.
    --
    -- nu_config and nu_env are 06-launchd-path's locals, reused and not
    -- respelled: SpawnCommandInNewTab replaces default_prog, so both config
    -- paths have to be named a second time, and taking them from the one
    -- source is the difference between a reuse and two spellings that drift.
    -- The spawn resolves `nu` through config.set_environment_variables.PATH,
    -- the same seeding default_prog depends on under a GUI launch — if that
    -- ever stops applying to a pane spawn, the symptom is the launchd-path
    -- one: "No viable candidates found in PATH" in a tab that stays open.
    --
    -- Ctrl+Shift+T keeps WezTerm's SpawnTab and the tab reconciler's manual
    -- new-tab path (finding C-1). Either key's extra tab is adopted by the
    -- nine-tab floor, never closed by it.
    { key = "s", mods = "CTRL|SHIFT", action = act.SendString("capsule recent\r") },
    {
        key = "o",
        mods = "CTRL|SHIFT",
        action = act.SpawnCommandInNewTab({
            args = { "nu", "--config", nu_config, "--env-config", nu_env, "--execute", "capsule recent" },
        }),
    },
```

- `\r`, not `\n`: reedline submits on carriage return (the `d`/`b` precedent).
- Lowercase `key` with `CTRL|SHIFT`, matching every neighbour; `show-keys`
  folds it to `'S'` / `'O'` with `'CTRL'`.
- `show-keys --lua` prints the space in the sent string as `capsule\u{20}recent`.
  Measured 2026-08-23 against this file plus these two entries. Any check that
  greps the dump for `capsule recent` looks for text that is not there.
- Known and accepted, the `d`/`b` trade unchanged: `Ctrl+Shift+S` lands
  wherever the pane's input goes, so a non-empty prompt line or a running TUI
  receives it as keystrokes. That is the wrapper being thin.

## Owed elsewhere, not in this footprint

`gates/manual/wave4.md` is held by another worker. The five human-run C.4
checks belong there and are written out here so nothing is lost; the
orchestrator places them. Every one of them is interactive by nature — a GUI
WezTerm, a tv screen, a keypress — which is why the automated gate (spec03)
does not claim them.

1. **C.4** — the picker, after a restart. Mount three directories, quit
   WezTerm, reopen it, press `Ctrl+Shift+S`.
   PASS: a list titled `Recent` opens with all three, newest first; typing
   narrows it; Enter attaches to that directory's capsule at `/workspace`.
   FAIL: no list, a title that is not `Recent`, the wrong order, or
   `No viable candidates found in PATH`.
2. **C.4** — the new-tab variant. With something running in the current pane,
   press `Ctrl+Shift+O`.
   PASS: a new tab opens, the picker is in that tab, the pick attaches there,
   and the pane you came from is untouched.
   FAIL: the picker appears in the old pane, or the new tab dies at once.
3. **C.4** — aborting costs nothing. Press `Ctrl+Shift+O`, then `Esc`.
   PASS: the tab stays, with a usable nushell prompt in the picked-from
   directory. FAIL: the tab closes, or the shell exits.
4. **C.4** — `Ctrl+Shift+T` is still a plain tab. Press it.
   PASS: a plain new tab, no picker. FAIL: a picker, or nothing.
5. **C.4** — a deleted directory. Delete a directory you mounted, then open
   the picker twice.
   PASS: it is absent the first time, and
   `~/.cache/capsule/recents.nuon` no longer names it.
   FAIL: still listed, or listed once more.

## Acceptance

- [x] `wezterm --config-file home/dot_config/wezterm/wezterm.lua show-keys
      --lua` under an isolated `HOME` lists `'S'` with `'CTRL'` and action
      `SendString 'capsule\u{20}recent\r'`.
- [x] The same dump lists `'O'` with `'CTRL'` and action
      `SpawnCommandInNewTab` whose `args` end `'--execute',
      'capsule\u{20}recent'` and whose `domain` is `'CurrentPaneDomain'`.
- [x] The `args` in that dump name the deployed config paths —
      `<HOME>/.config/nushell/config.nu` and `env.nu` — proving `nu_config`
      and `nu_env` were reused rather than a literal path written in.
- [x] The same dump still lists `'T'` with `'CTRL'` and with `'SHIFT|CTRL'`
      as `SpawnTab 'CurrentPaneDomain'` — the PRD's decision, unmoved.
- [x] The same dump still lists `'D'`, `'B'`, `'F6'`, `'Q'` and `'X'` —
      nothing displaced.

## Verify and Proof

```sh
cd "$(git rev-parse --show-toplevel)"
H=$(mktemp -d)
env HOME="$H" wezterm --config-file home/dot_config/wezterm/wezterm.lua \
  show-keys --lua > "$H/keys.lua"; echo "show-keys exit=$?"
/usr/bin/grep -nE "key = 'S'|key = 'O'|key = 'T'|key = 'D'|key = 'B'|key = 'F6'|key = 'Q'|key = 'X'" \
  "$H/keys.lua"
/usr/bin/grep -cF "'--execute', 'capsule\u{20}recent'" "$H/keys.lua"
/usr/bin/grep -cF "$H/.config/nushell/config.nu" "$H/keys.lua"
```
