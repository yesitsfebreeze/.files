---
complexity: 30
footprint:
  - home/dot_config/wezterm/wezterm.lua
  - tests/wezterm-appearance.sh
  - tests/wezterm-launchd-path.sh
  - gates/waves.tsv
  - prds/02-terminal/prd.md
  - prds/README.md
  - AGENTS.md
---

# spec01 — the cutover, in one change

Q8. `default_prog` attaches tmux, the tab bar goes, and every WezTerm binding
that addressed a tab or a pane is deleted **in the same change**, so there is
no period in which a digit means two different things.

`wezterm.lua`: **1297 → 449 lines.** More than the ~470 forecast, because copy
mode and the palette reader went with the rest.

## What was deleted

| Region | Lines | Where it lives now |
|---|---|---|
| `reconcile_tabs`, the slot map, the closing marker, 4 event registrations | ~320 | nowhere — tmux indices do not renumber, so the floor is unnecessary rather than reimplemented |
| the F5 jump table and the copy-mode table | ~120 | `tmux.conf` (`02-key-tables`, `05-copy-and-clipboard`) |
| the `colors.lua` reader, the reload watch, the derived `colors.tab_bar` | ~95 | `04-palette-delivery` |
| the occupancy tint and `format-tab-title` | ~150 | `03-status-bar`, as two format strings |
| the per-pane OSC retint | ~65 | tinty writes the client tty directly |
| the top-right clock | ~18 | tmux `status-right` |
| F6, Ctrl+Shift+X, F5, Ctrl+Shift+Q | ~60 | `tmux.conf`; Ctrl+Shift+Q went with the floor it defeated |

## What stays, and the one line that was added

Font, grid centering (and with it `status_update_interval`, its last
consumer), `window_decorations`, opacity, blur, `inactive_pane_hsb`,
scrollback, the launchd PATH seeding, the capsule keys, the two mouse
bindings.

**`config.disable_default_key_bindings = true` is load-bearing, not tidy.**
`show-keys` on a stock config lists `ActivateTab`, `ActivateTabRelative` and
`SplitVertical`/`SplitHorizontal` — a full second set of window and pane keys,
shipped, that no line of this file ever wrote. Left on, the epic's invariant
would be false out of the box and untestable, because the bindings that break
it are not in the file you would read to check. The genuinely local defaults
(fullscreen, font size, the macOS clipboard keys, quit, new window) are
re-added by hand.

**Ctrl+Shift+O spawns a new WINDOW**, not a new tab, and runs nushell directly
rather than through `tmux-main`: it is a one-shot `--execute` picker that
should exit with itself, not a second attach to the session you are in.

## The trap this change fell into

`SpawnCommandInNewWindow({ args = {...} })` reads `nu_config`/`nu_env`, which
were deleted with the old `default_prog`. Lua left the table with holes and
WezTerm rejected the whole config **silently**, falling back to its defaults —
`show-keys` then lists a plausible-looking table with none of this file's
bindings in it. `wezterm ls-fonts` prints the error that `show-keys` swallows.
The locals are restored and named.

## Acceptance

- [x] `bash tests/wezterm-appearance.sh` — ALL PASS. Its checks for the six
      removed mechanisms are **inverted, not deleted**: a gate that stopped
      looking would pass equally against a file where the old code came back.
- [x] `code_has` reads code, not commentary: four inverted checks convicted
      the comments that record the removal on first run, so every absence
      check strips Lua comment lines first.
- [x] `--probe` reads the **loaded** key table from the binary: ≥ 3
      `SendString` capsule keys present, and **zero** `ActivateTab`, zero
      `Split*`, zero F5/F6 — the invariant measured rather than promised.
- [x] `wezterm.lua` is under 600 lines (449).
- [x] `bash tests/wezterm-launchd-path.sh` — 111 checks, 111 pass, after
      amendment: `default_prog` resolves to `<home>/.local/bin/tmux-main`;
      the four PATH directories are counted once (`.local/bin` twice — the
      prefix and the script); the F6 prefix and its measured `path_helper`
      reason are read from `tmux.conf`; cf1 reverts `default_prog` in its copy
      so R7's drift stays reachable; cf2 asserts tmux-main's two-line
      diagnosis and the `/bin/sh` fallback.
- [x] **`TMUX_TMPDIR` is pinned in that gate, and it is a safety line.** tmux
      puts its socket under `$TMUX_TMPDIR`, falling back to `/tmp` — never
      `$TMPDIR`. Without it the stage's `new-session -A -s main` attached to
      the **developer's own session**. It did, once, on 2026-08-30; the
      leaked session was killed and the gate now asserts the pin.
- [x] Four gates retired: `wezterm-startup-layout.sh`,
      `wezterm-tab-content-state.sh`, `wezterm-f5-tab-select.sh`,
      `wezterm-copy-mode.sh`. Removed from `gates/waves.tsv`, which gains the
      six tmux gates.
- [x] Cross-cutting edits landed: `02-terminal` **I1** reversed and **I2**
      amended in place; all seven children carry a "Status after the tmux
      cutover" note saying superseded, amended or untouched, with what moved
      where; `prds/README.md`'s exclusion entry restates the burrito reason
      rather than repeating it; `AGENTS.md`'s scope decisions and epic table
      are in line.

## Verify and Proof

```sh
cd "$(git rev-parse --show-toplevel)"
wc -l home/dot_config/wezterm/wezterm.lua        # 449
bash tests/wezterm-appearance.sh
bash tests/wezterm-launchd-path.sh
bash tests/tmux-key-tables.sh
bash tests/tmux-status-bar.sh
tmux ls 2>&1 | grep -q 'no server running'
```

Run 2026-08-30: appearance ALL PASS, launchd-path 111/111, key-tables rc 0,
status-bar rc 0, default socket clean.
