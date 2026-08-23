# spec03 — the `theme` cable channel and its preview

Covers the tv half of **R3**. Creates the `theme` cable channel and
`theme-preview.sh`, the two television assets `theme` (spec01) runs.
[`04-television`](../../04-television/prd.md) R5 assigns both here: "that
node owns the scheme scope, this one owns the channel plumbing" — and S.5 is
not a dep, so these files must stand alone. They do: `theme` calls
`tv theme` directly, never through `finder`.

**Est:** 0.75h

**Footprint:** `home/dot_config/television/cable/theme.toml.tmpl` (create),
`home/dot_config/television/executable_theme-preview.sh` (create)

## What to write

### `cable/theme.toml.tmpl`

Port the live channel, templating the two absolute paths with
`{{ .chezmoi.homeDir }}`. Absolute paths, not `~/…`, because television
hands the command to `$SHELL` — here nu — and an absolute path is the one
form that runs identically under nu, bash and sh.

- `[metadata]`: name `theme`, requirements `["nu", "tinty"]`.
- `[source]`:
  `command = "nu -n -c 'source <home>/.config/nushell/theme.nu; _theme_list | to text'"`,
  `output = "{}"`, **`no_sort = true`, `frecency = false`** — the slot-pair
  head ordering is the whole point of the channel, and television otherwise
  reorders the list out from under it.
- `[preview]`: `command = "<home>/.config/television/theme-preview.sh '{}'"`.
- `[ui]`: `preview_panel = { size = 65 }`, input-bar header `"theme: {}"`.
- Keep the header comment stating the contract: the preview paints a
  swatch and emits ONE OSC 11; Enter prints the focused id to stdout and
  `theme` applies it afterwards in the live shell; browsing never fires
  tinty's hook chain.

### `executable_theme-preview.sh`

Port the live 152-line script as-is, minus nothing structural — it is
self-contained bash (no helper files, no `tinty apply` anywhere). The parts
that are load-bearing and must survive the port:

- **The OSC 11 line** — one escape straight to `/dev/tty` retinting only the
  terminal background to the focused scheme's base00. This is the live
  preview that earns the picker its place; the swatch is decoration around
  it. If the swatch port fights, the PRD's out-of-scope sanctions dropping
  it — the OSC 11 emit and a plain id line stay.
- **Slot-tag strip** — `case "$id" in *" ("*)` back to the bare id, matching
  `_theme_list`'s `" (A · current)"`/`" (B)"` tags.
- **bash-3.2 palette storage** — one plain variable per key with indirect
  expansion; `declare -A` on macOS's bash parses `08` as arithmetic and dies
  with "value too great for base".
- **Bail paths** — missing yaml prints the id and exits 0; unparsed palette
  prints a plain name line, never a broken frame.
- **`NO_COLOR`** honored completely: zero escapes, and no OSC 11 either.
- **No opaque card fill** (`WBG=""`): the terminal is translucent
  (`window_background_opacity`), and an escape-set background renders a
  solid rectangle over the see-through window.

## Acceptance

- [x] `chezmoi execute-template` (or a scratch `chezmoi apply`) renders
      `theme.toml` with both paths absolute under the destination home and
      no `{{` remaining. *(2026-08-22, gate `--preview`: a fully isolated
      execute-template renders both commands absolute under the scratch
      destination home, `{{` absent.)*
- [x] The rendered `[source]` keeps `no_sort = true` and
      `frecency = false`. *(Both lines survive the render verbatim.)*
- [x] `theme-preview.sh 'base16-fixture (A · current)'` against a fixture
      scheme yaml emits exactly one OSC 11 carrying the fixture's base00,
      and its stdout contains the scheme name and `base16`. *(Under a real
      pty via script(1): exactly one `ESC]11;` and it carries `#101010`;
      stdout carries `Fixture Sixteen` and `base16`.)*
- [x] `NO_COLOR=1 theme-preview.sh base16-fixture` emits zero `\033`
      bytes. *(Zero escape bytes; the palette still renders as text. The
      live script fails this — its reset/bold were unconditional — so the
      port guards them behind the color flag.)*
- [x] `theme-preview.sh base16-nonexistent` exits 0 and prints the id.
      *(rc=0, id printed.)*
- [x] `/usr/bin/grep -c 'tinty apply' executable_theme-preview.sh` returns
      0 — browsing never applies. *(0 — the port also rephrased the two
      comments that carried the literal.)*
- [x] `bash -n` passes under `/bin/bash`. *(Exit 0.)*

## Verify

```sh
bash tests/theme-switcher.sh --preview   # spec04's gate, preview stage
```
