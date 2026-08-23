# spec02 — tinty config + the WezTerm palette hook

Covers the machinery behind **R1**: `tinty apply` only *is* the single palette
funnel if tinty is configured to propagate an apply — the tinted-shell OSC
item for the current pane, and the `wezterm-colors.sh` hook that writes the
`colors.lua` every WezTerm window rereads. Creates
`home/dot_config/tinted-theming/tinty/config.toml` and the hook script.

**Est:** 0.75h

**Footprint:** `home/dot_config/tinted-theming/tinty/config.toml` (create),
`home/dot_config/tinted-theming/tinty/executable_wezterm-colors.sh` (create)

## Why this node owns these files

Nobody else does, and the PRD's acceptance ("switching schemes moves WezTerm
… with no restart") is unreachable without them.
[`managed-config`](../../../05-platform/01-deploy-mechanism/managed-config/prd.md)
R2 declares `tinted-theming` in the managed surface but "does not write"
dirs owned by other tracks;
[`capabilities-provisioning.md`](../../../../docs/capabilities-provisioning.md)
records that the live chezmoi source deleted the whole directory
(`8fe3a71`) and only the deployed copy survives; T.1
([`02-terminal/01-appearance`](../../../02-terminal/01-appearance/prd.md))
reads `colors.lua` and never writes its generator. The palette-switching
track is this node, so the propagation config lands here. `install.sh` (P.2)
already installs the `tinty` binary.

## What to write

### `config.toml`

The live file, minus the dropped surface:

- `default-scheme = "base16-gruvbox-dark-hard"` — matches WezTerm's built-in
  fallback (T.1 R3), so a fresh checkout with no prior pick lands on a
  neutral base. The generator and `tinty init` resolve `current_scheme`
  first and fall back to this only when nothing has ever been picked.
- `shell = "bash -c '{}'"`.
- One `[[items]]`: `tinted-shell` from
  `https://github.com/tinted-theming/tinted-shell`, `themes-dir =
  "scripts"`, `supported-systems = ["base16", "base24"]`, hook =
  `source "$TINTY_THEME_FILE_PATH" && "$HOME/.config/tinted-theming/tinty/wezterm-colors.sh"`.
- Keep the live comment explaining the split: the OSC sequences from
  tinted-shell only ever reach the one pane the hook ran in; the global path
  is `colors.lua`, which WezTerm has on its config-reload watch, so one
  write retints every window/tab/pane at once.

**Dropped from the live file, deliberately:** `background-override` (the
override ladder is out of scope), and the `zebar-colors.sh` /
`cmdpal-colors.sh` / `bg-override.sh` hook links (Windows/WSL surfaces on a
macOS-only host). None of those scripts is ported.

### `executable_wezterm-colors.sh`

Port the live 178-line script down to its core (~70 lines). Keep, each with
its recorded reason:

- **Scheme resolution**: `$1`, else `current_scheme`; yaml from
  `repos/schemes/<system>/` with fallback to `custom-schemes/<system>/`;
  silent exit 0 when nothing resolves.
- **bash-3.2-portable extraction** — no associative arrays, no `${var,,}`:
  macOS ships bash 3.2, where `declare -A` fails and every colour collapses
  to one value (the all-`#xxxxxx` corruption the live comment records).
  `grep -iE` + `sed -E` + `tr`, per key.
- **base24 brights** with per-colour fallback to the base16 accents
  (`br_red="${base12:-$base08}"` etc.), identical output for base16 schemes.
- **Half-parse bail**: empty `base00`/`base05` exits before writing, so a
  bad scheme never overwrites a good `colors.lua` with a half-empty one.
- **Unchanged-content guard**: compare the generated lua against the
  deployed copy and exit 0 on match — the hook runs on every `tinty init`,
  not only on a switch, and this guard is what keeps shell start cheap.
- **The write**: `mkdir -p ~/.config/wezterm` (T.1 has not landed; the dir
  may not exist), then the same `return { … }` lua table the live script
  emits — foreground/background/cursor/selection, 8 `ansi`, 8 `brights`,
  header comment naming the scheme.

**Dropped:** the `background-override` read, everything GlazeWM, the WSL
Windows mirror and its `cmd.exe` cache, and the `.chezmoidata/theme.toml`
write-back to the chezmoi source — the picked scheme is per-machine user
state here, not tracked config.

## Acceptance

- [x] With scratch `HOME`/`XDG_DATA_HOME`, a fixture scheme yaml, and
      `current_scheme` naming it: running the hook writes
      `$HOME/.config/wezterm/colors.lua` containing the fixture's base00
      and base05, 8 `ansi` entries and 8 `brights` entries. *(2026-08-22,
      gate `--hook`: background `#101010`, foreground `#d8d8d8`, 23 hex
      values = 7 roles + 8 ansi + 8 brights.)*
- [x] A base24 fixture lands its base12–17 values in `brights`; a base16
      fixture falls back to the accent colours there. *(brights carry
      `#bb0012` and `#bb0017` for base24; `#ab4642` (base08) for base16.)*
- [x] A fixture missing `base05` leaves an existing `colors.lua`
      byte-identical (half-parse bail). *(sha256 identical before/after,
      hook still exits 0.)*
- [x] Running the hook twice writes the file once — the second run exits on
      the unchanged-content guard (mtime unchanged). *(mtime pinned to
      1577833200, unchanged after the re-run.)*
- [x] `/usr/bin/grep -E 'zebar|cmdpal|glazewm|wslpath|chezmoidata|background-override'`
      over both new files returns nothing. *(No hits.)*
- [x] `bash -n` on the hook passes under `/bin/bash` (the 3.2 on macOS).
      *(Exit 0.)*

## Verify

```sh
bash tests/theme-switcher.sh --hook   # spec04's gate, hook stage
```
