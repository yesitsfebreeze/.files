# spec02 — the terminal bindings and the wave-3 manual boxes

Append `Ctrl+Shift+D` and `Ctrl+Shift+B` to wezterm.lua's key table (R8) and
add C.2's three human-run checks to `gates/manual/wave3.md`. Both keys are
free on the record: the epic's `## Bindings` table owns them, decision 5(c)
freed `B`, and no rekey is permitted (the PRD's `## Decisions`).

**Est:** 1.5h

**Footprint:** `home/dot_config/wezterm/wezterm.lua`,
`gates/manual/wave3.md` — **both serial-after-T.2**, that lane holds the
wezterm dir and the wave-3 checklist. If either is still held at
implementation, land nothing there and report the edit as owed to that lane
(the dev-image spec02 precedent).

## Design

Append two entries to `config.keys`, after the `Ctrl+Shift+Q` entry:

```lua
-- prds/01-capsule/01-container-lifecycle R8: thin wrappers over the one
-- capsule CLI. SendString, not a spawn, because the pane's cwd is
-- unreadable from Lua on this build (pane:get_current_working_directory()
-- is absent from wezterm 20240203 — see the R10 comment above): the
-- command is delivered to the pane's shell, whose cwd IS the pane's
-- directory. One code path by construction — the binding types exactly
-- the invocation a hand would.
{ key = "d", mods = "CTRL|SHIFT", action = act.SendString("capsule\r") },
{ key = "b", mods = "CTRL|SHIFT", action = act.SendString("capsule --rebuild\r") },
```

- `\r`, not `\n`: reedline submits on carriage return.
- Lowercase `key` with `CTRL|SHIFT`, matching the `q` entry;
  `show-keys` folds this to `'D'`/`'B'` with `'CTRL'`.
- Known and accepted: the string lands wherever the pane's input goes, so a
  non-empty prompt line or a running TUI receives it as keystrokes. That is
  the wrapper being thin; record it in the comment, do not guard it.

**gates/manual/wave3.md** — three `**C.2**` boxes in the house style
(PASS/FAIL each; `manual-coverage.sh` requires the task id):

1. Fresh-directory end-to-end: in a new scratch directory run `capsule` —
   PASS: image builds (first run only), zsh prompt at `/workspace`, `ls`
   shows the directory's contents; run it again — PASS: back at the prompt
   in well under a second, no build output. FAIL: any rebuild on the second
   run, or landing anywhere but `/workspace`.
2. Binding and CLI are one path: remove the scratch capsule, press
   `Ctrl+Shift+D` in a pane cd'd to the directory, `docker inspect` the
   container (Name, Image, Mounts, Labels) to a file; remove it, run
   `capsule` by hand from an unrelated cwd with the path argument, inspect
   again. PASS: the diff of the two inspects is empty. FAIL: any field
   differs.
3. `Ctrl+Shift+B` recreates: note the container id, press it. PASS: image
   rebuild runs, the new container id differs, shell lands at `/workspace`.
   FAIL: old container id survives, or no rebuild.

## Acceptance

- [x] `wezterm --config-file home/dot_config/wezterm/wezterm.lua show-keys
      --lua` (isolated `HOME`) lists `'D'` and `'B'` with `'CTRL'`, actions
      `SendString` of `capsule\r` and `capsule --rebuild\r`.
- [x] The same dump still lists `'F6'` and the `'Q'`/`'CTRL'` row — nothing
      displaced (T.1/T.2 regression guard).
- [x] `gates/manual/wave3.md` carries the three `**C.2**` boxes, unticked,
      and `bash gates/manual-coverage.sh` passes — or the report records
      both files as owed to the T.2 lane.
- [ ] Pressing `Ctrl+Shift+D` at an idle prompt runs `capsule` in that pane
      (manual box 2's first half, executed once here).

## Verify

```sh
env HOME=$(mktemp -d) wezterm --config-file home/dot_config/wezterm/wezterm.lua \
  show-keys --lua | /usr/bin/grep -E "'D'|'B'|SendString"
bash gates/manual-coverage.sh
```
