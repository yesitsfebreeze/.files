# spec01 — `theme.nu`: the switcher module and its `config.nu` anchor

Covers **R1**, **R2**, the shell half of **R3**, and **R4**/**R5**'s
boundaries. Creates `home/dot_config/nushell/theme.nu` — the `theme` command,
the A/B slots, `_theme_toggle` — and fills the reserved `THEME` anchor in
`config.nu` with its `source` line. The tv assets it calls are spec03's; the
tinty propagation is spec02's.

**Est:** 1h

**Footprint:** `home/dot_config/nushell/theme.nu` (create),
`home/dot_config/nushell/config.nu` (edit, `THEME` anchor only)

## Reconciliation against live `~/.config/nushell/theme.nu`

Read in full on 2026-08-22, per the PRD's first acceptance box. Verdicts:

- **R1 holds.** Every apply in the live file goes through `^tinty apply`
  (`_theme_use_slot`, `_theme_commit`); the slot files record ids but only
  tinty writes `current_scheme`. Keep that shape.
- **R2 holds, with one correction.** The slots are deliberately **A/B, not
  light/dark**: nothing inspects a scheme's `variant`, a slot holds whatever
  was last picked while it was active, and light/dark is just the common use.
  The PRD's "switching between a light and a dark scheme" describes the use,
  not the mechanism — implement A/B.
- **R3 holds.** The picker applies **after tv exits, in the live shell** —
  never from a television action — and the preview never applies at all.
  Both constraints carry their reasons below.
- **R4 holds.** S.1 delivered the re-assert; `config.nu` reserves a `THEME`
  anchor after it (R10(e)). This spec only fills that anchor.
- **R5 holds.** The live F6 runs
  `nu -n -c "source $HOME/.config/nushell/theme.nu; _theme_toggle"` via
  `sh -lc` with PATH seeded. That invocation is the terminal's; this file's
  half of the contract is that it sources cleanly under `nu -n` and exports
  `_theme_toggle`.
- **Dropped by the `SIMPLIFY`,** confirmed present in the live file and to be
  left behind: `theme bg` and everything under it (the override ladder, the
  R/G/B tuner, `_theme_bg_persist`, `_theme_bg_tune`, `_theme_bg_list`,
  `_theme_override`), and the liked/recency machinery (`theme like`,
  `unlike`, `liked`, `recent`, `forget`, `_theme_recent_push`, the
  `recent.txt`/`liked.txt` files).

## What to write

### `home/dot_config/nushell/theme.nu`

Port the live file minus the dropped surface. Public surface:

```
theme                  open the tv picker; Enter applies into the ACTIVE slot
theme toggle           flip to the other slot and apply it (what F6 runs)
theme a | theme b      activate that slot and apply its scheme
theme slots            print both slots, * marks the active one
```

Structure, keeping the live names so the two files diff cleanly:

1. **Constants.** `THEME_SLOTS = ["a" "b"]`;
   `THEME_SLOT_FALLBACK = "base16-gruvbox-light-hard"`, used only as the
   tiebreak when seeding would put the same scheme in both slots — which
   would make F6 a no-op.
2. **State dir.** `$env.XDG_STATE_HOME | default ~/.local/state`, subdir
   `tinted-theming`, files `slot-a.txt`, `slot-b.txt`, `slot-active.txt`.
   Beside — not inside — tinty's data dir, so a `tinty install` or catalog
   re-clone never wipes the slots. No `recent.txt`, no `liked.txt`.
3. **Readers.** `_theme_current` (tinty's `current_scheme` under
   `XDG_DATA_HOME | default ~/.local/share`), `_theme_default_scheme`
   (tinty `config.toml`'s `default-scheme`, hard fallback
   `base16-gruvbox-dark-hard`), `_theme_active_slot` (anything unreadable or
   unrecognised reads as `a`, so a corrupt state file can never wedge the
   toggle), `_theme_slot`.
4. **`_theme_slots_seed`** — called at the top of every entry point. Makes
   both slots valid and **reconciles**: the active slot is defined as
   "whatever is actually applied", so a bare `tinty apply` run outside this
   file is adopted into the active slot. Drift repair in the order that loses
   the least: if the live scheme is the *other* slot's, move the **pointer**
   — overwriting the active slot there would collapse both slots onto one
   scheme and leave F6 a no-op with nothing to recover from.
5. **`_theme_use_slot`** — apply **first**, move the pointer only once tinty
   has returned. `tinty apply` is synchronous through its hook chain
   (~100 ms+) and F6 can be pressed again inside that window: with the
   pointer written first, the second press's drift repair saw pointer=new
   but current_scheme=old, "corrected" the pointer back, and the toggle
   bounced to the slot it had just left. Skip the apply when the slot's
   scheme is already current, so re-activating the live slot never fires the
   hook chain for a no-op. `export def`.
6. **`_theme_toggle`** — seed, then `_theme_use_slot` on the other slot.
   `export def`: the terminal invokes it out of band as
   `nu -n -c "source $HOME/.config/nushell/theme.nu; _theme_toggle"`, so the
   file must parse standalone under `nu -n` — no reference to anything
   `config.nu` or `env.nu` defines.
7. **`_theme_scheme_bg`** — a scheme id's `palette.base00` from its yaml
   under `repos/schemes/<system>/` with fallback to
   `custom-schemes/<system>/`. **`_theme_osc_bg`** — one OSC 11.
   **`_theme_bg_restore`** — re-assert the current scheme's base00 (OSC 111
   only when it is unknown). Explicit OSC 11, not OSC 111: the reset
   restores WezTerm's config background, which can lag the live theme, and
   some hosts ignore 111 entirely. No override branch — the override is
   dropped.
8. **`_theme_catalog`** — `tinty list` + `tinty list --custom-schemes`,
   trimmed, deduped, sorted, both under `try`. The custom-schemes arm stays
   even though this repo ships no custom schemes: it is one flag, and it
   keeps any schemes the machine already carries listable.
9. **`_theme_list`** — `export def`, the channel's source (spec03 calls it).
   Seed, then: head = the live scheme tagged `" (A · current)"` (active-slot
   letter) and the other slot's scheme tagged `" (B)"`; body = the catalog
   minus the head. No liked, no recents. television preserves source order,
   so the pair F6 flips between sits at the very top.
10. **`_theme_commit`** — strip the trailing ` (…)` tag
    (`str replace --regex ' \([^)]*\)$' ''` — a scheme id never contains
    `" ("`, so this cannot eat part of a real name), seed, `^tinty apply`
    under `try` with stderr dropped, write the id into the **active** slot.
    Picking a theme retunes the mode you are in; it never chooses a mode —
    that is the whole contract with F6.
11. **`def --wrapped theme [...rest]`** — dispatch. `--wrapped` types rest
    items as `glob` and `match` compares structurally, so coerce
    `($rest | get 0? | default "" | into string)` before dispatching.
    Subcommands `toggle`/`slots`/`a`/`b`; anything else falls through to the
    picker. Before the picker: error out with `run: tinty install` guidance
    when `tinty` is missing or `_theme_catalog` comes back empty (the
    catalog clone is a one-time `tinty install`, run nowhere automatic), and
    with `run: chezmoi apply` when `tv` is missing. Then
    `let sel = (tv theme ...$rest | str trim)` — non-empty →
    `_theme_commit $sel`, empty (Esc) → `_theme_bg_restore`.

Why the apply happens here and not in a television action, kept as a file
comment: tv prints the chosen entry on Enter and nothing on Esc; applying in
the live interactive shell after tv has fully exited means the OSC retint and
tinty's hooks run with the real shell env, not a stripped television-action
subprocess.

### `home/dot_config/nushell/config.nu`

At the `── THEME ──` anchor, replace the "Empty as this node lands" sentence
with the `source` line:

```
source ~/.config/nushell/theme.nu
```

Nothing else in the file moves. The anchor already sits after the palette
re-assert (S.1 R10(e)) and before `── KEYBINDINGS ──`; a `source` of a
missing file is a parse error (`nu::parser::sourced_file_not_found`), which
is why the line lands in the same change as the file.

## Acceptance

- [x] `nu -n -c 'source home/dot_config/nushell/theme.nu'` exits 0 — the
      file parses standalone, with no config.nu in sight. *(2026-08-22: exit
      0, stdout `PARSE-OK`, stderr empty — gate `--module` first two checks.)*
- [x] With scratch `XDG_STATE_HOME`/`XDG_DATA_HOME` and a stub `tinty` on
      PATH: `theme toggle` twice lands back on the starting slot, and the
      stub's call log shows the pointer file still naming the *old* slot at
      the instant of each apply (apply-before-pointer). *(Log:
      `apply base16-beta active=a` then `apply base16-alpha active=b`, final
      active=a, current=base16-alpha. The gate's counterfactual copy with
      the pointer written first logs `active=b` and FAILS the check.)*
- [x] With `current_scheme` hand-written to a scheme in neither slot,
      `_theme_list | first` names that scheme — the bare `tinty apply` was
      adopted into the active slot. *(Got `base16-gamma (A · current)`,
      slot-a.txt now `base16-gamma`.)*
- [x] `theme toggle` onto a slot whose scheme is already current spawns no
      `tinty apply` (stub call log empty). *(Log empty, pointer moved to b.)*
- [x] `_theme_commit "base16-zenburn (A · current)"` applies bare
      `base16-zenburn`. *(Stub saw `apply base16-zenburn`.)*
- [x] `grep -E 'theme bg|liked|recent\.txt|_theme_recent|_theme_override'`
      over `theme.nu` returns nothing — the dropped surface stayed dropped.
      *(No hits.)*
- [x] `config.nu`'s `THEME` anchor sources `theme.nu`, and the anchor order
      `PALETTE → THEME → KEYBINDINGS` still holds
      (`bash tests/nushell-core.sh --tree` stays green). *(2026-08-22:
      `--tree` EXIT=0; gate reports PALETTE(427) < THEME(480) < source(485)
      < KEYBINDINGS(487), source line present exactly once.)*

## Verify

```sh
nu -n -c 'source home/dot_config/nushell/theme.nu' \
  && /usr/bin/grep -c 'source ~/.config/nushell/theme.nu' home/dot_config/nushell/config.nu \
  && bash tests/nushell-core.sh --tree \
  && bash tests/theme-switcher.sh --module   # spec04's gate, module stage
```
