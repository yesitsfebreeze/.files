# leadermode — concept & design

`leadermode` gives Nushell a **which-key style leader overlay**: one chord opens a
menu, subsequent keys are swallowed and dispatched, and menus nest into a real
prefix tree. It lives in `home/dot_config/nushell/leadermode.nu`, is sourced by
`config.nu`, and is bound to **ctrl+space**.

## Why it has to be built, not configured

reedline (nu's line editor) has **no native multi-key prefix**. Every keybinding
is one chord → one event; there is no `<leader> g s` chord tree, and no community
plugin provides one. So a leader is emulated with the only two primitives the
runtime exposes:

1. **`executehostcommand`** — one reedline chord (ctrl+space) runs the nu command
   `leader`.
2. **`input listen`** — `leader` then reads keys raw in a loop. While that loop
   runs, reedline is not reading, so the overlay genuinely owns the keyboard. Each
   key either dispatches a menu row or is swallowed.

## The menu tree

`_leader_menu` returns the overlay rows. A row is one of these kinds:

| Row shape | Kind | Behaviour |
|-----------|------|-----------|
| `{ key, desc, palette: true }` | `palette` | opens the `q` commands channel (tv fuzzy pick over `_leader_commands`) |
| `{ name\|key, desc, find: {closure} }` | `find` | closure returns a `finder` selection; `_leader_open` acts on it (file→edit, dir→cd, grep→edit@line, commit→git show) |
| `{ name\|key, desc, run: {closure} }` | `run` | arbitrary closure; output prints. A `cd` inside it does **not** propagate (closure env is scoped) — use `find` for cd |
| `{ key, desc, menu: [ …rows ] }` | `menu` | descend into a nested level |

Every command is consolidated into the **`q` commands channel**, so the root tree
holds a single `q` row. `<leader> q` opens a tv picker over `_leader_commands` — you
fuzzy-type the command name and `enter` runs it. The default command set: `find
(resume)`, `find (new)`, `recent cwd`, and `git status`/`log`/`diff`. **Add a command
= one row in `_leader_commands`** — no other code changes needed; add direct-key
overlay shortcuts in `_leader_menu` only if you want them alongside the palette.

### The `q` palette

`_leader_palette` hands the precomputed command-name list to tv's `channels` channel
via `--source-command` (the same trick `finder` uses for its channel picker), so tv
draws and fuzzy-matches it. The confirmed line resolves through `_leader_command
[cmds, name]` (resolve-by-name, since the palette picks by the displayed entry, not a
keypress) and dispatches by `_leader_kind` — `find` rows route through `_leader_open`,
`run` rows fire their closure. It is called **directly** from `_leader_run` (never via
`do`) so a `cd` still reaches the shell.

## Dispatch — the pure core

Two pure helpers decide everything; the loop is just I/O around them:

- **`_leader_resolve [menu, code]`** → the row bound to that key, or `null`. Keys
  are matched on `input listen`'s `.code`, which is **case-sensitive** — a shifted
  letter arrives as its uppercase char, so `f` and `F` are distinct rows that never
  collide.
- **`_leader_kind [row]`** → `"menu" | "palette" | "find" | "run"`, checked in that precedence.
- **`_leader_command [cmds, name]`** → the palette row whose `name` matches the fuzzy-picked line, or `null`.

`_leader_run` loops: render the level, read a key, `esc` returns `"back"`, an
unmapped key is swallowed, otherwise resolve + classify + act. A submenu recurses;
its `"back"` re-renders the parent, its `"done"` (an action fired below) exits the
whole overlay. The recursion is `--env` end to end, so a `cd` from `_leader_open`
propagates out through every level to the shell.

```
ctrl+space ─▶ leader ─▶ _leader_run(root)
                          │ render level (_leader_prompt)
                          │ input listen ─▶ key
                          │   esc        ─▶ return "back"
                          │   unmapped   ─▶ swallow, loop
                          │   resolve+kind:
                          │     menu    ─▶ _leader_run(sub) ─▶ "back": re-render · "done": exit
                          │     palette ─▶ _leader_palette (tv pick → dispatch) ─▶ "done"
                          │     find    ─▶ _leader_open(do find) ─▶ "done"
                          │     run     ─▶ do run               ─▶ "done"
```

## Constraints

- **Interactive only** — `input listen` needs a tty; `leader` no-ops otherwise.
- **nu #13891**: `input listen` ignores `use_kitty_protocol`, so *modifier* combos
  inside the loop are unreliable. Keep menu keys plain chars; `esc` is the
  bail/back. (The f/F split works because shift is folded into the char itself, not
  reported as a separate modifier.)

## Testing

`_leader_resolve` and `_leader_kind`, plus the real `_leader_menu`'s validity
(every row has key+desc, unique top-level keys, expected kinds), are covered
headless in `tests/nushell/leadermode-test.nu` — run `just test`. The interactive
loop and the `do`-closure side effects are verified by hand.

See also [finder — concept & design](finder.md), the search engine leader routes into.
