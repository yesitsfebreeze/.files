# spec01 — create `wezterm.lua`: palette reader, tab bar, baseline, F6

Creates `home/dot_config/wezterm/wezterm.lua` — the first file of the
terminal epic and the artifact every later T-node extends. It covers all of
R1–R11: the font stack, the tinty palette reader, the derived tab bar, the
digit-only tab title, the per-pane OSC retint, the appearance baseline, the
clock and the F6 theme toggle. Written against the deployed
`~/.config/wezterm/wezterm.lua` (epic I4) and against the `colors.lua` shape
that S.9's landed hook generates.

**Est:** 1.5h

**Footprint:** `home/dot_config/wezterm/wezterm.lua` (create — the only file;
`home/dot_config/wezterm/` must hold nothing else)

## The seam: what the hook writes, what this file reads

`home/dot_config/tinted-theming/tinty/executable_wezterm-colors.sh` (S.9,
landed) writes `~/.config/wezterm/colors.lua` as a Lua `return { … }` table
with exactly these keys, every value a lowercase `"#rrggbb"` string:
`foreground` `background` `cursor_bg` `cursor_border` `cursor_fg`
`selection_bg` `selection_fg`, `ansi` (8 entries), `brights` (8 entries).

**There are no base16 keys in that file.** Where the PRD's R4 and R7 say
base0N, use these aliases — the same mapping the hook encodes:

| base16 | colors.lua key |
|---|---|
| base00 | `background` (also `ansi[1]`) |
| base02 | `selection_bg` |
| base03 | `brights[1]` |
| base05 | `foreground` (also `ansi[8]`) |
| base07 | `brights[8]` |

The hook bails before writing when base00 or base05 fail to parse, so a file
it wrote always carries non-empty `background` and `foreground`.

## What to write

Head: `require("wezterm")` (the only `require` in the file),
`wezterm.config_builder()`, `local act = wezterm.action`,
`local triple = wezterm.target_triple`,
`local is_mac = triple:find("darwin") ~= nil` (the only platform surface
WezTerm offers), `local home = os.getenv("HOME") or ""`.

**Not in this file, on purpose:** no `default_prog`, no
`set_environment_variables`, no launchd PATH block —
[`06-launchd-path`](../../06-launchd-path/prd.md) owns those and lands later;
until then WezTerm falls back to the login shell and this file must load
standalone. No tab floor (T.2), no F5 (T.3), no copy mode (T.4), no
`center_grid` (T.8), no wallpaper pipeline and no opacity user-var (refused,
epic non-goals), no burrito comment. Do not create `colors.lua` in the
source tree — the legacy source tracked a stale copy and a `chezmoi apply`
would have clobbered the live palette; the file is generated user state.

### R1 — font

`config.font = wezterm.font_with_fallback({ "CaskaydiaCove Nerd Font",
"CaskaydiaCove NF", "JetBrainsMono Nerd Font", "Cascadia Code", "Menlo" })`.
`config.font_size = is_mac and 14.0 or 9.0`. `config.line_height = 1.0`.
`config.font_dirs = { home .. "/Library/Fonts" }` on macOS,
`{ home .. "/.local/share/fonts" }` otherwise — comment the reason: a
freshly installed font resolves from there before the system font cache
refreshes.

### R2, R3 — the palette reader

- `config.color_scheme = "Gruvbox dark, hard (base16)"` — the one permitted
  constant, commented as the no-theme-picked fallback, never as the palette.
- `local colors_file = home .. "/.config/wezterm/colors.lua"`.
- `wezterm.add_to_config_reload_watch_list(colors_file)` — auto-reload only
  watches files WezTerm loaded and a `dofile` is invisible to it.
- `load_theme()`: `local ok, t = pcall(dofile, colors_file)`; return `t`
  only if `ok and type(t) == "table" and t.background and t.foreground and
  t.ansi`, else `nil`. Comment both halves: `dofile` not `require` (require
  caches by module name — a second `tinty apply` in the same GUI process
  would keep returning the first palette), and the essential-key check
  (rejects the half-written file a concurrent hook can leave, instead of
  painting a half-empty theme).
- **Deviation from live, required by R3:** the deployed file falls back to a
  literal `"#1d2021"` overlay when no theme loads. Do not port that hex.
  When `load_theme()` returns nil, set no `config.colors` at all — the
  fallback `color_scheme` paints its own base00, which is the same value.
  The file must contain no `#rrggbb` constant and no scheme name other than
  the fallback line.

### R4 — tab bar and window frame, derived

Inside `if theme then`:

- `local base03 = theme.brights and theme.brights[1] or theme.selection_bg`
  (keep the live fallback and the live comment: colors.lua carries no
  separate base03 key).
- `tab_bar`: `background = theme.background`; `active_tab` bg
  `theme.selection_bg`, fg `theme.foreground`, `intensity = "Bold"`;
  `inactive_tab` bg `theme.background`, fg `base03`;
  `inactive_tab_hover` and `new_tab_hover` bg `theme.selection_bg`, fg
  `theme.foreground`, `italic = false`; `new_tab` bg `theme.background`, fg
  `base03`. Comment why derived: the retro bar does not inherit the scheme
  and stayed near-black under a light one.
- `config.colors = { foreground, background, cursor_bg, cursor_border,
  cursor_fg, selection_bg, selection_fg, ansi, brights, tab_bar }` — each
  field straight from `theme`.
- `config.window_frame = { active_titlebar_bg = theme.background,
  inactive_titlebar_bg = theme.background, button_fg = theme.foreground,
  button_bg = theme.background }` — the fancy bar is off, but
  `window_frame` still paints the resize border.

Chrome, outside the `if`: `use_fancy_tab_bar = false` (what makes
`colors.tab_bar` apply at all), `tab_bar_at_bottom = false`,
`show_new_tab_button_in_tab_bar = false`,
`hide_tab_bar_if_only_one_tab = true` — comment the last as vestigial while
the nine-tab floor holds, kept for a window opened by other means.

### R5 — tab title

```lua
wezterm.on("format-tab-title", function(tab)
    return string.format("  %d  ", tab.tab_index + 1)
end)
```

Comment: the bar is the F5 keymap legend
([`03-f5-jump-mode`](../../03-f5-jump-mode/prd.md) leans on this); nine
process titles would not fit and the opposite corner is the clock's.

### R6 — per-pane OSC retint

Port `theme_osc(t)` and `retint_all_panes()` from the live file verbatim in
mechanism:

- Payload: one OSC 4 with slots `0–7` from `ansi` and `8–15` from
  `brights`, then OSC 10 `foreground`, 11 `background`, 12 `cursor_bg`,
  17 `selection_bg`, 19 `selection_fg`, each `"\27]" .. code .. ";" ..
  value .. "\27\\"`.
- Dedupe on the payload in `wezterm.GLOBAL.tinty_osc` — the event fires per
  window and a theme switch reloads all of them; `GLOBAL` because it
  survives the reload that resets every local.
- Outer `pcall` around the mux walk plus inner `pcall` around each
  `p:inject_output(osc)` — the method is absent on older builds and a pane
  can die mid-iteration.
- `wezterm.on("window-config-reloaded", retint_all_panes)`.

Comment the reason it exists: a pane that received tinted-shell's per-pane
escapes holds an override that outranks `config.colors`, so a reload alone
leaves it on the old scheme. OSC only — nothing printed, cursor never
moves — safe over a full-screen TUI.

### R7, R8, R9 — the baseline

`window_decorations = "RESIZE"` ·
`default_cursor_style = "BlinkingBlock"` ·
`window_background_opacity = 0.95` ·
`macos_window_background_blur = 30` ·
`inactive_pane_hsb = { saturation = 0.85, brightness = 0.7 }` ·
`scrollback_lines = 10000` · `audible_bell = "Disabled"` ·
`window_padding = { left = 0, right = 0, top = 0, bottom = 0 }` —
comment: zeroed *because*
[`07-grid-centering`](../../07-grid-centering/prd.md) owns padding at
runtime (finding T-4); until that node lands the sub-cell remainder sits as
a gap on the right and bottom, and that is expected, not a bug here ·
`adjust_window_size_when_changing_font_size = false` (a fullscreen window
cannot grow, so WezTerm would leave a gap instead and appear to resize) ·
`front_end = "OpenGL"` (transparency plus OS blur have the same backend
sensitivity the old layered background had) · `max_fps = 60` and
`animation_fps = 60` (255 kept the GPU churning for nothing) ·
`enable_kitty_keyboard = false`, commented as the matched pair with
nushell's `use_kitty_protocol = false`
([`04-shell/01-core-config`](../../../04-shell/01-core-config/prd.md)):
enabling only the WezTerm half leaks `^[[?...u` over the prompt ·
`status_update_interval = 5000` — the one tick that drives the tab
reconcile, the centering and the clock; at 1 s it repainted the bar every
second for a minute-resolution clock.

The translucent tint is the active scheme's base00 by construction:
`config.colors.background` (with a theme) or the fallback scheme (without) —
never pure black, never a constant.

### R10 — the clock

`update-right-status` handler: `window:set_right_status(wezterm.format({
{ Foreground = { AnsiColor = "Silver" } }, { Text = "  " ..
wezterm.strftime("%H:%M") .. "  " } }))`, unconditionally and last so
nothing can displace it. Comment the record R10 demands: the OSC 7 cwd
label is impossible on this build — `pane:get_current_working_directory()`
is nil on `20240203` and raised on every tick, which is why the corner sat
empty; HH:MM only because the 5 s tick repaints it.

### R11 — F6

`config.keys = { … }` is created here with one entry; T.2/T.3/T.4 append to
this same table in later waves.

```lua
{
    key = "F6",
    mods = "NONE",
    action = wezterm.action_callback(function()
        wezterm.background_child_process({
            "sh", "-lc",
            'export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$HOME/.local/bin:$HOME/.cargo/bin:$PATH"; '
            .. 'exec nu -n -c "source $HOME/.config/nushell/theme.nu; _theme_toggle"',
        })
    end),
},
```

`_theme_toggle` is the export S.9's `theme.nu` provides for exactly this
out-of-band call. Comment both constraints as requirements: bound in
WezTerm because a full-screen TUI swallows a shell-level binding;
`background_child_process` because `tinty apply` runs the whole hook chain
(tinted-shell + the colors.lua generator) and `run_child_process` would
freeze every window for its duration — nothing needs the exit status, the
visible effect arrives when the reload watch fires on the rewritten
`colors.lua`. The inline PATH seeding repeats for the reason
[`06-launchd-path`](../../06-launchd-path/prd.md) owns; cross-link, do not
restate launchd mechanics.

## Acceptance

- [x] `env HOME=$SCRATCH wezterm --config-file
      home/dot_config/wezterm/wezterm.lua ls-fonts --list-system` exits 0
      with stderr free of `not a valid Config field`, in all three states:
      no `colors.lua`, a hook-generated `colors.lua`, and a truncated
      `colors.lua` (e.g. the first 3 lines of a valid one).
- [x] `/usr/bin/grep -cE '#[0-9a-fA-F]{6}'` on the file returns 0, and the
      only scheme name in the file is the single
      `config.color_scheme = "Gruvbox dark, hard (base16)"` line.
- [x] The only `require(` in the file is `require("wezterm")`; `dofile` and
      `add_to_config_reload_watch_list` are both present.
- [x] `env HOME=$SCRATCH wezterm --config-file … show-keys --lua` lists the
      `F6` binding; `run_child_process` appears nowhere in the file.
- [x] `git ls-files home/dot_config/wezterm/` prints exactly
      `home/dot_config/wezterm/wezterm.lua` — no `colors.lua`, no
      `config.lua`, no `background.png`, no `solo-window.*`, no
      `wsl-clip-prime.sh`.

## Verify

```sh
SRC=home/dot_config/wezterm/wezterm.lua
H="$(mktemp -d)"
env HOME="$H" wezterm --config-file "$SRC" ls-fonts --list-system \
  >/dev/null 2>"$H/err"; echo "rc=$?"
/usr/bin/grep -c 'not a valid Config field' "$H/err" || true   # want 0
/usr/bin/grep -cE '#[0-9a-fA-F]{6}' "$SRC" || true             # want 0
env HOME="$H" wezterm --config-file "$SRC" show-keys --lua \
  | /usr/bin/grep -c "'F6'"                                     # want >=1
git ls-files home/dot_config/wezterm/                           # one line
```
